#!/usr/bin/env bash

require_cmd lsblk
require_cmd mkfs.ext4
require_cmd blkid
require_cmd mount

: "${INSTALL_MODE:=erase-disk}"
: "${TARGET_DISK:=auto}"
: "${TARGET_ROOT_PARTITION:=}"
: "${TARGET_EFI_PARTITION:=}"
: "${TARGET_SWAP_PARTITION:=}"
: "${FORMAT_ROOT:=yes}"
: "${FORMAT_EFI:=no}"
: "${FORMAT_SWAP:=yes}"
: "${DEVWORKS_MANUAL_CONFIRM_DISK:=no}"
: "${DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK:=no}"
: "${TARGET_EFI_SIZE_MIB:=512}"
: "${TARGET_SWAP_SIZE_MIB:=2048}"
: "${TARGET_ROOT_LABEL:=DEVWORKS_ROOT}"
: "${TARGET_EFI_LABEL:=DEVWORKS_EFI}"
: "${TARGET_SWAP_LABEL:=DEVWORKS_SWAP}"

print_disk_inventory() {
  log_info "Available install disks and partitions:"
  lsblk -e7 -p -o NAME,SIZE,TYPE,TRAN,MODEL,SERIAL,FSTYPE,PARTLABEL,LABEL,MOUNTPOINTS || true
}

canonical_block_device() {
  readlink -f "$1"
}

partition_parent_disk() {
  local partition="$1"
  local parent
  parent="$(lsblk -dnro PKNAME "${partition}" | head -n1 | xargs || true)"
  [[ -n "${parent}" ]] || die "Unable to determine parent disk for partition: ${partition}"
  printf '/dev/%s' "${parent}"
}

require_partition_device() {
  local partition="$1"
  local purpose="$2"
  [[ -n "${partition}" ]] || die "${purpose} partition is not configured."
  partition="$(canonical_block_device "${partition}")"
  [[ -b "${partition}" ]] || die "${purpose} is not a block device: ${partition}"
  [[ "$(lsblk -dnro TYPE "${partition}" | xargs)" == "part" ]] ||
    die "${purpose} must be a partition, not a whole disk: ${partition}"
}

device_is_mounted() {
  local device="$1"
  lsblk -nr -o MOUNTPOINTS "${device}" | grep -q '[^[:space:]]'
}

