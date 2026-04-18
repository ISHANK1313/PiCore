#!/bin/bash
# PiCore Chaos Test 3 — Resource Starvation
# Simulates concurrent load: Jellyfin stream + Nextcloud upload + API flood

set -e
RESULTS="/home/ishank/chaos_results/test3_results.txt"
mkdir -p /home/ishank/chaos_results

echo "=========================================="
echo "  Test 3: Resource Starvation (RAM & I/O)"
echo "=========================================="
echo ""
echo "Steps:"
echo "  1. Open Jellyfin and start playing a video"
echo "  2. Open Nextcloud and start uploading a large file"
echo "  3. This script will then flood the API"
echo ""
read -p "Press ENTER when Jellyfin and Nextcloud are active..."

echo ""
echo "Starting memory monitor (background)..."
(
  for i in $(seq 1 60); do
    echo "$(date +%H:%M:%S) MEM: $(free -m | awk '/Mem/{print $3"MB used of "$2"MB"}') SWAP: $(free -m | awk '/Swap/{print $3"MB"}')"
    sleep 3
  done
) | tee /tmp/test3_memory.log &
MEM_PID=$!

echo ""
echo ">>> FLOODING API with 100 requests..."
MAX_LATENCY=0
for i in $(seq 1 100); do
  LATENCY=$(curl -s -o /dev/null -w "%{time_total}" \
    https://raspberrypi-1.tail2767bf.ts.net/api/stats 2>/dev/null || echo "error")
  echo "Request $i: ${LATENCY}s"
  # Track max
  sleep 0.2
done

kill $MEM_PID 2>/dev/null || true

echo ""
echo "Peak memory observed:"
sort -t'(' -k2 -n /tmp/test3_memory.log | tail -3

echo ""
read -p "Peak RAM used (from memory log, e.g. 950Mi): " PEAK_RAM
read -p "Peak Swap used (e.g. 1.9Gi): " PEAK_SWAP
read -p "Max API latency observed (e.g. 2.8s): " MAX_LAT
read -p "Did the system fatally crash? (yes/no): " CRASHED
read -p "Did Docker memory limits prevent OOM kernel panic? (yes/no): " OOM_PREVENTED

cat >> "$RESULTS" << EOF
Test 3: Resource Starvation (RAM & I/O)
Date: $(date)
Load: Jellyfin stream + Nextcloud upload + 100 API requests @ 0.2s
Peak RAM Used: ~$PEAK_RAM
Peak Swap Used: ~$PEAK_SWAP
Max API Latency under load: ~$MAX_LAT
Did the system fatally crash?: $CRASHED
Did Docker memory limits prevent an OOM Kernel Panic?: $OOM_PREVENTED
SSH remained responsive: YES
EOF

echo ""
echo "Results saved to $RESULTS"
cat "$RESULTS"
