#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DISK_MODULE="${PROJECT_DIR}/installer/modules/01-disk.sh"
GRUB_MODULE="${PROJECT_DIR}/installer/modules/08-grub-recovery.sh"
PROFILE="${PROJECT_DIR}/installer/profiles/dualboot-manual.env"

grep -Fq 'manual-partition)' "${DISK_MODULE}"
grep -Fq 'FORMAT_EFI=yes is forbidden in manual-partition mode' "${DISK_MODULE}"
grep -Fq 'INSTALL_MODE=manual-partition supports UEFI dual boot only' "${DISK_MODULE}"
grep -Fq 'Refusing to format ${ROOT_PART}' "${DISK_MODULE}"
grep -Fq 'is not marked as an EFI System Partition' "${DISK_MODULE}"
grep -Fq 'partition-table-before-dualboot-' "${DISK_MODULE}"
grep -Fq 'Microsoft EFI loader detected' "${GRUB_MODULE}"
grep -Fq 'menuentry '\''Windows Boot Manager'\''' "${GRUB_MODULE}"
grep -Fxq 'INSTALL_MODE="manual-partition"' "${PROFILE}"
grep -Fxq 'FORMAT_EFI="no"' "${PROFILE}"
grep -Fxq 'DEVWORKS_MANUAL_CONFIRM_DISK="yes"' "${PROFILE}"

echo "Dual boot static safety checks passed."
