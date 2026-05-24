# VirtualBox Setup Guide

Panduan ini dipakai untuk menjalankan dan menguji Devworks Server OS di VirtualBox.

## Kebutuhan

- VirtualBox terinstall di Windows.
- ISO Devworks Server OS:

```text
dist/devworks-server-os.iso
```

Opsional untuk test otomatis:

```text
dist/devworks-server-os-autoinstall.iso
```

## Rekomendasi VM

```text
Name: Devworks Server OS Test
Type: Linux
Version: Debian 12 (64-bit)
RAM: 4096 MB minimum
CPU: 2 core minimum
Disk: 32 GB atau lebih, VDI dynamic
EFI: off untuk jalur BIOS sederhana
Network: NAT
```

Port forwarding NAT yang disarankan:

```text
Host 2224  -> Guest 22
Host 18080 -> Guest 80
Host 18443 -> Guest 443
Host 18089 -> Guest 8088
```

## Boot Live ISO

1. Buka VirtualBox.
2. Buat VM baru dengan spesifikasi di atas.
3. Masuk ke Settings.
4. Pilih Storage.
5. Pasang `dist/devworks-server-os.iso` sebagai optical disk.
6. Jalankan VM.
7. Tunggu desktop Devworks muncul.

Akun default:

```text
Username: devworks
Password: devworks
```

## Install Permanen Ke Disk Virtual

Gunakan ISO standar untuk test manual.

Langkah:

1. Boot ISO.
2. Buka terminal.
3. Jalankan installer permanen:

```bash
sudo /opt/devworks/installer/install-devworks-os.sh
```

4. Baca daftar disk.
5. Pilih disk virtual target.
6. Ketik konfirmasi sesuai instruksi, misalnya:

```text
ERASE /dev/sda
```

7. Tunggu instalasi selesai.
8. Shutdown VM.
9. Lepas ISO dari Storage.
10. Boot ulang dari disk virtual.

## Autoinstall Khusus VirtualBox

ISO autoinstall hanya untuk VM yang disk-nya boleh dihapus otomatis.

```text
dist/devworks-server-os-autoinstall.iso
```

Profil ini menargetkan:

```text
TARGET_DISK=/dev/sda
```

Jangan gunakan ISO autoinstall pada PC/laptop yang memiliki data penting.

## Checklist Setelah Boot Dari Disk

Di dalam guest:

```bash
hostnamectl
lsblk
df -h
free -h
ip addr
systemctl --failed
sudo ufw status verbose
```

Cek service:

```bash
systemctl is-active ssh ufw fail2ban
sudo devworks status
```

Cek SSH dari Windows host:

```powershell
ssh devworks@127.0.0.1 -p 2224
```

Cek HTTP dari Windows host:

```powershell
curl.exe -I http://127.0.0.1:18080
```

## Uji Restart

Minimal lakukan:

1. Boot dari disk permanen.
2. Login ke desktop.
3. Buka Devworks Control Center.
4. Restart VM.
5. Ulangi minimal 3 kali.
6. Pastikan desktop, wallpaper, shortcut, icon Applications, dan Control Center tetap benar.
7. Pastikan `systemctl --failed` kosong atau tidak berisi service kritis.

## Troubleshooting

Jika muncul "insert boot media":

- Pastikan ISO terpasang saat ingin live boot.
- Jika ingin boot dari hasil instalasi, pastikan ISO sudah dilepas dan disk virtual berada di boot order.
- Pastikan instalasi permanen benar-benar selesai sebelum reboot.

Jika desktop tidak muncul:

- Coba login TTY dengan `devworks/devworks`.
- Jalankan:

```bash
sudo systemctl status lightdm --no-pager
sudo systemctl restart lightdm
```

Jika network tidak aktif:

```bash
ip addr
sudo systemctl restart NetworkManager
```

Jika SSH tidak bisa:

```bash
sudo systemctl status ssh --no-pager
sudo ufw status verbose
```
