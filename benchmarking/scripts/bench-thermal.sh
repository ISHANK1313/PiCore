#!/bin/bash
# PiCore Thermal Profiling Script
# Records CPU temp + frequency + throttle state under sustained load

set -e
RESULTS_DIR="/home/ishank/bench_results"
CSV="$RESULTS_DIR/thermal-$(date +%Y%m%d_%H%M%S).csv"
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "  PiCore Thermal Profile"
echo "  Duration: 10 minutes under full load"
echo "=========================================="

echo "time_s,temp_c,freq_mhz,throttle_hex,load_1m" > "$CSV"

# Start CPU stress
sudo apt install stress-ng -y -q
stress-ng --cpu 4 &
STRESS_PID=$!

echo "Stress test started (PID $STRESS_PID)"
echo "Sampling every 2 seconds for 600 seconds..."

for i in $(seq 1 300); do
    TEMP=$(vcgencmd measure_temp 2>/dev/null | grep -oP '[\d.]+' || echo "0")
    FREQ_HZ=$(vcgencmd measure_clock arm 2>/dev/null | grep -oP '\d+$' || echo "0")
    FREQ_MHZ=$((FREQ_HZ / 1000000))
    THROTTLE=$(vcgencmd get_throttled 2>/dev/null | grep -oP '0x\w+' || echo "0x0")
    LOAD=$(cat /proc/loadavg | awk '{print $1}')
    echo "$((i*2)),${TEMP},${FREQ_MHZ},${THROTTLE},${LOAD}" | tee -a "$CSV"
    sleep 2
done

kill $STRESS_PID 2>/dev/null || true

echo ""
echo "Thermal profile saved: $CSV"
echo ""
echo "Key values to check:"
echo "  Max temp: $(sort -t',' -k2 -n "$CSV" | tail -1 | cut -d',' -f2)°C"
echo "  Min freq: $(sort -t',' -k3 -n "$CSV" | head -2 | tail -1 | cut -d',' -f3) MHz"
echo ""
echo "Throttling occurred if freq drops below 1800MHz or throttle_hex != 0x0"
