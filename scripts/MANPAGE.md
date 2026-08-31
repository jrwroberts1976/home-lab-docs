# Home Lab Script Manual

This page is the operator-facing **man page** for the scripts stored under `scripts/`.

It documents what each script does, how it is normally invoked, what it reads or changes, and the main dependencies or safety considerations. Repository paths are source-control locations; deployed runtime paths can differ.

## Safety legend

| Marker | Meaning |
| --- | --- |
| **READ-ONLY** | Inspects state and prints/collects evidence without intentionally changing the live service configuration. |
| **METRICS** | Writes Prometheus/node-exporter textfile metrics or local state used by monitoring. |
| **CONFIG CHANGE** | Changes live configuration, a scheduler, firewall rule, protected environment file, or Grafana provisioning/API state. |
| **BACKUP / RETENTION** | Creates backups/archives or applies retention/pruning. Read the side-effects section before running. |
| **EMAIL / SERVICE RUN** | Can trigger email delivery or start a service that generates/sends a report. |
| **SECRET-SENSITIVE** | Works with credentials, tokens, encrypted recovery material, or protected identities. It is designed not to print secrets, but should still be run from a trusted shell. |

## Quick index

| Script | Class | Purpose |
| --- | --- | --- |
| `crowdsec-activity-metrics.sh` | METRICS | Export 24-hour CrowdSec decision and kernel-block activity to Prometheus. |
| `deploy-blocked-mac-alert.sh` | CONFIG CHANGE | Create/update the Grafana blocked-MAC alert rule. |
| `deploy-grafana-email-standard.sh` | CONFIG CHANGE | Install the common Grafana email templates and apply them to email contact points. |
| `deploy-pihole-collector-stale-alert.sh` | CONFIG CHANGE | Create/update the Grafana stale Pi-hole collector alert. |
| `deploy-restic-alerts.sh` | CONFIG CHANGE | Create/update Restic server-down and stale-health Grafana alerts. |
| `diagnose-daily-security-report-generators.sh` | READ-ONLY | Build a diagnostic evidence bundle for security report generators. |
| `find-daily-brief-generators.sh` | READ-ONLY | Locate scripts, services, timers and mail paths that generate daily security/runbook reports. |
| `homelab-network-discovery.py` | METRICS | Discover LAN devices, maintain MAC inventory and export discovery metrics. |
| `host-recovery-inventory.sh` | READ-ONLY | Capture a host rebuild/recovery inventory and tar archive. |
| `host-recovery-scp-generate.sh` | READ-ONLY | Generate a Service Continuity Procedure from a recovery inventory bundle. |
| `inspect-engineering-security-runbook.sh` | READ-ONLY | Inspect the Greenbone engineering runbook generator, timers, report and journals. |
| `patch-engineering-runbook-interpretation.sh` | CONFIG CHANGE | Patch the live Greenbone AI review prompt with the security interpretation model. |
| `pihole-alert-diagnose.sh` | READ-ONLY | Query Prometheus to show active Pi-hole policy alert series and event ages. |
| `pihole-collector-flock-wrapper.sh` | CONFIG COMPONENT | Generic non-blocking flock wrapper for the Pi-hole query collector. |
| `pihole-grafana-trace.sh` | READ-ONLY | Trace a Pi-hole event through Prometheus and Grafana logs. |
| `pihole-ids01-collector-inspect.sh` | READ-ONLY | Inspect the `ids-01` Pi-hole collector timer, service, output and FTL DB. |
| `pihole-latency-test.sh` | TEST | Generate a blocked DNS query and measure DNS-to-Prometheus latency. |
| `pihole-notifier-inspect.sh` | READ-ONLY | Inspect Pi-hole Grafana routing/grouping and notifier logs. |
| `pihole-stage0-backup.sh` | BACKUP / RETENTION | Back up Grafana Pi-hole alert provisioning and capture the timing baseline. |
| `pihole-stage1-group-interval.sh` | CONFIG CHANGE | Guarded change of Pi-hole `group_interval` from `5m` to `30s`. |
| `pihole-stage2-group-by.sh` | CONFIG CHANGE | Guarded addition of route-local Pi-hole `group_by: ['...']`. |
| `pihole-stage3-flock-deploy.sh` | CONFIG CHANGE | Install the locked collector wrapper and redirect systemd/cron to it. |
| `pihole-stage3-flock-verify.sh` | TEST | Prove the Stage 3 single-instance collector protection works. |
| `pihole-stage4-flock-monitoring-deploy.sh` | CONFIG CHANGE / METRICS | Add collector-success and flock-skip monitoring to the Stage 3 wrapper. |
| `pihole-stage4-flock-monitoring-verify.sh` | TEST | Verify Stage 4 state and Prometheus metrics. |
| `prepare-npm-sops-recovery-validation.sh` | SECRET-SENSITIVE | Package the staged encrypted NPM recovery source and transfer it to DietPi for independent validation. |
| `resend-management-security-report.sh` | EMAIL / SERVICE RUN | Start the management security report service and verify the new report. |
| `restic-server-health.sh` | METRICS | Check the Restic REST server container/port/HTTPS health and export metrics. |
| `rotate-npm-api-token.sh` | CONFIG CHANGE / SECRET-SENSITIVE | Create, validate and atomically install a long-lived NPM API token. |
| `sync-npm-token-sops.sh` | CONFIG CHANGE / SECRET-SENSITIVE | Sync live NPM values into the SOPS recovery source in an isolated worktree and stage the encrypted file. |
| `watch-blocked-macs.py` | METRICS | Watch ASUS router logs for configured MACs and export last-seen metrics. |
| `dietpi/backup-dietpi.sh` | BACKUP / RETENTION / METRICS | Snapshot Pi-hole databases, run Restic backup and export backup metrics. |
| `dietpi/collect-patch-status.sh` | METRICS | Refresh APT metadata and export patch/reboot/automatic-update status. |
| `dietpi/collect-vulnerabilities.py` | METRICS | Run a Trivy OS rootfs scan and export vulnerability metrics. |
| `dietpi/export-pihole-security-events` | READ-ONLY | Export the last 24 hours of selected Pi-hole policy-category events to TSV. |
| `dietpi/homelab-block-icmp-timestamp` | CONFIG CHANGE | Idempotently insert an iptables rule dropping ICMP timestamp requests. |
| `dietpi/homelab-monthly-archive` | BACKUP / RETENTION | Copy the `ids-01` replica into a dated monthly archive with `rsync --delete`. |
| `dietpi/homelab-monthly-retention` | READ-ONLY | Report monthly/yearly archives that would be removed by retention; currently deletes nothing. |
| `dietpi/homelab-software-metrics` | METRICS | Export a curated software/version/update/service-state inventory. |
| `dietpi/pihole-block-alert/alert_service.py` | EMAIL / SERVICE RUN | Tail Pi-hole logs, record blocks, classify selected categories and send grouped email alerts. |
| `dietpi/pihole-blocklist-metrics.sh` | METRICS / TEST | Export blocklist health plus active DNS blocking tests. |
| `dietpi/pihole-query-metrics-locked.sh` | METRICS / CONFIG COMPONENT | DietPi-installed flock wrapper with collector success/skip metrics. |
| `dietpi/pihole-query-metrics.sh` | METRICS | Export blocked-query, client, domain and policy-category metrics from Pi-hole DBs. |
| `dietpi/pihole-update-metrics` | METRICS | Run the Pi-hole update checker and export component update status. |
| `dietpi/restic-backup-dietpi` | BACKUP / RETENTION | Back up core DietPi paths, then run Restic forget/prune retention. |
| `dietpi/validate-npm-sops-recovery-identity.sh` | SECRET-SENSITIVE | Decrypt and verify the transferred NPM source using the protected DietPi recovery identity. |

