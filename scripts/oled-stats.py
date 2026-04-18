#!/usr/bin/env python3
"""
PiCore — OLED Stats Display
Shows live system stats on a 1.3" SH1106 OLED (I2C, 128x64)
Polls Spring Boot API every 10 seconds.

Hardware: SH1106 OLED on I2C pins (GPIO 2=SDA, GPIO 3=SCL)
Library: luma.oled
Install: pip3 install luma.oled requests --break-system-packages

Run: python3 oled-stats.py
Enable on boot: add to /etc/rc.local or create systemd service
"""

import time
import requests
from luma.core.interface.serial import i2c
from luma.oled.device import sh1106
from luma.core.render import canvas
from PIL import ImageFont

API_URL = "http://localhost:8085/api/stats"
REFRESH_INTERVAL = 10  # seconds
FONT_SIZE = 10


def get_font():
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", FONT_SIZE)
    except Exception:
        return ImageFont.load_default()


def fetch_stats():
    try:
        resp = requests.get(API_URL, timeout=5)
        if resp.status_code == 200:
            return resp.json()
    except Exception:
        pass
    return None


def render(device, stats, font):
    with canvas(device) as draw:
        if stats is None:
            draw.text((0, 0),  "PiCore", font=font, fill="white")
            draw.text((0, 12), "API offline", font=font, fill="white")
            return

        # Line 1: Hostname / status
        host = stats.get("hostname", "picore")[:12]
        draw.text((0, 0), f"{host}", font=font, fill="white")

        # Line 2: CPU temp + usage
        temp = stats.get("cpuTempCelsius", 0)
        cpu = stats.get("cpuUsagePercent", 0)
        draw.text((0, 12), f"CPU {temp:.1f}C  {cpu:.0f}%", font=font, fill="white")

        # Line 3: RAM
        ram_used = stats.get("memoryUsedMB", 0)
        ram_total = stats.get("memoryTotalMB", 1024)
        ram_pct = stats.get("memoryUsedPercent", 0)
        draw.text((0, 24), f"RAM {ram_used}/{ram_total}MB {ram_pct:.0f}%", font=font, fill="white")

        # Line 4: Disk (data drive)
        disk_pct = stats.get("dataDiskUsedPercent", 0)
        disk_used = stats.get("dataDiskUsedGB", 0)
        draw.text((0, 36), f"Disk {disk_used:.1f}GB {disk_pct:.0f}%", font=font, fill="white")

        # Line 5: Uptime + containers
        uptime = stats.get("uptimeFormatted", "--")
        containers = stats.get("activeContainers", 0)
        draw.text((0, 48), f"Up:{uptime}  [{containers}]ctr", font=font, fill="white")


def main():
    serial = i2c(port=1, address=0x3C)
    device = sh1106(serial)
    font = get_font()

    print("PiCore OLED display started.")
    print(f"Polling {API_URL} every {REFRESH_INTERVAL}s")

    while True:
        stats = fetch_stats()
        render(device, stats, font)
        time.sleep(REFRESH_INTERVAL)


if __name__ == "__main__":
    main()