select_target_disk_interactive() {
  local choice index disk
  mapfile -t disks < <(lsblk -e7 -dpno NAME,TYPE | awk '$2 == "disk" {print $1}')
  [[ "${#disks[@]}" -gt 0 ]] || die "No installable disks found."

  print_disk_inventory
  echo
  echo "Select target disk number. The selected disk will be erased."
  index=1
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

detect_existing_operating_systems() {
  local disk="$1"
  if lsblk -nr -o FSTYPE,PARTLABEL,LABEL,MOUNTPOINTS "${disk}" | grep -Eiq 'ntfs|BitLocker|EFI|ESP|Microsoft|Windows|linux|ext4|btrfs|xfs|crypto_LUKS|LVM'; then
    return 0
  fi
  blkid | grep -F "${disk}" | grep -Eiq 'TYPE="(ntfs|vfat|ext4|btrfs|xfs|crypto_LUKS|LVM2_member)"'
}

resolve_boot_mode() {
  local boot_mode="${TARGET_BOOT_MODE:-auto}"
  if [[ "${boot_mode}" == "auto" ]]; then
    if [[ -d /sys/firmware/efi ]]; then
      boot_mode="efi"
    else
      boot_mode="bios"
    fi
  fi
  printf '%s' "${boot_mode}"
}

print_erase_disk_summary() {
  local disk_size disk_model boot_mode existing_os
  disk_size="$(lsblk -dpno SIZE "${TARGET_DISK}" | head -n1 | xargs || true)"
  disk_model="$(lsblk -dpno MODEL,SERIAL "${TARGET_DISK}" | head -n1 | sed 's/[[:space:]]\+/ /g' | xargs || true)"
  boot_mode="$(resolve_boot_mode)"
  existing_os="no obvious existing OS signature detected"
  if detect_existing_operating_systems "${TARGET_DISK}"; then
    existing_os="possible existing OS/data partitions detected"
  fi

  cat <<EOF
Install summary
---------------
Mode:        ${INSTALL_MODE}
Target disk: ${TARGET_DISK}
Disk size:   ${disk_size:-unknown}
Disk model:  ${disk_model:-unknown}
Boot mode:   ${boot_mode}
EFI size:    ${TARGET_EFI_SIZE_MIB} MiB
Swap size:   ${TARGET_SWAP_SIZE_MIB} MiB
Root FS:     ${TARGET_ROOT_FS:-ext4}
Detection:   ${existing_os}

Partition plan:
  1. ERASE the complete target disk.
  2. Create a new EFI System Partition (${TARGET_EFI_SIZE_MIB} MiB).
  3. Create a BIOS boot partition when BIOS mode is selected.
  4. Create swap when TARGET_SWAP_SIZE_MIB > 0.
  5. Create a root filesystem using remaining space.

EOF
}

print_manual_partition_summary() {
  local root_fs efi_fs swap_fs
  root_fs="$(blkid -s TYPE -o value "${ROOT_PART}" 2>/dev/null || true)"
  efi_fs="$(blkid -s TYPE -o value "${EFI_PART}" 2>/dev/null || true)"
  swap_fs="disabled"
  if [[ -n "${SWAP_PART}" ]]; then
    swap_fs="$(blkid -s TYPE -o value "${SWAP_PART}" 2>/dev/null || true)"
  fi

  cat <<EOF
Install summary
---------------
Mode:          ${INSTALL_MODE}
Target disk:   ${TARGET_DISK}
Boot mode:     efi
Root part:     ${ROOT_PART} (${root_fs:-unformatted}) - WILL BE FORMATTED as ext4
EFI part:      ${EFI_PART} (${efi_fs:-unknown}) - PRESERVED and mounted only
Swap part:     ${SWAP_PART:-none} (${swap_fs:-none})

Safety rules:
  - No partition table will be created or erased.
  - Windows and data partitions are not resized or formatted by this installer.
  - The selected root partition loses all existing data.
  - The selected EFI partition must already be the shared EFI System Partition.

EOF
}

confirm_destructive_disk_action() {
  local expected="ERASE ${TARGET_DISK}"
  print_disk_inventory
  echo
  print_erase_disk_summary
  log_warn "This will permanently erase all partitions and data on ${TARGET_DISK}."
  log_warn "This mode is not dualboot-safe."
  echo "To continue, type exactly: ${expected}"
  read -r -p "> " confirmation
  [[ "${confirmation}" == "${expected}" ]] || die "Disk confirmation did not match. Aborting."
}

confirm_manual_partition_action() {
  local expected="INSTALL ${ROOT_PART} KEEP-EFI ${EFI_PART}"
  print_disk_inventory
  echo
  print_manual_partition_summary
  log_warn "Only the root partition ${ROOT_PART} will be formatted."
  log_warn "Verify it is NOT a Windows, recovery, EFI, or data partition."
  echo "To continue, type exactly: ${expected}"
  read -r -p "> " confirmation
  [[ "${confirmation}" == "${expected}" ]] || die "Partition confirmation did not match. Aborting."
}

mount_and_record_target() {
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
INSTALL_MODE="${INSTALL_MODE}"
TARGET_DISK="${TARGET_DISK}"
EFI_PART="${EFI_PART}"
BIOS_PART="${BIOS_PART:-}"
ROOT_PART="${ROOT_PART}"
SWAP_PART="${SWAP_PART}"
ROOT_UUID="${ROOT_UUID}"
EFI_UUID="${EFI_UUID}"
SWAP_UUID="${SWAP_UUID}"
EOF

  if [[ -n "${PARTITION_TABLE_BACKUP:-}" && -f "${PARTITION_TABLE_BACKUP}" ]]; then
    mkdir -p "${INSTALL_ROOT}/var/backups/devworks-installer"
    install -m 0600 "${PARTITION_TABLE_BACKUP}" \
      "${INSTALL_ROOT}/var/backups/devworks-installer/$(basename "${PARTITION_TABLE_BACKUP}")"
    log_info "Partition table backup preserved in installed system: /var/backups/devworks-installer/$(basename "${PARTITION_TABLE_BACKUP}")"
  fi

  log_info "Target prepared:"
  log_info "  EFI:  ${EFI_PART} UUID=${EFI_UUID}"
  if [[ -n "${BIOS_PART:-}" ]]; then
    log_info "  BIOS: ${BIOS_PART}"
  fi
  log_info "  Root: ${ROOT_PART} UUID=${ROOT_UUID}"
  if [[ -n "${SWAP_PART}" ]]; then
    log_info "  Swap: ${SWAP_PART} UUID=${SWAP_UUID}"
  fi
}

partition_type_guid() {
  local partition="$1"
  local disk="$2"
  local guid partition_number

  guid="$(lsblk -dnro PARTTYPE "${partition}" 2>/dev/null | tr '[:upper:]' '[:lower:]' | xargs || true)"
  if [[ -n "${guid}" ]]; then
    printf '%s\n' "${guid}"
    return 0
  fi

  case "${partition}" in
    *p[0-9]*) partition_number="${partition##*p}" ;;
    *[0-9]*) partition_number="${partition##*[!0-9]}" ;;
    *) return 0 ;;
  esac
  command -v sgdisk >/dev/null 2>&1 || return 0
  sgdisk -i "${partition_number}" "${disk}" 2>/dev/null |
    awk -F': ' '/Partition GUID code:/ {print tolower($2); exit}' |
    awk '{print $1}'
}

