#!/usr/bin/env bash

: "${ADMIN_USER:=devworks}"
: "${ADMIN_FULL_NAME:=Devworks Administrator}"
INITIAL_ADMIN_USER="${ADMIN_USER}"
: "${ADMIN_PASSWORD_MODE:=prompt}"
: "${ADMIN_PASSWORD_HASH:=}"
: "${FORCE_PASSWORD_CHANGE:=no}"
: "${ADMIN_SUDO_NOPASSWD:=no}"
: "${ENABLE_AUTOLOGIN:=no}"
: "${AUTOLOGIN_USER:=${ADMIN_USER}}"
: "${SSH_KEY_SETUP_MODE:=prompt}"
: "${SSH_AUTHORIZED_KEYS_FILE:=}"

resolve_admin_identity() {
  if [[ "${ADMIN_PASSWORD_MODE}" == "prompt" && -z "${ADMIN_PASSWORD_HASH}" ]]; then
    is_interactive || die "ADMIN_PASSWORD_MODE=prompt requires an interactive terminal or ADMIN_PASSWORD_HASH."

    while true; do
      ADMIN_USER="$(prompt_with_default "Admin username" "${ADMIN_USER}")"
      if validate_linux_username "${ADMIN_USER}"; then
        break
      fi
      log_warn "Invalid username. Use lowercase letters, digits, underscore, or dash; start with a letter or underscore."
    done

    ADMIN_FULL_NAME="$(prompt_with_default "Admin full name" "${ADMIN_FULL_NAME}")"
  fi
}

resolve_admin_password_hash() {
  case "${ADMIN_PASSWORD_MODE}" in
    prompt)
      if [[ -z "${ADMIN_PASSWORD_HASH}" ]]; then
        local password=""
        password="$(prompt_secret_confirm "Admin password")"
        ADMIN_PASSWORD_HASH="$(hash_password_sha512 "${password}")"
        unset password
      fi
      ;;
    hash)
      [[ -n "${ADMIN_PASSWORD_HASH}" ]] || die "ADMIN_PASSWORD_MODE=hash requires ADMIN_PASSWORD_HASH."
      ;;
    locked)
      ADMIN_PASSWORD_HASH="!"
      ;;
    *)
      die "Unsupported ADMIN_PASSWORD_MODE: ${ADMIN_PASSWORD_MODE}"
      ;;
  esac
}

resolve_ssh_key_file() {
  if [[ -n "${SSH_AUTHORIZED_KEYS_FILE}" && -f "${SSH_AUTHORIZED_KEYS_FILE}" ]]; then
    return 0
  fi

  case "${SSH_KEY_SETUP_MODE}" in
    prompt)
      if is_interactive && prompt_yes_no "Install an SSH public key for ${ADMIN_USER}" "yes"; then
        while true; do
          SSH_AUTHORIZED_KEYS_FILE="$(prompt_with_default "SSH public key file path" "${SSH_AUTHORIZED_KEYS_FILE}")"
          if [[ -f "${SSH_AUTHORIZED_KEYS_FILE}" ]]; then
            break
          fi
          log_warn "SSH public key file not found: ${SSH_AUTHORIZED_KEYS_FILE}"
        done
      fi
      ;;
    required)
      if is_interactive; then
        while true; do
          SSH_AUTHORIZED_KEYS_FILE="$(prompt_with_default "Required SSH public key file path" "${SSH_AUTHORIZED_KEYS_FILE}")"
          if [[ -f "${SSH_AUTHORIZED_KEYS_FILE}" ]]; then
            break
          fi
          log_warn "SSH public key file not found: ${SSH_AUTHORIZED_KEYS_FILE}"
        done
      else
        [[ -n "${SSH_AUTHORIZED_KEYS_FILE}" && -f "${SSH_AUTHORIZED_KEYS_FILE}" ]] || \
          die "SSH_KEY_SETUP_MODE=required needs SSH_AUTHORIZED_KEYS_FILE."
      fi
      ;;
    skip)
      ;;
    *)
      die "Unsupported SSH_KEY_SETUP_MODE: ${SSH_KEY_SETUP_MODE}"
      ;;
  esac
}

