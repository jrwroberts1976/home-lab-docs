# Pi-hole Policy Alert Latency Improvement Runbook

## Purpose

Provide a controlled, measurable plan for reducing the delay between a Pi-hole policy block and the corresponding Grafana email notification.

This runbook applies to the `Pi-hole Policy Category Detected` alert for `adult`, `gambling`, `threat` and `bypass` events across both Pi-hole nodes.

The goal is to improve latency without making the alert path fragile, noisy, or dependent on a live SQLite database mounted over the network.

## Current architecture

1. Client DNS query is blocked by Pi-hole.
2. `/usr/local/bin/pihole-query-metrics.sh` reads the local Pi-hole FTL SQLite database and writes node-exporter textfile metrics.
3. Prometheus scrapes node-exporter.
4. Grafana evaluates `Pi-hole Policy Category Detected`.
5. Grafana notification policy groups the alert and sends email through `Homelab Email Alerts`.

### Pi-hole 1 / DietPi

- query DB: `/etc/pihole/pihole-FTL.db`
- collector schedule: cron every minute
- host label: `dietpi`
- node-exporter instance: `192.168.2.48:9100`

### Pi-hole 2 / ids-01

- query DB: `/home/james/docker/stacks/pihole-secondary/etc-pihole/pihole-FTL.db`
- collector schedule: `pihole-query-metrics.timer`, approximately every minute
- host label: `ids-01`
- node-exporter instance: `192.168.2.242:9100`

## Known timings

### Collector

Each Pi-hole collector runs approximately once per minute, so a new query can wait up to about 60 seconds before it is exported.

### Prometheus

The global Prometheus scrape interval is 15 seconds. The separate `scrape_interval: 60s` entry in `prometheus.yml` belongs to the WUD job, not the Pi-hole/node-exporter path.

### Grafana rule evaluation

Provisioned rule file:

```text
/home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-policy-alerts.yml
```

Current evaluation interval:

```yaml
interval: 1m
```

The event lookback has already been widened from 120 seconds to 300 seconds in both PromQL branches so valid events are not lost between collection, scrape and evaluation cycles.

### Grafana notification policy

Provisioned policy file:

```text
/home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-notification-policy.yml
```

Current Pi-hole policy route:

```yaml
- receiver: Homelab Email Alerts
  object_matchers:
    - ['service', '=', 'pihole']
    - ['alert_type', '=', 'policy-category']
  group_wait: 1s
  group_interval: 5m
  repeat_interval: 24h
```

The `group_interval: 5m` is the largest avoidable contributor once a policy alert group already exists. A newly detected alert instance can be held until the next notification update for that group.

## Baseline evidence

A controlled Pi-hole 1 test was run from TestServer (`192.168.2.220`) against Pi-hole 1 (`192.168.2.48`).

```text
TEST START: 2026-08-21 20:54:46 BST
nslookup www.betfred.com 192.168.2.48
Address: 0.0.0.0
TEST END:   2026-08-21 20:54:47 BST
```

At `20:57:14 BST`, Prometheus returned the DietPi gambling event for client `192.168.2.220` with an event age of approximately 123 seconds.

Grafana email for the gambling group arrived at approximately `20:57:50 BST`.

Measured end-to-end latency:

```text
20:54:46 -> 20:57:50 = 3 minutes 4 seconds
```

During testing, gambling notifications were observed at approximately `20:42:50`, `20:47:50`, `20:52:50` and `20:57:50`, matching the configured five-minute `group_interval` cadence.

## Architecture decision: do not mount the live Pi-hole SQLite DB over NFS

Pi-hole stores query data in SQLite. Grafana can query a SQLite database only when the database file is accessible to the Grafana server process.

For Pi-hole 1, exposing the live FTL database to Grafana over NFS or another network filesystem is rejected as the alerting design because it would add network latency and introduce unnecessary filesystem/locking risk around a live SQLite database.

The supported design remains:

```text
local Pi-hole SQLite DB
        -> local collector
        -> node-exporter textfile metric
        -> Prometheus
        -> Grafana
        -> email
```

Keeping both Pi-hole nodes on the same monitoring architecture also makes testing and fault diagnosis simpler.

Direct local SQLite access on `ids-01` may still be considered later for dashboard/reporting experiments, but it is not part of this latency-remediation plan and must not replace the primary alert path without separate testing.

## Improvement target

Initial operational target:

- remove the five-minute notification cadence from Pi-hole policy alerts
- achieve typical end-to-end notification latency below two minutes
- aim for a measured hard ceiling of roughly 150 seconds across repeated controlled tests
- preserve the current 300-second event lookback until the full path has proved stable
- avoid increasing unrelated Grafana notification noise

The target is measured from the timestamp immediately before the DNS test query to the email receipt timestamp.

## Change plan

Changes are applied one stage at a time. After every stage, repeat the same timestamped test and record the result before making another change.

### Stage 0 - record and protect the current configuration

Before changing either Grafana provisioning file, create timestamped backups.

```bash
sudo cp /home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-notification-policy.yml \
  /home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-notification-policy.yml.bak-$(date +%Y%m%d-%H%M%S)

sudo cp /home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-policy-alerts.yml \
  /home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-policy-alerts.yml.bak-$(date +%Y%m%d-%H%M%S)
```

Record the current values:

```bash
grep -nE 'group_wait|group_interval|repeat_interval' \
  /home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-notification-policy.yml

grep -nE 'interval:|time\(\) - ' \
  /home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-policy-alerts.yml
```

Expected baseline:

