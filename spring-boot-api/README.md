# Spring Boot Dashboard API

Custom REST API that exposes live hardware telemetry from the Raspberry Pi's
`/proc` and `/sys` filesystems. Written from scratch — not a library or template.

## Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/api/stats` | 40+ live hardware metrics |
| GET | `/api/health` | Liveness check |

## Key Technical Details

- CPU usage is calculated via two-sample `/proc/stat` delta with 250ms sleep
- `vcgencmd` (GPU temp, throttle, voltage) cached every 15s via `@Scheduled`
- Docker container list cached every 30s via `@Scheduled`
- All `/proc`/`/sys` paths read via Docker volume mounts (not root on host)
- JVM memory: `-Xmx180m -Xms64m -XX:+UseSerialGC` (ARM64 optimised)

## Build

```bash
cd spring-boot-api
sudo docker build -t custom-nas-api:latest .
```

## Deploy

Add to Portainer infrastructure stack YAML, then deploy.
Or add to `docker-compose.yml` and run `docker compose up -d`.

## Test

```bash
curl http://localhost:8085/api/stats | python3 -m json.tool
curl http://localhost:8085/api/health
```

## Source Files

| File | Purpose |
|---|---|
| `DashboardApplication.java` | Spring Boot entry point |
| `NasStatsController.java` | REST endpoint definitions |
| `NasStatsService.java` | All metric reading logic |
| `NasStats.java` | Data model (all 40+ fields) |
| `application.properties` | Port, paths, cache intervals |
| `Dockerfile` | Multi-stage build, ARM64 optimised |
| `pom.xml` | Dependencies (Spring Boot 3, no extra deps) |
