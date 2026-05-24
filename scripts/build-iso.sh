#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root on a Debian builder: sudo bash scripts/build-iso.sh" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_DIR="${PROJECT_DIR}/iso"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y live-build ca-certificates rsync

rsync -a --delete "${PROJECT_DIR}/admin-ui/" "${ISO_DIR}/config/includes.chroot/opt/devworks/admin-ui/"
rsync -a --delete "${PROJECT_DIR}/installer/" "${ISO_DIR}/config/includes.chroot/opt/devworks/installer/"
find "${ISO_DIR}/config/includes.chroot/opt/devworks/installer" -type f -name '*.sh' -exec chmod +x {} +
chmod +x "${ISO_DIR}/config/includes.chroot/opt/devworks/installer/devworks-install.sh"
install -D -m 0644 "${PROJECT_DIR}/services/devworks-admin-ui.service" \
  "${ISO_DIR}/config/includes.chroot/etc/systemd/system/devworks-admin-ui.service"
chmod +x "${ISO_DIR}/auto/config"
find "${ISO_DIR}/config/hooks/normal" -maxdepth 1 -type f -name '*.chroot' -exec chmod +x {} +

cd "${ISO_DIR}"
lb clean
lb config \
  --mode debian \
  --distribution bookworm \
  --archive-areas "main contrib non-free-firmware" \
  --binary-images iso-hybrid \
  --debian-installer live \
  --security false \
  --apt-indices false \
  --iso-application "Devworks Server OS" \
  --iso-publisher "Devworks Server OS project; https://github.com/affandy21/devworks-server-os" \
  --iso-volume "Devworks Server OS 0.1.1" \
  --bootappend-live "boot=live components hostname=devworks-server username=devworks user-fullname=Devworks"
lb build

mkdir -p "${PROJECT_DIR}/dist"
cp -f ./*.hybrid.iso "${PROJECT_DIR}/dist/devworks-server-os.iso"

echo "ISO created: ${PROJECT_DIR}/dist/devworks-server-os.iso"
