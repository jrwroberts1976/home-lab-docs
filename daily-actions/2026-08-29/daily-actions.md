# Daily Actions — 29 August 2026

## Starting position

The 28 August record was closed with Prometheus, Homepage and Dashy proven through the Stage 6 work completed to that point. The main priority for 29 August remained the **one updater for the estate** programme, starting with a read-only steady-state inspection path and then extending that model across hosts without widening mutation authority.

## Current Stage 6 checkpoint

Current `homelab-container-version-control` reviewed main after today's merges:

```text
container-http framework merge     = 1f78afcbb9041b4076c63b4d64b133e94f9a0896  (PR #76)
steady authority transition merge  = 60f6bc1d7bc8cbed12011b258bb2f12930f8f454  (PR #77)
```

Current reviewed `docker-env` authority target:

```text
d1ca9a5e10d151893573fd97d6a5c282ba912a1e
```

Current Docker runtime scope proven during today's work:

```text
TestServer   linux/arm64   30 containers
ids-01       linux/amd64   31 containers
```

Existing steady-state inspect-ready service/host instances remain:

```text
Dashy/TestServer          4.6.0
Homepage/TestServer       2.1.2
Prometheus/TestServer     3.13.2
Prometheus/ids-01         3.13.2
```

## Completed today

### Steady-state inspection framework

- Completed the read-only Stage 6 steady-state inspection model rather than reusing the pre-approval transition inspector.
- Preserved reviewed authority, immutable image identity, runtime shape, mounts, networks, health and protected-container invariants.
- Kept mutation authority out of the steady-state inspector: no pull, arm, deploy, rollback, recreate or arbitrary command surface.
- Integrated steady-state routing into the estate updater while keeping `prepare`, `deploy` and `rollback` fail-closed in the current front end.
- Proved Homepage, Dashy and Prometheus steady-state inspection on TestServer.

### ids-01 / cross-architecture inspection

- Installed and proved the narrow ids-01 Stage 6 read-only inspection transport.
- Preserved the separate fixed-command SSH/sudo trust boundary rather than granting broad shell or Docker authority.
- Brought ids-01 Prometheus to the proven `3.13.2` state and completed two-host steady-state inspection for Prometheus.
- Proven combined Prometheus inspection result: both TestServer and ids-01 inspect-ready, no mutation allowed, no deployment performed.

### Blackbox Exporter onboarding preparation

- Selected Blackbox Exporter as the next low-risk, standard-registry cross-host workload.
- Confirmed both hosts currently run `0.28.0`.
- Confirmed TestServer and ids-01 use the common repository/index digest:

```text
prom/blackbox-exporter@sha256:e753ff9f3fc458d02cca5eddab5a77e1c175eee484a8925ac7d524f04366c2fc
```

- Added the reviewed `BLACKBOX_EXPORTER_IMAGE` Compose override to both TestServer and ids-01 source paths in `docker-env` PR #23.
- Aligned both live Compose files with `docker-env` revision `d1ca9a5e10d151893573fd97d6a5c282ba912a1e` without pulling an image, recreating a container or restarting a service.
- TestServer Blackbox remains healthy through `192.168.2.220:9115/-/healthy`.
- ids-01 Blackbox remains healthy through its `monitoring` Docker network without publishing port 9115 to the host.

### `container-http` framework extension

- Added a narrow declarative `container-http` steady-state health strategy for services such as ids-01 Blackbox that expose health only inside a reviewed Docker network.
- The manifest may provide only a reviewed network, numeric container port, path and expected status; a fixed URL is rejected.
- The inspector derives the current container IP from `NetworkSettings.Networks[$network].IPAddress`; no container IP is hard-coded.
- Negative tests reject undeclared networks, invalid/boolean ports, unsafe paths and fixed URLs.
- Full steady-state regression suite passed with no host contact or mutation during source validation.
- PR #76 merged as `1f78afcbb9041b4076c63b4d64b133e94f9a0896`.
- Installed the reviewed inspector and validator on both hosts.
  - TestServer retains `root:root 0755`.
  - ids-01 retains its stronger `root:root 0700` boundary.
