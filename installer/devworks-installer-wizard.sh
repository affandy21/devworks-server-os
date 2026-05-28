#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_INSTALLER="${SCRIPT_DIR}/devworks-install.sh"
if [[ ! -x "${DEFAULT_INSTALLER}" && -x /opt/devworks/installer/devworks-install.sh ]]; then
  DEFAULT_INSTALLER="/opt/devworks/installer/devworks-install.sh"
fi
INSTALLER="${DEVWORKS_INSTALLER:-${DEFAULT_INSTALLER}}"
CONFIG_OUT="${DEVWORKS_WIZARD_CONFIG:-/tmp/devworks-install.env}"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

need_root() {
  [[ "${EUID}" -eq 0 ]] || die "Jalankan dengan sudo: sudo devworks-installer (atau sudo bash /run/live/medium/devworks-installer dari USB saat ini)"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

is_yes_answer() {
  case "${1:-}" in
    y|Y|yes|YES|ya|YA) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_default() {
  local prompt="$1"
  local default="$2"
  local answer=""
  printf '%s [%s]: ' "${prompt}" "${default}"
  read -r answer
  printf '%s' "${answer:-${default}}"
}

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-no}"
  local answer=""
  local suffix="[y/N]"
  [[ "${default}" == "yes" ]] && suffix="[Y/n]"
  while true; do
    printf '%s %s: ' "${prompt}" "${suffix}"
    read -r answer
    answer="${answer:-${default}}"
    case "${answer}" in
      y|Y|yes|YES|ya|YA) return 0 ;;
      n|N|no|NO|tidak|TIDAK) return 1 ;;
      *) printf 'Jawab dengan yes/no, ya/tidak, atau y/n.\n' >&2 ;;
    esac
  done
}

validate_linux_username() {
  [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]
}

