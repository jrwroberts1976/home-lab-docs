# Stage 6 — Seven Inspect-Ready Instances Closeout

Date: 29 August 2026

## Outcome

Stage 6 steady-state inspection has advanced from the earlier four-instance checkpoint to **seven inspect-ready service/host instances** without widening the caller-facing mutation surface.

Current inspect-ready estate:

```text
Dashy / TestServer                 4.6.0
Homepage / TestServer              2.1.2
Prometheus / TestServer            3.13.2
Prometheus / ids-01                3.13.2
Blackbox Exporter / TestServer     0.28.0
Blackbox Exporter / ids-01         0.28.0
maintenance-page / TestServer      1.31.4
```

The estate front end remains read-only for these steady-state paths. `prepare`, `deploy` and `rollback` remain fail-closed in the current caller-facing `homelab-update` implementation.

## Blackbox Exporter completion

Blackbox Exporter was normalized from its tagged configured image to the reviewed immutable digest on both TestServer and ids-01 using the dedicated same-image normalization framework rather than weakening generic update/rollback rules.

Reviewed image:

```text
prom/blackbox-exporter@sha256:e753ff9f3fc458d02cca5eddab5a77e1c175eee484a8925ac7d524f04366c2fc
```

The steady-state onboarding source was merged in `homelab-container-version-control` PR #80 as:

```text
77a26a84f8b6b45b9bc4647f4737325a19f5769e
```

Final Blackbox steady-state manifest hashes:

```text
TestServer  fb37ad15445f5dab2a063634470ab05c4ed6ef71ca5b861130e9ba34e55586fe
ids-01      2adfd6503cc4df6419479e7c8c730f3edc5d98a0a3c05781f3145509f3b34fa7
```

The merged catalog hash after Blackbox activation was:

```text
02efcf49dd4befb1a05b7811236c3a8c389404135e2a86dbef5eb2cb6509052a
```

Combined TestServer + ids-01 `homelab-update --action inspect` passed with mutation disabled and deployment unperformed.

## maintenance-page completion

`maintenance-page` was selected next because it was already running an immutable Nginx digest and therefore required no image normalization.

Observed version:

```text
nginx 1.31.4
```

Reviewed configured image:

```text
nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913
```

Local image ID on TestServer:

```text
sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5
```

Reviewed `docker-env` authority remains:

```text
d1ca9a5e10d151893573fd97d6a5c282ba912a1e
```

Reviewed Compose SHA-256:

```text
26fb63ff74360932f0dbf9eb27876c67bb3212767aaa6a11ea6c3370750eeadf
```

Runtime contract:

- container: `maintenance-page`;
- network: `homelab_apps`;
- published endpoint: `192.168.2.220:8088 -> 80/tcp`;
- restart policy: `unless-stopped`;
- privileged: false;
- read-only root filesystem: false;
- no device authority;
- no Docker socket authority;
- two reviewed read-only bind mounts.

Reviewed content hashes:

```text
default.conf  5f776d04e520489a0958d2f267dcf034448a3c385b88f142ae7aa67d53a34d13
index.html    9497b740f24af80568843efdf500544a25b47f4dd3fe248161c31c4cd202eb29
change.json   59b8e6034f7c3e76893a86b126ed862182e4aa38aa9aca36c0c884ab790d0ec8
```

HTTP health at `http://192.168.2.220:8088/` returned 200 throughout discovery, source review, commit/push, merge, activation and cleanup.

The maintenance-page source change was merged in `homelab-container-version-control` PR #81 as:

```text
6a508c8af676682b25a8ac390917edf5518c7db8
```

Installed maintenance-page manifest SHA-256:

```text
e162b97d7c835049ac7e44ac4fac4d1479e282a9b7871b9ac463f43e515aad90
```

Activated catalog SHA-256:

```text
85b1e963b6a7ec4cc8aad0e8ca12976b65231f6831c2562d387b8d277193bb21
```

Direct steady-state inspection passed, followed by the first real live `homelab-update` inspection for `maintenance-page`.

Final proof:

```text
inspect_ready_instances=7
MUTATION_ALLOWED=false
DEPLOYMENT_ALLOWED=false
DEPLOYMENT_PERFORMED=false
TESTSERVER_CONTAINERS_UNCHANGED=30
CONTAINER_CHANGED=false
RUNTIME_CHANGED=false
```

The temporary source worktree, local source branch and remote source branch were removed after proving the merged source commit remained contained in `main`. Production Stage 6 metadata and the running container were retained unchanged.

## Safety boundary retained

At this checkpoint:

- steady-state inspection remains read-only;
- no arbitrary image, path, digest, SSH identity or command inputs are exposed to callers;
- no deploy-time pulls are permitted;
- immutable configured-image identity is required for inspect-ready workloads;
- TestServer Jenkins and Jenkins-DinD remain protected during relevant inspections;
- ids-01 protected workloads remain within the reviewed remote inspection boundary;
- device-backed, privileged, writable-Docker-socket, stateful and local-build workloads remain outside the generic low-risk onboarding path until their own contracts are reviewed.

## Next Stage 6 work

Continue the remaining Docker estate by risk class, prioritising low-risk standard-registry workloads that already fit the reviewed steady-state model. Likely easier candidates include Authelia, Cloudflare DDNS, DuckDNS, LibreSpeed, Nebula Sync and Node Exporter, subject to fresh runtime/source discovery before onboarding.

More complex workloads such as cAdvisor, Portainer, BirdNET-Go, Nginx Proxy Manager, stateful stores and local-build services must not inherit the low-risk contract merely to increase coverage.

## Section status

**Blackbox Exporter onboarding: complete.**

**maintenance-page onboarding: complete.**

**Stage 6 seven-instance steady-state checkpoint: complete.**
