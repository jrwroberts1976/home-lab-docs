# Home Lab Documentation

Homelab SOPs, Service Continuity Plans (SCPs), and Service Overview documentation for operating, recovering and understanding the platform.

This repository is the operational documentation source for the `jrwroberts1976` home lab. It covers infrastructure, monitoring, networking, security, automation, backups, hosted services, recovery procedures and day-to-day support.

## Documentation model

The repository is organised around three primary document types:

### Standard Operating Procedures (SOPs)

Repeatable operational procedures for running and supporting the homelab. SOPs answer **how do I do this safely and consistently?**

Typical content includes:

- deployments and maintenance procedures
- patching and upgrade steps
- alert handling and verification
- operational checks
- configuration changes
- monitoring and troubleshooting procedures

### Service Continuity Plans (SCPs)

Recovery and continuity documentation for restoring services after failure or disruption. SCPs answer **how do I recover this service and prove it is healthy again?**

Typical content includes:

- recovery prerequisites
- dependencies and recovery order
- backup and restore procedures
- rebuild steps
- recovery validation
- rollback and fallback options
- recovery evidence and known limitations

### Service Overviews

High-level documentation explaining what each service is, why it exists, how it fits into the platform, and what controls protect it. Service Overviews answer **what is this service and how is it operated?**

Each Service Overview should cover where relevant:

- purpose and scope
- architecture and components
- service owner
- users and consumers
- dependencies
- availability expectations
- monitoring and alerting
- backup and recovery requirements
- security controls
- change and maintenance considerations
- links to related SOPs and SCPs

Implementation-specific engineering projects such as `jenkins-gradle-delivery-lab` and `homelab-container-version-control` remain authoritative in their own repositories. This repository documents how those projects are operated, supported and recovered as part of the homelab service estate.

Initial indexes are maintained under:

```text
sop/
scp/
procedures/
service-overviews/
```

Existing operational documents remain valid and will be progressively classified into these sections without breaking established links.

## Current todo

### Active — priority order

- Remove synthetic Pi-hole enforcement-probe traffic from raw seven-day client/category Prometheus totals while retaining all five active DNS block tests.
- Project: end-to-end Docker image version control — continue Stage 0 inventory of declared vs running images, drift/floating/unmanaged classification, and secret-location inventory. Delivery is now tracked in `jrwroberts1976/homelab-container-version-control` issue #1; the original home-lab-docs issue #9 remains the initiating record.
- Restore and verify Suricata 24-hour collection after the collection timeout.
- Investigate CrowdSec reporting synchronisation / DNS resolution.
- Add a Greenbone → Loki ingestion health check.
- Suricata dashboard improvements.
- Continue `projects.jrwroberts.co.uk` documentation.
- Continue the homelab data dictionary.
- Tapo → Grafana proof of concept.
- Jenkins tests/docs.
- Portfolio/contact form.
- Engineering Portfolio README — replace the default Astro starter README with a project-specific README covering the site's purpose, architecture, deployment workflow and project links.

### Complete / pending verification

- Docker/WUD BAU check — DNS path repaired and verified interactively; pending one successful scheduled WUD scan with `0 errors`, then complete the image/update review.
- **High CPU Usage Grafana alert rule** — reduce/threshold structure fixed and live; pending verification on the next real trigger.
- Blocked-MAC monitoring — completed, pending real trigger.

### Completed today

- ids-01 service estate audited and cleaned — zero failed units; unused Docker Alloy removed in favour of the active systemd collector; obsolete SecOps timer and legacy secondary Pi-hole metrics units archived; active collectors revalidated.
- Daily Security & Recovery Brief enhanced with combined primary and secondary Pi-hole Adult and Malware/Phishing totals by client IP, fresh evidence collection before email delivery, synthetic-probe exclusion and evidence-correct explanatory wording.
- Engineering Portfolio guarded deployment workflow validated end-to-end — the deployment script now distinguishes Docker `running` from application readiness, retries `/healthz` for up to approximately 60 seconds, fails early on Docker `unhealthy`, and runs the container-version-control project route as part of smoke testing. The corrected script was merged to the Engineering Portfolio `main` branch and a subsequent production deployment completed successfully.
- Engineering Portfolio maintenance-mode path coverage fixed and proven persistent — the maintenance Nginx configuration now uses `try_files $uri $uri/ /index.html;`, is bind-mounted read-only through the maintenance Compose stack, survives forced container recreation, passes `nginx -t`, and returned HTTP 200 for `/`, `/about/`, `/projects/`, `/projects/container-version-control/`, and a deliberately nonexistent path while maintenance mode was active.
- The validated maintenance-page Compose/Nginx pattern has been brought under `jrwroberts1976/homelab-container-version-control` as a production pilot artifact rather than remaining an undocumented TestServer-only change.
- Core host-health BAU — no separate repeat SSH sweep required today; TestServer post-reboot service/container validation, all-host APT/security/reboot checks, and the existing Prometheus/Grafana host-health monitoring already cover the intended BAU verification.
- Homelab Hardware Health dashboard documented — Loki-backed kernel/system log monitoring covers aggregate hardware health, disk/filesystem faults, CPU/memory/PCIe errors, thermal/panic events, trends and raw fault evidence with a default 24-hour view.
- `ids-01` secondary Pi-hole / WUD DNS incident resolved and verified interactively — `pihole-secondary` had failed to restart because Docker attempted to bind `192.168.2.242:53` before the Wi-Fi address was available. After the address was present, the Pi-hole container was recreated through Compose, restoring its `pihole-secondary_default` network attachment and `unbound#5335` resolution. The stale Compose pin was corrected back from `2026.04.1` to the previously running `2026.07.2`, eliminating the temporary FTL/SQLite schema errors. WUD was then recreated; Docker repopulated its embedded resolver with external servers `192.168.2.48` and `192.168.2.242`, and normal lookups of Docker Hub and GHCR now succeed with no new startup `EAI_AGAIN` errors. One successful scheduled WUD scan remains as the final BAU verification step.
- Docker image version-control project raised as GitHub issue #9 after Dashy and Pi-hole maintenance exposed compose-to-runtime version drift and downgrade risk; implementation now continues in the dedicated `homelab-container-version-control` repository.
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

