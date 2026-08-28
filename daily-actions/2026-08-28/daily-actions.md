# Daily Actions — 28 August 2026

## Starting position

Today continues the Stage 6 container-version-control work from the previous session.

The working objective remains to use Jenkins as a controlled orchestration layer for Docker container updates while keeping Git as the source of authority, immutable image identities as deployment intent, human approval as the mutation gate, and narrowly allow-listed service-scoped SSH/sudo commands as the execution boundary.

No Prometheus deployment has occurred.

## Evidence carried forward from 27 August

### Dashy

The Dashy Stage 6 pilot completed successfully.

- current version: `4.6.0`;
- immutable index digest: `sha256:40e3b27369002d4bce12cdffd5136b05924e1a7ea4e0d971a890557045fb1d59`;
- local ARM64 image/config ID: `sha256:f7c93e5961154c8ee4a4bce7f4448d30b9ee46def5ed8eb3ebef3d111370de99`;
- final Docker health: `healthy`;
- restart count: `0`;
- Stage 6 enable state removed/disarmed;
- update-specific consumed marker retained;
- rollback not required.

Dashy should remain untouched until a real newer release exists. A future release receives a new transaction manifest; the completed `dashy-4.6.0.json` record remains historical evidence.

### LibreSpeed

LibreSpeed was inspected as the intended next low-risk Stage 6 service, but there was no real update to apply.

- current: `6.2.1`;
- latest/current upstream checked: `6.2.1`;
- health: `healthy`;
- restart count: `0`;
- deployment required: no.

No no-op deployment should be performed simply to exercise the framework.

### Prometheus

Prometheus was selected as the next genuine update candidate.

Current / rollback identity:

```text
version=3.13.1
index_digest=sha256:3c42b892cf723fa54d2f262c37a0e1f80aa8c8ddb1da7b9b0df9455a35a7f893
local_image_id=sha256:4b91f0c2630ca36c5ed0275657a92a2e9270790b48d3ce7117adf1b468fceaa5
revision=73ff57ce2b8161059ac7fe5188f03f1c3d22b29a
platform=linux/arm64
```

Candidate identity:

```text
version=3.13.2
index_digest=sha256:508729e0e2d18e11fd742a5a5ca70e557b940a93948c3c95fd0123a6fd538b69
platform_manifest_digest=sha256:819dcd34085a183b908a439fc9379f1b504c0431a837b5e5b2d37a259b21c179
local_image_id=sha256:26bf7bb2ea9e4394b01ea4bd704e802ad4544eea9b2bc95a5dad244b342142d5
revision=bb5dff00cf8fdfbf5c65e0531aa835fa238a43a2
created=2026-07-30T12:02:05.288407376Z
platform=linux/arm64
```

Candidate acquisition changed only the local Docker image cache. The running Prometheus container remained unchanged, running, restart count `0`, with `http://127.0.0.1:9090/-/ready` returning `200`.

## Source-authority prerequisite completed

`docker-env` PR #19 added the Stage 6 image override for Prometheus and was merged.

```text
docker-env authority revision=ce591602bc6300cad001eb445269f8f4b8933c53
Compose SHA-256=bcf38b612b8319fef2e3d077f3a3e70599cbe0ddbd26a8789f35ca1fd2836b1d
```

The authoritative Prometheus image line is:

```yaml
image: ${PROMETHEUS_IMAGE:-prom/prometheus:v3.13.1}
```

Therefore the normal/default runtime remains `3.13.1`, while Stage 6 can inject an exact immutable image reference when a reviewed update is approved.

## Generic Stage 6 compatibility completed

Prometheus exposed two valid service patterns that the original Dashy-focused generic implementation did not yet model correctly:

1. Prometheus uses a persistent mutable TSDB bind-mounted directory. It must be verified as an exact path/type invariant, not content-hashed like an immutable config file.
2. The Prometheus image does not expose the OCI version/revision labels expected by the original inspector. Exact immutable ref, config ID, architecture and RepoDigest remain available as cryptographic image identity while the binary revision is separately recorded from `prometheus --version`.

The compatibility change was reviewed and merged through `homelab-container-version-control` PR #49.

```text
reviewed source commit=18e431aac7777a31a931053ca7b4a4198098d0b8
merge commit=5daee1d5f14b717180a4b87ffb5d52b73c7c043e
```

The merged change scope is exactly:

```text
config/service-update-manifest.schema.json
ops/testserver/homelab-stage6-execute
ops/testserver/homelab-stage6-inspect
scripts/validate-stage6-service-manifest.py
```

Validation completed:

