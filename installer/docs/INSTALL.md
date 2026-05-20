# Devworks Server OS Installer

The installer is a destructive permanent disk installer for Devworks Server OS.
It is intended to run from a live Linux environment.

## Quick Start

```bash
cp installer/config.env.example installer/config.env
nano installer/config.env
sudo bash installer/devworks-install.sh --config installer/config.env
```

The installer is destructive in the current `erase-disk` mode. For manual
installs, keep the interactive confirmation enabled:

```bash
DEVWORKS_MANUAL_CONFIRM_DISK="yes"
TARGET_DISK="auto"
```

The installer will show disks with `lsblk`, ask you to choose a disk, then
require this exact confirmation before erasing anything:

```text
ERASE /dev/sdX
```

Fully automated installs refuse to erase a disk unless this value is set:

```bash
DEVWORKS_I_UNDERSTAND_THIS_ERASES_DISK="yes"
```

Do not set the automated erase flag on a laptop or server that has more than
one disk unless you have verified the target disk out of band.

## Dualboot Status

Dualboot is not enabled in this installer yet. `INSTALL_MODE="erase-disk"`
always replaces the selected disk. A proper dualboot workflow needs a separate
non-destructive partition mode that can reuse an existing EFI System Partition
and install Devworks into prepared free space without touching Windows/Linux
partitions.

## Main Parameters

- `INSTALL_MODE`: currently only `erase-disk`.
- `TARGET_DISK`: disk to erase and install onto, or `auto` for the disk picker.
- `DEVWORKS_MANUAL_CONFIRM_DISK`: show disk list and require typed confirmation.
- `DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK`: default `no`; keep it disabled for safety.
- `TARGET_BOOT_MODE`: `auto`, `efi`, or `bios`.
- `ADMIN_USER`: administrator account.
- `ADMIN_PASSWORD_HASH`: SHA-512 password hash from `openssl passwd -6`.
- `ENABLE_AUTOLOGIN`: GUI autologin for lab/preview systems.
- `SSH_PASSWORD_AUTH`: temporary password login for setup.
- `ENABLE_UFW`: firewall activation.
- `TLS_MODE`: `self-signed`, `existing`, `certbot`, or `off`.
- `ENABLE_WEB_STACK`: enables nginx and web target service.
- `ENABLE_AI_RUNTIME`: enables AI runtime service.
- `ENABLE_GUI`: installs XFCE and LightDM.
- `ENABLE_NATIVE_MONITOR`: installs native Devworks Control Center.

## Recommended Production Changes

Before installing on a real server:

```bash
ENABLE_AUTOLOGIN="no"
SSH_PASSWORD_AUTH="no"
TLS_MODE="existing"
ENABLE_AUTO_REBOOT_AFTER_SECURITY_UPDATE="no"
```

Deploy SSH keys through:

```bash
SSH_AUTHORIZED_KEYS_FILE="/root/authorized_keys"
```
