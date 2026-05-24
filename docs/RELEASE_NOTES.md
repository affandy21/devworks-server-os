# Release Notes

## Devworks Server OS Preview

Tanggal dokumentasi: 2026-05-20

## Ringkasan

Release preview ini menyiapkan Devworks Server OS sebagai ISO bootable berbasis Debian dengan GUI Devworks, Devworks Control Center native, dan installer permanen ke disk.

## ISO

```text
dist/devworks-server-os.iso
SHA256: f4ebde934a5da0391b8f82f11a3682ed785e76435085a9e19dacc381b167b7e5

dist/devworks-server-os-autoinstall.iso
SHA256: d31a48c842c81ca9f313e4d4a06d0e02081db24554cea915776678175addb921
```

Release ini juga menyertakan:

- Package manifest dari ISO final.
- Detached GPG signatures untuk ISO, checksum, dan manifest.
- Public release signing key.

GPG fingerprint:

```text
426072F517789C47A914345A4F53E388EE9884EA
```

## Fitur Baru

- Installer permanen ke disk.
- Manual confirm disk untuk ISO standar.
- Profil autoinstall untuk VirtualBox.
- Desktop GUI dengan wallpaper Devworks.
- Shortcut Devworks Control Center di desktop.
- Devworks Control Center native GTK.
- Grafik realtime untuk CPU, memory, disk, dan network.
- Icon Applications grid Devworks.
- Control Center tidak lagi terbuka otomatis saat startup.

## Perbaikan

- Wallpaper default disesuaikan dengan aset Devworks yang diberikan.
- Control Center dibuat muat di layar VirtualBox 1024x768.
- Shortcut desktop dibuat tersedia setelah instalasi permanen.
- Icon yang hilang atau berubah menjadi tanda seru diperbaiki.
- Icon Applications dikembalikan ke gaya grid, bukan logo utama Devworks.

## Batasan

- Dualboot otomatis belum didukung.
- Mode installer saat ini masih `erase-disk`.
- ISO autoinstall tidak boleh dipakai pada mesin yang memiliki data penting.
- Validasi server fisik tetap harus dilakukan sebelum production.

## Rekomendasi Upgrade Berikutnya

- First boot wizard.
- Installer dualboot non-destructive.
- Service manager untuk web dan AI.
- Hardening SSH production.
- Repository update internal.
- Source request email khusus untuk release production.

## v0.1.1-server-hardening

Release ini menambahkan hardening untuk server kosong yang akan dipakai lebih serius.

### Added

- Profil installer `installer/profiles/production-server.env`.
- Installer-style admin username/password prompt for permanent installs.
- SSH public key prompt/required modes.
- Optional first-login password expiration for hash-based installs.
- SSH empty password hardening.
- Reduced SSH max authentication tries.
- Admin web UI local-only binding via `ADMIN_WEB_UI_BIND=127.0.0.1`.
- Sysctl production hardening profile.
- Production validation checks.
- Server backup/restore documentation.

### Changed

- Bare-metal profile now asks for the real admin password during install.
- Bare-metal and production profiles now use prompted credentials instead of a shared default hash.
- Bare-metal admin web UI now binds to localhost by default.
- README documents the production hardening profile.

### Backup Artifact

Local backup created:

```text
C:\root\backups\devworks-server-backup-20260524-040912.tar.gz
C:\root\backups\devworks-server-backup-20260524-040912.tar.gz.sha256
```

### Remaining Production Requirements

- Use prompted credentials or provide a unique hash for automated deployment.
- Provide SSH authorized keys before disabling SSH password login.
- Provide real TLS certificate files or switch to certbot after DNS is ready.
- Validate restore of each web/AI project from backup.
