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
- Current release: build `14`
- Current image digest: `sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a`
- Sample resource use: approximately `1m` CPU and `166Mi` memory

The Kubernetes Metrics API is already available through `metrics-server`.

`kube-state-metrics` is already deployed in the `monitoring` namespace and exposes the required deployment and pod state.

## Prometheus evidence

The `kube-state-metrics` endpoint is available at:

```text
192.168.2.211:8080
```

Prometheus already stores the Defender metrics needed for an operational dashboard:

```text
kube_deployment_spec_replicas = 1
kube_deployment_status_replicas_available = 1
kube_pod_container_status_ready = 1
kube_pod_container_status_restarts_total = 8
```

No new Kubernetes exporter and no new scrape target are required.

## Live Grafana path

The live Grafana service runs on `ids-01` rather than TestServer.

Validated runtime:

```text
ids-01
  grafana/grafana:13.2.0
  host port 3001 -> container port 3000
```

Grafana and Prometheus share the Docker network named `monitoring` on `ids-01`.

The provisioned Prometheus datasource uses:

```text
http://prometheus:9090
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

Existing provisioned assets confirm the active pattern, including Homelab NOC, software-update, Pi-hole and security dashboards plus provisioned Pi-hole alerting and notification policies.

## Source-of-truth decision

The live `ids-01:/home/james/docker` tree is deployment state and is not itself a Git checkout.

`home-lab-docs` contains the operational documentation and deployment/runbook material, but it does not currently contain the live Grafana dashboard JSON or alert-rule YAML as deployable source.

The `docker-env` repository already owns Docker stack configuration under `stacks/monitoring`. It is therefore the appropriate repository for reusable Grafana configuration assets.

The intended ownership model is:

| Concern | Authoritative source |
|---|---|
| Defender application source and Jenkins delivery | `jenkins-gradle-delivery-lab` |
| Kubernetes desired state and approved release digest | `kubernetes-homelab/applications/homelab-defender-test` |
| Reusable Grafana dashboard and alert configuration | `docker-env/stacks/monitoring/grafana` |
| Operational documentation and evidence | `home-lab-docs/jenkins` |
| Live Grafana deployment state | `ids-01:/home/james/docker/data/monitoring/grafana` |

## Host-specific monitoring stacks

The TestServer and `ids-01` monitoring Compose files are materially different and should not be treated as two copies of one host-independent file.

The `ids-01` stack includes its own Grafana service, WUD integration, `monitoring` Docker network and host-specific bindings and mounts. The TestServer stack has different service composition, bindings and network ownership.

Do not overwrite either host's monitoring Compose file with the other merely to remove drift. Shared Grafana assets should be made reusable while host-specific runtime definitions remain explicit.

## Planned Grafana assets

The proposed Git-owned source layout is:

```text
docker-env/
└── stacks/
    └── monitoring/
        └── grafana/
            ├── dashboards/
            │   └── homelab-defender-kubernetes.json
            └── alerting/
                └── homelab-defender-alerts.yml
```

The proposed paths are not excluded by the current `docker-env` ignore rules.

## Dashboard target

The first Defender dashboard should show at least:

- deployment health;
- desired replicas;
- available replicas;
- pod/container ready state;
- pod phase;
- current restart total;
- new restarts over a short window;
- current release/image information where available; and
- CPU/memory once the required series are confirmed for the running pod.

## Alert design

The first alerts should detect state change and operational impact rather than static historical counters.

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

## Restart interpretation

The Defender pod showed `8` restarts. `kube-state-metrics` showed `31` restarts, with the latest restart times appearing broadly aligned.

That snapshot is consistent with a possible wider node or service restart, but it is not sufficient evidence to attribute a root cause. Future alert handling should correlate Defender restarts with node, Kubernetes and monitoring-service events before classifying an application incident.

## Change rule

For the next stage:

1. create the Defender Grafana assets in a clean `docker-env` branch or worktree based on current `origin/main`;
2. do not disturb unrelated local modifications in the existing TestServer checkout;
3. validate dashboard JSON and alert YAML before deployment;
4. deploy only the Grafana assets to the existing `ids-01` mounts;
5. confirm Grafana provisioning accepts them without errors;
6. confirm the dashboard queries the existing Prometheus datasource successfully;
7. validate alert evaluation without creating noise from the existing restart total; and
8. record the final deployed state in `home-lab-docs`.
