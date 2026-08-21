# Home Lab Documentation

Technical documentation for the `jrwroberts1976` home lab, including infrastructure, monitoring, networking, security, automation, backups, and hosted services.

## Current todo

### Active — priority order

- Docker/WUD BAU check.
- Project: end-to-end Docker image version control — inventory declared vs running images, detect drift, define pinning/rollback policy, and integrate WUD as an update signal. Tracked in GitHub issue #9.
- CPU/memory/disk/core services check.
- Restore and verify Suricata 24-hour collection after the collection timeout.
- Investigate CrowdSec reporting synchronisation / DNS resolution.
- Add a Greenbone → Loki ingestion health check.
- Suricata dashboard improvements.
- Continue `projects.jrwroberts.co.uk` documentation.
- Continue the homelab data dictionary.
- Tapo → Grafana proof of concept.
- Jenkins tests/docs.
- Portfolio/contact form.
- Maintenance-page / NPM-token work.

### Complete / pending verification

- **High CPU Usage Grafana alert rule** — reduce/threshold structure fixed and live; pending verification on the next real trigger.
- Blocked-MAC monitoring — completed, pending real trigger.

### Completed today

- `ids-01` secondary Pi-hole / WUD DNS incident resolved — `pihole-secondary` had failed to restart because Docker attempted to bind `192.168.2.242:53` before the Wi-Fi address was available. After the address was present, the Pi-hole container was recreated through Compose, restoring its `pihole-secondary_default` network attachment and `unbound#5335` resolution. The stale Compose pin was also corrected back from `2026.04.1` to the previously running `2026.07.2`, eliminating the temporary FTL/SQLite schema errors. WUD can again resolve Docker Hub and GHCR through the secondary DNS path.
- Docker image version-control project raised as GitHub issue #9 after Dashy and Pi-hole maintenance exposed compose-to-runtime version drift and downgrade risk.
- `k3s-node-01` Grafana APT repository migration — repo changed from `https://packages.grafana.com/oss/deb` to `https://apt.grafana.com`, now uses `signed-by=/etc/apt/keyrings/grafana.asc`, and `apt update` completes cleanly with all packages up to date. The older Grafana key remains in the legacy trusted keyring by choice; it is no longer used by the Grafana repo definition and no warning is produced.
- TestServer Dashy update — deployment mismatch corrected from stale compose pin `4.5.10` while the running container was `4.5.12`; compose is now pinned to `lissy93/dashy:4.5.13`, the image was pulled and Dashy recreated successfully, container health is `healthy`, config validation passes, and Dashy reports version `4.5.13` up to date. Backup saved as `/home/james/docker/stacks/dashboards/docker-compose.yml.bak-20260821`.
- TestServer deliberate reboot and post-maintenance validation completed successfully; host returned normally on kernel `6.18.39+rpt-rpi-v8`, `systemctl --failed` reported 0 failed units, Homepage, Uptime Kuma and Dashy all reached healthy state, and Dashy health checks returned HTTP 200 with valid configuration.
- APT/security/reboot BAU completed across `ids-01`, TestServer, `k3s-node-01`, and DietPi; no host currently requires a reboot.
- TestServer Zeek cleanup — confirmed Zeek is no longer required on this host, purged 10 Zeek-related packages, and freed approximately 321 MB.
- TestServer Zeek dependency cleanup — `apt autoremove` removed 12 now-unused Zeek dependencies and freed a further 12.7 MB.
- TestServer package updates — GitHub CLI upgraded `2.97.0 → 2.98.0` and Terraform upgraded `1.15.8 → 1.15.9`; no services, containers, sessions, or VMs require restart.
- TestServer `needrestart` cleanup — disabled the unsupported processor-microcode hint check via `/etc/needrestart/conf.d/raspberry-pi.conf`; subsequent `needrestart` run completed without the microcode warning and retained service/container/session restart checks.
- DietPi Grafana APT repository removal — removed `/etc/apt/sources.list.d/grafana.list`; subsequent `apt update` completed cleanly, all packages are up to date, and no reboot is required.
- `ids-01` APT/security check — all packages up to date; no reboot required.
- `k3s-node-01` APT/security check — all packages up to date; no reboot required.
- TestServer security update check — no security-repository upgrades and no reboot required.
- Legacy ASUS `192.168.2.220:9106` Prometheus scrape target reviewed, confirmed unused, removed from the active Prometheus configuration, configuration validated with `promtool`, and absence from active targets verified after reload.
- Backup / integrity / restore / replica BAU check.
- Greenbone daily vulnerability review.
- Pi-hole security-event review.
- Linux Host Down incident reviewed and resolved.
- Pi-hole Block Health incident reviewed and resolved.
- Standardised Grafana alert emails.
- ASUS router monitoring path documented.
- Network discovery source/path documented.
- Important Scripts page created.
- Scripts/config/systemd assets saved to `home-lab-docs`.
- Daily actions reorganised into dated folders.
- Recent documentation changes merged to `main`.

### Recommended next item

Finish the Docker/WUD BAU check, then begin the first deliverable for GitHub issue #9: an inventory of Compose-declared versus actually running Docker image versions on TestServer and `ids-01`.

## Documentation

- [Network Discovery Dashboard](network-discovery-dashboard.md) — LAN device discovery, persistent MAC inventory, friendly-name enrichment, Prometheus metrics, and automatic per-device Grafana dashboard creation.
- [ASUS Router Monitoring](asus-router-monitoring.md) — confirmed router-health collector path on TestServer, systemd service ownership, Node Exporter textfile metrics, and retirement of the legacy `192.168.2.220:9106` scrape target.
- [Important Scripts](important-scripts.md) — operationally important scripts with an explicit Server / Host field, paths, purpose, inputs, outputs, and how each script is started.
- [Blocked MAC Monitoring](blocked-mac-monitoring.md) — reusable ASUS-router log watcher on ids-01, watched-MAC configuration, systemd timer, Prometheus metrics, Grafana alerting, and test procedure.
- [Grafana Alert Email Standard](grafana-alert-email-standard.md) — common homelab alert email subject/body format, reusable notification templates, and deployment procedure.
- [Daily Homelab Actions Log](daily-actions-log.md) — dated follow-up notes from the automated daily homelab security and recovery emails.

## Operational assets

- [Scripts and deployment assets](scripts/README.md) — repository copies of the operational scripts, their runtime hosts and paths, supporting systemd units, config files, and Grafana alert deployment tooling.
