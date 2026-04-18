#!/bin/bash
# PiCore Memory Benchmark Script
# Tests RAM bandwidth and pressure behaviour

set -e
RESULTS_DIR="/home/ishank/bench_results"
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "  PiCore Memory Benchmark"
echo "=========================================="

# mbw — memory copy bandwidth
if ! command -v mbw &>/dev/null; then
    sudo apt install mbw -y -q
fi

echo ""
echo "[1/2] Memory bandwidth (256MB array)..."
mbw -n 10 256 | tee -a "$RESULTS_DIR/memory-bandwidth.txt"

echo ""
echo "[2/2] Memory pressure test (fill to 85% RAM)..."
FREE_MB=$(free -m | awk '/Mem/{print $4}')
STRESS_MB=$((FREE_MB * 80 / 100))
echo "Stressing with ${STRESS_MB}MB for 30 seconds..."

(
  for i in $(seq 1 30); do
    echo "$(date +%H:%M:%S) RAM: $(free -m | awk '/Mem/{print $3"/"$2"MB"}') SWAP: $(free -m | awk '/Swap/{print $3"MB"}')"
    sleep 1
  done
) &
MONITOR_PID=$!

stress-ng --vm 1 --vm-bytes "${STRESS_MB}M" --timeout 30s 2>/dev/null || true
kill $MONITOR_PID 2>/dev/null || true

echo ""
echo "Memory benchmark complete. Results in $RESULTS_DIR/"
