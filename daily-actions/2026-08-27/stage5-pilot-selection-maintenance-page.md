# Stage 5 Pilot Selection — maintenance-page

**Date:** 27 August 2026  
**Status:** SELECTED — DESIGN/BASELINE ONLY, DEPLOYMENT AUTHORITY NOT ENABLED  
**Pilot service:** `maintenance-page`

## Decision

Select `maintenance-page` as the first Stage 5 controlled deployment pilot.

This selection does not authorize a deployment. The Stage 4 safety boundary remains in force until a separate reviewed implementation explicitly installs the narrowly scoped Stage 5 wrapper and approval path.

```text
Stage 4 = COMPLETE
READ-ONLY
deployment.allowed=false
deployment.performed=false
Stage 5 deployment authority = NOT ENABLED
```

## Why this service was selected

The live candidate audit showed `maintenance-page` has the smallest blast radius among the reviewed low-risk services:

- one container and one Compose service;
- non-privileged;
- no Docker socket mount;
- no writable data/database mount;
- no secrets observed in the Compose definition;
- two read-only bind mounts only;
- one LAN-bound HTTP port (`192.168.2.220:8088 -> 80`);
- one existing external network (`homelab_apps`);
- restart count `0` at selection time;
- static content served by nginx;
- deterministic HTTP smoke checks are available;
- rollback can restore the exact current nginx image identity without data repair.

Other reviewed candidates were rejected for the first pilot because they introduced additional authority or state:

- `dozzle`: read-only Docker socket mount;
- `homepage`: writable data/log/config mounts plus Docker socket;
- `dashy`: writable configuration mount;
- `librespeed`: writable configuration mount;
- `filebrowser`: writable configuration/database/data mounts.

## Authoritative Git definition

Repository:

```text
jrwroberts1976/docker-env
```

Authoritative `main` at selection time:

```text
1f95b0a2d6f8da5500a6a02d0d8416393107e8df
```

Stack path:

```text
stacks/maintenance-page/
```

Reviewed Git identities:

```text
docker-compose.yml blob: d71a7f4bb1e4d3c212c343ea7743ccaa52a43d6c
nginx/default.conf blob: ee5c4ef3dad09c13f4a8a2de14f2981b7d5ace1b
html/index.html blob:    20a3db1c4de7692c81ca894c3667bf1f95d036c4
```

The Git Compose definition currently uses:

```text
image: nginx:alpine
container_name: maintenance-page
restart: unless-stopped
port: 192.168.2.220:8088:80
mounts: html -> /usr/share/nginx/html:ro
        nginx/default.conf -> /etc/nginx/conf.d/default.conf:ro
network: homelab_apps
```

The live container's Compose labels point to `/home/james/docker/stacks/maintenance-page/docker-compose.yml`. That live checkout remains non-authoritative; the final implementation must reconcile the exact pilot source back to the reviewed `docker-env` Git authority before any deployment action is offered.

## Current live baseline

Captured during the read-only candidate audit:

```text
container:          maintenance-page
state:              running
restart count:      0
configured image:   nginx:alpine
runtime image ID:   sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483
repo digest:        nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
privileged:         false
network:            homelab_apps
live IPv4:          172.18.0.10
network gateway:    172.18.0.1
published endpoint: 192.168.2.220:8088 -> 80/tcp
healthcheck:        none defined
```

Live mounts:

```text
/home/james/docker/stacks/maintenance-page/nginx/default.conf
  -> /etc/nginx/conf.d/default.conf (read-only)

/home/james/docker/stacks/maintenance-page/html
  -> /usr/share/nginx/html (read-only)
```

## Rollback target

The first pilot rollback target is the exact currently running immutable image identity:

```text
nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
```

The runtime image ID at baseline is:

```text
sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483
```

Rollback must also use the reviewed maintenance-page configuration identity. No rollback is permitted to a floating tag alone.

## Candidate image gate

The current Git definition uses mutable tag `nginx:alpine`. That is acceptable as historical configuration evidence but is not sufficient Stage 5 candidate identity.

Before any deployment authority is installed or any human approval is requested, the implementation must select and review one exact candidate digest, for example conceptually:

```text
nginx@sha256:<reviewed-candidate-digest>
```

Required candidate gate:

```text
PASS: candidate digest explicitly recorded
PASS: architecture matches TestServer
PASS: candidate image available locally or pullable before approval
PASS: candidate differs from current baseline only as intended
PASS: authoritative Git change pins the digest
PASS: rollback digest remains available
```

A pipeline must refuse to deploy `nginx:alpine` as a mutable candidate.

## Pre-defined health and smoke checks

The first pilot must validate more than Docker command success.

Required checks after deployment and after any rollback:

```text
1. container `maintenance-page` is running
2. resulting image digest/immutable identity matches the approved target
3. restart/recreation scope contains only `maintenance-page`
4. Jenkins controller was not recreated/restarted
5. Jenkins DinD was not recreated/restarted
6. network membership remains `homelab_apps`
7. published endpoint remains `192.168.2.220:8088 -> 80/tcp`
8. both application/config mounts remain read-only
9. HTTP GET http://192.168.2.220:8088/ succeeds
10. response contains expected marker: `Planned Maintenance | James Roberts`
```

The nginx configuration uses `try_files $uri $uri/ /index.html`, and the reviewed HTML contains title `Planned Maintenance | James Roberts`, giving a deterministic application-level smoke check.

## Expected deployment scope

For the pilot, only the `maintenance-page` service may be recreated.

Forbidden scope:

```text
Jenkins
jenkins-docker
other homelab_apps containers
Docker network recreation
host firewall changes
host SSH changes
unrelated Compose services
```

The deployment wrapper must reject any request outside the exact allow-listed service.

## Pilot approval payload

Before the human approval gate, Jenkins must display at minimum:

```text
service: maintenance-page
current image digest: nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
candidate image digest: <exact reviewed digest>
authoritative docker-env commit: <exact reviewed commit>
config identity: <reviewed stack blobs/commit>
expected action: recreate maintenance-page only
health endpoint: http://192.168.2.220:8088/
health marker: Planned Maintenance | James Roberts
rollback image digest: nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752
approval.required=true
approval.granted=false
```

## Selection acceptance result

```text
PASS: one-service pilot
PASS: non-critical service
PASS: no privileged mode
PASS: no Docker socket
PASS: no writable application/database state
PASS: authoritative Git-managed stack exists
PASS: current immutable runtime identity captured
PASS: exact rollback image captured
PASS: deterministic smoke checks defined
PASS: no data repair required for rollback
PASS: Jenkins remains excluded
PASS: mutable candidate tag identified and blocked
```

## Current state

```text
Stage 5 boundary design: COMPLETE
Stage 5 pilot selection: COMPLETE — maintenance-page
Candidate digest: NOT YET SELECTED
Restricted deployment wrapper: NOT YET IMPLEMENTED
Jenkins approval/execution stages: NOT YET IMPLEMENTED
Stage 5 deployment authority: NOT ENABLED
Stage 5 deployment performed: NO
```

## Next step

Design the restricted Stage 5 wrapper and dry-run pipeline contract for `maintenance-page`, including digest pinning, drift detection, exact one-service recreation scope, human approval semantics, smoke checks and rollback. Do not install or enable the deployment command during the design/dry-run phase.