---

# Top-level scripts

## `crowdsec-activity-metrics.sh`

### NAME
`crowdsec-activity-metrics.sh` — export recent CrowdSec activity as node-exporter textfile metrics.

### SYNOPSIS
```bash
./scripts/crowdsec-activity-metrics.sh
```

### DESCRIPTION
Runs `cscli alerts list --since 24h -o json` inside the `crowdsec` container, counts unique IP decisions, examines the kernel journal for `crowdsec:` block entries, and writes the resulting metrics atomically to `crowdsec_activity.prom`.

### SIDE EFFECTS
**METRICS.** Creates/updates `/home/james/docker/data/monitoring/node-exporter/textfile/crowdsec_activity.prom`. Does not change CrowdSec policy.

### REQUIREMENTS
Docker, the `crowdsec` container, `jq`, `journalctl`, and access to the node-exporter textfile directory.

---

## `deploy-blocked-mac-alert.sh`

### NAME
`deploy-blocked-mac-alert.sh` — deploy the Grafana `blocked_mac_detected` alert rule.

### SYNOPSIS
```bash
GRAFANA_TOKEN=... ./scripts/deploy-blocked-mac-alert.sh
```
Optional: `GRAFANA_URL`, default `http://localhost:3001`.

### DESCRIPTION
Checks whether the alert rule already exists, then POSTs or PUTs the rule through the Grafana provisioning API. The rule fires when a watched MAC has been seen in the previous five minutes.

### SIDE EFFECTS
**CONFIG CHANGE.** Creates or updates a live Grafana alert rule.

### REQUIREMENTS
`GRAFANA_TOKEN`, `curl`, `jq`, Grafana provisioning API access, and the expected Prometheus datasource UID.

---

## `deploy-grafana-email-standard.sh`

### NAME
`deploy-grafana-email-standard.sh` — install the standard homelab Grafana email format.

### SYNOPSIS
```bash
GRAFANA_TOKEN=... ./scripts/deploy-grafana-email-standard.sh
```
Optional: `GRAFANA_URL`, default `http://localhost:3001`.

### DESCRIPTION
Creates/updates the `homelab-email` notification-template group and updates every Grafana contact point of type `email` to use the standard subject and message templates.

### SIDE EFFECTS
**CONFIG CHANGE.** Changes Grafana notification templates and email contact-point settings. It does not send a test email itself.

### REQUIREMENTS
`GRAFANA_TOKEN`, `curl`, `jq`, and Grafana provisioning API access.

---

## `deploy-pihole-collector-stale-alert.sh`

### NAME
`deploy-pihole-collector-stale-alert.sh` — deploy the stale Pi-hole query-collector alert.

### SYNOPSIS
```bash
GRAFANA_TOKEN=... ./scripts/deploy-pihole-collector-stale-alert.sh
```
Optional: `GRAFANA_URL`, `PROM_DS_UID`.

### DESCRIPTION
Creates or updates the `pihole_collector_stale` Grafana rule. It alerts when `homelab_pihole_collector_last_success_timestamp_seconds` is more than five minutes old, with a two-minute `for` period. Individual flock skips are intentionally diagnostic rather than alert conditions.

### SIDE EFFECTS
**CONFIG CHANGE.** Creates or updates a Grafana alert rule.

### REQUIREMENTS
`GRAFANA_TOKEN`, `curl`, `jq`, Grafana API access and the Stage 4 collector metrics.

---

## `deploy-restic-alerts.sh`

### NAME
`deploy-restic-alerts.sh` — deploy Restic server-health Grafana alerts.

### SYNOPSIS
```bash
GRAFANA_TOKEN=... ./scripts/deploy-restic-alerts.sh
```

### DESCRIPTION
Creates/updates two Grafana rules: `Restic Server Down` when the overall health metric is zero, and `Restic Health Check Stale` when the health collector has not updated for more than five minutes.

### SIDE EFFECTS
**CONFIG CHANGE.** Creates or updates live Grafana alert rules.

### REQUIREMENTS
`GRAFANA_TOKEN`, `curl`, `jq`, Grafana API access, Prometheus and `restic-server-health.sh` metrics.

---

## `diagnose-daily-security-report-generators.sh`

### NAME
`diagnose-daily-security-report-generators.sh` — collect a safe diagnostic bundle for the daily security/report-generation chain.

