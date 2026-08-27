# Stage 5 maintenance-page Candidate Dry-Run Evidence

**Date:** 27 August 2026  
**Status:** PASS — REVIEW ONLY, NO DEPLOYMENT AUTHORITY ENABLED

## Reviewed candidate

```text
docker-env PR: #16
branch: stage5/maintenance-page-nginx-1.31.4-candidate
candidate commit: 2f4965008440810bb4c3eb23d14f6bc4d40e44c4
candidate image: nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913
candidate version: nginx 1.31.4-alpine
candidate linux/arm64 child: sha256:57744b8fa99abc438b1fbde6bd69e4270d0984ccfdee60c661ec22243047373a
rollback image: nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
rollback version: nginx 1.31.3-alpine
```

## Candidate branch scope

Git comparison against `docker-env` base `1f95b0a2d6f8da5500a6a02d0d8416393107e8df` proved:

```text
1 commit
1 changed file
1 addition
1 deletion
```

Only `stacks/maintenance-page/docker-compose.yml` changed, replacing floating `nginx:alpine` with the reviewed immutable candidate digest.

## Corrected dry-run method

The first attempted worktree dry-run stopped safely before Docker because `git fetch origin <branch>` populated `FETCH_HEAD` without creating an `origin/<branch>` remote-tracking ref. No Compose or container operation occurred.

The corrected method:

1. fetched the exact branch ref and verified `FETCH_HEAD` equals candidate commit `2f496500...`;
2. created a detached review worktree from that exact SHA;
3. verified the reviewed Compose candidate pin;
4. proved reviewed/live Compose differed only by the candidate image line;
5. proved `nginx/default.conf` and `html/index.html` matched byte-for-byte;
6. used the reconciled live Compose path with an image-only temporary override so relative bind mounts remained anchored to the live stack directory;
7. ran `docker compose --dry-run` for `maintenance-page` only.

## Dry-run result

Compose proposed only the pilot service lifecycle:

```text
DRY-RUN MODE - maintenance-page Pulling
DRY-RUN MODE - maintenance-page Pulled
DRY-RUN MODE - Container maintenance-page Recreate
DRY-RUN MODE - Container maintenance-page Recreated
DRY-RUN MODE - Container <id>_maintenance-page Starting
DRY-RUN MODE - Container <id>_maintenance-page Started
```

No protected or unrelated service appeared in the dry-run.

## No-change proof

Before and after the dry-run:

```text
maintenance-page container ID: unchanged
maintenance-page restart count: unchanged
Jenkins container ID: unchanged
Jenkins restart count: unchanged
Jenkins DinD container ID: unchanged
Jenkins DinD restart count: unchanged
candidate image local presence: absent before and absent after
```

Therefore the dry-run did not pull the candidate and did not mutate a live container.

The live rollback identity remained:

```text
nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
```

HTTP baseline remained:

```text
GET http://192.168.2.220:8088/ -> 200
content marker -> Planned Maintenance | James Roberts
```

## Acceptance

```text
PASS: PR #16 candidate commit reproduced exactly
PASS: reviewed/live config differs only by candidate image
PASS: candidate Compose resolves exactly to reviewed digest
PASS: dry-run scope is maintenance-page only
PASS: no live container changed or restarted
PASS: no candidate image was pulled
PASS: nginx 1.31.3 rollback identity remains live
PASS: maintenance-page HTTP baseline remains healthy
```

## Safety state

```text
PR #16 = DRAFT / UNMERGED
Stage 5 deployment authority = NOT ENABLED
Stage 5 deployment performed = NO
```

## Next step

Implement the restricted Stage 5 wrapper/helper/policy and Jenkins approval contract in Git for review only. Do not install the host account, SSH key, sudo rule, helper, policy or Jenkins credential yet.
