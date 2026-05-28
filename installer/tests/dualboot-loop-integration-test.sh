#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d /tmp/devworks-dualboot-test.XXXXXX)"
DISK_IMAGE="${TEST_ROOT}/dualboot-test.img"
LOOP_DEV=""
CREATED_PART_NODES=()

cleanup() {
  set +e
  umount -lf "${TEST_ROOT}/install/boot/efi" 2>/dev/null || true
  umount -lf "${TEST_ROOT}/install" 2>/dev/null || true
  if ((${#CREATED_PART_NODES[@]} > 0)); then
    rm -f "${CREATED_PART_NODES[@]}"
  fi
  [[ -n "${LOOP_DEV}" ]] && losetup -d "${LOOP_DEV}" 2>/dev/null || true
  rm -rf "${TEST_ROOT}"
}
trap cleanup EXIT

for command in losetup parted mkfs.fat mkfs.ext4 sgdisk blkid lsblk mount; do
  command -v "${command}" >/dev/null 2>&1 || {
    echo "Missing integration test command: ${command}" >&2
    exit 1
  }
done

truncate -s 768M "${DISK_IMAGE}"
LOOP_DEV="$(losetup --find --show --partscan "${DISK_IMAGE}")"
parted -s "${LOOP_DEV}" mklabel gpt
parted -s "${LOOP_DEV}" mkpart ESP fat32 1MiB 129MiB
parted -s "${LOOP_DEV}" set 1 esp on
parted -s "${LOOP_DEV}" mkpart WINDOWS ntfs 129MiB 385MiB
parted -s "${LOOP_DEV}" mkpart DEVWORKS ext4 385MiB 100%
partprobe "${LOOP_DEV}"
udevadm settle || true

part_prefix="${LOOP_DEV}"
[[ "${LOOP_DEV}" =~ [0-9]$ ]] && part_prefix="${LOOP_DEV}p"
EFI_PART="${part_prefix}1"
WINDOWS_PART="${part_prefix}2"
ROOT_PART="${part_prefix}3"

create_missing_part_node() {
  local part_node="$1"
  local part_name="${part_node##*/}"
  local major_minor major minor

  [[ -b "${part_node}" ]] && return 0
  major_minor="$(lsblk -nr -o NAME,MAJ:MIN "${LOOP_DEV}" | awk -v name="${part_name}" '$1 == name { print $2; exit }')"
  [[ -n "${major_minor}" ]] || {
    echo "Kernel did not expose test partition ${part_name}." >&2
    exit 1
  }
  major="${major_minor%%:*}"
  minor="${major_minor##*:}"
  mknod "${part_node}" b "${major}" "${minor}"
  CREATED_PART_NODES+=("${part_node}")
}

create_missing_part_node "${EFI_PART}"
create_missing_part_node "${WINDOWS_PART}"
create_missing_part_node "${ROOT_PART}"

mkfs.fat -F32 -n SYSTEM "${EFI_PART}" >/dev/null
mkfs.ext4 -F -L WINDOWS_DATA "${WINDOWS_PART}" >/dev/null
mkfs.ext4 -F -L OLD_ROOT "${ROOT_PART}" >/dev/null
windows_uuid_before="$(blkid -s UUID -o value "${WINDOWS_PART}")"

mkdir -p "${TEST_ROOT}/esp"
mount "${EFI_PART}" "${TEST_ROOT}/esp"
mkdir -p "${TEST_ROOT}/esp/EFI/Microsoft/Boot"
printf 'preserve-this-loader\n' > "${TEST_ROOT}/esp/EFI/Microsoft/Boot/bootmgfw.efi"
umount "${TEST_ROOT}/esp"

# shellcheck source=../modules/00-lib.sh
source "${PROJECT_DIR}/installer/modules/00-lib.sh"
INSTALL_ROOT="${TEST_ROOT}/install"
EFI_ROOT="${INSTALL_ROOT}/boot/efi"
STATE_DIR="${TEST_ROOT}/state"
mkdir -p "${STATE_DIR}"
INSTALL_MODE="manual-partition"
TARGET_BOOT_MODE="efi"
TARGET_ROOT_PARTITION="${ROOT_PART}"
TARGET_EFI_PARTITION="${EFI_PART}"
TARGET_SWAP_PARTITION=""
FORMAT_ROOT="yes"
FORMAT_EFI="no"
DEVWORKS_MANUAL_CONFIRM_DISK="yes"
TARGET_ROOT_LABEL="DEVWORKS_ROOT"

# shellcheck source=../modules/01-disk.sh
source "${PROJECT_DIR}/installer/modules/01-disk.sh" <<< "INSTALL ${ROOT_PART} KEEP-EFI ${EFI_PART}"

[[ "$(blkid -s LABEL -o value "${ROOT_PART}")" == "DEVWORKS_ROOT" ]]
[[ "$(blkid -s UUID -o value "${WINDOWS_PART}")" == "${windows_uuid_before}" ]]
[[ -f "${INSTALL_ROOT}/boot/efi/EFI/Microsoft/Boot/bootmgfw.efi" ]]
grep -Fxq 'preserve-this-loader' "${INSTALL_ROOT}/boot/efi/EFI/Microsoft/Boot/bootmgfw.efi"
find "${INSTALL_ROOT}/var/backups/devworks-installer" -name 'partition-table-before-dualboot-*.gpt' -print -quit | grep -q .

cleanup_mounts

if (
  INSTALL_ROOT="${TEST_ROOT}/reject-install"
  EFI_ROOT="${INSTALL_ROOT}/boot/efi"
  STATE_DIR="${TEST_ROOT}/reject-state"
  mkdir -p "${STATE_DIR}"
  INSTALL_MODE="manual-partition"
  TARGET_BOOT_MODE="efi"
  TARGET_ROOT_PARTITION="${WINDOWS_PART}"
  TARGET_EFI_PARTITION="${EFI_PART}"
  FORMAT_ROOT="yes"
  FORMAT_EFI="no"
  DEVWORKS_MANUAL_CONFIRM_DISK="yes"
  source "${PROJECT_DIR}/installer/modules/01-disk.sh" <<< "INSTALL ${WINDOWS_PART} KEEP-EFI ${EFI_PART}"
); then
  echo "Installer unexpectedly accepted a Microsoft data partition as root." >&2
  exit 1
fi

[[ "$(blkid -s UUID -o value "${WINDOWS_PART}")" == "${windows_uuid_before}" ]]
echo "Dual boot loop-device integration test passed."
