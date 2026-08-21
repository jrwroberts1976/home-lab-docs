# Pi-hole Policy Alert Latency Troubleshooting

## Purpose

Document the observed delay between a Pi-hole policy block and the corresponding Grafana email notification, the evidence collected on 21 August 2026, and the remaining tuning work.

This applies to the `Pi-hole Policy Category Detected` alert for `adult`, `gambling`, `threat` and `bypass` events across both Pi-hole nodes.

## Current alert path

1. Client DNS query is blocked by Pi-hole.
2. `/usr/local/bin/pihole-query-metrics.sh` reads the Pi-hole FTL database and writes node-exporter textfile metrics.
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

## Relevant timings

### Prometheus

The global Prometheus scrape interval is 15 seconds. The separate 60-second scrape interval in `prometheus.yml` belongs to the WUD job and is not the Pi-hole/node-exporter scrape interval.

### Grafana alert rule

Provisioned rule file:

```text
/home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-policy-alerts.yml
```

Current rule evaluation interval:

```yaml
interval: 1m
```

The policy event lookback was widened from 120 seconds to 300 seconds in both PromQL branches so valid events are not missed due to collector, scrape and evaluation timing.

### Grafana notification policy

Provisioned policy file:

```text
/home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-notification-policy.yml
```

Pi-hole policy-category route:

```yaml
- receiver: Homelab Email Alerts
  object_matchers:
    - ['service', '=', 'pihole']
    - ['alert_type', '=', 'policy-category']
  group_wait: 1s
  group_interval: 5m
  repeat_interval: 24h
```

The `group_interval: 5m` is the main source of perceived delay once an alert group already exists. A new alert instance can be detected by Grafana but held until the next notification update for the existing group.

## Measured example

A controlled Pi-hole 1 test was run from TestServer (`192.168.2.220`) against Pi-hole 1 (`192.168.2.48`).

```text
TEST START: 2026-08-21 20:54:46 BST
nslookup www.betfred.com 192.168.2.48
Address: 0.0.0.0
TEST END:   2026-08-21 20:54:47 BST
```

At `20:57:14 BST`, Prometheus returned the DietPi gambling event for client `192.168.2.220` with an event age of approximately 123 seconds.

Grafana email for the gambling group arrived at approximately `20:57:50 BST`.

Measured end-to-end time:

```text
20:54:46 -> 20:57:50 = 3 minutes 4 seconds
```

During testing, gambling group notifications were observed at approximately `20:42:50`, `20:47:50`, `20:52:50` and `20:57:50`, matching the configured five-minute `group_interval` cadence.

## Diagnosis

The Pi-hole block itself is immediate. Both collectors have been proven to run automatically and expose policy metrics successfully.

Possible cumulative delay:

- Pi-hole collector: up to about 60 seconds before the next scheduled run
- Prometheus scrape: up to about 15 seconds
- Grafana rule evaluation: up to about 60 seconds
- notification update for an existing group: up to 5 minutes with the current `group_interval`

The biggest avoidable contributor for an already-active policy group is the Grafana notification grouping interval.

## Direct Grafana-to-SQLite option

Pi-hole stores query data in SQLite. Grafana can query SQLite through the `frser-sqlite-datasource` plugin if the database file is accessible to the Grafana server filesystem.

This is straightforward for Pi-hole 2 because Grafana and the secondary Pi-hole run on `ids-01`; the FTL database could be mounted read-only into the Grafana container and queried directly.

It is not a true network database connection for Pi-hole 1. The DietPi SQLite file would need to be exposed or copied/mounted onto the Grafana host. Using a live SQLite database across a network filesystem is not recommended as the primary alert path.

Direct SQLite queries could remove the collector and Prometheus stages for a local database, but they would not remove Grafana rule evaluation time or the current 5-minute notification `group_interval`. Therefore this is an architecture option to evaluate, not the primary fix for the observed email delay.

## Recommended next change

Change only the Pi-hole policy-category route from:

```yaml
group_interval: 5m
```

to a shorter value such as:

```yaml
group_interval: 30s
```

Keep the existing 300-second event lookback while testing the notification interval change.

After the change, repeat a timestamped end-to-end test and record:

1. DNS test time
2. Pi-hole FTL event time
3. collector/textfile update time
4. Prometheus visibility time
5. Grafana email receipt time

## TODO

- [ ] Tune the Pi-hole policy notification `group_interval` and retest latency.
- [ ] Decide whether Grafana rule evaluation should remain at 1 minute or move to 30 seconds.
- [ ] Consider whether direct SQLite access is useful for Pi-hole 2 dashboards or alerting; do not replace the current path until tested safely.
- [ ] Keep the 300-second lookback unless testing proves a shorter window is reliable.
- [ ] Add overlap protection (`flock` or equivalent) to collectors where appropriate.
- [ ] Record final measured latency after tuning.
