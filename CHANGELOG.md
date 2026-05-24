# Changelog

All notable changes to Devworks Server OS are documented here.

## Preview - 2026-05-20

### Added

- Bootable Debian-based ISO.
- Permanent disk installer.
- Manual disk confirmation for standard ISO.
- VirtualBox autoinstall profile.
- Devworks desktop wallpaper and theme assets.
- Devworks Control Center native GTK application.
- CPU, memory, disk, network, and service monitoring.
- VirtualBox setup guide.
- Official-style OS manual and release notes.

### Changed

- Control Center no longer opens automatically on startup.
- Applications icon uses Devworks grid style.
- Control Center layout fits 1024x768 VirtualBox display.

### Known Limitations

- Dualboot automation is not yet supported.
- The current installer mode is erase-disk.
- Physical server installation still requires hardware validation and backup planning.

## v0.1.1-server-hardening - 2026-05-24

### Added

- Production server installer profile.
- First-login admin password expiration.
- SSH hardening controls.
- Local-only admin web UI binding.
- Kernel/network sysctl hardening.
- Server backup and restore documentation.
- Backup archive for `C:\root\server`.

### Changed

- Bare-metal profile now defaults closer to production safety.
- Validation now checks production hardening files and disabled autologin.
