#!/usr/bin/env bash
# Download Debian ISO for quick VirtualBox testing
# This bypasses the complex live-build process

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${PROJECT_DIR}/dist"

ISO_PATH="${PROJECT_DIR}/dist/debian-12-netinstall.iso"
DEBIAN_ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.8.0-amd64-netinst.iso"

if [ -f "${ISO_PATH}" ]; then
    echo "[✓] ISO already exists: ${ISO_PATH}"
    ls -lh "${ISO_PATH}"
    exit 0
fi

echo "[*] Downloading Debian 12 netinstall ISO (small, quick)..."
echo "[*] URL: ${DEBIAN_ISO_URL}"

if ! command -v wget &> /dev/null; then
    echo "[!] wget not found, installing..."
    apt-get update && apt-get install -y wget
fi

cd "${PROJECT_DIR}/dist"
wget -q --show-progress -O debian-12-netinstall.iso "${DEBIAN_ISO_URL}"

echo "[✓] ISO downloaded: ${ISO_PATH}"
echo "[✓] Size: $(du -h "${ISO_PATH}" | cut -f1)"
echo ""
echo "Next steps:"
echo "  1. Create VirtualBox VM with this ISO"
echo "  2. Boot and install Debian 12 Stable"
echo "  3. Run: sudo bash /path/to/scripts/bootstrap-server.sh"
echo "  4. Run: sudo bash /path/to/scripts/harden-system.sh"
echo "  5. Run: sudo bash /path/to/scripts/install-admin-ui-service.sh"
