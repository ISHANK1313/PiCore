#!/bin/bash
# PiCore API Benchmark Script
# Tests Spring Boot /api/stats under concurrent load

set -e
RESULTS_DIR="/home/ishank/bench_results"
mkdir -p "$RESULTS_DIR"
API_URL="https://raspberrypi-1.tail2767bf.ts.net/api/stats"

echo "=========================================="
echo "  PiCore API Benchmark"
echo "  Endpoint: /api/stats"
echo "=========================================="

# Install wrk if not present
if ! command -v wrk &>/dev/null; then
    sudo apt install wrk -y
fi

echo ""
echo "[1/3] Single connection baseline (30s)..."
wrk -t 1 -c 1 -d 30s --latency "$API_URL" \
    | tee -a "$RESULTS_DIR/api-single.txt"

echo ""
echo "[2/3] Concurrent load test (20 connections, 30s)..."
wrk -t 2 -c 20 -d 30s --latency "$API_URL" \
    | tee -a "$RESULTS_DIR/api-concurrent.txt"

echo ""
echo "[3/3] Manual request timing (10 sequential)..."
for i in $(seq 1 10); do
    curl -s -o /dev/null -w "Request $i: %{http_code} in %{time_total}s\n" "$API_URL"
done | tee -a "$RESULTS_DIR/api-sequential.txt"

echo ""
echo "Results saved to $RESULTS_DIR/"
echo "Key metrics:"
echo "  Requests/sec, avg latency, p99 latency, timeout count"
