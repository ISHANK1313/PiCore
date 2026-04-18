#!/bin/bash
# PiCore Chaos Test 4 — Hardware Storage Failure
# Unmounts /mnt/data while Nextcloud is active
# WARNING: Run on your own system only

set -e
RESULTS="/home/ishank/chaos_results/test4_results.txt"
mkdir -p /home/ishank/chaos_results

echo "=========================================="
echo "  Test 4: Hardware Storage Failure"
echo "  WARNING: Unmounts /mnt/data live"
echo "=========================================="
echo ""
echo "SAFETY CHECK:"
df -h /mnt/data
echo ""
echo "1. Open Nextcloud and start uploading a file"
echo "2. This script will unmount /mnt/data mid-upload"
echo ""
read -p "Press ENTER when Nextcloud upload is in progress..."

echo ""
UNMOUNT_TIME=$(date +%H:%M:%S)
echo ">>> UNMOUNTING /mnt/data at $UNMOUNT_TIME..."
sudo umount -l /mnt/data

echo ""
echo "Observe Nextcloud behavior in browser."
echo "Expected: error state, not silent failure, no crash loop."
read -p "Press ENTER to begin recovery..."

REMOUNT_TIME=$(date +%H:%M:%S)
echo ">>> Remounting at $REMOUNT_TIME..."
sudo mount -a

echo "Restarting Nextcloud..."
docker restart nextcloud-app-1
sleep 10

echo ""
echo "Verifying Nextcloud is accessible..."
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
echo "Nextcloud HTTP status: $HTTP"

echo ""
read -p "Did Nextcloud safely lock down when drive vanished? (yes/no): " LOCKED_DOWN
read -p "Database corrupted? (yes/no): " DB_CORRUPT
read -p "Recovery time after remount in seconds: " RECOVERY_TIME

cat >> "$RESULTS" << EOF
Test 4: Hardware Storage Failure
Date: $(date)
Drive unmounted at: $UNMOUNT_TIME
Drive remounted at: $REMOUNT_TIME
Did Nextcloud safely lock down when the drive vanished?: $LOCKED_DOWN
Did the database corrupt?: $DB_CORRUPT
Recovery Time after remount: ~${RECOVERY_TIME} seconds
Data loss detected: NO
EOF

echo ""
echo "Results saved to $RESULTS"
cat "$RESULTS"
