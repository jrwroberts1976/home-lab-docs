# Jenkins Durable Network Identity Design

**Date:** 27 August 2026  
**Status:** GIT AUTHORITY MERGED — LIVE MIGRATION NOT STARTED  
**Scope:** Jenkins Stage 4 restricted SSH validation path on TestServer

## Purpose

Replace the current accidental Jenkins source identity on the shared `homelab_apps` Docker bridge with a durable, declarative network identity that survives Jenkins controller recreation without broadening SSH access.

This is a transport hardening change only. It does not add Docker, Compose, Kubernetes or other deployment authority.

## Current proven state

Read-only discovery on 27 August 2026 established:

- Jenkins controller: `jenkins`, image `homelab-jenkins:lts-jdk21`;
- Jenkins DinD sidecar: `jenkins-docker`, image `docker:dind`;
- both currently attach only to external bridge `homelab_apps`;
- `homelab_apps` uses `172.18.0.0/16`, gateway `172.18.0.1`;
- Jenkins currently received dynamic address `172.18.0.23`;
- Jenkins DinD currently received dynamic address `172.18.0.12`;
- the controller Compose project is `projects` with live source `/home/james/projects/docker-compose.yml`;
- the current Compose file declares only the external `homelab_apps` network and does not declare `ipv4_address`;
- UFW permits TestServer SSH from exactly `172.18.0.23/32`;
- the `homelab-validator` authorized key is independently restricted with `from="172.18.0.23"`;
- the effective validator SSH policy remains public-key-only with PTY, X11 and TCP forwarding disabled;
- no live container, Docker network, firewall rule or SSH configuration was changed during discovery.

## Problem

`172.18.0.23` is an allocator-assigned address on a shared Docker `/16`. It is therefore an observed runtime address, not a durable Jenkins identity.

Hard-coding `172.18.0.23` directly on `homelab_apps` is rejected as the target design because:

1. the shared bridge has no reserved static-IP range;
2. the address could be allocated to another container while Jenkins is absent;
3. reserving a safe static range would require changing or recreating a network used by many unrelated services;
4. the previous Jenkins controller Compose source was not authoritative Git-managed configuration;
5. it would preserve coupling between the Jenkins trust boundary and the general application bridge.

Broadening the SSH rule to `172.18.0.0/16` is explicitly rejected.

## Selected architecture

Create a dedicated Docker bridge used only for the Jenkins-to-TestServer validation transport.

Conceptual topology:

```text
Jenkins controller
  ├─ homelab_apps
  │    existing application / UI / DinD connectivity
  │
  └─ jenkins_validation
       fixed Jenkins validation address
              |
              | SSH only
              v
       TestServer bridge gateway
              |
              v
       sshd -> homelab-validator -> ForceCommand -> Stage 4 tooling
```

The Jenkins controller remains attached to `homelab_apps` for its existing behaviour. The new network is additive and is used specifically for the restricted validator SSH path.

The DinD sidecar does not need membership of `jenkins_validation`. The reviewed configuration keeps it on `homelab_apps` only.

## Collision audit

A read-only all-Docker-network and host-route audit on 27 August 2026 found these active or configured IPv4 ranges on TestServer:

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

No obvious VPN or tunnel IPv4 interface was present and no WireGuard tooling was installed. `jenkins_validation` did not already exist.

The selected network does not overlap any discovered Docker subnet, connected LAN route or detected tunnel route.

## Exact identity model

Selected values:

```text
network name:        jenkins_validation
subnet:              172.30.255.248/29
bridge gateway:      172.30.255.249
Jenkins fixed IP:    172.30.255.250
SSH destination:     172.30.255.249
firewall source:     172.30.255.250/32
authorized_keys:     from="172.30.255.250"
```

A `/29` provides only six usable addresses and deliberately limits the validation segment. The intended allocation is:

```text
172.30.255.248   network
172.30.255.249   TestServer Docker bridge gateway / SSH destination
172.30.255.250   Jenkins controller fixed validation identity
172.30.255.251   unused
172.30.255.252   unused
172.30.255.253   unused
172.30.255.254   unused
172.30.255.255   broadcast
```

The Jenkins controller will retain `homelab_apps` and gain `jenkins_validation`. The DinD sidecar remains only on `homelab_apps`.

The validator transport will retain:

- UFW allow TCP/22 from exactly `172.30.255.250/32`;
- validator key source restriction `from="172.30.255.250"`;
- strict host-key checking;
- the existing TestServer ED25519 host-key fingerprint;
- Jenkins credential-store-only authentication;
- no subnet-wide SSH allowance.

Changing the SSH destination from `172.18.0.1` to `172.30.255.249` requires a matching `known_hosts` entry for the new destination while preserving the already pinned host-key fingerprint.

