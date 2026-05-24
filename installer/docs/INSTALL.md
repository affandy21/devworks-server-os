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
