# SSL/TLS Setup

PiCore uses Tailscale's automatic certificate management for TLS.
No manual certificate configuration required.

---

## How It Works

Tailscale automatically provisions and renews TLS certificates for
`*.ts.net` domains via Let's Encrypt. The certificate is valid,
browser-trusted, and renewed before expiry automatically.

```
Browser → HTTPS request to raspberrypi-1.tail2767bf.ts.net
        → Tailscale verifies certificate (*.tail2767bf.ts.net)
        → WireGuard tunnel to Pi
        → Nginx Proxy Manager on port 80 (HTTP internally)
```

TLS terminates at the Tailscale layer. Traffic inside the Pi's
Docker network is unencrypted HTTP — acceptable since it never
leaves the Pi.

---

## Verify Certificate

```bash
# From any machine:
curl -I https://raspberrypi-1.tail2767bf.ts.net/api/health

# Should return: HTTP/2 200 with valid TLS
# Certificate issuer: Let's Encrypt via Tailscale
```

In browser: green padlock → Certificate details:
- Issued to: `raspberrypi-1.tail2767bf.ts.net`
- Issued by: Let's Encrypt
- Valid for: 90 days (auto-renewed)

---

## Enable HTTPS in Tailscale

In Tailscale admin console (admin.tailscale.com):
1. DNS tab
2. Toggle "Enable HTTPS" → ON
3. Wait ~60 seconds for certificate provisioning

On Pi:
```bash
# Verify Tailscale cert is active
sudo tailscale cert raspberrypi-1.tail2767bf.ts.net
```

---

## Why Not Self-Signed Certificates

Self-signed certificates:
- Cause browser warnings (NET::ERR_CERT_AUTHORITY_INVALID)
- Require manual installation in every client's trust store
- Expire and require manual renewal

Tailscale certificates:
- Trusted by all browsers automatically
- Auto-renewed
- Zero configuration

---

## Why Not Certbot/ACME Directly

Direct Let's Encrypt via Certbot requires:
- An open port 80 for ACME HTTP challenge
- A public IP (not always available)
- Port forwarding on router

PiCore has no open ports — Tailscale Funnel handles everything.
Certbot is therefore not usable in this architecture.

---

## NPM SSL Configuration

Nginx Proxy Manager is set to "HTTP Only" for the proxy host
because TLS is handled upstream by Tailscale. If you want NPM
to also handle TLS (double TLS — uncommon), you can:

1. NPM → Proxy Hosts → Edit → SSL tab
2. Request a new SSL certificate via Let's Encrypt
3. This requires port 80 challenge — works via Tailscale Funnel

For most cases: leave NPM on HTTP Only. Tailscale handles TLS.
