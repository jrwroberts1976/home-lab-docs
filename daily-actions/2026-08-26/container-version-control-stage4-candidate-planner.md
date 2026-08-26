# Container Version Control — Stage 4 Candidate Planner Checkpoint

**Date:** 26 August 2026  
**Status:** READ-ONLY REGISTRY-IMAGE CANDIDATE PLANNING VALIDATED ACROSS CURRENT TESTSERVER ESTATE  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

This checkpoint supersedes the earlier Stage 4 note in `daily-actions.md` that identified the candidate image planner as the next engineering step.

## Completed in this checkpoint

The Stage 4 implementation is reviewed as three stacked units:

```text
#19  stage4/service-ownership
#20  stage4/image-comparator
#21  stage4/candidate-planner
```

Candidate-planner commits:

```text
f3de3b1  Add Stage 4 candidate image planner
707a6af  Fix service-specific candidate image extraction
```

The planner remains read-only and emits machine-readable evidence without performing image pulls, container recreation, restart or deployment.

## Validated planner path

The first complete real path used Dozzle on TestServer:

```text
running container
→ service ownership
→ clean authoritative Git checkout
→ Compose validation
→ exact service image extraction
→ runtime image identity
→ remote OCI index
→ linux/arm64 platform manifest
→ image comparator
→ read-only JSON plan
```

Authoritative source during validation:

```text
repository: jrwroberts1976/docker-env
revision:   232a364bd929b2ed3ed6ffa37dccd045f8c05843
```

For Dozzle the runtime RepoDigest and remote OCI index digest matched exactly, one compatible `linux/arm64` manifest was found, the comparator returned `same` via `exact-digest`, and deployment remained disabled/not performed.

## Fail-closed controls

Five deliberate planner tests passed:

1. clean checkout of the wrong Git repository was rejected;
2. dirty authoritative checkout was rejected;
3. local-build candidate was rejected pending provenance handling;
4. Jenkins platform exception was rejected; and
5. the valid Dozzle path continued to succeed.

Result:

```text
passed: 5
failed: 0
```

The exact staged planner blob was executed successfully before the initial planner commit.

## Secret-handling boundary

The planner validates the complete Compose model while discarding rendered stdout. Service-image extraction now uses:

```text
docker compose config --no-interpolate --format json
```

and pipes the model directly to `jq` to retain only:

```text
.services[$service].image
```

This avoids retaining a fully interpolated Compose document and also avoids the dependency-expansion behaviour of `docker compose config --images <service>`.

## Autokuma extraction defect and fix

The first full estate sweep exposed one planner defect for `autokuma`.

`docker compose config --images autokuma` returned both:

```text
louislam/uptime-kuma:1.23.16
ghcr.io/bigboot/autokuma@sha256:8acbd3ad3ec8cb6c066aa0ee541154921283ec78159015937128541921c47974
```

because Autokuma declares a Compose `depends_on` relationship with Uptime Kuma.

Commit `707a6af` replaced dependency-expanded image-list parsing with exact service-image extraction from the non-interpolated Compose model. Autokuma then returned its single authoritative image and validated as `same` via `exact-digest` on `linux/arm64`. Dozzle remained valid after the change.

## Full TestServer registry-image sweep

After the Autokuma fix, every automatically eligible registry-backed service on the current TestServer estate produced a safe read-only plan.

Final result:

```text
running containers:       30
eligible registry images: 24
planned successfully:     24
policy-blocked:            1
local-build skipped:       4
platform exceptions:       2
planner failures:          0
```

Policy results:

```text
23 same
 1 ordering-unknown-blocked
```

All successful plans resolved a compatible `linux/arm64` candidate platform.

### Important representative results

**Autokuma**

```text
candidate: ghcr.io/bigboot/autokuma@sha256:8acbd3ad3ec8cb6c066aa0ee541154921283ec78159015937128541921c47974
result:    same
method:    exact-digest
```

**Smokeping**

Git desired state remains digest-pinned even though runtime `Config.Image` is only `linuxserver/smokeping:latest`:

```text
candidate: linuxserver/smokeping:latest@sha256:a0d1e57744a2217a0fe83b7828cffe2cbce16f44e59c858bead8ff41e7b63581
result:    same
method:    exact-digest
```

This confirms the planner does not reduce the authoritative Git digest pin to a floating runtime tag.

**Maintenance page**

```text
candidate: nginx:alpine
result:    ordering-unknown-blocked
method:    same-tag-different-identity
```

The remote `nginx:alpine` digest has moved since the currently running image. The planner correctly treats this as a successful policy block rather than guessing whether the moving channel represents an upgrade or downgrade.

## Safety state

No image was pulled by the planner. No container was recreated, restarted or deployed. No `docker compose up` was executed. No Git mutation or deployment primitive exists in the planner. Jenkins has not been given Docker deployment authority by this work.

## Next Stage 4 work

Registry-image candidate planning is now validated across the complete current eligible TestServer estate.

Next controls:

1. add the read-only Trivy candidate security-validation gate;
2. implement local-build provenance handling;
3. add secret-readiness checks without exposing secret values;
4. produce the non-secret deployment-plan artifact with exact rollback identity; and
5. connect the proven read-only controls into Jenkins only after those gates are independently validated.

Deployment remains disabled throughout Stage 4.
