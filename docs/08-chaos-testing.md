# Chaos Testing & Resilience Validation

Chaos engineering validates how a system behaves under controlled failure
conditions. All four tests below were run on the live production stack on
March 27, 2026. Results are measured, not estimated.

---

## Pre-Test Methodology

### Three-Terminal Setup

Every test was executed with three simultaneous SSH sessions:

**Terminal 1** — Test execution (kill commands, mount/unmount)

**Terminal 2** — Continuous hardware monitoring:
```bash
watch -n 2 "echo '=== MEMORY ===' && free -h && \
            echo '=== DOCKER ===' && docker ps --format '{{.Names}} {{.Status}}' && \
            echo '=== CPU TEMP ===' && vcgencmd measure_temp"
```

**Terminal 3** — Continuous service health probe:
```bash
watch -n 1 "curl -s -o /dev/null -w 'API Status: %{http_code} (%{time_total}s)' \
            https://raspberrypi-1.tail2767bf.ts.net/api/stats"
```

### Baseline Snapshot (taken before any test)

```
Date: Fri Mar 27 IST 2026
CPU temp: 52.0°C
Memory: 905 MiB total / 696 MiB used / 43 MiB free
Swap: 2.9 GiB total / 798 MiB used
Docker containers: 8 running
API response: 200 in ~1.6s
```

---

## Test 1: Hard Application Crash

**Scenario:** Force-kill the Spring Boot API container.

**Execution:**
```bash
docker exec nas-api kill -9 1
```

**Measured Results:**

| Metric | Value |
|---|---|
| Observed downtime | **~4 seconds** |
| Recovery status | **SUCCESS** |
| Docker auto-restart | **YES** (restart: unless-stopped policy) |
| Data corruption | **NONE** |
| Manual intervention required | **NO** |

**What happened:** Terminal 3 showed HTTP 200 → 000 (instant drop) →
000 × 3 probes → 200 (recovery). Docker's `restart: unless-stopped` policy
triggered container restart automatically. The 4-second gap is Docker's restart
delay plus JVM startup time (~3s for Spring Boot with -Xmx180m).

**Engineering significance:** This proves the restart policy works as configured.
A monitoring system (Uptime Kuma) would log a 4-second outage window.
For a dashboard API polled every 5 seconds, one poll may return an error.

---

## Test 2: Network/VPN Failure

**Scenario:** Take down the Tailscale tunnel (simulates ISP outage or
Tailscale service disruption).

**Execution:**
```bash
sudo tailscale down
# [verify public URL inaccessible from phone on mobile data]
sudo tailscale up
```

**Measured Results:**

| Metric | Value |
|---|---|
| Public access during outage | **Completely dropped (correct)** |
| Time to recovery after `tailscale up` | **~3 seconds** |
| Nginx Proxy Manager required manual reboot | **NO (auto-recovered)** |
| Local LAN access maintained | **YES** |
| Data integrity | **UNAFFECTED** |

**What happened:** Tailscale down → all public endpoints became unreachable
immediately (correct ZTNA behavior — no fallback route). `tailscale up` → VPN
reconnected → Nginx resumed routing in ~3 seconds without intervention.

**Engineering significance:** Demonstrates ZTNA correctness — the system has
no fallback public exposure when the VPN is down. Also proves zero dependency
on Nginx restart after tunnel recovery.

---

## Test 3: Resource Starvation (RAM & I/O)

**Scenario:** Simultaneous Jellyfin video stream + Nextcloud upload +
API bombing (100 requests over 20 seconds).

**Execution:**
```bash
# Terminal A: Start Jellyfin stream in browser
# Terminal B: Start large file upload in Nextcloud
# Terminal C: API bomb
for i in {1..100}; do
  curl -s -o /dev/null -w "API Request $i: %{http_code} in %{time_total}s "
       https://raspberrypi-1.tail2767bf.ts.net/api/stats
  sleep 0.2
done
```

**Measured Results:**

| Metric | Value |
|---|---|
| Peak RAM used | **~950 MB** of 905 MiB available |
| Peak swap used | **~1.9 GB** of 2.9 GiB |
| Max API latency under load | **~2.8 seconds** |
| Did the system fatally crash | **NO — Graceful degradation** |
| Did Docker mem_limits prevent OOM kernel panic | **YES** |
| SSH remained responsive | **YES** |
| Any container exited | **NO** |

**What happened:** RAM hit ~950MB (above physical limit, spilling into swap).
API latency climbed to 2.8s (vs baseline ~1.6s) — degraded but functional.
Docker memory limits prevented any single container from consuming all
remaining memory. The swapfile absorbed the overflow. System remained
administrable via SSH throughout.

**Engineering significance:** The `mem_limit` declarations in docker-compose.yml
are the critical component here. Without them, one container would grow
unbounded and trigger kernel OOM killer — a hard crash. This test validates
the resource isolation design.

---

## Test 4: Hardware Storage Failure

**Scenario:** Unmount the data drive while Nextcloud is actively serving files.

**Execution:**
```bash
# Start a file upload in Nextcloud browser
# Then immediately:
sudo umount -l /mnt/data

# Observe Nextcloud behavior, then recover:
sudo mount -a
docker restart nextcloud-app-1
```

**Measured Results:**

| Metric | Value |
|---|---|
| Nextcloud safely locked down when drive vanished | **YES** |
| Database corrupted | **NO** |
| Recovery time after remount | **~12 seconds** |
| Data loss | **NONE** |
| Error handling behavior | **Graceful — showed error, did not crash loop** |

**What happened:** Nextcloud detected the missing filesystem and entered a
read-error state (correct behavior — it did not silently write to a null
target). MariaDB database survived because it stores in a Docker volume
separate from `/mnt/data`. After `mount -a` + `docker restart nextcloud-app-1`,
full service resumed in ~12 seconds.

**Engineering significance:** The most dangerous test. The fact that the
database was not corrupted validates the Docker volume separation design.
If MariaDB data had been stored directly on `/mnt/data`, unmounting would
have caused corruption. The architecture isolates DB from media/files.

---

## RTO Summary Table

| Test | Failure Type | Downtime | Recovery Time | Manual Intervention | Grade |
|---|---|---|---|---|---|
| 1 | Container crash | ~4s | ~4s | **NO** | ✅ PASS |
| 2 | VPN/network failure | Duration of outage | ~3s after restore | **NO** | ✅ PASS |
| 3 | Resource starvation | 0 (degraded) | Immediate on load reduction | **NO** | ✅ PASS |
| 4 | Storage drive failure | ~30s | ~12s after remount | YES (mount -a) | ✅ PASS |

---

## What These Results Mean

**RTO (Recovery Time Objective):**
- Container-level failures: **< 10 seconds** automatically
- Network-level failures: **< 5 seconds** after restoration
- Storage failures: **< 15 seconds** with one manual command

**RPO (Recovery Point Objective):**
- Database: **0** (MariaDB in isolated Docker volume, unaffected by storage failure)
- User files: **Up to 24 hours** (rclone backup runs at 3AM)

---

## Running the Tests

```bash
# Establish baseline first
bash chaos-testing/scripts/establish-baseline.sh

# Then run each test in order
bash chaos-testing/scripts/test1-container-crash.sh
bash chaos-testing/scripts/test2-network-failure.sh
bash chaos-testing/scripts/test3-resource-starvation.sh
bash chaos-testing/scripts/test4-storage-failure.sh
```

**Warning:** Test 4 will make Nextcloud temporarily unavailable. Always run
on your own isolated setup, never on shared infrastructure.
