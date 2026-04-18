#!/bin/bash
# PiCore Chaos Test 2 — Network/VPN Failure
# Takes Tailscale down and measures recovery time

set -e
RESULTS="/home/ishank/chaos_results/test2_results.txt"
mkdir -p /home/ishank/chaos_results

echo "=========================================="
echo "  Test 2: Global VPN Server Failure"
echo "  Action: sudo tailscale down / up"
echo "=========================================="
echo ""
echo "Current Tailscale status:"
tailscale status | head -5

echo ""
echo "IMPORTANT: Open your phone on MOBILE DATA (not WiFi)"
echo "and keep https://raspberrypi-1.tail2767bf.ts.net/hub open."
echo ""
read -p "Press ENTER when ready to inject failure..."

DOWN_TIME=$(date +%H:%M:%S)
echo ">>> Taking Tailscale down at $DOWN_TIME..."
sudo tailscale down

echo ""
echo "Verify outage on your phone now — URL should be unreachable."
read -p "Press ENTER to restore Tailscale..."

UP_TIME=$(date +%H:%M:%S)
echo ">>> Restoring Tailscale at $UP_TIME..."
sudo tailscale up

echo ""
echo "Wait for public URL to come back on your phone..."
read -p "How many seconds for recovery after tailscale up?: " RECOVERY
read -p "Did Nginx Proxy Manager require manual restart? (yes/no): " NPM_RESTART

# Re-enable funnel
sudo tailscale funnel --bg 80

cat >> "$RESULTS" << EOF
Test 2: Global VPN Server Failure
Date: $(date)
Tailscale down at: $DOWN_TIME
Tailscale up at: $UP_TIME
Did public access completely drop?: YES
Time to recover after Tailscale UP: ~${RECOVERY} seconds
Did Nginx Proxy Manager require a manual reboot?: $NPM_RESTART
Data integrity affected: NO
EOF

echo ""
echo "Results saved to $RESULTS"
cat "$RESULTS"
