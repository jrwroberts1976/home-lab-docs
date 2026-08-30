# cAdvisor — Docker Container Telemetry

## Purpose

cAdvisor exposes container resource and runtime metrics so Prometheus can monitor Docker workloads independently of the application inside each container.

## Current homelab role

cAdvisor runs on both TestServer (`main`) and `ids-01` and is scraped by Prometheus. It provides container-level evidence such as CPU, memory, filesystem and network usage that complements host metrics from Node Exporter.

```text
Docker runtime
     |
     v
  cAdvisor
     |
     v
 Prometheus
     |
     v
  Grafana
```

## Monitoring and health

Three layers must be checked when cAdvisor appears down:

1. **container state** — the cAdvisor container is running;
2. **network state** — it is attached to the expected Docker network and/or published port;
3. **scrape state** — Prometheus reports the target as `up=1`.

This distinction is important because an `ids-01` incident on 22 August 2026 showed a running cAdvisor container that was missing its expected Docker network attachment and therefore remained unreachable to Prometheus.

## Dependencies

cAdvisor depends on access to the Docker/container runtime and the host resources required by its container definition. Prometheus depends on stable reachability to its metrics endpoint.

## Backup and recovery

cAdvisor has little application state of its own. Recovery is primarily configuration recovery:

- restore the authoritative Compose definition;
- recreate the container with required mounts/permissions;
- confirm Docker network attachment;
- confirm the metrics endpoint;
- confirm Prometheus target health.

Historical metrics are retained by Prometheus rather than cAdvisor.

## Security

The metrics endpoint can expose detailed workload and resource metadata. It should be reachable only by intended monitoring systems and should not be published externally.

## Change and maintenance rules

- Treat runtime mounts and privileges as security-sensitive.
- Validate Prometheus scrape health after container recreation.
- Do not diagnose cAdvisor solely from `docker ps`.
- Keep TestServer and `ids-01` host-specific networking differences intact.

## Related documentation

- [Prometheus](prometheus.md)
- [Grafana](grafana.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
