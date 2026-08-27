# Stage 5 Candidate Image Staging — maintenance-page

**Date:** 27 August 2026  
**Status:** COMPLETE — IMAGE CACHE ONLY, NO DEPLOYMENT AUTHORITY ENABLED  
**Pilot:** `maintenance-page`

## Candidate

```text
nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913
```

Reviewed Linux/ARM64 child manifest:

```text
sha256:57744b8fa99abc438b1fbde6bd69e4270d0984ccfdee60c661ec22243047373a
```

Expected ARM64 image-config digest:

```text
sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5
```

## Staging result

The candidate was pulled by exact immutable index digest only.

Validation passed:

```text
PASS: candidate was not local before staging
PASS: remote Linux/ARM64 child still matched the reviewed manifest
PASS: pulled digest remained the exact reviewed candidate index
PASS: local image ID matched the reviewed ARM64 config digest
PASS: local platform is linux/arm64
PASS: local RepoDigest contains the reviewed candidate index digest
```

## Rollback baseline

The exact rollback identity remained local and continued to be the currently running maintenance-page image:

```text
nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
```

Rollback platform remained:

```text
linux/arm64
```

## No-container-mutation proof

A full `docker ps -aq` container-ID and restart-count snapshot was captured before and after image staging.

Result:

```text
PASS: all container IDs unchanged
PASS: all container restart counts unchanged
PASS: maintenance-page remained on the rollback image
PASS: Jenkins remained unchanged
PASS: Jenkins DinD remained unchanged
```

The maintenance-page HTTP baseline also remained healthy:

```text
GET http://192.168.2.220:8088/ -> 200
content marker -> Planned Maintenance | James Roberts
```

## Safety state

```text
IMAGE CACHE CHANGE ONLY
NO CONTAINER DEPLOYMENT PERFORMED
NO ACCOUNT CREATED
NO SSH KEY CREATED
NO SUDO RULE CREATED
NO HELPER/POLICY INSTALLED
NO AUTHORITY CHECKOUT INSTALLED
NO STAGE 5 DEPLOYMENT AUTHORITY ENABLED
NO STAGE 5 DEPLOYMENT PERFORMED
```

## Next gate

Both immutable images are now locally available. The next Stage 5 phase is an authority-installation design/rehearsal that computes the exact account, SSH, sudo, root-owned file, authority-checkout and policy installation state without yet enabling Jenkins deployment authority or deploying the maintenance-page container.
