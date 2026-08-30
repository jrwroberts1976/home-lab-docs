# File Browser — Web File Access

## Purpose

File Browser provides web-based access to selected files and directories in the homelab. It is an operational convenience layer over explicitly mounted storage, not a replacement for backup or source control.

## Current homelab role

The `filebrowser` container runs on TestServer (`main`). Its effective scope is defined by the host paths/volumes mounted into the container and the permissions granted to its runtime identity.

## Dependencies

File Browser depends on Docker, persistent application configuration where used, the availability of mounted host storage and correct filesystem permissions.

## Monitoring and health

Validate:

- the container is running;
- the web interface is reachable from intended networks;
- authentication works;
- expected directories are visible;
- write operations are available only where deliberately permitted.

## Backup and recovery

Back up File Browser configuration/database if it contains users or settings that must persist. The files exposed through File Browser must be protected according to their own backup requirements; File Browser does not create a backup simply by making them accessible.

## Security

The service can expose host files and therefore needs strict mount boundaries and access control. Avoid broad mounts such as the whole host filesystem. Do not expose secret-bearing directories unless there is an explicit, protected operational reason.

## Change and maintenance rules

- Review mounts before deployment changes.
- Prefer read-only mounts when write access is unnecessary.
- Validate ownership/permissions after host migrations.
- Keep access limited to intended users/networks.

## Related documentation

- [Docker Container Inventory](docker-container-inventory.md)
- [Restic](restic.md)
- [Service Overviews index](README.md)
