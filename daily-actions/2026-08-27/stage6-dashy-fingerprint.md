# Stage 6 Dashy deep fingerprint

Date: 2026-08-27

## Status

Read-only discovery complete. No deployment performed.

## Current runtime

- service: `dashy`
- Compose project/service: `dashboards/dashy`
- current configured tag: `lissy93/dashy:4.5.13`
- current immutable digest: `lissy93/dashy@sha256:8bef3c7bf607de54bbcd4bc3733c481b06c0053b9d12ea781e3bd29457b8b6a4`
- current image ID: `sha256:417b161fc4c22a4dc6759110f6794c880c72a91e4b8c64e1d653605c2726b3ee`
- platform: `linux/arm64`
- container running: true
- restart count: 0
- Docker health status: healthy
- health command: `node services/healthcheck.js`
- network: `homelab_apps`
- runtime user: `node`
- privileged: false
- restart policy: `unless-stopped`

## Configuration boundary

Single writable bind mount:

- source: `/home/james/docker/data/dashboards/dashy/conf.yml`
- destination: `/app/user-data/conf.yml`
- SHA256: `03d8e2c988c949ae298b2ea76867759d359b5272a14e4b1f1bef33f2e71a96aa`
- owner: `james:james`
- mode: `0644`

WUD labels:

- `wud.watch=true`
- `wud.watch.digest=true`

## Git authority

- repository: `jrwroberts1976/docker-env`
- authority commit: `b8058c667cac59dc741587f0554437ee000f6486`
- authoritative Compose path: `stacks/dashboards/docker-compose.yml`
- Compose SHA256: `ffda0a4e3a42c350535dd1f0ed81a8326a5b1456f0d76f0570ef116465339c56`
- live Compose equals clean Git authority byte-for-byte
- Git currently pins `lissy93/dashy:4.5.13`

## Candidate discovery finding

The locally cached `lissy93/dashy:latest` image is **not an upgrade**:

- cached `latest` OCI version: `4.5.10`
- cached digest: `lissy93/dashy@sha256:de4e7150670ba8bc5ae3ec8da166cdd28531db0be0ce4053a7522a5085fa33ff`
- cached image ID: `sha256:cd978c0cf050b6042c2073fce67324e94db9d65ee46a581fe1ac9894c57d4738`
- platform: `linux/arm64`

The running service is already 4.5.13, so using the cached `latest` image would be a downgrade.

Upstream GitHub release discovery shows Dashy `4.6.0` as the current stable release, published 2026-08-21.

## Stage 6 design implication

Generic candidate selection must **not** trust a locally cached `latest` tag as an update source. The framework must:

1. resolve an explicit upstream version;
2. compare version ordering with the currently approved version;
3. resolve the exact immutable multi-arch/ARM64 digest for that explicit version;
4. reject stale `latest`, downgrade, same-version, wrong-architecture, or digest-drift candidates;
5. only after validation may the candidate be staged locally and proposed for human approval.

## Protected-state baseline

- Jenkins container ID: `f451fb005c7f3e0b23ee15dd39dc89cdea042fe178d5a212a643e432100a893d`
- Jenkins restart count: 0
- Jenkins DinD container ID: `6055f8a7d365779548a9dc6acd8babbb6856baf690e3ea193554d417d31d5548`
- Jenkins DinD restart count: 1

All container IDs and restart counts were unchanged by discovery.

## Result

`STAGE 6 DASHY FINGERPRINT: COMPLETE`

`NO DEPLOYMENT PERFORMED`
