# Stage 6 Container Update Closeout — 31 August 2026

## Session scope

The 31 August working day was reopened in the evening for the Docker/Compose container-version-control Stage 6 workstream.

The session focused on proving the generic Jenkins update path against real services, extending the framework only where live evidence required it, and establishing the target operating model in which a normal update is selected and completed from Jenkins rather than by a chain of manual SSH steps.

The implementation repository is:

```text
jrwroberts1976/homelab-container-version-control
```

The Docker Compose authority repository is:

```text
jrwroberts1976/docker-env
```

## Target operating model

The intended business-as-usual flow is:

```text
WUD detects update
        |
        v
Jenkins reviewed service selector
        |
        v
candidate discovery / exact immutable identity
        |
        v
Jenkins pulls and verifies exact candidate
        |
        v
read-only pre-approval inspection
        |
        v
human approval
        |
        v
zero-drift reinspection
        |
        v
arm exact one-shot update
        |
        v
recreate only selected service
        |
        v
health/runtime/protected-container verification
        |
        +--> rollback if acceptance fails
        |
        v
disarm
        |
        v
promote Git Compose authority
        |
        v
promote catalogue + steady state
        |
        v
final read-only verification
        |
        v
SUCCESS_CLOSED
```

Normal operation should not require manual SSH, manual `docker pull`, manual Compose edits, manual catalogue edits or a separate closure procedure.

## Loki 3.7.7 — generic multi-host deployment proved

The ids-01 Loki update from `3.7.6` to `3.7.7` proved the generic multi-host Stage 6 execution route.

Jenkins successfully performed:

- reviewed manifest validation;
- pinned ids-01 host routing;
- read-only pre-approval inspection;
- human approval;
- exact zero-drift reinspection;
- executor credential binding only after approval/zero drift;
- one-shot arm;
- exact immutable deployment with `--no-deps --no-build --pull never --force-recreate`;
- health/runtime/protected-container verification;
- rollback skip because acceptance passed;
- disarm.

Independent runtime evidence confirmed the exact Loki 3.7.7 image running on ids-01 with restart count zero and `/ready` returning ready.

The Loki test also exposed the remaining end-to-end closure gap: runtime deployment could succeed while Git authority, catalogue and steady-state records remained behind. This drove the later closure design used during the Dozzle work.

## Generic Stage 6 framework improvements completed

### Multi-host routing

The generic pipeline now supports reviewed TestServer and ids-01 routes with fixed host-key pins and dedicated credentials. Manifest data cannot supply arbitrary SSH endpoints or credential IDs.

### Container HTTP health

Dozzle does not publish a host port and does not have a Docker healthcheck. A reviewed `container-http` health strategy was therefore added to the Stage 6 schema, validator, inspector and executor.

The strategy:

- uses a manifest-reviewed Docker network;
- dynamically resolves the live target container IP;
- checks a reviewed container port/path;
- verifies the expected HTTP status;
- never hard-codes the current container IP.

This enabled direct Dozzle health validation on `homelab_apps`, port `8080`, path `/`, expected HTTP `200`.

### Empty runtime user

Dozzle's Docker `Config.User` is the valid empty string. The generic inspector/executor previously rejected this despite the schema allowing it.

The narrow fix preserves exact equality while permitting an empty reviewed runtime user. No user substitution or broader relaxation was introduced.

### Transition/disarm container-http support

The Stage 6 transition helper initially supported terminal health for `docker-health` and `http` but not `container-http`.

This omission caused the post-deployment Dozzle disarm failure. The helper was extended with the same reviewed dynamic container-network HTTP logic and the Jenkins framework trust anchor was advanced to the reviewed framework commit.

## Dozzle 10.8.0 — deployment and final closure

### Starting point

Dozzle was selected as the first previously deferred service to requalify because it is stateless, uses a read-only Docker socket and had a clean WUD update available:

```text
10.7.2 -> 10.8.0
```

The Docker Compose authority was first converted to an image-variable form without changing the running service:

```yaml
image: ${DOZZLE_IMAGE:-amir20/dozzle:v10.7.2}
```