### SYNOPSIS
```bash
./scripts/diagnose-daily-security-report-generators.sh [output-directory]
```

### DESCRIPTION
Copies report-generator source files where present, records hashes/permissions, captures relevant systemd units/timers, recent journals, report products, Python syntax checks and a filename-only secret/config inventory. It creates a manifest and a `.tar.gz` evidence bundle.

### SIDE EFFECTS
**READ-ONLY** with respect to services/configuration. It creates local diagnostic files and an archive. Secret contents are deliberately excluded.

### REQUIREMENTS
Permission to read the inspected files and journals; some evidence may require root privileges.

---

## `find-daily-brief-generators.sh`

### NAME
`find-daily-brief-generators.sh` — discover the generators and schedules behind the daily security/recovery reports.

### SYNOPSIS
```bash
./scripts/find-daily-brief-generators.sh [output-directory]
```

### DESCRIPTION
Searches expected script/project/system locations for known report titles, security/report keywords, mail-sending commands and evidence-source references. It also captures relevant systemd timers/unit files and cron entries.

### SIDE EFFECTS
**READ-ONLY.** Creates a discovery-output directory containing text evidence.

### REQUIREMENTS
`sudo` for protected searches, `grep`, systemd tools and access to the expected home/project paths.

---

## `homelab-network-discovery.py`

### NAME
`homelab-network-discovery.py` — maintain a MAC-based LAN device inventory and Prometheus discovery metrics.

### SYNOPSIS
```bash
python3 scripts/homelab-network-discovery.py
```

### DESCRIPTION
Runs an ARP-style `nmap` scan of `192.168.2.0/24` on `wlo1`, enriches devices with ASUS router custom-client/DHCP names over SSH, persists first/last-seen state, marks newly discovered devices and exports node-exporter metrics. New non-baseline MACs are also written to syslog with `NEW_NETWORK_DEVICE`.

### SIDE EFFECTS
**METRICS.** Updates `/var/lib/homelab-network-discovery/devices.json` and `/var/lib/prometheus/node-exporter/homelab_network_discovery.prom`; logs new-device events. It actively scans the LAN but does not configure devices.

### REQUIREMENTS
Python 3, `nmap`, SSH access/key for the ASUS router, writable state/metric paths and the configured `wlo1`/`192.168.2.0/24` network assumptions.

---

## `host-recovery-inventory.sh`

### NAME
`host-recovery-inventory.sh` — capture the configuration evidence needed to rebuild a host.

### SYNOPSIS
```bash
./scripts/host-recovery-inventory.sh
OUTPUT_DIR=/safe/path ./scripts/host-recovery-inventory.sh
```

### DESCRIPTION
Collects OS, hardware, packages, users/groups, network, firewall, systemd, cron, Docker, Kubernetes, monitoring/security, Git, backup and restore-path evidence. Secret **paths and metadata** are inventoried, but secret contents are intentionally excluded. A recovery README, SHA-256 manifest and `.tar.gz` archive are produced.

### SIDE EFFECTS
**READ-ONLY** against host configuration. Creates a potentially sensitive inventory bundle containing configuration evidence, so store it appropriately.

### REQUIREMENTS
Run with enough privilege to read the intended host configuration. Optional sections depend on Docker, Kubernetes/k3s, nftables/iptables and other installed tooling.

---

## `host-recovery-scp-generate.sh`

### NAME
`host-recovery-scp-generate.sh` — generate a Service Continuity Procedure from a host recovery inventory.

### SYNOPSIS
```bash
./scripts/host-recovery-scp-generate.sh /path/to/host-recovery-<host>-<timestamp> [output-file]
```

### DESCRIPTION
Reads the inventory bundle, summarises the captured platform and generates a recovery runbook covering OS rebuild, network, users, packages, systemd/cron, containers, Kubernetes, data, secrets, Git, monitoring and validation.

### SIDE EFFECTS
**READ-ONLY** with respect to the recovered host. Writes a Markdown SCP, defaulting to `scp/SCP-Host-Recovery-<host>.md` in the repository.

### REQUIREMENTS
A directory previously created by `host-recovery-inventory.sh`.

---

## `inspect-engineering-security-runbook.sh`

### NAME
`inspect-engineering-security-runbook.sh` — inspect the live Greenbone engineering-security runbook generation chain.

### SYNOPSIS
```bash
sudo ./scripts/inspect-engineering-security-runbook.sh
```

### DESCRIPTION
Prints relevant timers, service files, runner/generator source, AI-review Python code, the latest engineering report and recent journals for the Greenbone AI review and engineering email services.

### SIDE EFFECTS
**READ-ONLY.** No service is restarted or changed.

### REQUIREMENTS
Root privileges and the expected Greenbone/report paths on the security host.

---

## `patch-engineering-runbook-interpretation.sh`

### NAME
`patch-engineering-runbook-interpretation.sh` — patch the live Greenbone AI review generator with the security interpretation model.

### SYNOPSIS
```bash
./scripts/patch-engineering-runbook-interpretation.sh
```

### DESCRIPTION
Backs up `/usr/local/lib/homelab-greenbone/ai_review.py`, inserts a classification/interpretation block into the confirmed AI instructions section, refuses to patch twice or patch an unexpected file layout, then performs a Python compile check.

### SIDE EFFECTS
**CONFIG CHANGE.** Modifies live generator source under `/usr/local/lib/homelab-greenbone/`. A timestamped backup is created first.

### REQUIREMENTS
`sudo`, Python 3, and the expected live generator structure.

---

## `pihole-alert-diagnose.sh`

### NAME
`pihole-alert-diagnose.sh` — show which Pi-hole policy-category metric series can currently satisfy the Grafana alert lookback.

### SYNOPSIS
```bash
./scripts/pihole-alert-diagnose.sh
PROM_URL=http://localhost:9090 LOOKBACK=300 ./scripts/pihole-alert-diagnose.sh
```

