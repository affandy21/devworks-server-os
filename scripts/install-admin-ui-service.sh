#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/install-admin-ui-service.sh" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install -d -m 0755 /opt/devworks/admin-ui
rsync -a --delete "${PROJECT_DIR}/admin-ui/" /opt/devworks/admin-ui/
chown -R www-data:www-data /opt/devworks/admin-ui

install -D -m 0644 "${PROJECT_DIR}/services/devworks-admin-ui.service" /etc/systemd/system/devworks-admin-ui.service
systemctl daemon-reload
systemctl enable --now devworks-admin-ui

echo "Devworks Admin UI is running on port 8088."

