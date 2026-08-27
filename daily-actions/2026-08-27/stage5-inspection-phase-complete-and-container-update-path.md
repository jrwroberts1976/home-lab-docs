# Stage 5 inspection phase complete and Jenkins container-update path

Date: 2026-08-27

## Executive status

Stage 5 has completed the **inspection-only transport and security-boundary phase** for the `maintenance-page` pilot.

The project objective has not changed:

> **Jenkins is intended to become the controlled mechanism that detects container version changes, validates exact immutable candidates, presents the planned change for human approval, performs only the approved service-scoped container update, validates health after the change, records the result, and provides a controlled rollback path.**

The work completed so far establishes the safety boundary required before Jenkins is given any deployment authority.

Current status:

```text
Stage 4 = COMPLETE
Stage 5 pilot = maintenance-page
Jenkins remote inspection transport = PROVEN
Jenkins positive inspection path = PROVEN
Jenkins negative command boundary = PROVEN
approval.required = true
approval.granted = false
deployment.allowed = false
deployment.performed = false
Stage 5 deployment helper installed = NO
Stage 5 enable file present = NO
deploy/rollback sudo authority = NO
maintenance-page deployment performed = NO
```

## End goal: Jenkins-managed Docker container version updates

The intended steady-state flow remains:

1. Jenkins detects or is triggered by a version/image change for an approved Docker service.
2. Jenkins identifies the exact current immutable image and exact candidate immutable image.
3. Jenkins validates architecture, provenance, source authority, configuration, service scope and rollback target.
4. Jenkins produces a machine-readable plan/inspection artifact.
5. Jenkins performs health and readiness checks before approval.
6. Jenkins presents the exact planned action for **human approval**.
7. Only after approval, Jenkins invokes a narrowly allow-listed remote deployment action for the approved service.
8. TestServer independently revalidates policy, Git authority, hashes, current image, candidate image, rollback image and enable state before mutation.
9. The helper performs one exact service-scoped Compose recreation using an immutable digest and `--pull never`.
10. Post-change HTTP/service health checks run immediately.
11. Jenkins records the deployment result and exact immutable identities.
12. If post-change validation fails, the separately defined rollback action restores the pinned rollback image.
13. The one-shot execution state is consumed/disabled so deployment authority is not left generally open.

This is **not** intended to become general Jenkins shell access or general Docker administration.

Jenkins itself remains a permanent exception: Jenkins must never automatically deploy/recreate its own controller or DinD control plane through this mechanism.

## Stage 4 safety baseline

Stage 4 remains complete and read-only.

The accepted baseline proves:

- Jenkins can use a stored SSH credential without exposing the private key;
- TestServer receives the request through a restricted forced-command wrapper;
- Jenkins independently parses the returned deployment-plan artifact;
- `deployment.allowed=false`;
- `deployment.performed=false`;
- the explicit `Stop before deployment` stage remains enforced.

Stage 5 has been built on top of this baseline rather than replacing it.

## Durable Jenkins SSH identity

A dedicated validation network provides a durable security identity:

```text
network: jenkins_validation
subnet: 172.30.255.248/29
TestServer destination/gateway: 172.30.255.249
Jenkins fixed source: 172.30.255.250
```

Jenkins remains attached to `homelab_apps` for its existing application/DinD connectivity. `jenkins-docker` is not attached to the validation network.

The pinned TestServer ED25519 host-key fingerprint is:

```text
SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk
```

The Stage 5 inspection credential is:

```text
ID: homelab-stage5-testserver-inspector
username: homelab-stage5-pilot
public fingerprint: SHA256:nvCBuAboTuAqiBCGj3Rj7DPNQW9um7FZByjKZHH0naI
scope: GLOBAL
store: system::system::jenkins
domain: _
credential class: BasicSSHUserPrivateKey
private-key source: DirectEntryPrivateKeySource
```

## TestServer Stage 5 inspection account

Installed account:

