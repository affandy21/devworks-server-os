# Server Backup and Restore

This document explains the backup created from the Windows server folder and how to restore it on Devworks Server OS.

## Backup Source

```text
C:\root\server
```

Backup output:

```text
C:\root\backups\devworks-server-backup-20260524-040912.tar.gz
C:\root\backups\devworks-server-backup-20260524-040912.tar.gz.sha256
```

## Verify Backup on Windows

```powershell
Get-FileHash C:\root\backups\devworks-server-backup-20260524-040912.tar.gz -Algorithm SHA256
Get-Content C:\root\backups\devworks-server-backup-20260524-040912.tar.gz.sha256
```

## Copy Backup to Devworks Server OS

Example with SCP:

```powershell
scp C:\root\backups\devworks-server-backup-20260524-040912.tar.gz devworks@SERVER_IP:/home/devworks/
scp C:\root\backups\devworks-server-backup-20260524-040912.tar.gz.sha256 devworks@SERVER_IP:/home/devworks/
```

## Restore on Devworks Server OS

```bash
cd /home/devworks
sha256sum -c devworks-server-backup-20260524-040912.tar.gz.sha256
sudo mkdir -p /srv/imported
sudo tar -xzf devworks-server-backup-20260524-040912.tar.gz -C /srv/imported
sudo chown -R devworks:devworks /srv/imported/server
```

The restored tree will be:

```text
/srv/imported/server
```

Expected top-level directories:

```text
/srv/imported/server/ai
/srv/imported/server/devworks.co.id
/srv/imported/server/devworks.id
/srv/imported/server/payroll-ci4-local
```

## Move a Web Project Into Production Path

Example:

```bash
sudo rsync -a /srv/imported/server/devworks.co.id/ /srv/devworks/web/
sudo chown -R www-data:www-data /srv/devworks/web
sudo nginx -t
sudo systemctl reload nginx
```

## Container Projects

If a project contains `docker-compose.yml` or `compose.yml`, inspect it before starting:

```bash
find /srv/imported/server -maxdepth 3 \( -name docker-compose.yml -o -name compose.yml \) -print
```

Then run from the selected project directory:

```bash
podman compose up -d
```

or, if Docker is enabled:

```bash
docker compose up -d
```

## Important

Do not blindly run old scripts as root on the new server. Review `.env`, database credentials, TLS paths, service ports, and firewall requirements first.

