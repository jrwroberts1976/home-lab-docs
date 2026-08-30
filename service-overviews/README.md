# Service Overviews

This section explains the services that make up the homelab, how they fit together, and how they are operated and protected.

## Core infrastructure and automation

- [OpenTofu — Infrastructure as Code](opentofu.md) — Infrastructure-as-Code role, Proxmox integration, state, security, recovery and controlled change.
- [Jenkins — CI/CD Controller and Docker Build Runtime](jenkins.md) — logical Jenkins service covering both `jenkins` and `jenkins-docker`, build/runtime dependencies, authority boundaries and recovery.
- [Jenkins Operations](../jenkins/README.md) — detailed operational ownership, delivery boundaries, platform baselines, controlled updates and recovery planning.
- [Docker Container Inventory](docker-container-inventory.md) — host/container purpose inventory with a required Service Overview link for every listed service.

## Monitoring, logging and observability

- [Prometheus — Metrics Collection and Time-Series Monitoring](prometheus.md) — two-instance monitoring topology, exporters, scrape health, TSDB state and change control.
- [Grafana — Dashboards, Investigation and Alerting](grafana.md) — live `ids-01` dashboard service, datasources, alerting dependencies and recovery.
- [Grafana Alerting](grafana-alerting.md) — central alert evaluation, Git-managed rules, protected API-token use, SMTP delivery and notification validation.
- [Grafana Alloy — Log Collection and Routing](alloy.md) — active log collection/routing, stable Loki labels, source selection, permissions and ingestion validation.
- [Loki — Central Log Storage](loki.md) — central log storage, ingestion dependencies, retained evidence and recovery expectations.
- [cAdvisor — Docker Container Telemetry](cadvisor.md) — container CPU/memory/filesystem/network metrics and the three-layer container/network/scrape health model.
- [Blackbox Exporter — Availability Probing](blackbox-exporter.md) — HTTP/HTTPS/TCP/ICMP-style probe role and interpretation of probe versus exporter failure.
- [What's Up Docker (WUD)](wud.md) — image-update discovery, registry/DNS dependencies and its advisory role within controlled image governance.
- [Uptime Kuma — Service Availability Monitoring](uptime-kuma.md) — service reachability/history monitoring and notification-path validation.
- [AutoKuma — Uptime Kuma Monitor Automation](autokuma.md) — automated monitor reconciliation and ownership boundaries.
- [SmokePing — Network Latency and Packet-Loss Monitoring](smokeping.md) — long-term network latency/loss trend evidence.
- [LibreSpeed — Internal Throughput Testing](librespeed.md) — on-demand internal network throughput testing.

## Security, identity and DNS policy

- [CrowdSec — Threat Detection and Enforcement](crowdsec.md) — detection, Local API, bouncer enforcement and security telemetry interpretation.
- [Authelia — Authentication and Access Control](authelia.md) — authentication/policy layer for selected reverse-proxied services.
- [Pi-hole — DNS Filtering and Policy Enforcement](pihole.md) — multi-node Pi-hole role, filtering, resilience, monitoring and recovery.
- [Unbound — Recursive DNS Resolver](unbound.md) — recursive resolver role upstream of Pi-hole and primary/secondary DNS paths.
- [Nebula Sync — Pi-hole Configuration Replication](nebula-sync.md) — selected Pi-hole configuration replication between primary and secondary services.
- [AI Security Review](ai-security-review.md) — Loki/Prometheus evidence sources and AI-assisted Greenbone/security review path.
- [Daily Security & Recovery Reporting](daily-security-and-recovery-reporting.md) — report-generation chains, dual-Pi-hole evidence and recovery assurance.

## Network edge and remote access

- [Nginx Proxy Manager — Reverse Proxy and TLS Edge](nginx-proxy-manager.md) — published-service routing, TLS termination, persistence and access-boundary controls.
- [DuckDNS — Dynamic DNS](duckdns.md) — DuckDNS record maintenance for changing WAN addresses.
- [Cloudflare DDNS — Dynamic Cloudflare DNS Updates](cloudflare-ddns.md) — Cloudflare DNS API update path and credential scope.

## Docker operations and file access

- [Portainer — Docker Management and Agent Access](portainer.md) — covers both `portainer` and `portainer-agent`, Docker authority and recovery.
- [Dozzle — Live Docker Log Viewer](dozzle.md) — live container-log troubleshooting and distinction from retained Loki logging.
- [File Browser — Web File Access](filebrowser.md) — controlled web access to explicitly mounted host files/directories.

## Applications and user-facing services

- [BirdNET-Go — Bird Audio Detection](birdnet-go.md) — current bird-detection workload and planned garden-room Raspberry Pi 4 placement.
- [Engineering Portfolio — Public Project Site](engineering-portfolio.md) — public portfolio application, guarded deployment and published-service dependencies.
- [Maintenance Page — Controlled Service-Change Fallback](maintenance-page.md) — all-path maintenance fallback used during controlled public application changes.
- [Homelab Defender](homelab-defender.md) — Jenkins-delivered Kubernetes application ownership, runtime architecture, monitoring and release identity.

## Backup, recovery and host ownership

- [Restic — Backup and Recovery](restic.md) — central `ids-01` Rest Server, scheduled backups, health monitoring, credential recovery and restore assurance.
- [SOPS and age secret recovery](sops-and-age-secret-recovery.md) — encrypted recovery architecture and tested secret-recovery controls.
- [ids-01 Service and Timer Inventory](ids-01-service-inventory.md) — active services/timers, ownership boundaries, retired duplicates and cleanup evidence.

## Coverage rule

Every logical service listed in [Docker Container Inventory](docker-container-inventory.md) must have a Service Overview. Multiple runtime rows may link to the same overview when they are instances or components of one logical service, for example:

- TestServer and `ids-01` Prometheus instances -> `prometheus.md`;
- `portainer` and `portainer-agent` -> `portainer.md`;
- `jenkins` and `jenkins-docker` -> `jenkins.md`.

When a new container/service is added to the inventory, its overview must be created or linked as part of the same documentation change.

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
