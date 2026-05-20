# VirtualBox Reboot Test

## NAT Port Forwarding

Recommended:

- Host `2222` -> Guest `22`
- Host `18088` -> Guest `8088`
- Host `18080` -> Guest `80`
- Host `18443` -> Guest `443`

## Reboot Loop

After installing to the VM disk and enabling SSH:

```bash
COUNT=5 SSH_HOST=127.0.0.1 SSH_PORT=2222 SSH_USER=devworks \
  bash installer/tests/reboot-test.sh
```

## Manual Checks

```bash
ssh -p 2222 devworks@127.0.0.1
sudo systemctl --failed
sudo ufw status verbose
curl -fsS http://127.0.0.1/health
curl -kfsS https://127.0.0.1/health
```
