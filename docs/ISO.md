# Devworks Server OS ISO

Dokumen ini merangkum status ISO Devworks Server OS. Manual lengkap ada di `docs/DEVWORKS_SERVER_OS_MANUAL.md`.

## File ISO

```text
dist/devworks-server-os.iso
```

Checksum build terakhir tersedia di file `.sha256`:

```text
dist/devworks-server-os.iso.sha256
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
- Mode dual boot UEFI `manual-partition` yang mempertahankan EFI Windows.
- Firmware grafis dasar AMD, Intel, dan NVIDIA pada sistem hasil instalasi.
- Profil manual dual boot khusus UEFI dan pengujian keselamatannya.

Tidak lagi berlaku:

- Status lama yang menyebut installer permanen belum tersedia.
- Status lama yang menyebut Control Center otomatis terbuka saat startup.

## Rekomendasi Pemakaian

Gunakan ISO standar untuk:

- VirtualBox manual test.
- PC server kosong.
- Laptop/PC uji tanpa data penting.

ISO autoinstall lama, bila masih diarsipkan, hanya boleh digunakan untuk:

- VirtualBox.
- Disk uji yang boleh dihapus otomatis.
- Pipeline test yang memang menargetkan `/dev/sda`.

ISO autoinstall tersebut bukan artefak rilis v0.2.1 untuk pemasangan fisik.

## Catatan Dual Boot

Dual boot UEFI tersedia melalui profil manual:

```text
installer/profiles/dualboot-manual.env
```

Installer tidak melakukan resize partisi dan tidak memilih ruang kosong secara otomatis. Administrator harus memperkecil partisi Windows terlebih dahulu, memilih partisi Linux khusus sebagai root, dan memastikan `FORMAT_EFI="no"`. ISO autoinstall tetap khusus disk uji VirtualBox yang boleh dihapus.
