# PiCore Frontend Dashboard

Custom HTML/CSS/JS dashboard served by nginx:alpine.
No frameworks, no build step, no npm.

## What It Shows

**Core telemetry (live, every 5s):**
- CPU temperature + usage
- RAM usage bar
- Disk usage bars (OS + data drive)
- Uptime + container count

**Extended metrics:**
- CPU frequency, cores, I/O wait
- Context switches, interrupts
- Dirty pages, shared memory, buffers/cached
- Swap usage %

**Load averages:** 1m, 5m, 15m

**Storage:** OS drive + data drive progress bars

**Disk I/O & Network:**
- Total read/write bytes (human readable)
- RX/TX speed (KB/s current)
- Packet counts, error counts

**System information panel:**
- Hardware: Device, RAM, OS drive, storage, power
- Software: OS, kernel, kernel version, arch, runtime, API
- Network & Status: Tailscale Funnel, VPN, proxy, firewall, protocol, voltage, throttle

**Running containers:** Tag list from /api/stats

**Terminal log:** Auto-scrolling system event log

## Deployment

```bash
# Copy index.html to Docker volume
sudo nano /var/lib/docker/volumes/opennas-frontend_opennas_html/data/index.html
# Paste contents, save

# Or via scp:
scp frontend/index.html ishank@raspberrypi.local:/tmp/
ssh ishank@raspberrypi.local "sudo cp /tmp/index.html /var/lib/docker/volumes/opennas-frontend_opennas_html/data/"
```

## Configuration

One line to change in `index.html`:
```javascript
const API_BASE = 'https://raspberrypi-1.tail2767bf.ts.net/api';
```

Change to your Tailscale domain. All API calls go through this URL.

## Design

- Theme: Light blue-white (`#f0f5ff` background, white cards)
- Polls: Every 5 seconds via `fetch()`
- Null-safe: All `.toFixed()` calls wrapped via `const fix = (v, n=1) => ...`
- No external dependencies (no CDN, no fonts, no frameworks)
