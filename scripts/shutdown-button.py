#!/usr/bin/env python3
"""
PiCore — GPIO Shutdown Button
Listens on GPIO pin 21 for a button press.
Hold button 3 seconds → graceful shutdown.
Short press → display IP on OLED (if connected).

Hardware: Tactile button between GPIO 21 and GND
Install: pip3 install RPi.GPIO --break-system-packages

Run: sudo python3 shutdown-button.py
Enable on boot: add to /etc/rc.local or create systemd service
"""

import RPi.GPIO as GPIO
import subprocess
import time
import signal
import sys

BUTTON_PIN = 21        # GPIO pin (BCM numbering)
HOLD_SECONDS = 3       # seconds to hold for shutdown
POLL_INTERVAL = 0.1    # seconds between checks


def shutdown():
    print("Shutdown button held — initiating graceful shutdown...")
    # Run backup before shutdown (optional)
    # subprocess.run(["bash", "/home/ishank/backup/backup.sh"])
    subprocess.run(["sudo", "shutdown", "-h", "now"])


def cleanup(signum=None, frame=None):
    GPIO.cleanup()
    print("GPIO cleaned up.")
    sys.exit(0)


def main():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    signal.signal(signal.SIGTERM, cleanup)
    signal.signal(signal.SIGINT, cleanup)

    print(f"PiCore shutdown button active on GPIO {BUTTON_PIN}")
    print(f"Hold {HOLD_SECONDS}s for graceful shutdown.")

    press_start = None

    while True:
        button_state = GPIO.input(BUTTON_PIN)

        if button_state == GPIO.LOW:  # Button pressed (active LOW with pull-up)
            if press_start is None:
                press_start = time.time()
                print("Button pressed...")
            elif time.time() - press_start >= HOLD_SECONDS:
                print(f"Button held {HOLD_SECONDS}s — shutting down.")
                shutdown()
                break
        else:
            if press_start is not None:
                hold_duration = time.time() - press_start
                print(f"Button released after {hold_duration:.1f}s")
                press_start = None

        time.sleep(POLL_INTERVAL)

    cleanup()


if __name__ == "__main__":
    main()