### DESCRIPTION
Queries Prometheus for active `pihole_blocked_client_category_last_event_timestamp_seconds` series, counts them by host/category and reports newest-event ages. Useful for explaining grouped firing/resolved notifications.

### SIDE EFFECTS
**READ-ONLY.** Prometheus query only.

### REQUIREMENTS
`curl`, Python 3 and Prometheus API access.

---

## `pihole-collector-flock-wrapper.sh`

### NAME
`pihole-collector-flock-wrapper.sh` — generic non-blocking single-instance wrapper for the Pi-hole query collector.

### SYNOPSIS
```bash
COLLECTOR=/usr/local/bin/pihole-query-metrics.sh \
LOCKFILE=/run/lock/pihole-query-metrics.lock \
./scripts/pihole-collector-flock-wrapper.sh [collector-args...]
```

### DESCRIPTION
Runs the configured collector under `flock -n`. If another instance already owns the lock, it logs a skip and exits cleanly instead of stacking collector processes.

### SIDE EFFECTS
**CONFIG COMPONENT.** By itself it only runs/wraps the collector. The scheduler must be explicitly pointed at it before it becomes part of production.

### REQUIREMENTS
`flock`, an executable collector and permission to create the lock file.

---

## `pihole-grafana-trace.sh`

### NAME
`pihole-grafana-trace.sh` — trace a Pi-hole latency test through Prometheus and Grafana.

### SYNOPSIS
```bash
./scripts/pihole-grafana-trace.sh [YYYY-MM-DDTHH:MM:SS]
```
Optional: `GRAFANA_CONTAINER`, `PROMETHEUS`.

### DESCRIPTION
Shows the Grafana container, current Pi-hole policy metrics, and relevant Grafana state/notifier/email/error logs since the supplied timestamp.

### SIDE EFFECTS
**READ-ONLY.** Does not restart or modify Grafana.

### REQUIREMENTS
Docker, `curl`, Python 3 and access to Prometheus/Grafana logs.

---

## `pihole-ids01-collector-inspect.sh`

### NAME
`pihole-ids01-collector-inspect.sh` — inspect the `ids-01` Pi-hole query collector end to end.

### SYNOPSIS
```bash
./scripts/pihole-ids01-collector-inspect.sh
```
Optional environment overrides: `SERVICE`, `TIMER`, `DB`, `TEXTFILE_DIR`, `COLLECTOR`.

### DESCRIPTION
Prints the systemd timer/service definitions and status, collector source, recent logs/processes, candidate Prometheus textfiles and recent FTL database rows. It is aimed at distinguishing true event timestamps from collector-refresh artifacts.

### SIDE EFFECTS
**READ-ONLY.** No Grafana, scheduler or collector change is made.

### REQUIREMENTS
systemd tools; `sqlite3` is used when available; read access to the secondary Pi-hole database and textfile directory.

---

## `pihole-latency-test.sh`

### NAME
`pihole-latency-test.sh` — generate a controlled blocked DNS query and measure when its metric becomes visible in Prometheus.

### SYNOPSIS
```bash
CLIENT=<source-ip> ./scripts/pihole-latency-test.sh dietpi [domain]
CLIENT=<source-ip> ./scripts/pihole-latency-test.sh ids-01 [domain]
```
Optional: `PROM_URL`, `OUT_DIR`, `CATEGORY`, `POLL_SECONDS`, `TIMEOUT_SECONDS`.

### DESCRIPTION
Captures the previous metric value, sends an `nslookup` to the selected Pi-hole, polls Prometheus for a new matching policy-category event and writes detailed text/CSV timing evidence. Email receipt time is recorded manually afterward to calculate full end-to-end latency.

### SIDE EFFECTS
**TEST.** Deliberately generates a DNS request expected to be blocked and therefore can trigger the normal alerting path. Writes result files under `~/pihole-latency-tests` by default.

### REQUIREMENTS
`nslookup`, `curl`, Python 3, Prometheus API access and the correct `CLIENT` label/source IP for the test host.

---

## `pihole-notifier-inspect.sh`

### NAME
`pihole-notifier-inspect.sh` — inspect Pi-hole Grafana notification routing, grouping and notifier activity.

### SYNOPSIS
```bash
./scripts/pihole-notifier-inspect.sh [YYYY-MM-DDTHH:MM:SS]
```
Optional: `GRAFANA_CONTAINER`, `GRAFANA_PROVISIONING`.

### DESCRIPTION
Prints the provisioned Pi-hole notification policy and alert rule, highlights grouping/timing and labels, then searches Grafana logs for state, notifier, SMTP and error activity.

### SIDE EFFECTS
**READ-ONLY.** No Grafana restart or configuration change.

### REQUIREMENTS
Read access to Grafana provisioning files and Docker logs.

---

## `pihole-stage0-backup.sh`

### NAME
`pihole-stage0-backup.sh` — create the pre-change Pi-hole Grafana timing baseline and backup.

### SYNOPSIS
```bash
sudo ./scripts/pihole-stage0-backup.sh
```
Optional: `ALERT_DIR`, `POLICY`, `RULES`, `BACKUP_DIR`.

### DESCRIPTION
Copies the Pi-hole notification-policy and alert-rule provisioning files into a timestamped backup directory, records relevant timing/lookback lines and SHA-256 hashes, and prints the expected pre-Stage-1 values.

### SIDE EFFECTS
**BACKUP / RETENTION.** Creates files only; does not alter Grafana configuration.

### REQUIREMENTS
Read/write access to the Grafana alert provisioning and backup directories.

---

## `pihole-stage1-group-interval.sh`

### NAME
`pihole-stage1-group-interval.sh` — guarded change of only the Pi-hole policy-category `group_interval`.

### SYNOPSIS
```bash
./scripts/pihole-stage1-group-interval.sh --dry-run
sudo ./scripts/pihole-stage1-group-interval.sh --apply
```

### DESCRIPTION
Locates exactly one Pi-hole policy-category route, accepts only an existing `5m` or `30s` value, proposes `30s`, shows the diff, and on `--apply` makes a timestamped backup before writing the file.

