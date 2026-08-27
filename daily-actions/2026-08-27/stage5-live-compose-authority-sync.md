# Stage 5 Live Compose Authority Sync — maintenance-page

**Date:** 27 August 2026  
**Status:** COMPLETE — LIVE CONFIGURATION SYNCED, NO DEPLOYMENT PERFORMED

## Purpose

Synchronize the live `maintenance-page` Compose file with the merged `docker-env` Git authority without recreating or restarting the running container and without enabling Stage 5 deployment authority.

## Git authority

```text
repository: jrwroberts1976/docker-env
authority commit: f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883
live file: /home/james/docker/stacks/maintenance-page/docker-compose.yml
authoritative SHA256: 26fb63ff74360932f0dbf9eb27876c67bb3212767aaa6a11ea6c3370750eeadf
```

The only pre-sync live-vs-authority delta was the reviewed image declaration:

```yaml
image: nginx:alpine
```

became:

```yaml
image: "${MAINTENANCE_PAGE_IMAGE:-nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913}"
```

No other Compose drift was present.

## Immutable image state

```text
candidate:
nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913
linux/arm64 config ID:
sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5

rollback / currently running:
nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
runtime image ID:
sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483
```

Both immutable images are now locally available as Linux/ARM64.

## Validation result

The sync procedure:

- fetched the exact merged `docker-env` authority commit;
- verified the authoritative Compose SHA256;
- proved the pre-change delta was only the reviewed image declaration;
- verified candidate and rollback Compose rendering;
- verified both immutable images were local Linux/ARM64 images;
- retained the current live Compose backup;
- installed only the exact authoritative Compose file;
- validated Compose syntax for candidate and rollback modes;
- ran Compose dry-run only;
- proved the dry-run scope was `maintenance-page` only;
- proved every Docker container ID and restart count remained unchanged;
- proved `maintenance-page` remained on the rollback image;
- proved HTTP returned `200` and contained `Planned Maintenance | James Roberts`.

Retained backup:

```text
/var/backups/maintenance-page-compose-before-stage5-20260827-071201.yml
```

## Safety state

```text
Live Compose configuration: MATCHES MERGED GIT AUTHORITY
Candidate image: LOCAL
Rollback image: LOCAL AND CURRENTLY RUNNING
Container deployment performed: NO
Stage 5 account: NOT CREATED
Stage 5 SSH key: NOT CREATED
Stage 5 sudo rule: NOT CREATED
Stage 5 helper/policy: NOT INSTALLED
Stage 5 authority checkout: NOT INSTALLED
Stage 5 Jenkins credential: NOT CREATED
Stage 5 deployment authority: NOT ENABLED
Stage 5 deployment performed: NO
```

## Next gate

Perform an installation rehearsal only. Calculate the exact merged authority-gate/helper hashes, proposed execution-policy values, ownership/modes, account and sudo boundaries, authority-checkout identity and SSH forced-command shape without creating or installing them.

The currently merged Stage 5 SSH wrapper remains review-only and rejects `deploy maintenance-page` and `rollback maintenance-page`. A separate reviewed execution wrapper and Jenkins human-approval pipeline path are still required before Stage 5 authority may be enabled.
