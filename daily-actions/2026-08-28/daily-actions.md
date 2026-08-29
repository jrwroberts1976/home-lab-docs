# Daily Actions — 28 August 2026

## Status

**CLOSED — end-of-day record.**

The detailed working TODO and Prometheus starting-point note in this folder remain historical evidence of the state earlier in the day. This document records the final 28 August outcome and supersedes the earlier in-progress statements that Prometheus had not yet been deployed.

## Main objective

Continue Stage 6 container-version-control development without weakening the established security model:

- Git-reviewed authority;
- immutable image identities;
- separate inspector and executor identities;
- explicit human approval before mutation;
- exact post-approval zero-drift reinspection;
- no deployment-time image pulls;
- one-shot execution authority;
- health validation and rollback rules;
- protection of Jenkins, Jenkins-DinD and unrelated workloads;
- no general shell or unrestricted Docker authority for Jenkins.

## Completed — Prometheus generic Stage 6 pilot

Prometheus moved from application version `3.13.1` to `3.13.2` through the generic Stage 6 path.

Reviewed candidate identity:

```text
version=3.13.2
index_digest=sha256:508729e0e2d18e11fd742a5a5ca70e557b940a93948c3c95fd0123a6fd538b69
arm64_manifest=sha256:819dcd34085a183b908a439fc9379f1b504c0431a837b5e5b2d37a259b21c179
local_image_id=sha256:26bf7bb2ea9e4394b01ea4bd704e802ad4544eea9b2bc95a5dad244b342142d5
```

Jenkins Build #6 deployed the exact candidate successfully. The build was reported as historical `FAILURE` because the executor compared equivalent published-port JSON objects without canonical key ordering. The workload itself remained on the new candidate and healthy.

PR #58 fixed the false-negative by canonicalising JSON before comparison.

```text
PR58 merge=75a2694202c3c8aed2820a185451d5af3a57b3a8
```

Controlled recovery installed the exact corrected executor, preserved the already-running Prometheus candidate, retained the consumed audit marker and removed the one-shot enable state without recreating the container.

Final Prometheus state:

```text
application_version=3.13.2
live=YES
healthy=YES
one_shot_armed=NO
rollback_required=NO
Jenkins_unchanged=YES
Jenkins_DinD_unchanged=YES
```

## Completed — read-only Docker socket Stage 6 extension

Homepage required a narrowly reviewed Docker socket exception. Stage 6 was extended without generalising Docker socket access to ordinary services.

PR #60 merged the socket framework contract:

```text
framework_source=0884f49e415c02356f4f8bde586ea5f285ee7772
```

The exception remains fail-closed:

- `risk_class=medium` required;
- `runtime.docker_socket_allowed=true` required;
- exactly one `/var/run/docker.sock` bind;
- exact same source and destination;
- mount must be `rw=false`;
- source kind must be `socket`;
- host source must be a Unix socket;
- low-risk, writable, alternate-path, duplicate and policy-mismatch cases are rejected.

The reviewed socket-capable validator, inspector and executor were installed with exact hash verification and backup before replacement. No container was changed by the framework installation.

## Completed — Homepage 2.1.2 Stage 6 pilot

The Homepage Compose authority was updated through `docker-env` PR #21 so the default image remains v2.0.0 while Stage 6 may inject only a reviewed exact image value.

```text
docker_env_authority=788b302c67fc21618d471ab7951ebf379d2a5593
compose_sha256=9a1295c5c7848c578a9b339411b02b2320cb7bd4b78764fce1d6b661fe97287f
```

Reviewed candidate:

```text
version=2.1.2
index_digest=sha256:da9dca9ec258c628146bed1445da0853f2b88f0b10bafd97c091de807c363d60
arm64_manifest=sha256:e422a1ec7834b5cfac54e9cb1804475f7a4d61bb0c04002ebc59542bd8b3350d
local_image_id=sha256:3a2b25796deabbf5c77ed9efcca2e1cb270b64f00c70ca87cf797640e26705fe
revision=5873f8e7d5d09567f15d437f75f8509e3b5d3d94
```

The reviewed Homepage manifest was merged through PR #62 and deployed by Jenkins Build #8.

Build #8 proved:

- exact reviewed source checkout;
- pre-approval inspection;
- human approval;
- exact second inspection / zero drift;
- executor unavailable until after approval and zero drift;
- exact one-shot arm;
- immutable candidate deployment;
- health and runtime invariants;
- rollback correctly skipped because deployment succeeded;
- one-shot authority disarmed;
- evidence archived.

Independent post-deploy verification passed:

```text
homepage_version=2.1.2
homepage_image=ghcr.io/gethomepage/homepage@sha256:da9dca9ec258c628146bed1445da0853f2b88f0b10bafd97c091de807c363d60
homepage_image_id=sha256:3a2b25796deabbf5c77ed9efcca2e1cb270b64f00c70ca87cf797640e26705fe
homepage_health=healthy
homepage_restart_count=0
homepage_docker_socket=read-only
homepage_armed=false
stage6_build=8
```

Protected Jenkins, Jenkins-DinD and Prometheus containers remained unchanged.

## Completed — Stage 6 documentation checkpoint

The final Stage 6 checkpoint was refreshed and merged through `homelab-container-version-control` PR #63.

```text
merge=dd7588fe5c9ee211471058946861ad21412b64dc
```

It records the Prometheus recovery, Homepage pilot, socket exception, estate-updater contract and next development sequence. Stale documentation PR #55 was closed unmerged as superseded.

