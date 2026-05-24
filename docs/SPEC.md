# Devworks Server OS Specification

Spesifikasi ini menjelaskan bentuk teknis Devworks Server OS pada build saat ini. Manual operasional lengkap ada di `docs/DEVWORKS_SERVER_OS_MANUAL.md`.

## Persona Pengguna

Devworks Server OS ditujukan untuk admin server yang ingin menjalankan:

- Website production.
- API service.
- Runtime atau service AI.
- Monitoring lokal tanpa selalu masuk SSH.
- Desktop administrasi ringan untuk server fisik atau VM.

## Prinsip Desain

- Basis OS memakai Debian Stable agar stabil dan mudah diaudit.
- Sistem tetap sederhana, tidak membuat kernel baru dari nol.
- Workload aplikasi disarankan berjalan sebagai systemd service atau container.
- Workload web, AI, container daemon, dan port publik tidak aktif otomatis; administrator mengaktifkannya melalui `dw` atau nama panjang `devworks`.
- GUI dipakai untuk administrasi dan monitoring, bukan sebagai lapisan wajib untuk menjalankan server.
- Konfigurasi penting tetap berbasis file teks dan systemd.
- Operasi destructive wajib memakai konfirmasi manual pada ISO standar.
- Perubahan besar harus diuji di VirtualBox sebelum dipasang ke server fisik.

## Komponen Utama

| Komponen | Pilihan |
| --- | --- |
| Base system | Debian Stable amd64 |
| Kernel | Linux kernel Debian |
| Init/service manager | systemd |
| Bootloader | GRUB |
| Desktop | XFCE ringan |
| Display manager | LightDM |
| Monitoring GUI | Devworks Control Center native GTK |
| Web server | Nginx tersedia sebagai fitur opt-in |
| SSH | OpenSSH |
| Firewall | UFW |
| Brute-force protection | Fail2ban |
| Time sync | Chrony |
| Security updates | unattended-upgrades |
| Installer | Devworks permanent disk installer |
| Feature manager | `dw` / `devworks` CLI |

## UI/UX

Desktop menyediakan:

- Wallpaper default Devworks.
- Panel sederhana.
- Icon Applications bertema Devworks grid.
- Shortcut Devworks Control Center di desktop.
- Control Center tidak auto-open saat startup.

Devworks Control Center menampilkan:

- CPU usage dan grafik realtime.
- Memory usage dan grafik realtime.
- Disk usage.
- Network throughput.
- Kernel, hostname, uptime, dan informasi runtime.
- Status service penting.
- Status service opsional ditampilkan sebagai komponen yang bisa diaktifkan, bukan diasumsikan wajib berjalan.

## Kebijakan Workload Default

Setelah instalasi production, OS hanya menyiapkan platform:

- SSH dan firewall aktif.
- Update keamanan otomatis aktif.
- GUI/native monitoring tersedia jika profil GUI dipilih.
- Web stack tersedia tetapi `nginx` tidak enabled.
- AI runtime tidak dibuat atau dijalankan.
- Docker daemon tidak enabled; Podman dapat dipasang tanpa daemon.
- Port 80, 443, 11434, dan 8088 tidak dibuka kecuali user memilih.

Aktivasi dilakukan secara eksplisit:

```bash
sudo dw enable web --domain example.com --tls certbot --email admin@example.com --open-firewall
sudo dw enable ai --runtime ollama --bind 127.0.0.1
sudo dw enable container podman
```

## Installer

Installer permanen memakai mode:

```text
INSTALL_MODE=erase-disk
```

ISO standar memakai:

```text
DEVWORKS_MANUAL_CONFIRM_DISK=yes
TARGET_DISK=auto
```

ISO autoinstall khusus VirtualBox memakai:

```text
DEVWORKS_MANUAL_CONFIRM_DISK=no
TARGET_DISK=/dev/sda
DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK=yes
```

## Batasan Versi Ini

- Dualboot otomatis belum tersedia.
- Mode installer non-destructive belum tersedia.
- Repository update OS milik Devworks belum tersedia.
- Driver GPU AI production perlu disesuaikan dengan hardware target.
- Autentikasi dan role management untuk admin tooling perlu dikeraskan sebelum production publik.
