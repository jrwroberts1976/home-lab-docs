# Container Version Control — Stage 4 Local-Build Provenance Checkpoint

**Date:** 26 August 2026  
**Status:** READ-ONLY LOCAL-BUILD PROVENANCE GATE VALIDATED  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

This checkpoint supersedes earlier Stage 4 notes that listed local-build provenance as future work.

## Implementation

Stage 4 now includes a sixth stacked review unit:

```text
#19  stage4/service-ownership
#20  stage4/image-comparator
#21  stage4/candidate-planner
#22  stage4/trivy-gate
#23  stage4/secret-readiness
#24  stage4/local-build-provenance
```

Local-build provenance commit:

```text
946f3ec  Add Stage 4 local build provenance gate
```

Files:

```text
config/local-build-provenance.yml
scripts/validate-local-build-provenance.py
```

The validator is read-only. It does not build, pull, tag, push, restart, recreate or deploy images/containers and contains no source-control mutation primitive.

## Eligible local-build estate

Five TestServer services are classified as `local-build`, but Jenkins is an explicit platform exception and is not eligible for automatic provenance handling.

The four non-exception local builds are therefore:

```text
birdnet-exporter
crowdsec-exporter
engineering-portfolio
projects-jrwroberts-co-uk
```

Registry coverage validation passed 4/4 with no missing or extra entries.

## Provenance strategies

Two explicit strategies are implemented.

### Path equivalence

Used when a runtime image was built from an older valid Git revision but its registered build inputs have not changed since that revision.

Required proof:

```text
runtime OCI source matches authoritative repository
runtime OCI revision is a valid Git commit
runtime revision exists in the authority repository
runtime revision is an ancestor of desired Git revision
registered build-input paths are unchanged from runtime revision to desired revision
```

If all checks pass, the local image is classified:

```text
same
```

If the revision is valid and ancestral but a registered build input changed, the result is:

```text
rebuild-required
```

If identity/ancestry cannot be trusted, the result is:

```text
provenance-blocked
```

### Exact head

Used where the deployed local image is expected to correspond exactly to the clean authoritative repository HEAD.

Required proof:

```text
runtime OCI revision == authoritative Git HEAD
```

A different valid revision is classified `rebuild-required`; missing or unverifiable identity remains blocked.

## Registered services

| Container | Repository | Strategy | Expected image |
|---|---|---|---|
| `birdnet-exporter` | `jrwroberts1976/docker-env` | `path-equivalence` | `birdnet-go-birdnet-exporter:local` |
| `crowdsec-exporter` | `jrwroberts1976/docker-env` | `path-equivalence` | `monitoring-crowdsec-exporter:local` |
| `engineering-portfolio` | `jrwroberts1976/engineering-portfolio` | `exact-head` | `james-roberts/engineering-portfolio:local` |
| `projects-jrwroberts-co-uk` | `jrwroberts1976/projects-jrwroberts-co-uk` | `exact-head` | `projects-jrwroberts-co-uk-projects-site:local` |

## Real estate-wide validation

Result:

```text
builds checked:      4
same:                4
rebuild-required:    0
provenance-blocked:  0
overall result:      same
```

Deployment state remained:

```json
{
  "allowed": false,
  "performed": false
}
```

### BirdNET exporter

Runtime OCI revision:

```text
dbac27d5d3c6e3b314701735188df6b21518ae43
```

Desired `docker-env` revision:

```text
232a364bd929b2ed3ed6ffa37dccd045f8c05843
```

Registered build inputs:

```text
stacks/birdnet-go/docker-compose.yaml
stacks/birdnet-go/birdnet-exporter
scripts/build-birdnet-exporter.sh
```

Validation proved the runtime revision exists, is an ancestor of desired state and none of those paths changed. Result: `same`.

### CrowdSec exporter

Runtime OCI revision:

```text
7f92a42a02f0bcb43c43f0c94eff698514770850
```

Desired `docker-env` revision:

```text
232a364bd929b2ed3ed6ffa37dccd045f8c05843
```

Registered build inputs:

