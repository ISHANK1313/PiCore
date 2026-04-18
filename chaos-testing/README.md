# Chaos Testing

Four controlled failure scenarios validated on production hardware,
March 27, 2026. All results are measured, not estimated.

## Results Summary

| Test | Failure | Downtime | Recovery | Auto |
|---|---|---|---|---|
| 1 | Container crash | ~4s | ~4s | YES |
| 2 | VPN failure | Duration | ~3s | YES |
| 3 | Resource starvation | 0 (degraded) | Immediate | YES |
| 4 | Storage drive failure | ~30s | ~12s | NO (1 cmd) |

All 4 tests passed. No data corruption in any scenario.

## Three-Terminal Setup (Required)

Before any test, open 3 SSH terminals:

**Terminal 2 (hardware monitor):**
```bash
watch -n 2 "echo '=== MEMORY ===' && free -h && echo '=== DOCKER ===' && docker ps --format '{{.Names}} {{.Status}}' && echo '=== CPU TEMP ===' && vcgencmd measure_temp"
```

**Terminal 3 (service health):**
```bash
watch -n 1 "curl -s -o /dev/null -w 'API Status: %{http_code} (%{time_total}s)' https://raspberrypi-1.tail2767bf.ts.net/api/stats"
```

**Terminal 1:** Run test scripts.

## Running Tests

```bash
# Establish baseline first
mkdir -p /home/ishank/chaos_results
# Record baseline manually or use the baseline commands in docs/08-chaos-testing.md

# Run tests in order
bash scripts/test1-container-crash.sh
bash scripts/test2-network-failure.sh
bash scripts/test3-resource-starvation.sh
bash scripts/test4-storage-failure.sh
```

## Warning

Test 4 unmounts the data drive. Run on your own isolated hardware only.
