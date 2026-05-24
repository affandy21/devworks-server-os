#!/usr/bin/env bash

: "${ENABLE_UFW:=yes}"
: "${ALLOW_HTTP:=no}"
: "${ALLOW_HTTPS:=no}"
: "${ALLOW_ADMIN_UI_PORT:=no}"
: "${ADMIN_UI_PORT:=8088}"
: "${TLS_MODE:=off}"
: "${TLS_DOMAIN:=devworks.local}"
: "${TLS_CERT_SOURCE:=}"
: "${TLS_KEY_SOURCE:=}"
: "${CERTBOT_EMAIL:=admin@example.com}"

log_info "Configuring firewall and optional TLS material"

apt_install_target openssl

if is_yes "${ENABLE_UFW}"; then
  chroot_run ufw --force reset
  chroot_run ufw default deny incoming
  chroot_run ufw default allow outgoing
  chroot_run ufw allow "${SSH_PORT}/tcp"
  is_yes "${ALLOW_HTTP}" && chroot_run ufw allow 80/tcp
  is_yes "${ALLOW_HTTPS}" && chroot_run ufw allow 443/tcp
  is_yes "${ALLOW_ADMIN_UI_PORT}" && chroot_run ufw allow "${ADMIN_UI_PORT}/tcp"
  chroot_run ufw --force enable
  chroot_run systemctl enable ufw
fi

mkdir -p "${INSTALL_ROOT}/etc/devworks/tls"

case "${TLS_MODE}" in
  self-signed)
    chroot_run openssl req -x509 -newkey rsa:4096 -sha256 -days 825 -nodes \
      -keyout /etc/devworks/tls/devworks.key \
      -out /etc/devworks/tls/devworks.crt \
      -subj "/CN=${TLS_DOMAIN}" \
      -addext "subjectAltName=DNS:${TLS_DOMAIN},DNS:localhost,IP:127.0.0.1"
    ;;
  existing)
    [[ -f "${TLS_CERT_SOURCE}" ]] || die "TLS_CERT_SOURCE not found: ${TLS_CERT_SOURCE}"
    [[ -f "${TLS_KEY_SOURCE}" ]] || die "TLS_KEY_SOURCE not found: ${TLS_KEY_SOURCE}"
    install -D -m 0644 "${TLS_CERT_SOURCE}" "${INSTALL_ROOT}/etc/devworks/tls/devworks.crt"
    install -D -m 0600 "${TLS_KEY_SOURCE}" "${INSTALL_ROOT}/etc/devworks/tls/devworks.key"
    ;;
  certbot)
    apt_install_target certbot python3-certbot-nginx
    log_warn "Certbot installed. Certificate issuance remains opt-in via: sudo devworks enable web --tls certbot ..."
    ;;
  off)
    log_info "TLS_MODE=off; no certificate is generated during installation."
    ;;
  *)
    die "Unsupported TLS_MODE: ${TLS_MODE}"
    ;;
esac

cat > "${INSTALL_ROOT}/etc/devworks/tls/README" <<EOF
Devworks Server OS does not publish HTTPS automatically.

After DNS points to this server, enable web/TLS explicitly, for example:

  sudo devworks enable web --domain example.com --tls certbot --email admin@example.com --open-firewall

For a local self-signed test:

  sudo devworks enable web --domain devworks.local --tls self-signed
EOF

log_info "Firewall configured. Public web ports remain closed unless explicitly allowed."
