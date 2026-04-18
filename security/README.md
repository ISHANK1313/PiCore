# Security

PiCore implements a layered security model with six distinct layers.

## Quick Hardening

```bash
# UFW
sudo bash ufw-setup.sh

# Fail2Ban
sudo bash fail2ban-setup.sh

# Tailscale ZTNA
# See ztna-setup.md
```

## Security Layers

| Layer | Tool | Status |
|---|---|---|
| Zero-Trust Network | Tailscale ZTNA | ✅ Active |
| Firewall | UFW | ✅ Active |
| Intrusion Prevention | Fail2Ban | ✅ Active |
| Rate Limiting | Nginx | ✅ Active |
| TLS Encryption | Tailscale auto-cert | ✅ Active |
| Application Auth | Nextcloud accounts | ✅ Active |

## Files

| File | Purpose |
|---|---|
| `ufw-setup.sh` | Configure UFW firewall rules |
| `fail2ban-setup.sh` | Install and configure Fail2Ban |
| `ztna-setup.md` | Tailscale ZTNA setup guide |
| `ssl-setup.md` | TLS/HTTPS configuration |
| `security-audit-checklist.md` | Full audit checklist |

## Quick Audit

```bash
sudo ufw status verbose
sudo fail2ban-client status
tailscale status
curl -I https://raspberrypi-1.tail2767bf.ts.net/api/health
```
