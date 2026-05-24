# Devworks Server OS Manual

Dokumen ini adalah manual operasional untuk Devworks Server OS, sebuah sistem Linux kustom berbasis Debian yang dibuat untuk server web, runtime AI, monitoring lokal, dan instalasi permanen ke disk.

## 1. Ringkasan

Devworks Server OS dibuat sebagai sistem server sederhana, stabil, dan mudah dipantau. Sistem ini memakai basis Debian Stable agar tetap realistis untuk server production: kernel, paket keamanan, systemd, OpenSSH, firewall, dan layanan server mengikuti ekosistem Linux yang matang.

Komponen utama:

- Debian Stable base system.
- Kernel Linux amd64 untuk PC/laptop/server Intel atau AMD 64-bit.
- Desktop XFCE ringan dengan tema Devworks.
- Devworks Control Center sebagai aplikasi native GTK, bukan browser atau webview.
- Installer permanen ke disk.
- SSH, UFW, Fail2ban, tooling Nginx opt-in, dan update keamanan otomatis.
- Dukungan service web dan AI tersedia sebagai fitur opt-in melalui `dw`/`devworks`, bukan auto-start bawaan.

## 2. Status Build Saat Ini

Status saat ini:

- Bisa boot di VirtualBox.
- Bisa berjalan sebagai live ISO.
- Bisa dipasang permanen ke disk virtual kosong.
- Desktop GUI tersedia.
- Wallpaper default memakai wallpaper Devworks yang diberikan.
- Shortcut Devworks Control Center tersedia di desktop.
- Devworks Control Center tidak terbuka otomatis saat startup.
- Devworks Control Center menampilkan metrik CPU, memory, disk, network, service, dan grafik realtime.
- Menu Applications memakai icon grid Devworks, bukan logo utama.
- Installer memiliki konfirmasi manual disk untuk mengurangi risiko salah hapus disk.

Catatan penting:

- Sistem ini adalah OS kustom berbasis Debian, bukan kernel baru dari nol.
- Stabilitas production tetap perlu validasi hardware, backup, dan uji restart di target sebenarnya.
- Dualboot belum otomatis. Mode installer saat ini adalah erase-disk dengan konfirmasi manual.

## 3. File ISO

File build berada di:

```text
dist/devworks-server-os.iso
dist/devworks-server-os-autoinstall.iso
```

Checksum build terakhir:

```text
devworks-server-os.iso
SHA256: a5e5c8d4b9d51ccccc9296027b93ac9e4bb207ab6c5aca718ccb0c65dcbe5d79

devworks-server-os-autoinstall.iso
SHA256: d31a48c842c81ca9f313e4d4a06d0e02081db24554cea915776678175addb921
```

Release tambahan:

```text
devworks-server-os-package-manifest.tsv
devworks-server-os-package-manifest.tsv.sha256
devworks-server-os-release-signing-key.asc
*.asc detached GPG signatures
```

Fungsi SHA256:

- Memastikan file ISO tidak rusak.
- Memastikan ISO yang dipakai sama persis dengan hasil build.
- Membantu validasi sebelum dipasang ke PC/server asli.

Contoh cek checksum di Windows PowerShell:

```powershell
Get-FileHash .\dist\devworks-server-os.iso -Algorithm SHA256
Get-FileHash .\dist\devworks-server-os-autoinstall.iso -Algorithm SHA256
```

Fingerprint GPG signing key:

```text
426072F517789C47A914345A4F53E388EE9884EA
```

Contoh verifikasi di Linux:

```bash
gpg --import devworks-server-os-release-signing-key.asc
gpg --verify devworks-server-os.iso.asc devworks-server-os.iso
sha256sum -c devworks-server-os.iso.sha256
```

## 4. Edisi ISO

### ISO Standar

```text
dist/devworks-server-os.iso
```

Gunakan ini untuk testing manual, VirtualBox, laptop, atau PC server kosong. Installer akan meminta konfirmasi disk sebelum menghapus dan memasang sistem.

### ISO Autoinstall

```text
dist/devworks-server-os-autoinstall.iso
```

Gunakan hanya untuk VirtualBox atau target uji yang memang boleh dihapus otomatis. Profil ini memakai target `/dev/sda` dan tidak cocok untuk PC/laptop yang punya data penting.

## 5. Kebutuhan Minimum

Minimum yang disarankan:

