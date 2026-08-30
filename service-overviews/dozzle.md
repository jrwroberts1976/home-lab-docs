# Dozzle — Live Docker Log Viewer

## Purpose

Dozzle provides a lightweight web interface for viewing live Docker container logs during operational troubleshooting.

## Current homelab role

Dozzle runs on TestServer (`main`). It provides convenient short-term access to container stdout/stderr without replacing Loki as the central retained log platform.

```text
Docker container logs
      |
      +--> Dozzle (live operational view)
      |
      +--> Alloy/Loki where centrally collected
```

## Dependencies

Dozzle depends on Docker API/socket access and the host's container logging configuration.

## Monitoring and health

Check that the Dozzle container is running, the UI is reachable from the intended network and expected running containers appear. Missing logs may be an application logging issue rather than a Dozzle fault.

## Backup and recovery

Dozzle is largely stateless/configuration-driven. Restore the Compose definition and required Docker access. Historical log recovery belongs to Loki or the underlying logging system, not Dozzle.

## Security

Docker logs can contain internal addresses, request details and occasionally sensitive application output. Dozzle access should be restricted. Docker socket/API access granted to the container is highly privileged and should be treated as a security boundary.

## Change and maintenance rules

- Do not treat Dozzle as the retained audit log.
- Investigate applications that emit secrets to stdout/stderr.
- Validate Docker access after container/runtime changes.
- Keep public exposure disabled unless there is a strong, protected requirement.

## Related documentation

- [Loki](loki.md)
- [Grafana Alloy](alloy.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
