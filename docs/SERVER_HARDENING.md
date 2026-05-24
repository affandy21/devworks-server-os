# Devworks Server OS v0.1.1 Server Hardening

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
- Admin password expires on first login.
- Admin web UI binds to `127.0.0.1` by default.
- UFW allows only SSH, HTTP, and HTTPS by default.
- Admin UI port `8088` is not opened by UFW.
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
ADMIN_PASSWORD_HASH
SSH_AUTHORIZED_KEYS_FILE
TLS_DOMAIN
TLS_CERT_SOURCE
TLS_KEY_SOURCE
```

The installer remains destructive in `erase-disk` mode. It is suitable for an empty server disk, not a dualboot disk.

## Required Pre-Install Files

Production profile expects:

```text
/root/devworks-authorized_keys
/root/tls/fullchain.pem
/root/tls/privkey.pem
```

The production profile requires `/root/devworks-authorized_keys`. This avoids creating a server where SSH password login is disabled but no key is installed.

## First Login

The admin password is expired intentionally. On first login, set a new strong password.

Default preview hash is still present as a placeholder and must be replaced before real production use.

Generate a new password hash:

```bash
openssl passwd -6
```

Then replace `ADMIN_PASSWORD_HASH` in the selected installer profile.

## Post-Install Validation

After boot:

```bash
sudo devworks-validation-checklist
systemctl --failed
sudo ufw status verbose
sudo nginx -t
curl -I http://127.0.0.1/health
curl -kI https://127.0.0.1/health
```

SSH from another machine:

```bash
ssh devworks@SERVER_IP
```

## Admin UI Access

The remote admin web UI binds to localhost:

```text
127.0.0.1:8088
```

Use SSH tunneling if needed:

```bash
ssh -L 8088:127.0.0.1:8088 devworks@SERVER_IP
```

Then open:

```text
http://127.0.0.1:8088
```

## Still Not Included

- Automatic dualboot support.
- Automated restore of every application stack from `C:\root\server`.
- Hardware-specific GPU driver validation.
- Formal external security audit.
