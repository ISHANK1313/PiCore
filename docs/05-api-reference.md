# Spring Boot API Reference

Base URL: `https://raspberrypi-1.tail2767bf.ts.net/api`
Local URL: `http://localhost:8085/api`

All endpoints return JSON. CORS is enabled for all origins.

---

## GET /api/stats

Returns live hardware telemetry from `/proc` and `/sys`.

**Response fields:**

### CPU

| Field | Type | Description | Example |
|---|---|---|---|
| cpuTempCelsius | double | CPU temperature from thermal_zone0 | 52.1 |
| gpuTempCelsius | Double | GPU temp via vcgencmd measure_temp | 52.0 |
| cpuUsagePercent | double | CPU usage % (two-sample /proc/stat delta) | 13.1 |
| cpuIoWaitPercent | Double | I/O wait % from /proc/stat | 2.3 |
| cpuFreqMHz | Double | Current clock speed | 1800.0 |
| cpuMaxFreqMHz | Double | Governor max frequency | 1800.0 |
| cpuMinFreqMHz | Double | Governor min frequency | 600.0 |
| cpuCores | int | Core count from /proc/cpuinfo | 4 |
| loadAvg1m | double | 1-minute load average | 1.22 |
| loadAvg5m | double | 5-minute load average | 2.20 |
| loadAvg15m | double | 15-minute load average | 3.90 |
| contextSwitches | Long | Context switches since boot | 3500000 |
| interrupts | Long | Interrupts since boot | 1900000 |

### Power

| Field | Type | Description | Example |
|---|---|---|---|
| cpuVoltage | String | Core voltage via vcgencmd | "1.2000V" |
| throttleStatus | String | Throttle state | "NONE" |
| voltageStatus | String | Voltage event history | "OK" |
| throttleHex | String | Raw throttle hex code | "0x0" |

### Memory

| Field | Type | Description | Example |
|---|---|---|---|
| memoryTotalMB | long | Total RAM in MB | 905 |
| memoryUsedMB | long | Used RAM (total - available) | 696 |
| memoryFreeMB | long | Free RAM (raw) | 43 |
| memoryAvailableMB | Long | Available RAM (includes reclaimable) | 209 |
| memoryCachedMB | Long | Cached pages | 156 |
| memoryBuffersMB | Long | Buffer pages | 24 |
| memorySharedMB | Long | Shared memory | 12 |
| memoryDirtyMB | Long | Dirty pages awaiting flush | 8 |
| memoryUsedPercent | double | RAM used % | 76.9 |

### Swap

| Field | Type | Description | Example |
|---|---|---|---|
| swapTotalMB | long | Total swap (swapfile) | 2048 |
| swapUsedMB | long | Used swap | 798 |
| swapFreeMB | long | Free swap | 1250 |
| swapUsedPercent | double | Swap used % | 38.9 |

### Storage (OS Drive)

| Field | Type | Description | Example |
|---|---|---|---|
| diskTotalGB | double | Total size of root filesystem | 29.7 |
| diskUsedGB | double | Used on root filesystem | 17.6 |
| diskFreeGB | double | Free on root filesystem | 12.3 |
| diskUsedPercent | double | Used % | 58.8 |

### Storage (Data Drive — /mnt/data)

| Field | Type | Description | Example |
|---|---|---|---|
| dataDiskTotalGB | Double | Total size of /mnt/data | 120.5 |
| dataDiskUsedGB | Double | Used on /mnt/data | 11.7 |
| dataDiskFreeGB | Double | Free on /mnt/data | 108.6 |
| dataDiskUsedPercent | Double | Used % | 9.7 |

### Disk I/O (from /proc/diskstats)

| Field | Type | Description | Example |
|---|---|---|---|
| diskReadBytes | Long | Total bytes read since boot | 2533274790 |
| diskWriteBytes | Long | Total bytes written since boot | 128974848 |
| diskReadHuman | String | Human-readable read total | "2.36 GB" |
| diskWriteHuman | String | Human-readable write total | "123.0 MB" |
| diskReadOps | Long | Total read operations | 83000 |
| diskWriteOps | Long | Total write operations | 3000 |

