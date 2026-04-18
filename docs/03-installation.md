# Installation Guide

This guide follows the exact sequence used to build PiCore, derived from
production setup notes. Every command was tested on Raspberry Pi 4 (1GB).

---

## Prerequisites

- Raspberry Pi 4 (any RAM, 1GB minimum)
- 28GB+ USB flash drive (OS)
- 128GB+ USB flash drive (data storage)
- Power supply (5V/3A minimum) or power bank
- Laptop with SSH client
- Stable WiFi connection

---

## Phase 1 — OS Setup

### 1.1 Flash Raspbian OS Lite

1. Download Raspberry Pi Imager from raspberrypi.com
2. Select **Raspberry Pi OS Lite (64-bit)**
3. Flash to 28GB USB flash drive
4. In Imager advanced settings: enable SSH, set username/password, configure WiFi

### 1.2 Enable USB Boot

```bash
# On an existing Pi (or using SD card first):
sudo raspi-config
# → Advanced Options → Boot Order → USB Boot
```

### 1.3 First SSH Connection

```bash
ssh pi@<pi-ip-address>
# Or: ssh ishank@raspberrypi.local
```

If you get a stored fingerprint error:
```bash
ssh-keygen -R <pi-ip-address>
```

### 1.4 System Update

```bash
sudo apt update && sudo apt upgrade -y
```

---

## Phase 2 — Storage Setup

### 2.1 Identify Drives

```bash
lsblk
# OS drive: typically /dev/sda (28GB flash)
# Data drive: typically /dev/sdc (128GB flash)
```

### 2.2 Format Data Drive

```bash
sudo mkfs.ext4 /dev/sdc
```

### 2.3 Create Mount Point

```bash
sudo mkdir -p /mnt/data
```

### 2.4 Permanent Mount via fstab

```bash
# Get the UUID of the data drive
sudo blkid

# Add to fstab
sudo nano /etc/fstab
# Add this line (replace UUID with your actual UUID):
# UUID=your-uuid-here /mnt/data ext4 defaults,noatime 0 2

# Mount everything
sudo mount -a

# Verify
df -h /mnt/data
```

### 2.5 Set Permissions for Docker

```bash
sudo chown -R 33:33 /mnt/data
```

---

## Phase 3 — Swap Space

```bash
# Create 2GB swapfile on OS drive
sudo fallocate -l 2G /swapfile

# Lock down permissions
sudo chmod 600 /swapfile

# Format as swap
sudo mkswap /swapfile

# Enable immediately
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

Expected output shows ~2GB swap available.

---

## Phase 4 — Docker

```bash
# Install Docker
curl -sSL https://get.docker.com | sh

# Add user to docker group
sudo usermod -aG docker ishank

# Refresh permissions (no reboot needed)
newgrp docker

# Verify
docker ps
```

---

## Phase 5 — Deploy the Stack

```bash
# Copy docker-compose.yml to Pi
scp infrastructure/docker-compose.yml ishank@raspberrypi.local:~/

# Start all services
docker compose up -d

# Monitor startup (takes 2-3 minutes first time)
docker compose logs -f
```

Verify all containers are running:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Expected output:
```
NAMES              STATUS
jellyfin           Up X minutes
nas-api            Up X minutes
nextcloud-app-1    Up X minutes
nextcloud-db-1     Up X minutes
npm                Up X minutes
opennas-frontend   Up X minutes
portainer          Up X minutes
uptime-kuma        Up X minutes (healthy)
```

---

## Phase 6 — Tailscale

```bash
# Install
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate (opens browser on first run)
sudo tailscale up

# Enable Funnel for public HTTPS access
sudo tailscale funnel --bg 80

# Enable HTTPS for Jellyfin on alternate port
sudo tailscale funnel --bg --https=8443 8096

# Check status and get your public URL
tailscale status
```

Your public URL will be: `https://raspberrypi-1.tail2767bf.ts.net`

**Tailscale DNS configuration** (in Tailscale admin console):
1. DNS → Enable HTTPS certificates
2. Access Controls → Add nodeAttrs for funnel:
```json
"nodeAttrs": [
  {
    "target": ["autogroup:member"],
    "attr": ["funnel"]
  }
]
```

