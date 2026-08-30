# CrowdSec — Threat Detection and Enforcement

## Purpose

CrowdSec detects hostile or suspicious behaviour and produces security decisions that can be enforced by a firewall bouncer. It adds behavioural and community-intelligence-based protection to the homelab.

## Current homelab role

The Docker container inventory records the CrowdSec engine on TestServer (`main`). The wider homelab also uses CrowdSec components on `ids-01`, including the engine/Local API path and firewall-bouncer telemetry documented by the security reporting stack.

```text
logs / events
    |
    v
 CrowdSec engine
    |
    +--> local decisions
    +--> community intelligence
    |
    v
firewall bouncer
    |
    v
network enforcement
```

Prometheus metrics and Loki streams are used to distinguish detections, decisions and actual blocked traffic.

## Dependencies

CrowdSec depends on trustworthy log/event input, its Local API, the firewall bouncer and network/firewall integration. Reporting also depends on Prometheus and Loki evidence being current.

## Monitoring and health

Check separately:

- CrowdSec engine health;
- Local API reachability;
- bouncer authentication/health;
- current decision activity;
- actual blocked packet/source evidence;
- Loki stream freshness.

A decision count does not by itself prove packets were blocked, and blocked packets do not imply a successful compromise.

## Backup and recovery

Restore configuration, acquisition/scenario definitions, bouncer configuration and required credentials from protected sources. After recovery, prove the Local API and bouncer are authenticated and confirm fresh telemetry reaches the monitoring/reporting path.

## Security

CrowdSec and its bouncer sit on a security boundary. API credentials, firewall authority and configuration must be protected. Changes should be scoped narrowly and validated to avoid accidentally blocking legitimate traffic or disabling enforcement.

## Change and maintenance rules

- Preserve stable Loki labels used by security readers.
- Validate CrowdSec configuration before restart.
- Verify bouncer operation after engine/API changes.
- Keep detection, decision and enforcement metrics conceptually separate.

## Related documentation

- [Daily Security & Recovery Reporting](daily-security-and-recovery-reporting.md)
- [Grafana Alloy](alloy.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [ids-01 Service and Timer Inventory](ids-01-service-inventory.md)
- [Service Overviews index](README.md)
