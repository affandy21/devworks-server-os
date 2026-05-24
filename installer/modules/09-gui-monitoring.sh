#!/usr/bin/env bash

: "${ENABLE_GUI:=yes}"
: "${ENABLE_NATIVE_MONITOR:=yes}"
: "${ENABLE_ADMIN_WEB_UI:=yes}"
: "${ADMIN_WEB_UI_BIND:=127.0.0.1}"
: "${WALLPAPER_SOURCE:=/usr/share/backgrounds/halo/devworks-wallpaper.png}"

if ! is_yes "${ENABLE_GUI}"; then
  log_info "GUI disabled."
  return 0
fi

log_info "Installing GUI and Devworks native monitoring"

apt_install_target \
  xorg dbus-x11 lightdm lightdm-gtk-greeter xfce4 xfce4-terminal \
  network-manager-gnome policykit-1 fonts-dejavu fonts-liberation \
  python3 python3-gi gir1.2-gtk-3.0

chroot_run systemctl enable lightdm
chroot_run systemctl set-default graphical.target

SRC="${PROJECT_DIR}/iso/config/includes.chroot"
if [[ ! -d "${SRC}" ]]; then
  SRC=""
fi

ASSET_ROOT="${SRC:-}"
if [[ -z "${ASSET_ROOT}" ]]; then
  ASSET_ROOT=""
fi

copy_if_exists "${ASSET_ROOT}/usr/share/backgrounds/halo/devworks-wallpaper.png" \
  "${INSTALL_ROOT}/usr/share/backgrounds/halo/devworks-wallpaper.png" 0644
copy_if_exists "${ASSET_ROOT}/usr/share/backgrounds/halo/devworks-wallpaper.png" \
  "${INSTALL_ROOT}/usr/share/backgrounds/devworks/devworks-wallpaper.png" 0644
copy_if_exists "${ASSET_ROOT}/usr/share/icons/hicolor/512x512/apps/devworks-control-center.png" \
  "${INSTALL_ROOT}/usr/share/icons/hicolor/512x512/apps/devworks-control-center.png" 0644
copy_if_exists "${ASSET_ROOT}/usr/share/icons/hicolor/scalable/apps/devworks-applications.svg" \
  "${INSTALL_ROOT}/usr/share/icons/hicolor/scalable/apps/devworks-applications.svg" 0644
copy_if_exists "${ASSET_ROOT}/usr/share/icons/hicolor/scalable/apps/devworks-menu.svg" \
  "${INSTALL_ROOT}/usr/share/icons/hicolor/scalable/apps/devworks-menu.svg" 0644
copy_if_exists "${ASSET_ROOT}/usr/share/icons/hicolor/512x512/apps/devworks-menu.png" \
  "${INSTALL_ROOT}/usr/share/icons/hicolor/512x512/apps/devworks-menu.png" 0644
rm -f "${INSTALL_ROOT}/usr/share/icons/hicolor/512x512/apps/devworks-applications.png"
copy_if_exists "${ASSET_ROOT}/usr/share/pixmaps/devworks-control-center.png" \
  "${INSTALL_ROOT}/usr/share/pixmaps/devworks-control-center.png" 0644
copy_if_exists "${ASSET_ROOT}/usr/share/pixmaps/devworks-logo.png" \
  "${INSTALL_ROOT}/usr/share/pixmaps/devworks-logo.png" 0644

mkdir -p "${INSTALL_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
copy_if_exists "${ASSET_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" \
  "${INSTALL_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" 0644
copy_if_exists "${ASSET_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
  "${INSTALL_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" 0644
copy_if_exists "${ASSET_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
  "${INSTALL_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" 0644

if [[ -n "${ADMIN_USER:-}" && -d "${INSTALL_ROOT}/home/${ADMIN_USER}" ]]; then
  mkdir -p "${INSTALL_ROOT}/home/${ADMIN_USER}/.config/xfce4/xfconf/xfce-perchannel-xml"
  copy_if_exists "${ASSET_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" \
    "${INSTALL_ROOT}/home/${ADMIN_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" 0644
  copy_if_exists "${ASSET_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
    "${INSTALL_ROOT}/home/${ADMIN_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" 0644
  copy_if_exists "${ASSET_ROOT}/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" \
    "${INSTALL_ROOT}/home/${ADMIN_USER}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" 0644
