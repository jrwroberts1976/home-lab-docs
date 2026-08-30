# Loki — Central Log Storage

## Purpose

Loki is the homelab log store used for central investigation, dashboards, alerting and security evidence. It receives labelled log streams from Grafana Alloy and other supported collectors so operational evidence does not remain isolated on individual hosts or containers.

## Current homelab role

Loki runs on both TestServer (`main`) and `ids-01`. The live Grafana instance on `ids-01` uses the local Loki container as its primary Loki datasource.

```text
Hosts / containers / security services
              |
              v
         Grafana Alloy
              |
              v
             Loki
              |
              +--> Grafana dashboards
              +--> log-backed alerts
              +--> security investigation
              +--> AI/SecOps evidence readers
```

The `ids-01` logging path includes streams for Pi-hole, Unbound, CrowdSec, CrowdSec Local API, the firewall bouncer and Greenbone review output. Stable labels are important because dashboards and scripts query those labels directly.

## Dependencies

Loki depends on reliable storage, the Docker runtime on the host, valid collector configuration and network reachability from Alloy. Grafana and security/reporting consumers depend on Loki being available and on expected streams continuing to arrive.

## Monitoring and health

Health must cover more than whether the container is running. Validate:

- the Loki process is reachable;
- Grafana can query the datasource;
- expected streams contain recent entries;
- Alloy is not reporting rejected or failed writes;
- storage has sufficient free space;
- ingestion has not silently stopped for critical streams.

A healthy Loki container with stale streams is an ingestion failure, not a healthy logging service.

## Data, backup and recovery

Loki data is operational evidence and should be treated as persistent state. Recovery priorities are:

1. restore the authoritative Compose/configuration;
2. restore persistent Loki data where retention of historical evidence is required;
3. restore Alloy collectors;
4. confirm current ingestion before relying on dashboards or reports.

Where historical logs are not part of the restore objective, the service can be rebuilt from configuration, but loss of retained security/incident evidence must be explicitly accepted.

## Security

Loki should remain infrastructure-only unless there is a deliberate authenticated publishing requirement. Logs can contain internal hostnames, IP addresses, usernames, request paths and security evidence, so unrestricted access is inappropriate.

## Change and maintenance rules

- Preserve stable labels used by dashboards, alerts and scripts.
- Validate ingestion after collector or logging-driver changes.
- Do not assume a container restart proves log recovery.
- Check storage growth and retention before increasing collection scope.
- Keep host-specific monitoring stacks distinct where their Compose definitions differ.

## Related documentation

- [Grafana Alloy](alloy.md)
- [Grafana](grafana.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Log ingestion and Grafana email recovery SOP](../sop/log-ingestion-and-grafana-email-recovery.md)
- [Service Overviews index](README.md)
