# Grafana Alerting

## Purpose

Grafana on `ids-01` is the central dashboard, alert-evaluation and email-notification service for the homelab.

## Runtime ownership

- Host: `ids-01`
- Container: `grafana`
- Image: `grafana/grafana:13.2.0`
- Host port: `3001` -> container port `3000`
- Compose stack: `/home/james/docker/stacks/monitoring`
- Docker network: `monitoring`
- Default receiver: `Homelab Email Alerts`
- Git-managed Grafana source: `jrwroberts1976/grafana-alerting`

The live Grafana container shares the `monitoring` Docker network with Prometheus and Loki.

## Datasources

The live datasource identities recorded on 26 August 2026 are:

```text
Prometheus | PBFA97CFB590B2093 | prometheus | http://prometheus:9090
Loki       | P8E80F9AEF21F6940 | loki       | http://loki:3100
```

The Prometheus datasource is the live operational metrics path used by Grafana for Homelab Defender and other infrastructure alerts.

## Alert source and persistence model

The `jrwroberts1976/grafana-alerting` repository is the Git source for Grafana-managed alert definitions. Rule definitions are stored under `rules/`, and repository source is deployed to live Grafana through the provisioning API.

The active Grafana rules are persisted by Grafana in its database. Inspection of the live `alert_rule` table confirmed fields including rule UID, title, condition, query data, folder UID, group, no-data/error state, duration, annotations and labels.

The live database is runtime state, not the authoring interface. Do not create or modify rules by writing directly to `grafana.db`.

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
category=availability|performance|stability|...
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
2. validate PromQL against the live Prometheus datasource;
3. merge the Git source before deployment;
4. query the Grafana API for the target rule or dashboard;
5. create or update only the intended object;
6. verify the resulting live definition and evaluation state; and
7. leave unrelated historical rules and dashboards untouched.

## Dashboard source and deployment model

The `grafana-alerting` repository contains a `dashboards/` directory and is the Git source for reusable Grafana dashboard JSON.

The live Grafana file provider also imports dashboards from:

```text
/home/james/docker/data/monitoring/grafana/dashboards
    -> /etc/grafana/dashboards
```

However, the first Homelab Defender dashboard was deliberately deployed through the scoped Grafana dashboard API rather than by copying a file into that provisioned directory.

The deployed source is:

```text
dashboards/homelab-defender-kubernetes.json
```

The source dashboard uses the confirmed Prometheus UID `PBFA97CFB590B2093`. Existing file-provisioned dashboards may use `${DS_PROMETHEUS}`; this API-managed dashboard is documented according to its actual deployed source rather than forcing a different convention after the fact.

## Homelab Defender monitoring deployment — 26 August 2026

The Defender monitoring source was committed as `5a1b65c`, merged through `grafana-alerting#4`, and incorporated into `main` as merge commit `8244758`.

### Dashboard

```text
Title: Homelab Defender Kubernetes Operations
UID: homelab-defender-k8s
API: POST /api/dashboards/db
HTTP: 200
Version: 1
Path: /d/homelab-defender-k8s/homelab-defender-kubernetes-operations
```

The dashboard contains nine state/release panels and intentionally omits CPU/memory because no Defender resource series were present in the live Prometheus datasource.

### Alert rules

`Homelab Defender Deployment Unavailable`:

```text
UID: ffwbnisgmg4cgb
Database ID: 37
folderUID: homelab-alerts
ruleGroup: Homelab Defender
severity: critical
category: availability
for: 2m
noDataState: Alerting
execErrState: Alerting
provenance: api
isPaused: false
HTTP create result: 201
```

`Homelab Defender New Container Restart`:

```text
UID: afwbnisiruz28f
Database ID: 38
folderUID: homelab-alerts
ruleGroup: Homelab Defender
severity: warning
category: stability
for: 1m
noDataState: OK
execErrState: Alerting
provenance: api
isPaused: false
HTTP create result: 201
```

The restart rule uses a ten-minute `increase()` expression so the historical restart total of `8` did not immediately trigger the rule. Both candidate expressions evaluated to `0` before deployment.

The broad repository-wide `deploy-alerts.sh` was not used for this change. The two Defender rules were deployed individually so unrelated live rules could not be reconciled accidentally.

## Post-deployment verification status

The API accepted the dashboard and both rules successfully. A final live retrieval/evaluation check remains required to confirm:

- dashboard retrieval by UID;
- exact live rule definitions;
- healthy/inactive evaluation state for both rules; and
- absence of unexpected notifications.

Until that check completes, the Defender monitoring change is considered deployed successfully at the Grafana configuration/API layer with final operational evaluation verification pending.

## SMTP credential delivery

The Gmail application password is supplied through a Docker Compose secret using:

```text
GF_SMTP_PASSWORD__FILE=/run/secrets/grafana_smtp_password
```

The source secret remains outside Git under `/home/james/docker/secrets`. Its parent directory is mode `0700`; the file is mode `0444` so the non-root Grafana container can read the bind mount while other host users cannot traverse the protected directory.

## Validation history

On 24 August 2026, direct Gmail authentication, Grafana secret loading, Grafana health and contact-point email delivery all passed. All 29 rules, including four K3s compliance rules, survived the scoped recreation. No direct password remained in active Compose, `.env` or runtime, and 303 retired plaintext Compose copies were removed.

On 26 August 2026, the live Grafana database and datasource configuration were inspected read-only. This confirmed the Prometheus/Loki datasource UIDs, API-managed live alert-rule persistence and the existing `homelab-alerts` folder/group conventions without changing Grafana state.

Later on 26 August 2026, the Git-owned Homelab Defender dashboard and two alert rules were deployed through scoped Grafana API calls. No Grafana container restart, Prometheus change, Kubernetes change or Jenkins change was required.

## Recovery rule

Documentation may record secret names, protected file paths, datasource UIDs, dashboard/rule UIDs and required permissions, but never credential values.

After changing the SMTP secret, recreate only Grafana and verify health, secret loading and contact-point delivery.

After changing alert definitions or API-managed dashboards, merge source first, deploy only the intended objects, verify the resulting live state and preserve rollback evidence. Do not edit the Grafana SQLite database directly.
