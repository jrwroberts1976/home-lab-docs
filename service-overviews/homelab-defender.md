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

The existing Kubernetes monitoring components already provide the state required for an operational dashboard; no new Kubernetes exporter or Prometheus scrape target is required.

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

A separate Prometheus instance on TestServer also scrapes the same `kube-state-metrics` endpoint successfully. The live Grafana dashboards and alert evaluation use the `ids-01` Prometheus datasource.

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

The historical restart count of `8` must not itself generate a new incident. Restart alerting should detect an increase over a short time window.

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

Kubernetes `metrics-server` currently provides point-in-time resource usage through `kubectl top`; the recorded pod sample was approximately `1m` CPU and `166Mi` memory.

However, the live `ids-01` Prometheus instance returned no Defender series for:

```text
container_cpu_usage_seconds_total{namespace="homelab-defender-test",container="homelab-defender"}
container_memory_working_set_bytes{namespace="homelab-defender-test",container="homelab-defender"}
```

Therefore CPU and memory panels should not be added to the first Grafana dashboard by inventing or assuming unavailable telemetry. They can be added later if kubelet/cAdvisor resource series are deliberately exposed to the live Prometheus path.

## Grafana dashboard ownership

The live Grafana container runs on `ids-01` and file-provisions dashboards from:

```text
/home/james/docker/data/monitoring/grafana/dashboards
    -> /etc/grafana/dashboards
```

The existing `jrwroberts1976/grafana-alerting` repository already contains a `dashboards/` directory and is the appropriate Git home for the Defender dashboard candidate.

The expected source file is:

```text
grafana-alerting/dashboards/homelab-defender-kubernetes.json
```

Existing Grafana dashboards use a datasource variable named `${DS_PROMETHEUS}` rather than hard-coding a datasource UID. The Defender dashboard should follow that convention.

## Alert ownership and deployment

Grafana alert definitions are Git-managed in:

```text
jrwroberts1976/grafana-alerting/rules
```

The repository deploys Grafana-managed alert rules through the Grafana provisioning API. The live rules are persisted by Grafana and are visible in the Grafana database; they should not be created by writing directly to SQLite.

Existing automation on `ids-01` also demonstrates the protected-token pattern:

```text
/home/james/docker/secrets/grafana-api-token
```

Deployment scripts use `GRAFANA_TOKEN` when explicitly supplied, otherwise read the protected token file, and call the Grafana provisioning API at `http://localhost:3001`.

The live Prometheus datasource UID used by existing rules is:

```text
PBFA97CFB590B2093
```

The existing Grafana alert folder UID is `homelab-alerts`, displayed as **Homelab Alerts**.

## Initial alert design

The first service-specific rules should cover:

1. deployment unavailable — available replicas lower than desired replicas;
2. container/pod not ready; and
3. a new restart detected over a short evaluation window.

Deployment availability can be expressed conceptually as:

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

New restarts can be detected with:

```promql
increase(
  kube_pod_container_status_restarts_total{
    namespace="homelab-defender-test",
    container="homelab-defender"
  }[10m]
) > 0
```

Existing homelab alert rules typically evaluate every 60 seconds and use labels such as `severity` and `category` for notification routing.

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

Grafana API tokens, SMTP passwords and other credentials must remain outside committed documentation and source files.

## Maintenance and change rules

Before changing Defender monitoring:

1. validate PromQL against the live Prometheus datasource;
2. preserve the existing Grafana rule state as rollback evidence when changing alerts;
3. validate dashboard JSON with `jq` before deployment;
4. deploy alerts through the existing Grafana provisioning API, not direct SQLite writes;
5. deploy dashboard JSON only to the existing Grafana dashboard mount;
6. avoid changes to Kubernetes or Prometheus unless a missing telemetry requirement is explicitly approved; and
7. record the resulting operational state in `home-lab-docs`.

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
