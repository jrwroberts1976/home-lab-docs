# Jenkins Operations

This area is the operational documentation home for Jenkins and the Homelab Defender delivery path.

The implementation repository remains authoritative for application source, tests, the `Jenkinsfile`, image construction and the restricted node-side deployment implementation:

- [jenkins-gradle-delivery-lab](https://github.com/jrwroberts1976/jenkins-gradle-delivery-lab)

Kubernetes desired state remains authoritative in:

- [kubernetes-homelab/applications/homelab-defender-test](https://github.com/jrwroberts1976/kubernetes-homelab/tree/main/applications/homelab-defender-test)

This area documents how Jenkins is operated, changed, validated, supported and recovered as part of the homelab.

## Current documents

- [Platform baseline — 26 August 2026](platform-baseline-2026-08-26.md) — pre-change versions, image identities, ownership, security controls, release state and update candidates.
- [Homelab Defender monitoring baseline — 26 August 2026](homelab-defender-monitoring-baseline-2026-08-26.md) — validated K3s metrics path, live Grafana/Prometheus architecture, monitoring ownership boundaries, deployed dashboard/alert evidence and remaining post-deployment validation.
- [Homelab Defender service overview](../service-overviews/homelab-defender.md) — service-level purpose, runtime, dependencies, monitoring, alerting, availability and maintenance context.

## Service scope

Jenkins currently provides:

- Java and Gradle test/package automation;
- isolated Docker-in-Docker image builds;
- Trivy HIGH/CRITICAL vulnerability gating;
- authenticated publication to the private TestServer registry;
- a restricted SSH deployment request to `k3s-node-01`;
- Kubernetes rollout and application health verification; and
- automatic rollback to the previously running image when release verification fails.

Operational support for the delivered workload uses the existing homelab monitoring platform. `kube-state-metrics` exposes the Defender deployment and pod state, Prometheus stores those metrics, and the live Grafana service on `ids-01` now hosts the dedicated Defender operations dashboard and two service-specific alert rules.

## Ownership boundaries

| Concern | Authoritative source |
|---|---|
| Jenkins controller and DinD Compose runtime | TestServer `/home/james/projects/docker-compose.yml` |
| Custom Jenkins controller image | TestServer `/home/james/projects/Dockerfile` |
| Application, tests and delivery pipeline | `jenkins-gradle-delivery-lab` |
| Node-side restricted deploy implementation | `jenkins-gradle-delivery-lab/ops/deploy-homelab-defender` |
| Kubernetes desired state and approved release digest | `kubernetes-homelab/applications/homelab-defender-test` |
| Grafana alert definitions and dashboard source | `grafana-alerting` |
| Host-specific monitoring Compose/runtime configuration | `docker-env` plus controlled host deployment state |
| Jenkins operational documentation and evidence | `home-lab-docs/jenkins` |
| Runtime Jenkins data | TestServer `/home/james/docker/data/jenkins` |
| DinD image/build cache | TestServer `/home/james/docker/data/jenkins-docker` |
| Live Defender Grafana state | Grafana runtime on `ids-01` |

The TestServer Jenkins Compose file and custom controller Dockerfile are operationally critical but are not yet recorded here as Git-owned source. Bringing them under controlled source ownership is part of the Jenkins documentation and recovery work.

The TestServer and `ids-01` monitoring Compose definitions are host-specific and must not be made identical merely to remove drift. Grafana rule/dashboard source follows the existing `grafana-alerting` repository, while host-specific runtime definitions remain explicit.

## Current release

Jenkins build 14 is the last recorded fully automated healthy release:

```text
192.168.2.220:5000/homelab-defender:14
```

Build 14 passed Gradle testing and packaging, image construction, Trivy scanning with zero HIGH/CRITICAL findings, registry publication, restricted K3s deployment, rollout and ClusterIP `/healthz` verification.

## Current monitoring deployment

The Defender Grafana source was merged through `grafana-alerting#4` as merge commit `8244758`.

Live Grafana objects created on 26 August 2026:

```text
Dashboard: Homelab Defender Kubernetes Operations
Dashboard UID: homelab-defender-k8s

Alert: Homelab Defender Deployment Unavailable
Alert UID: ffwbnisgmg4cgb

Alert: Homelab Defender New Container Restart
Alert UID: afwbnisiruz28f
```

The dashboard was created through `POST /api/dashboards/db` with HTTP `200`. Both alert rules were created through the Grafana provisioning API with HTTP `201` and returned `provenance=api`, `isPaused=false`.

A final post-deployment live retrieval/evaluation check remains outstanding before the monitoring change is considered fully operationally closed.

## Change rules

Before changing Jenkins or a delivery image:

1. Record the current controller, builder, scanner and application-base identities.
2. Confirm the TestServer Jenkins data and DinD data locations are protected.
3. Retain a rollback image or immutable digest.
4. Change one controlled source branch.
5. Validate configuration and build candidates before container recreation.
6. Confirm Jenkins returns healthy with its jobs, credentials and build history intact.
7. Run a gated end-to-end release.
8. Reconcile the approved tag and digest into `kubernetes-homelab`.
9. Confirm the operational monitoring path remains healthy after release.
10. Record the before/after evidence in this area and the current daily-actions log.

## Planned documents

- Jenkins controller and DinD update SOP.
- Credential and build-log validation SOP.
- End-to-end release and Kubernetes reconciliation SOP.
- Jenkins controller/data recovery SCP.
- Private-registry publication and recovery notes.
