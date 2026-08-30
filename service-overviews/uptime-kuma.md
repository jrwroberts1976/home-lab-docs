# Uptime Kuma — Service Availability Monitoring

## Purpose

Uptime Kuma provides human-readable availability monitoring for homelab applications and infrastructure endpoints. It complements Prometheus by focusing on whether a service can actually be reached and used from the monitoring point of view.

## Current homelab role

Uptime Kuma runs on TestServer (`main`). It monitors selected HTTP, HTTPS, TCP and other service endpoints and presents availability history and status information.

```text
Homelab services
      |
      v
 Uptime Kuma
      |
      +--> availability history
      +--> operational status
      +--> notifications where configured
```

AutoKuma is used alongside it to automate monitor creation for services that can be described from container metadata or configuration.

## Dependencies

Uptime Kuma depends on Docker, persistent application state, DNS/network reachability to monitored targets and any configured notification integrations.

## Monitoring and health

A healthy Uptime Kuma service means:

- the container is running;
- the web interface is reachable;
- monitor checks are executing;
- expected monitors are present;
- recent monitor results are being recorded;
- notification paths are tested after material changes.

Monitor failures must be interpreted in context: they can indicate the target is down, DNS is broken, routing is broken, or the monitoring service itself has a problem.

## Backup and recovery

Uptime Kuma has persistent configuration/history that should be backed up if preserving monitor definitions and history matters. Recovery should restore the authoritative Compose definition and persistent data, then verify representative monitors.

## Security

The service reveals internal endpoint names and availability. Administrative access should be protected and unnecessary external publication avoided.

## Change and maintenance rules

- Keep monitor names meaningful and aligned with actual services.
- Remove stale monitors when services are retired.
- Test notification paths after changes.
- Avoid using Uptime Kuma as the only source of health evidence for critical services.

## Related documentation

- [AutoKuma](autokuma.md)
- [Blackbox Exporter](blackbox-exporter.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
