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

## Generic Stage 6 compatibility work in progress

Prometheus exposed two valid service patterns that the original Dashy-focused generic implementation did not yet model correctly:

1. Prometheus uses a persistent mutable TSDB bind-mounted directory. It must be verified as an exact path/type invariant, not content-hashed like an immutable config file.
2. The Prometheus image does not expose the OCI version/revision labels expected by the current inspector. Exact digest, config digest, architecture and RepoDigest remain available and can be used as cryptographic image identity while the binary revision is separately recorded from `prometheus --version`.

A review branch exists in `homelab-container-version-control`:

```text
stage6/persistent-directory-support
```

The prepared change scope is exactly:

```text
config/service-update-manifest.schema.json
ops/testserver/homelab-stage6-execute
ops/testserver/homelab-stage6-inspect
scripts/validate-stage6-service-manifest.py
```

Validation already completed:

- shell syntax: PASS;
- Dashy manifest backward compatibility: PASS;
- generic inspector source guard: PASS;
- generic execution source guard: PASS;
- persistent directory + `sha256: null`: PASS;
- persistent directory + static SHA-256: rejected as expected;
- file bind + missing SHA-256: rejected as expected;
- unknown metadata verification mode: rejected as expected;
- no commit, push or host installation has occurred for this branch yet.

The only cleanup identified before commit is to catch `jsonschema.ValidationError` and report a concise `FAIL:` message rather than a Python traceback.

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

Finish and revalidate the generic persistent-directory/digest-pinned framework branch, then review its final four-file diff before committing or pushing it.

Only after that change is merged should Prometheus service onboarding begin.

## Safety state at start of day

```text
Prometheus live version = 3.13.1
Prometheus live ready = HTTP 200
Prometheus candidate 3.13.2 local = YES
Prometheus deployment performed = NO
Prometheus Stage 6 manifest installed = NO
Prometheus Stage 6 enable state = ABSENT
Prometheus executor permission = NOT INSTALLED
Prometheus inspector permission = NOT INSTALLED
Generic compatibility branch committed = NO
Generic compatibility code installed = NO
Jenkins general shell/Docker authority = NO
```

This file should be updated during the working session whenever a material Stage 6 change is completed, rejected, rolled back or left outstanding.
