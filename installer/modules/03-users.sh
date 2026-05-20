#!/usr/bin/env bash

: "${ADMIN_USER:=devworks}"
: "${ADMIN_FULL_NAME:=Devworks Administrator}"
: "${ADMIN_PASSWORD_HASH:?ADMIN_PASSWORD_HASH is required}"
: "${ADMIN_SUDO_NOPASSWD:=no}"
: "${ENABLE_AUTOLOGIN:=no}"
: "${AUTOLOGIN_USER:=${ADMIN_USER}}"

log_info "Configuring admin user ${ADMIN_USER}"

if ! chroot_run id "${ADMIN_USER}" >/dev/null 2>&1; then
  chroot_run useradd -m -s /bin/bash -c "${ADMIN_FULL_NAME}" "${ADMIN_USER}"
fi

echo "${ADMIN_USER}:${ADMIN_PASSWORD_HASH}" | chroot "${INSTALL_ROOT}" chpasswd -e
chroot_run usermod -aG sudo,adm,systemd-journal "${ADMIN_USER}"

if is_yes "${ADMIN_SUDO_NOPASSWD}"; then
  cat > "${INSTALL_ROOT}/etc/sudoers.d/90-devworks-admin" <<EOF
${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL
EOF
else
  cat > "${INSTALL_ROOT}/etc/sudoers.d/90-devworks-admin" <<EOF
${ADMIN_USER} ALL=(ALL:ALL) ALL
EOF
fi
chmod 0440 "${INSTALL_ROOT}/etc/sudoers.d/90-devworks-admin"

install -d -m 0700 -o 1000 -g 1000 "${INSTALL_ROOT}/home/${ADMIN_USER}/.ssh"
if [[ -n "${SSH_AUTHORIZED_KEYS_FILE:-}" && -f "${SSH_AUTHORIZED_KEYS_FILE}" ]]; then
  install -m 0600 -o 1000 -g 1000 "${SSH_AUTHORIZED_KEYS_FILE}" "${INSTALL_ROOT}/home/${ADMIN_USER}/.ssh/authorized_keys"
fi

if is_yes "${ENABLE_AUTOLOGIN}"; then
  mkdir -p "${INSTALL_ROOT}/etc/lightdm/lightdm.conf.d"
  cat > "${INSTALL_ROOT}/etc/lightdm/lightdm.conf.d/50-devworks-autologin.conf" <<EOF
[Seat:*]
autologin-user=${AUTOLOGIN_USER}
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
EOF
  log_warn "Autologin enabled for ${AUTOLOGIN_USER}. Disable for production bare metal."
else
  rm -f "${INSTALL_ROOT}/etc/lightdm/lightdm.conf.d/50-devworks-autologin.conf"
fi

log_info "User configuration complete."
