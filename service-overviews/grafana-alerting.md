# Grafana Alerting

## Purpose

Grafana on `ids-01` is the central alert-evaluation and email-notification service for the homelab.

## Runtime ownership

- Host: `ids-01`
- Container: `grafana`
- Image: `grafana/grafana:13.2.0`
- Host port: `3001` -> container port `3000`
- Compose stack: `/home/james/docker/stacks/monitoring`
- Docker network: `monitoring`
- Default receiver: `Homelab Email Alerts`
- Git-managed alert source: `jrwroberts1976/grafana-alerting`

The live Grafana container shares the `monitoring` Docker network with Prometheus and Loki.

## Datasources

The live datasource identities recorded on 26 August 2026 are:

```text
Prometheus | PBFA97CFB590B2093 | prometheus | http://prometheus:9090
Loki       | P8E80F9AEF21F6940 | loki       | http://loki:3100
```

The Prometheus datasource is the live operational metrics path used by Grafana for Homelab Defender and other infrastructure alerts.

## Alert source and persistence model

The `jrwroberts1976/grafana-alerting` repository is the Git source for Grafana-managed alert definitions. Rule definitions are stored under `rules/`, and the repository's deployment workflow creates or updates them through Grafana's provisioning API.

The active Grafana rules are persisted by Grafana in its database. Inspection of the live `alert_rule` table confirmed fields including rule UID, title, condition, query data, folder UID, group, no-data/error state, duration, annotations and labels.

This means the live database is runtime state, not the authoring interface. Do not create or modify rules by writing directly to `grafana.db`.

Selected YAML files under `/home/james/docker/data/monitoring/grafana/provisioning/alerting` may still provide notification-policy or historical provisioning material. The presence or size of one YAML file must not be treated as a complete inventory of live alert rules.

## Existing rule conventions

Current rules demonstrate two common Grafana models:

- a single Prometheus query used directly as the rule condition; and
- a Prometheus query followed by Grafana reduce/threshold expressions.

The live Prometheus datasource UID used by existing rules is:

```text
PBFA97CFB590B2093
```

The standard infrastructure alert folder is:

```text
UID: homelab-alerts
Name: Homelab Alerts
```

Existing rules commonly evaluate every 60 seconds and use labels such as:

```text
severity=critical|warning
category=availability|performance|...
```

Those labels are used by the existing notification-policy routing.

## API deployment and protected token

Existing scripts in `home-lab-docs/configuration/ids-01/grafana-token-consumers/` demonstrate the supported API deployment model.

They use:

```text
GRAFANA_URL=http://localhost:3001
GRAFANA_TOKEN_FILE=/home/james/docker/secrets/grafana-api-token
```

An explicitly supplied `GRAFANA_TOKEN` can override the file source. The token itself is never embedded in the scripts or documentation.

The deployment pattern is:

1. validate the candidate definition;
2. query the provisioning API for the target rule UID;
3. update the existing rule when present or create it when absent;
4. verify the resulting definition and evaluation state; and
5. leave unrelated historical rules untouched.

## Dashboard relationship

The `grafana-alerting` repository also contains a `dashboards/` directory, so reusable Grafana dashboard JSON belongs with the existing Grafana source rather than in the host-specific monitoring Compose repository.

The live Grafana file provider imports dashboards from:

```text
/home/james/docker/data/monitoring/grafana/dashboards
    -> /etc/grafana/dashboards
```

Existing dashboards use a Grafana datasource variable named `${DS_PROMETHEUS}` rather than hard-coding the Prometheus UID. New dashboard JSON should follow that convention where practical.

## SMTP credential delivery

The Gmail application password is supplied through a Docker Compose secret using:

```text
GF_SMTP_PASSWORD__FILE=/run/secrets/grafana_smtp_password
```

The source secret remains outside Git under `/home/james/docker/secrets`. Its parent directory is mode `0700`; the file is mode `0444` so the non-root Grafana container can read the bind mount while other host users cannot traverse the protected directory.

## Validation completed

On 24 August 2026, direct Gmail authentication, Grafana secret loading, Grafana health and contact-point email delivery all passed. All 29 rules, including four K3s compliance rules, survived the scoped recreation. No direct password remained in active Compose, `.env` or runtime, and 303 retired plaintext Compose copies were removed.

On 26 August 2026, the live Grafana database and datasource configuration were inspected read-only. This confirmed the Prometheus/Loki datasource UIDs, API-managed live alert-rule persistence and the existing `homelab-alerts` folder/group conventions without changing Grafana state.

## Recovery rule

Documentation may record secret names, protected file paths, datasource UIDs and required permissions, but never credential values.

After changing the SMTP secret, recreate only Grafana and verify health, secret loading and contact-point delivery.

After changing alert definitions, deploy through the provisioning API, verify evaluation state and preserve rollback evidence. Do not edit the Grafana SQLite database directly.
