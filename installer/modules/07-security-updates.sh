#!/usr/bin/env bash

: "${ENABLE_UNATTENDED_UPGRADES:=yes}"
: "${ENABLE_AUTO_REBOOT_AFTER_SECURITY_UPDATE:=no}"

log_info "Configuring security updates"

if is_yes "${ENABLE_UNATTENDED_UPGRADES}"; then
  apt_install_target unattended-upgrades apt-listchanges
  cat > "${INSTALL_ROOT}/etc/apt/apt.conf.d/20auto-upgrades" <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
  cat > "${INSTALL_ROOT}/etc/apt/apt.conf.d/50unattended-upgrades" <<EOF
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=\${distro_codename},label=Debian-Security";
        "origin=Debian,codename=\${distro_codename}-security,label=Debian-Security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::Automatic-Reboot "${ENABLE_AUTO_REBOOT_AFTER_SECURITY_UPDATE}";
Unattended-Upgrade::Automatic-Reboot-Time "03:30";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
  chroot_run systemctl enable unattended-upgrades
  chroot_run systemctl enable apt-daily.timer
  chroot_run systemctl enable apt-daily-upgrade.timer
fi

cat > "${INSTALL_ROOT}/etc/fail2ban/jail.local" <<'EOF'
[DEFAULT]
backend = systemd
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
journalmatch = _SYSTEMD_UNIT=ssh.service + _COMM=sshd
EOF
chroot_run systemctl enable fail2ban

cat > "${INSTALL_ROOT}/etc/logrotate.d/devworks" <<'EOF'
/var/log/devworks/*.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
    create 0640 root adm
}
EOF

mkdir -p "${INSTALL_ROOT}/var/log/devworks"
log_info "Security updates configured."
