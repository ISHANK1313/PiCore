# Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS (Port 443)
                  Tailscale Funnel
                  (WireGuard encrypted)
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                 RASPBERRY PI 4 — 1GB RAM                         │
│              raspberrypi-1.tail2767bf.ts.net                     │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ PRIMARY STACK (infrastructure/docker-compose.yml)          │  │
│  │                                                            │  │
│  │  ┌──────────────┐                   ┌─────────────────┐   │  │
│  │  │  Nginx PM    │                   │    Jellyfin     │   │  │
│  │  │  (Proxy)     │                   │  (Media Server) │   │  │
│  │  │  172.19.0.4  │                   │  172.19.0.2     │   │  │
│  │  └──────────────┘                   └─────────────────┘   │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────┐                       │  │
│  │  │ Spring Boot  │  │  Uptime Kuma │                       │  │
│  │  │  Dashboard   │  │  (Monitor)   │                       │  │
│  │  │  172.19.0.5  │  │  172.19.0.3  │                       │  │
│  │  └──────────────┘  └──────────────┘                       │  │
│  │                                                            │  │
│  │  ┌──────────────┐  ┌──────────────────────────────────┐  │  │
│  │  │  PicoClaw    │  │     opennas-frontend             │  │  │
│  │  │  (AI Agent)  │  │     (nginx:alpine)               │  │  │
│  │  │  <10MB RAM   │  │     172.20.0.2                   │  │  │
│  │  └──────────────┘  └──────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Security:  UFW (tailscale0 ingress policy) │ Fail2Ban │ Tailscale ZTNA │
│  Storage:   /dev/sda (28GB OS) │ /dev/sdc (128GB /mnt/data)    │
│  Memory:    1GB RAM + 2GB swapfile (/swapfile)                  │
└──────────────────────────────────────────────────────────────────┘
         │                               │
  ┌──────▼──────┐                ┌───────▼───────┐
  │  Telegram   │                │  Admin SSH    │
  │  Bot (AI)   │                │  Tailscale IP │
  │  PicoClaw   │                │  100.66.68.83 │
  └─────────────┘                └───────────────┘
```

---

Nextcloud is intentionally deployed as a separate Portainer-managed stack using
`infrastructure/docker-compose-snippet.yml` (not part of the primary
`infrastructure/docker-compose.yml` stack). This allows independent restarts
and resource isolation from the always-on core services.

> Note: Internal Docker bridge IPs shown in this document (for example
> `172.19.0.x`) are illustrative only and are dynamically assigned at runtime.

## Network Topology

```
Traffic Source          Path                          Destination
──────────────────────────────────────────────────────────────────
Public user (any device)
  Browser → URL         Tailscale DNS                 Pi:443
                        → Nginx PM                    → Route by path:
                                                         /hub  → :8081
                                                         /tv   → :8096
                                                         /     → :8080
                                                         /api  → :8085

Admin (owner only)
  SSH client            Tailscale VPN                 Pi:22
                        100.66.68.83

Docker internal
  Container A           Docker bridge network         Container B
                        172.x.x.0/24
```

---

## Docker Stack — Ports and Memory Limits

| Container | Stack/Deployment | Image | Internal Port | Exposed | mem_limit |
|---|---|---|---|---|---|
| npm | Primary (`docker-compose.yml`) | jc21/nginx-proxy-manager | 80,81,443 | 80,81,443 | — |
| jellyfin | Primary (`docker-compose.yml`) | lscr.io/linuxserver/jellyfin | 8096 | 8096 | 256MB |
| nas-api | Primary (`docker-compose.yml`) | custom-nas-api | 8085 | 8085 | 180MB |
| uptime-kuma | Primary (`docker-compose.yml`) | louislam/uptime-kuma | 3001 | 3001 | — |
| opennas-frontend | Primary (`docker-compose.yml`) | nginx:alpine | 80 | 8081 | — |
| nextcloud-app-1 | Separate (`docker-compose-snippet.yml` via Portainer) | nextcloud | 80 | 8080 | 400MB |
| nextcloud-db-1 | Separate (`docker-compose-snippet.yml` via Portainer) | mariadb:10.6 | 3306 | — | 200MB |
| portainer | Separate host deployment | portainer/portainer-ce | 9000,9443 | 9000,9443 | — |

**Total allocated container limits:** ~1.1GB RAM across explicitly limited
containers. Because this exceeds the Pi's 1GB physical RAM (typically
~50-100MB reserved for GPU), this design relies on the configured 2GB swapfile
under concurrent load and traffic spikes, with reduced performance expected
when swapping is active. Containers without explicit limits can raise real
runtime usage above this baseline.

---

## Request Lifecycle

```
1. User types: https://raspberrypi-1.tail2767bf.ts.net/hub

