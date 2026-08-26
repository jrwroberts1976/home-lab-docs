# Homelab Defender Build 15 Validation — 26 August 2026

This record closes the first Homelab Defender release exercised end to end after the dedicated Grafana dashboard and alert rules were deployed and validated.

## Outcome

**Status: COMPLETE**

Jenkins build `15` completed successfully through the full delivery path:

```text
Test
  -> Package
  -> Containerise
  -> Trivy Security Scan
  -> Publish image
  -> Deploy to K3s
  -> rollout and /healthz verification
```

The release was then validated independently in Kubernetes, Prometheus/Grafana monitoring and Git-owned desired state.

## Source and parameters

Application repository:

```text
jrwroberts1976/jenkins-gradle-delivery-lab
```

Source revision used for the release:

```text
d0e8e8b Merge Kubernetes desired-state documentation alignment
```

Jenkins parameters:

```text
BUILD_CONTAINER=false
PUBLISH_CONTAINER=true
```

The Jenkinsfile confirms that `PUBLISH_CONTAINER=true` also enables the Containerise and Security Scan stages, so this parameter combination exercised the full release path.

## Jenkins result

Jenkins recorded:

```text
Build: 15
Result: SUCCESS
Duration: 1013344 ms
```

Credential bindings remained protected through Jenkins `withCredentials` blocks for the private registry and restricted K3s SSH deployment identity. No credential value was intentionally written to the build log.

The pipeline successfully entered both `Publish image` and `Deploy to K3s`, and ended with:

```text
Deployment of 192.168.2.220:5000/homelab-defender:15 completed successfully.
Finished: SUCCESS
```

## Trivy security gate

The HIGH/CRITICAL Trivy gate passed. Publication and deployment would not have been reached if the configured `--exit-code 1` scan had failed.

During this run Trivy refreshed its databases. The initial vulnerability-database request to `mirror.gcr.io` returned `BLOB_UNKNOWN`; Trivy automatically fell back to `ghcr.io/aquasecurity/trivy-db:2` and completed the download successfully.

The Java vulnerability database was also refreshed. This accounted for most of the unusually long scan time and was not a stuck Jenkins executor or failed cache.

Persistent DinD cache volume:

```text
trivy-cache
CreatedAt: 2026-08-20T14:43:40Z
Mountpoint: /var/lib/docker/volumes/trivy-cache/_data
```

Observed cache size after build 15:

```text
/root/.cache/trivy/db       1.2G
/root/.cache/trivy/java-db  1.4G
/root/.cache/trivy/fanal    1.0M
Total                       2.6G
```

Trivy metadata after the successful refresh:

```text
Vulnerability DB
  UpdatedAt:    2026-08-26T07:03:22.527318236Z
  DownloadedAt: 2026-08-26T07:28:38.661266407Z
  NextUpdate:   2026-08-27T07:03:22.527318085Z

Java DB
  UpdatedAt:    2026-08-26T01:07:43.424187285Z
  DownloadedAt: 2026-08-26T07:35:54.16422798Z
  NextUpdate:   2026-08-29T01:07:43.424187155Z
```

**Conclusion:** the Trivy cache is persistent and healthy. Build 15 performed a legitimate database refresh. No Jenkinsfile change is required from this observation.

## Kubernetes runtime validation

Runtime host:

```text
k3s-node-01 | 192.168.2.195
```

Validated state after deployment:

```text
Namespace:  homelab-defender-test
Deployment: homelab-defender
Ready:      1/1
Available:  1
Pod:        homelab-defender-545cfbd765-mnbz4
Pod state:  Running
Restarts:   0
Pod IP:     10.42.0.196
Service:    homelab-defender
ClusterIP:  10.43.232.88
Port:       8080/TCP
```

The Jenkins deploy helper advanced the live Deployment specification to:

```text
192.168.2.220:5000/homelab-defender:15
```

The running container resolved to:

```text
192.168.2.220:5000/homelab-defender@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

Containerd inventory independently showed tag `15` with the same digest prefix and a distinct local image/config ID:

```text
Tag:       15
Digest:    2154a1881acc6...
Image ID:  4248f415ba996...
Size:      96MB
```

The approved immutable release identity is therefore:

```text
192.168.2.220:5000/homelab-defender:15@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

## Monitoring validation

The live Prometheus path on `ids-01` observed the new pod and build-15 image identity.

`kube_pod_container_info` reported:

```text
pod        = homelab-defender-545cfbd765-mnbz4
image      = 192.168.2.220:5000/homelab-defender:15
image_spec = 192.168.2.220:5000/homelab-defender:15
image_id   = 192.168.2.220:5000/homelab-defender@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

Both Defender alert expressions remained healthy after the release:

```text
Homelab Defender Deployment Unavailable -> 0
Homelab Defender New Container Restart  -> 0
```

The new pod had zero restarts at validation time. This confirms that the monitored release path handled a normal rollout without generating either service-specific alert condition.

The dedicated monitoring objects remain:

```text
Dashboard: Homelab Defender Kubernetes Operations
Dashboard UID: homelab-defender-k8s

Alert: Homelab Defender Deployment Unavailable
Alert UID: ffwbnisgmg4cgb

Alert: Homelab Defender New Container Restart
Alert UID: afwbnisiruz28f
```

No synthetic Defender firing/email-delivery test was performed during this release validation.

## Git desired-state reconciliation

The authoritative Kubernetes source is:

```text
jrwroberts1976/kubernetes-homelab/applications/homelab-defender-test
```

After runtime validation, the approved build-15 tag and digest were reconciled into Git on branch:

```text
deploy/homelab-defender-build-15
```

Reconciliation commit:

```text
2c7c3f0 Reconcile Homelab Defender build 15
```

Pull request:

```text
kubernetes-homelab#11 Reconcile Homelab Defender build 15
```

Merge commit:

```text
1565663aa0ed1584a09bdc0761ce5e143bf61cce
```

The Git-owned Deployment now records:

```text
kubernetes.io/change-cause: Jenkins build 15
image: 192.168.2.220:5000/homelab-defender:15@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

The Jenkins deployment helper currently advances the live workload by build tag; Git records the approved immutable tag plus digest after release validation. Do not overwrite a newer healthy Jenkins deployment with an older Git image reference. Reconcile Git first, then use the Git-owned manifest for controlled desired-state application.

## Closure

Build 15 demonstrates the complete controlled release chain:

```text
application source
  -> Jenkins tests/package
  -> container build
  -> Trivy HIGH/CRITICAL gate
  -> authenticated private registry publication
  -> restricted K3s deployment
  -> health-checked running workload
  -> Prometheus/Grafana observation
  -> Git immutable desired-state reconciliation
```

**Release status: COMPLETE AND HEALTHY.**

## Related documentation

- [Jenkins Operations](README.md)
- [Platform Baseline — 26 August 2026](platform-baseline-2026-08-26.md)
- [Homelab Defender Monitoring Baseline — 26 August 2026](homelab-defender-monitoring-baseline-2026-08-26.md)
- [Homelab Defender Service Overview](../service-overviews/homelab-defender.md)