```text
user: homelab-stage5-pilot
uid: 996
gid: 983
home: /var/lib/homelab-stage5-pilot
shell: /bin/bash
password: locked
Docker group membership: NO
```

The account has no unrestricted Docker or shell authority.

### SSH policy

The effective account policy requires public-key authentication and forces all sessions through:

```text
/usr/local/sbin/homelab-stage5-pilot-ssh
```

Relevant restrictions remain:

```text
AuthenticationMethods publickey
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitTTY no
AllowTcpForwarding no
AllowAgentForwarding no
X11Forwarding no
PermitTunnel no
PermitUserRC no
ForceCommand /usr/local/sbin/homelab-stage5-pilot-ssh
```

The authorized key is additionally restricted to:

```text
restrict,from="172.30.255.250"
```

### Final trust-file model

The final proven trust permissions are:

```text
/var/lib/homelab-stage5-pilot/.ssh
  owner: root:homelab-stage5-pilot
  mode: 0750

/var/lib/homelab-stage5-pilot/.ssh/authorized_keys
  owner: root:homelab-stage5-pilot
  mode: 0640
```

The account can read/traverse the trust path but cannot modify either object.

This supersedes the initial root-only `0700/0600` installation documented during identity creation. The root-only model prevented successful SSH public-key authorization because the target account could not traverse/read the configured `AuthorizedKeysFile`.

## Stage 5 pilot: maintenance-page

The selected first deployment pilot remains `maintenance-page` because it is low risk and narrowly scoped:

- nginx container;
- non-privileged;
- no Docker socket;
- no database;
- no writable application data;
- two read-only bind mounts;
- one HTTP endpoint;
- one `homelab_apps` network membership;
- deterministic health marker.

Current/rollback immutable image:

```text
nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
nginx 1.31.3-alpine
ARM64 image ID: sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483
```

Candidate immutable image:

```text
nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913
nginx 1.31.4-alpine
ARM64 child manifest: sha256:57744b8fa99abc438b1fbde6bd69e4270d0984ccfdee60c661ec22243047373a
local ARM64 image ID: sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5
```

Health endpoint and marker:

```text
http://192.168.2.220:8088/
HTTP 200
Planned Maintenance | James Roberts
```

## Git authority

### docker-env

The maintenance-page candidate/config authority was merged through PR #16 as:

```text
f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883
```

The Compose image declaration is parameterized so the immutable candidate is the default while the root execution policy can explicitly select the rollback digest.

Jenkins image reproducibility PR #17 added `openssh-client` as an explicit image dependency and merged as:

```text
b8058c667cac59dc741587f0554437ee000f6486
```

The PR was still useful even though later diagnosis proved the running Jenkins container already contained `/usr/bin/ssh` and `/usr/bin/ssh-keygen`. The earlier apparent absence came from incorrectly invoking the shell builtin `command` directly through `docker exec` rather than through `sh -c`.

No Jenkins rebuild/restart was required for the Stage 5 transport proof.

### homelab-container-version-control

Relevant Stage 5 reviewed source is already merged to `main`:

```text
PR #28 review boundary -> f05da1a31caa904c10b1a4b7455d2daf823be721
PR #29 guarded helper source -> 6112d3dcf1f38dad88e71cd322672c7e58b4ba6a
PR #30 inspection-only preapproval path -> ad3e85e2e6afe576d57dec186cefea58bddc8a20
PR #31 helper-free inspection hardening -> dfb773c81770fe12936d25558b427a279ebafd83
```

Current authoritative implementation main for the proven inspection phase:

```text
dfb773c81770fe12936d25558b427a279ebafd83
```

## Installed inspection-only components

TestServer currently has only the inspection path installed:

```text
/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate
  sha256: 561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda

/usr/local/libexec/homelab-stage5-maintenance-page-inspect
  sha256: 64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213

/usr/local/sbin/homelab-stage5-pilot-ssh
  sha256: 85ad4a488325a07316cc17bc3b245f5f0b4136a920b126e25fb35c659ccdd6a6

/etc/homelab-stage5/maintenance-page.policy.json
  sha256: adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f
```

