# Daily Homelab Actions — 22 August 2026

Planned follow-up work carried forward from 21 August 2026.

## Priority 1 — Fix daily security and engineering report truth

**Status:** OPEN — HIGHEST PRIORITY

The two report-generation components below are now the primary engineering priority because the Daily Security & Recovery Brief and Engineering Security Runbook can understate operational risk when evidence is missing, stale or incorrectly classified.

### Primary targets

1. `/usr/local/lib/homelab-secops-report/generate_report.py`
   - Controls the authoritative technical report that feeds the management brief.
   - Review how evidence is collected, classified and converted into operational states.
   - Ensure missing, stale or unavailable evidence cannot silently become healthy.
   - Separate security-compromise status from operational resilience and monitoring integrity.

2. `/usr/local/bin/homelab-security-reader.py`
   - Drives the Greenbone engineering security review/runbook evidence and AI interpretation.
   - Review priority classification and handling of UNKNOWN, stale and incomplete evidence.
   - Ensure engineering P1/P2/P3 findings reflect genuine unresolved operational risk.

### Required reporting rules

- **UNKNOWN is not HEALTHY.** Missing or unavailable evidence must be represented explicitly.
- **No compromise does not mean no incident.** Security posture and operational resilience must be scored separately.
- **Freshness matters.** A timer or service existing is not enough; collector output must be fresh and successfully scraped.
- **Failed units must be classified.** Actionable service failures should affect the report; intentionally masked/non-applicable services should not.
- **Backup status must distinguish PASS / FAIL / UNKNOWN.** Unknown backup, replica or storage state should produce at least a planned engineering action unless intentionally suppressed.
- **Overall status should be derived from the worst meaningful unresolved condition**, not solely from security-compromise evidence.
- **Monitoring failures are operational findings.** A broken collector or stale metric path must not be hidden by a healthy high-level service state.

### Validation targets

The revised generators must correctly represent the conditions discovered during the 22 August review:

- Pi-hole blocklist collector path failure must be visible when present.
- Stale or unavailable backup/replica/storage evidence must become an explicit engineering finding.
- CrowdSec transient API failures must be classified according to whether they remain unresolved.
- Non-applicable services such as masked OpenIPMI must not create false host failures.
- A clean security posture must not automatically produce an overall GREEN when recovery or monitoring evidence is degraded.

### Report architecture confirmed

```text
08:30
homelab-secops-management-report.timer
  -> homelab-secops-management-report.service
  -> /usr/local/sbin/homelab-secops-management-report
  -> /usr/local/sbin/homelab-secops-report
  -> /usr/local/lib/homelab-secops-report/generate_management_report.py
  -> management/latest.md
```

```text
07:30
homelab-greenbone-ai-review.timer
  -> homelab-greenbone-ai-review.service
  -> /usr/local/sbin/homelab-greenbone-ai-review
  -> /usr/local/bin/homelab-security-reader.py
  -> /var/lib/homelab-greenbone/reports/latest.md

07:45
homelab-greenbone-engineering-email.timer
  -> homelab-greenbone-engineering-email.service
  -> extracts Priority Summary from latest.md
  -> emails Engineering Security Runbook
```

The email sender scripts are not the primary targets; fix the report-generation/classification logic at the two components above first.

## Priority 2 — Pi-hole collector hardening

**Status:** COMPLETE

- [x] Add `flock` single-instance protection to both query collectors.
- [x] Verify efficient generic subdomain/category enrichment on DietPi.
- [x] Do not restore the expensive wildcard SQLite join approach.
- [x] Confirm both collectors continue to run within their scheduling interval without overlap.
- [x] Add Stage 4 flock monitoring metrics.
- [x] Add stale collector Grafana alert.

## Priority 3 — Documentation and recovery evidence

**Status:** IN PROGRESS