resolve_admin_identity
resolve_admin_password_hash
resolve_ssh_key_file

if [[ -z "${SSH_ALLOW_USERS:-}" || "${SSH_ALLOW_USERS}" == "${INITIAL_ADMIN_USER}" ]]; then
  SSH_ALLOW_USERS="${ADMIN_USER}"
fi
if [[ -z "${AUTOLOGIN_USER:-}" || "${AUTOLOGIN_USER}" == "${INITIAL_ADMIN_USER}" ]]; then
  AUTOLOGIN_USER="${ADMIN_USER}"
fi

log_info "Configuring admin user ${ADMIN_USER}"

if ! chroot_run id "${ADMIN_USER}" >/dev/null 2>&1; then
  chroot_run useradd -m -s /bin/bash -c "${ADMIN_FULL_NAME}" "${ADMIN_USER}"
fi

if [[ "${ADMIN_PASSWORD_MODE}" == "locked" ]]; then
  chroot_run usermod -L "${ADMIN_USER}"
else
  echo "${ADMIN_USER}:${ADMIN_PASSWORD_HASH}" | chroot "${INSTALL_ROOT}" chpasswd -e
fi
chroot_run usermod -aG sudo,adm,systemd-journal "${ADMIN_USER}"

if is_yes "${FORCE_PASSWORD_CHANGE}" && [[ "${ADMIN_PASSWORD_MODE}" != "locked" ]]; then
  chroot_run chage -d 0 "${ADMIN_USER}"
  log_warn "Password for ${ADMIN_USER} will be expired on first login."
fi

if is_yes "${ADMIN_SUDO_NOPASSWD}"; then
  cat > "${INSTALL_ROOT}/etc/sudoers.d/90-devworks-admin" <<EOF
${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL
EOF
else
  cat > "${INSTALL_ROOT}/etc/sudoers.d/90-devworks-admin" <<EOF
${ADMIN_USER} ALL=(ALL:ALL) ALL
EOF
fi
chmod 0440 "${INSTALL_ROOT}/etc/sudoers.d/90-devworks-admin"

admin_uid="$(chroot_run id -u "${ADMIN_USER}")"
admin_gid="$(chroot_run id -g "${ADMIN_USER}")"
install -d -m 0700 -o "${admin_uid}" -g "${admin_gid}" "${INSTALL_ROOT}/home/${ADMIN_USER}/.ssh"
if [[ -n "${SSH_AUTHORIZED_KEYS_FILE:-}" && -f "${SSH_AUTHORIZED_KEYS_FILE}" ]]; then
  install -m 0600 -o "${admin_uid}" -g "${admin_gid}" "${SSH_AUTHORIZED_KEYS_FILE}" "${INSTALL_ROOT}/home/${ADMIN_USER}/.ssh/authorized_keys"
elif is_yes "${REQUIRE_SSH_AUTHORIZED_KEYS:-no}"; then
  die "SSH_AUTHORIZED_KEYS_FILE is required for this profile: ${SSH_AUTHORIZED_KEYS_FILE:-unset}"
elif [[ "${SSH_PASSWORD_AUTH:-yes}" == "no" ]]; then
  log_warn "SSH password auth is disabled but SSH_AUTHORIZED_KEYS_FILE is missing. Ensure console access is available."
fi

if is_yes "${ENABLE_AUTOLOGIN}"; then
  mkdir -p "${INSTALL_ROOT}/etc/lightdm/lightdm.conf.d"
  cat > "${INSTALL_ROOT}/etc/lightdm/lightdm.conf.d/50-devworks-autologin.conf" <<EOF
[Seat:*]
autologin-user=${AUTOLOGIN_USER}
autologin-user-timeout=0
user-session=xfce
greeter-session=lightdm-gtk-greeter
EOF
  log_warn "Autologin enabled for ${AUTOLOGIN_USER}. Disable for production bare metal."
else
  rm -f "${INSTALL_ROOT}/etc/lightdm/lightdm.conf.d/50-devworks-autologin.conf"
fi

log_info "User configuration complete."
