# Home Lab Documentation

Technical documentation for the `jrwroberts1976` home lab, including infrastructure, monitoring, networking, security, automation, backups, and hosted services.

## Documentation

- [Network Discovery Dashboard](network-discovery-dashboard.md) — LAN device discovery, persistent MAC inventory, friendly-name enrichment, Prometheus metrics, and automatic per-device Grafana dashboard creation.
- [ASUS Router Monitoring](asus-router-monitoring.md) — confirmed router-health collector path on TestServer, systemd service ownership, Node Exporter textfile metrics, and the unresolved/legacy `:9106` scrape endpoint.
- [Important Scripts](important-scripts.md) — operationally important scripts with an explicit Server / Host field, paths, purpose, inputs, outputs, and how each script is started.
- [Blocked MAC Monitoring](blocked-mac-monitoring.md) — reusable ASUS-router log watcher on ids-01, watched-MAC configuration, systemd timer, Prometheus metrics, Grafana alerting, and test procedure.
- [Grafana Alert Email Standard](grafana-alert-email-standard.md) — common homelab alert email subject/body format, reusable notification templates, and deployment procedure.

## Operational assets

- [Scripts and deployment assets](scripts/README.md) — repository copies of the operational scripts, their runtime hosts and paths, supporting systemd units, config files, and Grafana alert deployment tooling.
