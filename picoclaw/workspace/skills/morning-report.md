# Skill: Morning Report

## Trigger

Cron — runs automatically at 8:00 AM daily.
Also fires when user asks for "daily summary" or "morning report".

## Report Format

```
📊 PiCore Morning Report — {date}

Uptime: {uptimeFormatted}
Containers: {activeContainers}/8 running

Memory: {memoryUsedMB}/{memoryTotalMB} MiB ({memoryUsedPercent}%)
Swap: {swapUsedMB} MiB used of {swapTotalMB} MiB
CPU temp: {cpuTempCelsius}°C

OS Drive: {diskUsedPercent}% used ({diskUsedGB}/{diskTotalGB} GB)
Data Drive: {dataDiskUsedPercent}% used ({dataDiskUsedGB}/{dataDiskTotalGB} GB)

Security: {fail2ban_bans} IPs banned overnight
Backup: {backup_status} ({backup_time})

{warnings_if_any}
```

## Data Sources

- System metrics: GET http://localhost:8085/api/stats
- Fail2Ban bans: `sudo fail2ban-client status sshd`
- Last backup: `ls -t ~/opennas_backups/*.log | head -1`

## Warnings to Include

If any threshold exceeded, append:
- ⚠️ CPU temp > 70°C
- ⚠️ RAM > 85% used
- ⚠️ Disk > 80% used
- ⚠️ Swap > 75% used
- ⚠️ Any container not running (compare activeContainers to 8)
