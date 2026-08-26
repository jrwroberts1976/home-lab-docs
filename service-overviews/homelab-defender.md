# Homelab Defender

## Purpose

Homelab Defender is the Kubernetes application used by the Jenkins/Gradle delivery lab to demonstrate a controlled source-to-runtime engineering path: application code is tested and packaged, a container image is built and security-scanned, the image is published to the private registry, and a restricted deployment action advances the running workload on K3s.

This overview records how the service is owned, deployed, observed and supported. Detailed Jenkins platform evidence remains under `../jenkins/`.

## Runtime

- Kubernetes node: `k3s-node-01` (`192.168.2.195`)
- Namespace: `homelab-defender-test`
- Deployment: `homelab-defender`
- Service: `homelab-defender`, ClusterIP, port `8080`
- Desired replicas: `1`
- Current healthy state recorded on 26 August 2026: `1/1` ready and available
- Current approved release: build `14`
- Approved digest: `sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a`

The authoritative Kubernetes desired state is:

```text
jrwroberts1976/kubernetes-homelab/applications/homelab-defender-test
```

The application repository is:

```text
jrwroberts1976/jenkins-gradle-delivery-lab
```

That repository owns the application source, tests, Jenkins delivery workflow and restricted node-side deployment implementation. The Kubernetes repository owns the desired Namespace/Deployment/Service/probe definition and the approved release tag/digest.

## Delivery architecture

```text
jenkins-gradle-delivery-lab
        |
        v
Jenkins on TestServer
        |
        +--> Gradle test/package
        +--> container build
        +--> Trivy HIGH/CRITICAL gate
        +--> private registry 192.168.2.220:5000
        |
        v
restricted SSH deploy request
        |
        v
k3s-node-01
        |
        v
homelab-defender-test / homelab-defender
```

The first fully automated end-to-end release recorded in this documentation is Jenkins build `14`.

## Monitoring architecture

The existing Kubernetes monitoring components provide the state required for operational monitoring; no new Kubernetes exporter or Prometheus scrape target was required.

`kube-state-metrics` runs in the K3s `monitoring` namespace and is exposed at:

```text
192.168.2.211:8080
```

The live Grafana path is:

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

Grafana and Prometheus share the `monitoring` Docker network on `ids-01`. The live Prometheus datasource is:

```text
name: Prometheus
uid: PBFA97CFB590B2093
url: http://prometheus:9090
```

A separate Prometheus instance on TestServer also scrapes the same `kube-state-metrics` endpoint successfully. The live Grafana dashboard and alert evaluation use the `ids-01` Prometheus datasource.

## Current metrics

The validated state series include:

```text
kube_deployment_spec_replicas
kube_deployment_status_replicas_available
kube_pod_container_status_ready
kube_pod_container_status_restarts_total
kube_pod_status_phase
kube_pod_container_info
```

At the recorded baseline:

```text
desired replicas   = 1
available replicas = 1
container ready    = 1
restart total      = 8
pod phase          = Running
```

The historical restart count of `8` is not itself an incident. Restart alerting detects a new increase over a ten-minute window.

## Release identity

`kube_pod_container_info` provides useful release metadata, but its labels need careful interpretation.

For the current pod it reported:

```text
image      = 192.168.2.220:5000/homelab-defender:12
image_id   = 192.168.2.220:5000/homelab-defender@sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a
image_spec = 192.168.2.220:5000/homelab-defender:14@sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a
```

For operational release display, use `image_spec` and `image_id`. Do not treat the separate `image` label as the authoritative release number when it disagrees with the digest-pinned deployment specification.

## Resource telemetry limitation

Kubernetes `metrics-server` provides point-in-time resource usage through `kubectl top`; the recorded pod sample was approximately `1m` CPU and `166Mi` memory.

However, the live `ids-01` Prometheus instance returned no Defender series for:

```text
container_cpu_usage_seconds_total{namespace="homelab-defender-test",container="homelab-defender"}
container_memory_working_set_bytes{namespace="homelab-defender-test",container="homelab-defender"}
```

CPU and memory panels were therefore intentionally omitted from the first Grafana dashboard. They can be added later if kubelet/cAdvisor resource series are deliberately exposed to the live Prometheus path.

## Grafana source ownership

Grafana dashboard and alert source is Git-managed in:

```text
jrwroberts1976/grafana-alerting
```

The deployed Defender source files are:

```text
dashboards/homelab-defender-kubernetes.json
rules/homelab-defender-deployment-unavailable.json
rules/homelab-defender-new-restart.json
```

The source change was introduced on branch `monitoring/homelab-defender`, committed as `5a1b65c`, merged through `grafana-alerting#4`, and incorporated into `main` as merge commit `8244758`.

The host-specific monitoring Compose/runtime configuration remains separate from these reusable Grafana assets.

## Deployed dashboard — 26 August 2026

The Defender dashboard was deployed to live Grafana through the authenticated dashboard API rather than by copying into the file-provisioned dashboard mount.

Deployment result:

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