---

## Phase 7 — Security Hardening

```bash
# Run the full UFW setup script
bash security/ufw-setup.sh

# Install and configure Fail2Ban
bash security/fail2ban-setup.sh

# Verify
sudo ufw status
sudo fail2ban-client status
```

---

## Phase 8 — Nextcloud Configuration

Tell Nextcloud its public domain name:
```bash
sudo docker exec --user www-data nextcloud-app-1 php occ \
  config:system:set trusted_domains 1 \
  --value="raspberrypi-1.tail2767bf.ts.net"

sudo docker exec --user www-data nextcloud-app-1 php occ \
  config:system:set overwrite.cli.url \
  --value="https://raspberrypi-1.tail2767bf.ts.net"

sudo docker exec --user www-data nextcloud-app-1 php occ \
  config:system:set overwriteprotocol \
  --value="https"

sudo docker restart nextcloud-app-1
```

Access Nextcloud at: `https://raspberrypi-1.tail2767bf.ts.net/apps/files`

---

## Phase 9 — Nginx Proxy Manager

1. Access NPM at `http://<local-pi-ip>:81`
2. Default credentials: `admin@example.com` / `changeme`
3. Change password immediately
4. Add Proxy Host:
   - Domain: `raspberrypi-1.tail2767bf.ts.net`
   - Scheme: `http`
   - Forward Hostname: `<local-pi-ip>`
   - Forward Port: `8080`
5. Custom Locations tab → Add:
   - Location: `/tv` → Jellyfin → Port 8096
   - Location: `/hub` → opennas-frontend → Port 8081
   - Location: `/api` → nas-api → Port 8085
6. Set Jellyfin base URL in Jellyfin Admin → Networking → Base URL: `/tv`

---

## Phase 10 — Spring Boot API

```bash
# Copy project to Pi
scp -r spring-boot-api/ ishank@raspberrypi.local:~/springboot/

# Build on Pi (requires Maven)
sudo apt install maven -y
cd ~/springboot
sudo docker build -t custom-nas-api:latest .

# Add to infrastructure stack in Portainer and deploy
```

Test the API:
```bash
curl https://raspberrypi-1.tail2767bf.ts.net/api/stats
curl https://raspberrypi-1.tail2767bf.ts.net/api/health
```

---

## Phase 11 — Automated Backup

```bash
# Install rclone
sudo apt install rclone -y

# Configure Google Drive (interactive wizard)
rclone config
# → n (new remote)
# → Name: gdrive
# → 18 (Google Drive)
# → Leave client_id blank
# → Leave client_secret blank
# → 1 (full access)
# → n (no advanced config)
# → n (no auto config — will give you a URL)
# → Open URL on laptop, authenticate, copy token back to Pi

# Test connection
rclone ls gdrive:

# Set up daily backup
sudo crontab -e
# Add: 0 3 * * * /home/ishank/backup/backup.sh

# Test immediately
bash backup/backup.sh
```

---

## Phase 12 — PicoClaw AI Agent

```bash
# Create directory and download
mkdir ~/picoclaw && cd ~/picoclaw
wget https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw-linux-arm64.tar.gz
tar -xzvf picoclaw-linux-arm64.tar.gz
chmod +x picoclaw

# Generate config
./picoclaw onboard

# Edit config (see picoclaw/config-template.json for reference)
nano ~/.picoclaw/config.json

# Start the NVIDIA proxy (required for vendor prefix handling)
python3 ~/picoclaw/nvidia-proxy.py &

# Start gateway (connects to Telegram)
./picoclaw gateway
```

---

## Verification Checklist

After complete setup, verify:

```bash
# All containers running
docker ps --format "{{.Names}}" | sort

# Public URL accessible
curl -I https://raspberrypi-1.tail2767bf.ts.net/api/health

# Backup working
ls -lh ~/opennas_backups/

# UFW active
sudo ufw status

# Fail2Ban running
sudo fail2ban-client status

# Swap available
free -h | grep Swap

# Data drive mounted
df -h /mnt/data
```