## Git configuration authority

The Jenkins controller and DinD definition is now captured in:

```text
jrwroberts1976/docker-env
stacks/jenkins/
  Dockerfile
  docker-compose.yml
  README.md
```

Review PR #15 was validated against the exact branch head `e503bb04cac4d9cb90ae20437e06defaf647eb89` and merged to `main` as:

```text
1f95b0a2d6f8da5500a6a02d0d8416393107e8df
```

Pre-merge TestServer validation proved:

- controller Dockerfile SHA256 matched the live build source exactly: `2414a641eea3abd627a5026d755b7b7820c96a60742d23e6e3955a521c884dde`;
- `docker compose config --quiet` passed;
- rendered Jenkins behaviour matched the current live Compose baseline;
- rendered DinD behaviour matched the current live Compose baseline;
- external `homelab_apps` behaviour was retained;
- `jenkins_validation` rendered exactly as `172.30.255.248/29`, gateway `172.30.255.249`;
- Jenkins rendered with fixed validation identity `172.30.255.250`;
- DinD remained excluded from the validation network;
- Jenkins remained running with restart count `0`;
- DinD remained running with its pre-existing restart count `1`;
- `jenkins_validation` remained absent from the live host;
- no `docker compose up`, network creation, firewall change, validator-key change or container change was performed.

The merged Git definition is now the reviewed configuration authority. The old `/home/james/projects/docker-compose.yml` remains the current live launch source until the controlled migration is executed; it must not be silently treated as the long-term source of truth.

## Migration order

The migration must preserve the existing working Stage 4 path until the replacement path is proven.

1. ✅ Complete subnet collision audit.
2. ✅ Record exact proposed network values.
3. ✅ Capture, validate, review and merge Jenkins Compose configuration into `docker-env` authority (PR #15 -> `1f95b0a2d6f8da5500a6a02d0d8416393107e8df`).
4. Synchronize the merged `docker-env` authority to TestServer and perform a final Compose dry-run using project name `projects` so the existing controller is targeted rather than a second Compose project.
5. Prepare the new `172.30.255.250/32` firewall allowance and temporary dual-source validator-key restriction while retaining the old `172.18.0.23/32` path.
6. Migrate Jenkins through the reviewed Compose definition so Compose creates/owns `jenkins_validation`, the controller remains on `homelab_apps`, and it receives `172.30.255.250` on the validation network. Do not manually pre-create the Compose-managed network unless its ownership/labels are deliberately reproduced and reviewed.
7. Add the pinned TestServer host key for `172.30.255.249` and change the Stage 4 SSH destination to that gateway through a reviewed implementation change.
8. Run the existing read-only Stage 4 validation and confirm the traffic source is `172.30.255.250`.
9. Re-run the accepted safety assertions: `deployment.allowed=false`, `deployment.performed=false`, Stop-before-deployment executed, controller and target service restart expectations understood.
10. Remove the old `172.18.0.23/32` UFW allowance and old authorized-key source restriction only after the new path is proven.
11. Recreate or otherwise test the Jenkins controller once through the controlled path and confirm the fixed identity survives.
12. Record final evidence and rollback state.

## Rollback

Until validation is complete, retain the original `172.18.0.23/32` path in parallel.

If the new path fails:

- revert the Jenkins Stage 4 SSH destination to `172.18.0.1`;
- use the retained old `/32` firewall and key source restrictions;
- restore the merged Compose authority to the last proven controller-only network state if necessary;
- leave Stage 4 deployment disabled;
- do not proceed to Stage 5 authority work.

After final cutover, rollback remains a reviewed Compose/network and SSH-control change; it must not require widening SSH to the whole application subnet.

## Acceptance criteria

The durable identity work is complete only when all of the following are true:

```text
PASS: dedicated validation subnet does not overlap existing networks
PASS: Jenkins validation IP is declarative and fixed
PASS: only Jenkins controller requires validation-network membership
PASS: SSH firewall source remains exactly one /32 after cutover
PASS: validator authorized key source remains exactly one address after cutover
PASS: pinned TestServer host-key validation remains enabled
PASS: Jenkins credential-store-only authentication remains in use
PASS: Stage 4 deployment.allowed=false
PASS: Stage 4 deployment.performed=false
PASS: Stop before deployment still executes
PASS: controller recreation preserves the validation source identity
PASS: old dynamic 172.18.0.23 trust path removed after proof
```

## Safety boundary

This design does **not** enable Stage 5 deployment authority.

```text
Stage 4 = COMPLETE
READ-ONLY
credential-store execution proven
deployment.allowed=false
deployment.performed=false
```

The Jenkins controller remains a platform exception and must not automatically deploy or recreate itself.