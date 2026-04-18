# Skill: NAS Stats

## Trigger

When user asks about system health, CPU temp, memory, disk usage, uptime,
or any metric about the Pi server.

## Steps

1. Call: GET http://localhost:8085/api/stats
2. Parse the JSON response
3. Format and return the relevant metrics

## Key Fields to Extract

```
cpuTempCelsius      → CPU temperature
cpuUsagePercent     → CPU usage
loadAvg1m           → 1-minute load average
memoryTotalMB       → Total RAM
memoryUsedMB        → Used RAM
memoryUsedPercent   → RAM usage %
swapUsedMB          → Swap used
swapTotalMB         → Swap total
diskUsedPercent     → OS drive usage
dataDiskUsedPercent → Data drive usage
uptimeFormatted     → Human-readable uptime
activeContainers    → Container count
containerNames      → List of running containers
networkRxKbps       → Current download speed
networkTxKbps       → Current upload speed
```

## Warning Thresholds

Flag these values as concerning:
- cpuTempCelsius > 70°C → warn about cooling
- memoryUsedPercent > 85% → warn about RAM pressure
- swapUsedMB > 1500 → warn about heavy swap usage
- diskUsedPercent > 80% → warn about OS drive space
- dataDiskUsedPercent > 85% → warn about data drive space
- loadAvg1m > 3.5 → warn about high load

## Example Output

```
CPU: 52.1°C | 13.1% usage | Load: 3.90
RAM: 696/905 MiB (76.9%) | Swap: 798 MiB used
Disk: OS 58.8% | Data 9.7%
Uptime: 7m | Containers: 8
```
