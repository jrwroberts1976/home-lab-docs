# Homelab Defender Monitoring Baseline — 26 August 2026

This document records the validated monitoring path for the Jenkins-delivered Homelab Defender workload, the source-of-truth boundaries for Grafana assets, and the initial dashboard/alert deployment completed on 26 August 2026.

## Scope

The initial validation confirmed that the existing homelab monitoring platform could observe the Kubernetes workload without installing additional exporters or changing the cluster.

The later implementation stage added only Grafana dashboard/alert configuration through scoped API calls. No Kubernetes object, Prometheus scrape target, Jenkins job, registry, application deployment or Grafana container runtime was changed.

## Workload baseline

The running application was inspected on `k3s-node-01`.

- Namespace: `homelab-defender-test`
- Deployment: `homelab-defender`
- Desired replicas: `1`
- Available replicas: `1`
- Ready replicas: `1/1`
- Pod phase: `Running`
- Container ready: `1`
- Restart total: `8`
- Current approved release: build `14`
- Current approved digest: `sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a`
- Sample resource use from `metrics-server`: approximately `1m` CPU and `166Mi` memory

The Kubernetes Metrics API is already available through `metrics-server`.

`kube-state-metrics` is already deployed in the `monitoring` namespace and exposes the required deployment and pod state.

## Prometheus evidence

The `kube-state-metrics` endpoint is available at:

```text
192.168.2.211:8080
```

Prometheus already stores the Defender state metrics needed for an operational dashboard:

```text
kube_deployment_spec_replicas = 1
kube_deployment_status_replicas_available = 1
kube_pod_container_status_ready = 1
kube_pod_container_status_restarts_total = 8
```

No new Kubernetes exporter and no new scrape target were required for deployment/readiness/restart monitoring.

## Live Grafana path

The live Grafana service runs on `ids-01` rather than TestServer.

Validated runtime:

```text
ids-01
  grafana/grafana:13.2.0
  host port 3001 -> container port 3000
```

Grafana and Prometheus share the Docker network named `monitoring` on `ids-01`.

The live datasource identities are:

```text
Prometheus | PBFA97CFB590B2093 | prometheus | http://prometheus:9090
Loki       | P8E80F9AEF21F6940 | loki       | http://loki:3100
```

From inside the Grafana container:

- `prometheus` resolves successfully;
- the Prometheus readiness endpoint returns ready; and
- a Defender query for `kube_deployment_status_replicas_available` returns `1`.

The validated live data path is therefore:

```text
Homelab Defender on k3s-node-01
        |
        v
kube-state-metrics 192.168.2.211:8080
        |
        v
Prometheus on ids-01
        |
        v
Grafana on ids-01
```

A separate Prometheus instance also exists on TestServer and was independently shown to scrape the same `kube-state-metrics` target successfully. The Grafana operational path documented here uses the `ids-01` Prometheus instance because that is the datasource used by the live Grafana service.

## Alert persistence and deployment model

Read-only inspection of Grafana's `alert_rule` table showed that live Grafana-managed rules are persisted in the Grafana database with their rule UID, condition, query JSON, folder UID, group, labels, annotations, duration and error/no-data state.

Existing rules use the live Prometheus datasource UID:

```text
PBFA97CFB590B2093
```

The existing alert folder UID is:

```text
homelab-alerts
```

Existing rule deployment automation uses Grafana's provisioning API rather than direct SQLite writes. Protected token consumers default to:

```text
GRAFANA_URL=http://localhost:3001
GRAFANA_TOKEN_FILE=/home/james/docker/secrets/grafana-api-token
```

Do not write directly to `grafana.db` to create or change Defender rules.

## Source ownership

The earlier working assumption that reusable Defender Grafana assets should be introduced under `docker-env/stacks/monitoring/grafana` was revised after inspecting the existing repositories.

`jrwroberts1976/grafana-alerting` already exists specifically to store Grafana-managed alert definitions for `ids-01`, deploys them through the provisioning API, contains rule JSON under `rules/`, and also contains a `dashboards/` directory.

The corrected ownership model is:

| Concern | Authoritative source |
|---|---|
| Defender application source and Jenkins delivery | `jenkins-gradle-delivery-lab` |
| Kubernetes desired state and approved release digest | `kubernetes-homelab/applications/homelab-defender-test` |
| Grafana alert definitions and dashboard source | `grafana-alerting` |
| Host-specific monitoring Compose/runtime configuration | `docker-env` plus controlled host deployment state |
| Operational documentation and evidence | `home-lab-docs` |
| Live Grafana deployment state | Grafana runtime on `ids-01` |

The TestServer and `ids-01` monitoring Compose files are materially different and should not be treated as two copies of one host-independent file.

## Release identity finding

`kube_pod_container_info` provides release metadata, but the current labels are not all equally authoritative.

The current pod reported:

```text
image      = 192.168.2.220:5000/homelab-defender:12
image_id   = 192.168.2.220:5000/homelab-defender@sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a
image_spec = 192.168.2.220:5000/homelab-defender:14@sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a
```

The digest-pinned `image_spec` matches the approved build `14` deployment. The separate `image` label reports tag `12` and must not be used by itself as the release number.

Dashboard release visibility therefore uses `image_spec`.

## Resource telemetry finding

