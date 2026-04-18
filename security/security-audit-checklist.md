# Security Audit Checklist

Run through this checklist after every major change.

## Firewall

```bash
sudo ufw status verbose
```
Expected: Status active, rules for 22/80/443/tailscale0

## Fail2Ban

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```
Expected: sshd jail active, 0 currently banned (normal state)

## Tailscale

```bash
tailscale status
```
Expected: Your Pi listed as connected node

## No Direct Open Ports

```bash
sudo ss -tlnp | grep -v "127.0.0.1\|::1"
```
Expected: Only 80, 443, 22 visible. NOT 8080, 8096, 9000, 3001 (those should be local only)

## TLS Certificate Valid

Open `https://raspberrypi-1.tail2767bf.ts.net` in browser.
Expected: Green padlock, valid certificate from Tailscale

## Docker Containers Running

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```
Expected: All 8 containers running/healthy

## API Keys Not in Git

```bash
git log --all -p | grep -i "nvapi\|token\|password\|api_key"
```
Expected: No output (no secrets in git history)

## Swapfile Permissions

```bash
ls -la /swapfile
```
Expected: `-rw------- 1 root root`

## PicoClaw allow_from Configured

```bash
cat ~/.picoclaw/config.json | grep allow_from
```
Expected: Your numeric Telegram ID listed, NOT empty array `[]`

## Nextcloud Trusted Domain

```bash
sudo docker exec --user www-data nextcloud-app-1 php occ config:system:get trusted_domains
```
Expected: Array containing `raspberrypi-1.tail2767bf.ts.net`

## Automated Backup Working

```bash
ls -lh ~/opennas_backups/ | head -5
rclone ls gdrive:nas-backup | head -5
```
Expected: Recent backup files present on both local and Google Drive

## Memory Limits Active

```bash
docker inspect nextcloud-app-1 | grep -i memory
docker inspect jellyfin | grep -i memory
```
Expected: MemoryLimit values set (not 0)
