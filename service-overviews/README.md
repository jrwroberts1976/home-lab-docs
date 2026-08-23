# Service Overviews

This section explains the services that make up the homelab, how they fit together, and how they are operated and protected.

## Current service overviews

- [AI Security Review](ai-security-review.md) — documents `homelab-security-reader.py`, its Loki and Prometheus evidence sources, the Greenbone AI review path, and ingestion-health requirements.
- [Daily Security & Recovery Reporting](daily-security-and-recovery-reporting.md) — documents the technical, management and email reporting chains, evidence interpretation rules, dual-Pi-hole event aggregation and report schedules.
- [ids-01 Service and Timer Inventory](ids-01-service-inventory.md) — records active services and timers, systemd/Docker ownership boundaries, retired duplicate collectors and outstanding cleanup work.
- [Nebula Sync — Pi-hole Configuration Replication](nebula-sync.md) — explains how selected Pi-hole configuration is replicated from the DietPi primary to `pihole-secondary` on ids-01, what is and is not synchronised, how the service is monitored, and how to distinguish a real sync failure from a monitoring false positive.

Each Service Overview should cover where relevant:

- purpose and scope
- architecture and components
- service owner
- users and consumers
- upstream and downstream dependencies
- availability expectations
- monitoring and alerting
- backup and recovery requirements
- security controls
- maintenance and change considerations
- related SOPs and SCPs

Service Overviews provide the context; SOPs provide the operating steps; SCPs provide the recovery plan.
