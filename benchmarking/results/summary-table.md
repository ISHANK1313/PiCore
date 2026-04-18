# PiCore Benchmark Summary

All values measured on production hardware, March 27, 2026.

## Storage

| Metric | PiCore (Measured) | Synology DS223 | Google Cloud pd-ssd | Ratio vs Synology |
|---|---|---|---|---|
| Sequential Read | **26.2 MB/s** | 225 MB/s | ~200 MB/s | 1:8.6x |
| Sequential Write | **24.6 MB/s** | 200 MB/s | ~180 MB/s | 1:8.1x |
| Random Read IOPS (4K) | **657** | ~5,000 | ~3,000 | 1:7.6x |
| Random Write IOPS (4K) | **657** | ~4,500 | ~2,800 | 1:6.8x |
| Read latency p50 | **1.01 ms** | ~0.2 ms | ~1 ms | ~5x worse |
| Read latency p99 | **1,132 ms** | ~5 ms | ~10 ms | ~226x worse |

## Network

| Metric | PiCore (Measured) | Synology DS223 | Google Cloud |
|---|---|---|---|
| LAN throughput | **18.7 Mbps** | 2,500 Mbps | 1,000+ Mbps |
| VPN throughput | **20.5 Mbps** | N/A | N/A |
| VPN overhead | **-1.8 Mbps (negative)** | N/A | N/A |

## API Performance

| Metric | Value |
|---|---|
| Requests/sec (20 concurrent) | **1.70** |
| Average latency | **1.66s** |
| Latency stdev | **16.35ms** |
| Timeout rate under load | **96%** (20 concurrent — not representative of normal use) |
| Single-client latency | **~1.66s** (by design) |

## Power & Cost

| Metric | PiCore | Synology DS223 | Google Cloud e2-micro |
|---|---|---|---|
| Idle power | **~3W** | ~8W | N/A |
| Load power | **~5W** | ~15W | N/A |
| Annual electricity cost | **~₹350** | ~₹1,050 | N/A |
| Hardware cost | **₹5,000** | ₹27,000 | ₹0 |
| Monthly service cost | **₹0** | ₹0 | **₹4,000** |
| 5-year TCO | **₹8,750** | ₹32,250 | ₹2,40,000 |

## Chaos Testing RTO

| Failure Type | Downtime | Recovery | Manual Intervention |
|---|---|---|---|
| Container crash | **~4s** | **~4s** | **NO** |
| VPN failure | Duration of outage | **~3s** | **NO** |
| Resource starvation | **0 (degraded)** | Immediate | **NO** |
| Storage failure | **~30s** | **~12s** | YES (mount -a) |
