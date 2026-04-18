#!/bin/bash
# PiCore — Automated Backup Script
# Runs via cron: 0 3 * * * /home/ishank/backup/backup.sh
# Backs up /mnt/data to Google Drive

set -e

LOG_FILE="/home/ishank/opennas_backups/backup_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="/home/ishank/opennas_backups"
GDRIVE_DEST="gdrive:nas-backup"
DATA_SOURCE="/mnt/data"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$BACKUP_DIR"

echo "[$TIMESTAMP] PiCore backup started" | tee -a "$LOG_FILE"

# Check data drive is mounted
if ! mountpoint -q "$DATA_SOURCE"; then
    echo "[$TIMESTAMP] ERROR: $DATA_SOURCE is not mounted. Aborting." | tee -a "$LOG_FILE"
    exit 1
fi

# Check rclone is available
if ! command -v rclone &> /dev/null; then
    echo "[$TIMESTAMP] ERROR: rclone not found." | tee -a "$LOG_FILE"
    exit 1
fi

# Sync to Google Drive
echo "[$TIMESTAMP] Starting rclone sync: $DATA_SOURCE → $GDRIVE_DEST" | tee -a "$LOG_FILE"

rclone sync "$DATA_SOURCE" "$GDRIVE_DEST" \
    --log-file="$LOG_FILE" \
    --log-level INFO \
    --transfers 2 \
    --checkers 4 \
    --contimeout 60s \
    --timeout 300s \
    --retries 3 \
    --low-level-retries 10 \
    --exclude ".Trash-*/**" \
    --exclude "lost+found/**"

BACKUP_END=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$BACKUP_END] Backup completed successfully." | tee -a "$LOG_FILE"

# Clean up old local logs (keep last 30)
ls -t "$BACKUP_DIR"/backup_*.log | tail -n +31 | xargs rm -f 2>/dev/null || true

echo "[$BACKUP_END] Log saved: $LOG_FILE"