### SIDE EFFECTS
**CONFIG CHANGE** in `--apply` mode. It deliberately does **not** restart Grafana.

### REQUIREMENTS
Python 3 and appropriate permissions on the provisioning file.

---

## `pihole-stage2-group-by.sh`

### NAME
`pihole-stage2-group-by.sh` — add route-local Pi-hole notification grouping that preserves individual alert instances.

### SYNOPSIS
```bash
./scripts/pihole-stage2-group-by.sh --dry-run
sudo ./scripts/pihole-stage2-group-by.sh --apply
```

### DESCRIPTION
Finds the Pi-hole policy-category route and adds exactly:
```yaml
group_by:
  - '...'
```
It refuses to continue if `group_by` already exists or if the diff contains anything other than those two added lines.

### SIDE EFFECTS
**CONFIG CHANGE** in `--apply` mode. Creates a backup and does **not** restart Grafana.

### REQUIREMENTS
Python 3 and root for `--apply`.

---

## `pihole-stage3-flock-deploy.sh`

### NAME
`pihole-stage3-flock-deploy.sh` — install Pi-hole collector single-instance protection and redirect the existing scheduler.

### SYNOPSIS
```bash
sudo ./scripts/pihole-stage3-flock-deploy.sh ids01
sudo ./scripts/pihole-stage3-flock-deploy.sh dietpi
```

### DESCRIPTION
Installs `/usr/local/bin/pihole-query-metrics-locked.sh` without modifying the underlying collector. On `ids01` it adds a systemd service drop-in; on `dietpi` it rewrites exactly one matching root cron entry. It backs up the existing scheduling configuration first.

### SIDE EFFECTS
**CONFIG CHANGE.** Changes the live scheduler target and can immediately execute/start the collector. The original collector source is left unchanged.

### REQUIREMENTS
Root, `flock`, the existing collector and the expected systemd or root-cron layout.

---

## `pihole-stage3-flock-verify.sh`

### NAME
`pihole-stage3-flock-verify.sh` — verify Stage 3 collector locking on either Pi-hole host.

### SYNOPSIS
```bash
sudo ./scripts/pihole-stage3-flock-verify.sh ids01
sudo ./scripts/pihole-stage3-flock-verify.sh dietpi
```

### DESCRIPTION
Checks collector/wrapper installation and scheduler wiring, runs the wrapper, deliberately holds the lock to prove a second start skips cleanly, checks for stacked processes and reports PASS/FAIL.

### SIDE EFFECTS
**TEST.** Executes the collector and performs a controlled held-lock test. Does not change scheduler configuration.

### REQUIREMENTS
Root and a completed Stage 3 deployment.

---

## `pihole-stage4-flock-monitoring-deploy.sh`

### NAME
`pihole-stage4-flock-monitoring-deploy.sh` — add monitoring state and Prometheus metrics to the Stage 3 locked collector wrapper.

### SYNOPSIS
```bash
sudo ./scripts/pihole-stage4-flock-monitoring-deploy.sh
```

### DESCRIPTION
Detects the actual node-exporter textfile directory rather than guessing, backs up the installed Stage 3 wrapper, replaces it with a monitored wrapper and exports last-success timestamp, lock-skip counter and last-run-success metrics. It seeds the metrics with a normal collector run.

### SIDE EFFECTS
**CONFIG CHANGE / METRICS.** Replaces the installed wrapper, creates `/var/lib/pihole-collector-monitor` state, writes a `.prom` file and executes the collector once.

### REQUIREMENTS
Root, `flock`, an installed Stage 3 wrapper, node-exporter configured with a textfile collector, and the listed standard shell utilities.

---

## `pihole-stage4-flock-monitoring-verify.sh`

### NAME
`pihole-stage4-flock-monitoring-verify.sh` — verify the Stage 4 monitored collector wrapper and exported metrics.

### SYNOPSIS
```bash
sudo ./scripts/pihole-stage4-flock-monitoring-verify.sh
```

### DESCRIPTION
Validates the wrapper/state/metrics files, deliberately increments the lock-skip counter under a held lock, performs a normal collector run, checks timestamp freshness and checks node-exporter exposure on port 9100 when available.

### SIDE EFFECTS
**TEST.** Increments the diagnostic lock-skip counter and runs the collector normally once.

### REQUIREMENTS
Root and a completed Stage 4 deployment.

---

## `prepare-npm-sops-recovery-validation.sh`

### NAME
`prepare-npm-sops-recovery-validation.sh` — transfer an independently verifiable NPM SOPS recovery package to DietPi.

### SYNOPSIS
```bash
./scripts/prepare-npm-sops-recovery-validation.sh
```
Optional overrides include `WORKTREE`, `LIVE_ENV`, `REMOTE`, `REMOTE_ARCHIVE`, `EXPECTED_HOST`.

### DESCRIPTION
On `TestServer`, verifies that the isolated worktree contains only the staged encrypted NPM source, creates a one-way checksum of the protected live NPM variables, builds a tightly allowlisted tar file, transfers it to DietPi with `scp`, then removes the local temporary archive.

### SIDE EFFECTS
**SECRET-SENSITIVE.** Transfers an encrypted validation package and checksum. It deliberately does not commit, push, deploy, restart or display credentials.

### REQUIREMENTS
Expected TestServer worktree/staging state, protected live NPM env file, Git and SSH/SCP access to DietPi.

---

## `resend-management-security-report.sh`

### NAME
`resend-management-security-report.sh` — regenerate and resend the management security report through its systemd service.

### SYNOPSIS
```bash
sudo ./scripts/resend-management-security-report.sh
```

### DESCRIPTION
Shows the current management report, starts `homelab-secops-management-report.service`, prints service status and recent journal output, then verifies that `latest.md` exists.

### SIDE EFFECTS
**EMAIL / SERVICE RUN.** Starts the report service; that service is expected to generate and send the management report.

### REQUIREMENTS
Root, the report service and `/var/lib/homelab-secops-report/management`.

---

## `restic-server-health.sh`

