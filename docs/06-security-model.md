# Security Model

---

## Threat Model

PiCore is a personal cloud server exposed to the public internet via Tailscale
Funnel. The following threats are in scope:

| Threat | Likelihood | Mitigation |
|---|---|---|
| SSH brute force | High | Fail2Ban (ban after 5 attempts) |
| Web login brute force | Medium | Fail2Ban + Nextcloud lockout |
| Unauthorized access to services | Medium | Tailscale ZTNA (no open ports) |
| Data exfiltration | Low | Data never leaves Pi without auth |
| Physical access attack | Very low | Not addressed (edge deployment) |
| Supply chain (malicious Docker image) | Low | All images from official registries |
| Compromised Telegram bot token | Low | Allow_from restriction (owner ID only) |

---

## Layer 1: Zero-Trust Network Access (Tailscale ZTNA)

**What it is:** Tailscale implements the ZTNA security model using WireGuard
as the underlying protocol. No traditional port forwarding. Every connection
is authenticated and encrypted.

**How it works:**
- Tailscale Funnel accepts inbound HTTPS on port 443
- Traffic is routed through Tailscale's global relay servers
- Pi receives traffic over an encrypted WireGuard tunnel
- No ports are open directly to the internet

**Verification:**
```bash
# Confirm no ports are open to internet directly
sudo nmap -p 1-65535 <your-public-ip>
# Should show all ports filtered/closed except what Tailscale manages
```

---

## Layer 2: UFW Firewall

**Configuration:**

```
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
Anywhere                   ALLOW       10.56.54.0/24  (local subnet)
```

**What this means:**
- SSH (22) open for admin access via Tailscale
- HTTP/HTTPS (80/443) open for Nginx (Tailscale Funnel terminates here)
- Local subnet allowed full access (for direct admin on same network)
- Everything else: DENY by default

---

## Layer 3: Fail2Ban — Intrusion Prevention

**Active jails:**

```ini
[sshd]
enabled  = true
maxretry = 5
bantime  = 3600
findtime = 600

[nextcloud]
enabled  = true
maxretry = 5
bantime  = 3600
```

Fail2Ban monitors `/var/log/auth.log` for SSH and Nextcloud's log for
failed logins. After 5 failed attempts in 10 minutes, the source IP is
added to UFW deny rules for 1 hour.

**Check current bans:**
```bash
sudo fail2ban-client status sshd
sudo fail2ban-client status nextcloud
```

---

## Layer 4: Nginx Rate Limiting

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req zone=api burst=20 nodelay;
```

Maximum 10 requests per second per IP address. Burst of 20 allowed before
rejection with HTTP 429.

This prevents:
- API endpoint flooding
- Credential stuffing attacks
- Denial-of-service via request volume

---

## Layer 5: TLS Encryption

All public endpoints use HTTPS enforced by Tailscale's automatic certificate
management. Tailscale provides valid TLS certificates for `*.ts.net` domains.

The certificate is valid, browser-trusted, and rotated automatically.

---

## Layer 6: Nextcloud Application Security

- User accounts required for all file access
- Share links: optional password, optional expiry
- Admin account separate from user accounts
- Trusted domains enforced (only `raspberrypi-1.tail2767bf.ts.net` accepted)

---

## PicoClaw Security Boundary

PicoClaw runs with a dedicated limited user. It cannot access the filesystem
outside its workspace and cannot execute system commands directly.

All privileged operations route through the Spring Boot API:
```
Telegram message → PicoClaw → Spring Boot API → controlled action
```

The API has no endpoints for destructive operations by default. Each
dangerous action (container restart, backup trigger) requires an explicit
endpoint addition with appropriate guards.

```json
"isolation": {},
"agents": {
  "defaults": {
    "restrict_to_workspace": true,
    "allow_read_outside_workspace": false
  }
}
```

**Security warning from PicoClaw config (visible in logs):**
```
SECURITY: Channel allows EVERYONE (allow_from is empty)
hint: Set allow_from to your ID, or use '*' to explicitly acknowledge open access
```

**Action required:** Set `allow_from` in Telegram channel config to your
numeric Telegram user ID. Without this, anyone who finds your bot can
interact with it.

```json
"telegram": {
  "enabled": true,
  "token": "YOUR_BOT_TOKEN",
  "allow_from": ["YOUR_NUMERIC_TELEGRAM_ID"]
}
```

---

## Security Audit Checklist

```
[ ] UFW enabled and active (sudo ufw status)
[ ] Fail2Ban running (sudo fail2ban-client status)
[ ] Tailscale connected (tailscale status)
[ ] No ports directly open (nmap scan from external)
[ ] Nextcloud HTTPS-only (test with http:// → should redirect or fail)
[ ] Portainer on local network only (not exposed via Nginx)
[ ] PicoClaw allow_from set to your Telegram ID
[ ] API keys not in any committed file (git log --all -p | grep nvapi)
[ ] Docker socket not unnecessarily exposed
[ ] Swapfile permissions 600 (ls -la /swapfile)
```

Run the full checklist:
```bash
bash security/security-audit-checklist.md
# (see security/ directory for the executable version)
```