The root-owned authority checkout is:

```text
/var/lib/homelab-stage5/authority/docker-env
```

and is pinned to the reviewed Docker authority commit.

The only Stage 5 sudo authority is the inspection command:

```text
/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate inspect
```

No deployment helper is installed.

No enable file exists.

No deploy or rollback sudo authority exists.

## First SSH identity write failure and safe rollback

The first Stage 5 identity creation attempt failed while generating Jenkins credential XML because the Python heredoc invocation omitted `-`. Python attempted to execute the XML template itself and raised `SyntaxError`.

The failure handler removed the newly installed public trust. A separate rollback verification proved:

- Jenkins Stage 5 credential absent;
- Stage 5 `authorized_keys` absent;
- Stage 5 `.ssh` directory absent;
- temporary root private-key directories absent;
- temporary Jenkins CLI/auth files absent;
- Stage 5 sshd hardening still active;
- inspection-only sudo authority still present;
- deployment helper absent;
- enable file absent;
- maintenance-page still on rollback.

The failed keypair was destroyed and never reused.

A new ED25519 keypair was generated on the successful retry.

## Successful Jenkins credential creation

The successful retry proved:

- generated public fingerprint matched the installed public fingerprint;
- public trust was source-restricted to `172.30.255.250`;
- Stage 5 account could not modify the trust file;
- private half was imported into Jenkins via supported CLI credential creation;
- stored credential metadata matched the Stage 4 credential model;
- Jenkins `credentials.xml` did not contain a literal OpenSSH private-key block;
- transient private/public key files and generated credential XML were deleted;
- temporary Jenkins CLI/API-token auth files were deleted;
- all container IDs and restart counts remained unchanged;
- deployment capability remained absent.

## SSH transport diagnosis and correction

The first end-to-end remote attempt bound the correct Jenkins credential and passed TestServer host-key verification but failed at public-key authentication.

The TestServer journal proved the request arrived from the correct source:

```text
172.30.255.250
```

The failure was therefore not caused by the `from=` restriction.

The trust-path access model was corrected to the final `0750/0640` group-readable, non-writable state described above. After that correction the same Jenkins credential authenticated successfully.

## Positive-path transport proof

### Remote ping

Jenkins bound the real Stage 5 credential and remotely invoked `ping`.

TestServer recorded:

```text
Accepted publickey for homelab-stage5-pilot from 172.30.255.250
ED25519 SHA256:nvCBuAboTuAqiBCGj3Rj7DPNQW9um7FZByjKZHH0naI
```

The forced wrapper returned readiness JSON showing:

```text
mode = stage5-inspection-only
inspection.allowed = true
deployment.allowed = false
deployment.performed = false
deploy_command_enabled = false
rollback_command_enabled = false
result = ready
```

### Remote maintenance-page inspection

Jenkins then remotely executed:

```text
inspect maintenance-page
```

The returned artifact was parsed by Jenkins and independently asserted as:

```text
mode = stage5-preapproval-inspect
artifact = pilot-inspection
pilot_id = stage5-maintenance-page-nginx-1.31.4-20260827
service = maintenance-page
host = TestServer
approval.required = true
approval.granted = false
inspection.allowed = true
inspection.performed = true
deployment.allowed = false
deployment.performed = false
deploy_command_enabled = false
rollback_command_enabled = false
result = ready-for-human-review
```

The artifact also proved:

- exact Docker authority commit;
- exact current immutable rollback digest;
- exact candidate immutable digest;
- both candidate and rollback images local for Linux/ARM64;
- runtime network/port shape;
- HTTP health marker passing;
- Jenkins and Jenkins-Docker protected container identities/restart counters.

No container changed or restarted.

## Negative-path security proof

Using the **same successfully authenticated Jenkins credential**, the forced wrapper rejected:

