# Container Version Control — Stage 4 Validation Gate Foundation

**Date:** 26 August 2026  
**Status:** Stage 4 ownership, image comparator and read-only candidate planner validated; Jenkins gate integration not yet implemented  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

## Purpose

This document records the operational checkpoint reached while building the Stage 4 validation gate for controlled Docker/Compose image version management.

Git and Compose remain the desired-state authority, Renovate proposes changes, Jenkins will validate them, and WUD remains an independent update signal rather than a deployment authority.

Stage 4 remains deliberately **read-only**. The validated components described here can inspect Git, Compose, runtime Docker image identity and remote registry manifest metadata, but they do not pull images, restart or recreate containers, run `docker compose up`, deploy services or give Jenkins deployment authority.

## Stage 4 safety boundary

The first Jenkins milestone is a read-only validation gate. Its intended responsibilities are:

1. resolve service ownership;
2. identify and verify the authoritative Git/Compose source;
3. validate Compose configuration;
4. identify current runtime and desired candidate image identities;
5. block unsafe downgrades or unknown ordering;
6. verify architecture/manifest compatibility;
7. run Trivy security validation;
8. confirm secret readiness without exposing secret values; and
9. produce a non-secret deployment-plan artifact including an exact rollback target.

Automatic deployment is explicitly outside the current Stage 4 scope.

## Service ownership model

The implementation repository contains:

```text
config/service-ownership.yml
scripts/resolve-service-ownership.sh
```

The ownership model distinguishes three authorities:

| Authority | Meaning |
|---|---|
| `docker-env` | Normal TestServer Compose service whose desired state is owned by `jrwroberts1976/docker-env` |
| `external-git` | Service whose runtime may appear under another filesystem location but whose source is owned by a separate Git repository |
| `platform-exception` | Deliberate service that currently has no acceptable Git source mapping and must fail closed for deployment automation |

Every resolved rule currently returns:

```text
validation: read-only
deployment_allowed: false
```

### Explicit image types

Image type is now explicit for the complete current TestServer container estate:

```text
registry-image: 25
local-build:     5
unknown/null:    0
```

The five local-build services are:

- `birdnet-exporter`;
- `crowdsec-exporter`;
- `engineering-portfolio`;
- `projects-jrwroberts-co-uk`; and
- the Jenkins controller platform exception.

This prevents the candidate planner from guessing whether a service is registry-backed or locally built.

### Explicit ownership overrides

The following services require explicit ownership rather than the normal `docker-env` default:

| Runtime service | Authority | Repository / exception |
|---|---|---|
| `engineering-portfolio` | `external-git` | `jrwroberts1976/engineering-portfolio` |
| `projects-jrwroberts-co-uk` / `projects-site` | `external-git` | `jrwroberts1976/projects-jrwroberts-co-uk` |
| Jenkins controller | `platform-exception` | `no-git-source` |
| Jenkins DinD service | `platform-exception` | `no-git-source` |

The Engineering Portfolio runtime Compose copy under `/home/james/docker/stacks/engineering-portfolio/compose.yml` was verified byte-identical to its authoritative source `/home/james/projects/engineering-portfolio/compose.yml` at the ownership checkpoint.

The Jenkins controller and DinD Compose file remains under `/home/james/projects/docker-compose.yml`, and `/home/james/projects` is not itself a Git worktree. Jenkins is therefore intentionally treated as a platform exception. Jenkins may assess or propose a Jenkins update, but Jenkins must not automatically recreate or deploy its own controller.

## Full TestServer ownership validation

The ownership resolver was exercised against the complete TestServer Docker estate.

```text
resolved:            30
failed:              0
docker-env:          26
external-git:        2
platform-exception:  2
other authority:     0
```

All 30 resolved services returned:

```json
"deployment_allowed": false
```

This proves the Stage 4 ownership layer covers the current TestServer estate without silently assigning unknown external services to `docker-env`.

## Version-ordering strategy

The implementation repository contains:

```text
config/version-schemes.yml
scripts/compare-image-version.py
```

The initial explicit ordering rules are:

| Repository | Parser | Reason |
|---|---|---|
| normal registry images | SemVer default | Most current TestServer release tags are semantic versions |
| `ghcr.io/tphakala/birdnet-go` | `yyyymmdd` | Release tags use an eight-digit date such as `20260716` |
| `getwud/wud` | `integer` | Release tags use integer releases such as `8` |
| `lscr.io/linuxserver/duckdns` | `opaque` | Tags such as `af6dcae5-ls86` must not be guessed into an ordering |
| `nginx` | `channel` | `alpine` is a moving channel, not an ordered release |
| local builds | `provenance` | Local images must be assessed through source/build provenance rather than tag ordering |

The comparator emits fail-closed results including:

```text
same
upgrade
downgrade-blocked
ordering-unknown-blocked
local-build-provenance-required
```

## Comparator validation

The read-only comparator is implemented and validated.

Synthetic policy matrix:

```text
15/15 PASS
```

Coverage includes:

- SemVer same / upgrade / downgrade;
- `v`-prefixed SemVer;
- BirdNET `YYYYMMDD` upgrade / downgrade;
- WUD integer upgrade / downgrade;
- opaque DuckDNS ordering blocked;
- nginx channel ordering blocked;
- same digest classified `same`;
- same tag with different digest treated as a real change and blocked as unknown ordering;
- repository changes blocked;
- local builds require provenance; and
- malformed or unsupported digest values fail closed.

Real TestServer checks included Dozzle, BirdNET-Go, WUD, DuckDNS, Smokeping and Engineering Portfolio.

