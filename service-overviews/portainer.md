# Portainer — Docker Management and Agent Access

## Purpose

Portainer provides a web-based management and visibility interface for Docker. The homelab inventory includes both the Portainer server and `portainer-agent`; this page covers the logical Portainer service as a whole.

## Current homelab role

Both `portainer` and `portainer-agent` run on TestServer (`main`).

```text
administrator
     |
     v
  Portainer
     |
     v
Portainer Agent / Docker endpoint
     |
     v
 containers / networks / volumes
```

Portainer is useful for observation and operational troubleshooting, but Git/Compose should remain authoritative for services that are managed as code.

## Dependencies

Portainer depends on Docker, its persistent application data and access to the managed Docker endpoint/agent.

## Monitoring and health

Validate:

- both server and agent containers are running where required;
- the Portainer UI is reachable only from intended networks;
- the Docker endpoint is connected;
- expected containers/networks are visible;
- authentication works.

## Backup and recovery

Preserve Portainer persistent data if retaining users, endpoints and settings matters. Recovery should restore the Compose definition and data, reconnect the endpoint and confirm visibility. Do not use Portainer-only state as the sole recovery source for production Compose services.

## Security

Portainer has powerful Docker management authority. Administrative access must be tightly controlled, and its Docker/agent access should never be publicly exposed. Compromise of Portainer can effectively become compromise of the Docker host.

## Change and maintenance rules

- Prefer Git/Compose changes for code-managed workloads.
- Avoid creating undocumented production containers manually through the UI.
- Validate agent connectivity after networking changes.
- Back up Portainer state before major upgrades.

## Related documentation

- [Docker Container Inventory](docker-container-inventory.md)
- [WUD](wud.md)
- [Jenkins](jenkins.md)
- [Service Overviews index](README.md)