### Reviewed runtime shape

The reviewed Dozzle runtime is:

```text
host:              TestServer
compose project:   management
compose service:   dozzle
network:           homelab_apps
published ports:   none
Docker socket:     /var/run/docker.sock -> /var/run/docker.sock, read-only
privileged:        false
read-only rootfs:  false
restart policy:    unless-stopped
runtime user:      empty string
health:            container-http / 8080 / HTTP 200
```

### Candidate identity

The exact 10.8.0 candidate used by Stage 6 is:

```text
immutable ref:
amir20/dozzle@sha256:243666b0593ff33ed1373901575236f0d6bed8a2d6b451cdae4345969a7b6d5c

local image/config ID:
sha256:eca1774c3ff18eb6ff177d0d557b2ff37da5df6f7c617450b4eca48327f20ce8

platform manifest:
sha256:5bbab2ac6c3873268a7810fdc4d7e5dbc2d395a78bde403b8a758cf418a75fbb

platform:
linux/arm64

upstream revision:
f9dc18a0aa1d4e1b561364a5d76a045609eb3536
```

The reviewed candidate-acquisition helper pulled the exact manifest-pinned immutable reference into the local image cache and proved that no container ID, restart count or running state changed during acquisition.

### Jenkins build #13

Jenkins build #13 passed:

- manifest/schema/security validation;
- framework trust checks;
- host-key pinning;
- pre-approval inspection;
- exact rollback/candidate/runtime identity checks;
- human approval;
- zero-drift reinspection;
- executor preflight after approval;
- one-shot arm;
- exact candidate deployment;
- host-side runtime and protected-container invariants;
- rollback skip because deployment passed.

The exact 10.8.0 candidate was successfully deployed.

The build then failed during terminal disarm with:

```text
FAIL: unsupported health strategy
```

This was not a deployment failure. It was the missing `container-http` branch in the transition helper.

The historical Jenkins build therefore remains a failure / deployed-but-closure-incomplete result and must not be rerun to recreate Dozzle.

### Safe disarm recovery

After the reviewed transition-helper fix was merged and installed, only the disarm operation was rerun.

The recovery proved:

- the consumed marker was retained;
- one-shot enable/arm state was removed;
- the Dozzle container ID did not change;
- the image did not change;
- the restart count remained zero;
- direct container HTTP health remained `200`.

### Git authority promotion

`docker-env` PR #32 promoted the durable Dozzle Compose default to the exact immutable 10.8.0 reference.

Merged authority commit:

```text
ba183402d11b8a2def59bf7f50893c1667aff9ac
```

Both authority checkouts were then advanced to that exact commit:

```text
/home/james/docker
/var/lib/homelab-stage6/authority/docker-env
```

The resulting Compose SHA-256 is:

```text
80215935aa7815ed39853483934e834ef44c96dce8d0939f9644764c289a2485
```

The default Compose render now resolves to the exact immutable 10.8.0 image without an environment override.

The authority synchronisation did not recreate Dozzle.

### Catalogue and steady-state promotion

`homelab-container-version-control` PR #96 completed the metadata closure.

Merged framework/catalogue commit:

```text
95f4a0f32828547488370f372e314c76e263239c
```

The Dozzle catalogue entry now records:

```text
desired_version:       10.8.0
current_version:       10.8.0
coverage:              managed-tested
inspect_ready:         true
manifest:              dozzle-10.8.0.json
configured_image:      exact immutable 10.8.0 reference
```

A Stage 6 steady-state manifest was added and installed as:

```text
/etc/homelab-stage6/steady-state/dozzle.json
```

The first final verification attempt failed only because this installed steady-state file was missing. The reviewed source, validator and steady-state inspector hashes already matched. The missing manifest was then installed from the exact merged Git source and validated.

The read-only steady-state inspection passed.

Final outcome:

```text
SUCCESS_CLOSED: Dozzle 10.8.0 fully closed and steady-state verified
```

## Final Dozzle runtime

At closeout:

