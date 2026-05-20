#!/usr/bin/env bash

: "${ENABLE_WEB_STACK:=yes}"
: "${WEB_SERVICE_NAME:=devworks-web}"
: "${WEB_ROOT:=/srv/devworks/web}"
: "${ENABLE_AI_RUNTIME:=yes}"
: "${AI_SERVICE_NAME:=devworks-ai}"
: "${AI_RUNTIME_MODE:=ollama}"
: "${AI_SERVICE_PORT:=11434}"
: "${ENABLE_CONTAINER_RUNTIME:=podman}"

log_info "Configuring web and AI services"

case "${ENABLE_CONTAINER_RUNTIME}" in
  podman)
    apt_install_target podman slirp4netns fuse-overlayfs
    ;;
  docker)
    apt_install_target docker.io docker-compose
    chroot_run systemctl enable docker
    ;;
  none)
    log_info "Container runtime disabled."
    ;;
  *)
    die "Unsupported ENABLE_CONTAINER_RUNTIME: ${ENABLE_CONTAINER_RUNTIME}"
    ;;
esac

if is_yes "${ENABLE_WEB_STACK}"; then
  mkdir -p "${INSTALL_ROOT}${WEB_ROOT}"
  cat > "${INSTALL_ROOT}${WEB_ROOT}/index.html" <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Devworks Server OS</title>
  <style>
    body{margin:0;background:#07111f;color:#e9f3ff;font-family:Arial,sans-serif;display:grid;place-items:center;min-height:100vh}
    main{max-width:720px;padding:32px}
    h1{color:#7ff4ff}
    code{color:#35f0b3}
  </style>
</head>
<body>
  <main>
    <h1>Devworks Server OS</h1>
    <p>Web service is online.</p>
    <p>Health check: <code>/health</code></p>
  </main>
</body>
</html>
EOF
  cat > "${INSTALL_ROOT}/etc/systemd/system/${WEB_SERVICE_NAME}.service" <<EOF
[Unit]
Description=Devworks web stack health target
After=network-online.target nginx.service
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/systemctl start nginx.service
ExecReload=/usr/bin/systemctl reload nginx.service

[Install]
WantedBy=multi-user.target
EOF
  cat > "${INSTALL_ROOT}/usr/local/sbin/devworks-web-health-check" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

curl -fsS --max-time 10 http://127.0.0.1/health >/dev/null
curl -kfsS --max-time 10 https://127.0.0.1/health >/dev/null
EOF
  chmod 0755 "${INSTALL_ROOT}/usr/local/sbin/devworks-web-health-check"
  cat > "${INSTALL_ROOT}/etc/systemd/system/devworks-web-health.service" <<'EOF'
[Unit]
Description=Devworks web and TLS health check
After=network-online.target nginx.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/devworks-web-health-check
EOF
  cat > "${INSTALL_ROOT}/etc/systemd/system/devworks-web-health.timer" <<'EOF'
[Unit]
Description=Run Devworks web and TLS health check periodically

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
AccuracySec=30s
Unit=devworks-web-health.service

[Install]
WantedBy=timers.target
EOF
  chroot_run systemctl enable "${WEB_SERVICE_NAME}.service"
  chroot_run systemctl enable devworks-web-health.timer
fi

if is_yes "${ENABLE_AI_RUNTIME}"; then
  case "${AI_RUNTIME_MODE}" in
    ollama)
      cat > "${INSTALL_ROOT}/etc/systemd/system/${AI_SERVICE_NAME}.service" <<EOF
[Unit]
Description=Devworks AI runtime placeholder
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=OLLAMA_HOST=0.0.0.0:${AI_SERVICE_PORT}
ExecStart=/bin/sh -c 'if command -v ollama >/dev/null 2>&1; then exec ollama serve; else exec python3 -m http.server ${AI_SERVICE_PORT} --bind 0.0.0.0; fi'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
      ;;
    placeholder|none)
      cat > "${INSTALL_ROOT}/etc/systemd/system/${AI_SERVICE_NAME}.service" <<EOF
[Unit]
Description=Devworks AI placeholder service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server ${AI_SERVICE_PORT} --bind 0.0.0.0
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
      ;;
    *)
      die "Unsupported AI_RUNTIME_MODE: ${AI_RUNTIME_MODE}"
      ;;
  esac
  chroot_run systemctl enable "${AI_SERVICE_NAME}.service"
fi

log_info "Service configuration complete."
