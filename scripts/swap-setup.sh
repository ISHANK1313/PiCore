#!/bin/bash
# PiCore — Swap Space Setup
# Creates and enables 2GB swapfile on OS drive

set -e

echo "============================================"
echo "  PiCore Swap Setup"
echo "============================================"
echo ""

SWAPFILE="/swapfile"
SWAP_SIZE="2G"

echo "Current memory state:"
free -h
echo ""

if [ -f "$SWAPFILE" ]; then
    echo "Swapfile already exists at $SWAPFILE"
    swapon --show
    echo ""
    read -p "Recreate swap? (yes/no): " RECREATE
    if [ "$RECREATE" != "yes" ]; then
        echo "Keeping existing swap."
        exit 0
    fi
    sudo swapoff "$SWAPFILE" 2>/dev/null || true
    sudo rm -f "$SWAPFILE"
fi

echo "Creating ${SWAP_SIZE} swapfile..."
sudo fallocate -l "$SWAP_SIZE" "$SWAPFILE"

echo "Locking permissions (root-only read)..."
sudo chmod 600 "$SWAPFILE"

echo "Formatting as swap..."
sudo mkswap "$SWAPFILE"

echo "Enabling swap..."
sudo swapon "$SWAPFILE"

echo "Making permanent in /etc/fstab..."
if grep -q "$SWAPFILE" /etc/fstab; then
    echo "Already in fstab."
else
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo ""
echo "Configuring swappiness (reduce swap aggressiveness)..."
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl vm.swappiness=10

echo ""
echo "============================================"
echo "  Swap setup complete!"
echo "============================================"
free -h
echo ""
ls -lh "$SWAPFILE"