```text
container=8d1ba35013044b14dc05c80895670956fbd37d1885d4a6b9af7aa875af0b6228
configured_image=amir20/dozzle@sha256:243666b0593ff33ed1373901575236f0d6bed8a2d6b451cdae4345969a7b6d5c
image_id=sha256:eca1774c3ff18eb6ff177d0d557b2ff37da5df6f7c617450b4eca48327f20ce8
restart=0
state=running
health=HTTP 200 via reviewed container-http path
```

Dozzle is fully closed at the runtime, authority, catalogue and steady-state levels.

## Important Jenkins qualification status

Dozzle has **not** produced a clean end-to-end Jenkins `SUCCESS_CLOSED` build.

Build #13 deployed the exact candidate correctly but failed at disarm before the transition-helper fix. The later disarm, authority promotion, catalogue promotion and steady-state installation were completed through reviewed manual recovery steps.

Therefore the next Jenkins work is not to redeploy Dozzle. The Dozzle one-shot update has already been consumed and the running service is already correct.

Instead Jenkins needs a non-mutating closed-state verification mode so Dozzle can be used to prove the corrected Jenkins control path without a second recreation.

Recommended result for that mode:

```text
SUCCESS_VERIFIED_CLOSED
```

## Candidate acquisition must move into Jenkins

Candidate acquisition was still a separate reviewed manual step during the Dozzle update.

The target Jenkins workflow must pull the exact immutable candidate itself before human approval.

The existing host-side helper already has the correct safety properties:

- accepts only a reviewed service name;
- reads the exact candidate from the installed root-owned manifest;
- pulls only the immutable manifest-pinned reference;
- verifies local image/config ID, platform and RepoDigest;
- proves all container identities/restart states are unchanged;
- does not run Compose or recreate/restart/remove containers.

Jenkins should invoke this through a new narrowly scoped candidate-acquisition SSH identity/forced command.

Do **not** expose the full deployment executor credential for candidate acquisition before approval. The executor can arm/deploy/rollback/disarm and must remain unavailable until after human approval and zero-drift reinspection.

## Alloy checkpoint

After Dozzle closure, Alloy was selected as the next likely requalification candidate.

Read-only Stage 6 evidence collection passed on TestServer, including runtime/Compose identity and its established health endpoints:

```text
http://192.168.2.220:12345/-/ready
http://192.168.2.220:12345/-/healthy
```

Both were previously proven to return HTTP `200`.

Work deliberately stopped before Alloy candidate acquisition. No Alloy update was deployed and the candidate was not intentionally pulled as part of the evening closeout.

Alloy should remain untouched until the Jenkins candidate-acquisition and closed-state verification changes are implemented and Dozzle is successfully verified through Jenkins.

## Tomorrow's exact restart point

Resume in this order:

1. add a dedicated restricted Stage 6 candidate-acquisition Jenkins credential/forced-command route;
2. wire candidate acquisition into the Jenkins workflow before human approval;
3. retain deployment `--pull never` and the existing post-approval executor boundary;
4. add a non-mutating `VERIFY_CLOSED` / equivalent Jenkins action;
5. run the Jenkins closed-state verification against Dozzle without recreating it;
6. require `SUCCESS_VERIFIED_CLOSED`;
7. only then resume Alloy;
8. use Alloy as the first fresh service intended to prove the complete Jenkins flow including Jenkins-owned candidate pull and final `SUCCESS_CLOSED` closure.

## Do not repeat tomorrow

- Do not rerun the Dozzle 10.8.0 deployment.
- Do not run `docker compose up` for Dozzle during verification.
- Do not clear the Dozzle consumed audit marker.
- Do not hard-code the current Dozzle container IP.
- Do not pull an Alloy candidate manually before the Jenkins candidate-acquisition path is ready.
- Do not bind the powerful Stage 6 executor credential before approval/zero-drift.
- Do not treat the historical Jenkins build #13 failure as an application rollback requirement; the deployed Dozzle service is healthy and formally closed.

## Closeout state

The evening session ends with Dozzle fully closed and healthy, the generic framework extended for the runtime cases discovered during live testing, and the remaining Jenkins BAU gaps explicitly identified.

No further container mutation is required tonight.
