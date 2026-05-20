#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/harden-system.sh" >&2
  exit 1
fi

sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?X11Forwarding .*/X11Forwarding no/' /etc/ssh/sshd_config
systemctl reload ssh

dpkg-reconfigure -f noninteractive unattended-upgrades

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 10.0.0.0/8 to any port 8088 proto tcp
ufw allow from 172.16.0.0/12 to any port 8088 proto tcp
ufw allow from 192.168.0.0/16 to any port 8088 proto tcp
ufw --force enable

echo "Devworks server hardening complete."

