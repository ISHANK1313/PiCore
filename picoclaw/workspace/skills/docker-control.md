# Skill: Docker Control

## Trigger

When user asks about Docker containers, wants to restart a service,
or asks what is running.

## Read-Only Operations (no confirmation needed)

List containers:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

Container resource usage:
```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

Container logs:
```bash
docker logs <container> --tail 20
```

## Restart Operations (require user confirmation)

Restart a container:
```bash
docker restart <container-name>
```

Confirm before executing. Ask: "Restart <name>? Reply 'yes' to confirm."

## Destructive Operations (NEVER execute without NFC gate)

Stop all containers, remove volumes, delete images — these require
explicit NFC hardware verification. Respond:
"This action requires physical presence verification. Not implemented in CLI mode."

## Container Names in This Stack

- nas-api (Spring Boot Dashboard)
- nextcloud-app-1 (Nextcloud)
- nextcloud-db-1 (MariaDB)
- jellyfin (Media server)
- npm (Nginx Proxy Manager)
- opennas-frontend (Landing page)
- uptime-kuma (Monitoring)
- portainer (Docker UI)
