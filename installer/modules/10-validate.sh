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
chroot_run systemctl is-enabled ssh
chroot_run test -f /etc/sysctl.d/98-devworks-production-hardening.conf
chroot_run test -x /usr/local/sbin/devworks
chroot_run test -L /usr/local/sbin/dw
if chroot_run bash -c 'command -v nginx >/dev/null 2>&1'; then
  chroot_run nginx -t
fi

if [[ "${SSH_PASSWORD_AUTH:-yes}" == "no" ]]; then
  chroot_run grep -R "^PasswordAuthentication no" /etc/ssh/sshd_config.d
fi

if [[ "${ENABLE_AUTOLOGIN:-no}" == "no" ]]; then
  chroot_run test ! -f /etc/lightdm/lightdm.conf.d/50-devworks-autologin.conf
fi

if is_yes "${ENABLE_UFW:-yes}"; then
  chroot_run ufw status verbose || true
fi

if is_yes "${ENABLE_WEB_STACK:-no}"; then
  chroot_run systemctl is-enabled nginx
else
  chroot_run bash -c '! systemctl is-enabled nginx >/dev/null 2>&1'
fi

if is_yes "${ENABLE_AI_RUNTIME:-no}"; then
  chroot_run systemctl is-enabled "${AI_SERVICE_NAME}.service"
else
  chroot_run bash -c '! systemctl is-enabled devworks-ai.service >/dev/null 2>&1'
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
Default workload policy: web/AI/container services disabled until user opt-in
EOF

log_info "Validation complete."
