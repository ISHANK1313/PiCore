# Contributing to PiCore

PiCore is an open final-year engineering project. Contributions, bug reports,
and suggestions are welcome.

---

## Before Contributing

Read the full architecture in `docs/02-architecture.md` and the bottlenecks
document in `docs/09-bottlenecks-and-tradeoffs.md` first. Many limitations
are intentional hardware constraints, not bugs.

---

## What You Can Contribute

**Documentation fixes** — typos, clarifications, missing steps in setup guides.

**Script improvements** — better error handling in shell scripts, more robust
benchmarking automation.

**New benchmarking scenarios** — additional fio test configurations, new wrk
load profiles.

**Dashboard features** — new metrics cards, UI improvements to `frontend/index.html`.

**Spring Boot API extensions** — new endpoints in `NasStatsController.java`,
new metric readers in `NasStatsService.java`.

**PicoClaw skills** — new skill files in `picoclaw/workspace/skills/`.

---

## What Not to Contribute

- Changes that require > 1GB RAM (incompatible with target hardware)
- Dependencies that have no ARM64 Docker image
- Features that require paid cloud services
- Code that stores API keys or credentials in the repository

---

## Contribution Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Test on actual Raspberry Pi 4 hardware if possible
5. Open a pull request with a clear description

---

## Code Style

**Java:** Standard Java conventions. No Lombok. Keep Spring Boot memory
footprint in mind — avoid heavy dependencies.

**Shell scripts:** Add `set -e` at top. Quote all variables. Add comments
explaining non-obvious commands.

**Python:** PEP 8. Python 3.9+ syntax only (Raspbian Lite default).

---

## Reporting Issues

Include:
- `docker ps` output
- `free -h` output
- `vcgencmd measure_temp` output
- The exact error message
- Which step in the setup guide you reached