## Digest precedence and runtime identity

Digest identity takes precedence over tag text.

A declaration such as:

```text
linuxserver/smokeping:latest@sha256:<digest>
```

is reproducible at deployment time because the digest fixes the exact artifact, even though `latest` by itself is a moving tag.

Runtime validation also established that Docker `Config.Image` must not be treated as the complete immutable identity. For example, a Git declaration may contain a tag plus digest while the runtime creation reference only preserves the tag.

The Stage 4 planner therefore records separately:

```text
Docker Config.Image
runtime image ID
runtime RepoDigests
runtime OS / architecture
candidate OCI index digest
candidate platform-manifest digest
```

## Read-only candidate image planner

The implementation repository now contains:

```text
scripts/plan-image-update.py
```

The first candidate-planner path joins:

```text
running container
    -> ownership resolver
    -> explicit clean authoritative Git checkout
    -> Compose validation
    -> exact desired service image
    -> runtime image identity
    -> remote OCI manifest metadata
    -> target-platform manifest
    -> image comparator
    -> read-only JSON plan
```

For registry-backed services the planner:

- requires `validation=read-only`;
- requires `deployment_allowed=false`;
- rejects platform exceptions from automatic planning;
- rejects local builds until provenance handling is implemented;
- requires an explicit clean authoritative Git checkout;
- verifies the checkout's GitHub repository against the ownership registry;
- records the exact Git revision used as desired-state evidence;
- validates the full Compose model;
- extracts only the selected service image;
- records runtime image ID and RepoDigest independently from `Config.Image`;
- resolves the remote OCI index digest without pulling image layers;
- selects exactly one manifest matching the runtime OS and architecture;
- invokes the comparator using immutable digest identity; and
- emits deployment state explicitly as disabled and not performed.

## Compose secret-handling boundary

The planner deliberately avoids retaining the full rendered Compose document.

Validation runs:

```text
docker compose config
```

with stdout discarded. Candidate extraction then uses image-only output:

```text
docker compose config --images <service>
```

This means the planner validates the full Compose model without capturing a rendered configuration that could contain interpolated environment values.

## Dozzle end-to-end validation

Dozzle was used as the first complete real TestServer candidate-planner path.

Authoritative source:

```text
repository: jrwroberts1976/docker-env
revision:   232a364bd929b2ed3ed6ffa37dccd045f8c05843
compose:    stacks/management/docker-compose.yml
service:    dozzle
```

Desired and runtime reference:

```text
amir20/dozzle:v10.7.2
```

Runtime identity:

```text
image ID:
sha256:f1480337d833d51986224a50211780b6ccf2b4cbf0f92be3b0eab4b44b6c469d

RepoDigest / OCI index digest:
sha256:01f9018ffdaa0ec523f9a91dea3eff65b25cdb5f0566ac6d5a2cb4cf591e35e9

platform:
linux/arm64
```

Remote registry inspection returned an OCI image index with exactly one `linux/arm64` application manifest:

```text
sha256:f4328903c5e34dae27b1a64439d6e047172fc3a4cfc925c59ea008f3178c4069
```

The top-level remote index digest exactly matched the runtime RepoDigest.

Final comparator result:

```text
method: exact-digest
result: same
```

Final deployment state:

```json
{
  "allowed": false,
  "performed": false
}
```

The exact staged planner blob was executed successfully before commit.

## Candidate-planner fail-closed validation

Five deliberate planner controls were exercised:

```text
5/5 PASS
```

Validated rejection cases:

1. clean checkout of the wrong Git repository;
2. dirty authoritative checkout;
3. local-build candidate pending provenance handling; and
4. Jenkins `platform-exception` candidate.

The fifth test confirmed that a valid Dozzle plan still succeeded after the negative controls.

Additional safety checks confirmed the planner contains no deployment or source-control mutation primitives.

## Implementation branches and pull requests

Stage 4 is being reviewed as a stacked series so each capability remains independently reviewable:

| PR | Branch | Capability |
|---|---|---|
| `#19` | `stage4/service-ownership` | ownership registry, resolver, image types and version schemes |
| `#20` | `stage4/image-comparator` | pure/read-only image comparator |
| `#21` | `stage4/candidate-planner` | read-only candidate image planner |

Candidate-planner commit:

```text
f3de3b1  Add Stage 4 candidate image planner
```

GitHub comparison confirmed `stage4/candidate-planner` is exactly one commit ahead of `stage4/image-comparator` and adds only:

```text
scripts/plan-image-update.py
```

## Source checkout discipline

The live `/home/james/docker` checkout was intentionally left unchanged because it contained unrelated state and was behind its remote branch.

A clean detached worktree remains the Stage 4 desired-state input for `docker-env` validation:

```text
/var/tmp/docker-env-stage4
```

Current recorded revision during the Dozzle planner validation:

```text
232a364bd929b2ed3ed6ffa37dccd045f8c05843
```

Future Jenkins validation should use clean SCM checkouts/worktrees rather than treating live runtime filesystem copies as authoritative Git state.

## Next engineering step

The next Stage 4 milestone is to extend the candidate planner beyond the proven Dozzle path and complete the remaining validation-gate controls:

1. broaden registry-image coverage and handle supported manifest forms safely;
2. implement local-build provenance handling;
3. add Trivy candidate security validation;
4. add secret-readiness checks without exposing secret values;
5. produce the non-secret deployment-plan artifact including exact rollback identity; and
6. only then connect the proven read-only controls into Jenkins.

Deployment capability remains disabled. Guarded deployment, health checks and rollback execution belong to the later deployment stage and require their own approval and recovery controls.
