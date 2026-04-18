#!/bin/bash
# UFW Firewall Setup for PiCore
# Run as: sudo bash ufw-rules.sh

set -e

echo "[PiCore] Configuring UFW firewall..."

# Reset to clean state
ufw --force reset

# Default: deny all incoming, allow all outgoing
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (critical — do this first to avoid locking yourself out)
ufw allow 22/tcp
echo "[OK] SSH (22/tcp) allowed"

# Allow HTTP and HTTPS (for Nginx Proxy Manager + Tailscale Funnel)
ufw allow 80/tcp
ufw allow 443/tcp
echo "[OK] HTTP/HTTPS (80,443/tcp) allowed"

# Allow local subnet full access (replace with your actual subnet)
ufw allow from 10.56.54.0/24
echo "[OK] Local subnet 10.56.54.0/24 allowed"

# Allow Tailscale interface
ufw allow in on tailscale0
echo "[OK] Tailscale interface allowed"

# Admin ports — local network only
ufw allow from 10.56.54.0/24 to any port 81    # Nginx PM admin
ufw allow from 10.56.54.0/24 to any port 9000  # Portainer
ufw allow from 10.56.54.0/24 to any port 3001  # Uptime Kuma
ufw allow from 10.56.54.0/24 to any port 8085  # Spring Boot API
echo "[OK] Admin ports (81,9000,3001,8085) restricted to local subnet"

# Enable firewall
ufw --force enable

echo ""
echo "[PiCore] UFW configuration complete."
echo ""
ufw status verbose
