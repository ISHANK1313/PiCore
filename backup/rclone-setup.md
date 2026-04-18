# Rclone Setup — Google Drive Backup

## Install

```bash
sudo apt install rclone -y
```

## Configure Google Drive Remote

```bash
rclone config
```

Follow the wizard:
1. `n` — new remote
2. Name: `gdrive`
3. Storage type: `18` (Google Drive)
4. `client_id`: leave blank
5. `client_secret`: leave blank
6. Scope: `1` (full access)
7. `service_account_file`: leave blank
8. Advanced config: `n`
9. Auto config: `n` (headless Pi — must use laptop)

**On your laptop** (download rclone, extract, run in cmd):
```
rclone authorize "drive"
```
Log in to Google, copy the token back to Pi SSH session.

## Test Connection

```bash
rclone ls gdrive:
```

Should list your Google Drive contents. If empty, the remote is working.

## Create Backup Destination

```bash
rclone mkdir gdrive:nas-backup
```

## Schedule Daily Backup

```bash
sudo crontab -e
```

Add:
```
0 3 * * * /home/ishank/backup/backup.sh
```

Runs every night at 3:00 AM.

## Manual Test

```bash
bash backup/backup.sh
```

## Verify Backup

```bash
rclone ls gdrive:nas-backup | head -20
```

## Token Refresh

If rclone stops working (usually after 6 months), refresh auth:
```bash
rclone config reconnect gdrive:
```
