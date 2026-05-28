# Release Notes

## Devworks Server OS Preview

Tanggal dokumentasi: 2026-05-20

## Ringkasan

Release preview ini menyiapkan Devworks Server OS sebagai ISO bootable berbasis Debian dengan GUI Devworks, Devworks Control Center native, dan installer permanen ke disk.

## ISO

```text
dist/devworks-server-os.iso
dist/devworks-server-os.iso.sha256

dist/devworks-server-os-autoinstall.iso
dist/devworks-server-os-autoinstall.iso.sha256
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

- Dual boot hanya didukung dengan mode manual-partition dan UEFI; installer
  tidak mengecilkan partisi Windows otomatis.
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

## v0.1.2-production-readiness

Release line ini mengubah Devworks Server OS menjadi platform server yang lebih aman secara default: OS menyediakan fitur, tetapi tidak menjalankan workload publik sebelum administrator memilih.

### Added

- `dw` short command with `devworks` as the long canonical feature manager CLI.
- Template systemd untuk web app, AI runtime, dan backup timer.
- Command opt-in untuk web/TLS, AI runtime, dan container.
- Resource limit AI melalui `MemoryMax` dan `CPUQuota`.

### Changed

- Web stack default: tersedia, tetapi `nginx` tidak enabled.
- AI runtime default: tidak dibuat dan tidak berjalan.
- Container runtime default: `none`; Docker daemon tidak enabled otomatis.
- UFW default: hanya SSH, HTTP/HTTPS dibuka hanya dengan opt-in.
- Admin web UI default: off; native Control Center tetap tersedia.
- Production profile tidak lagi meminta TLS file sebelum install. TLS diterbitkan setelah DNS siap.

### Recommended Activation

```bash
sudo dw status
sudo dw enable web --domain example.com --tls certbot --email admin@example.com --open-firewall
sudo dw enable ai --runtime ollama --bind 127.0.0.1 --memory-max 8G --cpu-quota 300%
```

## v0.2.0-server-qa

Release line ini menambahkan prosedur operasional agar Devworks Server OS lebih siap dipakai sebagai server publik yang dikendalikan administrator.

### Added

- `sudo dw audit --save` untuk audit SSH, UFW, failed units, public listener, TLS certificate, dan policy service opt-in.
- `sudo dw qa --save` untuk smoke test release candidate setelah install dan reboot.
- `sudo dw backup create` untuk membuat arsip backup dengan checksum.
- `sudo dw backup restore` untuk restore arsip ke target uji atau target produksi.
- `sudo dw backup schedule` dan `sudo dw backup unschedule` untuk timer backup systemd.
- `docs/QA_RELEASE_CHECKLIST.md` sebagai checklist build, install, reboot, backup, dan release.
- Ringkasan disk installer sebelum tindakan erase.
- Deteksi signature OS/filesystem lama sebelum disk dihapus.

### Changed

- Installer standar memberi konteks disk yang lebih jelas sebelum user mengetik konfirmasi manual.
- Prosedur production readiness sekarang memasukkan audit, QA, backup, dan restore test.

### Operational Notes

- Web, AI, dan container daemon tetap tidak auto-start pada instalasi awal.
- Backup lokal membantu rollback cepat, tetapi server publik tetap membutuhkan backup off-server.
- `dw audit` bisa menghasilkan WARN untuk service yang memang sengaja dibuka ke publik; administrator harus mencocokkan hasil audit dengan desain deployment.

## v0.2.1-dualboot-hardware

Release line ini menambahkan instalasi berdampingan dengan Windows secara manual dan menutup kekurangan firmware pada hasil instalasi fisik.

### Added

- Mode installer `manual-partition` untuk dual boot UEFI.
- Profil `installer/profiles/dualboot-manual.env`.
- Guard yang melarang format EFI di mode dual boot.
- Konfirmasi partisi eksplisit sebelum root Linux diformat.
- Backup tabel partisi GPT sebelum instalasi dual boot.
- Deteksi loader EFI Microsoft dan menu GRUB `Windows Boot Manager`.
- Firmware AMD, Intel, dan NVIDIA dasar pada sistem hasil instalasi.
- Opsi `ENABLE_HARDWARE_BACKPORTS` untuk GPU/perangkat lebih baru.
- Static safety test untuk guard dual boot di GitHub Actions.
- Integration test pada disk GPT virtual untuk membuktikan ESP Windows dipertahankan dan partisi Microsoft data ditolak.
- Verifikasi isi ISO otomatis serta package manifest yang diambil langsung dari ISO final.
- Shortcut Control Center menjalankan aplikasi GTK native langsung dan ditandai tepercaya satu kali pada sesi desktop.
- Sesi live mem-mask nginx, admin web UI, dan fail2ban sampai konfigurasi instalasi permanen diterapkan.
- `dw` dan `devworks` tersedia di PATH user standar melalui `/usr/local/bin`.

### Safety Notes

- Installer tidak mengecilkan partisi Windows; ruang harus disiapkan dari Windows terlebih dahulu.
- Dual boot hanya didukung dalam boot UEFI.
- `devworks-server-os-autoinstall.iso` tetap tidak aman untuk PC dengan data penting.
- Driver proprietary NVIDIA dan CUDA tetap opt-in sesuai GPU yang dipasang.

### Verified Artifact

```text
SHA256: 76182a46025ef6d0f1c3b4680c981e251469699fa033997de530a6f713af583f
GPG fingerprint: 426072F517789C47A914345A4F53E388EE9884EA
```

### Final QA

- ISO content verification: passed.
- GPG signature verification: passed.
- VirtualBox UEFI clean install: passed.
- Permanent disk boot without ISO: passed.
- Runtime policy: SSH/UFW active; nginx, web health, AI, Docker, and admin web
  UI not active until administrator opt-in.
- Native Devworks Control Center: passed.
