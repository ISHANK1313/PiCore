#!/bin/bash
# PiCore Network Benchmark Script
# Run iperf3 server on Pi first: iperf3 -s
# Then run this script FROM YOUR LAPTOP

PI_LOCAL_IP="10.56.54.100"
PI_TAILSCALE_IP="100.66.68.83"

echo "=========================================="
echo "  PiCore Network Benchmark"
echo "  Run iperf3 -s on Pi first"
echo "=========================================="
echo ""

echo "[1/3] Local network TCP throughput..."
iperf3 -c "$PI_LOCAL_IP" -t 10

echo ""
echo "[2/3] Tailscale VPN TCP throughput..."
iperf3 -c "$PI_TAILSCALE_IP" -t 10

echo ""
echo "[3/3] Parallel streams (4) via local..."
iperf3 -c "$PI_LOCAL_IP" -P 4 -t 10

echo ""
echo "Record:"
echo "  Local bitrate (sender/receiver)"
echo "  Tailscale bitrate (sender/receiver)"
echo "  VPN overhead = Tailscale - Local (expect near-zero)"
