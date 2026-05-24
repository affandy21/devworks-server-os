# Devworks Server OS QA and Release Checklist

This checklist is used before publishing a Devworks Server OS ISO as a stable
candidate.

## Local ISO Verification

```bash
sha256sum -c devworks-server-os.iso.sha256
gpg --verify devworks-server-os.iso.asc devworks-server-os.iso
```

## VirtualBox Install Test

Use a new VM with an empty virtual disk:

- CPU: 2 cores or more.
- Memory: 4 GB or more.
- Disk: 32 GB or more.
- Network: NAT for basic boot, bridged or forwarded ports for SSH tests.

Test flow:

1. Boot the ISO.
2. Confirm boot menu renders correctly.
3. Start installer.
4. Verify the installer summary shows the correct target disk.
5. Type the required erase confirmation only after checking the disk.
6. Finish install.
7. Remove ISO.
8. Boot from the virtual disk.
9. Login.
10. Run:

```bash
sudo dw qa --save
sudo dw audit --save
systemctl --failed
sudo ufw status verbose
```

## Reboot Stability Test

Repeat at least three times:

```bash
sudo reboot
```

After every reboot:

```bash
sudo dw qa --save
```

Expected default state:

- SSH active.
- UFW active.
- Fail2ban active or available.
- Nginx not enabled.
- AI runtime not enabled.
- Docker daemon not enabled.
- Ports 80, 443, 8088, and 11434 not listening on all interfaces unless explicitly enabled.

## Feature Opt-In Tests

Web local test:

```bash
sudo dw enable web --domain devworks.local --tls self-signed
curl -kI https://127.0.0.1/health
sudo dw disable web
```

AI placeholder test:

```bash
sudo dw enable ai --runtime placeholder --bind 127.0.0.1 --memory-max 512M --cpu-quota 50%
systemctl status devworks-ai --no-pager
sudo dw disable ai
```

Backup test:

```bash
sudo mkdir -p /srv/devworks/test
echo ok | sudo tee /srv/devworks/test/health.txt
sudo dw backup create --source /srv/devworks --dest /var/backups/devworks --name qa-backup
sudo dw backup restore --archive /var/backups/devworks/qa-backup.tar.gz --target /srv/qa-restore
test -f /srv/qa-restore/devworks/test/health.txt
```

## Release Asset Checklist

Publish these assets together:

- `devworks-server-os.iso`
- `devworks-server-os.iso.sha256`
- `devworks-server-os.iso.asc`
- `devworks-server-os.iso.sha256.asc`
- `devworks-server-os-package-manifest.tsv`
- `devworks-server-os-package-manifest.tsv.sha256`
- `devworks-server-os-release-signing-key.asc`
- Release notes and screenshots.

## Stop Conditions

Do not publish a stable candidate if:

- The ISO does not boot.
- The installer summary points to the wrong disk.
- `sudo dw qa --save` reports failed critical checks.
- SSH cannot be validated.
- UFW is inactive.
- Web, AI, or Docker starts automatically on a default production profile.
- GPG verification fails.
