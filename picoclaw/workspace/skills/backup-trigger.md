# Skill: Backup Trigger

## Trigger

When user asks to run a backup, check backup status, or asks
when the last backup ran.

## Check Last Backup

```bash
ls -lht /home/ishank/opennas_backups/ | head -5
```

## Trigger Manual Backup

Confirm first: "Run backup now? This syncs /mnt/data to Google Drive."

If confirmed:
```bash
bash /home/ishank/backup/backup.sh
```

Report progress when done. The script logs to ~/opennas_backups/backup_YYYYMMDD.log

## Check Google Drive Space

```bash
rclone about gdrive:
```

## Check What's in Backup

```bash
rclone ls gdrive:nas-backup | head -20
```

## Notes

- Backup runs automatically at 3:00 AM via cron
- Manual trigger uses same script
- If rclone is not authenticated, run: rclone config reconnect gdrive:
