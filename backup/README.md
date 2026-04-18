# Backup

Automated daily backup of `/mnt/data` to Google Drive via Rclone.

## Schedule

Runs at 3:00 AM daily via cron:
```
0 3 * * * /home/ishank/backup/backup.sh
```

## Files

| File | Purpose |
|---|---|
| `backup.sh` | Main backup script (rclone sync to Google Drive) |
| `restore.sh` | Restore from Google Drive backup |
| `rclone-setup.md` | Google Drive authentication guide |

## Quick Commands

```bash
# Manual backup
bash backup/backup.sh

# Check last backup
ls -lh ~/opennas_backups/ | head -5

# Verify on Google Drive
rclone ls gdrive:nas-backup | head -10

# Restore (interactive)
bash backup/restore.sh
```

## Recovery Point Objective (RPO)

- Database: **0** (MariaDB in Docker volume, separate from /mnt/data)
- User files: **Up to 24 hours** (daily backup)

## Setup

```bash
sudo apt install rclone -y
rclone config   # Follow wizard for Google Drive
sudo crontab -e # Add the 0 3 * * * line
```

See `rclone-setup.md` for detailed configuration.
