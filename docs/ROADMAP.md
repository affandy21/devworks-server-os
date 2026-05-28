# Roadmap

Roadmap ini melanjutkan Devworks Server OS dari build VirtualBox stabil menuju OS server yang lebih siap production.

## Fase 1: Stabilitas Installer

Status: berjalan.

- Installer permanen ke disk.
- Manual confirm disk.
- Profil VirtualBox manual dan autoinstall.
- Validasi boot dari disk setelah ISO dilepas.
- Uji restart berkali-kali.

## Fase 2: First Boot Wizard

Target:

- Set hostname.
- Set timezone.
- Buat user admin.
- Ganti password default.
- Pilih autologin aktif atau nonaktif.
- Pilih mode server: web, AI, atau hybrid.

## Fase 3: Dualboot Non-Destructive

Status: mode manual tersedia; pengujian perlu diperluas.

- Deteksi OS dan partisi yang sudah ada.
- Pilih partisi kosong.
- Pertahankan EFI dan masukkan Windows Boot Manager ke GRUB.
- Resize partisi otomatis tetap tidak dilakukan untuk menjaga keamanan data.
- Backup partition table.
- Pengujian lanjutan matrix Windows/UEFI untuk mode `manual-partition` dan GRUB Windows Boot Manager.

## Fase 4: Service Manager

Target:

- Kelola service web dari Devworks Control Center.
- Kelola service AI.
- Health check SSH, HTTP, TLS, UFW, dan runtime AI.
- Template systemd untuk aplikasi web dan worker AI.

## Fase 5: Security Hardening

Target:

- SSH key-first.
- Disable password SSH sebagai opsi production.
- UFW profile per mode server.
- Fail2ban jail tambahan.
- Audit log untuk aksi admin.

## Fase 6: Release Engineering

Target:

- Nomor versi OS.
- Changelog.
- Release checksum.
- ISO signing.
- Repository update internal.
- Automated VirtualBox/QEMU smoke test.

## Fase 7: Backup dan Recovery

Target:

- Snapshot sebelum update besar.
- Backup konfigurasi.
- Restore checklist.
- Recovery mode terdokumentasi.
- Export diagnostic bundle untuk troubleshooting.