All dashboard PromQL expressions were validated successfully against the live `ids-01` Prometheus before deployment.

The dashboard source uses the confirmed live datasource UID `PBFA97CFB590B2093`. The release panel uses `{{image_spec}}` so the digest-pinned build `14` identity is displayed rather than the misleading standalone `image=:12` label.

## Deployed alerts — 26 August 2026

The alert rules were deployed individually through Grafana's provisioning API using the protected API token at:

```text
/home/james/docker/secrets/grafana-api-token
```

No direct SQLite write was used and the broad repository-wide `deploy-alerts.sh` path was deliberately avoided so unrelated rules could not be reconciled accidentally.

### Homelab Defender Deployment Unavailable

```text
Grafana rule UID: ffwbnisgmg4cgb
Grafana database ID: 37
folder UID: homelab-alerts
rule group: Homelab Defender
severity: critical
category: availability
for: 2m
noDataState: Alerting
execErrState: Alerting
provenance: api
paused: false
```

PromQL:

```promql
sum(kube_deployment_spec_replicas{namespace="homelab-defender-test",deployment="homelab-defender"})
-
sum(kube_deployment_status_replicas_available{namespace="homelab-defender-test",deployment="homelab-defender"})
> bool 0
```

The expression evaluated to `0` against the healthy baseline before deployment.

### Homelab Defender New Container Restart

```text
Grafana rule UID: afwbnisiruz28f
Grafana database ID: 38
folder UID: homelab-alerts
rule group: Homelab Defender
severity: warning
category: stability
for: 1m
noDataState: OK
execErrState: Alerting
provenance: api
paused: false
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

The expression evaluated to `0` before deployment while the historical restart total remained `8`, confirming that the existing counter would not immediately trigger the rule.

## Post-deployment validation status

The Grafana API accepted the dashboard with HTTP `200` and both rules with HTTP `201`. Both returned live rule objects with `provenance=api` and `isPaused=false`.

A final post-deployment retrieval/evaluation check is still required to confirm:

- the dashboard can be retrieved from live Grafana by UID;
- both alert rules are present with the expected source definitions;
- both rules evaluate healthy/inactive against the current baseline; and
- no unexpected notification was generated.

Until that check is complete, the deployment is recorded as successful at the API/configuration layer with final operational evaluation verification pending.

## Restart interpretation

The Defender pod showed `8` restarts while `kube-state-metrics` itself showed `31`, with the latest restart times appearing broadly aligned. This is compatible with a wider node or service event, but the snapshot does not prove a root cause.

When a future Defender restart alert fires, correlate it with node state, Kubernetes events and monitoring-service restarts before classifying it as an application-only incident.

## Availability expectation

The service is expected to maintain one ready and available replica. A healthy state is therefore:

```text
desired = 1
available = 1
container ready = 1
pod phase = Running
```

Loss of the only available replica is service-impacting and should be treated as an availability incident after confirming the monitoring path itself is healthy.

## Security controls

The delivery path includes:

- Jenkins credential binding;
- private-registry authentication;
- Trivy HIGH/CRITICAL vulnerability gating;
- restricted SSH deployment on `k3s-node-01`;
- digest-pinned Kubernetes release state; and
- Git-owned desired-state reconciliation after an approved release.

Grafana API tokens, SMTP passwords and other credentials remain outside committed documentation and source files.

## Maintenance and change rules

Before changing Defender monitoring:

1. validate PromQL against the live Prometheus datasource;
2. validate dashboard/rule JSON before deployment;
3. preserve existing live Grafana state as rollback evidence when changing existing rules or dashboards;
4. merge source to `grafana-alerting/main` before live deployment;
5. deploy alert rules individually through the Grafana provisioning API using the protected token pattern;
6. deploy the Defender dashboard through the scoped Grafana dashboard API unless a future controlled change deliberately moves it to file provisioning;
7. do not write directly to Grafana SQLite;
8. avoid Kubernetes or Prometheus changes unless a missing telemetry requirement is explicitly approved; and
9. verify live dashboard/rule state after deployment and record the evidence in `home-lab-docs`.

## Source ownership

| Concern | Authoritative source |
|---|---|
| Application source, tests and Jenkins delivery | `jenkins-gradle-delivery-lab` |
| Kubernetes desired state and approved digest | `kubernetes-homelab/applications/homelab-defender-test` |
| Grafana alert definitions and dashboard source | `grafana-alerting` |
| Host-specific monitoring Compose/runtime configuration | `docker-env` plus the controlled host deployment state |
| Operational documentation and evidence | `home-lab-docs` |

The TestServer and `ids-01` monitoring Compose definitions are host-specific and materially different. They should not be made identical merely to remove apparent drift.

## Related documentation

- [Jenkins Operations](../jenkins/README.md)
- [Homelab Defender Monitoring Baseline — 26 August 2026](../jenkins/homelab-defender-monitoring-baseline-2026-08-26.md)
- [Grafana Alerting](grafana-alerting.md)
- [Docker Container Inventory](docker-container-inventory.md)
