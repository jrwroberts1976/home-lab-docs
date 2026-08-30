# Grafana Alloy — Log Collection and Routing

## Purpose

Grafana Alloy is the homelab log-collection and routing layer. It receives or reads operational and security logs, applies stable labels and routing rules, and forwards the resulting streams to Loki for search, dashboards, alerting and security review.

Alloy is not the long-term log store. Its job is to make sure logs reach Loki with labels that downstream consumers can rely on.

The operating principle is:

> Collect close to the source, preserve useful identity, route centrally, and prove ingestion from Loki.

## Current role in the homelab

The central logging path is:

```text
Applications / containers / system services / security controls
                       |
                       v
                 Grafana Alloy
                       |
                       v
                     Loki
                       |
             +---------+---------+
             |                   |
             v                   v
          Grafana          Security review
       dashboards/alerts      and reporting
```

`ids-01` currently uses the systemd-managed Alloy collector as the active service. An obsolete Docker Alloy container on `ids-01` was removed after the service audit confirmed that the systemd instance was the working collector.

The active `ids-01` command is:

```text
/usr/bin/alloy run --storage.path=/var/lib/alloy/data /etc/alloy/config.alloy
```

Primary configuration:

```text
/etc/alloy/config.alloy
```

Alloy runs as the dedicated `alloy` service user rather than as an unrestricted root process.

TestServer has its own host-specific log-collection path. Alloy configuration must therefore be treated as host-specific where inputs, paths and permissions differ; the `ids-01` configuration must not simply be copied over another host.

## Important log sources

The `ids-01` collector handles multiple source types because not every service writes logs in the same way.

Current or established sources include:

- systemd journal streams;
- Docker workloads configured to log through journald;
- file-based security logs where that remains the correct durable source;
- Greenbone AI review report files;
- CrowdSec engine and Local API journal events;
- CrowdSec firewall-bouncer logs;
- Pi-hole secondary and Unbound container journals;
- Suricata security-event logs;
- ASUS router/syslog-derived logging used by the monitoring and security platform.

The preferred source is the most stable source available. For example, Pi-hole secondary and Unbound were moved away from hard-coded Docker JSON log paths because container IDs change when containers are recreated.

## Stable labels are part of the interface

Alloy labels are not cosmetic. Grafana dashboards, Loki queries, AI review scripts and operational procedures depend on them.

Common labels include:

```text
job
host
env
service
container
```

Examples of established Loki streams on `ids-01` include:

```logql
{job="pihole",host="ids-01"}
{job="unbound",host="ids-01"}
{job="crowdsec",host="ids-01"}
{job="crowdsec-api",host="ids-01"}
{job="crowdsec-bouncer",host="ids-01"}
{job="greenbone-review",host="ids-01"}
```

A change that still sends logs but changes an established `job` or `host` label can break monitoring just as effectively as dropping the logs entirely.

For this reason, label changes are treated as interface changes and must be reviewed against downstream consumers.

## Example: durable container logging

Pi-hole secondary and Unbound use Docker's journald logging driver. Alloy selects them using stable container names rather than Docker container IDs.

Conceptually:

```text
Pi-hole secondary
      |
      v
Docker journald
      |
      v
Alloy journal source
      |
      v
job="pihole", host="ids-01"
      |
      v
Loki
```

The same pattern is used for Unbound.

This avoids fragile dependencies on paths such as:

```text
/var/lib/docker/containers/<container-id>/*-json.log
```

## Example: CrowdSec classification

CrowdSec was moved from fragile file-based main-agent logging to syslog/journald. Alloy reads the `crowdsec.service` journal and preserves a general `job="crowdsec"` stream.

Local API HTTP requests are additionally classified into the established:

```text
job="crowdsec-api"
```

stream so existing security-reader queries continue to work.

The CrowdSec firewall bouncer remains a separate file-based source because that path is stable and already works correctly.

## File permissions and least privilege

Alloy should be given the minimum read access required for each source.

The Greenbone AI review path demonstrated the correct pattern. Reports are created as:

```text
root:alloy 0640
```

with the containing directory traversable by the Alloy group.

This is preferable to making security-sensitive reports world-readable or running Alloy as root merely to bypass a permissions problem.

When a new source is added, first decide whether access should be provided through:

