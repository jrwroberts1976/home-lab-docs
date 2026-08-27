# Stage 5 Restricted Wrapper Design — maintenance-page

**Date:** 27 August 2026  
**Status:** DESIGN ONLY — NO DEPLOYMENT AUTHORITY ENABLED  
**Pilot:** `maintenance-page`

## Purpose

Define the minimum host-side execution authority required for the first Stage 5 pilot without weakening or extending the proven Stage 4 read-only validator path.

This document does not create an account, SSH key, sudo rule, deployment helper, Jenkins credential, pipeline deployment stage or Docker/Compose authority.

Current safety state remains:

```text
Stage 4 = COMPLETE
READ-ONLY
deployment.allowed=false
deployment.performed=false
Stage 5 deployment authority = NOT ENABLED
Stage 5 deployment performed = NO
```

## Core design decision: keep Stage 4 immutable

Do not add deployment verbs to `homelab-stage4-validation-ssh` and do not grant deployment rights to `homelab-validator`.

The existing Stage 4 path remains dedicated to:

```text
ping
plan <container>
```

The existing Jenkins credential `homelab-stage4-testserver-validator` remains read-only.

Stage 5 uses a separate identity, separate forced-command wrapper, separate Jenkins credential and separate root-owned policy.

This prevents a Stage 5 implementation defect from silently widening the already-proven Stage 4 trust boundary.

## Proposed Stage 5 identity

Host account:

```text
homelab-stage5-pilot
```

Proposed Jenkins credential ID:

```text
homelab-stage5-testserver-pilot
```

Network path remains the already-proven dedicated Jenkins validation transport:

```text
Jenkins source:  172.30.255.250
TestServer:      172.30.255.249:22
```

The Stage 5 account must not join the Docker group and must not receive unrestricted sudo.

Its SSH key must be separate from the Stage 4 validator key and restricted to:

```text
restrict,from="172.30.255.250"
```

Effective SSH policy must continue to disable PTY, X11 and TCP forwarding.

## Forced-command boundary

Proposed forced-command entry point:

```text
/usr/local/sbin/homelab-stage5-pilot-ssh
```

It must be root-owned and not writable by the Stage 5 account or Jenkins runtime user.

Allowed SSH command vocabulary for the first pilot:

```text
ping
inspect maintenance-page
deploy maintenance-page
rollback maintenance-page
```

Everything else is rejected.

The service name is not a general parameter. Only the literal service `maintenance-page` is valid in the pilot wrapper.

No arbitrary digest, Compose path, project name, shell fragment or Docker argument is accepted from SSH input.

## Privilege boundary

The SSH forced-command wrapper itself runs without Docker group membership.

Mutation is delegated only to one root-owned helper, proposed as:

```text
/usr/local/libexec/homelab-stage5-maintenance-page
```

The Stage 5 account may receive passwordless sudo for this helper only.

The helper must:

- be root-owned and non-writable by the Stage 5 account;
- accept only `inspect`, `deploy` and `rollback` internal actions;
- load all deployment identities from a root-owned policy file;
- never evaluate caller-provided shell code;
- never execute arbitrary Docker, Compose, Git or filesystem commands supplied by the caller;
- never target any service other than `maintenance-page`.

No direct Docker socket access is granted to the Stage 5 SSH account.

## Root-owned pilot policy

Proposed policy location:

```text
/etc/homelab-stage5/maintenance-page.policy
```

The policy is installed only after review and must pin the complete pilot identity, including:

```text
pilot_id
service=maintenance-page
compose_project=maintenance-page
compose_file=/home/james/docker/stacks/maintenance-page/docker-compose.yml
authoritative_git_commit
compose_sha256
nginx_config_sha256
index_html_sha256
candidate_image_digest
rollback_image_digest
expected_network=homelab_apps
expected_host_ip=192.168.2.220
expected_host_port=8088
expected_container_port=80
health_url=http://192.168.2.220:8088/
health_marker=Planned Maintenance | James Roberts
```

The policy must not contain credentials or private key material.

For the selected baseline, the currently proven immutable rollback identity is:

```text
nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
```

The candidate digest remains unset until separately selected and reviewed.

## Configuration identity and expected runtime state

The helper must fail closed unless these immutable live files match the policy hashes immediately before deployment:

```text
/home/james/docker/stacks/maintenance-page/docker-compose.yml
/home/james/docker/stacks/maintenance-page/nginx/default.conf
/home/james/docker/stacks/maintenance-page/html/index.html
```

The following are explicitly not part of immutable config identity:

```text
html/change.json
  expected runtime-generated change-control state

docker-compose.yml.bak-*
  inert local backup residue, not active Compose input
```

