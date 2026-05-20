# Devworks Empty Disk Install Test

This procedure validates installation on a blank VirtualBox disk before bare metal.

## VM Settings

- Name: Devworks Server OS Install Test
- Type: Linux / Debian 64-bit
- Memory: 4096 MB minimum
- CPU: 2 cores minimum
- Disk: 30 GB dynamically allocated, empty
- Network: NAT
- Optical disk: `dist/devworks-server-os.iso`
- Boot order: optical, hard disk

## Installer Steps

1. Boot the ISO.
2. Open a terminal.
3. Copy the installer config:

   ```bash
   cp installer/config.env.example installer/config.env
   nano installer/config.env
   ```

4. Set:

   ```bash
   TARGET_DISK="/dev/sda"
   DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK="yes"
   ENABLE_AUTOLOGIN="yes"
   SSH_PASSWORD_AUTH="yes"
   ```

5. Run:

   ```bash
   sudo bash installer/devworks-install.sh --config installer/config.env
   ```

6. Power off.
7. Remove ISO from optical drive.
8. Boot from disk.

## Expected Results

- GRUB menu says Devworks Server OS.
- System boots to GUI.
- Only one Devworks Control Center icon exists.
- Native monitor starts automatically.
- SSH is active.
- UFW is active.
- Nginx health endpoint returns `ok`.
- Web and AI services are enabled after reboot.

## Post-Boot Validation

```bash
sudo bash installer/tests/validation-checklist.sh
systemctl --failed
ss -tulpn
curl -fsS http://127.0.0.1/health
curl -kfsS https://127.0.0.1/health
```
