# Homelab Defender

## Purpose

Homelab Defender is the Kubernetes application used by the Jenkins/Gradle delivery lab to demonstrate a controlled source-to-runtime engineering path: application code is tested and packaged, a container image is built and security-scanned, the image is published to the private registry, and a restricted deployment action advances the running workload on K3s.

This overview records how the service is owned, deployed, observed and supported. Detailed Jenkins platform and release evidence remains under `../jenkins/`.

## Runtime

- Kubernetes node: `k3s-node-01` (`192.168.2.195`)
- Namespace: `homelab-defender-test`
- Deployment: `homelab-defender`
- Service: `homelab-defender`, ClusterIP `10.43.232.88`, port `8080`
- Desired replicas: `1`
- Current healthy state recorded on 26 August 2026: `1/1` ready and available
- Current approved release: build `15`
- Approved digest: `sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b`
- Build-15 validation pod: `homelab-defender-545cfbd765-mnbz4`, `Running`, `0` restarts

The authoritative Kubernetes desired state is:

```text
jrwroberts1976/kubernetes-homelab/applications/homelab-defender-test
```

The Git-owned approved image is:

```text
192.168.2.220:5000/homelab-defender:15@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
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

Jenkins build `14` was the first fully automated end-to-end release recorded in this documentation. Build `15` is the first release subsequently exercised end to end while the dedicated Defender Grafana monitoring was active.

Build 15 used:

```text
BUILD_CONTAINER=false
PUBLISH_CONTAINER=true
```

The Jenkinsfile makes `PUBLISH_CONTAINER=true` sufficient to run Containerise and Security Scan as well as Publish and Deploy. Build 15 therefore exercised:

```text
Test -> Package -> Containerise -> Security Scan -> Publish image -> Deploy to K3s
```

Jenkins recorded `SUCCESS` and the deployment health check completed successfully.

## Release identity

Build 15 was independently validated at runtime.

The live Jenkins deployment helper advanced the Deployment specification to:

```text
192.168.2.220:5000/homelab-defender:15
```

The running container reported:

```text
image_id = 192.168.2.220:5000/homelab-defender@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

Containerd independently showed tag `15` with digest prefix `2154a1881acc6...` and a distinct local image/config ID `4248f415ba996...`. This distinguishes the pullable registry digest from a local image/config identifier.

The approved immutable identity was reconciled into `kubernetes-homelab` through pull request `#11`, merged as:

```text
1565663aa0ed1584a09bdc0761ce5e143bf61cce
```

The Git-owned Deployment now records:

```text
kubernetes.io/change-cause: Jenkins build 15
image: 192.168.2.220:5000/homelab-defender:15@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

The Jenkins helper currently deploys by build tag, then the approved immutable tag/digest is reconciled into Git after validation. Do not apply an older Git image over a newer healthy Jenkins deployment; reconcile the approved release in Git first.

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

After build 15:

```text
desired replicas   = 1
available replicas = 1
pod phase          = Running
pod restarts       = 0
```

The two service-specific alert expressions both evaluated to `0` after the rollout.

`kube_pod_container_info` for the build-15 pod reported:

```text
image      = 192.168.2.220:5000/homelab-defender:15
image_spec = 192.168.2.220:5000/homelab-defender:15
image_id   = 192.168.2.220:5000/homelab-defender@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

For dashboard release display, `image_spec` remains appropriate for the build tag. For immutable release verification, use `image_id`, containerd/registry evidence and the Git-owned tag-plus-digest desired state rather than relying on a local image ID.

## Resource telemetry limitation

Kubernetes `metrics-server` provides point-in-time resource usage through `kubectl top`; the earlier recorded pod sample was approximately `1m` CPU and `166Mi` memory.

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

All dashboard PromQL expressions were validated successfully against the live `ids-01` Prometheus before deployment. The dashboard source uses datasource UID `PBFA97CFB590B2093` and release display through `{{image_spec}}`.

## Deployed alerts — 26 August 2026

The alert rules were deployed individually through Grafana's provisioning API using the protected API token source. No direct SQLite write was used and the broad repository-wide deployment path was deliberately avoided so unrelated rules could not be reconciled accidentally.

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

