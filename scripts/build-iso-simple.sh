#!/usr/bin/env bash
# Alternative ISO builder using prebuilt Debian ISO + customization
# This avoids the live-build complexity when building from Windows/WSL

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="/tmp/devworks-iso-build-$$"
DEBIAN_ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-12.8.0-amd64-DVD-1.iso"
OUTPUT_ISO="${PROJECT_DIR}/dist/devworks-server-os.iso"

mkdir -p "${WORK_DIR}" "${PROJECT_DIR}/dist"
cd "${WORK_DIR}"

echo "[*] Downloading Debian ISO (this may take a few minutes)..."
if ! command -v wget &> /dev/null; then
    apt-get update && apt-get install -y wget
fi
wget -q -O debian.iso "${DEBIAN_ISO_URL}"

echo "[*] Extracting ISO..."
mkdir -p extracted modified-iso
cd extracted
# Extract ISO using xorriso if available, otherwise use bsdtar or 7z
if command -v xorriso &> /dev/null; then
    xorriso -osirrox on -indev ../debian.iso -extract / .
elif command -v 7z &> /dev/null; then
    7z x ../debian.iso > /dev/null
else
    apt-get install -y xorriso
    xorriso -osirrox on -indev ../debian.iso -extract / .
fi

echo "[*] Adding Devworks admin UI..."
mkdir -p modified-iso/opt/devworks/admin-ui
cp -r "${PROJECT_DIR}/admin-ui/"* modified-iso/opt/devworks/admin-ui/
mkdir -p modified-iso/etc/systemd/system
cp "${PROJECT_DIR}/services/devworks-admin-ui.service" modified-iso/etc/systemd/system/

echo "[*] Creating modified ISO..."
xorriso -as mkisofs \
    -o "${OUTPUT_ISO}" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux.cat \
    -b isolinux.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e boot/efiboot.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -volid "DEVWORKS" \
    modified-iso/

echo "[*] Cleaning up..."
cd "${PROJECT_DIR}"
rm -rf "${WORK_DIR}"

echo "[✓] ISO created: ${OUTPUT_ISO}"
echo "[✓] Size: $(du -h "${OUTPUT_ISO}" | cut -f1)"
