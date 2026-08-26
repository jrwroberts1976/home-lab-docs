# Container Version Control — Stage 4 Jenkins Integration Checkpoint

**Date:** 26 August 2026  
**Status:** READ-ONLY JENKINS EXECUTION BOUNDARY PROVEN; CREDENTIAL-BOUND PIPELINE RUN STILL OUTSTANDING  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

## Purpose

This checkpoint supersedes the earlier `Next validation` section in `container-version-control-stage4-deployment-plan.md`.

The deployment-plan implementation is now merged and the Stage 4 Jenkins transport/runner boundary has been proven end to end. Stage 4 remains strictly non-deploying.

## Deployment-plan implementation merged

Implementation PR #25 merged as:

```text
c8ff8f8ff625469ceae1a18177f088c62b18feaa
```

Reviewed critical blobs:

```text
config/deployment-plan.schema.json
7420557838813710378b468034db33f1fc9c0b25

scripts/generate-deployment-plan.py
d615eb24e1be147911f91be5e1d3305faf207966
```

The real fail-closed paths that were previously outstanding are now proven:

- `maintenance-page` / `nginx:alpine` -> `ordering-unknown-blocked` -> `blocked / manual-review`;
- Jenkins platform exception -> `blocked / manual-review`.

Both remain:

```text
deployment.allowed=false
deployment.performed=false
```

## Jenkins execution boundary

Jenkins remains isolated behind its existing Docker-in-Docker daemon and does not receive the TestServer Docker socket.

The proven Stage 4 path is:

```text
Jenkins
-> restricted SSH
-> homelab-validator
-> sshd ForceCommand
-> root-owned read-only wrapper
-> immutable Stage 4 tooling
-> real TestServer runtime
-> deployment-plan JSON
-> STOP
```

A dedicated TestServer account exists:

```text
homelab-validator
```

It has no Docker-group membership and no unrestricted sudo authority. SSH is public-key-only, with PTY, forwarding, agent forwarding, X11, tunnels and user RC disabled.

The forced command accepts only:

```text
ping
plan <container>
```

Container names must match:

```text
^[A-Za-z0-9][A-Za-z0-9_.-]*$
```

Arbitrary commands and command-injection attempts are denied.

## Network and host-key restriction

Observed Jenkins address on `homelab_apps`:

```text
172.18.0.23
```

The TestServer SSH rule is currently restricted to that exact `/32`, and the validator key is independently restricted with the same source address in `authorized_keys`.

Pinned TestServer ED25519 fingerprint:

```text
SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk
```

Stage 4 uses strict host-key verification. `StrictHostKeyChecking=no` and `accept-new` are not accepted for this path.

A future hardening item remains: Jenkins needs a durable network identity so container recreation cannot silently invalidate the current `/32` restriction. The restriction must not be broadened to the Docker subnet as a shortcut.

## Trivy inherited-working-directory fault and fix

The first real forced-SSH Dozzle validation reached the Stage 4 runner but failed inside the Trivy security gate.

Root cause: the SSH session inherited `/home/homelab-validator` as its working directory. That directory is mode `0700`; after `runuser` switched execution to `james`, Trivy 0.72 could not traverse the directory while inspecting its default `trivy.yaml` path.

The wrapper was corrected to enter the Stage 4 tooling directory before dropping privileges:

```bash
cd "$TOOLING" || die "tooling directory unavailable"
```

After this change the real Jenkins SSH Dozzle plan passed, including the Trivy gate.

## Immutable Stage 4 tooling snapshot

The first working wrapper referenced the user-writable checkout under `/home/james/projects`. That was not acceptable as a final execution boundary because validation code could be modified outside reviewed Git state.

The runner is now pinned to an immutable root-owned snapshot of the exact merged Stage 4 revision:

```text
/opt/homelab-container-version-control-stage4/c8ff8f8ff625469ceae1a18177f088c62b18feaa
```

The snapshot was built directly from the Git revision and verified against the expected Git blobs.

Properties proven:

- root-owned;
- non-writable;
- executable scripts remain executable;
- `james` can execute the tooling but cannot modify it;
- the real Jenkins SSH path still passes using the immutable snapshot.

