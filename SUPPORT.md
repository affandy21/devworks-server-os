# Support

For operational guidance, start with:

- `docs/DEVWORKS_SERVER_OS_MANUAL.md`
- `docs/VIRTUALBOX_SETUP.md`
- `docs/ISO.md`
- `docs/RELEASE_NOTES.md`

## Common Support Data

When reporting a problem, include:

```bash
hostnamectl
lsblk
df -h
free -h
ip addr
systemctl --failed
sudo ufw status verbose
```

For installer issues, also include:

```text
/var/log/devworks-installer.log
```

Never share private keys, TLS private certificates, passwords, or production tokens.

