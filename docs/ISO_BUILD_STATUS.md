# ISO Build Status

Status build saat ini: berhasil.

## Output

```text
dist/devworks-server-os.iso
dist/devworks-server-os-autoinstall.iso
```

## Checksum

```text
devworks-server-os.iso
SHA256: f4ebde934a5da0391b8f82f11a3682ed785e76435085a9e19dacc381b167b7e5

devworks-server-os-autoinstall.iso
SHA256: d31a48c842c81ca9f313e4d4a06d0e02081db24554cea915776678175addb921
```

## Perubahan Dari Fase Awal

Dokumen lama pernah mencatat bahwa ISO belum bisa dibuat penuh dari Windows/WSL. Status itu tidak lagi menjadi status utama proyek.

Saat ini proyek sudah memiliki:

- ISO bootable.
- GUI desktop.
- Devworks Control Center native.
- Installer permanen ke disk.
- Profil autoinstall untuk VirtualBox.
- Manual confirm disk untuk ISO standar.

## Build

Build tetap paling aman dilakukan di lingkungan Linux/Debian:

```bash
sudo bash scripts/build-iso.sh
```

## Uji Yang Disarankan

Untuk setiap release baru:

1. Boot ISO standar di VirtualBox.
2. Jalankan live desktop.
3. Buka Devworks Control Center.
4. Install ke disk virtual kosong.
5. Lepas ISO.
6. Boot dari disk.
7. Restart VM minimal 3 kali.
8. Cek `systemctl --failed`.
9. Cek SSH, HTTP/TLS, UFW, dan Fail2ban.

