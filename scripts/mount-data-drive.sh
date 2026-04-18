#!/bin/bash
# PiCore — Data Drive Mount Script
# Sets up 128GB USB flash as permanent /mnt/data

set -e

echo "============================================"
echo "  PiCore Data Drive Setup"
echo "============================================"
echo ""

# Show available drives
echo "Available block devices:"
lsblk
echo ""

read -p "Enter the device path for your 128GB data drive (e.g. /dev/sdc): " DEVICE

# Verify device exists
if [ ! -b "$DEVICE" ]; then
    echo "ERROR: Device $DEVICE not found."
    exit 1
fi

echo ""
echo "WARNING: This will FORMAT $DEVICE as ext4."
echo "ALL DATA ON $DEVICE WILL BE ERASED."
read -p "Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Format
echo ""
echo "Formatting $DEVICE as ext4..."
sudo mkfs.ext4 -L nas-data "$DEVICE"
echo "Format complete."

# Create mount point
echo "Creating mount point /mnt/data..."
sudo mkdir -p /mnt/data

# Get UUID
UUID=$(sudo blkid -s UUID -o value "$DEVICE")
echo "Drive UUID: $UUID"

# Add to fstab
echo "Adding to /etc/fstab for permanent mount..."
if grep -q "nas-data\|$UUID" /etc/fstab; then
    echo "Entry already in fstab, skipping."
else
    echo "UUID=$UUID /mnt/data ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab
fi

# Mount
echo "Mounting..."
sudo mount -a

# Set permissions for Docker/Nextcloud (www-data = UID 33)
echo "Setting permissions..."
sudo chown -R 33:33 /mnt/data

# Create directory structure
echo "Creating directory structure..."
sudo mkdir -p /mnt/data/{cloud-data,media,docker,website,backups}
sudo chown -R 33:33 /mnt/data

echo ""
echo "============================================"
echo "  Data drive setup complete!"
echo "============================================"
df -h /mnt/data
echo ""
echo "Drive structure:"
ls -la /mnt/data/
