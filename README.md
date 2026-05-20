# Devworks Server OS

Devworks Server OS adalah sistem Linux kustom berbasis Debian Stable untuk server web, runtime AI, dan monitoring lokal. Build saat ini sudah memiliki ISO bootable, desktop GUI ringan, Devworks Control Center native, dan installer permanen ke disk.

Manual lengkap:

```text
docs/DEVWORKS_SERVER_OS_MANUAL.md
```

Dokumen pendukung:

```text
docs/SPEC.md
docs/ISO.md
docs/VIRTUALBOX_SETUP.md
docs/BUILD_RESULT.md
docs/ISO_BUILD_STATUS.md
docs/RELEASE_NOTES.md
docs/ROADMAP.md
```

## Status Singkat

- Bisa boot sebagai live ISO di VirtualBox.
- Bisa dipasang permanen ke disk virtual kosong.
- GUI tersedia dengan tema dan wallpaper Devworks.
- Devworks Control Center berjalan sebagai aplikasi native, bukan browser/webview.
- Monitoring CPU, memory, disk, network, dan service tersedia dengan grafik realtime.
- Installer memakai manual confirm disk untuk mengurangi risiko salah pilih disk.
- Dualboot otomatis belum didukung. Mode installer saat ini adalah `erase-disk`.

## File ISO

```text
dist/devworks-server-os.iso
dist/devworks-server-os-autoinstall.iso
```

Checksum build terakhir:

```text
devworks-server-os.iso
SHA256: f4ebde934a5da0391b8f82f11a3682ed785e76435085a9e19dacc381b167b7e5

devworks-server-os-autoinstall.iso
SHA256: d31a48c842c81ca9f313e4d4a06d0e02081db24554cea915776678175addb921
```

## Struktur Proyek

```text
admin-ui/     Devworks Admin UI/API lama
config/       konfigurasi sistem dan daftar paket
dist/         hasil ISO
docs/         dokumentasi resmi proyek
installer/    skrip installer permanen dan profil instalasi
iso/          konfigurasi live ISO
scripts/      skrip build dan helper
services/     unit systemd Devworks
```

## Build ISO

Build dilakukan dari Linux/Debian builder:

```bash
sudo bash scripts/build-iso.sh
```

Hasil build akan masuk ke:

```text
dist/devworks-server-os.iso
```

## Instalasi Aman

Untuk VirtualBox atau PC server kosong, gunakan ISO standar:

```text
dist/devworks-server-os.iso
```

Installer akan menampilkan daftar disk dan meminta konfirmasi manual seperti:

```text
ERASE /dev/sda
```

Jangan gunakan ISO autoinstall di PC/laptop yang memiliki data penting.
