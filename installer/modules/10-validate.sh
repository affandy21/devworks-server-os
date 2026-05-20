#!/usr/bin/env bash

: "${VALIDATE_RETRY_COUNT:=30}"
: "${VALIDATE_RETRY_SLEEP:=2}"

log_info "Running target validation"

mount_chroot_api

if [[ -f "${PROJECT_DIR}/installer/tests/validation-checklist.sh" ]]; then
  install -D -m 0755 "${PROJECT_DIR}/installer/tests/validation-checklist.sh" \
    "${INSTALL_ROOT}/usr/local/sbin/devworks-validation-checklist"
fi

chroot_run test -f /etc/os-release
chroot_run test -f /boot/grub/grub.cfg
chroot_run id "${ADMIN_USER}"
chroot_run visudo -cf /etc/sudoers
chroot_run sshd -t
chroot_run nginx -t
chroot_run systemctl is-enabled ssh
chroot_run systemctl is-enabled nginx

if is_yes "${ENABLE_UFW:-yes}"; then
  chroot_run ufw status verbose || true
fi

if is_yes "${ENABLE_WEB_STACK:-yes}"; then
  chroot_run systemctl is-enabled "${WEB_SERVICE_NAME}.service"
fi

if is_yes "${ENABLE_AI_RUNTIME:-yes}"; then
  chroot_run systemctl is-enabled "${AI_SERVICE_NAME}.service"
fi

if is_yes "${ENABLE_GUI:-yes}"; then
  chroot_run systemctl is-enabled lightdm
  chroot_run test -f /usr/local/bin/devworks-open-admin
  chroot_run test -f /usr/share/applications/devworks-control-center.desktop
  chroot_run test -f /etc/skel/Desktop/devworks-control-center.desktop
  chroot_run test -f "/home/${ADMIN_USER}/Desktop/devworks-control-center.desktop"
  chroot_run test ! -f /etc/xdg/autostart/devworks-admin.desktop
fi

cat > "${INSTALL_ROOT}/root/devworks-validation.txt" <<EOF
Devworks validation completed at $(date -Is)
Hostname: ${DEVWORKS_HOSTNAME}
Admin user: ${ADMIN_USER}
SSH port: ${SSH_PORT}
UFW enabled: ${ENABLE_UFW:-yes}
GUI enabled: ${ENABLE_GUI:-yes}
Web service: ${WEB_SERVICE_NAME:-devworks-web}
AI service: ${AI_SERVICE_NAME:-devworks-ai}
EOF

log_info "Validation complete."
