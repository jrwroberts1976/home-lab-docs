# Homelab Defender Monitoring Baseline — 26 August 2026

This document records the validated monitoring path for the Jenkins-delivered Homelab Defender workload and the source-of-truth boundaries established before adding Grafana dashboards and alerts.

## Scope

The objective was to confirm whether the existing homelab monitoring platform could observe the Kubernetes workload without installing additional exporters or changing the cluster.

No Kubernetes object, Prometheus scrape target, Grafana runtime, Jenkins job, registry or application deployment was changed during this validation.

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

No new Kubernetes exporter and no new scrape target are required for deployment/readiness/restart monitoring.

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

## Grafana provisioning paths

The live Grafana container on `ids-01` mounts:

```text
/home/james/docker/data/monitoring/grafana/data
    -> /var/lib/grafana

/home/james/docker/data/monitoring/grafana/dashboards
    -> /etc/grafana/dashboards

/home/james/docker/data/monitoring/grafana/provisioning
    -> /etc/grafana/provisioning
```

The `homelab` file provider imports dashboards from:

```text
/etc/grafana/dashboards
```

Existing dashboard JSON uses a datasource variable named `${DS_PROMETHEUS}`. New dashboard JSON should follow that convention rather than hard-coding the Prometheus UID.

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

The small active `pihole-policy-alerts.yml` file is not a complete representation of the live alert-rule inventory. Selected YAML provisioning files may still manage notification-policy or historical configuration, while Grafana-managed rules are persisted by Grafana after API deployment.

## Corrected source ownership

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
| Live Grafana deployment state | `ids-01:/home/james/docker/data/monitoring/grafana` |

The live `ids-01:/home/james/docker` tree remains deployment state and is not itself a Git checkout.

## Host-specific monitoring stacks

The TestServer and `ids-01` monitoring Compose files are materially different and should not be treated as two copies of one host-independent file.

The `ids-01` stack includes its own Grafana, Prometheus, Loki, WUD, Blackbox Exporter, `monitoring` Docker network and host-specific bindings and mounts. The TestServer stack has different service composition, bindings and network ownership.

Do not overwrite either host's monitoring Compose file with the other merely to remove drift.

## Release identity finding

`kube_pod_container_info` provides release metadata, but the current labels are not all equally authoritative.

The current pod reported:

```text
image      = 192.168.2.220:5000/homelab-defender:12
image_id   = 192.168.2.220:5000/homelab-defender@sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a
image_spec = 192.168.2.220:5000/homelab-defender:14@sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a
```

The digest-pinned `image_spec` matches the approved build `14` deployment. The separate `image` label reports tag `12` and must not be used by itself as the release number.

Dashboard release visibility should therefore prefer `image_spec` and `image_id`.

## Resource telemetry finding

The live `ids-01` Prometheus instance returned no Defender series for:

```text
container_cpu_usage_seconds_total{namespace="homelab-defender-test",container="homelab-defender"}
container_memory_working_set_bytes{namespace="homelab-defender-test",container="homelab-defender"}
```

The first Defender Grafana dashboard should therefore not include CPU/memory panels based on assumed Prometheus series. Resource usage remains available as a point-in-time Kubernetes Metrics API sample through `kubectl top`.

CPU/memory dashboarding can be added later if kubelet/cAdvisor resource series are deliberately exposed to the live Prometheus path.

## Planned Grafana assets

The corrected Git-owned source layout should use the existing Grafana repository, for example:

```text
grafana-alerting/
  dashboards/
    homelab-defender-kubernetes.json
  rules/
    homelab-defender-deployment-unavailable.json
    homelab-defender-restart.json
```

A not-ready rule may be added separately or aligned with the existing K3s workload-unready rule after checking for overlap.

## Dashboard target

The first Defender dashboard should show at least:

- deployment health;
- desired replicas;
- available replicas;
- pod/container ready state;
- pod phase;
- current restart total;
- new restarts over a short window; and
- current release/image identity using `image_spec`/`image_id`.

CPU and memory are deferred until the required time-series data is present in the live Prometheus datasource.

## Alert design

The first service-specific alerts should detect state change and operational impact rather than static historical counters.

### Deployment unavailable

Conceptually:

```promql
kube_deployment_status_replicas_available{
  namespace="homelab-defender-test",
  deployment="homelab-defender"
}
<
kube_deployment_spec_replicas{
  namespace="homelab-defender-test",
  deployment="homelab-defender"
}
```

### New container restart

Conceptually:

```promql
increase(
  kube_pod_container_status_restarts_total{
    namespace="homelab-defender-test",
    container="homelab-defender"
  }[10m]
) > 0
```

The existing restart total of `8` is historical state and must not itself create a new alert. A subsequent increase should be observable and eligible to notify.

Existing homelab alert rules commonly evaluate every 60 seconds and route using labels such as `severity` and `category`.

## Restart interpretation

The Defender pod showed `8` restarts. `kube-state-metrics` showed `31` restarts, with the latest restart times appearing broadly aligned.

That snapshot is consistent with a possible wider node or service restart, but it is not sufficient evidence to attribute a root cause. Future alert handling should correlate Defender restarts with node, Kubernetes and monitoring-service events before classifying an application incident.

## Change rule

For the next stage:

1. create the Defender dashboard/rule candidates in a clean branch of `grafana-alerting`;
2. validate dashboard and rule JSON with `jq`;
3. execute candidate PromQL against the live `ids-01` Prometheus datasource;
4. preserve existing Grafana rule state as rollback evidence;
5. deploy alert rules through the existing Grafana provisioning API using the protected token pattern;
6. deploy dashboard JSON to the existing `ids-01` dashboard mount;
7. confirm Grafana accepts the dashboard and rules without errors;
8. verify alert evaluation without creating noise from the existing restart total; and
9. record the final deployed state in `home-lab-docs`.

## Related service overview

See [Homelab Defender](../service-overviews/homelab-defender.md) for the service-level operational context.
