# Jenkins Durable Network Identity Design

**Date:** 27 August 2026  
**Status:** DESIGN SELECTED — NO LIVE CHANGE YET  
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
4. the Jenkins controller Compose source is not yet authoritative Git-managed configuration;
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

The DinD sidecar does not need membership of `jenkins_validation` unless a separately reviewed requirement is discovered. The default design is controller-only membership.

## Identity model

The validation bridge will use:

- a small dedicated RFC1918 subnet that does not overlap any existing Docker, LAN, VPN or routed network;
- a fixed Jenkins controller address declared in Compose;
- the bridge gateway as the Stage 4 SSH destination;
- a UFW allow rule for TCP/22 from exactly the fixed Jenkins address `/32`;
- the same fixed `/32` in the validator key `from=` restriction;
- no subnet-wide SSH allowance.

The exact subnet, gateway and Jenkins address are intentionally not assigned in this document until an all-Docker-network collision audit is complete.

## Required configuration ownership

Before the live controller is recreated, the configuration necessary to reproduce the Jenkins controller network identity must be captured in an authoritative, reviewable form.

At minimum this must include:

- definition of `jenkins_validation`;
- its selected subnet and gateway;
- the Jenkins fixed `ipv4_address`;
- Jenkins membership in both `homelab_apps` and `jenkins_validation`;
- the Stage 4 SSH destination address used by the Jenkins pipeline;
- the corresponding host firewall `/32` restriction;
- the corresponding validator authorized-key `from=` restriction;
- rollback instructions.

The current `/home/james/projects/docker-compose.yml` is runtime evidence, not yet sufficient Git authority by itself.

## Migration order

The eventual implementation must be staged so the existing working Stage 4 path is retained until the replacement path is proven.

1. Complete subnet collision audit.
2. Record exact proposed network values.
3. Capture/reconcile Jenkins Compose configuration into an authoritative review path.
4. Create the dedicated bridge without changing the running controller.
5. Prepare firewall and validator-key restrictions for the new single `/32` while retaining the old `/32` temporarily.
6. Add Jenkins to the dedicated bridge with its fixed address through the reviewed Compose change.
7. Change the Stage 4 SSH destination to the dedicated bridge gateway.
8. Run the existing read-only Stage 4 validation and confirm the traffic source is the new fixed `/32`.
9. Re-run the accepted safety assertions: `deployment.allowed=false`, `deployment.performed=false`, Stop-before-deployment executed, controller and target service restart expectations understood.
10. Remove the old `172.18.0.23/32` UFW allowance and old authorized-key source restriction only after the new path is proven.
11. Recreate or otherwise test the Jenkins controller once through the controlled path and confirm the fixed identity survives.
12. Record final evidence and rollback state.

## Rollback

Until validation is complete, retain the original `172.18.0.23/32` path in parallel.

If the new path fails:

- revert the Jenkins Stage 4 SSH destination to `172.18.0.1`;
- use the retained old `/32` firewall and key source restrictions;
- remove Jenkins from `jenkins_validation` if necessary;
- leave Stage 4 deployment disabled;
- do not proceed to Stage 5 authority work.

After final cutover, rollback remains a reviewed Compose/network and SSH-control change; it must not require widening SSH to the whole application subnet.

## Acceptance criteria

The durable identity work is complete only when all of the following are true:

```text
PASS: dedicated validation subnet does not overlap existing networks
PASS: Jenkins validation IP is declarative and fixed
PASS: only Jenkins controller requires validation-network membership
PASS: SSH firewall source remains exactly one /32
PASS: validator authorized key source remains exactly one address
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