validate_hostname() {
  [[ "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,62}$ ]] && [[ "$1" != *--* ]] && [[ "$1" != *- ]]
}

prompt_hostname() {
  local value=""
  while true; do
    printf '\nMasukkan hostname server.\n'
    printf 'Contoh yang benar: devworks-server, server01, web-ai-01\n'
    printf 'Aturan: huruf/angka/tanda minus, tanpa spasi, tidak diakhiri tanda minus.\n'
    value="$(prompt_default "Hostname server" "devworks-server")"
    if validate_hostname "${value}"; then
      HOSTNAME_VALUE="${value}"
      return 0
    fi
    printf '\nHostname tidak valid: %s\n' "${value}" >&2
    printf 'Silakan coba lagi. Contoh paling aman: devworks-server\n' >&2
  done
}

prompt_admin_username() {
  local value=""
  while true; do
    printf '\nMasukkan username admin Linux.\n'
    printf 'Contoh yang benar: devworks, admin, irpan\n'
    printf 'Aturan: huruf kecil, angka, underscore, atau minus. Tidak boleh spasi, titik, @, atau huruf besar.\n'
    value="$(prompt_default "Username admin" "devworks")"
    if validate_linux_username "${value}"; then
      ADMIN_USER_VALUE="${value}"
      return 0
    fi
    printf '\nUsername tidak valid: %s\n' "${value}" >&2
    printf 'Silakan coba lagi. Contoh paling aman: devworks\n' >&2
  done
}

quote_value() {
  printf '%q' "$1"
}

disk_partitions() {
  local disk="$1"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,PARTLABEL,LABEL,MOUNTPOINTS "${disk}" || true
}

live_disk_parent() {
  local source parent
  source="$(findmnt -n -o SOURCE /run/live/medium 2>/dev/null || true)"
  [[ -n "${source}" && -b "${source}" ]] || return 0
  parent="$(lsblk -no PKNAME "${source}" 2>/dev/null | head -n1 | xargs || true)"
  [[ -n "${parent}" ]] || return 0
  printf '/dev/%s' "${parent}"
}

load_disks() {
  mapfile -t DISKS < <(
    lsblk -dnpo PATH,TYPE | awk '$2 == "disk" {print $1}' |
      while read -r disk; do
        [[ -b "${disk}" ]] && printf '%s\n' "${disk}"
      done
  )
  [[ "${#DISKS[@]}" -gt 0 ]] || die "Tidak ada disk target yang ditemukan."
}

show_disk_table() {
  local live_parent="$1"
  printf '\nDisk yang terdeteksi\n'
  printf '====================\n'
  printf '%-4s %-16s %-10s %-22s %-18s %s\n' "No" "Device" "Ukuran" "Model" "Serial" "Keterangan"
  local i=1
  local disk size model serial note
  for disk in "${DISKS[@]}"; do
    size="$(lsblk -dnpo SIZE "${disk}" | xargs || true)"
    model="$(lsblk -dnpo MODEL "${disk}" | sed 's/[[:space:]]\+/ /g' | xargs || true)"
    serial="$(lsblk -dnpo SERIAL "${disk}" | sed 's/[[:space:]]\+/ /g' | xargs || true)"
    note=""
    [[ "${disk}" == "${live_parent}" ]] && note="USB installer - tidak bisa dipilih"
    if lsblk -nr -o FSTYPE,PARTLABEL,LABEL,MOUNTPOINTS "${disk}" | grep -Eiq 'ntfs|BitLocker|EFI|ESP|Microsoft|Windows'; then
      note="${note:+${note}; }OS/data lama terdeteksi"
    fi
    printf '%-4s %-16s %-10s %-22s %-18s %s\n' "${i}" "${disk}" "${size}" "${model:0:22}" "${serial:0:18}" "${note}"
    i=$((i + 1))
  done
}

select_disk() {
  local live_parent="$1"
  local choice disk
  while true; do
    show_disk_table "${live_parent}"
    printf '\nMasukkan nomor disk target yang akan dihapus dan diinstall, atau q untuk batal: '
    read -r choice
    [[ "${choice}" == "q" || "${choice}" == "Q" ]] && exit 0
    [[ "${choice}" =~ ^[0-9]+$ ]] || {
      printf 'Masukkan nomor disk yang valid.\n' >&2
      continue
    }
    (( choice >= 1 && choice <= ${#DISKS[@]} )) || {
      printf 'Nomor disk di luar daftar.\n' >&2
      continue
    }
    disk="${DISKS[$((choice - 1))]}"
    if [[ -n "${live_parent}" && "${disk}" == "${live_parent}" ]]; then
      printf 'Installer menolak install ke USB installer: %s\n' "${disk}" >&2
      continue
    fi
    TARGET_DISK="${disk}"
    return 0
  done
}

write_config() {
  local ssh_password_auth="$1"
  local ssh_key_mode="$2"
  local require_keys="$3"

  cat > "${CONFIG_OUT}" <<EOF
# Dibuat oleh Devworks Installer Wizard.
# Config ini memasang base desktop/server bersih lebih dulu.
DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK="no"
DEVWORKS_MANUAL_CONFIRM_DISK="yes"
DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK="no"
INSTALL_MODE="erase-disk"
TARGET_DISK="$(quote_value "${TARGET_DISK}")"
TARGET_BOOT_MODE="auto"
TARGET_SWAP_SIZE_MIB="4096"
APT_COMPONENTS="main contrib non-free non-free-firmware"
ENABLE_HARDWARE_BACKPORTS="no"

DEVWORKS_HOSTNAME="$(quote_value "${HOSTNAME_VALUE}")"
DEVWORKS_VERSION="0.2.1"
DEVWORKS_VERSION_NAME="Dual Boot Hardware"
TIMEZONE="Asia/Jakarta"
LOCALE="en_US.UTF-8"
KEYMAP="us"

ADMIN_USER="$(quote_value "${ADMIN_USER_VALUE}")"
ADMIN_FULL_NAME="Devworks Administrator"
ADMIN_PASSWORD_MODE="prompt"
ADMIN_PASSWORD_HASH=""
FORCE_PASSWORD_CHANGE="no"
ADMIN_SUDO_NOPASSWD="no"
ENABLE_AUTOLOGIN="no"

SSH_PORT="22"
SSH_PASSWORD_AUTH="${ssh_password_auth}"
SSH_PERMIT_ROOT_LOGIN="no"
SSH_ALLOW_USERS="\${ADMIN_USER}"
SSH_AUTHORIZED_KEYS_FILE=""
SSH_KEY_SETUP_MODE="${ssh_key_mode}"
REQUIRE_SSH_AUTHORIZED_KEYS="${require_keys}"
SSH_DISABLE_EMPTY_PASSWORDS="yes"
SSH_MAX_AUTH_TRIES="3"

ENABLE_UFW="yes"
ALLOW_HTTP="no"
ALLOW_HTTPS="no"
ALLOW_ADMIN_UI_PORT="no"
TLS_MODE="off"
TLS_DOMAIN="devworks.local"
TLS_CERT_SOURCE=""
TLS_KEY_SOURCE=""

ENABLE_WEB_STACK="no"
WEB_SERVICE_NAME="devworks-web"
WEB_ROOT="/srv/devworks/web"
WEB_ENABLE_FIREWALL="no"
WEB_TLS_MODE="off"
ENABLE_AI_RUNTIME="no"
AI_RUNTIME_MODE="none"
AI_BIND_ADDRESS="127.0.0.1"
AI_MEMORY_MAX="8G"
AI_CPU_QUOTA="300%"
AI_ENABLE_FIREWALL="no"
ENABLE_CONTAINER_RUNTIME="none"
INSTALL_WEB_FEATURE_PACKAGES="yes"
INSTALL_AI_FEATURE_PACKAGES="no"
INSTALL_CONTAINER_FEATURE_PACKAGES="no"
ENABLE_SERVICE_WIZARD="yes"

ENABLE_GUI="yes"
ENABLE_NATIVE_MONITOR="yes"
ENABLE_ADMIN_WEB_UI="no"
ADMIN_WEB_UI_BIND="127.0.0.1"

ENABLE_UNATTENDED_UPGRADES="yes"
ENABLE_AUTO_REBOOT_AFTER_SECURITY_UPDATE="no"
ENABLE_GRUB_RECOVERY="yes"
ENABLE_WINDOWS_BOOT_DETECTION="yes"
POST_INSTALL_REBOOT="no"
EOF
  chmod 0600 "${CONFIG_OUT}"
}

main() {
  need_root
  need_cmd lsblk
  need_cmd findmnt
  [[ -x "${INSTALLER}" ]] || die "Installer not found: ${INSTALLER}"

  clear || true
  cat <<'EOF'
Wizard Instalasi Devworks Server OS
===================================

Wizard sederhana ini memasang Devworks OS ke satu disk penuh.

PERINGATAN:
  Disk yang dipilih akan dihapus sepenuhnya.
  Windows, aplikasi, dan file pada disk tersebut akan hilang.
  Web, AI, Docker, dan port publik tetap nonaktif setelah install awal.

EOF

  local live_parent=""
  live_parent="$(live_disk_parent || true)"
  load_disks
  select_disk "${live_parent}"

  printf '\nDisk target yang dipilih: %s\n' "${TARGET_DISK}"
  printf 'Periksa isi disk di bawah ini sebelum lanjut.\n\n'
  disk_partitions "${TARGET_DISK}"

  prompt_hostname
  prompt_admin_username

  local ssh_password_auth="yes"
  local ssh_key_mode="prompt"
  local require_keys="no"
  if prompt_yes_no "Izinkan login SSH memakai password sementara untuk setup awal?" "yes"; then
    ssh_password_auth="yes"
    ssh_key_mode="prompt"
    require_keys="no"
  else
    ssh_password_auth="no"
    ssh_key_mode="required"
    require_keys="yes"
  fi

  cat <<EOF

Ringkasan instalasi
===================
Mode install:       hapus satu disk penuh
Disk target:        ${TARGET_DISK}
Hostname server:    ${HOSTNAME_VALUE}
Username admin:     ${ADMIN_USER_VALUE}
Desktop GUI:        aktif
Control Center:     aplikasi desktop native
Port SSH:           22
Login SSH password: ${ssh_password_auth}
Service web:        nonaktif sampai user mengaktifkan
Service AI:         nonaktif sampai user mengaktifkan
Container runtime:  nonaktif sampai user mengaktifkan
File config:        ${CONFIG_OUT}

EOF

  printf 'Untuk lanjut, ketik persis seperti ini: ERASE %s\n' "${TARGET_DISK}"
  printf '> '
  local confirmation=""
  read -r confirmation
  [[ "${confirmation}" == "ERASE ${TARGET_DISK}" ]] || die "Konfirmasi tidak cocok. Tidak ada proses install yang dijalankan."

  write_config "${ssh_password_auth}" "${ssh_key_mode}" "${require_keys}"
  printf '\nConfig dibuat di: %s\n' "${CONFIG_OUT}"
  printf 'Installer dimulai. Setelah ini Anda akan diminta membuat password admin.\n\n'
  exec bash "${INSTALLER}" --config "${CONFIG_OUT}"
}

main "$@"
