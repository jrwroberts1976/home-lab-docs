# Service Overviews

This section explains the services that make up the homelab, how they fit together, and how they are operated and protected.

## Current service overviews

- [Homelab Defender](homelab-defender.md) — Jenkins-delivered Kubernetes application ownership, runtime architecture, monitoring path, release identity, Grafana alerting and current telemetry limitations.
- [Jenkins Operations](../jenkins/README.md) — operational ownership, delivery boundaries, platform baselines, controlled updates, validation and recovery planning for Jenkins, DinD, Trivy, registry publication and K3s deployment.
- [OpenTofu — Infrastructure as Code](opentofu.md) — explains what OpenTofu is, why the homelab is adopting Infrastructure as Code, how OpenTofu, Proxmox, Ansible and Jenkins fit together, and the state, security, recovery and change-control model.
- [Grafana Alloy — Log Collection and Routing](alloy.md) — active log collection and routing, stable Loki labels, durable source selection, permissions, ingestion validation and recovery expectations.
- [Prometheus — Metrics Collection and Time-Series Monitoring](prometheus.md) — two-instance monitoring topology, exporters and custom metrics, scrape health, persistent configuration/TSDB state, security, recovery and change control.
- [Restic — Backup and Recovery](restic.md) — central `ids-01` Rest Server, scheduled DietPi backups and retention, health monitoring and alerts, encrypted credential recovery and restore assurance.
- [BirdNET-Go — Bird Audio Detection](birdnet-go.md) — current bird-detection workload and planned garden-room Raspberry Pi 4 placement, including audio health, DNS coexistence, monitoring, backup, privacy and migration acceptance gates.
- [Grafana Alerting](grafana-alerting.md) — central alert evaluation on `ids-01`, Git-managed rule definitions, provisioning-API deployment, protected API-token use, SMTP-secret delivery and notification validation.
- [Docker Container Inventory](docker-container-inventory.md) — human-readable host/container purpose inventory and monitoring-service relationships.
- [AI Security Review](ai-security-review.md) — documents `homelab-security-reader.py`, its Loki and Prometheus evidence sources, the Greenbone AI review path, and ingestion-health requirements.
- [Daily Security & Recovery Reporting](daily-security-and-recovery-reporting.md) — documents the technical, management and email reporting chains, evidence interpretation rules, dual-Pi-hole event aggregation and report schedules.
- [ids-01 Service and Timer Inventory](ids-01-service-inventory.md) — records active services and timers, systemd/Docker ownership boundaries, retired duplicate collectors and outstanding cleanup work.
- [Nebula Sync — Pi-hole Configuration Replication](nebula-sync.md) — explains how selected Pi-hole configuration is replicated from the DietPi primary to `pihole-secondary` on ids-01, what is and is not synchronised, how the service is monitored, and how to distinguish a real sync failure from a monitoring false positive.
- [SOPS and age secret recovery](sops-and-age-secret-recovery.md) — four-host encrypted recovery architecture, completed offline control and tested recovery operations.

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