The live `ids-01` Prometheus instance returned no Defender series for:

```text
container_cpu_usage_seconds_total{namespace="homelab-defender-test",container="homelab-defender"}
container_memory_working_set_bytes{namespace="homelab-defender-test",container="homelab-defender"}
```

The first Defender Grafana dashboard therefore intentionally omits CPU/memory panels. Resource usage remains available as a point-in-time Kubernetes Metrics API sample through `kubectl top`.

CPU/memory dashboarding can be added later if kubelet/cAdvisor resource series are deliberately exposed to the live Prometheus path.

## Git-owned monitoring assets

The implementation was created in a clean `grafana-alerting` worktree because the existing live checkout on `ids-01` contained substantial unrelated modified and untracked work.

The clean branch was:

```text
monitoring/homelab-defender
```

The source commit was:

```text
5a1b65c Add Homelab Defender Grafana monitoring
```

The change was merged through `grafana-alerting#4` into `main` as:

```text
8244758
```

Exactly three source files were introduced:

```text
dashboards/homelab-defender-kubernetes.json
rules/homelab-defender-deployment-unavailable.json
rules/homelab-defender-new-restart.json
```

The source change contained 293 additions and no unrelated files.

## Pre-deployment validation

Before merge/deployment:

- all three JSON files validated successfully with `jq`;
- all ten distinct dashboard PromQL expressions returned data from the live `ids-01` Prometheus;
- desired replicas returned `1`;
- available replicas returned `1`;
- historical restart total returned `8`;
- deployment-unavailable alert expression returned `0`;
- new-restart alert expression returned `0`;
- no live dashboard existed with UID `homelab-defender-k8s`;
- neither Defender alert title already existed in live Grafana; and
- the protected Grafana API token source was readable without displaying the token.

This proved that the historical restart total of `8` would not itself generate an immediate new restart alert.

## Deployed dashboard

The dashboard was deployed to live Grafana through the dashboard API:

```text
API: POST /api/dashboards/db
HTTP: 200
status: success
uid: homelab-defender-k8s
version: 1
path: /d/homelab-defender-k8s/homelab-defender-kubernetes-operations
```

Dashboard title:

```text
Homelab Defender Kubernetes Operations
```

The dashboard contains nine panels:

1. Available Replicas
2. Desired Replicas
3. Container Ready
4. Running Pods
5. Restart Total
6. New Restarts - 10m
7. Current Release Image
8. Deployment Replica History
9. Container Restart History

The dashboard source uses Prometheus datasource UID `PBFA97CFB590B2093` and displays the current release through `{{image_spec}}`.

The dashboard was not copied into the file-provisioned dashboard mount for this deployment; it was created through the scoped Grafana API.

## Deployed alert rules

The broad repository `deploy-alerts.sh` was deliberately not used because it would iterate across every rule file. The Defender rules were deployed individually through the Grafana provisioning API so unrelated historical rules could not be reconciled accidentally.

### Deployment unavailable

```text
Title: Homelab Defender Deployment Unavailable
Grafana UID: ffwbnisgmg4cgb
Grafana database ID: 37
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

PromQL:

```promql
sum(kube_deployment_spec_replicas{namespace="homelab-defender-test",deployment="homelab-defender"})
-
sum(kube_deployment_status_replicas_available{namespace="homelab-defender-test",deployment="homelab-defender"})
> bool 0
```

### New container restart

```text
Title: Homelab Defender New Container Restart
Grafana UID: afwbnisiruz28f
Grafana database ID: 38
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

PromQL:

```promql
sum(
  increase(
    kube_pod_container_status_restarts_total{
      namespace="homelab-defender-test",
      container="homelab-defender"
    }[10m]
  )
) > bool 0
```

## Post-deployment validation status

The Grafana API accepted the dashboard and both rules successfully. Both rule-create responses returned the expected source definition, `provenance=api` and `isPaused=false`.

The remaining validation step is to retrieve the dashboard/rules from live Grafana after creation and confirm both alert rules evaluate healthy/inactive against the current baseline with no unexpected notification.

Until that check is completed, the deployment is recorded as successful at the source and Grafana configuration/API layers with final operational evaluation verification pending.

## Restart interpretation

The Defender pod showed `8` restarts. `kube-state-metrics` showed `31` restarts, with the latest restart times appearing broadly aligned.

That snapshot is consistent with a possible wider node or service restart, but it is not sufficient evidence to attribute a root cause. Future alert handling should correlate Defender restarts with node, Kubernetes and monitoring-service events before classifying an application incident.

## Change rule

For future Defender monitoring changes:

1. use a clean `grafana-alerting` branch/worktree and do not disturb unrelated live-checkout changes;
2. validate dashboard/rule JSON with `jq`;
3. execute candidate PromQL against the live `ids-01` Prometheus datasource;
4. verify the intended dashboard/rule identities before writing;
5. merge the Git source before live deployment;
6. deploy only the intended Grafana dashboard/rules through scoped API calls;
7. do not write directly to Grafana SQLite;
8. verify live dashboard/rule state and alert evaluation after deployment; and
9. record the final operational evidence in `home-lab-docs`.

## Related service overview

See [Homelab Defender](../service-overviews/homelab-defender.md) for the service-level operational context.
