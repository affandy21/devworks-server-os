#!/usr/bin/env bash

require_cmd lsblk
require_cmd parted
require_cmd mkfs.ext4
require_cmd blkid

: "${INSTALL_MODE:=erase-disk}"
: "${TARGET_DISK:=auto}"
: "${DEVWORKS_MANUAL_CONFIRM_DISK:=no}"
: "${DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK:=no}"
: "${TARGET_EFI_SIZE_MIB:=512}"
: "${TARGET_SWAP_SIZE_MIB:=2048}"
: "${TARGET_ROOT_LABEL:=DEVWORKS_ROOT}"
: "${TARGET_EFI_LABEL:=DEVWORKS_EFI}"
: "${TARGET_SWAP_LABEL:=DEVWORKS_SWAP}"

print_disk_inventory() {
  log_info "Available install disks:"
  lsblk -e7 -dp -o NAME,SIZE,TYPE,TRAN,MODEL,SERIAL,FSTYPE,MOUNTPOINTS || true
}

select_target_disk_interactive() {
  mapfile -t disks < <(lsblk -e7 -dpno NAME,TYPE | awk '$2 == "disk" {print $1}')
  [[ "${#disks[@]}" -gt 0 ]] || die "No installable disks found."

  print_disk_inventory
  echo
  echo "Select target disk number. The selected disk will be erased."
  local index=1
  local disk
  for disk in "${disks[@]}"; do
    printf '  %d) %s\n' "${index}" "$(lsblk -dpno NAME,SIZE,MODEL,SERIAL "${disk}" | sed 's/[[:space:]]\+/ /g')"
    index=$((index + 1))
  done
  echo
  read -r -p "Disk number: " choice
  [[ "${choice}" =~ ^[0-9]+$ ]] || die "Invalid disk selection."
  (( choice >= 1 && choice <= ${#disks[@]} )) || die "Disk selection out of range."
  TARGET_DISK="${disks[$((choice - 1))]}"
}

confirm_destructive_disk_action() {
  local expected="ERASE ${TARGET_DISK}"
  print_disk_inventory
  echo
  log_warn "This will permanently erase all partitions and data on ${TARGET_DISK}."
  log_warn "This mode is not dualboot-safe."
  echo "To continue, type exactly: ${expected}"
  read -r -p "> " confirmation
  [[ "${confirmation}" == "${expected}" ]] || die "Disk confirmation did not match. Aborting."
}

if [[ "${INSTALL_MODE}" != "erase-disk" ]]; then
  die "INSTALL_MODE=${INSTALL_MODE} is not implemented yet. Current safe mode is erase-disk with manual disk confirmation. Dualboot will require a separate non-destructive partition workflow."
fi

if [[ "${TARGET_DISK}" == "auto" || -z "${TARGET_DISK}" ]]; then
  if is_yes "${DEVWORKS_MANUAL_CONFIRM_DISK}"; then
    select_target_disk_interactive
  else
    die "TARGET_DISK is auto but DEVWORKS_MANUAL_CONFIRM_DISK is not enabled."
  fi
fi

log_info "Preparing disk ${TARGET_DISK}"

[[ -b "${TARGET_DISK}" ]] || die "Target disk is not a block device: ${TARGET_DISK}"

if lsblk -nr -o MOUNTPOINTS "${TARGET_DISK}" | grep -q '[^[:space:]]' && ! is_yes "${DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK}"; then
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "${TARGET_DISK}" || true
  die "Target disk has mounted partitions. Unmount them or set DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK=\"yes\" only after verifying the target."
fi

if is_yes "${DEVWORKS_MANUAL_CONFIRM_DISK}"; then
  confirm_destructive_disk_action
elif ! is_yes "${DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK:-no}"; then
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "${TARGET_DISK}" || true
  die "Refusing to erase disk. Set DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK=\"yes\" in config."
fi

cleanup_mounts
swapoff -a || true

log_warn "Erasing partition table on ${TARGET_DISK}"
wipefs -a "${TARGET_DISK}" || true
sgdisk --zap-all "${TARGET_DISK}" 2>/dev/null || true
partprobe "${TARGET_DISK}" || true
sleep 2

parted -s "${TARGET_DISK}" mklabel gpt
parted -s "${TARGET_DISK}" mkpart ESP fat32 1MiB "$((TARGET_EFI_SIZE_MIB + 1))MiB"
parted -s "${TARGET_DISK}" set 1 esp on

disk_boot_mode="${TARGET_BOOT_MODE:-auto}"
if [[ "${disk_boot_mode}" == "auto" ]]; then
  if [[ -d /sys/firmware/efi ]]; then
    disk_boot_mode="efi"
  else
    disk_boot_mode="bios"
  fi
fi

NEXT_START_MIB=$((TARGET_EFI_SIZE_MIB + 1))
BIOS_PART=""
if [[ "${disk_boot_mode}" == "bios" ]]; then
  BIOS_START_MIB="${NEXT_START_MIB}"
  BIOS_END_MIB=$((BIOS_START_MIB + 2))
  parted -s "${TARGET_DISK}" mkpart BIOSBOOT "${BIOS_START_MIB}MiB" "${BIOS_END_MIB}MiB"
  parted -s "${TARGET_DISK}" set 2 bios_grub on
  BIOS_PART="$(disk_part_prefix "${TARGET_DISK}")2"
  NEXT_START_MIB="${BIOS_END_MIB}"
fi

ROOT_START_MIB="${NEXT_START_MIB}"
if [[ "${TARGET_SWAP_SIZE_MIB}" -gt 0 ]]; then
  SWAP_START_MIB="${ROOT_START_MIB}"
  SWAP_END_MIB=$((SWAP_START_MIB + TARGET_SWAP_SIZE_MIB))
  parted -s "${TARGET_DISK}" mkpart primary linux-swap "${SWAP_START_MIB}MiB" "${SWAP_END_MIB}MiB"
  parted -s "${TARGET_DISK}" mkpart primary ext4 "${SWAP_END_MIB}MiB" 100%
  EFI_PART="$(disk_part_prefix "${TARGET_DISK}")1"
  if [[ -n "${BIOS_PART}" ]]; then
    SWAP_PART="$(disk_part_prefix "${TARGET_DISK}")3"
    ROOT_PART="$(disk_part_prefix "${TARGET_DISK}")4"
  else
    SWAP_PART="$(disk_part_prefix "${TARGET_DISK}")2"
    ROOT_PART="$(disk_part_prefix "${TARGET_DISK}")3"
  fi
else
  parted -s "${TARGET_DISK}" mkpart primary ext4 "${ROOT_START_MIB}MiB" 100%
  EFI_PART="$(disk_part_prefix "${TARGET_DISK}")1"
  SWAP_PART=""
  if [[ -n "${BIOS_PART}" ]]; then
    ROOT_PART="$(disk_part_prefix "${TARGET_DISK}")3"
  else
    ROOT_PART="$(disk_part_prefix "${TARGET_DISK}")2"
  fi
fi

partprobe "${TARGET_DISK}" || true
udevadm settle || true
sleep 2

require_cmd mkfs.fat
mkfs.fat -F32 -n "${TARGET_EFI_LABEL}" "${EFI_PART}"
mkfs.ext4 -F -L "${TARGET_ROOT_LABEL}" "${ROOT_PART}"

if [[ -n "${SWAP_PART}" ]]; then
  mkswap -L "${TARGET_SWAP_LABEL}" "${SWAP_PART}"
fi

mkdir -p "${INSTALL_ROOT}"
mount "${ROOT_PART}" "${INSTALL_ROOT}"
mkdir -p "${EFI_ROOT}"
mount "${EFI_PART}" "${EFI_ROOT}"
if [[ -n "${SWAP_PART}" ]]; then
  swapon "${SWAP_PART}" || true
fi

ROOT_UUID="$(blkid -s UUID -o value "${ROOT_PART}")"
EFI_UUID="$(blkid -s UUID -o value "${EFI_PART}")"
SWAP_UUID=""
if [[ -n "${SWAP_PART}" ]]; then
  SWAP_UUID="$(blkid -s UUID -o value "${SWAP_PART}")"
fi

cat > "${STATE_DIR}/disk.env" <<EOF
EFI_PART="${EFI_PART}"
BIOS_PART="${BIOS_PART}"
ROOT_PART="${ROOT_PART}"
SWAP_PART="${SWAP_PART}"
ROOT_UUID="${ROOT_UUID}"
EFI_UUID="${EFI_UUID}"
SWAP_UUID="${SWAP_UUID}"
EOF

log_info "Disk prepared:"
log_info "  EFI:  ${EFI_PART} UUID=${EFI_UUID}"
if [[ -n "${BIOS_PART}" ]]; then
  log_info "  BIOS: ${BIOS_PART}"
fi
log_info "  Root: ${ROOT_PART} UUID=${ROOT_UUID}"
if [[ -n "${SWAP_PART}" ]]; then
  log_info "  Swap: ${SWAP_PART} UUID=${SWAP_UUID}"
fi
