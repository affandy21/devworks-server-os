#!/usr/bin/env bash

: "${SSH_PORT:=22}"
: "${SSH_PASSWORD_AUTH:=yes}"
: "${SSH_PERMIT_ROOT_LOGIN:=no}"
: "${SSH_ALLOW_USERS:=${ADMIN_USER}}"
: "${SSH_DISABLE_EMPTY_PASSWORDS:=yes}"
: "${SSH_MAX_AUTH_TRIES:=4}"

log_info "Configuring networking and SSH"

apt_install_target network-manager
chroot_run systemctl enable NetworkManager
chroot_run systemctl enable ssh
chroot_run systemctl enable chrony

mkdir -p "${INSTALL_ROOT}/etc/ssh/sshd_config.d"
cat > "${INSTALL_ROOT}/etc/ssh/sshd_config.d/90-devworks.conf" <<EOF
Port ${SSH_PORT}
PermitRootLogin ${SSH_PERMIT_ROOT_LOGIN}
PasswordAuthentication ${SSH_PASSWORD_AUTH}
PermitEmptyPasswords $(is_yes "${SSH_DISABLE_EMPTY_PASSWORDS}" && printf 'no' || printf 'yes')
PubkeyAuthentication yes
KbdInteractiveAuthentication no
X11Forwarding no
AllowUsers ${SSH_ALLOW_USERS}
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries ${SSH_MAX_AUTH_TRIES}
LoginGraceTime 30
EOF

cat > "${INSTALL_ROOT}/etc/sysctl.d/98-devworks-production-hardening.conf" <<'EOF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
EOF

cat > "${INSTALL_ROOT}/etc/NetworkManager/conf.d/10-devworks.conf" <<'EOF'
[main]
dns=default

[connection]
wifi.powersave=2
EOF

log_info "SSH configured on port ${SSH_PORT}."
