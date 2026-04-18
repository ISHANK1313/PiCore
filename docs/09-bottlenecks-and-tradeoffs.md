# Bottlenecks & Engineering Tradeoffs

This document is honest about what PiCore cannot do and why every limitation
exists. Most constraints are deliberate hardware budget decisions, not design
failures.

---

## 1. RAM Ceiling (1GB Hard Limit)

**Measured ceiling:** ~850MB usable for Docker containers after OS overhead
(the system shows 905 MiB total available, with OS consuming ~55MB baseline).

**What this killed:**
- Immich (photo AI) — ML container requires ~900MB alone
- ClamAV antivirus — 800MB idle footprint
- Grafana + Prometheus stack — ~400MB combined
- Netdata full agent — ~150MB

**What survived (with mem_limit enforcement):**

| Container | mem_limit | Actual peak usage |
|---|---|---|
| Nextcloud | 400MB | ~387MB |
| MariaDB | 200MB | ~156MB |
| Jellyfin | 256MB | ~198MB |
| Spring Boot API | 180MB | ~142MB |
| PicoClaw | <10MB | <10MB |
| nginx-pm | — | ~94MB |
| uptime-kuma | — | ~80MB |
| portainer | — | ~80MB |

Total at peak: ~1,147MB → overflows into swap (measured peak: ~950MB RAM
+ ~1.9GB swap under starvation test).

**Tradeoff accepted:** No ML workloads. No heavy monitoring agents. Every
service had to prove it could run within a per-container memory budget.

---

## 2. Flash Drive I/O — Write Buffer Exhaustion

**Measured behavior:**

| Phase | Sequential Write Speed |
|---|---|
| First 60 seconds (SLC cache) | ~80-120 MB/s (estimated, cache active) |
| After cache exhaustion | **24.6 MB/s** (measured by fio) |
| Random 4K write | **2.63 MB/s / 657 IOPS** |

The SanDisk USB flash drive uses an SLC write cache of approximately 2-4GB.
Large file uploads to Nextcloud that exceed this cache will experience a
visible speed cliff.

**Impact on users:** Uploading a 10GB video works fine initially, then slows
to ~25 MB/s. For personal use this is acceptable. For production multi-user
NAS, it is a hard constraint.

**Why flash, not HDD:**
- Silent operation (no moving parts, no vibration)
- Lower power draw (~0.5W vs ~5W for a 2.5" HDD)
- No spindle noise
- Fits the "invisible server on a desk" deployment model

---

## 3. USB 3.0 vs SATA — Interface Bottleneck

Even with a fast NVMe SSD, the Pi 4's USB 3.0 interface is shared bandwidth.
The theoretical max is 625 MB/s — but in practice, shared with network
traffic and OS I/O, real-world throughput is ~80-100 MB/s peak.

For this setup: flash drive is the bottleneck, not the USB interface.

---

## 4. WiFi vs Ethernet — Network Ceiling

**Measured:** 18.7 Mbps (local), 20.5 Mbps (Tailscale).

The Pi 4's 802.11ac WiFi has a theoretical maximum of ~300 Mbps, but
real-world throughput on a congested home network is far lower. Wired
Gigabit Ethernet would provide ~940 Mbps — a 50x improvement for file
transfers.

**Why WiFi:** No Ethernet port available at deployment location.
**Impact:** Large file downloads from Nextcloud are limited to ~18-20 Mbps
(~2.3 MB/s), meaning a 1GB file takes ~7 minutes. Jellyfin streaming is
unaffected (1080p requires only ~20-40 Mbps).

---

## 5. API Latency Under Concurrent Load

**Measured:** 1.70 req/s under 20 concurrent connections, 49/51 timeouts.

**Root cause:** `/api/stats` performs a mandatory 250ms sleep for CPU
usage calculation (two-sample `/proc/stat` delta). Under 20 concurrent
connections, 250ms × 20 queued requests = 5 second wait for last request
→ timeout.

**For actual use case (single dashboard polling every 5s):** Completely
unaffected. 1.70 req/s is measured under synthetic concurrent load that
will never occur in normal operation.

**Mitigations available (not yet implemented):**
- Background thread refreshes metrics every 5s, endpoint returns cached value
- Rate limiting at Nginx (implemented — 10 req/s) prevents this scenario

---

## 6. Single Node — No High Availability

**PiCore has no:**
- RAID array (single flash drive, no redundancy)
- Failover node
- Load balancer
- Multi-zone deployment

**What this means:** If the Pi dies, the service is down until replaced.
If the data drive fails, data since the last backup is lost.

**Mitigations implemented:**
- Nightly Google Drive backup (RPO: 24 hours)
- Docker `restart: unless-stopped` (auto-recovery from crashes)
- Measured RTO: < 10s for software failures
- Power bank prevents power-loss filesystem corruption

**Mitigation not implemented:** Hardware RAID / second Pi node. Would
require ~₹8,000 additional hardware investment.

---

## 7. ARM64 Compatibility

Some Docker images have no ARM64 build or have ARM64 builds that lag
behind x86 releases. Encountered during setup:

- Portainer: ARM64 supported ✅
- Nextcloud: ARM64 supported ✅
- Jellyfin: ARM64 supported ✅
- Some monitoring agents: required manual build or skip

---

## 8. Tailscale Latency Overhead

**Measured:** Local LAN 18.7 Mbps vs Tailscale 20.5 Mbps — VPN was
actually faster in this test due to routing.

However, Tailscale Funnel adds relay hop latency. Direct port forwarding
would have lower latency but exposes ports publicly. The ZTNA security
model was judged worth the negligible latency cost.

---

## 9. PicoClaw Rate Limits (NVIDIA NIM Free Tier)

**Constraint:** NVIDIA NIM free tier allows approximately 10-40 RPM
depending on model. Under heavy Telegram bot usage, 429 (Too Many Requests)
errors occur.

**Mitigation:** Local nginx-proxy.py handles prefix correction. The 429
error is transient — PicoClaw retries with backoff.

**For production use:** Upgrade to NVIDIA NIM paid tier or switch to a
higher-RPM free provider (Groq allows 30 RPM on llama-3.3-70b-versatile).

---

## Summary: What Was Sacrificed vs. Gained

| Sacrificed | Gained |
|---|---|
| High write performance (flash vs SATA) | Silent, low-power, no moving parts |
| High availability (single node) | Zero monthly cost |
| ML workloads (1GB RAM limit) | Stable always-on core stack |
| Concurrent API users (>5) | Custom hardware metrics others don't have |
| Enterprise SLA (99.99%+) | Full data sovereignty |
| Managed updates | Complete architectural control |

Every tradeoff was a deliberate choice within a ₹5,000 hardware budget.
The documentation of these tradeoffs — not the hiding of them — is what
makes this project credible.