prepare_manual_partition_install() {
  local root_disk efi_disk root_fs efi_fs swap_disk boot_mode root_parttype efi_parttype
  boot_mode="$(resolve_boot_mode)"
  [[ "${boot_mode}" == "efi" ]] ||
    die "INSTALL_MODE=manual-partition supports UEFI dual boot only. Boot the installer in UEFI mode."
  is_yes "${DEVWORKS_MANUAL_CONFIRM_DISK}" ||
    die "INSTALL_MODE=manual-partition requires DEVWORKS_MANUAL_CONFIRM_DISK=yes."
  is_yes "${FORMAT_ROOT}" ||
    die "INSTALL_MODE=manual-partition requires FORMAT_ROOT=yes to install on a dedicated empty Linux partition."
  ! is_yes "${FORMAT_EFI}" ||
    die "FORMAT_EFI=yes is forbidden in manual-partition mode. The existing EFI partition must be preserved."

  [[ -n "${TARGET_ROOT_PARTITION}" ]] || die "TARGET_ROOT_PARTITION is required in manual-partition mode."
  [[ -n "${TARGET_EFI_PARTITION}" ]] || die "TARGET_EFI_PARTITION is required in manual-partition mode."
  ROOT_PART="$(canonical_block_device "${TARGET_ROOT_PARTITION}")"
  EFI_PART="$(canonical_block_device "${TARGET_EFI_PARTITION}")"
  SWAP_PART=""
  if [[ -n "${TARGET_SWAP_PARTITION}" ]]; then
    SWAP_PART="$(canonical_block_device "${TARGET_SWAP_PARTITION}")"
  fi
  BIOS_PART=""

  require_partition_device "${ROOT_PART}" "Root"
  require_partition_device "${EFI_PART}" "EFI"
  [[ "${ROOT_PART}" != "${EFI_PART}" ]] || die "Root and EFI partitions cannot be the same device."

  root_disk="$(partition_parent_disk "${ROOT_PART}")"
  efi_disk="$(partition_parent_disk "${EFI_PART}")"
  [[ "${root_disk}" == "${efi_disk}" ]] ||
    die "For safety, manual-partition currently requires root and EFI partitions on the same disk."
  TARGET_DISK="${root_disk}"

  if [[ -n "${SWAP_PART}" ]]; then
    require_partition_device "${SWAP_PART}" "Swap"
    [[ "${SWAP_PART}" != "${ROOT_PART}" && "${SWAP_PART}" != "${EFI_PART}" ]] ||
      die "Swap must not reuse the root or EFI partition."
    swap_disk="$(partition_parent_disk "${SWAP_PART}")"
    [[ "${swap_disk}" == "${TARGET_DISK}" ]] ||
      die "For safety, swap must be on the same target disk in manual-partition mode."
  fi

  cleanup_mounts
  if device_is_mounted "${ROOT_PART}" || device_is_mounted "${EFI_PART}" ||
     { [[ -n "${SWAP_PART}" ]] && device_is_mounted "${SWAP_PART}"; }; then
    lsblk -o NAME,SIZE,TYPE,FSTYPE,PARTLABEL,LABEL,MOUNTPOINTS "${TARGET_DISK}" || true
    die "A selected partition is mounted. Unmount it before running the dual boot installer."
  fi

  root_fs="$(blkid -s TYPE -o value "${ROOT_PART}" 2>/dev/null || true)"
  root_parttype="$(partition_type_guid "${ROOT_PART}" "${TARGET_DISK}")"
  case "${root_fs,,}" in
    ntfs|vfat|fat|exfat|bitlocker)
      die "Refusing to format ${ROOT_PART}; its filesystem (${root_fs}) may contain Windows or user data."
      ;;
  esac
  case "${root_parttype}" in
    c12a7328-f81f-11d2-ba4b-00a0c93ec93b|ebd0a0a2-b9e5-4433-87c0-68b6b72699c7|de94bba4-06d1-4d40-a16a-bfd50179d6ac)
      die "Refusing root partition ${ROOT_PART}; its GPT type is reserved for EFI, Microsoft data, or Windows recovery."
      ;;
  esac
  efi_fs="$(blkid -s TYPE -o value "${EFI_PART}" 2>/dev/null || true)"
  [[ "${efi_fs,,}" == "vfat" ]] ||
    die "EFI partition must be an existing FAT32/vfat filesystem; found '${efi_fs:-unformatted}' on ${EFI_PART}."
  efi_parttype="$(partition_type_guid "${EFI_PART}" "${TARGET_DISK}")"
  [[ "${efi_parttype}" == "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" ]] ||
    die "EFI partition ${EFI_PART} is vfat but is not marked as an EFI System Partition."

  confirm_manual_partition_action
  PARTITION_TABLE_BACKUP="${STATE_DIR}/partition-table-before-dualboot-$(date +%Y%m%d-%H%M%S).gpt"
  require_cmd sgdisk
  sgdisk --backup="${PARTITION_TABLE_BACKUP}" "${TARGET_DISK}"
  chmod 0600 "${PARTITION_TABLE_BACKUP}"
  log_info "Partition table backed up before dual boot installation: ${PARTITION_TABLE_BACKUP}"
  log_warn "Formatting selected Linux root partition only: ${ROOT_PART}"
  mkfs.ext4 -F -L "${TARGET_ROOT_LABEL}" "${ROOT_PART}"
  if [[ -n "${SWAP_PART}" ]]; then
    is_yes "${FORMAT_SWAP}" ||
      die "Configured swap partition requires FORMAT_SWAP=yes in manual-partition mode."
    swapoff "${SWAP_PART}" 2>/dev/null || true
    mkswap -f -L "${TARGET_SWAP_LABEL}" "${SWAP_PART}"
  fi
  mount_and_record_target
}

