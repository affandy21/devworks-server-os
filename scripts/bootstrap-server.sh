#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/bootstrap-server.sh" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export DEBIAN_FRONTEND=noninteractive

install_package_list() {
  local package_file="$1"
  grep -Ev '^\s*(#|$)' "${package_file}" | xargs apt-get install -y
}

apt-get update
install_package_list "${PROJECT_DIR}/config/packages.base.list"
install_package_list "${PROJECT_DIR}/config/packages.web.list"
install_package_list "${PROJECT_DIR}/config/packages.ai.list"

install -D -m 0644 "${PROJECT_DIR}/config/sysctl.d/99-devworks-server.conf" /etc/sysctl.d/99-devworks-server.conf
sysctl --system

systemctl enable --now ssh
systemctl enable --now nginx
systemctl enable --now fail2ban
systemctl enable --now chrony

echo "Devworks base server bootstrap complete."
