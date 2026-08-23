# ids-01 Service and Timer Inventory

## Purpose

This page records the active service estate on `ids-01`, the systemd and Docker ownership boundaries, and the cleanup decisions verified on 23 August 2026.

It is intended to prevent duplicate collectors, stale timers and abandoned containers from being mistaken for active controls.

## Verified state

The service audit completed with:

- zero failed systemd units;
- 20 running services;
- active systemd ownership of Grafana Alloy;
- healthy Docker Compose projects for monitoring, Pi-hole, Nebula Sync, Restic and Greenbone;
- successful Pi-hole blocklist collection through the current Node Exporter textfile directory.

A systemd `Type=oneshot` service normally returns to `inactive (dead)` after a successful run. For these services, `Result=success`, the timer state and fresh output evidence are the relevant checks.

## Core continuously running services

| Service | Purpose | Decision |
|---|---|---|
| `alloy.service` | Loki log collection and routing, including ASUS router syslog | Keep |
| `crowdsec.service` | CrowdSec detection engine | Keep |
| `crowdsec-firewall-bouncer.service` | CrowdSec firewall enforcement | Keep |
| `suricata.service` | Network IDS | Keep |
| `docker.service` and `containerd.service` | Container runtime | Keep |
| `prometheus-node-exporter.service` | Host and textfile metrics | Keep |
| `smartmontools.service` | Storage health | Keep |
| `unattended-upgrades.service` | Automated package security maintenance | Keep |

## Reporting schedule

| Time | Timer | Purpose |
|---:|---|---|
| 07:00 plus up to 10 minutes | `homelab-greenbone-metrics.timer` | Export Greenbone metrics |
| 07:30 plus up to 5 minutes | `homelab-greenbone-ai-review.timer` | Generate the Greenbone AI review |
| 07:40 | `homelab-greenbone-email.timer` | Send the combined Daily Security & Recovery Brief |
| 07:45 | `homelab-greenbone-engineering-email.timer` | Send the engineering security runbook |
| 08:00 | `wud-image-report.timer` | Send the Docker image status report |
| 08:30 | `homelab-secops-management-report.timer` | Generate the technical and management SecOps reports |

The 07:40 brief now executes `/usr/local/sbin/homelab-secops-pihole-evidence` as an `ExecStartPre` action. It includes a per-client, last-24-hours table of blocked Adult and Malware/Phishing requests. Synthetic checks originating from `192.168.2.242` are excluded from that email table.

The separate Pi-hole daily email timer was disabled to prevent duplicate messages. The standalone sender remains available for manual testing.

## Manual workflows retained

- `homelab-full-overnight-run.service` is intentionally disabled and retained as an on-demand full scan-to-email workflow.
- `homelab-secops-report.service` is retained for manual technical report generation and use by reporting wrappers.
- `pihole-block-alert.service` remains disabled but retained while the Pi-hole policy-alert latency work remains open.

## Components retired on 23 August 2026

### Docker Alloy container

An unused Docker container named `alloy` was stuck in `Created` state and belonged to the obsolete Compose project at:

```text
/home/james/docker/data/monitoring/alloy/docker-compose.yml
```

The working collector is the enabled systemd service:

```text
/usr/bin/alloy run --storage.path=/var/lib/alloy/data /etc/alloy/config.alloy
```

The unused Docker container was removed after confirming `alloy.service` was active.

### Standalone SecOps timer

`homelab-secops-report.timer` was disabled and archived because the 08:30 management workflow already refreshes the authoritative technical report. The underlying `homelab-secops-report.service` remains available.

Retired unit files are stored under:

```text
/etc/systemd/system/retired-homelab-units
```

### Legacy secondary Pi-hole metrics collector

The disabled pair:

- `pihole-secondary-metrics.service`
- `pihole-secondary-metrics.timer`

was archived. Its script wrote to the legacy directory:

```text
/var/lib/prometheus/node-exporter/pihole_blocklists.prom
```

The active replacement is:

```text
pihole-blocklist-metrics.timer
  -> pihole-blocklist-metrics.service
  -> /usr/local/bin/pihole-blocklist-metrics.sh
  -> /var/lib/node_exporter/textfile_collector/pihole_blocklists.prom
```

The retired script is stored under:

```text
/usr/local/lib/retired-homelab-scripts
```

The replacement collector was run manually after cleanup and completed successfully. Node Exporter exposed the expected blocklist and five-category enforcement metrics.

## Greenbone exited containers

The Greenbone Compose stack contains several feed, data-loading, configuration and migration containers that are expected to be one-shot components. Containers with restart policy `no` must not be removed individually merely because they are exited.

Exit code `137` on old feed/data containers should be reviewed in the context of the complete Compose lifecycle and current feed health, not treated automatically as an active service failure.

## Validation commands

```bash
sudo systemctl --failed --no-pager
sudo systemctl list-timers --all --no-pager
sudo systemctl status alloy --no-pager --full
docker compose ls
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
sudo systemctl status pihole-blocklist-metrics.service --no-pager --full
stat /var/lib/node_exporter/textfile_collector/pihole_blocklists.prom
curl -fsS http://127.0.0.1:9100/metrics |
  grep -E '^pihole_|^homelab_pihole_'
```

## Remaining engineering work

1. Prevent active Pi-hole enforcement probes from distorting raw seven-day client/category metrics for `192.168.2.242`, while retaining all five active blocking tests.
2. Verify that the randomized 07:30 AI review always completes before the fixed 07:40 brief. Add an explicit execution dependency or increase separation if overlap is observed.
3. Decide whether the disabled `pihole-block-alert.service` remains part of the latency-improvement design before retiring it.
4. Keep the obsolete Alloy Compose definition from recreating the removed Docker container.
5. Review Greenbone feed-container exit history only if current feed freshness or scan execution becomes unhealthy.

## Change and recovery notes

The archived systemd units and exporter script can be restored from the two retirement directories. After restoring a unit, run:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now <timer-or-service>
```

Do not enable both legacy and replacement collectors for the same metric family.
