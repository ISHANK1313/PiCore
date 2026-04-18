# PiCore vs Commercial Infrastructure

This document compares PiCore against three reference systems:
Google Cloud (managed cloud), Synology DS223 (commercial NAS), and
Cisco (enterprise network infrastructure). All PiCore numbers are measured.
Reference system numbers are from official documentation and pricing pages.

---

## 1. Cost Comparison — 5-Year TCO

### PiCore vs Google Cloud (equivalent workload)

Google Cloud equivalent for PiCore's workload:
- e2-micro (2 vCPU, 1GB RAM) — closest compute match
- 128GB Persistent Disk (SSD)
- Cloud Storage bucket for backups
- Cloud Load Balancing for public HTTPS

| Cost Item | PiCore | Google Cloud Equivalent |
|---|---|---|
| Hardware/compute | ₹5,000 (one-time) | ₹0 upfront |
| Monthly compute | ₹0 | ₹1,200/mo (e2-micro) |
| Monthly storage (128GB) | ₹0 | ₹1,300/mo (pd-ssd) |
| Monthly egress (50GB/mo) | ₹0 | ₹850/mo |
| Monthly backup | ₹0 | ₹650/mo (Cloud Storage) |
| SSL/TLS | ₹0 (Tailscale) | ₹0 (Managed) |
| **Monthly total** | **₹0** | **₹4,000/mo** |
| **Year 1** | **₹5,000** | **₹48,000** |
| **5-year TCO** | **₹8,750** (with ₹750/yr electricity) | **₹2,40,000** |
| **Savings over 5 years** | — | **₹2,31,250** |

**Data sovereignty:** Google Cloud — your data is on Google's servers in
their jurisdiction. PiCore — data never leaves your room.

---

### PiCore vs Synology DS223

Synology DS223 is a 2-bay NAS, the entry-level commercial equivalent.

| Metric | PiCore | Synology DS223 |
|---|---|---|
| Hardware cost | **₹5,000** | **₹15,000–18,000** |
| + 2× HDD (4TB each) | N/A | + ₹12,000 |
| Total hardware | **₹5,000** | **₹27,000–30,000** |
| Monthly subscription | **₹0** | ₹0 (one-time) |
| Sequential Read | 26.2 MB/s | 225 MB/s |
| Sequential Write | 24.6 MB/s | 200 MB/s |
| RAM | 1GB DDR4 | 2GB DDR4 |
| Custom API | ✅ Spring Boot (original) | ❌ |
| AI agent | ✅ PicoClaw + Telegram | ❌ |
| Telegram bot | ✅ | ❌ |
| Live telemetry dashboard | ✅ 40+ metrics | Limited |
| Chaos testing validated | ✅ Documented RTO | ❌ |
| Open source stack | ✅ 100% | Partial |
| ARM64 Linux | ✅ Raspbian Lite | ❌ (Synology DSM) |
| ZTNA (Tailscale) | ✅ | ❌ (QuickConnect) |
| Hardware MFA (NFC) | Planned | ❌ |
| RAID support | ❌ (single drive) | ✅ RAID 1 |
| Performance scaling | ❌ Hard ceiling | ✅ Add drives |

**Synology advantages:** RAID redundancy, superior disk throughput, mature
ecosystem (DSM packages), SATA interface.

**PiCore advantages:** 5x lower cost, custom engineering stack, AI agent
layer, open architecture, documented failure behavior, data sovereignty
without vendor lock-in.

---

### PiCore vs Cisco (Enterprise Network Perspective)

Cisco represents enterprise-grade network infrastructure — a different
category, but relevant for comparing security models.

| Security Feature | PiCore | Cisco Enterprise |
|---|---|---|
| Network access model | **Zero-Trust (Tailscale ZTNA)** | Cisco ISE (ZTNA) |
| VPN protocol | **WireGuard (Tailscale)** | Cisco AnyConnect (IPSec/SSL) |
| Firewall | **UFW (host-based)** | Cisco ASA / Firepower |
| Intrusion Prevention | **Fail2Ban (rule-based)** | Cisco NGIPS |
| Rate limiting | **Nginx (application layer)** | Cisco ASA ACL |
| TLS | **Auto (Tailscale certs)** | PKI infrastructure |
| Network monitoring | **Uptime Kuma + Spring Boot** | Cisco DNA Center |
| Hardware cost | **₹5,000** | **₹5,00,000–50,00,000** |
| Monthly licensing | **₹0** | **₹10,000–1,00,000+/mo** |