prepare_erase_disk_install() {
  local disk_boot_mode next_start_mib root_start_mib
  require_cmd parted
  require_cmd mkfs.fat

  if [[ "${TARGET_DISK}" == "auto" || -z "${TARGET_DISK}" ]]; then
    if is_yes "${DEVWORKS_MANUAL_CONFIRM_DISK}"; then
      select_target_disk_interactive
    else
      die "TARGET_DISK is auto but DEVWORKS_MANUAL_CONFIRM_DISK is not enabled."
    fi
  fi

  TARGET_DISK="$(canonical_block_device "${TARGET_DISK}")"
  log_info "Preparing disk ${TARGET_DISK}"
  [[ -b "${TARGET_DISK}" ]] || die "Target disk is not a block device: ${TARGET_DISK}"
  [[ "$(lsblk -dnro TYPE "${TARGET_DISK}" | xargs)" == "disk" ]] ||
    die "TARGET_DISK must be a whole disk in erase-disk mode: ${TARGET_DISK}"

  if detect_existing_operating_systems "${TARGET_DISK}"; then
    log_warn "Existing filesystem/OS signatures were detected on ${TARGET_DISK}."
    log_warn "Continue only if this is the intended empty or disposable target disk."
  fi

  if device_is_mounted "${TARGET_DISK}" && ! is_yes "${DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK}"; then
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "${TARGET_DISK}" || true
    die "Target disk has mounted partitions. Unmount them or verify the intended disposable target first."
  fi

  if is_yes "${DEVWORKS_MANUAL_CONFIRM_DISK}"; then
    confirm_destructive_disk_action
  elif ! is_yes "${DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK:-no}"; then
    die "Refusing to erase disk. Set DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK=yes only for a verified disposable disk."
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

  disk_boot_mode="$(resolve_boot_mode)"
  next_start_mib=$((TARGET_EFI_SIZE_MIB + 1))
  BIOS_PART=""
  if [[ "${disk_boot_mode}" == "bios" ]]; then
    parted -s "${TARGET_DISK}" mkpart BIOSBOOT "${next_start_mib}MiB" "$((next_start_mib + 2))MiB"
    parted -s "${TARGET_DISK}" set 2 bios_grub on
    BIOS_PART="$(disk_part_prefix "${TARGET_DISK}")2"
    next_start_mib=$((next_start_mib + 2))
  fi

  root_start_mib="${next_start_mib}"
  if [[ "${TARGET_SWAP_SIZE_MIB}" -gt 0 ]]; then
    parted -s "${TARGET_DISK}" mkpart primary linux-swap "${root_start_mib}MiB" "$((root_start_mib + TARGET_SWAP_SIZE_MIB))MiB"
    parted -s "${TARGET_DISK}" mkpart primary ext4 "$((root_start_mib + TARGET_SWAP_SIZE_MIB))MiB" 100%
    EFI_PART="$(disk_part_prefix "${TARGET_DISK}")1"
    if [[ -n "${BIOS_PART}" ]]; then
      SWAP_PART="$(disk_part_prefix "${TARGET_DISK}")3"
      ROOT_PART="$(disk_part_prefix "${TARGET_DISK}")4"
    else
      SWAP_PART="$(disk_part_prefix "${TARGET_DISK}")2"
      ROOT_PART="$(disk_part_prefix "${TARGET_DISK}")3"
    fi
  else
    parted -s "${TARGET_DISK}" mkpart primary ext4 "${root_start_mib}MiB" 100%
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

  mkfs.fat -F32 -n "${TARGET_EFI_LABEL}" "${EFI_PART}"
  mkfs.ext4 -F -L "${TARGET_ROOT_LABEL}" "${ROOT_PART}"
  if [[ -n "${SWAP_PART}" ]]; then
    mkswap -L "${TARGET_SWAP_LABEL}" "${SWAP_PART}"
  fi
  mount_and_record_target
}

case "${INSTALL_MODE}" in
  erase-disk)
    prepare_erase_disk_install
    ;;
  manual-partition)
    prepare_manual_partition_install
    ;;
  *)
    die "Unsupported INSTALL_MODE=${INSTALL_MODE}. Supported modes: erase-disk, manual-partition."
    ;;
esac