### NAME
`restic-server-health.sh` — export health of the Restic REST server on `ids-01`.

### SYNOPSIS
```bash
./scripts/restic-server-health.sh
```
Optional: `RESTIC_CONTAINER`, `RESTIC_HOST_IP`, `RESTIC_PORT`, `RESTIC_URL`, `RESTIC_CACERT`, `NODE_EXPORTER_TEXTFILE_DIR`.

### DESCRIPTION
Checks that the Restic container is running, port 8000 is published, the TCP listener exists and the HTTPS endpoint responds with an expected healthy status (`200`, `401` or `403`). Exports component and overall health metrics.

### SIDE EFFECTS
**METRICS.** Writes `homelab_restic_server_health.prom`; no Restic configuration is changed.

### REQUIREMENTS
Docker, `ss`, `curl` and access to the node-exporter textfile directory.

---

## `rotate-npm-api-token.sh`

### NAME
`rotate-npm-api-token.sh` — rotate the protected Nginx Proxy Manager API token safely.

### SYNOPSIS
```bash
./scripts/rotate-npm-api-token.sh
```
The script interactively prompts on `/dev/tty` for the NPM login email and password.

### DESCRIPTION
Runs only on the expected `TestServer`, creates a temporary login token through the NPM container network, exchanges it for a long-lived token, validates that token against the configured proxy-host ID, atomically replaces only `NPM_TOKEN` in the protected env file, then validates the installed token. If final validation fails, the previous file is restored.

### SIDE EFFECTS
**CONFIG CHANGE / SECRET-SENSITIVE.** Updates `/home/james/docker/secrets/npm.env` (or `NPM_ENV`) with a validated token. It does not change a proxy host, container or service and does not print the credentials/token.

### REQUIREMENTS
Expected TestServer host, running `npm` container, Docker, `jq`, protected NPM env file and valid NPM login credentials.

---

## `sync-npm-token-sops.sh`

### NAME
`sync-npm-token-sops.sh` — synchronise the live NPM environment values into the encrypted SOPS recovery source.

### SYNOPSIS
```bash
./scripts/sync-npm-token-sops.sh
```

### DESCRIPTION
Requires the source repository to match `origin/main`, creates an isolated branch/worktree, decrypts the existing SOPS dotenv with the operational age identity, replaces only the three NPM values from the live protected env file, re-encrypts, verifies exact equality after decryption, checks that no private identity material entered the worktree and stages only the encrypted recovery file.

### SIDE EFFECTS
**CONFIG CHANGE / SECRET-SENSITIVE.** Creates an isolated Git worktree/branch and stages the encrypted file. It deliberately does **not** commit or push.

### REQUIREMENTS
TestServer, Git, `sops`, the operational age identity, the live protected NPM env file and a clean/synchronised `/home/james/docker` repository.

---

## `watch-blocked-macs.py`

### NAME
`watch-blocked-macs.py` — detect configured watched MAC addresses in the ASUS router log and export monitoring state.

### SYNOPSIS
```bash
python3 scripts/watch-blocked-macs.py
```

### DESCRIPTION
Reads `/etc/homelab/blocked-macs.txt`, SSHes to the ASUS router and searches `/tmp/syslog.log` for those MACs. New router-log entries are classified (DHCP/association/authentication events), written to syslog as `WATCHED_MAC_DETECTED`, persisted in state and exported through a last-seen Prometheus metric.

### SIDE EFFECTS
**METRICS.** Updates watcher state and `/var/lib/prometheus/node-exporter/watched_macs.prom`; logs detections. It does not add/remove router MAC filtering rules.

### REQUIREMENTS
Python 3, the blocked-MAC config file, ASUS SSH key/access and writable state/metric paths.

---

# DietPi scripts

## `dietpi/backup-dietpi.sh`

### NAME
`backup-dietpi.sh` — perform the monitored DietPi Restic backup with safe Pi-hole database snapshots.

### SYNOPSIS
```bash
sudo /path/to/backup-dietpi.sh
```

### DESCRIPTION
Loads the Restic REST-server environment, creates SQLite `.backup` copies of `gravity.db` and `pihole-FTL.db` in a staging directory, runs integrity checks, then executes Restic using configured include/exclude files and tags. It logs the run and writes success, timing and snapshot metrics.

### SIDE EFFECTS
**BACKUP / RETENTION / METRICS.** Creates staging DB snapshots, writes to the Restic repository and updates the DietPi backup metric file. This script itself does not run `restic forget`/prune.

### REQUIREMENTS
Restic credentials/certificate files, `sqlite3`, reachable Restic REST server, include/exclude files and the expected backup/metric directories.

---

## `dietpi/collect-patch-status.sh`

### NAME
`collect-patch-status.sh` — export DietPi patch/update/reboot automation status.

### SYNOPSIS
```bash
./scripts/dietpi/collect-patch-status.sh
```

### DESCRIPTION
Runs `sudo apt-get update -qq`, counts all and security-related upgradable packages, checks `/var/run/reboot-required`, reads DietPi's automatic APT-update mode and cron activity, preserves a last-success timestamp and writes Prometheus metrics.

### SIDE EFFECTS
**METRICS.** Refreshes APT package metadata and writes `patch_status.prom`. It does not install upgrades.

### REQUIREMENTS
APT, `sudo` permission for `apt-get update`, DietPi configuration and the node-exporter textfile path.

---

## `dietpi/collect-vulnerabilities.py`

### NAME
`collect-vulnerabilities.py` — scan the DietPi OS root filesystem with Trivy and export vulnerability metrics.

### SYNOPSIS
```bash
python3 scripts/dietpi/collect-vulnerabilities.py \
  --output-dir /var/lib/prometheus/node-exporter \
  [--output-name vulnerability_status.prom]
```

### DESCRIPTION
Runs `trivy rootfs` for OS-package vulnerabilities, counts findings by severity/fixability, exports selected CRITICAL/HIGH actionable detail labels, separately records unfixed CRITICAL findings and records scan success/timestamp. A failed scan writes a failure metric.