- Pi-hole route `group_wait: 1s`
- Pi-hole route `group_interval: 5m`
- Pi-hole route `repeat_interval: 24h`
- alert evaluation `interval: 1m`
- both lookback expressions use `time() - 300`

### Stage 1 - reduce only the Pi-hole notification group interval

Change the Pi-hole-specific policy route only:

```yaml
group_interval: 5m
```

to:

```yaml
group_interval: 30s
```

Do not change the root policy or the generic warning/critical routes during this stage.

Reload Grafana provisioning using the established Grafana restart procedure, then confirm Grafana starts without provisioning or alerting errors.

#### Stage 1 acceptance test

Run one timestamped gambling test against each Pi-hole independently.

Example against Pi-hole 1:

```bash
echo "TEST START: $(date '+%Y-%m-%d %H:%M:%S %Z')"
nslookup www.betfred.com 192.168.2.48
echo "TEST END:   $(date '+%Y-%m-%d %H:%M:%S %Z')"
```

Example against Pi-hole 2:

```bash
echo "TEST START: $(date '+%Y-%m-%d %H:%M:%S %Z')"
nslookup flashcasino.com 192.168.2.242
echo "TEST END:   $(date '+%Y-%m-%d %H:%M:%S %Z')"
```

Do not run either collector manually during the test.

Record:

1. DNS test start time
2. Pi-hole FTL event time
3. collector/textfile update time if needed for diagnosis
4. Prometheus visibility time
5. Grafana email receipt time
6. total end-to-end latency

Pass condition: the five-minute grouped-notification cadence is gone and the measured delay is materially lower than the 3m04s baseline.

### Stage 2 - reduce Grafana evaluation interval only if Stage 1 is still too slow

If Stage 1 still regularly exceeds the target, change the Pi-hole alert group evaluation interval from:

```yaml
interval: 1m
```

to:

```yaml
interval: 30s
```

Keep the 300-second event lookback unchanged.

Reload Grafana, repeat the timestamped tests on both Pi-hole nodes and record the new latency.

Do not reduce the lookback merely because the evaluation interval is shorter. The lookback is a reliability buffer and should only be tightened after several successful tests.

### Stage 3 - harden the collectors

Once notification timing is acceptable, add overlap protection so a slow collector invocation cannot stack with the next scheduled run.

Use `flock` or an equivalent single-instance guard around `/usr/local/bin/pihole-query-metrics.sh` on both nodes.

Validation requirements:

- scheduled collector continues to run automatically
- no overlapping collector processes
- output file continues to update
- policy metrics for `adult`, `gambling`, `threat` and `bypass` remain present
- normal runtime stays comfortably below the schedule interval

Do not reintroduce broad wildcard joins against the large category cache; those previously made the primary collector too slow.

### Stage 4 - consider collector frequency only if still necessary

Do not change collector frequency until Stages 1-3 are measured.

The current one-minute collector interval is a possible remaining source of up to about 60 seconds of delay, but changing it increases database read frequency and operational complexity.

Only consider a faster collector schedule if the measured result after Grafana tuning remains outside the agreed target. Any change must be tested for CPU, SQLite read load, runtime and overlap behaviour before being retained.

## Validation queries

### Prometheus - Pi-hole 1 gambling event

Run from the Prometheus host:

```bash
curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=time() - pihole_blocked_client_category_last_event_timestamp_seconds{host="dietpi",category="gambling"}'
```

### Prometheus - Pi-hole 2 gambling event

```bash
curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=time() - pihole_blocked_client_category_last_event_timestamp_seconds{host="ids-01",category="gambling"}'
```

Use a `client=` selector when testing from a known device so old events from another client do not confuse the result.

## Rollback

If Grafana provisioning fails, notifications become noisy, or behaviour becomes worse:

1. restore the timestamped backup of the changed provisioning file
2. restart Grafana using the established monitoring-stack procedure
3. confirm Grafana provisioning starts cleanly
4. confirm the Pi-hole policy rule is present
5. run a known-good controlled test
6. record the rollback and observed behaviour in this runbook

Do not change several timing controls at once. A single-variable change is required so the measured result can be attributed to the correct setting.

## Final acceptance criteria

The improvement work is complete when all of the following are true:

- Pi-hole 1 automatically detects and emails a controlled policy event
- Pi-hole 2 automatically detects and emails a controlled policy event
- no collector is run manually during validation
- notification cadence is no longer effectively tied to five-minute group updates
- three consecutive timestamped tests produce acceptable latency
- no Grafana provisioning errors are introduced
- no collector overlap is observed
- SMTP remains healthy
- the final measured timings and retained configuration are documented here

## Work log / TODO

- [x] Prove both Pi-hole nodes export `pihole_blocked_client_category_last_event_timestamp_seconds` automatically.
- [x] Widen both alert lookback expressions from 120 seconds to 300 seconds.
- [x] Measure a controlled Pi-hole 1 end-to-end test at 3 minutes 4 seconds.
- [x] Identify the Pi-hole-specific `group_interval: 5m` as the main avoidable notification delay.
- [x] Reject NFS-mounted live SQLite as the Pi-hole 1 Grafana alert architecture.
- [ ] Stage 0: back up and record the active timing configuration.
- [ ] Stage 1: change only the Pi-hole policy `group_interval` from 5m to 30s.
- [ ] Stage 1: retest Pi-hole 1 and Pi-hole 2 with timestamped DNS queries.
- [ ] Stage 2: if required, change Grafana evaluation from 1m to 30s and retest.
- [ ] Stage 3: add single-instance/overlap protection to both collectors.
- [ ] Stage 4: evaluate faster collector scheduling only if the measured result still requires it.
- [ ] Record final configuration and final latency measurements.
