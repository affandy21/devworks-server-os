# Devworks Server OS Production Readiness

This document defines the production default for Devworks Server OS.

## Default Policy

Devworks Server OS is a server platform. It must not assume which public
workloads the administrator wants to run.

Default installation policy:

- SSH is available for administration.
- UFW is enabled with deny incoming and allow outgoing.
- Only the SSH port is opened by default.
- Fail2ban and unattended security updates are enabled.
- Native Devworks Control Center is available on GUI profiles.
- Web server packages may be installed as tooling, but `nginx` is not enabled.
- AI runtime is not installed, not enabled, and no model is loaded.
- Docker daemon is not enabled by default.
- Public HTTP, HTTPS, AI, and admin UI ports are closed.

## Feature Activation

Use `dw` after first login. The long command `devworks` remains available as
the canonical name, while `dw` is the short administrator command.

```bash
sudo dw status
sudo dw templates
sudo dw audit --save
sudo dw qa --save
```

Enable a public web/TLS stack only after DNS points to the server:

```bash
sudo dw enable web \
  --domain example.com \
  --tls certbot \
  --email admin@example.com \
  --open-firewall
```

Enable a local AI runtime only when the server has enough resources:

```bash
sudo dw enable ai \
  --runtime ollama \
  --bind 127.0.0.1 \
  --memory-max 8G \
  --cpu-quota 300%
```

Install Podman without enabling a daemon:

```bash
sudo dw enable container podman
```

Enable Docker only when a daemon-based container runtime is required:

```bash
sudo dw enable container docker
```

Create and verify an on-server backup after application files are restored:

```bash
sudo dw backup create --source /srv/devworks --dest /var/backups/devworks
sudo dw backup restore --archive /var/backups/devworks/devworks-backup-YYYYMMDD-HHMMSS.tar.gz --target /srv/restore-test
```

Schedule a daily backup only after the restore path has been tested:

```bash
sudo dw backup schedule --source /srv/devworks --dest /var/backups/devworks --calendar "*-*-* 02:30:00"
systemctl list-timers devworks-backup.timer
```

## Public Server Checklist

Before publishing a server to the internet:

- Replace temporary passwords with unique credentials.
- Use SSH keys and keep SSH password authentication disabled.
- Confirm `sudo ufw status verbose` opens only required ports.
- Confirm `systemctl --failed` is empty.
- Confirm `sudo dw status` matches the intended workload profile.
- Run `sudo dw audit --save` and review every WARN/FAIL.
- Run `sudo dw qa --save` after each reboot test.
- Issue TLS certificates after DNS is correct.
- Configure on-server and off-server backup, then test restore.
- Apply resource limits to AI and heavy background jobs.
- Reboot and repeat validation.

## Why AI Is Opt-In

AI workloads can consume large amounts of memory, CPU, disk, and GPU resources.
Starting AI automatically is unsafe for a general server OS because many users
only need web, database, or administration features. Devworks Server OS provides
templates and commands, but the administrator decides when AI is installed and
started.

## Why Web Is Opt-In

A public web service needs a domain, TLS, firewall policy, application files,
and logging choices. Starting a default web service on every installation opens
unnecessary attack surface. Devworks Server OS keeps the server quiet until the
administrator explicitly enables web publishing.
