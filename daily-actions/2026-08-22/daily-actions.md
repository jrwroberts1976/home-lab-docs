# Daily Homelab Actions — 22 August 2026

Planned follow-up work carried forward from 21 August 2026.

## Priority 1 — Pi-hole policy alert latency improvement

**Status:** COMPLETE

Start from the Pi-hole Policy Alert Latency Improvement Runbook.

- [x] Record and back up the current Grafana alert and notification-policy configuration.
- [x] Change only the Pi-hole policy-category notification `group_interval` from `5m` to `30s`.
- [x] Reload/restart Grafana and verify provisioning is clean.
- [x] Run timestamped end-to-end tests through Pi-hole 1 / DietPi and validate alert-instance behaviour from ids-01 test traffic.
- [x] Record DNS test time, Pi-hole event time, Prometheus visibility time, Grafana notifier time, and Grafana email receipt time.
- [x] Compare the result with the measured 21 August baseline of 3 minutes 4 seconds.
- [x] Keep the existing 300-second policy-event lookback while tuning.
- [x] Add a Pi-hole route-local `group_by: ['...']` so distinct client/category/domain/host alert instances are not folded into the broad parent notification group.
- [x] Confirm duplicate/repeated FIRING emails are no longer occurring for the same distinct alert instance.

Final controlled DietPi gambling test on 22 August:

- DNS request: 06:08:18 BST
- Pi-hole event: 06:09:00 BST — 42 seconds
- Prometheus visible: 06:09:25 BST — 67 seconds total
- Grafana local notifier: 06:09:48.9 BST — approximately 91 seconds total
- Matching Gmail alert: 06:09:50 BST — approximately 92 seconds end-to-end
- Result: improved from the 21 August baseline of 3m04s to approximately 1m32s.

Architecture decision: do not mount the live Pi-hole SQLite database over NFS for Grafana. Keep database reads local to each Pi-hole node and export the required metrics.

## Priority 2 — Pi-hole collector hardening

**Status:** OPEN

- [ ] Add `flock` or equivalent single-instance protection to both query collectors.
- [ ] Finish and verify efficient generic subdomain/category enrichment on DietPi.
- [ ] Do not restore the expensive wildcard SQLite join approach.
- [ ] Confirm both collectors continue to run within their scheduling interval without overlap.

## Priority 3 — Documentation

**Status:** IN PROGRESS

- [ ] Update the Pi-hole Policy Alert Latency Improvement Runbook with the post-change measurements.
- [x] Record the final accepted alert timings and rollback configuration in the daily operational log.
- [x] Keep `home-lab-docs` as the authoritative operational record for this work.

## Backup incident — TestServer Restic backup failure

**Status:** RECOVERY IN PROGRESS

### Detection

Grafana repeatedly fired `Backup Failed` during the morning of 22 August. Prometheus metrics isolated the failure to TestServer / `main` (`192.168.2.220`):

- `homelab_backup_success = 0`
- `homelab_backup_last_success_timestamp = 0`
- latest snapshot label reported `snapshot="none"`
- DietPi, ids-01 and k3s-node-01 backup success metrics remained healthy.

The TestServer systemd unit `homelab-backup-testserver.service` had failed after its scheduled 03:30:58 BST run. The backup wrapper ran for about 15 minutes before returning exit status 1.

### Root cause

`/home/homelab-backup/logs/testserver-backup.log` showed Restic repeatedly failing to reach its REST repository:

```text
rest:https://192.168.2.242:8000/testserver/
dial tcp 192.168.2.242:8000: connect: connection refused
Fatal: unable to open config file
Restic backup failed with status 1
```

On ids-01, the `restic-server` container (`restic/rest-server:0.14.0`) was stopped and nothing was listening on TCP/8000. The container had `restart: unless-stopped`, and its logs showed clean shutdowns rather than an obvious crash.

After starting the existing container, Docker showed a configured `8000/tcp` HostConfig binding but an empty live `NetworkSettings.Ports` map. The container therefore appeared running but TCP/8000 was still not reachable from TestServer.

### Recovery performed

The Restic compose stack was recreated on ids-01 from:

```text
/home/james/docker/stacks/restic-server/docker-compose.yml
```

using:

```bash
docker compose down
docker compose up -d --force-recreate
```

After recreation:

- TestServer successfully connected to `https://192.168.2.242:8000/` over TLS.
- An unauthenticated curl returned HTTP 401, confirming the REST server was reachable and enforcing authentication.
- Restic successfully opened repository `0b1d890a` and listed the latest TestServer snapshot `fb4d01ba` from 21 August 2026 03:33:54.

### Outstanding actions

- [ ] Manually rerun `homelab-backup-testserver.service` and confirm a new successful snapshot is created.
- [ ] Confirm `homelab_backup_success` returns to `1` and the Grafana `Backup Failed` alert resolves.
- [ ] Investigate why `restic-server` was cleanly stopped despite `restart: unless-stopped`.
- [ ] Investigate why Docker retained the configured port binding while the live `NetworkSettings.Ports` mapping was empty until container recreation.
- [ ] Review recurring Docker `Error streaming logs: invalid character '\x00'` messages separately; do not conflate them with this backup failure unless evidence links them.

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
