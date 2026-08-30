# AutoKuma — Uptime Kuma Monitor Automation

## Purpose

AutoKuma automates the creation and maintenance of Uptime Kuma monitors from service definitions, reducing manual duplication and helping availability monitoring follow the deployed application estate.

## Current homelab role

AutoKuma runs on TestServer (`main`) alongside Uptime Kuma.

```text
service/container definitions
          |
          v
       AutoKuma
          |
          v
     Uptime Kuma
          |
          v
availability checks
```

## Dependencies

AutoKuma depends on access to the service metadata/configuration it uses for discovery and on connectivity/authentication to Uptime Kuma. Where Docker metadata is used, Docker access is security-sensitive.

## Monitoring and health

Check that:

- the AutoKuma container is running;
- it can reach Uptime Kuma;
- expected monitors are created/updated;
- retired services do not leave unintended stale monitors;
- automation errors are visible in logs.

The most useful validation is the resulting monitor state in Uptime Kuma, not only the AutoKuma container status.

## Backup and recovery

AutoKuma itself is primarily configuration-driven. Recovery consists of restoring its Compose/configuration and credentials, then confirming it reconciles Uptime Kuma to the expected monitor set. Uptime Kuma persistent state has its own recovery requirements.

## Security

Protect credentials used to control Uptime Kuma. If Docker access is granted, scope it as narrowly as the product/runtime permits and do not expose AutoKuma externally without a deliberate need.

## Change and maintenance rules

- Treat automation labels/configuration as authoritative for automated monitors.
- Validate deletions as carefully as creations.
- Avoid manually fighting monitors that AutoKuma owns; change the source definition instead.
- Reconcile after service rename or migration.

## Related documentation

- [Uptime Kuma](uptime-kuma.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
