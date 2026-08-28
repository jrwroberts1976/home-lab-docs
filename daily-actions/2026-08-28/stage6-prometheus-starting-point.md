# Stage 6 Prometheus — Continuation Starting Point

Date: 28 August 2026

## Purpose

This note is the evidence-backed restart point for the Prometheus Stage 6 pilot. It records the exact current/candidate identities, source authority, generic framework blockers already discovered, and the safe order of work for the next session.

## Why Prometheus is the next pilot

LibreSpeed was checked first but is already current at `6.2.1`, so no update should be forced.

Prometheus has a real patch update available and is therefore a useful second Stage 6 service after Dashy:

```text
current=3.13.1
candidate=3.13.2
```

This deliberately uses the smaller `3.13.1 → 3.13.2` transition before considering the later `3.14.0` minor release.

## Current / rollback identity

```text
repository=prom/prometheus
version=3.13.1
immutable_ref=prom/prometheus@sha256:3c42b892cf723fa54d2f262c37a0e1f80aa8c8ddb1da7b9b0df9455a35a7f893
index_digest=sha256:3c42b892cf723fa54d2f262c37a0e1f80aa8c8ddb1da7b9b0df9455a35a7f893
local_image_id=sha256:4b91f0c2630ca36c5ed0275657a92a2e9270790b48d3ce7117adf1b468fceaa5
binary_revision=73ff57ce2b8161059ac7fe5188f03f1c3d22b29a
created=2026-07-10T08:49:11.358103752Z
platform=linux/arm64
```

The live container remained on this exact image after candidate acquisition.

## Candidate identity

```text
repository=prom/prometheus
version=3.13.2
immutable_ref=prom/prometheus@sha256:508729e0e2d18e11fd742a5a5ca70e557b940a93948c3c95fd0123a6fd538b69
index_digest=sha256:508729e0e2d18e11fd742a5a5ca70e557b940a93948c3c95fd0123a6fd538b69
platform_manifest_digest=sha256:819dcd34085a183b908a439fc9379f1b504c0431a837b5e5b2d37a259b21c179
config_digest=sha256:26bf7bb2ea9e4394b01ea4bd704e802ad4544eea9b2bc95a5dad244b342142d5
binary_revision=bb5dff00cf8fdfbf5c65e0531aa835fa238a43a2
created=2026-07-30T12:02:05.288407376Z
platform=linux/arm64
local=true
```

Candidate acquisition did not recreate, restart or otherwise mutate the running Prometheus container.

## Live runtime baseline

```text
container=prometheus
compose_project=monitoring
compose_service=prometheus
network=homelab_apps
user=1000:1000
restart_policy=unless-stopped
privileged=false
docker_socket=false
devices=false
ready_endpoint=http://127.0.0.1:9090/-/ready
ready_expected=200
```

Authoritative bind mounts from `docker-env`:

- `/home/james/docker/data/monitoring/prometheus/prometheus.yml` → `/etc/prometheus/prometheus.yml`;
- `/home/james/docker/data/monitoring/prometheus/linux-hosts.yml` → `/etc/prometheus/linux-hosts.yml` read-only;
- `/home/james/docker/data/monitoring/prometheus/data` → `/prometheus` persistent TSDB directory.

The two config files should retain SHA-256 content invariants. The TSDB data directory is mutable operational state and must be validated as an exact directory path/type invariant rather than by a static content hash.

## Git / Compose authority

The Prometheus Stage 6 image-variable prerequisite was reviewed and merged in `jrwroberts1976/docker-env` PR #19.

```text
authority_repository=docker-env
authority_revision=ce591602bc6300cad001eb445269f8f4b8933c53
compose_file=/home/james/docker/stacks/monitoring/docker-compose.yml
compose_sha256=bcf38b612b8319fef2e3d077f3a3e70599cbe0ddbd26a8789f35ca1fd2836b1d
image_variable=PROMETHEUS_IMAGE
default_image=prom/prometheus:v3.13.1
```

The reviewed Compose source resolves the default image to `3.13.1` and accepts the exact immutable Stage 6 candidate through `PROMETHEUS_IMAGE`.

## Generic framework compatibility gap discovered

The Dashy pilot proved the Stage 6 design, but Prometheus exposed two assumptions that must be generalised rather than bypassed.

### 1. Persistent mutable directory support

Original validator/inspector/executor behaviour treated every bind source as an immutable regular file with a mandatory SHA-256.

That is correct for configuration files but incorrect for the Prometheus TSDB directory.

