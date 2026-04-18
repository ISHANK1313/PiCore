# PicoClaw AI Agent Integration

PicoClaw is an ultra-lightweight AI agent (Go binary, <10MB RAM) that
connects the NAS stack to Telegram, enabling natural language interaction
with all services.

---

## What Was Achieved

The Telegram bot "Project Admin Bot" is live and working. Confirmed response:

```
User: Give me full health report of the system

Bot: Here is the current health report for your system:

System Status
* Uptime: The system has been up for 13 minutes.

Memory Usage
* Total: 905 MiB
* Used: 696 MiB
* Free: 43 MiB
* Available: 209 MiB
* Swap: 2.9 GiB (798 MiB used)

Docker Container Resource Usage
| Container | CPU Usage | Memory Usage |
|nas-api | 14.64% | - |
|nextcloud-app-1 | 0.00% | - |
|jellyfin | 0.01% | - |
|opennas-frontend | 0.00% | - |
|npm | 0.04% | - |
|uptime-kuma | 0.28% | - |
|nextcloud-db-1 | 0.02% | - |
|portainer | 0.05% | - |
```

---

## Architecture

```
Telegram
    │
    ▼
PicoClaw Gateway (port 18790, Go binary)
    │ 16 tools loaded, 7 skills available
    ▼
NVIDIA NIM API (meta/llama-3.1-8b-instruct)
via nvidia-proxy.py (localhost:9099)
    │
    ▼
Spring Boot API (/api/stats)
    │
    ▼
/host/proc + /host/sys + docker socket
```

---

## Gateway Startup

```bash
cd ~/picoclaw
python3 ~/picoclaw/nvidia-proxy.py &    # Start NVIDIA prefix proxy
./picoclaw gateway                       # Start Telegram gateway
```

Expected output:
```
📦 Agent Status:
  • Tools: 16 loaded
  • Skills: 7/7 available
✓ Cron service started
✓ Heartbeat service started
✓ Channels enabled: [telegram]
✓ Gateway started on 127.0.0.1:18790
Press Ctrl+C to stop
```

---

## NVIDIA Proxy Requirement

PicoClaw parses model strings as `vendor/model` and sends only `model` to
the API. NVIDIA requires the full `nvidia/model-name`. The proxy corrects
this:

```python
# nvidia-proxy.py adds 'nvidia/' prefix back before forwarding to NIM
if not body.get('model','').startswith('nvidia/'):
    body['model'] = 'nvidia/' + body['model']
```

---

## Config Setup

See `picoclaw/config-template.json` for the full template. Key sections:

```json
{
  "agents": {
    "defaults": {
      "provider": "openai",
      "model_name": "nvidia-nemotron",
      "restrict_to_workspace": true
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOTFATHER_TOKEN",
      "allow_from": ["YOUR_TELEGRAM_NUMERIC_ID"]
    }
  }
}
```

Provider block pointing to local proxy:
```json
{
  "model_name": "nvidia-nemotron",
  "model": "nvidia/nemotron-3-super-120b-a12b",
  "api_base": "http://127.0.0.1:9099",
  "api_key": "dummy"
}
```

---

## Available Skills

| Skill | Trigger example | What it does |
|---|---|---|
| nas-stats | "How is the Pi doing?" | Calls /api/stats, formats health report |
| docker-control | "Show me all containers" | Runs docker ps, formats table |
| backup-trigger | "Run backup now" | Executes rclone sync script |
| security-alert | Automatic (Fail2Ban webhook) | Sends IP ban notification |
| morning-report | Cron 8AM daily | Uptime + backup status + disk usage |

---

## Use Cases Implemented

1. **System health on demand** — ask bot → get formatted report with RAM,
   CPU, disk, uptime, all containers

2. **Container status table** — bot lists all running containers with CPU %

3. **Scheduled morning report** — daily 8AM summary via cron skill

4. **Failure alerts** — when a service goes down, bot notifies via Telegram

---

## Known Limitations

- NVIDIA NIM free tier: ~10-40 RPM. Under heavy use, 429 errors occur
  (PicoClaw retries with backoff — not a crash)
- Docker memory column shows "-" — Docker memory stat reporting limitation
  on Pi 4 (cgroup memory accounting not fully enabled by default)
- NTP status shows N/A until `timedatectl` returns properly in container
- Sessions should be cleared after config changes:
  `rm -rf ~/.picoclaw/sessions/`

---

## Troubleshooting

**Bot does not respond:**
```bash
# Check gateway is running
ps aux | grep picoclaw

# Check Telegram token is valid
curl https://api.telegram.org/bot<YOUR_TOKEN>/getMe

# Check NVIDIA proxy is running
curl http://localhost:9099/v1/models
```

**404 from LLM:**
```bash
# Verify model works directly from Pi
curl https://integrate.api.nvidia.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"meta/llama-3.1-8b-instruct","messages":[{"role":"user","content":"hi"}],"max_tokens":50}'
```

**Session corruption (strange behavior):**
```bash
rm -rf ~/.picoclaw/sessions/
./picoclaw gateway
```
