#!/usr/bin/env bash
set -Eeuo pipefail

ISO_PATH="${1:-dist/devworks-server-os.iso}"
WORK_DIR="$(mktemp -d /tmp/devworks-iso-verify.XXXXXX)"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

for command in xorriso unsquashfs dpkg-query grep; do
  command -v "${command}" >/dev/null 2>&1 || {
    echo "Missing verification command: ${command}" >&2
    exit 1
  }
done

[[ -f "${ISO_PATH}" ]] || {
  echo "ISO not found: ${ISO_PATH}" >&2
  exit 1
}

xorriso -osirrox on -indev "${ISO_PATH}" \
  -extract /live/filesystem.squashfs "${WORK_DIR}/filesystem.squashfs" >/dev/null 2>&1
unsquashfs -no-progress -d "${WORK_DIR}/root" "${WORK_DIR}/filesystem.squashfs" >/dev/null

ROOT="${WORK_DIR}/root"
grep -Fq 'VERSION_ID="0.2.1"' "${ROOT}/etc/os-release"
grep -Fxq 'INSTALL_MODE="manual-partition"' "${ROOT}/opt/devworks/installer/profiles/dualboot-manual.env"
grep -Fxq 'FORMAT_EFI="no"' "${ROOT}/opt/devworks/installer/profiles/dualboot-manual.env"
grep -Fq 'FORMAT_EFI=yes is forbidden in manual-partition mode' "${ROOT}/opt/devworks/installer/modules/01-disk.sh"
grep -Fq "menuentry 'Windows Boot Manager'" "${ROOT}/opt/devworks/installer/modules/08-grub-recovery.sh"
grep -Fq -- '--no-nvram --removable' "${ROOT}/opt/devworks/installer/modules/08-grub-recovery.sh"
test -x "${ROOT}/opt/devworks/scripts/devworks"
test -x "${ROOT}/opt/devworks/installer/devworks-installer-wizard.sh"
test -x "${ROOT}/usr/local/sbin/devworks-installer"
test -x "${ROOT}/usr/local/sbin/install-devworks-os"
grep -Fq 'Target disk:' "${ROOT}/opt/devworks/installer/devworks-installer-wizard.sh"
grep -Fq 'Web service:       disabled until user enables it' "${ROOT}/opt/devworks/installer/devworks-installer-wizard.sh"
grep -Fq 'ln -sfn ../sbin/devworks "${INSTALL_ROOT}/usr/local/bin/devworks"' "${ROOT}/opt/devworks/installer/modules/06-services-web-ai.sh"
grep -Fq 'ln -sfn ../sbin/devworks "${INSTALL_ROOT}/usr/local/bin/dw"' "${ROOT}/opt/devworks/installer/modules/06-services-web-ai.sh"
grep -Fxq 'Exec=/opt/devworks/control-center/devworks-control-center' "${ROOT}/usr/share/applications/devworks-control-center.desktop"
grep -Fxq 'Exec=/usr/local/bin/devworks-trust-launchers' "${ROOT}/etc/xdg/autostart/devworks-trust-launchers.desktop"
test -x "${ROOT}/usr/local/bin/devworks-trust-launchers"

for package in firmware-amd-graphics firmware-misc-nonfree firmware-nvidia-gsp intel-microcode amd64-microcode libglib2.0-bin libgtk-3-bin desktop-file-utils; do
  dpkg-query --admindir="${ROOT}/var/lib/dpkg" -W -f='${db:Status-Status}\n' "${package}" 2>/dev/null | grep -Fxq installed
done

[[ ! -e "${ROOT}/etc/systemd/system/multi-user.target.wants/nginx.service" ]]
[[ ! -e "${ROOT}/etc/systemd/system/multi-user.target.wants/devworks-admin-ui.service" ]]
[[ ! -e "${ROOT}/etc/systemd/system/multi-user.target.wants/fail2ban.service" ]]
[[ "$(readlink "${ROOT}/etc/systemd/system/nginx.service")" == "/dev/null" ]]
[[ "$(readlink "${ROOT}/etc/systemd/system/devworks-admin-ui.service")" == "/dev/null" ]]
[[ "$(readlink "${ROOT}/etc/systemd/system/fail2ban.service")" == "/dev/null" ]]

xorriso -osirrox on -indev "${ISO_PATH}" \
  -extract /isolinux/splash.png "${WORK_DIR}/splash.png" >/dev/null 2>&1
[[ -s "${WORK_DIR}/splash.png" ]]

echo "ISO content verification passed: dual boot guards, native GUI launcher, firmware, version, splash, and opt-in workload policy are present."