fi

mkdir -p "${INSTALL_ROOT}/etc/lightdm/lightdm-gtk-greeter.conf.d"
copy_if_exists "${ASSET_ROOT}/etc/lightdm/lightdm-gtk-greeter.conf.d/60-devworks-theme.conf" \
  "${INSTALL_ROOT}/etc/lightdm/lightdm-gtk-greeter.conf.d/60-devworks-theme.conf" 0644

if is_yes "${ENABLE_NATIVE_MONITOR}"; then
  copy_if_exists "${ASSET_ROOT}/opt/devworks/control-center/devworks-control-center" \
    "${INSTALL_ROOT}/opt/devworks/control-center/devworks-control-center" 0755
  copy_if_exists "${ASSET_ROOT}/opt/devworks/control-center/devworks-control-center.png" \
    "${INSTALL_ROOT}/opt/devworks/control-center/devworks-control-center.png" 0644
  mkdir -p "${INSTALL_ROOT}/usr/local/bin"
  cat > "${INSTALL_ROOT}/usr/local/bin/devworks-open-admin" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec /opt/devworks/control-center/devworks-control-center
EOF
  chmod 0755 "${INSTALL_ROOT}/usr/local/bin/devworks-open-admin"

  mkdir -p "${INSTALL_ROOT}/etc/skel/Desktop" "${INSTALL_ROOT}/usr/share/applications"
  cat > "${INSTALL_ROOT}/usr/share/applications/devworks-control-center.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Devworks Control Center
Comment=Open native Devworks Server OS monitoring software
Exec=/usr/local/bin/devworks-open-admin
Icon=devworks-control-center
Terminal=false
Categories=System;Monitor;
EOF
  chmod 0644 "${INSTALL_ROOT}/usr/share/applications/devworks-control-center.desktop"
  cp "${INSTALL_ROOT}/usr/share/applications/devworks-control-center.desktop" \
    "${INSTALL_ROOT}/etc/skel/Desktop/devworks-control-center.desktop"
  chmod 0755 "${INSTALL_ROOT}/etc/skel/Desktop/devworks-control-center.desktop"
  rm -f "${INSTALL_ROOT}/etc/skel/Desktop/devworks-admin.desktop" \
    "${INSTALL_ROOT}/etc/xdg/autostart/devworks-admin.desktop"
  if [[ -n "${ADMIN_USER:-}" && -d "${INSTALL_ROOT}/home/${ADMIN_USER}" ]]; then
    mkdir -p "${INSTALL_ROOT}/home/${ADMIN_USER}/Desktop"
    cp "${INSTALL_ROOT}/usr/share/applications/devworks-control-center.desktop" \
      "${INSTALL_ROOT}/home/${ADMIN_USER}/Desktop/devworks-control-center.desktop"
    chmod 0755 "${INSTALL_ROOT}/home/${ADMIN_USER}/Desktop/devworks-control-center.desktop"
    chroot_run chown -R "${ADMIN_USER}:${ADMIN_USER}" "/home/${ADMIN_USER}/Desktop" "/home/${ADMIN_USER}/.config"
  fi
fi

if is_yes "${ENABLE_ADMIN_WEB_UI}"; then
  mkdir -p "${INSTALL_ROOT}/opt/devworks/admin-ui"
  if [[ -d "${PROJECT_DIR}/admin-ui" ]]; then
    rsync -a "${PROJECT_DIR}/admin-ui/" "${INSTALL_ROOT}/opt/devworks/admin-ui/"
  fi
  cat > "${INSTALL_ROOT}/etc/systemd/system/devworks-admin-ui.service" <<'EOF'
[Unit]
Description=Devworks Admin UI
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/devworks/admin-ui
Environment=DEVWORKS_HOST=${ADMIN_WEB_UI_BIND}
Environment=DEVWORKS_PORT=8088
Environment=DEVWORKS_ENABLE_INSTALL=0
ExecStart=/usr/bin/python3 /opt/devworks/admin-ui/server.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  chroot_run systemctl enable devworks-admin-ui.service
fi

chroot_run gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
chroot_run update-desktop-database /usr/share/applications || true

log_info "GUI and monitoring configured."
