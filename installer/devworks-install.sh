#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"
MODULE_DIR="${SCRIPT_DIR}/modules"
STAGE_FROM=""
STAGE_TO=""

usage() {
  cat <<'EOF'
Usage:
  sudo bash installer/devworks-install.sh --config installer/config.env
  sudo bash installer/devworks-install.sh --config installer/profiles/virtualbox.env
  sudo bash installer/devworks-install.sh --config installer/profiles/dualboot-manual.env

Options:
  --config PATH     Config file to source.
  --from STAGE      Start at module stage number, e.g. 04.
  --to STAGE        Stop after module stage number, e.g. 06.
  --help            Show this help.

Important:
  INSTALL_MODE=erase-disk erases TARGET_DISK.
  INSTALL_MODE=manual-partition formats only TARGET_ROOT_PARTITION, preserves
  TARGET_EFI_PARTITION, and requires typed confirmation in an UEFI boot.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG_FILE="$2"; shift 2 ;;
    --from) STAGE_FROM="$2"; shift 2 ;;
    --to) STAGE_TO="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash installer/devworks-install.sh --config installer/config.env" >&2
  exit 1
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "Config not found: ${CONFIG_FILE}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "${CONFIG_FILE}"

export SCRIPT_DIR PROJECT_DIR CONFIG_FILE MODULE_DIR STAGE_FROM STAGE_TO

# shellcheck source=modules/00-lib.sh
source "${MODULE_DIR}/00-lib.sh"

main() {
  devworks_init
  require_root
  log_section "Devworks Server OS permanent installer"
  log_info "Project directory: ${PROJECT_DIR}"
  log_info "Config file: ${CONFIG_FILE}"
  log_info "Target disk: ${TARGET_DISK:-unset}"
  log_info "Install root: ${INSTALL_ROOT}"

  run_module "01" "disk" "${MODULE_DIR}/01-disk.sh"
  run_module "02" "base-system" "${MODULE_DIR}/02-base-system.sh"
  run_module "03" "users" "${MODULE_DIR}/03-users.sh"
  run_module "04" "network-ssh" "${MODULE_DIR}/04-network-ssh.sh"
  run_module "05" "firewall-tls" "${MODULE_DIR}/05-firewall-tls.sh"
  run_module "06" "services-web-ai" "${MODULE_DIR}/06-services-web-ai.sh"
  run_module "07" "security-updates" "${MODULE_DIR}/07-security-updates.sh"
  run_module "08" "grub-recovery" "${MODULE_DIR}/08-grub-recovery.sh"
  run_module "09" "gui-monitoring" "${MODULE_DIR}/09-gui-monitoring.sh"
  run_module "10" "validate" "${MODULE_DIR}/10-validate.sh"

  log_section "Installation complete"
  log_info "Log file: ${LOG_FILE}"
  if [[ "${POST_INSTALL_REBOOT:-no}" == "yes" ]]; then
    log_warn "POST_INSTALL_REBOOT=yes; rebooting in 10 seconds."
    sleep 10
    reboot
  else
    log_info "Reboot manually after reviewing the log:"
    log_info "  reboot"
  fi
}

main "$@"
