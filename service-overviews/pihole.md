# Pi-hole — DNS Filtering and Policy Enforcement

## Purpose

Pi-hole provides DNS filtering, security-policy enforcement and visibility for homelab clients. It blocks known unwanted or policy-restricted domains and is part of the resilient DNS design.

## Current homelab role

The Docker container inventory records the secondary Pi-hole on `ids-01`. The homelab also has the primary DietPi Pi-hole, so Pi-hole must be considered as a multi-node DNS service rather than a single container.

```text
LAN clients
    |
    +--> primary Pi-hole
    |
    +--> secondary Pi-hole on ids-01
              |
              v
           Unbound
              |
              v
       recursive DNS
```

Selected Pi-hole configuration is replicated to the secondary using Nebula Sync. Prometheus collectors and Grafana alerting provide health, blocklist and policy-enforcement evidence.

## Dependencies

Pi-hole depends on reliable host/network availability, upstream Unbound resolution, DNS port availability, configuration/blocklists and synchronisation/recovery of protected settings.

## Monitoring and health

Validate:

- DNS answers are returned from each advertised Pi-hole;
- upstream Unbound resolution works;
- blocklist/configuration collectors are fresh;
- policy test domains behave as expected;
- both DNS servers are advertised to clients;
- failover works when either Pi-hole is unavailable.

## Backup and recovery

Recovery must preserve configuration, local DNS/policy settings and any required credentials. Git-backed configuration and encrypted recovery sources should be used where available. After restore, test real DNS resolution and policy enforcement, not only the web interface.

## Security

Pi-hole is a network security and policy control. Administrative credentials must be protected. DNS should remain limited to intended networks, and changes to blocklists/policy must be reviewed for both security benefit and false-positive impact.

## Change and maintenance rules

- Keep both DNS nodes independently recoverable.
- Synchronise only the configuration that is intentionally shared.
- Validate enforcement after blocklist changes.
- Exclude synthetic test traffic from human activity totals where documented while retaining the enforcement tests themselves.

## Related documentation

- [Unbound](unbound.md)
- [Nebula Sync](nebula-sync.md)
- [Pi-hole Policy Alert Latency SOP](../sop/pihole-policy-alert-latency.md)
- [Daily Security & Recovery Reporting](daily-security-and-recovery-reporting.md)
- [Docker Container Inventory](docker-container-inventory.md)
