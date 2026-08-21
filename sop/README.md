# Standard Operating Procedures (SOPs)

This section contains repeatable operational procedures for running and supporting the homelab safely and consistently.

## Current SOPs

- [Log Ingestion and Grafana Alert Email Recovery](log-ingestion-and-grafana-email-recovery.md) — recovery and validation steps for Greenbone, Pi-hole/Unbound, CrowdSec/LAPI Loki ingestion and Grafana SMTP/Docker DNS failures.
- [Pi-hole Policy Alert Latency Improvement Runbook](pihole-policy-alert-latency.md) — staged plan to reduce policy-alert delay, measure each change, reject NFS-mounted live SQLite, harden collectors, validate both Pi-hole nodes, and roll back safely if required.

SOPs should be task-focused and include where relevant:

- purpose and scope
- prerequisites
- exact operational steps
- validation checks
- rollback or recovery actions
- expected evidence or outputs
- related monitoring and alerts
- links to relevant Service Overview and SCP documents

Existing operational documents will be progressively classified here without breaking established links.
