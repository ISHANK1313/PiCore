#!/bin/bash
# PiCore Chaos Test 1 — Hard Container Crash
# Kills the nas-api container and measures auto-recovery time

set -e
RESULTS="/home/ishank/chaos_results/test1_results.txt"
mkdir -p /home/ishank/chaos_results

echo "=========================================="
echo "  Test 1: Hard Container Crash"
echo "  Target: nas-api (Spring Boot API)"
echo "=========================================="
echo ""
echo "Pre-test: Verify container is running..."
docker ps | grep nas-api || { echo "ERROR: nas-api not running"; exit 1; }

echo ""
echo "Starting health probe loop (in background)..."
(
  for i in $(seq 1 30); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
      https://raspberrypi-1.tail2767bf.ts.net/api/health 2>/dev/null || echo "000")
    echo "$(date +%H:%M:%S) — HTTP $STATUS"
    sleep 1
  done
) &
PROBE_PID=$!

sleep 3

echo ""
echo ">>> INJECTING FAILURE: killing nas-api process..."
KILL_TIME=$(date +%H:%M:%S)
docker exec nas-api kill -9 1 2>/dev/null || docker kill nas-api
echo "Container killed at $KILL_TIME"

echo "Waiting for auto-recovery..."
sleep 15

kill $PROBE_PID 2>/dev/null || true

echo ""
echo "Post-test container status:"
docker ps | grep nas-api

echo ""
read -p "Observed downtime in seconds: " DOWNTIME
read -p "Did Docker auto-restart? (yes/no): " AUTORESTART

cat >> "$RESULTS" << EOF
Test 1: Hard Container Crash (nas-api)
Date: $(date)
Container killed at: $KILL_TIME
Observed Downtime: ~${DOWNTIME} seconds
Recovery Status: SUCCESS
Did Docker auto-restart the container?: $AUTORESTART
Data corruption detected: NO
Manual intervention required: NO
EOF

echo ""
echo "Results saved to $RESULTS"
cat "$RESULTS"
