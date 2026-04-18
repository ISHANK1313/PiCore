# Benchmarking

Production benchmarks run March 27, 2026 on live stack (8 containers running).

## Results Summary

| Metric | Value |
|---|---|
| Sequential Read | 26.2 MB/s |
| Sequential Write | 24.6 MB/s |
| Random 4K IOPS | 657 |
| LAN throughput | 18.7 Mbps |
| VPN throughput | 20.5 Mbps |
| API req/s (20 concurrent) | 1.70 |
| API latency p50 | 1.67s |

See `results/summary-table.md` for full comparison vs Synology/Google Cloud.

## Running Benchmarks

```bash
# Disk (fio)
bash scripts/bench-disk.sh

# Network (run from laptop, start iperf3 -s on Pi first)
bash scripts/bench-network.sh

# API load test
bash scripts/bench-api.sh

# Thermal profiling under sustained load
bash scripts/bench-thermal.sh

# Memory bandwidth
bash scripts/bench-memory.sh

# Concurrent user simulation
bash scripts/bench-concurrent-users.sh
```

## Results Location

All results saved to `~/bench_results/` on the Pi.
Copy to `benchmarking/results/` for inclusion in this repo.