### Network (from /proc/net/dev, eth0/wlan0)

| Field | Type | Description | Example |
|---|---|---|---|
| networkRxBytes | long | Total bytes received since boot | 60416 |
| networkTxBytes | long | Total bytes sent since boot | 66457 |
| networkRxKbps | double | Current receive speed KB/s | 0.4 |
| networkTxKbps | double | Current transmit speed KB/s | 0.5 |
| networkRxPackets | Long | Total packets received | 277 |
| networkTxPackets | Long | Total packets sent | 161 |
| networkRxErrors | Long | Receive errors | 0 |
| networkTxErrors | Long | Transmit errors | 0 |
| networkRxDropped | Long | Dropped receive packets | 0 |
| networkTxDropped | Long | Dropped transmit packets | 0 |

### System

| Field | Type | Description | Example |
|---|---|---|---|
| uptimeSeconds | double | Seconds since boot | 420.0 |
| uptimeFormatted | String | Human-readable uptime | "7m" |
| activeContainers | int | Running Docker containers | 8 |
| containerNames | List\<String\> | Names of running containers | ["jellyfin","nas-api",...] |
| hostname | String | Pi hostname | "9a84a93c5f96" |
| osName | String | OS from /etc/os-release | "Raspberry Pi OS Lite" |
| kernelVersion | String | Kernel from /proc/version | "6.12.76+rpt-rpi-v8" |
| architecture | String | CPU architecture | "aarch64" |
| processCount | Integer | Running processes | 257 |
| threadCount | Integer | Running threads | 548 |
| ntpStatus | String | NTP sync status | "SYNCED" |
| systemTime | String | Server timestamp | "2026-04-18 08:13:38" |

---

**Example response (abbreviated):**
```json
{
  "cpuTempCelsius": 52.1,
  "cpuUsagePercent": 13.1,
  "cpuFreqMHz": 1800.0,
  "cpuCores": 4,
  "loadAvg1m": 3.90,
  "loadAvg5m": 2.20,
  "loadAvg15m": 1.22,
  "memoryTotalMB": 905,
  "memoryUsedMB": 696,
  "memoryUsedPercent": 76.9,
  "swapTotalMB": 2048,
  "swapUsedMB": 798,
  "diskTotalGB": 29.7,
  "diskUsedGB": 17.6,
  "diskUsedPercent": 58.8,
  "dataDiskTotalGB": 120.5,
  "dataDiskUsedGB": 11.7,
  "dataDiskUsedPercent": 9.7,
  "networkRxKbps": 0.4,
  "networkTxKbps": 0.5,
  "uptimeFormatted": "7m",
  "activeContainers": 8,
  "containerNames": ["jellyfin","nas-api","nextcloud-app-1","nextcloud-db-1","npm","opennas-frontend","portainer","uptime-kuma"],
  "hostname": "9a84a93c5f96",
  "kernelVersion": "6.12.76+rpt-rpi-v8",
  "throttleStatus": "NONE",
  "voltageStatus": "OK",
  "systemTime": "2026-04-18 08:13:38"
}
```

---

## GET /api/health

Liveness check for Uptime Kuma and reverse proxy health checks.

**Response:**
```json
{"status":"UP","service":"OpenNAS Dashboard"}
```

**HTTP 200** = service healthy.

---

## Implementation Notes

- CPU usage is calculated using a two-sample delta of `/proc/stat` with 250ms
  between samples. This means each `/api/stats` call takes a minimum of 250ms.
- `vcgencmd` values (GPU temp, throttle, voltage) are cached and refreshed
  every 15 seconds via `@Scheduled` to avoid hitting the videocore repeatedly.
- Docker container list is cached and refreshed every 30 seconds via
  `@Scheduled`.
- All `/proc` and `/sys` paths are accessed via Docker volume mounts
  (`/host/proc`, `/host/sys`) — the container does not run as root on the host.
