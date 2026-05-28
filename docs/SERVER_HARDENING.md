# Devworks Server OS Server Hardening

This document describes the production-oriented hardening profile for Devworks Server OS.

## Status

`v0.1.1-server-hardening` is intended for server validation and production-preparation on a dedicated empty server.

It is more secure than the preview profile, but every production deployment must still be validated on the target hardware and network.

## Main Changes

- Autologin disabled for bare-metal and production profiles.
- SSH root login disabled.
- SSH password authentication disabled in production profile.
- SSH empty passwords disabled.
- SSH max authentication tries reduced.
- Admin username/password can be collected interactively during installation.
- Admin web UI is disabled by default; native Control Center remains available on GUI installs.
- UFW allows only SSH by default.
- HTTP, HTTPS, AI, container daemons, and admin UI ports are opt-in.
- The `devworks` CLI provides explicit web, TLS, AI, container, and template activation.
- Kernel/network sysctl hardening profile installed.
- Production installer validation checks SSH, autologin, and hardening files.
- Dedicated `installer/profiles/production-server.env` profile added.

## Production Install Profile

Use:

```bash
sudo bash installer/devworks-install.sh --config installer/profiles/production-server.env
```

Before running, review:

```text
TARGET_DISK
ADMIN_PASSWORD_MODE
SSH_AUTHORIZED_KEYS_FILE
TLS_DOMAIN
ENABLE_WEB_STACK
ENABLE_AI_RUNTIME
ENABLE_CONTAINER_RUNTIME
```

Use `erase-disk` only for an empty server disk. For UEFI dual boot, use `manual-partition`, which formats only the selected Linux root partition and preserves the existing EFI partition after manual confirmation.

## Required Pre-Install Files

Production profile expects:

```text
/root/devworks-authorized_keys
```

The production profile requires `/root/devworks-authorized_keys`. This avoids creating a server where SSH password login is disabled but no key is installed.

## First Login

The production profile uses `ADMIN_PASSWORD_MODE=prompt`, so the installer asks
for the real admin password during installation. There is no shared production
password baked into the profile.

For fully automated installs, generate a new password hash:


```bash
openssl passwd -6
```

Then set:

```bash
ADMIN_PASSWORD_MODE="hash"
ADMIN_PASSWORD_HASH="..."
```

## Post-Install Validation

After boot:

```bash
sudo devworks-validation-checklist
systemctl --failed
sudo ufw status verbose
sudo dw status
```

SSH from another machine:

```bash
ssh devworks@SERVER_IP
```

## Enabling Public Web/TLS

Production installs do not publish a web service until the administrator opts in:

```bash
sudo dw enable web --domain example.com --tls certbot --email admin@example.com --open-firewall
sudo dw status
```

For a local HTTPS smoke test without opening public ports:

```bash
sudo dw enable web --domain devworks.local --tls self-signed
```

## Enabling AI

AI is always opt-in because it can consume large CPU, RAM, and GPU resources:

```bash
sudo dw enable ai --runtime ollama --bind 127.0.0.1 --memory-max 8G --cpu-quota 300%
```

## Still Not Included

- Automatic Windows partition resize; dual boot requires administrator-prepared free space.
- Automated restore of every application stack from `C:\root\server`.
- Hardware-specific GPU driver validation.
- Formal external security audit.
