# ISO Build Status

Status build saat ini: berhasil.

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
