# PiCore — Project Overview

**PiCore** is a single-node edge cloud platform built entirely on a Raspberry Pi 4
with 1GB RAM. It implements production-grade infrastructure patterns on severely
constrained hardware, including containerized microservices, Zero-Trust Network
Access, a custom hardware telemetry API, an AI agent layer, and a validated
chaos engineering test suite.

---

## What PiCore Is

PiCore is not a tutorial project. It is an attempt to answer a specific
engineering question:

> *How many production infrastructure patterns can be correctly implemented
> on a ₹5,000 edge device, and what are the measurable tradeoffs?*

The answer, documented with real benchmarks and failure test results, forms
the core contribution of this project.

---

## Core Services

| Service | Purpose | Technology |
|---|---|---|
| Private Cloud Drive | File storage, sync, sharing | Nextcloud + MariaDB |
| Media Server | Stream movies to any device | Jellyfin |
| Reverse Proxy | Route all traffic, TLS termination | Nginx Proxy Manager |
| AI Agent | Telegram bot, NAS automation | PicoClaw (Go, NVIDIA NIM) |
| Hardware Telemetry | Live system metrics API | Spring Boot 3 (Java) |
| Service Monitoring | Uptime tracking | Uptime Kuma |
| Container Management | Docker UI | Portainer CE |
| DNS Ad Blocking | Network-wide ad filtering | Pi-hole |

---

## Security Stack

| Layer | Tool | What It Does |
|---|---|---|
| Network perimeter | Tailscale ZTNA | No open ports, WireGuard tunnels |
| Firewall | UFW | Allowlist: 22, 80, 443 only |
| Intrusion prevention | Fail2Ban | Ban IPs after 5 failed SSH/web attempts |
| Rate limiting | Nginx | 10 req/s per IP |
| Encrypted transport | TLS (auto via Tailscale) | HTTPS for all public endpoints |

---

## Hardware

| Component | Specification |
|---|---|
| Compute | Raspberry Pi 4 Model B (1GB LPDDR4) |
| CPU | ARM Cortex-A72 quad-core @ 1.8GHz (ARM64) |
| OS Drive | 28GB USB Flash (Raspbian OS Lite 64-bit) |
| Data Drive | 128GB USB 3.0 Flash (ext4, /mnt/data) |
| Power | Power Bank (UPS function — prevents filesystem corruption) |
| Network | WiFi (802.11ac) + Tailscale overlay |

---

## Access Model

```
Internet → Tailscale Funnel (HTTPS/443) → Nginx PM → Services
Admin   → Tailscale VPN (SSH/22)        → Direct   → Pi terminal
```

No ports are exposed directly to the internet. All public traffic routes
through Tailscale's global relay network via WireGuard encryption.

---

## Project Scope

This project deliberately touches five engineering domains simultaneously:

1. **Systems administration** — Linux, Docker, storage, networking
2. **Backend engineering** — Spring Boot REST API, direct `/proc`/`sys` reads
3. **Frontend engineering** — Custom dashboard with live telemetry
4. **AI/agent engineering** — PicoClaw with NVIDIA NIM backend
5. **Reliability engineering** — Chaos testing with measured RTO

The constraints (1GB RAM, flash storage, USB 3.0 bandwidth ceiling) are not
obstacles — they are the engineering problem. Every architectural decision
documented in this repository is a response to a measurable hardware limit.

---

## Public URL

The live system is accessible at:
```
https://raspberrypi-1.tail2767bf.ts.net/hub
```

Services:
- `/hub` — Custom dashboard
- `/tv/web` — Jellyfin
- `/apps/files` — Nextcloud