```text
stacks/monitoring/docker-compose.yml
stacks/monitoring/crowdsec-exporter
scripts/build-crowdsec-exporter.sh
```

Validation proved the runtime revision exists, is an ancestor of desired state and none of those paths changed. Result: `same`.

### Engineering Portfolio

Authoritative clean Git HEAD and runtime OCI revision both equal:

```text
b917d8f0ce4dce41971b819c746f19dbcd3a2d0d
```

Result: `same`.

### Projects site

Authoritative clean Git HEAD and runtime OCI revision both equal:

```text
a6866fad989b5ab32fb26e938580900d30f14dcb
```

Result: `same`.

## Structural trust checks

Every registered local build passed the complete structural trust set:

- authoritative Git worktree clean;
- authoritative repository identity matches registry;
- service ownership resolves;
- ownership class is `local-build`;
- service is not a platform exception;
- ownership repository matches provenance registry;
- deployment disabled;
- runtime container exists and is running;
- runtime configured image matches expected local image;
- Docker image ID is internally consistent;
- required OCI `source`, `revision` and `created` labels present;
- OCI source matches authoritative repository;
- OCI revision is a valid 40-character Git commit and exists in the authority repository;
- authoritative Compose file exists and validates;
- expected Compose service exists;
- Compose contains a build declaration; and
- Compose image reference matches the registered local image.

## Fail-closed matrix

A deterministic fixture matrix was executed without changing any real container, image or repository.

Result:

```text
passed: 6
failed: 0
```

Validated decision boundaries:

1. bad OCI source label -> `provenance-blocked`;
2. unknown OCI revision -> `provenance-blocked`;
3. missing OCI provenance labels -> `provenance-blocked`;
4. Docker runtime/image identity mismatch -> `provenance-blocked`;
5. dirty authoritative Git worktree -> `provenance-blocked`; and
6. valid ancestral revision with changed registered build input -> `rebuild-required`.

The real baseline remained 4/4 `same` before and after the fixture tests.

## Exact staged-blob validation

The first exact-blob exercise exposed a harness issue rather than an implementation defect: relocating only the validator to `/tmp` caused its repository-relative ownership resolver path to resolve as `/scripts/resolve-service-ownership.sh`.

No code was changed merely to satisfy that artificial layout.

The test was corrected by constructing a repository-shaped temporary harness containing the exact staged validator/registry blobs plus the existing resolver dependencies.

The corrected exact-blob run proved:

- exactly the two intended provenance files were staged;
- staged blob hashes matched the validated worktree copies;
- the exact staged registry parsed;
- the exact staged validator compiled;
- no build, deployment or source-control mutation primitive was present;
- exact staged estate result remained 4/4 `same`;
- both exporter path-equivalence decisions were confirmed;
- both external-Git exact-head decisions were confirmed;
- all structural trust checks passed;
- deployment remained disabled everywhere;
- service-aware BirdNET validation passed; and
- all real authority repositories remained clean.

The exact validated files were then committed as `946f3ec` and pushed on `stage4/local-build-provenance`.

## Pull request state

Implementation pull request:

```text
homelab-container-version-control#24
Add Stage 4 local build provenance gate
```

Stack base:

```text
stage4/secret-readiness
05af557fabee550731a75d90d73afe2153cfe7f7
```

Provenance head:

```text
946f3ecbb9f2cd241c076bcd7e2c29d738075e9c
```

GitHub comparison confirmed exactly one commit ahead, zero behind, and exactly two added files (760 additions).

## Current Stage 4 state

Completed/proven implementation units:

```text
service ownership            validated
image version comparator     validated
candidate image planner      validated
Trivy candidate gate         validated
secret readiness             validated
local-build provenance       validated
```

Remaining read-only Stage 4 engineering before Jenkins integration:

```text
non-secret deployment-plan artifact
```

After that, the proven gates can be composed into the Jenkins validation flow while retaining the core safety boundary:

```text
deployment.allowed = false
deployment.performed = false
```

No image was built, pulled, retagged, pushed, restarted, recreated or deployed by this provenance checkpoint.