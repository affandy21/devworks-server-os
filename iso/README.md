# Devworks Server OS ISO

Folder ini berisi konfigurasi `live-build` untuk membuat ISO Linux yang bisa boot di VirtualBox.

Target fase ini sederhana:

- Boot sebagai OS Linux asli berbasis Debian Stable.
- Menjalankan kernel Linux dan systemd.
- Membawa paket server dasar.
- Menjalankan Devworks Admin UI otomatis di port `8088`.
- Cocok untuk uji awal di VirtualBox sebelum dibuat installer permanen.

## Build ISO

Jalankan dari Debian 12/Stable builder:

```bash
sudo bash scripts/build-iso.sh
```

Output:

```text
dist/devworks-server-os.iso
```

## Test di VirtualBox

1. Buat VM baru.
2. Type: `Linux`.
3. Version: `Debian (64-bit)`.
4. RAM: minimal `2048 MB`, disarankan `4096 MB`.
5. CPU: minimal `2`.
6. Storage: buat disk virtual kosong `20 GB`.
7. Mount `dist/devworks-server-os.iso` sebagai optical disk.
8. Boot VM.

Setelah boot, buka browser dari host ke:

```text
http://IP_VM:8088
```

Atau dari dalam VM:

```text
http://127.0.0.1:8088
```

## Login Live

Default live user:

```text
devworks
```

Live ISO ini belum ditujukan sebagai production install permanen. Tujuannya adalah membuktikan OS bootable dan service Devworks berjalan stabil dulu.
