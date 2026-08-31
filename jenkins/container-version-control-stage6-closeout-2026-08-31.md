# Container Version Control — Stage 6 Jenkins Closeout — 31 August 2026

## Status

The Docker/Compose container-version-control project has moved beyond the earlier Stage 4 assessment-only state.

By the end of 31 August, the generic Stage 6 Jenkins path had performed real controlled service deployment on TestServer and `ids-01` with approval, zero-drift and rollback boundaries.

The remaining work is to turn the proven component steps into the intended single business-as-usual Jenkins workflow.

## Current proven Jenkins controls

The generic Stage 6 pipeline now proves and enforces:

- reviewed service-update manifests;
- reviewed TestServer/ids-01 host routes;
- strict host-key checking;
- dedicated inspector/executor credentials;
- read-only pre-approval inspection;
- exact authority, rollback, candidate and runtime identity checks;
- human approval;
- second read-only inspection after approval;
- exact zero-drift comparison;
- executor credential exposure only after approval and zero drift;
- exact one-shot update IDs;
- selected-service-only recreation;
- `--no-deps --no-build --pull never --force-recreate` deployment;
- Docker health, fixed HTTP and internal Docker-network `container-http` health;
- protected-container identity/restart checks;
- reviewed rollback;
- disarm after terminal acceptance.

Manifest content cannot select arbitrary credentials or SSH targets.

## Loki proof

Loki `3.7.7` on `ids-01` proved the generic multi-host deployment/disarm path.

The deployment succeeded and remained healthy with restart count zero while protected Grafana/Prometheus containers remained unchanged.

The Loki run exposed an important distinction: successful runtime deployment did not yet mean Git authority, estate catalogue and steady-state closure were complete.

## Dozzle proof and framework lessons

Dozzle `10.8.0` was selected as a previously deferred service and requalified using:

- a read-only Docker socket;
- no published host port;
- reviewed `container-http` health on `homelab_apps:8080/`;
- an explicitly reviewed empty Docker runtime user.

Jenkins build #13 passed pre-approval inspection, human approval, zero-drift proof and exact deployment. The candidate itself deployed successfully.

The build subsequently failed at disarm because the transition helper had not yet implemented terminal `container-http` health. This was a framework closure failure, not a Dozzle application failure.

The transition helper was fixed and reviewed. Dozzle was then disarmed without recreation, its Compose authority was promoted to the exact immutable image, the catalogue was promoted, a steady-state manifest was installed, and the final read-only steady-state verification passed.

Dozzle is therefore fully closed, but build #13 is not a clean end-to-end Jenkins success.

Do **not** rerun the consumed Dozzle deployment simply to obtain a green Jenkins history entry.

## Candidate acquisition must be Jenkins-owned

During the Dozzle test, candidate acquisition was still executed as a separate reviewed host step.

The target workflow requires Jenkins to acquire the candidate itself before human approval.

The existing host-side helper already enforces the right behaviour:

- accepts only a reviewed service name;
- reads the root-owned installed Stage 6 manifest;
- pulls only the exact immutable manifest-pinned candidate reference;
- verifies local image/config ID, RepoDigest and platform;
- snapshots container state before and after;
- fails if any container identity/restart/running state changes;
- does not run Compose or mutate the running service.

This operation mutates only the local Docker image cache.

### Credential boundary

Candidate acquisition must not use the current full Stage 6 executor credential before approval.

The executor can arm, deploy, rollback and disarm, so exposing it to perform a pre-approval image pull would weaken the existing security model.

Create a dedicated candidate-acquisition SSH identity/forced-command route whose only useful operation is conceptually:

```text
acquire <reviewed-service>
```

The full executor remains unavailable until after:

```text
pre-approval inspection
        |
        v
human approval
        |
        v
second read-only inspection
        |
        v
zero-drift proof
```

Deployment continues with `--pull never` so the exact already-verified local image is the only candidate that can be recreated.

## Closed-state verification mode

Jenkins needs a non-mutating action for already-closed services.

For Dozzle, a `VERIFY_CLOSED` or equivalent action should verify:

- the reviewed service/catalogue identity;
- installed steady-state manifest identity;
- root-owned and live Git authority commit/Compose hash;
- exact configured immutable image;
- exact local image ID;
- runtime user/network/mount/restart/privilege invariants;
- health;
- protected containers;
- no arm/deployment authority present.

It must not:

- recreate the target;
- arm a consumed update;
- clear audit/consumed state;
- use the deployment executor unnecessarily.

Recommended explicit successful result:

```text
SUCCESS_VERIFIED_CLOSED
```

This is the correct way to prove the corrected Jenkins control path against Dozzle.

## Desired complete BAU flow

```text
reviewed service selector
        |
        v
candidate discovery
        |
        v
restricted Jenkins candidate acquisition
        |
        v
exact candidate + no-container-mutation proof
        |
        v
pre-approval inspection
        |
        v
human approval
        |
        v
zero-drift reinspection
        |
        v
post-approval executor
        |
        v
arm -> deploy selected service -> verify
        |
        +--> reviewed rollback on acceptance failure
        |
        v
disarm
        |
        v
promote/synchronise Git Compose authority
        |
        v
promote catalogue + steady state
        |
        v
install reviewed steady-state data
        |
        v
final read-only verification
        |
        v
SUCCESS_CLOSED
```

The operator should ultimately select a reviewed installed service from Jenkins rather than type a manifest filename.

## Next fresh service

TestServer Alloy has passed its initial read-only Stage 6 requalification evidence collection.

Its established health endpoints are:

```text
http://192.168.2.220:12345/-/ready
http://192.168.2.220:12345/-/healthy
```

Both have been proven HTTP `200`.

The WUD update observed for TestServer Alloy is `1.18.0 -> 1.19.2`.

No Alloy candidate was intentionally pulled and no Alloy deployment was performed before the 31 August closeout.

Resume Alloy only after:

1. restricted Jenkins candidate acquisition is implemented;
2. the Jenkins `VERIFY_CLOSED` path successfully verifies Dozzle without recreation.

Alloy should then be the first fresh service intended to prove the complete Jenkins-owned candidate-pull and final-closure flow.

## Result-state model

The end-to-end workflow should distinguish at least:

```text
SUCCESS_CLOSED
SUCCESS_VERIFIED_CLOSED
DEPLOYED_BUT_CLOSURE_INCOMPLETE
ROLLED_BACK_CLOSED
PRE_DEPLOYMENT_FAILED
MANUAL_REVIEW_REQUIRED
```

A healthy running candidate is not `SUCCESS_CLOSED` until authority, catalogue and steady-state closure are all verified.

## Related documentation

- [Jenkins Operations](README.md)
- [Jenkins service overview](../service-overviews/jenkins.md)
- [Dozzle](../service-overviews/dozzle.md)
- [Loki](../service-overviews/loki.md)
- [Alloy](../service-overviews/alloy.md)
- [31 August Stage 6 detailed closeout](../daily-actions/2026-08-31/stage6-container-update-closeout.md)
