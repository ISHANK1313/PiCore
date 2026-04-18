# PicoClaw Integration

AI agent layer for PiCore. Connects the NAS stack to Telegram via
PicoClaw (Go binary, <10MB RAM, <1s startup).

## Status: Working

Confirmed working as of April 18, 2026:
- Gateway starts cleanly (16 tools, 7 skills)
- Telegram bot "Project Admin Bot" responds
- Health reports include live memory + container CPU data

## Quick Start

```bash
# Start NVIDIA prefix proxy (required)
python3 ~/picoclaw/nvidia-proxy.py &

# Start Telegram gateway
cd ~/picoclaw
./picoclaw gateway
```

## Architecture

```
Telegram → PicoClaw → nvidia-proxy.py → NVIDIA NIM → response
                    ↓
              Spring Boot API (/api/stats)
```

## Key Files

| File | Purpose |
|---|---|
| `config-template.json` | Config template (no real keys) |
| `nvidia-proxy.py` | Adds vendor prefix to model names |
| `workspace/AGENT.md` | Agent role and instructions |
| `workspace/SOUL.md` | Tone and response format |
| `workspace/skills/` | Task-specific skill files |

## NVIDIA Proxy

PicoClaw strips vendor prefixes from model names — sends
`nemotron-3-super-120b-a12b` instead of `nvidia/nemotron-3-super-120b-a12b`.
The proxy adds it back. Run it before starting the gateway.

## Configuration

Copy `config-template.json` to `~/.picoclaw/config.json` and fill in:
- `channels.telegram.token` — from BotFather
- `channels.telegram.allow_from` — your numeric Telegram user ID
- NVIDIA API key in `nvidia-proxy.py`

## Skills Available

- `nas-stats.md` — live system health reports
- `docker-control.md` — container status and restarts
- `backup-trigger.md` — manual backup + status
- `security-alert.md` — Fail2Ban events + UFW rules
- `morning-report.md` — scheduled daily summary
