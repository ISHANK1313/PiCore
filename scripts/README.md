# Scripts

Utility scripts for PiCore setup, maintenance, and hardware integration.

## Setup Scripts

| Script | Purpose | Run as |
|---|---|---|
| `initial-setup.sh` | Full Pi setup from scratch (packages, docker, UFW, swap) | sudo |
| `mount-data-drive.sh` | Format and permanently mount 128GB data drive | sudo |
| `swap-setup.sh` | Create and enable 2GB swapfile | sudo |

## Hardware Scripts

| Script | Purpose | Run as |
|---|---|---|
| `oled-stats.py` | Live stats on SH1106 OLED display (I2C) | python3 |
| `shutdown-button.py` | GPIO shutdown button (hold 3s) | sudo python3 |

## Usage

```bash
# Full initial setup (run once after flashing OS)
sudo bash scripts/initial-setup.sh

# Mount data drive (run once after initial setup)
sudo bash scripts/mount-data-drive.sh

# Setup swap (included in initial-setup, run separately if needed)
sudo bash scripts/swap-setup.sh

# OLED display (requires luma.oled installed)
pip3 install luma.oled requests --break-system-packages
python3 scripts/oled-stats.py

# Shutdown button (requires RPi.GPIO)
pip3 install RPi.GPIO --break-system-packages
sudo python3 scripts/shutdown-button.py
```

## OLED Hardware

Connect SH1106 OLED via I2C:
- VCC → 3.3V (Pin 1)
- GND → GND (Pin 6)
- SDA → GPIO 2 (Pin 3)
- SCL → GPIO 3 (Pin 5)

The display polls `/api/stats` every 10 seconds and shows:
CPU temp, RAM usage, disk usage, uptime, container count.

## Shutdown Button Hardware

Connect tactile button:
- One leg → GPIO 21 (Pin 40)
- Other leg → GND (Pin 39)

Hold 3 seconds for graceful shutdown.
