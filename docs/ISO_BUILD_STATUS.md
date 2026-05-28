# ISO Build Status

Status rilis saat ini: ISO standar `v0.2.1-dualboot-hardware` berhasil
dibangun dan lolos verifikasi artefak otomatis.

## Output Utama

```text
dist/devworks-server-os.iso
dist/devworks-server-os.iso.sha256
dist/devworks-server-os.iso.asc
dist/devworks-server-os-package-manifest.tsv
dist/devworks-server-os-package-manifest.tsv.sha256
dist/devworks-server-os-package-manifest.tsv.asc
```

```text
76182a46025ef6d0f1c3b4680c981e251469699fa033997de530a6f713af583f  devworks-server-os.iso
```

## Fitur Yang Terverifikasi Dalam ISO

- GUI live dengan tema Devworks dan Control Center native.
- Installer permanen `erase-disk` untuk disk kosong.
- Installer `manual-partition` untuk UEFI dual boot dengan ESP dipertahankan.
- Backup tabel GPT sebelum pemformatan root pada mode dual boot.
- Menu GRUB Windows Boot Manager bila loader Microsoft ditemukan.
- Firmware dasar untuk Intel, AMD, dan NVIDIA GSP.
- Pada live ISO, nginx, admin web UI, dan fail2ban tidak dijalankan sebelum profil instalasi permanen mengatur layanannya.
- Launcher Control Center native menggunakan helper trust satu-kali dengan `gio`, sehingga shortcut desktop tidak membutuhkan dialog persetujuan manual berulang.
- Web, AI, container daemon, dan admin web UI tidak aktif secara default pada sistem terpasang.
- Command manager `dw` dan `devworks` tersedia di `/usr/local/bin` untuk user
  desktop dan tetap tersedia di `/usr/local/sbin` untuk operasi root.

## Build dan Tes

```bash
sudo bash scripts/build-iso.sh
bash installer/tests/verify-iso-content.sh dist/devworks-server-os.iso
sudo bash installer/tests/dualboot-loop-integration-test.sh
bash scripts/generate-iso-package-manifest.sh dist/devworks-server-os.iso dist/devworks-server-os-package-manifest.tsv
```

Pengujian VirtualBox UEFI final telah lolos pada VM bersih: ISO boot,
instalasi permanen ke disk, fallback EFI, boot tanpa ISO, policy service
opt-in, `dw status`, dan Control Center native. Untuk perangkat fisik, lakukan
backup, pemeriksaan GPU/network/storage, dan uji boot terlebih dahulu sebelum
migrasi server publik.
