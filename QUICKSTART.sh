#!/usr/bin/env bash
# Quick start guide - copy this and run on a Debian/Ubuntu VM manually

echo "====== Devworks Server OS - Manual Setup ======"
echo ""
echo "This script should be run on a fresh Debian 12 Stable VM"
echo ""

if [ ! -d "scripts" ]; then
    echo "ERROR: Run this from the project root directory"
    exit 1
fi

set -euo pipefail

echo "[1/4] Bootstrap base server packages..."
sudo bash scripts/bootstrap-server.sh

echo "[2/4] Hardening system security..."
sudo bash scripts/harden-system.sh

echo "[3/4] Installing container runtime..."
sudo bash scripts/install-container-runtime.sh

echo "[4/4] Installing Admin UI service..."
sudo bash scripts/install-admin-ui-service.sh

echo ""
echo "====== Setup Complete! ======"
echo ""
echo "Admin UI is running at: http://localhost:8088"
echo "Find your IP: hostname -I"
echo ""
echo "Check service status:"
echo "  systemctl status devworks-admin-ui"
echo ""
echo "View logs:"
echo "  journalctl -u devworks-admin-ui -f"
echo ""