Any other unexpected file/config difference affecting the mounted runtime must stop before deployment.

## Candidate image model

The pilot must never deploy a floating tag.

Before authority installation, the candidate must be an exact reviewed digest:

```text
nginx@sha256:<candidate>
```

The candidate image must already be locally available and verified before the human approval stage. The first pilot wrapper should not include a general-purpose `docker pull` capability.

This keeps image acquisition outside the deployment authority boundary for the first pilot.

## Compose image pinning model

The authoritative maintenance-page Compose definition should be changed through review so its image can be explicitly pinned while still allowing the exact rollback digest to be supplied by the root-owned helper.

Preferred pattern:

```yaml
image: "${MAINTENANCE_PAGE_IMAGE:-nginx@sha256:<reviewed-candidate-digest>}"
```

Properties:

- the default Git state is an immutable reviewed candidate digest;
- forward deployment can use the reviewed default or explicitly set the exact same candidate digest;
- rollback can set `MAINTENANCE_PAGE_IMAGE` to the root-policy rollback digest;
- no temporary Compose override file is required;
- the active Compose project remains `maintenance-page`;
- the existing relative read-only mounts remain anchored to the live stack path.

The final implementation must validate Compose rendering before merge and again immediately before any deployment.

## Inspect action

`inspect maintenance-page` is non-mutating and may be used before approval.

It must return a machine-readable object containing at least:

```text
pilot_id
service
policy identity/hash
authoritative Git commit
live immutable config hashes
current configured image
current runtime image ID/current repo digest
candidate digest
candidate local availability
rollback digest
container state/restart count
container ID
network membership
published port
mount read/write state
Jenkins container ID/restart count
Jenkins DinD container ID/restart count
health HTTP result/content marker
pilot consumed state
deployment.allowed=false
deployment.performed=false
```

The inspect output itself grants no deployment authority.

## One-shot deployment state

The first pilot must not create a reusable deployment switch.

Proposed root-owned state directory:

```text
/var/lib/homelab-stage5/maintenance-page/
```

The policy contains a unique `pilot_id`.

Before forward deployment:

```text
PASS: pilot_id has not already been consumed
PASS: current runtime digest equals exact rollback baseline
PASS: candidate digest differs from rollback baseline
```

After the forward deployment command is issued successfully and the target begins changing, the helper records the pilot as consumed.

A repeated forward `deploy` request for the same pilot ID must be rejected, even if the service is later rolled back.

This makes the human-approved first pilot one-shot rather than a permanent general deployment capability.

## Human approval binding

Human approval lives in the Jenkins pilot pipeline, not in the SSH wrapper.

Before approval Jenkins must independently validate the Stage 4 deployment plan and Stage 5 inspect artifact and display:

```text
pilot_id
service
current digest
candidate digest
authoritative Git commit
immutable config hashes
exact action: recreate maintenance-page only
health URL/marker
rollback digest
approval.required=true
approval.granted=false
```

The Jenkins `input` step must require an explicit human confirmation for that build.

After approval, Jenkins may send only the literal command:

```text
deploy maintenance-page
```

The caller does not supply the candidate digest. The root-owned policy determines it.

This binds execution to the reviewed installed policy rather than trusting pipeline-supplied deployment arguments.

## Deploy action preconditions

The root helper must re-check all of the following immediately before mutation:

```text
PASS: service literal is maintenance-page
PASS: pilot is not consumed
PASS: root policy is valid
PASS: authoritative Git commit matches policy
PASS: live Compose/config/index hashes match policy
PASS: current runtime digest equals rollback baseline
PASS: candidate digest is local and exact
PASS: candidate architecture matches TestServer
PASS: candidate differs from rollback baseline
PASS: maintenance-page is currently running
PASS: current network is homelab_apps
PASS: current port is 192.168.2.220:8088 -> 80
PASS: expected mounts are read-only
PASS: Jenkins controller baseline captured
PASS: Jenkins DinD baseline captured
```

Any mismatch stops before Compose is invoked.

## Exact deployment command class

The helper may execute only the equivalent of:

```text
MAINTENANCE_PAGE_IMAGE=<policy candidate digest>
docker compose \
  -p maintenance-page \
  -f /home/james/docker/stacks/maintenance-page/docker-compose.yml \
  up -d \
  --no-deps \
  --no-build \
  --pull never \
  --force-recreate \
  maintenance-page
```

The implementation must construct this command internally from constants and root-owned policy values, not from caller strings.

Forbidden operations include:

```text
docker compose down
docker compose up without explicit service
docker rm
docker system prune
docker exec
docker run arbitrary image
docker network create/remove
any Jenkins or jenkins-docker recreation
any unrelated service recreation
Git mutation
firewall/SSH mutation
```

