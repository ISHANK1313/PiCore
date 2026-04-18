# Zero-Trust Network Access (ZTNA) Setup

PiCore implements ZTNA using Tailscale. The principle: no network is trusted,
every connection is verified and encrypted, no implicit access based on network
location.

## What Makes This ZTNA

Traditional security: "inside the firewall = trusted"
ZTNA: "nothing is trusted. every connection must be verified"

Tailscale enforces this by:
1. Every device must authenticate via Tailscale account (identity verification)
2. All traffic is WireGuard-encrypted (no plaintext)
3. Access control lists (ACLs) define exactly who can reach what
4. No ports open to public internet — no way in without authentication

## Tailscale Setup

```bash
# Install
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate (opens browser)
sudo tailscale up

# Enable public HTTPS access via Funnel
sudo tailscale funnel --bg 80

# Verify
tailscale status
```

## Access Control Policy (Tailscale Admin Console)

Navigate to: admin.tailscale.com → Access Controls

```json
{
  "ACLs": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self:*"]
    }
  ],
  "nodeAttrs": [
    {
      "target": ["autogroup:member"],
      "attr": ["funnel"]
    }
  ]
}
```

## Funnel vs VPN

| | Tailscale Funnel | Tailscale VPN |
|---|---|---|
| Who can access | Anyone on internet | Only Tailscale members |
| Use case | Public website/API | Admin SSH access |
| Authentication | None (public) | Tailscale account |
| Protocol | HTTPS (port 443) | WireGuard (any port) |
| Pi services accessible | /hub, /tv, /api/stats | All ports |

## Why This Is Better Than Port Forwarding

Port forwarding: opens a port on your router, exposing Pi directly to internet.
Any bot/scanner that finds your IP can attempt to connect.

Tailscale Funnel: your router has NO open ports. Traffic goes
Internet → Tailscale relay → WireGuard tunnel → Pi. The router
never sees inbound connections — because there aren't any from its perspective.

## Auto-Start on Boot

Tailscale Funnel does not survive reboots by default. Add to crontab:

```bash
sudo crontab -e
# Add:
@reboot sleep 30 && tailscale funnel --bg 80
```

Or create a systemd service:

```bash
cat > /etc/systemd/system/tailscale-funnel.service << EOF
[Unit]
Description=Tailscale Funnel
After=tailscaled.service
Wants=tailscaled.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/tailscale funnel --bg 80

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable tailscale-funnel
sudo systemctl start tailscale-funnel
```
