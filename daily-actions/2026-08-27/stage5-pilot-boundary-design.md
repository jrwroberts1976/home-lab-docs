# Stage 5 Pilot Deployment Boundary

**Date:** 27 August 2026  
**Status:** DESIGN ONLY — NO DEPLOYMENT AUTHORITY ENABLED  
**Scope:** First controlled container deployment pilot after Stage 4 read-only validation

## Purpose

Define the minimum control boundary required before Jenkins is permitted to perform any deployment action.

Stage 4 remains the accepted read-only baseline. Stage 5 must not weaken the existing credential, host-key, source-IP, schema, wrapper or audit controls. This document deliberately defines policy and acceptance criteria only; it does not grant Jenkins Docker/Compose deployment authority.

## Non-negotiable safety boundary

Until a later reviewed implementation change explicitly enables the pilot, the current state remains:

```text
Stage 4 = COMPLETE
READ-ONLY
credential-store execution proven
deployment.allowed=false
deployment.performed=false
Stop before deployment = enforced
```

No deployment command is authorized by this design document.

## Stage 5 pilot objective

Prove that one low-risk service can be changed through a narrowly scoped, human-approved, reversible deployment path while preserving all Stage 4 evidence controls.

The pilot is successful only if it proves the control model, not merely that a container can be restarted.

## Human approval boundary

A deployment must require an explicit human action after the candidate deployment plan has already been generated and reviewed.

Required sequence:

```text
1. Generate read-only deployment plan
2. Validate candidate against schema and policy
3. Show exact current -> candidate identity
4. Show planned command/action
5. Show pre-defined health checks
6. Show pre-defined rollback target and rollback action
7. HUMAN APPROVAL
8. Execute one approved deployment action
9. Run health/smoke validation
10. Record result
11. Stop
```

The approval must be specific to one build, one target service and one reviewed candidate identity. Approval must not become a reusable global deployment switch.

## Pilot scope restrictions

The first Stage 5 pilot must be limited to exactly one service.

The selected service must:

- be non-critical to core network operation;
- not provide DNS, routing, firewalling, identity, secrets, storage, monitoring control-plane, CI/CD control-plane or Kubernetes control-plane functions;
- have a simple known-good rollback target;
- have no destructive database/schema migration in the pilot change;
- have no host-network, privileged or broad device-access requirement introduced by the pilot;
- have deterministic health or smoke checks that can run immediately after deployment;
- be represented by authoritative Git-managed configuration;
- have its current running image/config identity captured before execution;
- have its candidate image/config identity pinned before approval.

## Explicit exclusions

The following are not eligible for the first pilot:

- Jenkins controller;
- Jenkins DinD;
- private Docker registry;
- Pi-hole or Unbound;
- router, switch or firewall services;
- Greenbone/OpenVAS control services;
- Prometheus, Grafana, Loki or other monitoring control-plane components;
- k3s/Kubernetes control-plane components;
- any service whose rollback requires manual data repair;
- any service whose deployment would affect multiple unrelated Compose services.

The Jenkins controller remains a permanent platform exception: Jenkins must never automatically deploy or recreate itself.

## Required candidate identity

Before approval, the pipeline must show enough immutable information to distinguish the currently running artifact from the candidate.

Minimum evidence:

```text
target service/container
current image reference
current image digest or equivalent immutable identity
candidate image reference
candidate digest or equivalent immutable identity
authoritative Compose/config Git commit
whether deployment changes config, image, or both
expected container recreation/restart scope
```

A mutable tag alone is not sufficient candidate identity.

## Required deployment-plan assertions

The Stage 5 plan must continue to expose explicit policy fields.

Before approval:

```text
deployment.allowed=false
deployment.performed=false
approval.required=true
approval.granted=false
```

Only inside the narrowly scoped approved execution stage may the pilot set an execution-local approval state. The plan artifact itself must remain immutable after approval.

The deployment implementation must refuse execution if any of the following differ from the reviewed plan:

- target service;
- candidate digest/identity;
- authoritative Git commit;
- expected deployment command class;
- expected restart/recreation scope;
- rollback target.

## Deployment command boundary

The first pilot must expose only the minimum command required for the selected service.

The implementation must not grant Jenkins unrestricted shell, unrestricted Docker socket access, arbitrary `docker exec`, arbitrary Compose project control, arbitrary Git mutation, or subnet-wide remote-shell authority.

Preferred control pattern:

```text
Jenkins credential-store identity
        |
        v
restricted SSH source/destination controls
        |
        v
forced command / allow-listed deployment wrapper
        |
        +-- plan <approved-service>
        +-- deploy <approved-service> <approved-candidate>
        +-- rollback <approved-service> <approved-rollback-id>
```

The wrapper must reject all non-allow-listed services and actions.

## Pre-deployment gates

All of these must pass before the human approval point:

