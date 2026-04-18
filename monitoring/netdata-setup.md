# Netdata Setup (Optional — Heavy)

Netdata provides rich real-time metrics but costs ~150MB RAM.
**Not recommended on 1GB Pi with full stack running.**

Use the custom Spring Boot API instead — it provides 40+ metrics
at ~142MB RAM. The comparison:

| Tool | RAM | Metrics | Custom dashboard |
|---|---|---|---|
| Spring Boot API (current) | ~142MB | 40+ | ✅ Custom HTML |
| Netdata | ~150MB | 2000+ | ❌ Netdata UI only |
| Prometheus + Grafana | ~400MB | Unlimited | ✅ Grafana |

For this RAM budget, the custom Spring Boot API wins.

## If You Still Want Netdata

Install the lightweight static binary:

```bash
wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
sh /tmp/netdata-kickstart.sh --dont-start-it --stable-channel
```

Limit its memory in `/etc/netdata/netdata.conf`:
```ini
[global]
    dbengine multihost disk space = 256
    dbengine disk space = 256
    memory mode = ram
    history = 300
```

Start:
```bash
sudo systemctl start netdata
sudo systemctl enable netdata
```

Access at: `http://localhost:19999`

## Alternative: Prometheus + Grafana

Requires ~400MB RAM. Not feasible on 1GB Pi with current stack
unless you remove Nextcloud or Jellyfin to free headroom.

If moving to Pi 4 (4GB or 8GB):
```yaml
# Add to docker-compose.yml
prometheus:
  image: prom/prometheus:latest
  mem_limit: 128m
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml

grafana:
  image: grafana/grafana:latest
  mem_limit: 128m
  ports:
    - "3000:3000"
```

The Spring Boot API exposes metrics at `/api/stats` — add a custom
Prometheus exporter to scrape this endpoint.
