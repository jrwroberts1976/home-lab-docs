# Grafana — Dashboards, Investigation and Alerting

## Purpose

Grafana is the main human-facing observability service for the homelab. It provides dashboards, datasource exploration, central alert evaluation and email notification workflows.

## Current homelab role

The live Grafana service runs on `ids-01`.

Its primary datasources are the local monitoring-stack services:

```text
Prometheus on ids-01 ---> Grafana ---> dashboards / metric alerts
Loki on ids-01 --------> Grafana ---> log search / log-backed views
```

The live Prometheus datasource uses `http://prometheus:9090` and the live Loki datasource uses `http://loki:3100` inside the monitoring Docker network.

## Responsibilities

Grafana is used for:

- infrastructure and service dashboards;
- Prometheus metric exploration;
- Loki log investigation;
- alert-rule evaluation;
- notification routing;
- email delivery for operational/security alerts.

Grafana is not the original source of metrics or logs; it depends on Prometheus, Loki and their upstream collectors.

## Dependencies

Critical dependencies include:

- Docker runtime and the `ids-01` monitoring network;
- Prometheus and Loki;
- DNS for SMTP and any external integrations;
- protected SMTP credentials;
- protected API credentials used by deployment scripts;
- persistent Grafana state and/or Git-managed provisioned assets.

## Monitoring and health

Validate:

- Grafana is reachable;
- Prometheus and Loki datasources query successfully;
- alert rules evaluate without datasource errors;
- notification routing is healthy;
- SMTP DNS resolution works inside the container;
- a contact-point test email is received after material mail-path changes.

A running Grafana container does not prove alert delivery. The August 2026 SMTP incident demonstrated that stale Docker DNS could allow Grafana itself to run while email notifications failed.

## Backup and recovery

Recovery must restore:

1. the authoritative monitoring Compose definition;
2. Grafana persistent data or provisioned configuration as appropriate;
3. protected SMTP/API secrets from their secure recovery sources;
4. datasource connectivity;
5. alert rules and notification policies;
6. a successful end-to-end test notification.

## Security

Grafana has visibility into broad infrastructure and security telemetry. Administrative access, API tokens and SMTP credentials must be protected. Secrets are delivered outside Git and have SOPS/age recovery sources where documented.

## Change and maintenance rules

- Prefer Git-managed/provisioned alert definitions where available.
- Validate datasources after monitoring-stack network changes.
- Test email delivery after DNS, SMTP or secret changes.
- Treat dashboard correctness and alert correctness as separate validation tasks.

## Related documentation

- [Grafana Alerting](grafana-alerting.md)
- [Prometheus](prometheus.md)
- [Loki](loki.md)
- [Grafana Alloy](alloy.md)
- [Grafana Alert Email Standard](../grafana-alert-email-standard.md)
- [Service Overviews index](README.md)
