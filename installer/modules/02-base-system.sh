#!/usr/bin/env bash

require_cmd debootstrap
require_cmd mount

: "${DEBIAN_RELEASE:=bookworm}"
: "${DEBIAN_MIRROR:=http://deb.debian.org/debian}"
: "${DEBIAN_SECURITY_MIRROR:=http://security.debian.org/debian-security}"
: "${APT_COMPONENTS:=main contrib non-free-firmware}"
: "${DEVWORKS_HOSTNAME:=devworks-server}"
: "${DEVWORKS_PRETTY_NAME:=Devworks Server OS}"
: "${TIMEZONE:=Asia/Jakarta}"
: "${LOCALE:=en_US.UTF-8}"
: "${KEYMAP:=us}"

[[ -f "${STATE_DIR}/disk.env" ]] || die "disk.env missing. Run disk module first."
# shellcheck source=/dev/null
source "${STATE_DIR}/disk.env"

log_info "Installing Debian base system (${DEBIAN_RELEASE}) into ${INSTALL_ROOT}"
debootstrap --arch=amd64 --components="${APT_COMPONENTS// /,}" "${DEBIAN_RELEASE}" "${INSTALL_ROOT}" "${DEBIAN_MIRROR}"

mount_chroot_api

cat > "${INSTALL_ROOT}/etc/apt/sources.list" <<EOF
deb ${DEBIAN_MIRROR} ${DEBIAN_RELEASE} ${APT_COMPONENTS}
deb ${DEBIAN_MIRROR} ${DEBIAN_RELEASE}-updates ${APT_COMPONENTS}
deb ${DEBIAN_SECURITY_MIRROR} ${DEBIAN_RELEASE}-security ${APT_COMPONENTS}
EOF

cat > "${INSTALL_ROOT}/etc/fstab" <<EOF
UUID=${ROOT_UUID} / ext4 defaults,noatime,errors=remount-ro 0 1
UUID=${EFI_UUID} /boot/efi vfat umask=0077 0 1
EOF
if [[ -n "${SWAP_UUID}" ]]; then
  echo "UUID=${SWAP_UUID} none swap sw 0 0" >> "${INSTALL_ROOT}/etc/fstab"
fi

echo "${DEVWORKS_HOSTNAME}" > "${INSTALL_ROOT}/etc/hostname"
cat > "${INSTALL_ROOT}/etc/hosts" <<EOF
127.0.0.1 localhost
127.0.1.1 ${DEVWORKS_HOSTNAME}

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

chroot_run apt-get update
apt_install_target \
  linux-image-amd64 firmware-linux-free systemd-sysv dbus \
  ca-certificates curl wget gnupg lsb-release apt-transport-https \
  sudo vim nano less jq rsync git openssh-server \
  locales console-setup keyboard-configuration tzdata \
  chrony ufw fail2ban python3-systemd logrotate htop tmux sysstat smartmontools dosfstools

base_boot_mode="${TARGET_BOOT_MODE:-auto}"
if [[ "${base_boot_mode}" == "auto" ]]; then
  if [[ -d /sys/firmware/efi ]]; then
    base_boot_mode="efi"
  else
    base_boot_mode="bios"
  fi
fi

case "${base_boot_mode}" in
  bios)
    apt_install_target grub-pc grub-pc-bin
    ;;
  efi)
    apt_install_target grub-efi-amd64 grub-efi-amd64-bin shim-signed efibootmgr
    ;;
  *)
    die "Unsupported TARGET_BOOT_MODE for base packages: ${TARGET_BOOT_MODE}"
    ;;
esac

echo "${TIMEZONE}" > "${INSTALL_ROOT}/etc/timezone"
chroot_run ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
chroot_run dpkg-reconfigure -f noninteractive tzdata

sed -i "s/^# ${LOCALE} UTF-8/${LOCALE} UTF-8/" "${INSTALL_ROOT}/etc/locale.gen"
if ! grep -q "^${LOCALE} UTF-8" "${INSTALL_ROOT}/etc/locale.gen"; then
  echo "${LOCALE} UTF-8" >> "${INSTALL_ROOT}/etc/locale.gen"
fi
chroot_run locale-gen
echo "LANG=${LOCALE}" > "${INSTALL_ROOT}/etc/default/locale"
echo "XKBLAYOUT=\"${KEYMAP}\"" > "${INSTALL_ROOT}/etc/default/keyboard"

cat > "${INSTALL_ROOT}/etc/os-release" <<EOF
PRETTY_NAME="${DEVWORKS_PRETTY_NAME}"
NAME="Devworks Server OS"
VERSION_ID="1.0"
VERSION="1.0"
ID=devworks
ID_LIKE=debian
HOME_URL="https://devworks.local"
SUPPORT_URL="https://devworks.local"
BUG_REPORT_URL="https://devworks.local"
EOF

cat > "${INSTALL_ROOT}/etc/issue" <<EOF
Devworks Server OS \\n \\l

EOF

log_info "Base system installed."
