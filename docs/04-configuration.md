# Configuration Reference

All environment variables, config files, and tunable parameters.

---

## docker-compose.yml — Key Variables

### Nextcloud

| Variable | Value | Description |
|---|---|---|
| `MYSQL_HOST` | `nextcloud-db` | Docker service name of MariaDB |
| `MYSQL_DATABASE` | `nextcloud` | Database name |
| `MYSQL_USER` | `ncuser` | DB user |
| `MYSQL_PASSWORD` | Change this | DB user password |
| `NEXTCLOUD_ADMIN_USER` | `admin` | Initial admin account |
| `NEXTCLOUD_ADMIN_PASSWORD` | Change this | Admin password |
| `NEXTCLOUD_TRUSTED_DOMAINS` | `raspberrypi-1.tail2767bf.ts.net` | Allowed domains |

### MariaDB

| Variable | Value | Description |
|---|---|---|
| `MYSQL_ROOT_PASSWORD` | Change this | Root DB password |
| `MYSQL_DATABASE` | `nextcloud` | Database to create |
| `MYSQL_USER` | `ncuser` | User to create |
| `MYSQL_PASSWORD` | Match Nextcloud | Password for ncuser |

### Spring Boot API (nas-api)

| Variable | Default | Description |
|---|---|---|
| `PROC_PATH` | `/host/proc` | Mount path for /proc |
| `SYS_PATH` | `/host/sys` | Mount path for /sys |
| `DATA_PATH` | `/mnt/data` | Data drive path |
| `JAVA_OPTS` | `-Xmx180m -Xms64m` | JVM memory limits |

### Jellyfin

| Variable | Value | Description |
|---|---|---|
| `PUID` | `33` | User ID (www-data) |
| `PGID` | `33` | Group ID |
| `TZ` | `Asia/Kolkata` | Timezone |

---

## Memory Limits

Tuned for 1GB RAM with full stack:

```yaml
nextcloud-app-1:  mem_limit: 400m   # Largest consumer
nextcloud-db-1:   mem_limit: 200m   # MariaDB with Nextcloud DB
jellyfin:         mem_limit: 256m   # Media transcoding
nas-api:          mem_limit: 180m   # Spring Boot JVM
```

**Total allocated:** 1,036MB
**Available for OS + other containers:** ~100-200MB (covered by 2GB swap)

To increase any limit, edit `mem_limit` and run:
```bash
docker compose up -d --force-recreate <service>
```

---

## Nginx Proxy Manager

**Custom Locations (set in NPM web UI):**

| Location | Scheme | Host | Port |
|---|---|---|---|
| `/hub` | http | 100.66.68.83 | 8081 |
| `/tv` | http | jellyfin | 8096 |
| `/api` | http | 100.66.68.83 | 8085 |
| `/` (root) | http | 100.66.68.83 | 8080 |

**Proxy host settings:**
- Domain: `raspberrypi-1.tail2767bf.ts.net`
- SSL: HTTP Only (Tailscale handles TLS termination)
- Block common exploits: ON
- Websockets support: ON

---

## Tailscale

**Admin console settings** (admin.tailscale.com):

DNS → Enable HTTPS certificates: ON

Access Controls:
```json
{
  "nodeAttrs": [
    {
      "target": ["autogroup:member"],
      "attr": ["funnel"]
    }
  ]
}
```

**Funnel ports:**
```bash
sudo tailscale funnel --bg 80          # Main HTTP → Nginx
sudo tailscale funnel --bg --https=8443 8096  # Jellyfin direct (optional)
```

---

## UFW Rules

```
22/tcp          ALLOW   (SSH)
80/tcp          ALLOW   (HTTP → Nginx)
443/tcp         ALLOW   (HTTPS → Nginx)
10.56.54.0/24   ALLOW   (Local subnet — full access)
tailscale0      ALLOW   (Tailscale interface)
```

Change local subnet to match your network (`ip route | grep /24`).

---

## Fail2Ban

Config at: `/etc/fail2ban/jail.local`

| Setting | Value | Description |
|---|---|---|
| `bantime` | `3600` | Ban duration (seconds) |
| `findtime` | `600` | Window for counting failures |
| `maxretry` | `5` | Failed attempts before ban |

To unban yourself:
```bash
sudo fail2ban-client set sshd unbanip <YOUR_IP>
```

---

## PicoClaw

Config at: `~/.picoclaw/config.json`

| Setting | Description |
|---|---|
| `agents.defaults.provider` | Set to `"openai"` (OpenAI-compatible API) |
| `agents.defaults.model_name` | Must match a `model_name` in providers array |
| `agents.defaults.restrict_to_workspace` | `true` — limits file access |
| `channels.telegram.token` | Bot token from BotFather |
| `channels.telegram.allow_from` | Array of numeric Telegram user IDs |
| `providers[].api_base` | `http://127.0.0.1:9099` when using nvidia-proxy |
| `providers[].api_key` | `"dummy"` when using local proxy (proxy holds real key) |

**NVIDIA proxy config** (`picoclaw/nvidia-proxy.py`):
```python
NVIDIA_API_KEY = "nvapi-YOUR_KEY_HERE"
NVIDIA_BASE_URL = "https://integrate.api.nvidia.com/v1"
```

---

## Rclone

Config at: `~/.config/rclone/rclone.conf`

Created automatically by `rclone config`. Contains Google OAuth tokens.
**Never commit this file to git.**

Backup destination: `gdrive:nas-backup`
Cron schedule: `0 3 * * *` (3:00 AM daily)

---

## Spring Boot application.properties

Location: `spring-boot-api/src/main/resources/application.properties`

```properties
server.port=8085
spring.application.name=opennas-dashboard

# Proc/sys paths (overridden by Docker env vars)
nas.proc.path=/host/proc
nas.sys.path=/host/sys
nas.data.path=/mnt/data

# Cache refresh intervals
nas.vcgencmd.cache.seconds=15
nas.docker.cache.seconds=30

# CORS (allow dashboard to call API)
spring.web.cors.allowed-origins=*
```

---

## Cron Jobs

Check with: `sudo crontab -l`

```
0 3 * * *    /home/ishank/backup/backup.sh
@reboot      sleep 30 && tailscale funnel --bg 80
```

Add crontab entry: `sudo crontab -e`
