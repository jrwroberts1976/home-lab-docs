# Jenkins Durable Network Identity Design

**Date:** 27 August 2026  
**Status:** COMPLETE — LIVE CUTOVER PROVEN  
**Scope:** Jenkins Stage 4 restricted SSH validation path on TestServer

## Purpose

Replace the accidental Jenkins source identity on the shared `homelab_apps` Docker bridge with a durable, declarative network identity that survives Jenkins controller recreation without broadening SSH access.

This is a transport hardening change only. It does not add Docker, Compose, Kubernetes or other deployment authority.

## Final proven state

The completed design is:

```text
network name:        jenkins_validation
subnet:              172.30.255.248/29
bridge gateway:      172.30.255.249
Jenkins fixed IP:    172.30.255.250
SSH destination:     172.30.255.249
firewall source:     172.30.255.250/32
authorized_keys:     from="172.30.255.250"
```

Jenkins remains attached to `homelab_apps` for existing application/UI/DinD connectivity and additionally attaches to `jenkins_validation` with the declarative fixed address `172.30.255.250`. `jenkins-docker` remains only on `homelab_apps`.

Final SSH trust is deliberately narrow:

- UFW permits TCP/22 from exactly `172.30.255.250/32`;
- the `homelab-validator` public key is restricted to `from="172.30.255.250"`;
- Jenkins `known_hosts` pins only the durable TestServer destination `172.30.255.249`;
- TestServer ED25519 fingerprint remains `SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk`;
- validator key fingerprint remains `SHA256:DcO1PigKb2GXD6clI/1uCNHlX2MVryivfL5BbhkNe7k`;
- strict host-key checking and Jenkins credential-store-only authentication remain in use;
- no subnet-wide SSH rule exists.

## Why the original identity was rejected

The original Jenkins address `172.18.0.23` was allocator-assigned on shared bridge `homelab_apps` (`172.18.0.0/16`). It was therefore a runtime observation, not a durable security identity.

Hard-coding that address was rejected because:

1. the shared bridge had no reserved static-IP range;
2. the address could be reassigned while Jenkins was absent;
3. changing shared-network IPAM would risk unrelated services;
4. the previous controller Compose source was not authoritative Git-managed configuration;
5. it would preserve coupling between Jenkins trust and the general application bridge.

Broadening SSH to `172.18.0.0/16` was explicitly rejected.

## Collision audit

A read-only Docker-network and host-route audit found these active or configured ranges on TestServer:

```text
172.17.0.0/16
172.18.0.0/16
172.19.0.0/16
172.21.0.0/16
172.22.0.0/16
172.23.0.0/16
172.25.0.0/16
192.168.16.0/20
192.168.144.0/20
192.168.2.0/24
```

The selected `172.30.255.248/29` segment did not overlap any discovered Docker subnet, connected LAN route or detected tunnel route.

## Git configuration authority

The Jenkins controller and DinD definition is authoritative in:

```text
jrwroberts1976/docker-env
stacks/jenkins/
  Dockerfile
  docker-compose.yml
  README.md
```

Review PR #15 merged as:

```text
1f95b0a2d6f8da5500a6a02d0d8416393107e8df
```

The merged Compose definition preserves existing Jenkins/DinD behaviour, retains external `homelab_apps`, adds Compose-managed `jenkins_validation`, assigns Jenkins `172.30.255.250`, and excludes DinD from the validation network.

The Stage 4 implementation transport change was reviewed separately in `jrwroberts1976/homelab-container-version-control` PR #27. It changed only:

```diff
- STAGE4_HOST = '172.18.0.1'
+ STAGE4_HOST = '172.30.255.249'
```

and merged as:

```text
efcbc7199b435497f2b624b3efbb54bc50b274f6
```

## Migration and proof

The migration was performed with old and new trust paths temporarily available in parallel so rollback remained possible until the replacement path was proven.

Completed proof sequence:

1. Subnet collision audit completed.
2. Git-owned Jenkins Compose authority reviewed and merged.
3. Temporary dual `/32` UFW trust and dual-source authorized-key restriction prepared.
4. `jenkins_validation` created with reviewed Compose ownership labels and exact IPAM values.
5. Running Jenkins attached to `172.30.255.250` without restart; DinD remained excluded.
6. SSH probe from Jenkins to `172.30.255.249:22` matched the reviewed TestServer ED25519 fingerprint and incremented the new exact `/32` UFW counter.
7. Jenkins `known_hosts` gained the new destination while retaining the old destination for rollback.
8. PR #27 moved Stage 4 SSH destination to `172.30.255.249` only.
9. Successful Stage 4 `dozzle` run checked out exact merge `efcbc7199b435497f2b624b3efbb54bc50b274f6`, received the deployment-plan artifact, returned `no-change / none`, independently reconfirmed `deployment.allowed=false` and `deployment.performed=false`, reached `Stop before deployment`, and finished `SUCCESS`.
10. TestServer SSH journal recorded the successful Jenkins connection from `172.30.255.250` using the reviewed validator key.
11. Jenkins controller was deliberately recreated from the merged `docker-env` Compose authority. The container ID changed and Jenkins reacquired `jenkins_validation=172.30.255.250` with gateway `172.30.255.249` declaratively.
12. Jenkins HTTP recovered with `200`; persistent SSH state survived; DinD was not recreated and retained its pre-existing restart count `1`.
13. A post-recreation Stage 4 `dozzle` run again finished `SUCCESS` with the read-only contract intact.
14. Old trust was retired: UFW source `172.18.0.23` removed, authorized key reduced to only `from="172.30.255.250"`, and old Jenkins `known_hosts` destination `172.18.0.1` removed.
15. Final post-cutover Stage 4 `dozzle` run at `06:24` succeeded with the old trust path absent.

## Acceptance criteria

All acceptance criteria are now satisfied:

```text
PASS: dedicated validation subnet does not overlap existing networks
PASS: Jenkins validation IP is declarative and fixed
PASS: only Jenkins controller requires validation-network membership
PASS: SSH firewall source is exactly one /32 after cutover
PASS: validator authorized-key source is exactly one address after cutover
PASS: pinned TestServer host-key validation remains enabled
PASS: Jenkins credential-store-only authentication remains in use
PASS: Stage 4 deployment.allowed=false
PASS: Stage 4 deployment.performed=false
PASS: Stop before deployment still executes
PASS: controller recreation preserves the validation source identity
PASS: old dynamic 172.18.0.23 trust path removed after proof
PASS: final Stage 4 run succeeds after old trust removal
```

## Rollback state

Backups of the pre-cutover validator `authorized_keys` and Jenkins `known_hosts` were retained under `/var/backups`. Rollback, if ever required, must be a reviewed network/SSH-control change and must not widen SSH to the shared application subnet.

## Safety boundary

This completed work does **not** enable Stage 5 deployment authority.

```text
Stage 4 = COMPLETE
READ-ONLY
credential-store execution proven
deployment.allowed=false
deployment.performed=false
```

The Jenkins controller remains a platform exception and must not automatically deploy or recreate itself.