This closes the user-writable-tooling integrity gap.

## Fail-closed authority checkout check

The forced wrapper checks `/var/tmp/docker-env-stage4` before invoking the generator.

The Git status operation now runs explicitly as `james` and fails closed in both cases:

```text
Git status unavailable -> denied
authority checkout dirty -> denied
```

A Git error can no longer be mistaken for a clean checkout.

## Forced wrapper under source control

The installed wrapper has been captured into the implementation repository as:

```text
ops/testserver/homelab-stage4-validation-ssh
```

The reviewed source and installed wrapper were verified byte-for-byte identical.

Current SHA-256:

```text
091626e74ae811ff3a76b236ff57056b34efd38d421cc76bfe566097c9b967c7
```

Static checks found no shell-evaluation path, Docker deployment primitive or Git mutation primitive.

## Real Jenkins transport proof

The complete read-only transport has been exercised successfully against Dozzle.

Result:

```text
ownership:          pass
comparison:         same
architecture:       pass
security:           pass
secret readiness:   pass
provenance:         not-applicable
decision:           no-change
proposed action:    none
deployment:         allowed=false, performed=false
```

Negative tests also passed:

```text
arbitrary command       -> denied
command-injection input -> denied
```

Jenkins and Dozzle remained running with restart count `0`; no container was recreated or deployed.

## Jenkins credential model

The controller already has the required plugins:

```text
credentials
credentials-binding
ssh-credentials
```

An existing Jenkins job proves the supported pattern:

```text
BasicSSHUserPrivateKey
DirectEntryPrivateKeySource
sshUserPrivateKey(...)
```

The intended Stage 4 credential is:

```text
id:       homelab-stage4-testserver-validator
username: homelab-validator
```

The dedicated temporary private key remains in Jenkins persistent storage until credential-store binding is successfully proven. It must not be removed before that point.

## Jenkins controller validation capability

The controller currently has `git` and `ssh`, but does not have:

```text
python3
jq
pipeline-utility-steps
```

The immutable remote generator performs full JSON Schema validation before emitting the deployment plan.

The Jenkins Pipeline therefore performs an additional fail-closed contract check using native Pipeline Groovy JSON parsing, including:

```text
schema_version == 1
mode == read-only
artifact == deployment-plan
service.container == requested container
service.host == TestServer
deployment.allowed == false
deployment.performed == false
required gate results exist
decision/action pair is valid
```

The checked-out schema is pinned to reviewed blob:

```text
7420557838813710378b468034db33f1fc9c0b25
```

## Reviewable Jenkinsfile

A root `Jenkinsfile` has been prepared on `stage4/jenkins-integration` and remains uncommitted for review.

Static checks confirm:

- Jenkins-native `sshUserPrivateKey(...)` binding;
- strict pinned host-key verification;
- no reference to the temporary raw private-key path;
- reviewed schema blob pinning;
- independent Jenkins assertions that deployment is disabled and unperformed;
- no Docker deployment/restart/build/pull command;
- no Kubernetes or Helm deployment command;
- explicit stop-before-deployment behaviour.

The implementation repository currently has exactly two review changes:

```text
Jenkinsfile
ops/testserver/homelab-stage4-validation-ssh
```

## Remaining work

Before Stage 4 Jenkins integration is complete:

1. create `homelab-stage4-testserver-validator` in the Jenkins credential store without exposing the private key;
2. configure the Jenkins job/multibranch job for `homelab-container-version-control`;
3. run the Jenkinsfile through Jenkins credential binding;
4. verify the archived deployment-plan artifact and Jenkins-side Groovy assertions;
5. exercise a fail-closed Pipeline result;
6. remove the temporary loose validator key only after credential binding is proven;
7. review and commit the implementation wrapper and Jenkinsfile;
8. complete the implementation PR;
9. establish a durable Jenkins network identity for the `/32` SSH restriction; and
10. keep deployment authority disabled throughout Stage 4.

Stage 4 remains:

```text
READ-ONLY
deployment.allowed=false
deployment.performed=false
```