Prepared model:

```text
source_kind=file       -> SHA-256 required
source_kind=directory  -> SHA-256 must be null
```

The directory path itself remains exact and must exist as a real directory, must not be a symlink, and must match the manifest/runtime mount shape.

### 2. Digest-pinned metadata verification

The Prometheus Docker image does not publish the OCI `org.opencontainers.image.version` and `org.opencontainers.image.revision` labels that the original inspector expected.

The image still provides strong immutable identity through:

- exact repository@index digest;
- exact ARM64 platform manifest digest;
- exact local config/image digest;
- exact OS/architecture;
- exact RepoDigest membership.

Prepared manifest mode:

```text
metadata_verification=oci-labels    # existing Dashy default
metadata_verification=digest-pinned # Prometheus-compatible mode
```

Dashy remains backward compatible and continues to use OCI-label verification by default.

## Generic compatibility branch status

Repository:

```text
jrwroberts1976/homelab-container-version-control
```

Branch:

```text
stage6/persistent-directory-support
```

Exact change scope:

```text
config/service-update-manifest.schema.json
ops/testserver/homelab-stage6-execute
ops/testserver/homelab-stage6-inspect
scripts/validate-stage6-service-manifest.py
```

Current evidence:

```text
shell syntax = PASS
Dashy schema/invariants = PASS
generic inspector guard = PASS
generic execution guard = PASS
directory + sha256 null = PASS
directory + static hash = REJECTED AS EXPECTED
file + sha256 null = REJECTED AS EXPECTED
unknown metadata mode = REJECTED AS EXPECTED
commit = NOT YET
push = NOT YET
host install = NOT YET
```

A quality cleanup remains: catch JSON Schema validation errors so invalid manifests produce a concise `FAIL:` message without a Python traceback.

## Restricted host boundary still blocks Prometheus

This is intentional and must remain so until separately reviewed.

The current Stage 6 forced-command wrappers and sudoers permit only Dashy service actions.

Prometheus onboarding must add exactly these literal commands and no variable service selection:

```text
inspect prometheus
arm prometheus
deploy prometheus
rollback prometheus
disarm prometheus
```

Required source files/validators must be updated together so the boundary remains finite and testable.

No wildcard sudo, arbitrary argument forwarding, general shell, direct Docker command, direct Compose command, SCP/rsync or Docker socket authority is acceptable.

## Prometheus transaction manifest still to be created

Planned file:

```text
config/services/prometheus-3.13.2.json
```

It should not be created until the generic compatibility change is merged.

Before finalising the manifest, capture fresh SHA-256 values for:

```text
/home/james/docker/data/monitoring/prometheus/prometheus.yml
/home/james/docker/data/monitoring/prometheus/linux-hosts.yml
```

The TSDB directory should use:

```text
source_kind=directory
sha256=null
```

The candidate should use:

```text
metadata_verification=digest-pinned
```

## Safe order of continuation

1. Finish clean JSON Schema failure handling on `stage6/persistent-directory-support`.
2. Re-run positive/negative semantic tests and source guards.
3. Review exact four-file diff.
4. Commit/push and open a review PR.
5. Independently review and merge the generic compatibility change.
6. Create a separate Prometheus host-boundary onboarding change.
7. Review/merge literal inspector/executor/sudoer permissions.
8. Capture fresh config-file hashes.
9. Create and validate `prometheus-3.13.2.json`.
10. Install only reviewed generic/Prometheus Stage 6 files and manifest on TestServer.
11. Prove read-only Prometheus inspection through Jenkins.
12. Create/validate the Prometheus human-approval Jenkins path.
13. Run pre-approval inspection and stop at human approval.
14. Reinspect for zero drift after approval.
15. Bind restricted executor only after approval and zero drift.
16. Arm, deploy exact candidate, verify readiness/invariants, and disarm.
17. Roll back only through the defined consumed-update path if an actual deployment failure requires it.
18. Record immutable Jenkins and host evidence in this daily-actions folder.

## Do-not-cross boundary

```text
Prometheus deployment performed = false
Prometheus live current = 3.13.1
Prometheus candidate local = true
Prometheus manifest installed = false
Prometheus inspector authority installed = false
Prometheus executor authority installed = false
Stage 6 generic compatibility installed = false
Jenkins unrestricted shell/Docker authority = false
```

Do not skip directly from candidate acquisition to `docker compose up`. The Stage 6 value is the reviewed chain of authority, approval, exact execution and evidence, not merely changing the container image.