## Deployment performed semantics

The Stage 5 audit model must distinguish approval from execution.

Before Compose invocation:

```text
deployment.allowed=true only inside the approved execution stage
deployment.performed=false
```

After Compose has actually been invoked and accepted sufficiently to begin the target change:

```text
deployment.performed=true
```

A failed precondition must leave `deployment.performed=false`.

## Post-deployment validation

The helper must validate independently of the Compose return code:

```text
PASS: maintenance-page container is running
PASS: resulting immutable image identity equals candidate digest
PASS: maintenance-page container ID changed as expected
PASS: no unrelated target container was recreated by the operation
PASS: Jenkins container ID unchanged
PASS: Jenkins restart count unchanged
PASS: Jenkins DinD container ID unchanged
PASS: Jenkins DinD restart count unchanged
PASS: network membership remains homelab_apps
PASS: published endpoint remains 192.168.2.220:8088 -> 80
PASS: expected mounts remain read-only
PASS: HTTP GET returns success
PASS: response contains Planned Maintenance | James Roberts
```

The helper returns a machine-readable result artifact suitable for Jenkins archiving.

## Rollback action

Rollback is also allow-listed to `maintenance-page` only.

It may use only the exact rollback digest from the root-owned policy.

Before rollback:

```text
PASS: pilot was consumed
PASS: current runtime digest equals candidate digest or deployment is in a known failed-candidate state
PASS: rollback digest is locally available
PASS: immutable config still matches policy
```

Rollback invokes the same one-service Compose command class with:

```text
MAINTENANCE_PAGE_IMAGE=<policy rollback digest>
```

After rollback, all service/Jenkins/DinD/network/port/mount/HTTP checks run again.

Rollback does not reset the one-shot consumed marker. Re-deployment of the same pilot requires a new reviewed pilot ID/policy.

## Failure semantics

Fail closed before mutation for:

```text
policy mismatch
candidate missing
candidate digest mismatch
current runtime drift
Git authority drift
live config drift
unexpected network/port/mount state
pilot already consumed
Jenkins/DinD baseline unavailable
```

After mutation begins, any failed post-check is reported as a deployment failure and the pipeline enters the separately approved rollback path. No ad-hoc shell access is granted.

## Audit artifacts

The Jenkins run should archive:

```text
stage4-deployment-plan.json
stage5-preflight.json
stage5-deploy-result.json
stage5-rollback-result.json (only when used)
```

Artifacts must not include secrets or private keys.

## Installation sequence

Authority must be introduced in reviewable phases:

1. select and record exact candidate digest;
2. update `docker-env` maintenance-page Compose to immutable candidate/rollback-compatible image parameterization;
3. validate live-vs-Git configuration again;
4. add Stage 5 wrapper/helper/policy source to Git for review;
5. add separate Stage 5 Jenkins pipeline source for review;
6. prove pipeline dry-run stops before human approval/deployment;
7. only then create the Stage 5 host account/key/sudo/forced-command capability;
8. install root-owned reviewed helper and policy;
9. add separate Jenkins credential;
10. rerun dry-run with live credential but no approval;
11. perform one human-approved pilot;
12. close out and decide whether Stage 5 authority should remain, be removed, or be redesigned.

Do not combine authority installation and first live deployment into a single unreviewed step.

## Design acceptance criteria

```text
PASS: Stage 4 wrapper/account/credential remain unchanged
PASS: separate Stage 5 identity
PASS: Stage 5 account not in Docker group
PASS: no unrestricted sudo
PASS: forced command accepts one literal service only
PASS: root-owned policy pins candidate and rollback identities
PASS: caller cannot supply Docker/Compose arguments
PASS: candidate must already be local
PASS: live immutable config hashes rechecked immediately before deployment
PASS: change.json classified as expected runtime state
PASS: deployment is one-shot per pilot_id
PASS: Jenkins human approval is required
PASS: forward deploy targets maintenance-page only
PASS: rollback targets maintenance-page only
PASS: Jenkins/DinD are protected by before/after invariants
PASS: no Stage 5 authority is enabled by this design document
```

## Current state

```text
Stage 5 pilot: maintenance-page
Source reconciliation: COMPLETE
Restricted wrapper design: DOCUMENTED
Candidate digest: NOT YET SELECTED
Wrapper/helper implementation: NOT YET WRITTEN
Stage 5 account: NOT CREATED
Stage 5 Jenkins credential: NOT CREATED
Stage 5 deployment authority: NOT ENABLED
Stage 5 deployment performed: NO
```
