# Devworks Server OS Installer

The installer installs Devworks Server OS permanently from a live Linux
environment. It has a destructive blank-disk mode and a guarded UEFI
manual-partition mode for installing alongside an existing Windows system.

## Quick Start

From the live desktop or live terminal:

```bash
sudo devworks-installer
```

The wizard asks for the target disk, hostname, admin username, and first SSH
policy. It writes a temporary config and then calls the full installer.

For advanced installs, copy and edit a config manually:

```bash
cp installer/config.env.example installer/config.env
nano installer/config.env
sudo bash installer/devworks-install.sh --config installer/config.env
```

The `erase-disk` mode is destructive. For blank-disk installs, keep the
interactive confirmation enabled:

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

## Dual Boot UEFI

Dual boot is supported only with the guarded `manual-partition` mode on UEFI
systems. The installer does not resize Windows partitions. Prepare space in
Windows first, using Disk Management, and create/select a dedicated Linux root
partition from the live environment.

Never use the VirtualBox autoinstall ISO for dual boot.

Recommended procedure:

1. Back up files and save the BitLocker recovery key if encryption is enabled.
2. Disable Windows Fast Startup and hibernation.
3. Shrink the Windows partition using Windows Disk Management.
4. Boot the standard Devworks ISO in UEFI mode.
5. Copy `installer/profiles/dualboot-manual.env` to a working config and fill:

```bash
INSTALL_MODE="manual-partition"
TARGET_BOOT_MODE="efi"
TARGET_ROOT_PARTITION="/dev/nvme0n1p6"
TARGET_EFI_PARTITION="/dev/nvme0n1p1"
TARGET_SWAP_PARTITION=""
FORMAT_ROOT="yes"
FORMAT_EFI="no"
DEVWORKS_MANUAL_CONFIRM_DISK="yes"
```

6. Run the installer. It prints the chosen partitions and requires:

```text
INSTALL /dev/nvme0n1p6 KEEP-EFI /dev/nvme0n1p1
```

Only the selected Linux root partition is formatted. The existing FAT32 EFI
partition is mounted without formatting. When the Microsoft EFI bootloader is
present, GRUB includes a `Windows Boot Manager` menu entry. Before formatting
root, the installer writes a GPT partition table backup and stores a copy in
`/var/backups/devworks-installer/` on the new system.

## Main Parameters

- `INSTALL_MODE`: `erase-disk` for an empty disk, or `manual-partition` for guarded UEFI dual boot.
- `TARGET_DISK`: disk to erase and install onto, or `auto` for the disk picker.
- `TARGET_ROOT_PARTITION`: dedicated Linux root partition to format in `manual-partition` mode.
- `TARGET_EFI_PARTITION`: existing FAT32 EFI partition to preserve and reuse in `manual-partition` mode.
- `FORMAT_EFI`: must remain `no` in `manual-partition` mode.
- `DEVWORKS_MANUAL_CONFIRM_DISK`: show disk list and require typed confirmation.
- `DEVWORKS_ALLOW_INSTALL_ON_MOUNTED_DISK`: default `no`; keep it disabled for safety.
- `TARGET_BOOT_MODE`: `auto`, `efi`, or `bios`.
- `ADMIN_USER`: administrator account.
- `ADMIN_PASSWORD_MODE`: `prompt`, `hash`, or `locked`.
- `ADMIN_PASSWORD_HASH`: SHA-512 password hash from `openssl passwd -6`; only used with `ADMIN_PASSWORD_MODE=hash`.
- `ENABLE_AUTOLOGIN`: GUI autologin for lab/preview systems.
- `SSH_PASSWORD_AUTH`: temporary password login for setup.
- `SSH_KEY_SETUP_MODE`: `prompt`, `required`, or `skip`.
- `SSH_AUTHORIZED_KEYS_FILE`: SSH public keys copied into the admin account.
- `ENABLE_UFW`: firewall activation.
- `TLS_MODE`: `off`, `self-signed`, `existing`, or `certbot`; default `off`.
- `ENABLE_WEB_STACK`: explicit opt-in to enable nginx during install; default `no`.
- `ENABLE_AI_RUNTIME`: explicit opt-in to enable AI runtime during install; default `no`.
- `ENABLE_CONTAINER_RUNTIME`: explicit opt-in for `podman` or `docker`; default `none`.
- `INSTALL_WEB_FEATURE_PACKAGES`: install web tooling without enabling public web service.
- `ENABLE_SERVICE_WIZARD`: installs the `dw`/`devworks` feature manager and service templates.
- `ENABLE_GUI`: installs XFCE and LightDM.
- `ENABLE_NATIVE_MONITOR`: installs native Devworks Control Center.
- `ENABLE_HARDWARE_BACKPORTS`: opt-in newer Debian backports kernel/firmware for hardware that needs it.
- `ENABLE_WINDOWS_BOOT_DETECTION`: adds Windows Boot Manager to GRUB when its EFI loader exists.

## Recommended Production Changes

Before installing on a real server:

```bash
ADMIN_PASSWORD_MODE="prompt"
ENABLE_AUTOLOGIN="no"
SSH_PASSWORD_AUTH="no"
SSH_KEY_SETUP_MODE="required"
TLS_MODE="off"
ENABLE_WEB_STACK="no"
ENABLE_AI_RUNTIME="no"
ENABLE_CONTAINER_RUNTIME="none"
ENABLE_AUTO_REBOOT_AFTER_SECURITY_UPDATE="no"
```

Deploy SSH keys through:

```bash
SSH_AUTHORIZED_KEYS_FILE="/root/authorized_keys"
```

For manual installs, the recommended path is to let the installer prompt for
the admin username, full name, password, and SSH public key path. Do not keep a
shared default password in production profiles.

## Feature Activation After Install

The production default is intentionally quiet. Web apps, AI runtimes, container
daemons, and public HTTP/HTTPS firewall rules are not started automatically.

Use the feature manager after first login. `dw` is the short command; `devworks`
is kept as the long canonical command.

```bash
sudo dw status
sudo dw templates
sudo dw enable web --domain example.com --tls certbot --email admin@example.com --open-firewall
sudo dw enable ai --runtime ollama --bind 127.0.0.1 --memory-max 8G --cpu-quota 300%
sudo dw enable container podman
```
