# Chaos Testing — RTO Summary Table

**System:** PiCore — Raspberry Pi 4 (1GB RAM)
**Date:** March 27, 2026
**Stack:** 8 Docker containers (full production load)

## Recovery Time Objectives (Measured)

| Test | Failure Injected | Downtime | Recovery Time | Auto-Recovery | Data Safe | Result |
|---|---|---|---|---|---|---|
| 1 | `docker exec nas-api kill -9 1` | **~4s** | **~4s** | **YES** | ✅ YES | **PASS** |
| 2 | `sudo tailscale down` | Duration of outage | **~3s** after restore | **YES** | ✅ YES | **PASS** |
| 3 | Concurrent stream + upload + 100 API requests | **0** (degraded) | Immediate on load reduction | **YES** | ✅ YES | **PASS** |
| 4 | `sudo umount -l /mnt/data` | **~30s** | **~12s** after remount | **NO** (1 cmd) | ✅ YES | **PASS** |

## Key Findings

**All 4 tests passed.** No data corruption in any scenario.

**RTO by failure type:**
- Software crash: < 10 seconds (automated)
- Network failure: < 5 seconds after restoration (automated)
- Resource exhaustion: 0 downtime, graceful degradation
- Hardware storage: < 15 seconds with one manual command

**RPO (Recovery Point Objective):**
- Database: 0 (isolated Docker volume, unaffected by storage failure)
- User files: Up to 24 hours (daily backup at 3AM)

## What Prevented Disasters

| Risk | Mitigation | Validated |
|---|---|---|
| Container crash causing permanent outage | `restart: unless-stopped` | ✅ Test 1 |
| OOM kernel panic under load | Docker `mem_limit` on all containers | ✅ Test 3 |
| Database corruption on drive failure | MariaDB in Docker volume (not /mnt/data) | ✅ Test 4 |
| Data loss on storage failure | Rclone daily backup to Google Drive | ✅ Backup tested |
| Public access after VPN failure | ZTNA (no fallback route) | ✅ Test 2 |

## Comparison to Industry Standards

| Tier | Typical RTO | PiCore |
|---|---|---|
| Enterprise (Tier 1) | < 1 hour | ✅ Better |
| SMB / Mid-market | < 4 hours | ✅ Better |
| Consumer NAS (Synology) | Manual restart, minutes | ✅ Better (auto) |
| PiCore | **< 15 seconds** | — |
