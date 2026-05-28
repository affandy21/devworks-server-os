# Build Result: v0.2.1-dualboot-hardware

ISO standar Devworks Server OS v0.2.1 berhasil dibangun ulang dan artefak
rilis ditandatangani pada 28 Mei 2026 WIB.

## Artefak Rilis

```text
dist/devworks-server-os.iso
dist/devworks-server-os.iso.sha256
dist/devworks-server-os.iso.asc
dist/devworks-server-os.iso.sha256.asc
dist/devworks-server-os-package-manifest.tsv
dist/devworks-server-os-package-manifest.tsv.sha256
dist/devworks-server-os-package-manifest.tsv.asc
dist/devworks-server-os-package-manifest.tsv.sha256.asc
dist/devworks-server-os-release-signing-key.asc
```

```text
SHA256 ISO: 76182a46025ef6d0f1c3b4680c981e251469699fa033997de530a6f713af583f
GPG fingerprint: 426072F517789C47A914345A4F53E388EE9884EA
```

`devworks-server-os-autoinstall.iso` yang mungkin masih tersimpan adalah aset
laboratorium lama untuk VM dengan disk disposable, bukan media rilis v0.2.1.

## Verifikasi Lulus

- Syntax shell, static dual boot safety guard, dan release policy guard.
- Isi ISO: versi `0.2.1`, profil dual boot, guard EFI, GRUB Windows, splash boot, paket firmware, launcher native tepercaya dengan dukungan `gio`, dan layanan web/admin/fail2ban dimask pada sesi live.
- Uji disk virtual loop GPT: partisi Linux diformat, ESP dan loader Microsoft tetap dipertahankan, backup GPT dibuat, dan partisi Microsoft data ditolak sebagai root.
- SHA256 dan detached GPG signature untuk ISO serta package manifest.
- QA VirtualBox UEFI dari ISO final: install permanen `INSTALL_EXIT=0`,
  fallback `/boot/efi/EFI/BOOT/BOOTX64.EFI` tersedia, boot berhasil tanpa ISO,
  `dw` tersedia di PATH user, dan Control Center native berjalan.

## Cakupan GUI dan Hardware

- Desktop XFCE ringan, wallpaper Devworks, icon Applications grid, dan Control Center native masuk ke ISO.
- Firmware dasar AMD, Intel, dan NVIDIA GSP masuk ke ISO; driver proprietary NVIDIA/CUDA tetap opt-in.
- ISO masih harus diuji pada perangkat fisik target sebelum dipakai sebagai server publik. Mode dual boot tidak melakukan resize Windows otomatis.