**Key comparison:** PiCore implements the same *architectural pattern* as
Cisco's ZTNA (Zero-Trust Network Access) using open-source tooling. The
security principles — no implicit trust, verify every access, least privilege
— are identical. The implementation scale is different by orders of magnitude.

The Cisco equivalent of Tailscale Funnel is Cisco SD-WAN with Zero Trust
access policies. Functionality: equivalent. Cost: 1000x higher.

---

## 2. Performance Comparison

| Metric | PiCore (Measured) | Google Cloud e2-micro | Synology DS223 | Cisco UCS (entry) |
|---|---|---|---|---|
| CPU cores | 4 (ARM) | 2 (x86) | 2 (x86) | 2-4 (Xeon) |
| RAM | 1GB | 1GB | 2GB | 8GB+ |
| Storage IOPS (4K read) | **657** | ~3,000 | ~5,000 | ~50,000+ |
| Sequential read | **26.2 MB/s** | ~200 MB/s | 225 MB/s | 1+ GB/s |
| Network throughput | **18.7 Mbps** | 1 Gbps | 2.5 Gbps | 10+ Gbps |
| API latency (p50) | **1.66s** | ~50ms | N/A | N/A |
| Power consumption | **~5W** | ~15W (shared) | ~15W | 100W+ |

**Honest assessment:** PiCore loses on every raw performance metric. This
is expected — it costs ₹5,000, not ₹50,000 or ₹5,00,000.

The appropriate comparison is not "is PiCore faster than Google Cloud"
(it is not) but "does PiCore solve the personal cloud storage problem
adequately for one user at the lowest possible cost with maximum control."

For that question: yes.

---

## 3. Security Model Comparison

| Feature | PiCore | Google Drive | Synology | Cisco |
|---|---|---|---|---|
| Data location | **Your room** | Google US data centers | Your home | Your datacenter |
| Data sovereignty | **Full** | None | Full | Full |
| Vendor access to data | **None** | Possible | None | None |
| Open source | **100%** | No | Partial | No |
| Audit trail | **Spring Boot logs** | Limited | Yes | Full SIEM |
| Zero-trust model | **Tailscale ZTNA** | Google IAM | QuickConnect | Cisco ISE |
| End-to-end encryption | **WireGuard** | TLS (Google holds keys) | HTTPS | IPSec |
| Physical MFA | **Planned (NFC)** | No | No | Smart card |
| AI agent gating | **PicoClaw dead man's switch** | No | No | No |
| Brute force protection | **Fail2Ban** | Google rate limiting | Synology DSM | Cisco ASA |

---

## 4. Capability Comparison

| Capability | PiCore | Google Drive | Synology | Cisco |
|---|---|---|---|---|
| File storage + sync | ✅ Nextcloud | ✅ | ✅ | ❌ |
| Media streaming | ✅ Jellyfin | ❌ | ✅ DSVideo | ❌ |
| Custom REST API | ✅ Spring Boot | ❌ | ❌ | ❌ |
| Live telemetry (40+ metrics) | ✅ Custom | ❌ | Limited | ✅ (different) |
| AI agent (Telegram) | ✅ PicoClaw | ❌ | ❌ | ❌ |
| Chaos testing validated | ✅ Documented | ❌ | ❌ | ✅ (different) |
| Hardware MFA | Planned (NFC) | ❌ | ❌ | ✅ Smart card |
| Automated offsite backup | ✅ Rclone → GDrive | N/A | ✅ | ✅ |
| Container orchestration | ✅ Docker Compose | ❌ | ❌ | ✅ k8s |
| ZTNA | ✅ Tailscale | Google IAM | ❌ | ✅ Cisco ISE |

---

## 5. Honest Conclusion

**PiCore is not a replacement for Google Cloud, Synology, or Cisco.**

It is a deliberately constrained engineering exercise that implements
enterprise architectural patterns (ZTNA, containerized microservices,
observability, chaos engineering, AI agent layer) on a ₹5,000 budget.

The project's value is not in beating commercial products on benchmarks.
The value is in demonstrating that the *patterns and principles* — not the
hardware — are what make infrastructure trustworthy, observable, and resilient.

A production system at scale would use a Synology for NAS, Google Cloud for
compute, and Cisco for enterprise networking. PiCore exists to understand why,
by building all three from scratch on one board.
