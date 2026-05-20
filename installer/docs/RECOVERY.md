# Devworks Recovery

## GRUB Recovery

1. Reboot the system.
2. At GRUB, choose Advanced options.
3. Select a recovery mode kernel.
4. Use root shell.
5. Remount root:

   ```bash
   mount -o remount,rw /
   ```

## Service Recovery

```bash
systemctl --failed
journalctl -xb
systemctl restart NetworkManager ssh nginx
ufw status verbose
```

## Boot Repair From Live ISO

```bash
mount /dev/sda3 /mnt
mount /dev/sda1 /mnt/boot/efi
mount -t proc proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev
chroot /mnt
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Devworks
update-grub
exit
reboot
```
