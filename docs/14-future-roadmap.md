# Future Roadmap

---

## v1.5.0 — IoT Gateway Layer

**MQTT Broker (Mosquitto)**
- Install as Docker container
- ESP32 nodes publish sensor data over WiFi
- Spring Boot subscribes and stores in MariaDB
- Dashboard adds time-series sensor visualization panel

**ESP32 + CC1101 RF Sensor Gateway**
- Receive 433MHz wireless sensors (door, PIR, temperature)
- Decode and forward to MQTT broker
- PicoClaw skill: "What are the sensor readings?"

---

## v1.6.0 — AI Agent Expansion

**PicoClaw NFC Dead Man's Switch**
- Destructive commands (wipe volume, reboot) require NFC tap
- ESP32 + PN532 sends UID hash to Spring Boot
- Spring Boot validates and sets 60-second authorization window
- PicoClaw polls authorization flag before executing

**Rate Limiting in Spring Boot (Bucket4j)**
- Per-IP rate limiting at application layer
- Token bucket algorithm (different from Nginx which is sliding window)
- New benchmark: compare system behavior before and after

**Gitea Self-Hosted Git**
- Docker container on same stack
- Serve this repository from PiCore itself
- RAM estimate: ~60MB — within budget

---

## v1.7.0 — Security Hardening

**WiFi Anomaly Detection**
- ESP32 in promiscuous mode on isolated test network
- Detect deauthentication floods, rogue MAC addresses
- POST anomaly events to Spring Boot `/api/security/wifi-anomaly`
- PicoClaw alerts on Telegram with MAC + frame count

**LUKS Encrypted Volume**
- Encrypt `/mnt/data` at rest
- Key stored separately from drive
- If drive is physically stolen, data is unreadable

**Vaultwarden (Self-Hosted Bitwarden)**
- Password manager as Docker container
- RAM: ~10MB — negligible
- Adds personal productivity dimension to the stack

---

## v2.0.0 — Multi-Node

**Raspberry Pi Cluster (2 nodes)**
- Second Pi as replica node
- Litestream for MariaDB replication to second node
- Shared storage via NFS or SSHFS
- HA proxy for failover

This requires additional hardware investment (~₹8,000 for second Pi).

---

## Known Technical Debt

| Issue | Priority | Fix |
|---|---|---|
| API stats cached, not live under load | Medium | Background refresh thread |
| PicoClaw allow_from not configured | High | Set numeric Telegram ID |
| Tailscale Funnel not auto-starting on reboot | High | Systemd service |
| Docker memory column shows "-" | Low | Enable cgroup memory accounting |
| No automated security update mechanism | Medium | unattended-upgrades |
| Backup integrity not verified | Medium | Add rclone check after sync |
