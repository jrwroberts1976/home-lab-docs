# Home Lab Documentation

Technical documentation for the `jrwroberts1976` home lab, including infrastructure, monitoring, networking, security, automation, backups, and hosted services.

## Current todo

### Active

- Review the stale/unverified ASUS `192.168.2.220:9106` Prometheus target.
- Backups + integrity/replica BAU check.
- APT/security updates + reboot requirements.
- Docker/WUD BAU check.
- Pi-hole/DNS health + block enforcement check.
- Suricata meaningful overnight alerts.
- CPU/memory/disk/core services check.
- Fix the **High CPU Usage** Grafana alert rule error.
- Continue `projects.jrwroberts.co.uk` documentation.
- Continue the homelab data dictionary.
- Tapo → Grafana proof of concept.
- Jenkins tests/docs.
- Suricata dashboard improvements.
- Portfolio/contact form.
- Maintenance-page / NPM-token work.

### Completed

- Blocked-MAC monitoring — completed, pending real trigger.
- Standardised Grafana alert emails.
- ASUS router monitoring path documented.
- Network discovery source/path documented.
- Important Scripts page created.
- Scripts/config/systemd assets saved to `home-lab-docs`.
- All recent documentation changes merged to `main`.

### Recommended next item

Fix the **High CPU Usage** Grafana alert rule. The email formatting is now standardised, but the rule itself still has the reduce/evaluation problem.

## Documentation

- [Network Discovery Dashboard](network-discovery-dashboard.md) — LAN device discovery, persistent MAC inventory, friendly-name enrichment, Prometheus metrics, and automatic per-device Grafana dashboard creation.
- [ASUS Router Monitoring](asus-router-monitoring.md) — confirmed router-health collector path on TestServer, systemd service ownership, Node Exporter textfile metrics, and the unresolved/legacy `:9106` scrape endpoint.
- [Important Scripts](important-scripts.md) — operationally important scripts with an explicit Server / Host field, paths, purpose, inputs, outputs, and how each script is started.
- [Blocked MAC Monitoring](blocked-mac-monitoring.md) — reusable ASUS-router log watcher on ids-01, watched-MAC configuration, systemd timer, Prometheus metrics, Grafana alerting, and test procedure.
- [Grafana Alert Email Standard](grafana-alert-email-standard.md) — common homelab alert email subject/body format, reusable notification templates, and deployment procedure.
- [Daily Homelab Actions Log](daily-actions-log.md) — dated follow-up notes from the automated daily homelab security and recovery emails.

## Operational assets

- [Scripts and deployment assets](scripts/README.md) — repository copies of the operational scripts, their runtime hosts and paths, supporting systemd units, config files, and Grafana alert deployment tooling.
