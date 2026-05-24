# Build Result

Build ISO Devworks Server OS terakhir berhasil dibuat.

## Output

```text
dist/devworks-server-os.iso
dist/devworks-server-os-autoinstall.iso
```

## Checksum

```text
dist/devworks-server-os.iso.sha256
dist/devworks-server-os-autoinstall.iso.sha256
```

## Verifikasi Fitur

Sudah masuk ke build:

- ISO bootable berbasis Debian.
- Desktop XFCE ringan.
- Wallpaper Devworks default.
- Icon Applications grid Devworks.
- Devworks Control Center native GTK.
- Shortcut Devworks Control Center di desktop.
- Control Center tidak auto-start.
- Installer permanen ke disk.
- Manual confirm disk pada ISO standar.
- Profil autoinstall khusus VirtualBox.

## Bukti Uji Visual

Screenshot hasil uji lokal:

```text
devworks-final-desktop-fixed.png
devworks-final-control-center-fixed.png
devworks-menu-grid-icon-fixed.png
```

## Catatan Stabilitas

Build sudah layak untuk uji VirtualBox dan server kosong. Untuk server production fisik, tetap lakukan validasi hardware, backup, pengujian restart berkali-kali, dan uji TLS/SSH/firewall setelah instalasi.