### SIDE EFFECTS
**METRICS.** Performs a local filesystem vulnerability scan and atomically writes a Prometheus textfile; it does not patch packages.

### REQUIREMENTS
Python 3 and `/usr/local/bin/trivy`; the requested output directory must be writable.

---

## `dietpi/export-pihole-security-events`

### NAME
`export-pihole-security-events` — export selected Pi-hole security-policy events from the previous 24 hours.

### SYNOPSIS
```bash
./scripts/dietpi/export-pihole-security-events
```

### DESCRIPTION
Queries `pihole-FTL.db` for blocked queries associated with the configured NSFW, Gambling, DoH/VPN/Tor/Proxy Bypass and Threat Intelligence list IDs, groups them by client/domain/list and writes a tab-separated report.

### SIDE EFFECTS
**READ-ONLY** against Pi-hole. Atomically updates `/var/lib/homelab-secops/pihole-security-events.tsv`.

### REQUIREMENTS
Readable Pi-hole FTL DB, `pihole-FTL sqlite3` and a writable secops output directory.

---

## `dietpi/homelab-block-icmp-timestamp`

### NAME
`homelab-block-icmp-timestamp` — drop inbound ICMP timestamp requests.

### SYNOPSIS
```bash
sudo ./scripts/dietpi/homelab-block-icmp-timestamp
```

### DESCRIPTION
Checks whether the iptables INPUT rule already exists; if not, inserts a DROP rule for ICMP `timestamp-request` at the top of INPUT.

### SIDE EFFECTS
**CONFIG CHANGE.** Changes the live IPv4 firewall. The operation is idempotent for the exact rule, but persistence across reboot depends on the host's firewall persistence setup.

### REQUIREMENTS
Root and `iptables`.

---

## `dietpi/homelab-monthly-archive`

### NAME
`homelab-monthly-archive` — create a dated monthly archive from the `ids-01` replica.

### SYNOPSIS
```bash
./scripts/dietpi/homelab-monthly-archive
```

### DESCRIPTION
Checks the remote replica over SSH, creates `/mnt/backup/monthly/YYYY-MM-DD/ids-01`, and synchronises the remote `ids-01` replica into it with `rsync -aHAX --delete`. Progress is appended to the monthly archive log.

### SIDE EFFECTS
**BACKUP / RETENTION.** `rsync --delete` can remove files **inside the selected destination archive** that are absent from the source. Verify `SOURCE` and `DEST` before changing this script or running it in a modified environment.

### REQUIREMENTS
Mounted `/mnt/backup`, SSH key access to `192.168.2.195`, `rsync`, SSH and the expected replica path.

---

## `dietpi/homelab-monthly-retention`

### NAME
`homelab-monthly-retention` — report archive candidates under the monthly/yearly retention policy.

### SYNOPSIS
```bash
./scripts/dietpi/homelab-monthly-retention
```

### DESCRIPTION
Lists monthly archives and prints which monthly directories are older than 365 days and which yearly directories are older than 1825 days.

### SIDE EFFECTS
**READ-ONLY.** Despite its name, the current script performs **no deletion**. It only appends the retention assessment to `/mnt/backup/reports/retention.log`.

### REQUIREMENTS
Readable `/mnt/backup/monthly` and `/mnt/backup/yearly` directories and a writable reports directory.

---

## `dietpi/homelab-software-metrics`

### NAME
`homelab-software-metrics` — export a curated, low-cardinality software inventory for Grafana/Prometheus.

### SYNOPSIS
```bash
./scripts/dietpi/homelab-software-metrics
SOFTWARE_METRIC_DIR=/path ./scripts/dietpi/homelab-software-metrics
```

### DESCRIPTION
Collects OS/kernel/architecture, installed/manual package counts, curated APT package versions/candidates/service states, detected manually installed tools and Pi-hole component versions. It avoids reporting removed residual-config packages as installed updates.

### SIDE EFFECTS
**METRICS.** Atomically writes `homelab_software.prom`; does not install/update software.

### REQUIREMENTS
Writable metric directory and whichever package/tool commands correspond to software present on the host.

---

## `dietpi/pihole-block-alert/alert_service.py`

### NAME
`alert_service.py` — long-running Pi-hole block-event recorder and category email notifier.

### SYNOPSIS
```bash
SMTP_HOST=... SMTP_PORT=... SMTP_USERNAME=... SMTP_PASSWORD=... \
EMAIL_FROM=... EMAIL_TO=... \
python3 scripts/dietpi/pihole-block-alert/alert_service.py
```

### DESCRIPTION
Tails `/var/log/pihole/pihole.log`, correlates DNS query and block lines, records events in `/var/lib/pihole-block-alert/events.db`, looks up the blocking-list category in `gravity.db`, groups repeated client/domain attempts into a 60-second email window and sends TLS-authenticated SMTP alerts for configured adult/gambling/bypass/threat categories. Failed email attempts are retried after five minutes.

### SIDE EFFECTS
**EMAIL / SERVICE RUN.** Writes/updates the SQLite event database and can send email alerts. It does not change Pi-hole blocking rules.

### REQUIREMENTS
Python 3, readable Pi-hole log and gravity DB, writable state DB path, and the six required SMTP/email environment variables.

---

## `dietpi/pihole-blocklist-metrics.sh`

### NAME
`pihole-blocklist-metrics.sh` — export Pi-hole list health and verify live DNS blocking by category.

### SYNOPSIS
```bash
./scripts/dietpi/pihole-blocklist-metrics.sh
```

### DESCRIPTION
Reads `gravity.db` for enabled/failed list counts and domain totals, then performs five local DNS tests covering general, adult, gambling, bypass and threat categories. Exports overall health, enforcement health and per-list metrics.

### SIDE EFFECTS
**METRICS / TEST.** Generates local DNS queries to known test domains and writes `pihole_blocklists.prom`. It does not change adlists.

### REQUIREMENTS
Pi-hole/FTL SQLite access, `dig`, `bc` and the node-exporter textfile directory.

---

## `dietpi/pihole-query-metrics-locked.sh`

