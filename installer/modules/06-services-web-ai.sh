#!/usr/bin/env bash

: "${ENABLE_WEB_STACK:=no}"
: "${WEB_SERVICE_NAME:=devworks-web}"
: "${WEB_ROOT:=/srv/devworks/web}"
: "${WEB_ENABLE_FIREWALL:=no}"
: "${WEB_TLS_MODE:=off}"
: "${ENABLE_AI_RUNTIME:=no}"
: "${AI_SERVICE_NAME:=devworks-ai}"
: "${AI_RUNTIME_MODE:=ollama}"
: "${AI_SERVICE_PORT:=11434}"
: "${AI_BIND_ADDRESS:=127.0.0.1}"
: "${AI_MEMORY_MAX:=8G}"
: "${AI_CPU_QUOTA:=300%}"
: "${AI_ENABLE_FIREWALL:=no}"
: "${ENABLE_CONTAINER_RUNTIME:=none}"
: "${INSTALL_WEB_FEATURE_PACKAGES:=yes}"
: "${INSTALL_AI_FEATURE_PACKAGES:=no}"
: "${INSTALL_CONTAINER_FEATURE_PACKAGES:=no}"
: "${ENABLE_SERVICE_WIZARD:=yes}"

log_info "Installing Devworks feature manager and opt-in service templates"

mkdir -p "${INSTALL_ROOT}/etc/devworks/templates" "${INSTALL_ROOT}/usr/local/sbin" "${INSTALL_ROOT}/usr/local/bin"

if [[ -f "${PROJECT_DIR}/scripts/devworks" ]]; then
  install -D -m 0755 "${PROJECT_DIR}/scripts/devworks" "${INSTALL_ROOT}/usr/local/sbin/devworks"
  ln -sfn devworks "${INSTALL_ROOT}/usr/local/sbin/dw"
  ln -sfn ../sbin/devworks "${INSTALL_ROOT}/usr/local/bin/devworks"
  ln -sfn ../sbin/devworks "${INSTALL_ROOT}/usr/local/bin/dw"
else
  log_warn "scripts/devworks missing; feature manager will not be installed."
fi

if is_yes "${ENABLE_SERVICE_WIZARD}" && [[ -x "${INSTALL_ROOT}/usr/local/sbin/devworks" ]]; then
  chroot_run /usr/local/sbin/devworks templates
fi

if is_yes "${INSTALL_WEB_FEATURE_PACKAGES}"; then
  apt_install_target nginx-light certbot python3-certbot-nginx apache2-utils openssl
  rm -f "${INSTALL_ROOT}/etc/nginx/sites-enabled/default"
  chroot_run systemctl disable nginx || true
fi

if is_yes "${INSTALL_AI_FEATURE_PACKAGES}"; then
  apt_install_target python3-venv python3-pip build-essential pkg-config cmake git-lfs
fi

case "${INSTALL_CONTAINER_FEATURE_PACKAGES}" in
  yes|YES|true|TRUE|1|podman)
    apt_install_target podman slirp4netns fuse-overlayfs
    ;;
  docker)
    apt_install_target docker.io docker-compose
    chroot_run systemctl disable docker || true
    ;;
  no|NO|false|FALSE|0|none)
    log_info "Container packages are not installed by default."
    ;;
  *)
    die "Unsupported INSTALL_CONTAINER_FEATURE_PACKAGES: ${INSTALL_CONTAINER_FEATURE_PACKAGES}"
    ;;
esac

case "${ENABLE_CONTAINER_RUNTIME}" in
  none)
    log_info "Container runtime stays disabled until the user enables it."
    ;;
  podman)
    apt_install_target podman slirp4netns fuse-overlayfs
    log_info "Podman installed by explicit profile request; no daemon is enabled."
    ;;
  docker)
    apt_install_target docker.io docker-compose
    chroot_run systemctl enable docker
    ;;
  *)
    die "Unsupported ENABLE_CONTAINER_RUNTIME: ${ENABLE_CONTAINER_RUNTIME}"
    ;;
esac

if is_yes "${ENABLE_WEB_STACK}"; then
  log_warn "ENABLE_WEB_STACK=yes is an explicit opt-in. Enabling nginx web feature."
  web_args=(enable web --root "${WEB_ROOT}" --tls "${WEB_TLS_MODE}")
  is_yes "${WEB_ENABLE_FIREWALL}" && web_args+=(--open-firewall)
  chroot_run /usr/local/sbin/devworks "${web_args[@]}"
else
  chroot_run systemctl disable nginx || true
  log_info "Web stack is available but not enabled."
fi

if is_yes "${ENABLE_AI_RUNTIME}"; then
  log_warn "ENABLE_AI_RUNTIME=yes is an explicit opt-in. Enabling AI runtime service."
  ai_args=(enable ai --runtime "${AI_RUNTIME_MODE}" --port "${AI_SERVICE_PORT}" --bind "${AI_BIND_ADDRESS}" --memory-max "${AI_MEMORY_MAX}" --cpu-quota "${AI_CPU_QUOTA}")
  is_yes "${AI_ENABLE_FIREWALL}" && ai_args+=(--open-firewall)
  chroot_run /usr/local/sbin/devworks "${ai_args[@]}"
else
  rm -f "${INSTALL_ROOT}/etc/systemd/system/${AI_SERVICE_NAME}.service"
  log_info "AI runtime is available as a template but not enabled."
fi

cat > "${INSTALL_ROOT}/etc/devworks/FEATURES.md" <<'EOF'
# Devworks Server OS Features

The base system does not start public web workloads, AI runtimes, or container
daemons automatically. Enable only what the server actually needs.

Useful commands:

```bash
sudo dw status
sudo dw templates
sudo dw enable web --domain example.com --tls certbot --email admin@example.com --open-firewall
sudo dw enable ai --runtime ollama --bind 127.0.0.1 --memory-max 8G --cpu-quota 300%
sudo dw enable container podman
sudo dw disable ai
sudo dw disable web --close-firewall
```
EOF

log_info "Service feature configuration complete."
