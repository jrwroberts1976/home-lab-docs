# Container Version Control — Stage 4 Candidate Planner Checkpoint

**Date:** 26 August 2026  
**Status:** READ-ONLY CANDIDATE PLANNER VALIDATED  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

This checkpoint supersedes the earlier Stage 4 note in `daily-actions.md` that identified the candidate image planner as the next engineering step.

## Completed in this checkpoint

The Stage 4 implementation now includes three stacked review units:

```text
#19  stage4/service-ownership
#20  stage4/image-comparator
#21  stage4/candidate-planner
```

GitHub comparison confirmed `stage4/candidate-planner` is exactly one commit ahead of `stage4/image-comparator` and adds only:

```text
scripts/plan-image-update.py
```

Candidate-planner commit:

```text
f3de3b1  Add Stage 4 candidate image planner
```

## Validated planner path

The first complete real path used Dozzle on TestServer:

```text
running container
→ service ownership
→ clean authoritative Git checkout
→ Compose validation
→ desired image extraction
→ runtime image identity
→ remote OCI index
→ linux/arm64 platform manifest
→ image comparator
→ read-only JSON plan
```

Authoritative source:

```text
repository: jrwroberts1976/docker-env
revision:   232a364bd929b2ed3ed6ffa37dccd045f8c05843
compose:    stacks/management/docker-compose.yml
service:    dozzle
```

Desired/runtime image:

```text
amir20/dozzle:v10.7.2
```

Runtime image ID:

```text
sha256:f1480337d833d51986224a50211780b6ccf2b4cbf0f92be3b0eab4b44b6c469d
```

Runtime RepoDigest and remote OCI index digest matched exactly:

```text
sha256:01f9018ffdaa0ec523f9a91dea3eff65b25cdb5f0566ac6d5a2cb4cf591e35e9
```

Exactly one compatible platform manifest was found:

```text
platform: linux/arm64
digest:   sha256:f4328903c5e34dae27b1a64439d6e047172fc3a4cfc925c59ea008f3178c4069
```

Comparator result:

```text
method: exact-digest
result: same
```

Deployment state remained:

```text
allowed:   false
performed: false
```

## Fail-closed controls

Five deliberate planner tests passed:

1. clean checkout of the wrong Git repository was rejected;
2. dirty authoritative checkout was rejected;
3. local-build candidate was rejected pending provenance handling;
4. Jenkins platform exception was rejected; and
5. the valid Dozzle path continued to succeed.

Result:

```text
passed: 5
failed: 0
```

The exact staged planner blob was executed successfully before commit.

## Secret-handling boundary

The planner validates the complete Compose model but discards rendered output. It then obtains only the selected service image through:

```text
docker compose config --images <service>
```

This prevents the planner from retaining a fully rendered Compose document containing interpolated environment values.

## Safety state

No image was pulled by the planner. No container was recreated, restarted or deployed. No `docker compose up` was executed. No Git mutation or deployment primitive exists in the planner. Jenkins has not been given Docker deployment authority by this work.

## Next Stage 4 work

1. broaden registry-image candidate coverage and safely handle supported manifest forms;
2. implement local-build provenance handling;
3. add Trivy candidate security validation;
4. add secret-readiness checks without exposing secret values;
5. produce the non-secret deployment-plan artifact with exact rollback identity; and
6. connect the proven read-only controls into Jenkins only after those gates are independently validated.

Deployment remains disabled throughout Stage 4.