Continue Stage 0 of the Docker image version-control project: inventory the TestServer and ids-01 Compose declarations against the actually running image tags/digests and classify drift, floating tags and unmanaged containers. For BAU/security work, restore and verify the Suricata 24-hour collection. The Docker/WUD BAU check remains in pending verification until the next scheduled scan completes with `0 errors`.

## Documentation

- [Jenkins Operations](jenkins/README.md) — Jenkins/DinD service ownership, image and security baselines, controlled delivery validation, Kubernetes reconciliation and recovery planning.
- [Grafana Alerting](service-overviews/grafana-alerting.md) — central alert evaluation and validated SMTP delivery through a Docker Compose secret.

- [Engineering Portfolio Deployment and Maintenance](engineering-portfolio-deployment.md) — guarded production deployment, readiness checks, Nginx Proxy Manager maintenance switching, persistent all-path maintenance fallback, validation evidence and version-control ownership.
- [Network Discovery Dashboard](network-discovery-dashboard.md) — LAN device discovery, persistent MAC inventory, friendly-name enrichment, Prometheus metrics, and automatic per-device Grafana dashboard creation.
- [Homelab Hardware Health Dashboard](hardware-health-dashboard.md) — Loki-backed kernel and hardware fault monitoring for storage, filesystem, CPU/memory/PCIe, thermal/panic events and raw evidence.
- [ASUS Router Monitoring](asus-router-monitoring.md) — confirmed router-health collector path on TestServer, systemd service ownership, Node Exporter textfile metrics, and retirement of the legacy `192.168.2.220:9106` scrape target.
- [Important Scripts](important-scripts.md) — operationally important scripts with an explicit Server / Host field, paths, purpose, inputs, outputs, and how each script is started.
- [Blocked MAC Monitoring](blocked-mac-monitoring.md) — reusable ASUS-router log watcher on ids-01, watched-MAC configuration, systemd timer, Prometheus metrics, Grafana alerting, and test procedure.
- [Grafana Alert Email Standard](grafana-alert-email-standard.md) — common homelab alert email subject/body format, reusable notification templates, and deployment procedure.
- [Daily Security & Recovery Reporting](service-overviews/daily-security-and-recovery-reporting.md) — report-generation chains, dual-Pi-hole evidence aggregation, recovery/Loki assurance and combined email behaviour.
- [ids-01 Service and Timer Inventory](service-overviews/ids-01-service-inventory.md) — active service ownership, schedules, retired duplicate collectors and validation commands.
- [Daily Homelab Actions](daily-actions/README.md) — dated operational follow-up notes, with each day stored in its own `YYYY-MM-DD` folder.

## Procedures

- [NPM API token creation and rotation](procedures/npm-api-token-rotation.md) — create a validated long-lived Nginx Proxy Manager API token and install it atomically into the protected TestServer environment.
- [NPM token SOPS synchronisation procedure](procedures/npm-token-sops-synchronisation.md) — safely synchronise the protected live Nginx Proxy Manager token into its encrypted TestServer recovery source.

## Operational assets

- [Scripts and deployment assets](scripts/README.md) — repository copies of the operational scripts, their runtime hosts and paths, supporting systemd units, config files, and Grafana alert deployment tooling.

## Secret recovery

- [SOPS and age service overview](service-overviews/sops-and-age-secret-recovery.md)
- [SOPS and age secret recovery how-to](sop/sops-age-secret-recovery-how-to.md)