## Completed — three-host estate inventory

Read-only inventories were captured for all three active execution domains:

```text
TestServer     Docker Compose   linux/arm64   30 running containers
ids-01         Docker Compose   linux/amd64   17 running containers
k3s-node-01    k3s/containerd   linux/arm64   11 long-running controllers
```

No inventory collection pulled an image, recreated a container, changed a Compose file, changed a Kubernetes resource, armed Stage 6 or performed a deployment.

Key findings:

- Prometheus is `3.13.2` on TestServer and `3.13.1` on ids-01, making it the strongest first cross-architecture Stage 6 proof;
- Blackbox Exporter is already `0.28.0` on both Docker hosts and is a good same-version reporting case;
- cAdvisor is privileged/device-backed on both Docker hosts and requires a separate runtime class;
- Loki differs materially between hosts (`2.9.6` vs `3.7.6`) and must not be automatically converged;
- TestServer WUD has a writable Docker socket while ids-01 WUD is read-only;
- Kubernetes user workloads, k3s-managed components and network-critical MetalLB workloads were separated into distinct lifecycle classes;
- `demo/whoami` was verified as genuinely digest-pinned in the Deployment, active ReplicaSet and Pod specs;
- MetalLB is Helm-managed and its host-network components remain pinned/manual pending a dedicated Kubernetes network-critical contract.

## Completed — estate updater Phase 1

The first formal estate coverage catalogue and routing-only `homelab-update` front end were merged through PR #64.

```text
merge=2f9b3441f0581fdf27bd906fc876b7639a9da8fc
```

Phase 1 includes:

- TestServer, ids-01 and k3s-node-01 from day one;
- reviewed service/host/backend metadata;
- caller validation for service, desired version, hosts and action;
- rejection of arbitrary image, digest, Compose path and unknown options;
- fail-closed `prepare`, `deploy` and `rollback` actions;
- no SSH, Docker, kubectl, Jenkins or shell execution path;
- `host_contact_performed=false` and `mutation_allowed=false` in the routing plan.

TestServer source review passed all regression gates.

## Completed — steady-state inspection readiness correction

Before adding live host contact, review identified that a completed transition manifest is not automatically a valid steady-state inspection contract.

Homepage is successfully **managed-tested**, but its existing transition manifest describes rollback v2.0.0 and candidate v2.1.2. The existing Stage 6 inspector is specifically a pre-approval transition inspector and expects the live workload to still be the rollback identity.

PR #65 therefore corrected the estate model rather than misusing the transition inspector.

```text
merge=7d6ca7cb8693d4953889fc4093a2d086322cd76e
```

Homepage is now represented as:

```text
coverage=managed-tested
inspect_ready=false
blocker=consumed-transition-manifest-requires-steady-state-inspector
```

Prometheus remains separately blocked by its authority roll-forward requirement.

## End-of-day Stage 6 state

```text
Prometheus 3.13.2 TestServer pilot = COMPLETE
Homepage 2.1.2 TestServer pilot = COMPLETE
Generic Docker Compose Stage 6 path = PROVEN
Medium-risk read-only Docker socket contract = PROVEN
Human approval / zero-drift gate = PROVEN
One-shot arm / consume / disarm = PROVEN
Three-host estate inventory = COMPLETE
Estate updater Phase 1 routing-only front end = MERGED
Steady-state inspection readiness model = CORRECTED
Phase 2 steady-state inspector = NOT YET IMPLEMENTED
ids-01 Stage 6 execution backend = NOT YET INSTALLED
k3s Stage 6 backend = NOT YET IMPLEMENTED
```

## Daily summary

### Completed today

- Completed the Prometheus `3.13.1 -> 3.13.2` generic Stage 6 pilot and controlled false-negative recovery.
- Added and installed the narrow medium-risk read-only Docker socket framework extension.
- Completed the Homepage `2.0.0 -> 2.1.2` Stage 6 pilot through Jenkins Build #8 with independent post-deploy verification.
- Refreshed and merged the final Stage 6 documentation checkpoint; closed stale PR #55.
- Captured read-only estate inventories for TestServer, ids-01 and k3s-node-01.
- Classified Docker, Kubernetes, platform-managed, special-risk, local-build and pinned/manual workload classes.
- Created and merged the three-host estate updater Phase 1 catalogue and routing-only front end.
- Corrected the model so `managed-tested` and current `inspect-ready` state are distinct.

### Carried forward to 29 August

- Build the new **steady-state read-only inspection contract** rather than reusing the pre-approval transition inspector.
- Start the steady-state inspector with Homepage on TestServer, with no arm/deploy/rollback capability.
- Resolve shared authority roll-forward debt for Prometheus and Dashy before expecting their old transition manifests to inspect successfully.
- Add the ids-01 read-only Stage 6 backend and use Prometheus `3.13.2` as the first amd64/cross-host proof after review.
- Add a read-only Kubernetes inspection backend for k3s-node-01, beginning with digest-pinned `demo/whoami`.
- Continue workload onboarding only through explicit reviewed runtime classes; do not weaken Docker socket, privileged/device, host-network, stateful or network-critical policies to increase coverage.
- Review the 29 August nightly homelab report when it arrives around 08:00 and add only new evidence-backed actions.
- Keep Jenkins dashboard organisation, Proxmox VM/IaC planning, Docker-to-Proxmox migration planning, Homelab Defender publication and Grafana Host Overview audit in the secondary backlog until the current Stage 6 priority reaches a clean checkpoint.

**28 August is closed.**
