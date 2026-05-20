#!/usr/bin/env bash

: "${ENABLE_UFW:=yes}"
: "${ALLOW_HTTP:=yes}"
: "${ALLOW_HTTPS:=yes}"
: "${ALLOW_ADMIN_UI_PORT:=no}"
: "${ADMIN_UI_PORT:=8088}"
: "${TLS_MODE:=self-signed}"
: "${TLS_DOMAIN:=devworks.local}"
: "${TLS_CERT_SOURCE:=}"
: "${TLS_KEY_SOURCE:=}"
: "${CERTBOT_EMAIL:=admin@example.com}"

log_info "Configuring firewall and TLS"

apt_install_target nginx-light openssl

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
    log_warn "Certbot installed. Certificate issuance must run after DNS points to this host."
    ;;
  off)
    log_warn "TLS_MODE=off; HTTPS nginx config will not be enabled."
    ;;
  *)
    die "Unsupported TLS_MODE: ${TLS_MODE}"
    ;;
esac

mkdir -p "${INSTALL_ROOT}/etc/nginx/sites-available" "${INSTALL_ROOT}/etc/nginx/sites-enabled" "${INSTALL_ROOT}${WEB_ROOT:-/srv/devworks/web}"
cat > "${INSTALL_ROOT}/etc/nginx/sites-available/devworks.conf" <<EOF
server {
    listen 80 default_server;
    server_name _;
    root ${WEB_ROOT:-/srv/devworks/web};
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /health {
        add_header Content-Type text/plain;
        return 200 "ok\\n";
    }
}
EOF

if [[ "${TLS_MODE}" != "off" && "${TLS_MODE}" != "certbot" ]]; then
  cat >> "${INSTALL_ROOT}/etc/nginx/sites-available/devworks.conf" <<EOF

server {
    listen 443 ssl;
    server_name _;
    root ${WEB_ROOT:-/srv/devworks/web};
    index index.html;

    ssl_certificate /etc/devworks/tls/devworks.crt;
    ssl_certificate_key /etc/devworks/tls/devworks.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location /health {
        add_header Content-Type text/plain;
        return 200 "ok\\n";
    }
}
EOF
fi

rm -f "${INSTALL_ROOT}/etc/nginx/sites-enabled/default"
ln -sf /etc/nginx/sites-available/devworks.conf "${INSTALL_ROOT}/etc/nginx/sites-enabled/devworks.conf"
chroot_run systemctl enable nginx

log_info "Firewall and TLS configuration complete."