- Runtime verification after installation proved all 30 TestServer containers and all 31 ids-01 containers unchanged.

### Shared authority reconciliation

- The Blackbox image-variable source change legitimately changed the shared monitoring Compose hashes, making the older steady-state authority metadata stale.
- Survey proved the target `docker-env` revision descends from both previous reviewed authority baselines.
- Dashy and Homepage Compose content is unchanged and therefore retains SHA-256:

```text
9a1295c5c7848c578a9b339411b02b2320cb7bd4b78764fce1d6b661fe97287f
```

- TestServer monitoring Compose now correctly targets:

```text
b8a895bd8e23c9f528cf9209f70368be42bf53f8044cbd99ef35eae188e3d68b
```

- ids-01 monitoring Compose now correctly targets:

```text
128a8e842a2b1bc54b966b93aac9d11ba1d7c0cc7d8eb89282c7f2ffa1f89ae9
```

- PR #77 changed only the four existing steady-state manifests: Dashy/Homepage authority revision only, and both Prometheus manifests authority revision plus reviewed Compose hash.
- PR #77 merged as `60f6bc1d7bc8cbed12011b258bb2f12930f8f454`.

## Current safety boundary

At this checkpoint:

- the reviewed source authority transition is merged, but the installed Stage 6 authority checkout/manifests still need to be advanced and re-proven;
- no update is armed;
- no image was pulled as part of the framework/authority work;
- no container was changed by the `container-http` framework installation;
- the estate front end still exposes steady-state inspection only for the reviewed inspect-ready paths;
- Jenkins/Jenkins-DinD remain protected on TestServer;
- Grafana/Loki remain protected during ids-01 Stage 6 work;
- Blackbox Exporter remains `inspect_ready=false` for a deliberate reason described below.

## Blackbox remaining blocker

Blackbox is technically healthy and its source authority is ready, but the running containers still report the configured image as the tagged form:

```text
prom/blackbox-exporter:v0.28.0
```

The steady-state contract correctly requires the running configured image to be the reviewed immutable digest reference. The existing generic transition framework also deliberately requires a genuinely different rollback digest/newer candidate and therefore is not suitable for simply recreating the same Blackbox image under a digest reference.

Do **not** weaken those validation/rollback guarantees merely to make Blackbox show as inspect-ready. The safe choices are:

1. design and regression-test a separate narrow same-image tag-to-digest normalization contract with a truthful rollback model; or
2. leave Blackbox pending until its next real version upgrade, then bring it under the normal Stage 6 immutable transition path.

## Next safe actions

1. Advance the installed Stage 6 `docker-env` authority checkout to `d1ca9a5e10d151893573fd97d6a5c282ba912a1e` together with the reviewed steady-state manifests.
2. Re-run Dashy, Homepage and both Prometheus steady-state inspections and prove the original four inspect-ready instances remain good after authority roll-forward.
3. Decide whether to build the reusable same-image immutable-normalization contract or wait for the next Blackbox release.
4. If normalization is implemented, add reviewed Blackbox steady-state manifests/catalogue routing and prove a combined TestServer + ids-01 inspection with no mutation.
5. Continue onboarding the remaining Docker estate by risk class rather than weakening policy to increase the inspect-ready count.

## Daily report triage

The 29 August nightly homelab report review is still an explicit operational step in `todo.md`. Record its findings separately when reviewed; do not infer a clean report from Stage 6 project validation.

## Daily summary

Today moved Stage 6 from a TestServer-focused pilot into a working cross-host read-only inspection framework. The steady-state model, ids-01 transport, multi-host Prometheus proof and internal-network HTTP health strategy are now implemented and reviewed. The shared authority debt created by the Blackbox Compose-source change has been corrected in Git source through PR #77.

The immediate remaining work is operational roll-forward and re-proof of the existing four managed instances. Blackbox itself is deliberately left pending rather than compromising immutable identity or rollback guarantees.
