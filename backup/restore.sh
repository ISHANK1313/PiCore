#!/bin/bash
# PiCore — Restore from Google Drive Backup
# WARNING: This will overwrite /mnt/data with backup contents
# Run as: bash restore.sh

set -e

echo "============================================"
echo "  PiCore Restore Script"
echo "  WARNING: This overwrites /mnt/data"
echo "============================================"
echo ""

read -p "Are you sure you want to restore? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

GDRIVE_SOURCE="gdrive:nas-backup"
DATA_DEST="/mnt/data"

# Verify mount
if ! mountpoint -q "$DATA_DEST"; then
    echo "ERROR: $DATA_DEST is not mounted. Mount it first with: sudo mount -a"
    exit 1
fi

echo ""
echo "Listing available files in backup..."
rclone ls "$GDRIVE_SOURCE" | head -30
echo ""

read -p "Proceed with full restore? This will sync $GDRIVE_SOURCE → $DATA_DEST (yes/no): " CONFIRM2
if [ "$CONFIRM2" != "yes" ]; then
    echo "Restore cancelled."
    exit 0
fi

echo ""
echo "Starting restore..."
rclone sync "$GDRIVE_SOURCE" "$DATA_DEST" \
    --log-level INFO \
    --transfers 2 \
    --checkers 4

echo ""
echo "Restore complete. Restart Nextcloud to reload files:"
echo "  docker restart nextcloud-app-1"
