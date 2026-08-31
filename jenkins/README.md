# Jenkins Operations

This area is the operational documentation home for Jenkins, the Homelab Defender delivery path and the guarded Docker/Compose Stage 6 service-update workflow.

The implementation repository remains authoritative for Homelab Defender application source, tests, the `Jenkinsfile`, image construction and the restricted node-side deployment implementation:

- [jenkins-gradle-delivery-lab](https://github.com/jrwroberts1976/jenkins-gradle-delivery-lab)

Kubernetes desired state remains authoritative in:

- [kubernetes-homelab/applications/homelab-defender-test](https://github.com/jrwroberts1976/kubernetes-homelab/tree/main/applications/homelab-defender-test)

The separate `homelab-container-version-control` repository is authoritative for Docker/Compose image-version governance and the Stage 6 guarded service-update framework. That project has now moved beyond the earlier read-only Stage 4 foundation and has performed real reviewed Jenkins deployments on TestServer and `ids-01`.

This area records Jenkins operational use, validation, security boundaries and recovery expectations across those workflows.

## Current documents

- [Platform baseline — 26 August 2026](platform-baseline-2026-08-26.md) — pre-change versions, image identities, ownership, security controls, release state and update candidates.
- [Homelab Defender monitoring baseline — 26 August 2026](homelab-defender-monitoring-baseline-2026-08-26.md) — the initial build-14 monitoring baseline, live Grafana/Prometheus architecture, monitoring ownership boundaries, dashboard/alert deployment and closure evidence.
- [Homelab Defender build 15 validation — 26 August 2026](homelab-defender-build-15-validation-2026-08-26.md) — successful full release, Trivy database refresh evidence, K3s runtime validation, monitoring checks and immutable Git desired-state reconciliation.
- [Container Version Control — Stage 4 Validation Gate Foundation — 26 August 2026](container-version-control-stage4-foundation-2026-08-26.md) — historical foundation for read-only TestServer ownership, image typing, version comparison and candidate-planning controls.
- [Container Version Control — Stage 6 Jenkins Closeout — 31 August 2026](container-version-control-stage6-closeout-2026-08-31.md) — current generic Stage 6 deployment state, Loki/Dozzle proof, candidate-acquisition security boundary, `VERIFY_CLOSED` requirement and Alloy restart point.
- [Homelab Defender service overview](../service-overviews/homelab-defender.md) — service-level purpose, runtime, dependencies, monitoring, alerting, availability and maintenance context.
- [Jenkins service overview](../service-overviews/jenkins.md) — current logical Jenkins service and Stage 6 control boundaries.

## Service scope

Jenkins currently provides:

- Java and Gradle test/package automation;
- isolated Docker-in-Docker image builds;
- Trivy HIGH/CRITICAL vulnerability gating;
- authenticated publication to the private TestServer registry;
- a restricted SSH deployment request to `k3s-node-01`;
- Kubernetes rollout and application health verification;
- automatic rollback to the previously running Defender image when release verification fails; and
- guarded Stage 6 Docker/Compose service updates through reviewed host-side inspectors/executors.

Operational support for the delivered workload uses the existing homelab monitoring platform. `kube-state-metrics` exposes the Defender deployment and pod state, Prometheus stores those metrics, and the live Grafana service on `ids-01` hosts the dedicated Defender operations dashboard and two service-specific alert rules.

## Container Version Control Stage 6 — current checkpoint

The Stage 6 generic Jenkins path now supports reviewed service updates on TestServer and `ids-01`.

Proven controls include:

- Git-reviewed service manifests and validators;
- fixed host routes and pinned SSH host fingerprints;
- dedicated read-only inspector credentials;
- read-only pre-approval inspection;
- exact rollback/candidate/runtime identity checks;
- explicit human approval;
- second read-only inspection and exact zero-drift proof;
- deployment executor credential binding only after approval/zero drift;
- one-shot arm/deploy/disarm authority;
- target-only recreation with `--no-deps --no-build --pull never --force-recreate`;
- reviewed rollback;
- Docker health, fixed HTTP and `container-http` health strategies;
- protected-container checks.

Loki `3.7.7` on `ids-01` proved the generic multi-host deployment/disarm path.

Dozzle `10.8.0` proved the TestServer path, read-only Docker-socket handling, internal-container HTTP health and empty runtime-user support. Jenkins build #13 deployed the exact Dozzle candidate successfully but later failed at disarm because the transition helper did not yet support `container-http`. The framework was fixed and the already-deployed Dozzle service was then fully closed through reviewed recovery without a second recreation.

Dozzle is now authoritative, catalogued and steady-state verified, but it has not produced a single clean Jenkins `SUCCESS_CLOSED` build. Its consumed update must not be redeployed merely to make the historical Jenkins result green.

### Remaining Stage 6 Jenkins work

Before the next fresh service update:

1. add a narrowly scoped candidate-acquisition SSH identity/forced command;
2. make Jenkins pull and verify the exact immutable candidate before human approval;
3. prove candidate acquisition changes only the local image cache and no container state;
4. keep the full deployment executor credential unavailable until after approval and zero drift;
5. retain `--pull never` during deployment;
6. add a non-mutating `VERIFY_CLOSED` / equivalent action;
7. use that action to verify Dozzle through Jenkins without recreating it;
8. then resume TestServer Alloy as the first fresh complete-flow candidate.

A useful non-mutating success state is:

```text
SUCCESS_VERIFIED_CLOSED
```

The intended full fresh-update success state remains:

```text
SUCCESS_CLOSED
```

See [Container Version Control — Stage 6 Jenkins Closeout — 31 August 2026](container-version-control-stage6-closeout-2026-08-31.md) for the exact restart point.

## Ownership boundaries

| Concern | Authoritative source |
|---|---|
| Jenkins controller and DinD Compose runtime | TestServer `/home/james/projects/docker-compose.yml` |
| Custom Jenkins controller image | TestServer `/home/james/projects/Dockerfile` |
| Application, tests and Defender delivery pipeline | `jenkins-gradle-delivery-lab` |
| Node-side restricted Defender deploy implementation | `jenkins-gradle-delivery-lab/ops/deploy-homelab-defender` |
| Kubernetes desired state and approved Defender release digest | `kubernetes-homelab/applications/homelab-defender-test` |
| Docker/Compose Stage 6 version-control implementation and policy | `homelab-container-version-control` |
| Docker/Compose service authority | `docker-env` plus reviewed host authority checkouts |
| Grafana alert definitions and dashboard source | `grafana-alerting` |
| Jenkins operational documentation and evidence | `home-lab-docs/jenkins` |
| Runtime Jenkins data | TestServer `/home/james/docker/data/jenkins` |
| DinD image/build cache | TestServer `/home/james/docker/data/jenkins-docker` |
| Live Defender Grafana state | Grafana runtime on `ids-01` |

The TestServer Jenkins Compose file and custom controller Dockerfile remain operationally critical and should be brought under controlled Git ownership. The container-version-control estate continues to treat the Jenkins controller/DinD services as higher-risk platform exceptions rather than silently allowing generic self-update authority.

The TestServer and `ids-01` monitoring Compose definitions are host-specific and must not be made identical merely to remove drift. Grafana rule/dashboard source follows the existing `grafana-alerting` repository, while host-specific runtime definitions remain explicit.

## Current Homelab Defender release

Jenkins build `15` is the current recorded healthy Defender release.

Approved immutable identity:

```text
192.168.2.220:5000/homelab-defender:15@sha256:2154a1881acc63db852dbeebc7daf5890a1c9527c4b70837b2ad33fb76ad940b
```

Build 15 ran with:

```text
BUILD_CONTAINER=false
PUBLISH_CONTAINER=true
```

Because `PUBLISH_CONTAINER=true` enables the Containerise and Security Scan gates as well as publication/deployment, the release exercised the complete path:

```text
Test -> Package -> Containerise -> Security Scan -> Publish image -> Deploy to K3s
```

Jenkins recorded `SUCCESS` after `1013344 ms`. The resulting K3s Deployment was `1/1` available, the new pod was `Running` with zero restarts, and the two Defender alert expressions both evaluated to `0`.

The approved build-15 identity was reconciled into `kubernetes-homelab` through pull request `#11`, merged as `1565663aa0ed1584a09bdc0761ce5e143bf61cce`.

Build `14` remains the previous validated rollback release with digest:

```text
sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a
```

See [Homelab Defender build 15 validation — 26 August 2026](homelab-defender-build-15-validation-2026-08-26.md) for the full release evidence.

## Trivy cache state

Build 15 refreshed both Trivy vulnerability databases. The primary vulnerability-DB mirror returned `BLOB_UNKNOWN`, after which Trivy automatically succeeded through its fallback repository. The Java database was also downloaded and accounted for most of the long scan duration.

The persistent DinD volume `trivy-cache` is healthy and retained approximately:

```text
Vulnerability DB: 1.2G
Java DB:          1.4G
Total cache:      2.6G
```

Recorded database metadata after build 15 showed:

```text
Vulnerability DB next update: 2026-08-27T07:03:22Z
Java DB next update:          2026-08-29T01:07:43Z
```

This was a legitimate database refresh rather than a failed cache. No Jenkinsfile change is required from this observation.

## Current monitoring deployment

The Defender Grafana source was merged through `grafana-alerting#4` as merge commit `8244758`.

Live Grafana objects created and subsequently validated on 26 August 2026:

```text
Dashboard: Homelab Defender Kubernetes Operations
Dashboard UID: homelab-defender-k8s

Alert: Homelab Defender Deployment Unavailable
Alert UID: ffwbnisgmg4cgb

Alert: Homelab Defender New Container Restart
Alert UID: afwbnisiruz28f
```

The dashboard was created through `POST /api/dashboards/db` with HTTP `200`. Both alert rules were created through the Grafana provisioning API with HTTP `201` and returned `provenance=api`, `isPaused=false`.

Final live retrieval/evaluation returned both rules `state=inactive`, `health=ok`, zero active Defender alert instances and both PromQL conditions equal to `0`. Build 15 was then deployed while this monitoring was active; the new pod remained healthy and neither alert condition fired.

A synthetic Defender firing/email-delivery test has not been performed. The monitoring rollout itself is otherwise operationally complete.

## Change rules

Before changing Jenkins or a delivery image:

1. Record the current controller, builder, scanner and application-base identities.
2. Confirm the TestServer Jenkins data and DinD data locations are protected.
3. Retain a rollback image or immutable digest.
4. Change one controlled source branch.
5. Validate configuration and build candidates before container recreation.
6. Confirm Jenkins returns healthy with its jobs, credentials and build history intact.
7. Run a gated end-to-end release.
8. Verify the running registry digest independently from a local Docker image/config ID.
9. Reconcile the approved desired state into the authoritative Git repository.
10. Confirm the operational monitoring path remains healthy after release.
11. Record the before/after evidence in this area and the current daily-actions log.

For Defender, the Jenkins deploy helper currently advances the live Deployment by build tag and the Git-owned Kubernetes manifest records the approved immutable tag plus digest after release validation. Do not apply an older desired-state image over a newer healthy Jenkins deployment; reconcile Git first.

For Stage 6 Docker/Compose updates, candidate acquisition, deployment and durable closure are separate authority levels and must stay deliberately separated. A pre-approval candidate pull may mutate only the local image cache through its dedicated restricted identity. The full deployment executor remains post-approval only. A healthy deployment is not fully closed until Compose authority, catalogue and steady-state verification agree with the runtime.

## Planned documents

- Jenkins controller and DinD update SOP.
- Credential and build-log validation SOP.
- End-to-end release and Kubernetes reconciliation SOP.
- Jenkins controller/data recovery SOP.
- Private-registry publication and recovery notes.
- Final Stage 6 candidate-acquisition/closed-state-verification operating procedure after the Jenkins implementation is proven.
