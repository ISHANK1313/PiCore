# Monitoring

Service health monitoring for PiCore.

## Active Monitoring Tools

**Uptime Kuma** (primary):
- URL: `http://10.56.54.100:3001`
- Monitors: raspberry, nextcloud, nginx, jellyfin, portainer
- Check interval: 60 seconds
- All monitors show 100% uptime

**Spring Boot /api/stats** (hardware telemetry):
- URL: `http://localhost:8085/api/stats`
- Provides 40+ live metrics from /proc and /sys
- Polled by frontend dashboard every 5 seconds
- Also queried by PicoClaw for Telegram health reports

## Uptime Kuma Import

```bash
# In Uptime Kuma → Settings → Backup → Import
# Upload: monitoring/uptime-kuma-monitors.json
```

Or add monitors manually — see `uptime-kuma-monitors.json` for URLs and intervals.

## What Was Observed

From Uptime Kuma screenshots (April 18, 2026):
- Jellyfin: 100% uptime
- Nextcloud: 100% uptime (one 48000ms timeout logged — transient memory pressure)
- Nginx: 100% uptime
- Portainer: 100% uptime
- Raspberry Pi API: 100% uptime

## Not Recommended on 1GB Pi

- Netdata (~150MB RAM) — see `netdata-setup.md` for details
- Prometheus + Grafana (~400MB RAM) — not feasible with full stack
