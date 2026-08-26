# Container Version Control — Stage 4 Trivy Candidate Security Gate

**Date:** 26 August 2026  
**Status:** READ-ONLY TRIVY CANDIDATE SECURITY GATE VALIDATED  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

This checkpoint follows the full 24/24 registry-image candidate-planner validation and supersedes earlier Stage 4 notes that listed Trivy candidate validation as the next engineering step.

## Stacked implementation state

Stage 4 is now reviewed as four stacked units:

```text
#19  stage4/service-ownership
#20  stage4/image-comparator
#21  stage4/candidate-planner
#22  stage4/trivy-gate
```

Trivy-gate commit:

```text
50da6a0  Add Stage 4 Trivy candidate security gate
```

GitHub comparison confirms `stage4/trivy-gate` is exactly one commit ahead of `stage4/candidate-planner` and adds only:

```text
scripts/validate-image-security.py
```

## Gate contract

The gate consumes the JSON produced by `scripts/plan-image-update.py` and requires:

```text
mode: read-only
deployment.allowed: false
deployment.performed: false
planner result: same | upgrade
```

It then:

1. validates the candidate SHA-256 index digest;
2. reconstructs the exact immutable `repository@sha256:<digest>` candidate;
3. uses Trivy with `--image-src remote` and the planner-selected platform;
4. scans vulnerabilities only;
5. evaluates HIGH and CRITICAL severities;
6. validates the Trivy `ArtifactName` and `RepoDigests` against the expected immutable candidate; and
7. emits a small non-secret JSON gate result.

Gate outcomes are:

```text
pass                exit 0
security-blocked    exit 1
validation error    exit 2
```

A planner result already blocked by ordering/downgrade policy does not proceed to Trivy.

## Trivy policy

Validated Trivy version:

```text
0.72.0
```

The Stage 4 gate uses the same core vulnerability policy already proven elsewhere in the homelab Jenkins work:

```text
--scanners vuln
--severity HIGH,CRITICAL
--skip-version-check
```

For registry-backed Stage 4 candidates it additionally forces:

```text
--image-src remote
--platform <planner os/arch>
```

This avoids using Docker's local image store as the scan source and does not require `docker pull`.

## Real Dozzle validation

A fresh read-only Dozzle planner result was used as the first real Trivy path.

Exact immutable candidate:

```text
amir20/dozzle@sha256:01f9018ffdaa0ec523f9a91dea3eff65b25cdb5f0566ac6d5a2cb4cf591e35e9
```

Platform:

```text
linux/arm64
```

The Trivy report returned:

```text
ArtifactName: exact expected immutable candidate
RepoDigest:   exact expected immutable candidate
HIGH:         0
CRITICAL:     0
result:       pass
```

The gate output also preserved:

```json
{
  "deployment": {
    "allowed": false,
    "performed": false
  }
}
```

## Docker-state safety proof

Docker state was measured before and after the real remote scan.

Dozzle image ID remained:

```text
sha256:f1480337d833d51986224a50211780b6ccf2b4cbf0f92be3b0eab4b44b6c469d
```

Docker image-object count remained:

```text
before: 300
after:  300
```

Result:

```text
PASS: Trivy gate did not alter Docker image state
```

The script contains no Docker pull, container restart/recreation, Compose deployment, Git mutation or deployment primitives.

## Trivy cache handling

An isolated first proof downloaded a fresh vulnerability database and populated approximately 1.3 GB of Trivy cache state.

The validated Stage 4 flow therefore uses an explicit configurable cache path. Manual validation currently uses:

```text
/var/tmp/homelab-container-version-control-trivy-cache
```

The cache is persistent between validations so the vulnerability database does not need to be downloaded from scratch every run. A future Jenkins integration should provide a dedicated persistent Trivy cache with the same separation from Docker state.

The gate records available Trivy DB metadata such as DB version, update time and next-update time in its machine-readable result.

## Deterministic fail-closed validation

A controlled fake Trivy executable was used only for deterministic policy tests, avoiding dependence on the changing vulnerability state of a deliberately vulnerable public image.

Result:

```text
passed: 9
failed: 0
```

Validated cases:

1. non-read-only planner mode rejected before Trivy invocation;
2. deployment-enabled planner input rejected before Trivy invocation;
3. policy-blocked planner result rejected before Trivy invocation;
4. candidate image/index-digest mismatch rejected;
5. invalid SHA-256 candidate digest rejected;
6. eligible `upgrade` reaches the security gate and can pass;
7. controlled HIGH vulnerability returns `security-blocked` and exit code 1;
8. mismatched Trivy artifact identity is rejected; and
9. Trivy execution failure fails closed.

This proves both the positive scan path and the negative security-control paths without introducing deployment capability.

## Exact staged-blob validation

Before commit, the exact staged `validate-image-security.py` blob was:

1. materialised from the Git index;
2. compiled successfully;
3. checked again for Docker/Git mutation primitives;
4. executed against a fresh real Dozzle candidate plan using Trivy `0.72.0`; and
5. verified to leave Docker image state unchanged.

Only after those checks was commit `50da6a0` created and pushed.

## Current Stage 4 position

The following read-only controls are now independently validated:

```text
service ownership
runtime -> Git authority resolution
version-order / downgrade policy
immutable runtime/candidate identity
architecture / manifest compatibility
full current TestServer registry-image candidate planning (24/24)
Trivy HIGH/CRITICAL candidate security gate
```

Deployment remains disabled.

## Next Stage 4 work

Remaining controls before Jenkins integration are:

1. implement local-build provenance handling;
2. add secret-readiness validation without exposing secret values;
3. produce the non-secret deployment-plan artifact including exact rollback identity; and
4. connect the independently validated read-only controls into Jenkins.

Guarded deployment, service recreation, health checks and rollback execution remain later-stage work and are not enabled by this checkpoint.