2. DNS: Tailscale resolves to Pi's Tailscale IP (100.66.68.83)

3. Tailscale Funnel: WireGuard-encrypted tunnel to Pi

4. Pi receives on port 443 (Tailscale Funnel)
   → Forwards to port 80 (Nginx PM)

5. Nginx PM checks:
   ├── Rate limit: 10 req/s per IP
   ├── SSL: auto-managed by Tailscale
   └── Route: /hub → 172.20.0.2:80 (opennas-frontend)

6. opennas-frontend serves index.html

7. index.html JavaScript polls /api/stats every 5s
   → Nginx routes /api → 172.19.0.5:8085 (Spring Boot)
   → Spring Boot reads /host/proc + /host/sys
   → Returns JSON with 40+ metrics

8. Dashboard renders live telemetry
```

---

## Data Flow

```
Input Sources:
  Browser file upload    → Nextcloud → /mnt/data/cloud-data/
  Media files (manual)   → Jellyfin  → /mnt/data/media/
  Telegram message       → PicoClaw  → Spring Boot API → Response
  System metrics         → /proc/sys → Spring Boot → Dashboard

Storage Layout (/mnt/data on 128GB USB flash):
  /mnt/data/
  ├── cloud-data/     (Nextcloud user files)
  ├── media/          (Jellyfin library)
  ├── docker/         (Docker volumes)
  └── website/        (opennas-frontend source)

Backup (daily 3AM cron):
  /mnt/data/ → rclone sync → Google Drive (gdrive:nas-backup)

Monitoring:
  /host/proc + /host/sys → Spring Boot (NasStatsService.java)
                        → /api/stats (JSON)
                        → Dashboard frontend
                        → PicoClaw Telegram bot
```

---

## Security Architecture — Layered Defense

```
Layer 1 (Outermost):  Tailscale ZTNA
  No open ports. All traffic through WireGuard VPN.
  Public access only via Tailscale Funnel (managed relay).

Layer 2:  UFW Firewall
  ALLOW: 22/tcp + 443/tcp (80/tcp optional) on tailscale0
  DENY:  80/443 on eth0 and wlan0
  OPTIONAL EXCEPTION: LAN subnet allowlist only if explicitly needed

Layer 3:  Nginx Rate Limiting
  10 requests/second per IP
  Burst: 20 requests

Layer 4:  Fail2Ban
  SSH: ban after 5 failed attempts, 3600s ban duration
  Nextcloud: ban after 5 failed logins

Layer 5:  TLS Encryption
  All public endpoints: HTTPS only (Tailscale auto-cert)

Layer 6 (Application):  Nextcloud MFA
  User accounts with password protection
  Share links: optional password + expiry date
```

---

## PicoClaw Architecture

```
Telegram Message
      │
      ▼
PicoClaw Gateway (Go binary, port 18790)
      │ parses intent
      ▼
Skill selection (7 skills loaded)
      │
      ├── NAS stats    → GET http://localhost:8085/api/stats
      ├── Docker       → docker ps (via shell skill)
      ├── Backup       → rclone sync (via shell skill)
      └── Security     → Fail2Ban / UFW queries
      │
      ▼
NVIDIA NIM API (meta/llama-3.1-8b-instruct)
via nvidia-proxy.py (local prefix proxy on :9099)
      │
      ▼
Formatted Telegram reply
```
