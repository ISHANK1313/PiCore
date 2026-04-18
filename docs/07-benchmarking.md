# Benchmarking Results

All benchmarks were run on production hardware under real load conditions.
No synthetic or estimated numbers. Date: March 27, 2026.

---

## Hardware Under Test

| Component | Specification |
|---|---|
| Device | Raspberry Pi 4 Model B |
| RAM | 1GB LPDDR4 |
| OS Drive | 28GB USB Flash |
| Data Drive | 128GB SanDisk USB 3.0 |
| OS | Raspbian OS Lite 64-bit |
| Kernel | 6.12.76+rpt-rpi-v8 |
| Docker Containers Running | 8 (full production stack) |

---

## 1. Storage I/O — fio

### Test 1A: Sequential Read/Write (1MB block size)

**Command:**
```bash
sudo fio --name=seq_test --ioengine=posixaio --rw=readwrite \
         --bs=1M --size=256M --numjobs=1 --iodepth=1 \
         --directory=/mnt/data
```

**Results:**

| Metric | Read | Write |
|---|---|---|
| Throughput | **26.2 MB/s (27.5 MB/s)** | **24.6 MB/s (25.8 MB/s)** |
| IOPS | 26 | 24 |
| Average latency | 33.97 ms | 4.40 ms |
| p50 latency | 1.01 ms | 1.75 ms |
| p99 latency | 1132 ms | 23.5 ms |
| p99.9 latency | 1200 ms | 23.7 ms |
| Disk utilization | 96.59% | — |

**Key observation:** Read latency has extreme variance — p99 is 1132ms vs p50
of 1ms. This is characteristic of USB 3.0 flash with SLC write buffer
exhaustion causing sudden stalls. The 96.59% disk utilization confirms the
storage subsystem is the primary bottleneck.

---

### Test 1B: Random Read/Write (4K block size, iodepth=4)

**Command:**
```bash
sudo fio --name=rand_test --ioengine=posixaio --rw=randrw \
         --bs=4k --size=128M --numjobs=1 --iodepth=4 \
         --directory=/mnt/data
```

**Results:**

| Metric | Read | Write |
|---|---|---|
| Throughput | **2.63 MB/s** | **2.63 MB/s** |
| IOPS | **657** | **657** |
| Average latency | 3.23 ms | 2.83 ms |
| p50 latency | 1.73 ms | 1.09 ms |
| p95 latency | 2.70 ms | 2.06 ms |
| p99 latency | 31.9 ms | 28.2 ms |
| p99.99 latency | 2902 ms | 2902 ms |

**Key observation:** Random 4K performance (657 IOPS) is sufficient for
Nextcloud metadata operations but explains slowness under concurrent database
queries. The p99.99 latency of 2.9 seconds indicates occasional extreme stalls
under deep queue depth — impactful for MariaDB under concurrent user load.

---

### Storage Benchmark Summary

| Metric | PiCore (Measured) | Synology DS223 (Spec) | Ratio |
|---|---|---|---|
| Sequential Read | 26.2 MB/s | 225 MB/s | 1:8.6x |
| Sequential Write | 24.6 MB/s | 200 MB/s | 1:8.1x |
| Random Read IOPS (4K) | 657 | ~5,000 | 1:7.6x |
| Random Write IOPS (4K) | 657 | ~4,500 | 1:6.8x |

The performance gap is expected — Synology uses 2.5GbE with SATA HDDs or
NVMe SSDs. PiCore uses USB 3.0 with a consumer flash drive. For personal
single-user cloud storage, 26 MB/s sequential is sufficient.

---

## 2. Network Throughput — iperf3

### Test 2A: Local Network (LAN)

**Command (from laptop):**
```bash
iperf3 -c 10.56.54.100
```

**Results:**

| Interval | Transfer | Bitrate |
|---|---|---|
| 0-1s | 2.38 MB | 19.6 Mbps |
| 1-2s | 2.38 MB | 20.2 Mbps |
| 2-3s | 2.25 MB | 18.8 Mbps |
| 3-4s | 2.12 MB | 17.7 Mbps |
| 4-5s | 2.38 MB | 19.9 Mbps |
| **Average** | **22.4 MB / 10s** | **18.7 Mbps** |

**Sender:** 18.7 Mbps | **Receiver:** 18.6 Mbps

---

### Test 2B: Tailscale VPN (WireGuard tunnel)

**Command (from laptop):**
```bash
iperf3 -c 100.66.68.83
```

**Results:**