- journal membership/access;
- a dedicated group;
- controlled file ownership and mode;
- a stable application logging interface;
- or a different collection mechanism entirely.

Do not solve collection errors by broadly weakening permissions.

## Availability expectations

Alloy is part of the observability and security evidence path. A short interruption does not normally stop the protected application itself, but prolonged collection failure can create monitoring blind spots and lost forensic evidence.

The important availability questions are therefore:

1. Is the Alloy process running?
2. Can it read the intended sources?
3. Can it reach Loki?
4. Are expected streams still receiving fresh entries?

A running Alloy process by itself is not proof that log ingestion is healthy.

## Validation

Validate configuration before restarting the service:

```bash
sudo /usr/bin/alloy validate /etc/alloy/config.alloy
```

Check the service:

```bash
sudo systemctl status alloy --no-pager --full
sudo journalctl -u alloy --since "15 minutes ago" --no-pager
```

Then prove ingestion from the destination by querying Loki for the affected stream.

For example:

```logql
{job="crowdsec-api",host="ids-01"}
```

The preferred proof chain is:

```text
source produces a fresh event
        |
        v
Alloy reads the event
        |
        v
Loki stores the event
        |
        v
query returns the fresh event with expected labels
```

## Monitoring and alerting

Alloy monitoring should cover more than process state.

Useful controls include:

- `alloy.service` active state;
- recent Alloy errors from its own journal;
- Loki reachability;
- freshness of critical streams;
- source-specific collection failures;
- permission-denied events;
- unexpected label disappearance;
- ingestion gaps after container recreation or log rotation.

Critical streams such as Greenbone, Suricata, CrowdSec and Pi-hole security events should eventually have explicit freshness checks where a silent ingestion failure would otherwise go unnoticed.

## Common failure modes

### Source permission denied

Symptoms:

- Alloy remains running;
- one file source stops updating;
- Alloy logs show `permission denied`.

Response:

- inspect file and directory ownership/mode;
- grant only the required group/read access;
- correct the producer so future files are created with the correct ownership;
- validate in Loki using a fresh marker/event.

### Container recreation breaks file path

Symptoms:

- container is healthy;
- old JSON log path no longer receives data;
- Alloy source points at a previous Docker container ID.

Response:

- prefer journald or another stable source keyed by service/container identity;
- remove stale container-ID-specific paths;
- prove current data reaches Loki.

### Labels change unexpectedly

Symptoms:

- Loki contains data;
- dashboards/reports show no data;
- established LogQL selectors no longer match.

Response:

- compare labels before and after the change;
- preserve established labels unless an intentional migration is being performed;
- update and test every downstream consumer if the label contract must change.

### Loki unavailable

Symptoms:

- Alloy source reads continue;
- writes fail or queue/retry;
- downstream dashboards become stale.

Response:

- restore Loki/network availability;
- inspect Alloy for write/retry errors;
- confirm recent timestamps appear after recovery.

## Backup and recovery requirements

The important recoverable assets are:

- `/etc/alloy/config.alloy`;
- any supporting certificates or controlled credentials;
- service/unit configuration where customised;
- documentation of required source permissions and group membership;
- downstream Loki label expectations.

Alloy's local storage path is operational state, not a substitute for backing up configuration.

A recovered collector should be considered healthy only after:

1. the configuration validates;
2. the service starts cleanly;
3. critical sources can be read;
4. Loki is reachable;
5. fresh test/current events are queryable with the expected labels.

## Change rules

1. Validate Alloy configuration before restart or reload.
2. Prefer stable journal/service identities over Docker container-ID paths.
3. Preserve established Loki labels unless a controlled migration is planned.
4. Grant read access narrowly; do not make sensitive logs world-readable.
5. Do not run duplicate collectors against the same source without a deliberate reason.
6. Treat host-specific paths and source sets as host-specific configuration.
7. Verify the destination stream after every meaningful source change.
8. A running collector is not sufficient evidence; prove fresh ingestion in Loki.

## Related documentation

- [Service Overviews index](README.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [AI Security Review](ai-security-review.md)
- [ids-01 Service and Timer Inventory](ids-01-service-inventory.md)
- [Log Ingestion and Grafana Alert Email Recovery](../sop/log-ingestion-and-grafana-email-recovery.md)
- [Homelab Hardware Health Dashboard](../hardware-health-dashboard.md)
