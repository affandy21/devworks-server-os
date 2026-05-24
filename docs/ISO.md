# Devworks Server OS ISO

Dokumen ini merangkum status ISO Devworks Server OS. Manual lengkap ada di `docs/DEVWORKS_SERVER_OS_MANUAL.md`.

## File ISO

```text
dist/devworks-server-os.iso
dist/devworks-server-os-autoinstall.iso
```

Checksum build terakhir tersedia di file `.sha256`:

```text
dist/devworks-server-os.iso.sha256
dist/devworks-server-os-autoinstall.iso.sha256
```

Release asset tambahan:

```text
devworks-server-os-package-manifest.tsv
devworks-server-os-package-manifest.tsv.sha256
devworks-server-os-release-signing-key.asc
*.asc detached GPG signatures
```

GPG signing key fingerprint:

```text
426072F517789C47A914345A4F53E388EE9884EA
```

## Status

Sudah tersedia:

- ISO bootable berbasis Debian.
- Desktop GUI ringan.
- Wallpaper dan tema Devworks.
- Devworks Control Center native.
- Shortcut Devworks Control Center di desktop.
- Installer permanen ke disk.
- Konfirmasi manual disk untuk ISO standar.
- Profil autoinstall khusus VirtualBox.

Tidak lagi berlaku:

- Status lama yang menyebut installer permanen belum tersedia.
- Status lama yang menyebut Control Center otomatis terbuka saat startup.

## Rekomendasi Pemakaian

Gunakan ISO standar untuk:

- VirtualBox manual test.
- PC server kosong.
- Laptop/PC uji tanpa data penting.

Gunakan ISO autoinstall hanya untuk:

- VirtualBox.
- Disk uji yang boleh dihapus otomatis.
- Pipeline test yang memang menargetkan `/dev/sda`.

## Catatan Dualboot

Dualboot otomatis belum didukung. Manual confirm disk hanya mengurangi risiko salah pilih disk, bukan membuat installer non-destructive.

Untuk dualboot dibutuhkan workflow baru yang bisa resize partisi, memilih partisi kosong, memasang GRUB tanpa menghapus OS lama, dan melakukan backup tabel partisi.
