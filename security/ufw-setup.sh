#!/bin/bash
# PiCore — UFW Security Setup Script
# Run as: sudo bash security/ufw-setup.sh

set -e

echo "============================================"
echo "  PiCore UFW Firewall Setup"
echo "============================================"

# Safety check
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Run as root (sudo bash ufw-setup.sh)"
  exit 1
fi

# Backup existing rules
ufw status verbose > /tmp/ufw-backup-$(date +%Y%m%d).txt 2>&1 || true
echo "[OK] Existing rules backed up to /tmp/"

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH — always first
ufw allow 22/tcp
echo "[OK] SSH allowed (22/tcp)"

# Web traffic
ufw allow 80/tcp
ufw allow 443/tcp
echo "[OK] HTTP/HTTPS allowed (80,443/tcp)"

# Local network — full access
LOCAL_SUBNET="10.56.54.0/24"
ufw allow from $LOCAL_SUBNET
echo "[OK] Local subnet $LOCAL_SUBNET allowed"

# Tailscale interface
ufw allow in on tailscale0
echo "[OK] Tailscale interface (tailscale0) allowed"

ufw --force enable
echo ""
echo "============================================"
echo "  UFW enabled. Current rules:"
echo "============================================"
ufw status verbose