- CPU: Intel/AMD 64-bit.
- RAM: 4 GB minimum, 8 GB atau lebih disarankan untuk AI ringan.
- Disk: 32 GB minimum, 80 GB atau lebih disarankan.
- Network: Ethernet atau adapter jaringan yang didukung kernel Debian.
- VirtualBox: EFI boleh dimatikan untuk jalur BIOS sederhana.

Untuk workload AI:

- RAM 16 GB atau lebih.
- Disk SSD.
- GPU NVIDIA memerlukan instalasi driver dan runtime tambahan sesuai model GPU.

## 6. Akun Admin

Live ISO/lab build masih memakai user awal untuk masuk ke sesi live bila diperlukan:

```text
Username: devworks
Password: devworks
```

Untuk instalasi permanen ke disk, installer sekarang bekerja seperti OS server umum:

- Installer meminta username admin.
- Installer meminta password admin baru dan konfirmasi password.
- Installer dapat memasang SSH public key ke akun admin.
- Profil production tidak menyimpan password default bersama.

Rekomendasi setelah instalasi production:

- Matikan autologin bila server dipasang di lokasi fisik yang tidak aman.
- Nonaktifkan login SSH memakai password jika sudah memakai SSH key.

## 7. Instalasi Permanen Ke Disk

Installer permanen tersedia melalui skrip:

```text
/opt/devworks/installer/install-devworks-os.sh
```

Mode installer saat ini:

```text
INSTALL_MODE=erase-disk
```

Artinya installer akan membuat sistem baru di disk target dan menghapus isi disk tersebut setelah konfirmasi.

Alur aman ISO standar:

1. Boot ISO di VirtualBox atau PC target.
2. Login sebagai user default jika diperlukan.
3. Jalankan installer permanen.
4. Installer menampilkan daftar disk.
5. Pilih disk target.
6. Ketik konfirmasi sesuai instruksi, misalnya:

```text
ERASE /dev/sda
```

7. Tunggu proses selesai.
8. Reboot.
9. Lepas ISO dari virtual optical drive.
10. Boot dari disk hasil instalasi.

## 8. Manual Confirm Disk

Manual confirm disk dibuat agar installer tidak langsung menghapus disk tanpa validasi manusia.

Variabel penting:

```text
DEVWORKS_MANUAL_CONFIRM_DISK=yes
TARGET_DISK=auto
DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK=no
INSTALL_MODE=erase-disk
```

Perilaku:

- Jika `TARGET_DISK=auto`, installer akan menampilkan disk dan meminta pilihan.
- Jika `DEVWORKS_MANUAL_CONFIRM_DISK=yes`, installer meminta kalimat konfirmasi.
- Jika disk target sedang mounted, installer menolak kecuali override diaktifkan.
- Jika `INSTALL_MODE` bukan `erase-disk`, installer berhenti karena mode lain belum didukung.

## 9. Dualboot

Status dualboot:

```text
Belum didukung otomatis.
```

Manual confirm disk membantu mencegah salah pilih disk, tetapi belum membuat installer aman untuk dualboot. Dualboot butuh workflow terpisah:

- Deteksi partisi yang sudah ada.
- Resize partisi tanpa merusak data.
- Install ke partisi kosong yang dipilih.
- Konfigurasi GRUB agar OS lama tetap terdeteksi.
- Backup tabel partisi sebelum perubahan.
- Konfirmasi tambahan untuk setiap operasi destructive.

Untuk saat ini, jika ingin dualboot, gunakan disk terpisah atau lakukan partisi manual dengan backup penuh terlebih dahulu.

## 10. Desktop dan GUI

GUI memakai XFCE ringan agar cocok untuk server. Tampilan disesuaikan dengan tema Devworks:

- Wallpaper default Devworks.
- Panel sederhana.
- Icon Applications bergaya grid.
- Shortcut Devworks Control Center di desktop.
- Devworks Control Center tidak auto-open saat startup.

Tujuan GUI bukan mengganti seluruh desktop environment dari nol, tetapi memberi pengalaman server OS yang rapi, ringan, dan mudah dipantau.

## 11. Devworks Control Center

Devworks Control Center adalah aplikasi native GTK. Aplikasi ini bukan halaman browser dan bukan webview.

Fitur:

- Monitoring CPU realtime.
- Monitoring memory realtime.
- Monitoring disk.
- Monitoring network.
- Grafik ringkas untuk metrik utama.
- Status service penting.
- Tampilan dibuat agar muat di resolusi VirtualBox 1024x768.

