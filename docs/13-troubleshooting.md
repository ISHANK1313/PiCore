# Troubleshooting

Common issues encountered during setup and their solutions.

---

## SSH Issues

### Stored fingerprint mismatch
```
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED
```
**Fix:**
```bash
ssh-keygen -R <pi-ip-address>
ssh pi@<pi-ip-address>
```

### SSH connection timeout
Check Pi is powered on and connected to WiFi. If using USB boot, verify
the OS flash drive is firmly inserted.

---

## Docker Issues

### Container keeps restarting

```bash
# Check logs for the failing container
docker logs <container-name> --tail 50

# Check memory usage — most common cause on 1GB Pi
free -h
docker stats --no-stream
```

Most common cause: container hitting its `mem_limit`. Solution: temporarily
increase limit in docker-compose.yml or reduce other containers' limits.

### "no space left on device"

```bash
df -h
# If root (/) is full:
docker system prune -a    # removes unused images/containers
# If /mnt/data is full:
du -sh /mnt/data/*        # find what's consuming space
```

### Portainer not accessible (port 81 blocked)

```bash
sudo ufw allow 9000/tcp
sudo ufw allow 81/tcp
```

---

## Nextcloud Issues

### 400 Bad Request after setting up reverse proxy

The Host header is missing. In NPM custom location config, add:
```nginx
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

### Nextcloud not accessible from public URL

```bash
sudo docker exec --user www-data nextcloud-app-1 php occ \
  config:system:set trusted_domains 1 \
  --value="raspberrypi-1.tail2767bf.ts.net"

sudo docker restart nextcloud-app-1
```

### "timeout of 48000ms exceeded" in Uptime Kuma

Nextcloud is taking too long to respond. Check:
```bash
docker stats nextcloud-app-1 --no-stream
# If near 400MB limit, it's memory pressure
```

Also visible in Uptime Kuma (as seen in screenshots): `timeout of 48000ms exceeded`
This is a transient Nextcloud slowness under memory pressure. Not data loss.

---

## Jellyfin Issues

### Black screen after login through reverse proxy

Jellyfin doesn't know its base URL. Fix:
1. Log into Jellyfin directly: `http://<pi-local-ip>:8096`
2. Admin → Dashboard → Networking → Base URL: `/tv`
3. Save and restart container:
```bash
docker restart jellyfin
```

### Known hosts error (network.xml)

```bash
docker exec jellyfin sed -i \
  's|<KnownProxies></KnownProxies>|<KnownProxies>10.56.54.100</KnownProxies>|' \
  /config/config/network.xml
docker restart jellyfin
```

---

## Tailscale Issues

### Funnel not working after reboot

Funnel needs to be re-enabled after reboot:
```bash
sudo tailscale funnel --bg 80
sudo tailscale funnel --bg --https=8443 8096
```

Add to `/etc/rc.local` or create a systemd service to auto-enable on boot.

### "Funnel" nodeAttr not working

In Tailscale admin console → Access Controls, ensure:
```json
"nodeAttrs": [
  {
    "target": ["autogroup:member"],
    "attr": ["funnel"]
  }
]
```

---

## Spring Boot API Issues

### API returns 000 (connection refused)

```bash
docker logs nas-api --tail 20
docker restart nas-api
```

If it keeps failing, check memory:
```bash
docker stats nas-api --no-stream
# If near 180MB limit, increase mem_limit in compose
```

### API always returns 1.66s latency

This is by design — the CPU usage calculation requires a 250ms sleep for
a two-sample measurement. It is not a bug.

---

## Pi Crashing / Freezing

### Green LED flashing rapidly

Intense disk I/O — normal under heavy load. Not a problem.

### Red LED goes off, then system reboots

Undervoltage from power supply. The Pi throttles and may reboot.
- Use a proper 5V/3A power supply or power bank
- Check: `vcgencmd get_throttled` — `0x50005` indicates past undervoltage

### OOM killer killing containers

Docker `mem_limit` should prevent this. If it happens:
```bash
dmesg | grep -i "killed process"    # see what was killed
free -h                              # check current state
cat /proc/swaps                      # verify swapfile active
```

If swapfile is not active:
```bash
sudo swapon /swapfile
```

---

## PicoClaw Issues

### 404 from LLM

The model name has a prefix issue. Verify the local proxy is running:
```bash
ps aux | grep proxy
# If not running:
python3 ~/picoclaw/nvidia-proxy.py &
```

### Bot not responding in Telegram

1. Check gateway is running: `ps aux | grep picoclaw`
2. Check bot token: `curl https://api.telegram.org/bot<TOKEN>/getMe`
3. Check allow_from is set correctly in config.json
4. Clear sessions: `rm -rf ~/.picoclaw/sessions/`

### Rate limit errors (429)

NVIDIA NIM free tier limit hit. Wait 60 seconds, try again.
For permanent fix, switch to a higher-RPM provider in config.json.

---

## Backup Issues

### Rclone cannot authenticate

```bash
rclone config reconnect gdrive:
```

Follow the OAuth flow again. The access token may have expired.

### Backup script fails silently

```bash
bash ~/backup/backup.sh  # run manually to see errors
```

Check Google Drive storage quota is not full.
