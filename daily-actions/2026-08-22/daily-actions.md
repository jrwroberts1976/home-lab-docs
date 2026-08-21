# Daily Homelab Actions — 22 August 2026

Planned follow-up work carried forward from 21 August 2026.

## Priority 1 — Pi-hole policy alert latency improvement

**Status:** OPEN

Start from the Pi-hole Policy Alert Latency Improvement Runbook.

- [ ] Record and back up the current Grafana alert and notification-policy configuration.
- [ ] Change only the Pi-hole policy-category notification `group_interval` from `5m` to `30s`.
- [ ] Reload/restart Grafana and verify provisioning is clean.
- [ ] Run timestamped end-to-end tests through Pi-hole 1 / DietPi and Pi-hole 2 / ids-01.
- [ ] Record DNS test time, Pi-hole event time, collector/textfile update time, Prometheus visibility time, and Grafana email receipt time.
- [ ] Compare the result with the measured 21 August baseline of 3 minutes 4 seconds.
- [ ] Only if required, evaluate changing the Grafana rule evaluation interval from `1m` to `30s`.
- [ ] Keep the existing 300-second policy-event lookback while tuning.

Architecture decision: do not mount the live Pi-hole SQLite database over NFS for Grafana. Keep database reads local to each Pi-hole node and export the required metrics.

## Priority 2 — Pi-hole collector hardening

**Status:** OPEN

- [ ] Add `flock` or equivalent single-instance protection to both query collectors.
- [ ] Finish and verify efficient generic subdomain/category enrichment on DietPi.
- [ ] Do not restore the expensive wildcard SQLite join approach.
- [ ] Confirm both collectors continue to run within their scheduling interval without overlap.

## Priority 3 — Documentation

**Status:** OPEN

- [ ] Update the Pi-hole Policy Alert Latency Improvement Runbook with the post-change measurements.
- [ ] Record the final accepted alert timings and rollback configuration.
- [ ] Keep `home-lab-docs` as the authoritative operational record for this work.

## Additional work if time permits

- [ ] Continue Stage 0 of the Docker image version-control project.
- [ ] Verify the next Greenbone scheduled run and add an ingestion-health alert if required.
- [ ] CrowdSec freshness/tidy review.
- [ ] Continue Suricata dashboard/filter/end-to-end validation.

## Closed from 21 August 2026

- [x] Pi-hole policy-category metrics proven through both Pi-hole nodes.
- [x] DietPi automatic collection confirmed via cron.
- [x] ids-01 automatic collection confirmed via systemd timer.
- [x] Policy-event lookback widened from 120 seconds to 300 seconds.
- [x] DNS → Pi-hole → collector → Prometheus → Grafana → Gmail path proven.
- [x] Controlled Pi-hole 1 latency test measured at 3 minutes 4 seconds.
- [x] Grafana Pi-hole notification `group_interval: 5m` identified as a major delay source.
- [x] NFS-mounted live SQLite access rejected for the monitoring architecture.
- [x] Pi-hole Policy Alert Latency Improvement Runbook created in `home-lab-docs`.
