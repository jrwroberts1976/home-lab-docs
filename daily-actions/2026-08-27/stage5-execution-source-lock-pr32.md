# Stage 5 execution source lock and PR #32

Date: 2026-08-27

## Purpose

Record the exact source lock and merge boundary for the first human-approved Stage 5 execution transition for the `maintenance-page` pilot.

This milestone does **not** install execution authority on TestServer and does **not** perform a deployment.

## Proven source review

Repository: `jrwroberts1976/homelab-container-version-control`

Source branch:

`stage5/human-approved-execution-transition`

Reviewed implementation source commit:

`7918c6c4ed01c32333c781e6d9de3eeaa19e4773`

Final reviewed branch head before merge:

`d7d5f82d4c860c3fd479d43845f5525fdc7d521b`

The final read-only validation completed successfully on TestServer and confirmed:

- exact clean source checkout;
- existing Stage 4 source unchanged;
- existing Stage 5 inspection source unchanged;
- transition helper source frozen after review;
- executor wrapper source frozen after review;
- final execution policy contains no placeholders;
- live inspection policy remains unchanged;
- execution components remain absent from TestServer;
- executor account remains absent;
- maintenance-page remains on the exact rollback digest;
- no Stage 5 deployment performed.

## Final source hashes

Transition helper:

`73eb78453b87e86760cb9fafd556e11c2a5c43c8df2b2d3e87fa0429902d64d1`

Executor forced-command wrapper:

`2feea261deaccb92dccc1f9c982ed9f4360c6320ad84dba2d7b39e476582dc49`

Final execution policy:

`e8c629e34d16a02b2dc9a979dbe50da47dace810875bbc3296cead6285af2bc5`

Existing proven installed component hashes retained by the execution policy:

- authority gate: `561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda`
- deployment helper source: `a0df7b46aa01ffc9ef3fbf43cea43caeef34681ef22b759ae822ed2832cfc42a`
- inspector: `64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213`

## Policy identities

Pilot ID:

`stage5-maintenance-page-nginx-1.31.4-20260827`

Docker environment authority commit:

`f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`

Rollback:

`nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`

Candidate:

`nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913`

Candidate Linux/ARM64 manifest:

`sha256:57744b8fa99abc438b1fbde6bd69e4270d0984ccfdee60c661ec22243047373a`

## Identity separation

The proven inspection identity remains permanent and read-only:

- TestServer account: `homelab-stage5-pilot`
- Jenkins credential: `homelab-stage5-testserver-inspector`
- forced command remains the inspection-only wrapper;
- sudo authority remains exact `authority-gate inspect` only.

Execution is designed to use a separate identity after human approval:

- TestServer account: `homelab-stage5-executor`
- Jenkins credential: `homelab-stage5-testserver-executor`
- independent SSH key;
- source restricted to Jenkins `172.30.255.250`;
- no Docker group membership;
- literal forced-command allow-list only;
- no shell, arbitrary Docker/Compose, arbitrary service, digest, path or Git input.

The executor identity was still absent at this source-lock milestone.

## Human approval design

The future Stage 5 Jenkins pipeline remains:

1. bind inspection credential;
2. run `inspect maintenance-page`;
3. parse and assert the exact pilot/current/candidate/rollback/health/protected state;
4. block on Jenkins `input` restricted to `james` for this first pilot;
5. repeat inspection and fail if any critical identity drifted;
6. only after approval and drift check, bind the separate executor credential;
7. arm the exact pilot;
8. deploy exactly one `maintenance-page` update;
9. verify exact candidate, HTTP health and protected-state invariants;
10. disarm the transient execution activation;
11. use only the reviewed rollback path if required.

Jenkins remains a permanent self-deployment exception.

## PR and merge

Pull request:

`jrwroberts1976/homelab-container-version-control#32`

Title:

`Add human-approved Stage 5 execution transition`

PR head:

`d7d5f82d4c860c3fd479d43845f5525fdc7d521b`

Merged commit:

`a7fb8258b2d7a401e4bb494846b8a764e95aa0fc`

The PR changed only five new source/review files:

- `config/stage5-maintenance-page-execution-enabled.template.json`
- `docs/stage5-human-approved-execution-transition.md`
- `ops/testserver/homelab-stage5-executor-ssh`
- `ops/testserver/homelab-stage5-maintenance-page-transition`
- `scripts/validate-stage5-execution-transition-review.sh`

No existing Stage 4 or Stage 5 inspection implementation file was modified by this PR.

## Live host state at merge

Active inspection policy SHA256:

`adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`

Still absent:

- `/usr/local/libexec/homelab-stage5-maintenance-page`
- `/usr/local/libexec/homelab-stage5-maintenance-page-transition`
- `/usr/local/sbin/homelab-stage5-executor-ssh`
- `/etc/homelab-stage5/maintenance-page.execution-policy.json`
- `/etc/homelab-stage5/maintenance-page.enable`
- `homelab-stage5-executor` account
- deploy/rollback executor sudo authority
- Jenkins executor credential
- Jenkins Stage 5 execution job

Runtime remained:

`nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`

No container was changed or restarted by the source review or merge.

## Next gate

The next phase is **installation rehearsal**, not live deployment.

The rehearsal must use the exact merged source, stage execution components while leaving effective deployment authority false, and prove the existing inspection path remains unchanged before any executor identity or Jenkins execution credential is introduced.

NO EXECUTION AUTHORITY INSTALLED AT THIS MILESTONE.

NO STAGE 5 DEPLOYMENT PERFORMED.