Catatan teknis:

- Metrik dibaca dari sistem Linux seperti `/proc`, `/sys`, dan command system.
- Pembaruan realtime tetap memakai interval refresh ringan di aplikasi GUI, karena event kernel mentah tidak menyediakan semua angka agregat UI secara langsung.
- Untuk production, sampling interval harus dibuat ringan agar tidak membebani server.

## 12. Service Default

Service yang aktif pada profil production minimal:

```text
ssh
ufw
fail2ban
chrony
unattended-upgrades
```

Service GUI:

```text
lightdm
xfce4-session
```

Service web dan AI dapat ditambahkan sebagai unit systemd atau container dengan restart policy.

Devworks Server OS tidak menjalankan workload publik secara otomatis. Gunakan:

```bash
sudo dw status
sudo dw templates
sudo dw enable web --domain example.com --tls certbot --email admin@example.com --open-firewall
sudo dw enable ai --runtime ollama --bind 127.0.0.1 --memory-max 8G --cpu-quota 300%
sudo dw enable container podman
```

Contoh Docker service policy:

```bash
docker update --restart unless-stopped NAMA_CONTAINER
```

Contoh systemd service:

```ini
[Unit]
Description=Devworks Web Service
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/devworks-web-start

[Install]
WantedBy=multi-user.target
```

## 13. Network dan Port

Port yang umum dipakai:

```text
22    SSH
80    HTTP, hanya jika user mengaktifkan web publik
443   HTTPS/TLS, hanya jika user mengaktifkan web publik
8088  Devworks Admin UI lama atau API lokal jika diaktifkan
11434 Ollama atau runtime AI lokal jika dipakai
```

Untuk VirtualBox NAT port forwarding yang pernah dipakai:

```text
Host 2224  -> Guest 22
Host 18080 -> Guest 80
Host 18443 -> Guest 443
Host 18089 -> Guest 8088
```

Untuk server production, buka hanya port yang diperlukan.

## 14. TLS

TLS untuk production sebaiknya memakai Nginx reverse proxy.

Rekomendasi:

- Gunakan certificate valid dari Let's Encrypt atau certificate resmi lain.
- Simpan certificate di lokasi standar, misalnya `/etc/letsencrypt`.
- Buka port 80 dan 443 hanya saat web publik siap dipasang.
- Jalankan renewal otomatis.
- Uji setelah reboot.

Aktivasi TLS production:

```bash
sudo dw enable web --domain DOMAIN_ANDA --tls certbot --email admin@example.com --open-firewall
sudo nginx -t
sudo systemctl status nginx --no-pager
curl -I https://DOMAIN_ANDA
```

## 15. Firewall dan Fail2ban

UFW disiapkan sebagai firewall sederhana.