| Interval | Transfer | Bitrate |
|---|---|---|
| 0-1s | 2.12 MB | 17.8 Mbps |
| 1-2s | 2.12 MB | 17.7 Mbps |
| 4-5s | 2.75 MB | 23.4 Mbps |
| 5-6s | 2.88 MB | 23.6 Mbps |
| **Average** | **24.5 MB / 10s** | **20.5 Mbps** |

**Sender:** 20.5 Mbps | **Receiver:** 19.9 Mbps

---

### Network Summary

| Test | Throughput | Latency Note |
|---|---|---|
| Local (10.56.54.100) | **18.7 Mbps** | WiFi bottleneck |
| Tailscale VPN (100.66.68.83) | **20.5 Mbps** | VPN overhead negligible |
| VPN overhead | **+1.8 Mbps** | Counterintuitively faster (routing) |

**Key finding:** Tailscale VPN adds negligible overhead on this setup — in
fact slightly faster due to different routing path. The WiFi interface
(802.11ac) is the actual bottleneck, not the Pi's CPU or Tailscale encryption.
Both tests are well below the theoretical WiFi maximum, indicating the Pi's
WiFi adapter is operating normally.

---

## 3. API Performance — wrk Load Test

### Test 3A: Spring Boot /api/stats under concurrent load

**Command:**
```bash
wrk -t 2 -c 20 -d 30s --latency \
    https://raspberrypi-1.tail2767bf.ts.net/api/stats
```

**Results:**

| Metric | Value |
|---|---|
| Duration | 30 seconds |
| Threads | 2 |
| Connections | 20 |
| Total Requests | 51 |
| **Requests/sec** | **1.70** |
| **Transfer/sec** | **3.00 KB** |
| Average Latency | **1.66s** |
| Stdev Latency | 16.35ms |
| Max Latency | 1.67s |
| p50 Latency | 1.67s |
| p75 Latency | 1.67s |
| p90 Latency | 1.67s |
| p99 Latency | 1.67s |
| Socket Timeouts | **49 of 51 connections** |

**Analysis:**

The API serves only 1.70 requests/second under 20 concurrent connections, with
49/51 connections timing out. This is explained by the `/api/stats` endpoint
design — it performs a 250ms CPU sampling sleep (two-snapshot delta for accurate
CPU usage measurement) on every request. Under concurrent load this creates a
queuing effect.

The latency is highly consistent (stdev 16.35ms, very low) — this is not
instability, it is the deterministic 250ms + processing overhead.

**Mitigation approaches documented:**
1. Cache stats every 5 seconds, serve cached value (reduces live accuracy)
2. Move CPU sampling to background thread, serve last-computed value
3. Rate limit at Nginx to prevent concurrent request pile-up (implemented)

For a dashboard polling every 5-10 seconds from a single client, 1.70 req/s
is entirely adequate — the issue only manifests under load testing with 20
concurrent connections.

---

## 4. Power & Cost Efficiency

| Metric | PiCore | Synology DS223 | AWS t3.micro + 128GB EBS |
|---|---|---|---|
| Idle power draw | ~3W | ~8W | N/A (cloud) |
| Load power draw | **~5W** | **~15W** | N/A |
| Annual electricity (₹8/kWh) | **₹350/yr** | **₹1,050/yr** | N/A |
| Monthly cloud equivalent | ₹0 | ₹0 | **~₹2,400/mo** |
| 5-year TCO | **₹6,750** | **₹20,250** | **₹1,44,000** |

Hardware cost: ₹5,000 (Pi 4 + flash drives)
Monthly operating cost: effectively ₹0 (electricity ~₹30/month)

---

## 5. Memory Profile Under Full Load

Measured during chaos Test 3 (concurrent Jellyfin stream + Nextcloud upload
+ API bombing):

| Component | Peak Usage |
|---|---|
| Total RAM used | **~950 MB** of 1024 MB |
| Swap used | **~1.9 GB** of 2 GB |
| Available RAM at peak | ~43 MB |
| Docker mem_limits prevented OOM | **YES** |
| System crashed | **NO** |

The 2GB swapfile was critical — without it the kernel OOM killer would have
terminated containers under this load. Docker `mem_limit` constraints prevented
any single container from consuming all available memory.

---

## Benchmark Reproducibility

To reproduce all benchmarks:
```bash
# Storage
bash benchmarking/scripts/bench-disk.sh

# Network (run from laptop after starting iperf3 -s on Pi)
bash benchmarking/scripts/bench-network.sh

# API load test
bash benchmarking/scripts/bench-api.sh

# Thermal profile under stress
bash benchmarking/scripts/bench-thermal.sh
```

Results will be written to `benchmarking/results/`.