- [ ] Update the Pi-hole Policy Alert Latency Improvement Runbook with the post-change measurements.
- [x] Record the final accepted alert timings and rollback configuration in the daily operational log.
- [x] Add a dedicated Nebula Sync service overview.
- [x] Record the Nebula Sync false-alert root cause and monitoring fix below.
- [x] Keep `home-lab-docs` as the authoritative operational record for this work.
- [x] Create ids-01 host recovery inventory and SCP.
- [ ] Create host recovery inventory and SCP for the other hosts.

## Pi-hole configuration sync monitoring — false alert resolved

**Status:** FIXED

### Symptom

Grafana fired `Pi-hole Configuration Sync Unhealthy` for `ids-01`. Prometheus initially reported:

```text
homelab_pihole_sync_up = 1
homelab_pihole_sync_last_result_success = 0
homelab_pihole_sync_last_success_timestamp_seconds = 0
homelab_pihole_sync_age_seconds = -1
```

This appeared to indicate that the Nebula Sync container was healthy but no successful Pi-hole configuration sync had been observed.

### Service verification

The `nebula-sync` container was checked directly and was healthy. Its logs showed successful selective synchronisation every 15 minutes, repeatedly ending with:

```text
Sync completed
```

Current deployment details confirmed:

```text
container: nebula-sync
image: ghcr.io/lovelaze/nebula-sync:v0.11.2
stack: /home/james/docker/stacks/nebula-sync
schedule: */15 * * * *
mode: selective
replicas: 1
```

The service itself was therefore not the cause of the alert.

### Collector investigation

The custom metrics collector was identified as:

```text
/usr/local/bin/nebula-sync-metrics.sh
```

with:

```text
nebula-sync-metrics.service
nebula-sync-metrics.timer
```

The timer runs the collector approximately every minute.

The collector correctly detected the healthy container and correctly parsed recent `Sync completed` messages. Its fresh output contained:

```text
homelab_pihole_sync_up 1
homelab_pihole_sync_last_result_success 1
homelab_pihole_sync_last_success_timestamp_seconds 1787377500
homelab_pihole_sync_age_seconds 732
```

### Root cause

Two different node-exporter textfile directories existed on ids-01.

The Nebula Sync collector was writing fresh metrics to:

```text
/var/lib/prometheus/node-exporter/nebula_sync.prom
```

However, `prometheus-node-exporter` had been explicitly configured to read:

```text
--collector.textfile.directory=/var/lib/node_exporter/textfile_collector
```

A stale `nebula_sync.prom` from 20 August remained in that active directory. Node-exporter therefore exposed the stale failure values while the fresh healthy values were being written to a directory it was not scraping.

This was a monitoring-path/configuration error, not a Nebula Sync replication failure.

### Fix

A backup of the collector was created:

```text
/usr/local/bin/nebula-sync-metrics.sh.bak-20260822
```

The collector output path was changed from:

```text
/var/lib/prometheus/node-exporter/nebula_sync.prom
```

to the authoritative node-exporter textfile directory:

```text
/var/lib/node_exporter/textfile_collector/nebula_sync.prom
```

The collector was then run manually. Node-exporter immediately exposed the corrected values and Prometheus returned:

```text
homelab_pihole_sync_up = 1
homelab_pihole_sync_last_result_success = 1
homelab_pihole_sync_last_success_timestamp_seconds = 1787377500
homelab_pihole_sync_last_failure_timestamp_seconds = 1787309943
homelab_pihole_sync_age_seconds = 732
```

The obsolete `/var/lib/prometheus/node-exporter/nebula_sync.prom` file was removed so there is now one authoritative metrics path.

### Result

- Nebula Sync confirmed healthy.
- Successful 15-minute replication confirmed from live logs.
- Metrics collector confirmed healthy.
- node-exporter now reads the fresh collector output.
- Prometheus now receives correct Pi-hole sync health values.
- Root cause of the false Grafana warning removed.
- DNS/Pi-hole alert inbox was cleared after review to provide a clean baseline for new alerts.

## Backup incident — TestServer Restic backup failure

**Status:** RECOVERED — MONITORING ADDED AND TESTED

### Detection and root cause