Contoh baseline:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status verbose
```

Port web dibuka oleh `sudo dw enable web ... --open-firewall` setelah admin memilih domain dan TLS.

Fail2ban digunakan untuk mengurangi brute force SSH.

Validasi:

```bash
sudo systemctl status fail2ban --no-pager
sudo fail2ban-client status
```

## 16. Update Keamanan Otomatis

Update keamanan otomatis memakai `unattended-upgrades`.

Validasi:

```bash
sudo systemctl status unattended-upgrades --no-pager
sudo unattended-upgrade --dry-run --debug
```

Rekomendasi production:

- Aktifkan update security otomatis.
- Jangan otomatis upgrade paket besar tanpa testing.
- Lakukan backup sebelum perubahan besar.
- Jadwalkan maintenance window untuk reboot kernel.

## 17. GRUB dan Recovery Mode

GRUB dipakai sebagai bootloader.

Recovery mode penting untuk:

- Reset password.
- Perbaikan service yang gagal boot.
- Perbaikan network.
- Rollback konfigurasi.
- Mount root filesystem untuk rescue.

Checklist:

```bash
sudo update-grub
grep -i recovery /boot/grub/grub.cfg
```

Untuk server fisik, pastikan akses console tersedia melalui monitor lokal, IPMI, KVM, atau remote console provider.

## 18. Validasi Setelah Install

Setelah boot dari disk permanen, jalankan:

```bash
hostnamectl
lsblk
df -h
free -h
ip addr
systemctl --failed
sudo ufw status verbose
sudo systemctl status ssh --no-pager
sudo systemctl status fail2ban --no-pager
sudo dw status
```

Uji akses SSH:

```bash
ssh devworks@IP_SERVER
```

Uji HTTP hanya setelah web diaktifkan:

```bash
sudo dw enable web --domain IP_SERVER --tls off --open-firewall
curl -I http://IP_SERVER
```

Uji TLS jika domain sudah diarahkan:

```bash
curl -I https://DOMAIN_ANDA
```

## 19. Prosedur Uji Restart VirtualBox

Prosedur uji minimal:

1. Install OS ke disk virtual kosong.
2. Reboot.
3. Lepas ISO dari optical drive.
4. Pastikan boot dari disk.
5. Login ke desktop.
6. Buka Devworks Control Center.
7. Cek tidak ada service failed.
8. Restart VM minimal 3 kali.
9. Pastikan hasil tetap konsisten.

Command validasi di guest:

```bash
systemctl --failed
systemctl is-active ssh ufw fail2ban
sudo dw status
```

## 20. Prosedur Uji Disk Kosong

Target uji:

- VirtualBox VM baru.
- Disk virtual baru, kosong, minimal 32 GB.
- ISO Devworks Server OS terpasang sebagai optical disk.

Langkah:

1. Boot ISO standar.
2. Jalankan installer.
3. Pilih disk target yang kosong.
4. Konfirmasi `ERASE /dev/sdX`.
5. Tunggu selesai.
6. Shutdown.
7. Lepas ISO.
8. Boot ulang dari disk.
9. Jalankan checklist validasi.

## 21. Instalasi Ke PC atau Server Intel

Bisa dipasang ke PC/laptop/server Intel 64-bit selama hardware didukung kernel Debian.

Syarat aman:

- Backup semua data.
- Gunakan ISO standar, bukan autoinstall.
- Pastikan disk target benar.
- Untuk server kosong, mode erase-disk cocok.
- Untuk dualboot, jangan gunakan installer ini sebelum workflow dualboot non-destructive dibuat.

Rekomendasi untuk server kosong:

- Pasang hanya satu disk saat instalasi pertama jika memungkinkan.
- Cabut disk berisi data penting agar tidak salah pilih.
- Setelah instalasi stabil, baru tambahkan disk data tambahan.

## 22. Batasan Saat Ini

Batasan yang masih perlu dicatat:

- Dualboot otomatis belum tersedia.
- Installer saat ini fokus pada erase-disk.
- Driver GPU AI production belum dibuat universal untuk semua model GPU.
- Belum ada sistem update OS versi resmi seperti repository sendiri.
- Hardening production perlu disesuaikan lagi dengan domain, IP publik, TLS, backup, dan model deployment web/AI.

## 23. Roadmap

Roadmap yang disarankan:

1. Installer dualboot non-destructive.
2. Wizard setup awal untuk user, password, hostname, timezone, dan network.
3. Devworks repository internal untuk update paket OS.
4. Snapshot dan rollback otomatis.
5. Backup scheduler.
6. Native service manager untuk Web dan AI.
7. Health check SSH, TLS, firewall, disk, dan runtime AI.
8. Build release dengan nomor versi dan changelog.

## 24. Identitas Build

Nama produk:

```text
Devworks Server OS
```

Basis:

```text
Debian Stable amd64
```

Target:

```text
Server web, server AI, dan workstation administrasi ringan.
```

Status:

```text
Preview stabil untuk VirtualBox dan server kosong berbasis Intel/AMD 64-bit.
```

## 25. Upstream dan Source Code

Devworks Server OS memakai komponen upstream seperti Debian, Linux kernel, GNU utilities, systemd, XFCE, LightDM, OpenSSH, Nginx, UFW, dan Fail2ban.

Atribusi dan link source code upstream tersedia di:

```text
docs/THIRD_PARTY_NOTICES.md
docs/SOURCE_CODE_OFFER.md
```

Permintaan source code dan compliance:

```text
https://github.com/affandy21/devworks-server-os/issues/new/choose
```

Catatan penting:

- Linux adalah merek dagang Linus Torvalds.
- Debian adalah merek dagang Software in the Public Interest, Inc.
- Devworks Server OS tidak diklaim sebagai produk resmi Debian atau kernel.org.
- Jika suatu release memodifikasi Linux kernel, source code kernel hasil modifikasi harus dipublikasikan atau ditawarkan sesuai kewajiban lisensinya.
