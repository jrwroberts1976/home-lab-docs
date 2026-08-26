# Container Version Control — Stage 4 Deployment Plan Checkpoint

**Date:** 26 August 2026  
**Status:** READ-ONLY DEPLOYMENT PLAN CONTRACT AND REAL GENERATOR PATHS VALIDATED  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

## Branch and scope

Stage 4 deployment-plan work started from merged implementation `main` at:

```text
298d43b8186b794c251eb3c8ddea2d046e26bb12
```

Working branch:

```text
stage4/deployment-plan
```

The milestone remains strictly non-deploying. The artifact may propose an action for review, but it cannot authorize or perform deployment.

## Frozen deployment-plan contract

Added:

```text
config/deployment-plan.schema.json
```

The contract records:

- service identity and ownership;
- authoritative Git revision and Compose file set;
- runtime image identity;
- candidate image identity;
- ownership, comparison, architecture, security, secret-readiness and local-build provenance gate results;
- final decision and proposed action; and
- explicit deployment safety state.

Deployment is structurally fixed to:

```json
{
  "allowed": false,
  "performed": false
}
```

Allowed decisions are:

```text
no-change
ready-for-review
rebuild-required
blocked
```

Allowed proposed actions are descriptive only:

```text
none
deploy-registry-image
rebuild-local-image
manual-review
```

No execution command, secret value, decrypted payload or credential field is part of the schema.

## Contract validation

Initial synthetic contract validation passed 8/8:

- four valid examples accepted: `no-change`, `ready-for-review`, `rebuild-required`, `blocked`;
- deployment-enabled artifact rejected;
- execution-like proposed action rejected;
- invalid security result rejected; and
- unexpected execution field rejected.

Real gate output discovery then established the exact existing JSON shapes. In particular:

- planner authority uses `compose_files[]`, not a guaranteed single Compose file;
- runtime and candidate platform identity is represented as `os` plus `architecture`.

The schema was hardened to those real shapes and the full synthetic matrix passed again 8/8.

The contract is treated as frozen for this Stage 4 milestone.

## Real gate interface discovery

Seven read-only real checks were captured successfully:

```text
Dozzle ownership resolver
Dozzle candidate planner
Dozzle Trivy security gate
Dozzle secret readiness
BirdNET ownership resolver
BirdNET local-build provenance
BirdNET secret readiness
```

Result:

```text
passed gates: 7
failed gates: 0
```

No stderr was produced, no obvious secret material appeared in captured JSON, and the authoritative Git repositories remained clean.

## Deployment-plan generator

Added:

```text
scripts/generate-deployment-plan.py
```

The generator orchestrates the existing proven gates rather than duplicating their validation logic.

For registry-backed images it uses:

```text
ownership resolver
→ candidate image planner
→ architecture comparison
→ service-scoped secret readiness
→ Trivy candidate security gate
→ deployment-plan artifact
```

For local builds it uses:

```text
ownership resolver
→ local-build provenance gate
→ service-scoped secret readiness
→ deployment-plan artifact
```

Platform exceptions remain blocked for manual review.

Static validation confirmed:

- Python compilation passes;
- CLI exposes only container, authority-root and Trivy-cache inputs;
- no Docker/Compose deployment, restart, pull, push or build primitive is present;
- no Git mutation primitive is present; and
- deployment remains explicitly disabled.

## Real generator validation

Two representative real services were exercised end-to-end.

### Dozzle — registry-image path

Result:

```text
comparison:        same
architecture:      pass
security:          pass
secret readiness:  pass
provenance:        not-applicable
decision:          no-change
proposed action:   none
deployment:        allowed=false, performed=false
```

The generated artifact contains the authoritative Git revision, Compose file, runtime image ID and digest, candidate index digest and target-platform digest.

### BirdNET exporter — local-build path

Result:

```text
comparison:        local-build-provenance-required
architecture:      not-applicable
security:          not-applicable
secret readiness:  pass
provenance:        same
decision:          no-change
proposed action:   none
deployment:        allowed=false, performed=false
```

The generated artifact records the local image identity and authoritative Compose/provenance state without inventing registry digests for a local build.

## Independent validation and safety proof

Both generated artifacts independently validated against the frozen JSON Schema.

Safety checks passed:

- no obvious password, token, credential, AGE/SOPS payload or private-key material appeared;
- no execution commands appeared in either artifact;
- Dozzle image ID unchanged;
- BirdNET image ID unchanged;
- Dozzle restart count remained `0`;
- BirdNET restart count remained `0`;
- Docker container object count remained `30`;
- Docker image object count remained `300`;
- all authoritative Git repositories remained clean; and
- the generator remained mutation-free after the real test.

Final real result:

```text
PASS: REAL DEPLOYMENT PLAN VALIDATION 2/2
PASS: registry-image path -> Dozzle no-change
PASS: local-build path    -> BirdNET no-change
PASS: deployment remained disabled and unperformed
```

## Next validation

Before staging or committing the implementation, exercise fail-closed generator paths, including:

- a real policy-blocked registry-image case; and
- the Jenkins platform-exception case.

Only after those paths are proven should the schema and generator be staged, exact staged blobs revalidated, committed and reviewed through a pull request.
