#!/bin/bash
# PiCore — Fail2Ban Setup Script
# Run as: sudo bash security/fail2ban-setup.sh

set -e

echo "============================================"
echo "  PiCore Fail2Ban Setup"
echo "============================================"

apt install fail2ban -y
echo "[OK] Fail2Ban installed"

# Copy jail config
cp security/fail2ban-jail.local /etc/fail2ban/jail.local
cp security/nextcloud-filter.conf /etc/fail2ban/filter.d/nextcloud.conf
echo "[OK] Config files copied"

systemctl enable fail2ban
systemctl restart fail2ban
echo "[OK] Fail2Ban started and enabled on boot"

sleep 2
echo ""
echo "============================================"
echo "  Fail2Ban status:"
echo "============================================"
fail2ban-client status
echo ""
echo "  SSH jail:"
fail2ban-client status sshd