### NAME
`pihole-query-metrics-locked.sh` — DietPi installed single-instance wrapper plus collector-health metrics.

### SYNOPSIS
```bash
/usr/local/bin/pihole-query-metrics-locked.sh [collector-args...]
```

### DESCRIPTION
Uses a non-blocking flock to prevent overlapping query-collector runs. A lock skip increments a persisted counter and exits cleanly. A normal collector run records last success and last-run success state, then writes `pihole_collector_flock.prom`.

### SIDE EFFECTS
**METRICS / CONFIG COMPONENT.** Runs the underlying collector, updates local state and metrics, and logs lock skips.

### REQUIREMENTS
`flock`, executable `/usr/local/bin/pihole-query-metrics.sh`, writable `/var/lib/pihole-collector-monitor` and node-exporter textfile paths.

---

## `dietpi/pihole-query-metrics.sh`

### NAME
`pihole-query-metrics.sh` — export Pi-hole blocked-query and policy-category history from SQLite.

### SYNOPSIS
```bash
./scripts/dietpi/pihole-query-metrics.sh
```

### DESCRIPTION
Queries the FTL DB for total/7-day blocked counts, top blocked domains, per-client counts and last-seen times. It joins the query DB to `/var/lib/pihole-category-cache.db` to export adult/gambling/threat/bypass counts and true latest event timestamps including domain labels.

### SIDE EFFECTS
**METRICS.** Writes `/var/lib/prometheus/node-exporter/pihole_queries.prom`; does not modify Pi-hole databases. The final file ownership/move uses `sudo`.

### REQUIREMENTS
`sqlite3`, category cache DB, readable Pi-hole FTL DB and sudo rights to install the metric file.

---

## `dietpi/pihole-update-metrics`

### NAME
`pihole-update-metrics` — export update availability for Pi-hole Core, Web and FTL.

### SYNOPSIS
```bash
./scripts/dietpi/pihole-update-metrics
```

### DESCRIPTION
Runs `pihole updatechecker`, reads `/etc/pihole/versions`, compares installed and GitHub/latest versions for Core/Web/FTL and exports update-available, checker-success and timestamp metrics.

### SIDE EFFECTS
**METRICS.** Performs the Pi-hole update check and writes `pihole_updates.prom`; it does not install updates.

### REQUIREMENTS
Pi-hole CLI/version cache and writable node-exporter textfile directory.

---

## `dietpi/restic-backup-dietpi`

### NAME
`restic-backup-dietpi` — run the simple DietPi Restic backup and enforce retention.

### SYNOPSIS
```bash
sudo ./scripts/dietpi/restic-backup-dietpi
```

### DESCRIPTION
Loads `/etc/restic/dietpi.env`, backs up `/etc`, `/home`, `/usr/local` and `/var/lib`, then executes Restic retention with 7 daily, 4 weekly, 12 monthly and 5 yearly snapshots.

### SIDE EFFECTS
**BACKUP / RETENTION.** Runs `restic forget ... --prune`; snapshots outside the retention policy can be removed and unreferenced repository data pruned. This is materially more destructive than the monitored `backup-dietpi.sh` script.

### REQUIREMENTS
Correct Restic environment/credentials and access to the configured repository.

---

## `dietpi/validate-npm-sops-recovery-identity.sh`

### NAME
`validate-npm-sops-recovery-identity.sh` — independently validate the NPM encrypted recovery source using DietPi's protected recovery identity.

### SYNOPSIS
```bash
./scripts/dietpi/validate-npm-sops-recovery-identity.sh
```
Optional: `ARCHIVE`, `SOPS_RECOVERY_IDENTITY`, `EXPECTED_HOST`.

### DESCRIPTION
Runs only on the expected DietPi host, verifies the incoming tar allowlist, extracts it into `/dev/shm`, decrypts the SOPS file with the protected recovery age identity, confirms the exact expected NPM variable structure and compares a one-way checksum with the protected live source checksum. Temporary plaintext and the transfer archive are removed afterward.

### SIDE EFFECTS
**SECRET-SENSITIVE.** Temporarily creates decrypted recovery material in RAM-backed storage and then removes it. It deliberately does not change repository files, containers, proxy hosts or services and does not print credentials/private identity material.

### REQUIREMENTS
DietPi, `sops`, protected recovery identity, the validation archive created by `prepare-npm-sops-recovery-validation.sh`, and sudo access to read the recovery identity.

---

# Recommended operating rules

1. **Use the dry-run mode first** where a script provides one, especially the Pi-hole Stage 1 and Stage 2 provisioning changes.
2. **Read the SIDE EFFECTS section before running** any item marked CONFIG CHANGE, BACKUP / RETENTION, EMAIL / SERVICE RUN or SECRET-SENSITIVE.
3. **Do not assume repository path equals runtime path.** Several scripts are repository copies of files deployed under `/usr/local/bin`, `/usr/local/sbin`, `/var/lib`, or host-specific script directories.
4. **Preserve staged-change sequencing.** For the Pi-hole latency work, Stage 0 is the backup/baseline; Stage 1 and Stage 2 are Grafana policy changes; Stage 3 adds single-instance locking; Stage 4 adds monitoring of the locked collector.
5. **Treat recovery inventories and diagnostics as sensitive operational evidence** even where secret contents are intentionally excluded.
6. **Treat Restic retention/prune separately from backup creation.** In particular, `dietpi/restic-backup-dietpi` performs `forget --prune`, while `dietpi/backup-dietpi.sh` performs the monitored backup without that retention command.
7. **Review hard-coded host/network assumptions before reuse on another host.** Several scripts intentionally target the current homelab paths, hostnames, interfaces and addresses.

## Related documentation

- `scripts/README.md` — deployment/runtime-path notes and the Pi-hole latency execution sequence.
- `grafana-alert-email-standard.md` — common Grafana alert email format.
- `blocked-mac-monitoring.md` — watched/blocked MAC monitoring design.
- `engineering-portfolio-deployment.md` — separate Engineering Portfolio operational scripts and deployment process.
