#!/bin/bash
# PiCore — Full Initial Setup Script
# Run after flashing Raspbian OS Lite and first SSH connection
# Usage: bash initial-setup.sh

set -e

echo "============================================"
echo "  PiCore Initial Setup"
echo "  Raspberry Pi 4 — Raspbian OS Lite 64-bit"
echo "============================================"
echo ""

# ── System update ────────────────────────────────────────────────────
echo "[1/7] Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget nano git htop ufw fail2ban iperf3 fio wrk

# ── Swap space ───────────────────────────────────────────────────────
echo ""
echo "[2/7] Setting up 2GB swapfile..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "Swapfile created and enabled."
else
    echo "Swapfile already exists, skipping."
fi
free -h | grep Swap

# ── Docker ───────────────────────────────────────────────────────────
echo ""
echo "[3/7] Installing Docker..."
if ! command -v docker &>/dev/null; then
    curl -sSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    echo "Docker installed. Run 'newgrp docker' or re-login for permissions."
else
    echo "Docker already installed."
fi
docker --version

# ── Tailscale ────────────────────────────────────────────────────────
echo ""
echo "[4/7] Installing Tailscale..."
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "Tailscale installed. Run: sudo tailscale up"
else
    echo "Tailscale already installed."
fi

# ── UFW Firewall ─────────────────────────────────────────────────────
echo ""
echo "[5/7] Configuring UFW firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow from 10.56.54.0/24
sudo ufw allow in on tailscale0
sudo ufw --force enable
echo "UFW configured."
sudo ufw status

# ── Fail2Ban ─────────────────────────────────────────────────────────
echo ""
echo "[6/7] Configuring Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo "Fail2Ban enabled."

# ── Rclone ───────────────────────────────────────────────────────────
echo ""
echo "[7/7] Installing Rclone..."
if ! command -v rclone &>/dev/null; then
    sudo apt install rclone -y
    echo "Rclone installed. Run: rclone config"
else
    echo "Rclone already installed."
fi

# ── Summary ──────────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "  Initial setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Mount data drive:  bash scripts/mount-data-drive.sh"
echo "  2. Authenticate Tailscale: sudo tailscale up"
echo "  3. Deploy Docker stack: docker compose up -d"
echo "  4. Configure Google Drive: rclone config"
echo "  5. Enable Tailscale Funnel: sudo tailscale funnel --bg 80"
echo ""
echo "System info:"
echo "  RAM: $(free -h | awk '/Mem/{print $2}')"
echo "  Swap: $(free -h | awk '/Swap/{print $2}')"
echo "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
echo "  Kernel: $(uname -r)"
