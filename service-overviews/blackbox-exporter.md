# Blackbox Exporter — Availability Probing

## Purpose

Blackbox Exporter performs active network and application probes on behalf of Prometheus. It is used to test whether an endpoint is reachable from the monitoring host rather than only checking whether the target process claims to be running.

## Current homelab role

Blackbox Exporter runs in the monitoring stacks on both TestServer (`main`) and `ids-01`.

```text
Prometheus
    |
    v
Blackbox Exporter
    |
    +--> HTTP / HTTPS probes
    +--> TCP probes
    +--> ICMP-style reachability probes where configured
    |
    v
probe metrics -> Prometheus -> Grafana / alerting
```

## Why it matters

Process health and user-visible availability are different. A web container can be running while DNS, TLS, routing, reverse proxying or the application endpoint is broken. Blackbox probes provide evidence from the monitoring path itself.

## Dependencies

The exporter depends on network reachability, DNS where hostnames are probed, valid probe configuration and any permissions required by the selected probe type. Prometheus supplies the target parameters and stores the resulting metrics.

## Monitoring and health

Monitor both the exporter target itself and the results of probes. A failed probe should be distinguished from an exporter outage. Useful evidence includes probe success, latency, HTTP status, TLS information and DNS/connection timing where configured.

## Backup and recovery

Blackbox Exporter is configuration-driven and has no significant persistent data. Recovery consists of restoring its Compose/configuration, starting the container and proving known-good probes from Prometheus.

## Security

Probe configuration can reveal internal service names and network targets. Keep the exporter infrastructure-only and avoid turning it into an unrestricted network-scanning endpoint.

## Change and maintenance rules

- Add probes deliberately and document their purpose.
- Avoid excessive probe frequency that creates synthetic traffic or load.
- Re-test expected probes after DNS, TLS, reverse-proxy or network changes.
- Keep host-specific probe viewpoints where they provide useful independent evidence.

## Related documentation

- [Prometheus](prometheus.md)
- [Grafana Alerting](grafana-alerting.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
