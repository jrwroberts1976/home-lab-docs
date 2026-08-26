# Container Version Control — Stage 4 Validation Gate Foundation

**Date:** 26 August 2026  
**Status:** Stage 4 foundation validated; comparator and Jenkins gate not yet implemented  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

## Purpose

This document records the operational checkpoint reached before implementing the Stage 4 candidate-image comparator and Jenkins validation gate.

The project is building controlled, observable and reversible Docker image version management. Git and Compose remain the desired-state authority, Renovate will propose changes, Jenkins will validate them, and WUD remains an independent update signal rather than a deployment authority.

At this checkpoint Stage 4 is deliberately **read-only**. No image pull, container recreation, restart or deployment capability has been introduced by the Stage 4 work described here.

## Stage 4 safety boundary

The first Jenkins milestone is a read-only validation gate. Its intended responsibilities are:

1. resolve service ownership;
2. identify the authoritative Git/Compose source;
3. validate Compose configuration;
4. compare current and proposed image identities;
5. block unsafe downgrades or unknown ordering;
6. verify architecture/manifest compatibility;
7. run Trivy security validation;
8. confirm secret readiness without exposing secret values; and
9. produce a non-secret deployment-plan artifact including an exact rollback target.

Automatic deployment is explicitly outside the current Stage 4 scope.

## Service ownership model

A service-ownership registry was created in the implementation repository as:

```text
config/service-ownership.yml
```

The ownership model distinguishes three authorities:

| Authority | Meaning |
|---|---|
| `docker-env` | Normal TestServer Compose service whose desired state is owned by `jrwroberts1976/docker-env` |
| `external-git` | Service whose runtime may appear under another filesystem location but whose source is owned by a separate Git repository |
| `platform-exception` | Deliberate service that currently has no acceptable Git source mapping and must fail closed for deployment automation |

Every recorded ownership rule currently has:

```text
validation: read-only
deployment_allowed: false
```

### Explicit ownership overrides

The following services require explicit ownership rather than the normal `docker-env` default:

| Runtime service | Authority | Repository / exception |
|---|---|---|
| `engineering-portfolio` | `external-git` | `jrwroberts1976/engineering-portfolio` |
| `projects-jrwroberts-co-uk` / `projects-site` | `external-git` | `jrwroberts1976/projects-jrwroberts-co-uk` |
| Jenkins controller | `platform-exception` | `no-git-source` |
| Jenkins DinD service | `platform-exception` | `no-git-source` |

The Engineering Portfolio runtime Compose copy under `/home/james/docker/stacks/engineering-portfolio/compose.yml` was verified byte-identical to its authoritative source `/home/james/projects/engineering-portfolio/compose.yml`. Its deployment script explicitly copies from the Git-owned project into the production runtime location.

The Jenkins controller and DinD Compose file remains under `/home/james/projects/docker-compose.yml`, and `/home/james/projects` is not itself a Git worktree. Jenkins is therefore intentionally treated as a platform exception. Jenkins may assess or propose a Jenkins update, but Jenkins must not automatically recreate or deploy its own controller.

## Read-only ownership resolver

The implementation repository now contains a read-only ownership resolver:

```text
scripts/resolve-service-ownership.sh
```

The resolver maps a running container through Docker Compose labels to the ownership registry and emits machine-readable JSON containing:

- container name;
- Compose project and service;
- authority;
- repository;
- authoritative source Compose path;
- runtime Compose path;
- image type;
- exception where applicable;
- validation mode; and
- `deployment_allowed`.

The resolver fails closed when a service is outside the default `docker-env` authority root and has no explicit override.

## Full TestServer validation

The ownership resolver was exercised against the complete TestServer Docker estate.

Validation result:

```text
resolved:            30
failed:              0
docker-env:          26
external-git:        2
platform-exception:  2
other authority:     0
```

Safety result:

```text
PASS: every container resolved to a recognised authority
```

All 30 resolved services returned:

```json
"deployment_allowed": false
```

This proves the Stage 4 ownership layer covers the current TestServer estate without silently assigning unknown external services to `docker-env`.

## Version-ordering strategy

A separate version-scheme registry was added as:

```text
config/version-schemes.yml
```

An inventory of image declarations in the clean `docker-env` worktree and the two external Git-owned projects found:

```text
semver               18
floating-or-channel   2
other                  8
```

The initial explicit ordering rules are:

| Repository | Parser | Reason |
|---|---|---|
| normal registry images | SemVer default | Most current TestServer release tags are semantic versions |
| `ghcr.io/tphakala/birdnet-go` | `yyyymmdd` | Current release tags use an eight-digit date such as `20260716` |
| `getwud/wud` | `integer` | Current release tags use integer releases such as `8` |
| `lscr.io/linuxserver/duckdns` | `opaque` | Tags such as `af6dcae5-ls86` must not be guessed into an ordering |
| `nginx` | `channel` | `alpine` is a moving channel, not an ordered release |
| local builds | `provenance` | Local images must be assessed through source/build provenance rather than tag ordering |

Unknown ordering must fail closed as:

```text
ordering-unknown-blocked
```

Local builds must report:

```text
local-build-provenance-required
```

## Digest precedence

Digest identity takes precedence over tag text.

A declaration such as:

```text
linuxserver/smokeping:latest@sha256:<digest>
```

is still reproducible at deployment time because the digest fixes the exact artifact, even though `latest` by itself is a moving tag.

Likewise, a digest-only declaration is reproducible even when no human-readable version tag is present.

A digest change under the same tag is a real image change and must receive full validation. It must not be silently treated as `same`, nor should Jenkins guess upgrade/downgrade ordering from an unchanged tag.

## Planned comparator results

The next implementation component is the read-only image comparator. Its expected policy results are:

```text
same
upgrade
downgrade-blocked
ordering-unknown-blocked
local-build-provenance-required
```

The following edge case remains to be explicitly classified before implementation is considered complete:

```text
same tag + different digest
```

It is known to be a real image change, but the final policy result name for that condition has not yet been selected.

## Implementation commits at checkpoint

The local implementation branch on TestServer is:

```text
stage4/service-ownership
```

Recorded local commits:

```text
71d526b  Add Stage 4 service ownership registry
828950a  Add Stage 4 service ownership resolver
8469100  Add Stage 4 image version scheme registry
```

At the time this operational checkpoint was written, that implementation branch had not yet been pushed to GitHub. These commit identifiers therefore record the validated local state rather than claiming the changes are already present on the remote default branch.

## Source checkout discipline

The live `/home/james/docker` checkout was intentionally left unchanged because it contained unrelated state and was behind its remote branch.

A clean detached worktree was created for Stage 4 source-of-truth validation:

```text
/var/tmp/docker-env-stage4
```

That worktree was based on `origin/main` and is used as clean desired-state input. Future Jenkins validation should use clean SCM checkouts/worktrees rather than treating live runtime filesystem copies as authoritative Git state.

External Git-owned services similarly require clean source checkouts of their own repositories.

## Next engineering step

Build and test the read-only image comparator independently of Jenkins.

The comparator must establish:

```text
What is running now?
What does authoritative Git declare?
What image is proposed?
Is it the same, an upgrade, a downgrade, or impossible to order safely?
```

Only after the comparator and related validation controls are proven should they be connected to a Jenkins Stage 4 pipeline. Deployment capability remains disabled until the later guarded-deployment stage has its own approval, rollback and recovery controls.
