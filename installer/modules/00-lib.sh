#!/usr/bin/env bash

INSTALL_ROOT="${INSTALL_ROOT:-/mnt/devworks}"
BOOT_ROOT="${BOOT_ROOT:-${INSTALL_ROOT}/boot}"
EFI_ROOT="${EFI_ROOT:-${BOOT_ROOT}/efi}"
LOG_DIR="${LOG_DIR:-/var/log/devworks-installer}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log}"
STATE_DIR="${STATE_DIR:-/var/lib/devworks-installer}"
CHROOT_ENV=(env DEBIAN_FRONTEND=noninteractive)

devworks_init() {
  mkdir -p "${LOG_DIR}" "${STATE_DIR}"
  touch "${LOG_FILE}"
  exec > >(tee -a "${LOG_FILE}") 2>&1
  trap 'log_error "Installer failed at line ${LINENO}. See ${LOG_FILE}"' ERR
}

log_ts() { date "+%Y-%m-%d %H:%M:%S"; }
log_info() { printf '[%s] [INFO] %s\n' "$(log_ts)" "$*"; }
log_warn() { printf '[%s] [WARN] %s\n' "$(log_ts)" "$*" >&2; }
log_error() { printf '[%s] [ERROR] %s\n' "$(log_ts)" "$*" >&2; }
log_section() { printf '\n[%s] === %s ===\n' "$(log_ts)" "$*"; }

die() {
  log_error "$*"
  exit 1
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "This command must run as root."
}

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

is_yes() {
  case "${1:-}" in
    yes|YES|true|TRUE|1) return 0 ;;
    *) return 1 ;;
  esac
}

stage_enabled() {
  local stage="$1"
  if [[ -n "${STAGE_FROM:-}" && "${stage}" < "${STAGE_FROM}" ]]; then
    return 1
  fi
  if [[ -n "${STAGE_TO:-}" && "${stage}" > "${STAGE_TO}" ]]; then
    return 1
  fi
  return 0
}

run_module() {
  local stage="$1"
  local name="$2"
  local file="$3"
  if ! stage_enabled "${stage}"; then
    log_info "Skipping ${stage}-${name}"
    return 0
  fi
  [[ -f "${file}" ]] || die "Module not found: ${file}"
  log_section "Running ${stage}-${name}"
  # shellcheck source=/dev/null
  source "${file}"
}

retry() {
  local attempts="$1"
  local sleep_seconds="$2"
  shift 2
  local i=1
  until "$@"; do
    if [[ "${i}" -ge "${attempts}" ]]; then
      return 1
    fi
    log_warn "Command failed, retry ${i}/${attempts}: $*"
    sleep "${sleep_seconds}"
    i=$((i + 1))
  done
}

chroot_run() {
  [[ -d "${INSTALL_ROOT}" ]] || die "Install root missing: ${INSTALL_ROOT}"
  chroot "${INSTALL_ROOT}" "${CHROOT_ENV[@]}" "$@"
}

write_file() {
  local path="$1"
  local mode="$2"
  local owner="${3:-root:root}"
  install -D -m "${mode}" /dev/null "${path}"
  chown "${owner}" "${path}"
  cat > "${path}"
}

append_once() {
  local path="$1"
  local marker="$2"
  if [[ -f "${path}" ]] && grep -Fq "${marker}" "${path}"; then
    return 0
  fi
  cat >> "${path}"
}

disk_part_prefix() {
  local disk="$1"
  if [[ "${disk}" =~ [0-9]$ ]]; then
    printf '%sp' "${disk}"
  else
    printf '%s' "${disk}"
  fi
}

mount_chroot_api() {
  mountpoint -q "${INSTALL_ROOT}/proc" || mount -t proc proc "${INSTALL_ROOT}/proc"
  mountpoint -q "${INSTALL_ROOT}/sys" || mount --rbind /sys "${INSTALL_ROOT}/sys"
  mountpoint -q "${INSTALL_ROOT}/dev" || mount --rbind /dev "${INSTALL_ROOT}/dev"
  mountpoint -q "${INSTALL_ROOT}/run" || mount --rbind /run "${INSTALL_ROOT}/run"
}

umount_chroot_api() {
  umount -lf "${INSTALL_ROOT}/run" 2>/dev/null || true
  umount -lf "${INSTALL_ROOT}/dev" 2>/dev/null || true
  umount -lf "${INSTALL_ROOT}/sys" 2>/dev/null || true
  umount -lf "${INSTALL_ROOT}/proc" 2>/dev/null || true
}

cleanup_mounts() {
  set +e
  umount_chroot_api
  umount -lf "${EFI_ROOT}" 2>/dev/null || true
  umount -lf "${INSTALL_ROOT}" 2>/dev/null || true
  set -e
}

apt_install_target() {
  chroot_run apt-get install -y --no-install-recommends "$@"
}

copy_if_exists() {
  local src="$1"
  local dst="$2"
  local mode="${3:-0644}"
  if [[ -e "${src}" ]]; then
    install -D -m "${mode}" "${src}" "${dst}"
  else
    log_warn "Optional source missing: ${src}"
  fi
}
