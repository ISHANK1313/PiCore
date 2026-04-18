# Changelog — PiCore

All notable changes to this project are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [v1.4.0] — 2026-04-18 — AI Agent Layer

### Added
- PicoClaw AI agent integration (Go binary, <10MB RAM footprint)
- NVIDIA NIM backend via local proxy (`nvidia-proxy.py`)
- Telegram bot gateway (`./picoclaw gateway`)
- 16 tools loaded, 7 skills available at startup
- NAS health report on demand via Telegram
- Live container resource table in bot responses
- AGENT.md and SOUL.md personality configuration

### Changed
- Dashboard updated with NTP status and system time fields
- Spring Boot API extended with container name list endpoint

---

## [v1.3.0] — 2026-03-27 — Resilience Validation

### Added
- Chaos Engineering test suite (4 failure scenarios)
- Baseline snapshot tooling (`chaos_results/baseline.txt`)
- Quantified RTO for all 4 scenarios (documented in results/)
- Three-terminal monitoring methodology documented
- fio disk benchmarking suite (sequential + random)
- iperf3 network benchmarking (local + Tailscale VPN)
- wrk API concurrency stress testing
- Power draw and TCO analysis

### Results Highlights
- Test 1 (Container crash): 4s downtime, auto-recovery confirmed
- Test 2 (VPN failure): 3s recovery after `tailscale up`
- Test 3 (Resource starvation): Graceful degradation, no kernel panic
- Test 4 (Storage failure): No DB corruption, 12s recovery

---

## [v1.2.0] — 2026-03-26 — Monitoring & Observability

### Added
- Spring Boot REST API (custom, original code)
  - 40+ live hardware metrics from `/proc` and `/sys`
  - Endpoints: `/api/stats`, `/api/health`
  - vcgencmd integration (throttle, voltage, GPU temp)
  - Docker container list via socket
- Custom frontend dashboard (`opennas-frontend` container)
  - Live telemetry (CPU temp, RAM, disk, network)
  - Extended metrics (context switches, dirty pages, swap)
  - System information panel (hardware/software/network)
  - Terminal-style system log with auto-scroll
- Uptime Kuma service health monitoring
- Rate limiting (Nginx + UFW)

### Changed
- docker-compose.yml consolidated all services into one stack
- mem_limit added to all containers (prevents OOM kernel panic)

---

## [v1.1.0] — 2026-03-25 — Public Access & Reverse Proxy

### Added
- Nginx Proxy Manager reverse proxy routing
- Tailscale Funnel public HTTPS access (no port forwarding)
- Path-based routing: `/tv` → Jellyfin, `/cloud` → Nextcloud, `/hub` → Dashboard
- Jellyfin base URL configuration (`/tv`)
- Nextcloud trusted domain configuration
- UFW firewall (ports 22, 80, 443 + local subnet)
- Fail2Ban intrusion prevention
- SSL/TLS via Tailscale automatic certificates

### Fixed
- WebSocket support for Uptime Kuma via Nginx custom headers
- Nextcloud 400 error with reverse proxy (Host header fix)

---

## [v1.0.0] — 2026-03-21 — Initial Stack

### Added
- Raspberry Pi 4 (1GB) base setup
  - Raspbian OS Lite 64-bit (headless)
  - USB boot from 28GB flash drive
  - 128GB USB 3.0 data drive (`/mnt/data`, ext4)
  - 2GB swapfile (`/swapfile`)
- Docker + Docker Compose
- Portainer CE (container management UI)
- Nextcloud + MariaDB 10.6 (private cloud storage)
- Jellyfin (media server)
- Automated Google Drive backup via Rclone (3AM cron)
- Tailscale VPN (private admin access)

---

## Planned — v1.5.0

- MQTT broker (Mosquitto) + IoT sensor pipeline
- NFC hardware authentication (ESP32 + PN532)
- PicoClaw NFC dead man's switch for destructive commands
- WiFi anomaly detection (ESP32 promiscuous mode)
- Rate limiting per endpoint in Spring Boot (Bucket4j)
- Gitea self-hosted Git server