The scheduled TestServer backup failed at 03:30:58 BST because Restic could not reach its REST repository at `192.168.2.242:8000`. On ids-01 the `restic-server` container was stopped and nothing was listening on TCP/8000.

After starting the existing container, Docker showed a configured port binding but an empty live `NetworkSettings.Ports` map, so TCP/8000 remained unreachable.

### Recovery

The Restic compose stack at `/home/james/docker/stacks/restic-server` was recreated with `docker compose down` followed by `docker compose up -d --force-recreate`.

After recreation:

- TestServer connected successfully over TLS.
- An unauthenticated curl returned HTTP 401, confirming service availability and authentication enforcement.
- Restic successfully opened repository `0b1d890a`.
- The TestServer backup service was manually rerun and completed at 06:23:53 BST with `status=0/SUCCESS`.
- Grafana subsequently reported the backup failure as resolved.

### Restic monitoring added

A dedicated Restic REST-server health collector now checks container state, Docker port publication, TCP/8000 listening state, HTTPS reachability and overall service health.

It exports:

```text
homelab_restic_server_up
homelab_restic_server_container_up
homelab_restic_server_port_published
homelab_restic_server_port_listening
homelab_restic_server_https_reachable
homelab_restic_server_health_timestamp_seconds
```

The collector runs every minute through `restic-server-health.timer` and writes into `/var/lib/node_exporter/textfile_collector`.

Two Grafana alerts were deployed:

1. `Restic Server Down` — critical, `for: 2m`.
2. `Restic Health Check Stale` — critical, `for: 2m`, no-data alerts enabled.

A controlled stale-health test successfully produced the expected Grafana/Gmail alert. The health timer was subsequently restarted and the collector returned to normal operation.

### Remaining Restic follow-up

- [ ] Confirm the next scheduled TestServer backup completes normally.
- [ ] Perform a controlled `Restic Server Down` alert test when convenient and away from a scheduled backup window.
- [ ] Investigate why `restic-server` was cleanly stopped despite `restart: unless-stopped`.
- [ ] Investigate the temporary Docker port-binding inconsistency seen before container recreation.
- [ ] Review recurring Docker `Error streaming logs: invalid character '\x00'` messages separately.

## Additional work if time permits

- [ ] Continue Stage 0 of the Docker image version-control project.
- [ ] Verify the next Greenbone scheduled run and add an ingestion-health alert if required.
- [ ] CrowdSec freshness/tidy review.
- [ ] Continue Suricata dashboard/filter/end-to-end validation.

## Closed / completed

- [x] k3s-node-01 recovery and stability work — complete; do not carry forward as an outstanding recovery task.
- [x] Pi-hole policy-category metrics proven through both Pi-hole nodes.
- [x] DietPi automatic collection confirmed.
- [x] ids-01 automatic collection confirmed.
- [x] Policy-event lookback widened from 120 seconds to 300 seconds.
- [x] DNS → Pi-hole → collector → Prometheus → Grafana → Gmail path proven.
- [x] Pi-hole alert latency reduced from 3m04s baseline to approximately 1m32s in the final controlled test.
- [x] Duplicate Pi-hole notification behaviour corrected with route-local grouping.
- [x] Nebula Sync service confirmed healthy and false monitoring alert root cause corrected.
- [x] NFS-mounted live SQLite access rejected for the monitoring architecture.
- [x] Pi-hole Policy Alert Latency Improvement Runbook created in `home-lab-docs`.
- [x] Stage 3 flock single-instance protection deployed and verified on ids-01 and DietPi.
- [x] Stage 4 flock monitoring deployed and verified on ids-01 and DietPi.
- [x] Pi-hole Query Collector Stale Grafana alert deployed.
- [x] ids-01 blocklist metrics path corrected and Prometheus verification completed.
- [x] Non-applicable OpenIPMI service investigated and masked; `systemctl --failed` now clean on ids-01.
- [x] Daily Security & Recovery / Engineering Security Runbook generation chain located and documented.