## Monitoring validation — complete

The live dashboard and both alert rules were retrieved read-only after deployment.

Dashboard verification:

```text
HTTP: 200
UID: homelab-defender-k8s
Title: Homelab Defender Kubernetes Operations
Version: 1
Panels: 9
Path: /d/homelab-defender-k8s/homelab-defender-kubernetes-operations
```

Both alert definitions returned HTTP `200`, retained the expected source settings, and remained unpaused.

Live rule evaluation during the initial monitoring closure:

```text
ffwbnisgmg4cgb | Homelab Defender Deployment Unavailable | state=inactive | health=ok
afwbnisiruz28f | Homelab Defender New Container Restart  | state=inactive | health=ok
```

Grafana Alertmanager reported zero active Defender alert instances and both current PromQL conditions were `0`.

Build 15 was then released while the monitoring was active. The new pod reached `Running` with zero restarts, Prometheus observed the build-15 image identity, and both Defender alert expressions remained `0`.

No synthetic firing/email-delivery exercise was performed during either closure step.

**Monitoring rollout status: COMPLETE.**

## Trivy security cache

The build-15 Security Scan refreshed both Trivy vulnerability databases. The first vulnerability-DB request to `mirror.gcr.io` returned `BLOB_UNKNOWN`; Trivy automatically fell back to `ghcr.io/aquasecurity/trivy-db:2` and continued successfully.

The persistent `trivy-cache` DinD volume contained approximately:

```text
Vulnerability DB: 1.2G
Java DB:          1.4G
Total cache:      2.6G
```

Metadata after the build showed:

```text
Vulnerability DB downloaded: 2026-08-26T07:28:38Z
Vulnerability DB next update: 2026-08-27T07:03:22Z
Java DB downloaded:          2026-08-26T07:35:54Z
Java DB next update:         2026-08-29T01:07:43Z
```

The long build-15 scan was therefore a legitimate database refresh, not a broken cache or stuck Jenkins executor. No Jenkinsfile change is required from this observation.

## Restart interpretation

The earlier build-14 baseline showed the Defender pod with `8` restarts while `kube-state-metrics` itself showed `31`, with the latest restart times appearing broadly aligned. That snapshot was compatible with a wider node or service event but did not establish a root cause.

The build-15 pod had zero restarts at post-release validation. When a future Defender restart alert fires, correlate it with node state, Kubernetes events and monitoring-service restarts before classifying it as an application-only incident.

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
- persistent Trivy vulnerability database cache;
- restricted SSH deployment on `k3s-node-01`;
- independent runtime digest verification;
- Git-owned immutable desired-state reconciliation after an approved release; and
- dedicated Grafana availability/restart monitoring.

Grafana API tokens, registry credentials, SSH private keys, SMTP passwords and other credentials remain outside committed documentation and source files.

## Maintenance and change rules

Before changing Defender or its monitoring:

1. validate the application/pipeline source revision and intended Jenkins parameters;
2. retain the current approved immutable image as rollback evidence;
3. validate PromQL against the live Prometheus datasource before monitoring changes;
4. validate dashboard/rule JSON before Grafana deployment;
5. preserve existing live Grafana state as rollback evidence when changing existing objects;
6. run the full gated Jenkins release before approving a new runtime;
7. verify the running registry digest independently from a local Docker image/config ID;
8. reconcile the approved tag and digest into `kubernetes-homelab` after runtime validation;
9. do not apply an older desired-state image over a newer healthy Jenkins deployment;
10. verify live dashboard/rule state and alert evaluation after release; and
11. record the evidence in `home-lab-docs`.

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
- [Platform Baseline — 26 August 2026](../jenkins/platform-baseline-2026-08-26.md)
- [Homelab Defender Monitoring Baseline — 26 August 2026](../jenkins/homelab-defender-monitoring-baseline-2026-08-26.md)
- [Homelab Defender Build 15 Validation — 26 August 2026](../jenkins/homelab-defender-build-15-validation-2026-08-26.md)
- [Grafana Alerting](grafana-alerting.md)
- [Docker Container Inventory](docker-container-inventory.md)