```text
deploy maintenance-page -> return code 2
rollback maintenance-page -> return code 2
inspect jenkins -> return code 2
docker ps -> return code 2
shell -> return code 2
```

The TestServer journal showed successful public-key authentication before those command rejections. This proves the restriction is enforced at the command boundary, not merely by failed transport authentication.

After the negative tests:

- temporary Jenkins job removed;
- temporary Jenkins API-token files removed;
- all container IDs/restart counts unchanged;
- maintenance-page remained on exact rollback digest;
- deployment helper remained absent;
- enable file remained absent;
- deploy/rollback sudo authority remained absent.

## Branch and PR consolidation

A repository check after the proof found no open PRs in:

```text
jrwroberts1976/docker-env
jrwroberts1976/homelab-container-version-control
jrwroberts1976/home-lab-docs
```

Stage 5 branch refs still exist, but comparison to `main` showed every one has:

```text
ahead_by = 0
```

Therefore there is no unmerged Stage 5 code on those branch refs.

Observed stale merged refs include:

```text
docker-env:
  stage5/jenkins-openssh-client
  stage5/maintenance-page-nginx-1.31.4-candidate

homelab-container-version-control:
  stage5/inspection-without-deploy-helper
  stage5/maintenance-page-deploy-helper-review
  stage5/maintenance-page-inspect-approval-review
  stage5/maintenance-page-wrapper-review
```

These branches are already contained by `main`; they do not need another merge.

## Current hard stop

The inspection phase does **not** authorize deployment.

The current hard stop remains:

```text
approval.required = true
approval.granted = false
deployment.allowed = false
deployment.performed = false
helper absent
enable file absent
deploy sudo absent
rollback sudo absent
```

## Next Stage 5 phase

The next work is the **execution-transition preflight**, not a deployment.

Before enabling anything, revalidate:

1. current `homelab-container-version-control/main` exact commit;
2. current `docker-env/main` exact commit;
3. reviewed mutating helper source and expected SHA256;
4. current inspection gate/inspector/wrapper/policy hashes;
5. exact root-owned authority checkout state;
6. exact candidate and rollback immutable digests and local ARM64 image IDs;
7. maintenance-page current runtime still equals rollback;
8. health check and marker still pass;
9. Jenkins/DinD protected state unchanged;
10. execution policy remains disabled until the approval workflow is ready;
11. exact sudo transition required for deploy/rollback;
12. one-shot enable/state design;
13. Jenkins human-approval stage;
14. post-deploy health checks;
15. rollback action and rollback-health checks;
16. evidence/recording requirements;
17. automatic removal/consumption of temporary execution authority.

Only after those are independently reviewed should the Stage 5 pilot transition from inspection-ready to execution-ready.

## What success will look like

For the first real pilot, Jenkins should eventually produce a run that visibly proves:

```text
current = nginx 1.31.3 immutable rollback digest
candidate = nginx 1.31.4 immutable candidate digest
plan = validated
inspection = pass
approval = HUMAN GRANTED
deployment action = exactly maintenance-page only
pull = never
candidate already local = yes
post-deploy HTTP health = pass
post-deploy marker = pass
unrelated containers = unchanged
Jenkins = unchanged
Jenkins-Docker = unchanged
record = written
one-shot execution authority = consumed/disabled
```

A later run should be able to exercise the reviewed rollback path if the post-deploy health check fails.

Once the pilot is proven, the same architecture can be generalized carefully to other suitable Docker containers, with per-service policy and exclusions rather than unrestricted Docker access.

## Conclusion

Yes: **the project remains on the path to use Jenkins to update Docker container versions.**

The reason no update has happened yet is deliberate. Stage 5 has first proven that Jenkins can inspect the real host using a real stored credential while being cryptographically and operationally prevented from deploying, rolling back, executing Docker directly, or obtaining a shell.

That inspection boundary is now complete and is the foundation for the next controlled deployment-enablement phase.