- shell syntax: PASS;
- Dashy manifest backward compatibility: PASS;
- generic inspector source guard: PASS;
- generic execution source guard: PASS;
- persistent directory + `sha256: null`: PASS;
- persistent directory + static SHA-256: rejected as expected;
- file bind + missing SHA-256: rejected as expected;
- unknown metadata mode: rejected as expected;
- JSON Schema failures now return concise `FAIL:` output without traceback;
- file bind mounts remain hashed by default;
- persistent directory binds require exact directory type and no static hash;
- inspector and executor reject symlink bind sources;
- `digest-pinned` mode retains exact config ID, OS, architecture and RepoDigest gates;
- no host installation occurred;
- no Prometheus deployment occurred.

## Host-boundary status

The generic Stage 6 helpers can accept a service name, but the intentionally restricted SSH/sudo front doors are currently Dashy-only.

Prometheus is therefore **not authorised for Stage 6 execution yet**.

Before Prometheus can be deployed, reviewed source must explicitly add only these literal commands:

```text
inspect prometheus
arm prometheus
deploy prometheus
rollback prometheus
disarm prometheus
```

The existing no-wildcard/no-variable-service/no-general-shell/no-general-Docker security model must remain intact.

## Today’s next safe action

Onboard Prometheus into the restricted Stage 6 inspector/executor boundary in reviewed source, keeping every new command literal and service-scoped.

Only after that change is independently reviewed and merged should the new generic code and Prometheus authority be installed on TestServer.

## Safety state at current point

```text
Prometheus live version = 3.13.1
Prometheus live ready = HTTP 200
Prometheus candidate 3.13.2 local = YES
Prometheus deployment performed = NO
Prometheus Stage 6 manifest installed = NO
Prometheus Stage 6 enable state = ABSENT
Prometheus executor permission = NOT INSTALLED
Prometheus inspector permission = NOT INSTALLED
Generic compatibility source merged = YES
Generic compatibility code installed = NO
Jenkins general shell/Docker authority = NO
```

## Daily summary

### Completed today

- Created and merged the `2026-08-28` daily operational record, TODO list and Prometheus Stage 6 continuation starting point in `home-lab-docs`.
- Updated the `daily-actions` index so 27 and 28 August are visible in the standing operational record.
- Established the daily-summary convention so each day records both work completed that day and work genuinely carried forward.
- Clarified the nightly-report triage rule: the current day's report is reviewed when it arrives, normally around 08:00 local time, and safe planned work can continue beforehand rather than substituting yesterday's report.
- Added Jenkins dashboard/folder organisation as an explicit follow-up: each container should have its own Jenkins folder containing its related pipeline jobs, while shared/control-plane jobs remain separately grouped.
- Added the Proxmox VM Infrastructure-as-Code project to the backlog, covering Terraform-provisioned VM infrastructure and Ansible configuration for PostgreSQL, TimescaleDB and Nginx.
- Added a separate long-term roadmap item for phased migration of the current Docker platform onto Proxmox, with inventory, target architecture, migration waves, data movement, cutover, monitoring continuity and rollback planning.
- Completed the generic Stage 6 persistent-directory / digest-pinned compatibility change and merged `homelab-container-version-control` PR #49 at merge commit `5daee1d5f14b717180a4b87ffb5d52b73c7c043e`; all fail-closed and backward-compatibility gates passed, with no host installation and no Prometheus deployment.

### Carried forward

- Review today's nightly homelab report when it arrives around 08:00 and add any new evidence-backed actions to the current TODO.
- Explicitly onboard `prometheus` into the restricted Stage 6 inspector/executor SSH and sudo boundaries, keeping only literal service-scoped commands.
- Create and validate `config/services/prometheus-3.13.2.json` with exact rollback/candidate identities, persistent TSDB directory semantics and hashed config-file invariants.
- Build and prove the Prometheus Jenkins human-approval path, then perform the `3.13.1 → 3.13.2` deployment only after every gate passes.
- Tidy the Jenkins dashboard so container update pipelines are grouped by container/service in their own folders, preserving job history, credentials, triggers and the existing security boundary; keep Jenkins platform/control-plane utility jobs in a separate administrative grouping.
- Plan the Proxmox VM/IaC project for PostgreSQL, TimescaleDB and Nginx, including VM sizing, storage, networking, backup/restore, monitoring, secrets handling and acceptance criteria.
- Build a phased roadmap for migrating the current Docker platform to Proxmox, using the VM/IaC project to establish reusable Terraform/Ansible patterns before production workload migration.
- Publish Homelab Defender through the controlled external route and link it from the Engineering Portfolio.
- Audit Grafana Host Overview coverage and resolve any collection/query gaps deliberately.

This summary should be updated during the working session as carried-forward items are completed, deferred or otherwise resolved.