```text
PASS: Stage 4 schema/wrapper integrity checks
PASS: strict SSH host-key validation
PASS: Jenkins credential-store authentication
PASS: target service is the single approved pilot
PASS: authoritative Git commit is exact and clean
PASS: current runtime identity captured
PASS: candidate immutable identity captured
PASS: candidate differs only as expected
PASS: deployment action preview generated
PASS: restart/recreation scope matches expectation
PASS: health checks defined and runnable
PASS: rollback identity captured and available
PASS: rollback command preview generated
PASS: no platform-exception service included
PASS: no unrelated service operation proposed
```

Any failed pre-deployment gate must stop before approval is offered.

## Human approval semantics

The approval prompt must display, at minimum:

```text
service
current immutable identity
candidate immutable identity
authoritative Git commit
exact deployment action class
expected service interruption/recreation
health checks
rollback target
```

The user must actively approve the specific candidate. Timeout, absence of response or aborted build means no deployment.

## Execution boundary

After approval, the pipeline may execute only the reviewed pilot action.

Required runtime protections:

- re-check candidate identity immediately before deployment;
- re-check current runtime identity has not drifted since plan generation;
- stop if drift is detected;
- execute exactly one target-service deployment operation;
- never deploy/recreate Jenkins itself;
- do not automatically continue to another service;
- preserve full stdout/stderr and return-code evidence;
- set `deployment.performed=true` only after the deployment command was actually issued successfully enough to begin the target change;
- record the resulting immutable runtime identity.

## Post-deployment validation

The pilot must have pre-defined validation that is independent of the deployment command returning zero.

Minimum checks:

- container/service is running as expected;
- resulting immutable image/config identity matches the approved candidate;
- target port/HTTP/service health check passes where applicable;
- service-specific smoke check passes;
- expected network membership remains intact;
- no unexpected additional container was recreated/restarted;
- Jenkins controller and Jenkins DinD remain unchanged;
- monitoring can still observe the pilot service where applicable.

## Automatic stop and rollback boundary

If any required post-deployment validation fails, the pipeline must stop further forward action immediately.

For the first pilot, rollback should require either:

1. an automatic rollback only when the rollback action and rollback identity were fully pre-approved as part of the same pilot plan; or
2. a second explicit human approval before rollback.

No ad-hoc recovery shell should be granted to Jenkins.

Rollback must restore the exact pre-deployment immutable identity or other explicitly captured known-good target.

After rollback, the same health/smoke checks must run again and the final state must be recorded.

## Audit artifact

The completed pilot run must archive a machine-readable artifact containing at least:

```text
stage
build/run identifier
target service
authoritative Git commit
current identity at plan time
candidate identity
approval required/granted
approval actor or recorded human approval event where available
deployment action class
deployment.allowed
deployment.performed
deployment start/end result
post-deployment identity
health-check results
rollback required
rollback performed
rollback identity/result
final state
```

Secrets, private keys and credential values must never appear in the artifact.

## Failure semantics

The build must fail closed.

Examples:

```text
candidate identity changed -> STOP
runtime drift after plan -> STOP
approval absent -> STOP
health check unavailable -> STOP
unexpected service recreation -> FAIL / ROLLBACK PATH
rollback target unavailable -> STOP BEFORE DEPLOYMENT
wrapper integrity mismatch -> STOP
host-key mismatch -> STOP
```

A Jenkins infrastructure or transport problem must never be interpreted as deployment approval.

## Stage 5 implementation phases

The implementation should be introduced in separate reviewed steps:

1. **Design approval** — review this boundary with no code granting deployment authority.
2. **Pilot selection** — choose exactly one eligible service and document its current state, candidate, checks and rollback.
3. **Wrapper design** — add only the allow-listed pilot deployment/rollback operations and review them before installation.
4. **Pipeline design** — add plan + human approval + execution stages while retaining Stage 4 assertions.
5. **Dry-run proof** — prove the new pipeline stops before deployment and shows the exact approval payload.
6. **Authority installation** — install only the reviewed restricted deployment capability.
7. **Controlled pilot** — run one approved deployment.
8. **Closeout** — archive evidence, verify rollback readiness, and decide whether any broader Stage 5 scope is justified.

Each phase must be independently reviewable. Do not combine design, authority grant and first live deployment into one uncontrolled change.

## Acceptance criteria for the boundary

This design is ready for pilot selection when all of the following are agreed:

```text
PASS: one-service pilot only
PASS: explicit human approval after read-only plan
PASS: immutable current and candidate identities shown
PASS: approval is build/service/candidate specific
PASS: pre-defined health checks required
PASS: rollback target captured before deployment
PASS: fail-closed drift detection required
PASS: deployment wrapper is allow-listed, not general shell
PASS: Jenkins controller cannot deploy/recreate itself
PASS: no unrestricted Docker/Compose authority
PASS: full audit artifact required
PASS: Stage 4 remains read-only until a separate reviewed authority change
```

## Current decision state

```text
Stage 5 boundary design: DOCUMENTED
Stage 5 pilot service: NOT YET SELECTED
Stage 5 deployment wrapper: NOT YET IMPLEMENTED
Stage 5 Jenkins pipeline authority: NOT YET IMPLEMENTED
Stage 5 deployment authority: NOT ENABLED
Stage 5 deployment performed: NO
```
