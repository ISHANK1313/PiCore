#!/bin/bash
# PiCore Concurrent User Simulation
# Simulates multiple users accessing services simultaneously

set -e
RESULTS_DIR="/home/ishank/bench_results"
mkdir -p "$RESULTS_DIR"
LOG="$RESULTS_DIR/concurrent-$(date +%Y%m%d_%H%M%S).txt"

echo "=========================================="
echo "  PiCore Concurrent User Simulation"
echo "=========================================="
echo ""

# Start resource monitor
(
  echo "time,ram_used_mb,swap_used_mb,load_1m" > "$RESULTS_DIR/concurrent-resources.csv"
  for i in $(seq 1 60); do
    RAM=$(free -m | awk '/Mem/{print $3}')
    SWAP=$(free -m | awk '/Swap/{print $3}')
    LOAD=$(cat /proc/loadavg | awk '{print $1}')
    echo "$(date +%H:%M:%S),$RAM,$SWAP,$LOAD" | tee -a "$RESULTS_DIR/concurrent-resources.csv"
    sleep 2
  done
) &
MONITOR_PID=$!

echo "Simulating 5 concurrent API clients..."
for i in 1 2 3 4 5; do
  (
    for j in $(seq 1 10); do
      RESULT=$(curl -s -o /dev/null -w "Client$i-Req$j: %{http_code} %{time_total}s" \
        https://raspberrypi-1.tail2767bf.ts.net/api/stats 2>/dev/null)
      echo "$RESULT" | tee -a "$LOG"
      sleep 1
    done
  ) &
done

wait

echo ""
echo "Simulating Nextcloud upload (50MB test file)..."
dd if=/dev/urandom of=/tmp/concurrent_test.bin bs=1M count=50 2>/dev/null
curl -u admin:YOURPASSWORD \
     -T /tmp/concurrent_test.bin \
     http://localhost:8080/remote.php/dav/files/admin/concurrent_test.bin \
     2>/dev/null | tee -a "$LOG" || echo "Upload test skipped (no auth)"
rm -f /tmp/concurrent_test.bin

kill $MONITOR_PID 2>/dev/null || true

echo ""
echo "Peak resource usage:"
sort -t',' -k2 -n "$RESULTS_DIR/concurrent-resources.csv" | tail -3

echo ""
echo "Results saved to $RESULTS_DIR/"
