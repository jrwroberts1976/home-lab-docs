# Stage 5 pilot — end-to-end Jenkins-managed update proven

Date: 2026-08-27

Status: **COMPLETE / PASS**

## Outcome

The first Stage 5 human-approved Jenkins-managed container update completed successfully for `maintenance-page`.

Jenkins build #2 completed the reviewed flow:

1. source and host-key preflight;
2. pre-approval inspection;
3. exact artifact assertions with deployment still disabled;
4. human approval restricted to `james`;
5. second inspection after approval;
6. exact critical-state drift comparison;
7. executor credential binding only after approval + drift proof;
8. exact one-shot arm;
9. exact candidate deployment;
10. rollback skipped because deployment succeeded;
11. exact disarm;
12. archived evidence and terminal Jenkins `SUCCESS`.

## Source / pipeline identity

- `homelab-container-version-control` main after CPS fix: `a633d676d85e550f216b75c46674dae474e0db18`
- reviewed Stage 5 pipeline SHA256: `442e38ce1618509681b89208e9fe3dbfa87607fd9bf09985324b0a0739e5bfee`
- pilot ID: `stage5-maintenance-page-nginx-1.31.4-20260827`

## Immutable image identities

Rollback / previous current:

`nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`

Candidate / new current:

`nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913`

Candidate ARM64 image ID:

`sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5`

## Jenkins result

Build #2 finished `SUCCESS`.

Archived evidence proved:

- approval by `james`;
- pre/post-approval critical state identical;
- arm artifact exact and `result=armed`;
- deploy artifact exact and `deployment.performed=true`;
- rollback stage skipped because deploy succeeded;
- disarm artifact exact and `result=disarmed`;
- final Jenkins message: `STAGE 5 PILOT RESULT: DEPLOYED EXACT CANDIDATE AND DISARMED`.

## Independent TestServer terminal proof

Independent post-flight checks proved:

- active policy SHA256: `e8c629e34d16a02b2dc9a979dbe50da47dace810875bbc3296cead6285af2bc5`;
- active policy is byte-for-byte the reviewed staged execution policy;
- enable file absent;
- consumed marker present at `/var/lib/homelab-stage5/maintenance-page/stage5-maintenance-page-nginx-1.31.4-20260827.consumed`;
- consumed marker root:root mode 0600;
- consumed marker records `action=deploy`;
- current container uses the exact candidate immutable digest and exact candidate ARM64 image ID;
- new maintenance-page container restart count is 0 and state is running;
- published address remains exact `192.168.2.220:8088`;
- policy-pinned health URL `http://192.168.2.220:8088/` returned HTTP 200 with marker `Planned Maintenance | James Roberts`;
- Jenkins container ID and restart count unchanged;
- Jenkins DinD container ID and restart count unchanged;
- executor sudo surface remains the exact four reviewed commands;
- inspection identity remains read-only.

## Effective authority after disarm

Terminal state follows the reviewed Stage 5 design exactly.

`disarm` removes **only** the enable file. It intentionally does not restore the old inspection-ready policy file.

The active policy therefore remains the exact reviewed `execution-enabled` policy after terminal disarm, but effective deployment authority is **false** because:

1. the authority gate requires the root-owned matching enable file for deploy/rollback; and
2. that enable file is absent; and
3. the pilot has been consumed, so the helper rejects reuse of the same pilot ID.

Result:

- `PILOT ARMED: FALSE`
- `ONE-SHOT PILOT CONSUMED: TRUE`
- `EFFECTIVE DEPLOYMENT AUTHORITY: FALSE`

A later version update must use a new pilot policy, with the current candidate becoming that future pilot's rollback baseline.

## Verification corrections recorded

Two post-flight verifier assumptions were corrected during validation:

1. The verifier initially expected the inspection-ready policy SHA to be restored after disarm. This was incorrect. The reviewed state machine explicitly leaves the execution policy active and removes only the enable file.
2. The verifier initially tested health at `127.0.0.1:8088`. This was incorrect. The reviewed policy pins `expected_host_ip=192.168.2.220` and `health_url=http://192.168.2.220:8088/`.

Neither verifier issue reflected a deployment fault. The corrected checks passed.

## Final conclusion

**STAGE 5 PILOT: END-TO-END SUCCESS**

**JENKINS-MANAGED CONTAINER UPDATE: PROVEN**

The project has now demonstrated the intended steady-state safety properties for a real container update:

- exact immutable current/candidate/rollback identities;
- source-controlled authority;
- human approval before executor binding;
- second inspection and drift gate after approval;
- tightly scoped executor identity and sudo surface;
- no arbitrary Docker/Compose access from Jenkins;
- exact service-scoped deployment;
- health and protected-state validation;
- one-shot consumption and disarm;
- fail-closed behavior demonstrated independently by build #1 before arm;
- successful exact deployment demonstrated by build #2.
