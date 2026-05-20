#!/usr/bin/env bash

: "${TARGET_BOOT_MODE:=auto}"
: "${GRUB_TIMEOUT:=5}"
: "${GRUB_CMDLINE_LINUX_DEFAULT:=quiet}"
: "${ENABLE_GRUB_RECOVERY:=yes}"

[[ -f "${STATE_DIR}/disk.env" ]] || die "disk.env missing. Run disk module first."
# shellcheck source=/dev/null
source "${STATE_DIR}/disk.env"

log_info "Installing GRUB bootloader"
mount_chroot_api

cat > "${INSTALL_ROOT}/etc/default/grub" <<EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=${GRUB_TIMEOUT}
GRUB_DISTRIBUTOR="Devworks Server OS"
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT}"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_RECOVERY=false
EOF

boot_mode="${TARGET_BOOT_MODE}"
if [[ "${boot_mode}" == "auto" ]]; then
  if [[ -d /sys/firmware/efi ]]; then
    boot_mode="efi"
  else
    boot_mode="bios"
  fi
fi

case "${boot_mode}" in
  efi)
    chroot_run grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Devworks --recheck
    ;;
  bios)
    chroot_run grub-install --target=i386-pc "${TARGET_DISK}"
    ;;
  *)
    die "Unsupported TARGET_BOOT_MODE: ${TARGET_BOOT_MODE}"
    ;;
esac

chroot_run update-initramfs -u -k all
chroot_run update-grub

mkdir -p "${INSTALL_ROOT}/boot/devworks"
cat > "${INSTALL_ROOT}/boot/devworks/RECOVERY.txt" <<'EOF'
Devworks Server OS recovery notes

1. At GRUB, choose "Advanced options for Devworks Server OS".
2. Select a recovery mode kernel.
3. For root shell, remount root read-write:
   mount -o remount,rw /
4. Check failed services:
   systemctl --failed
5. Repair network:
   systemctl restart NetworkManager ssh
6. Review logs:
   journalctl -xb
EOF

log_info "GRUB installed in ${boot_mode} mode."
