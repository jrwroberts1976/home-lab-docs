# Dozzle — Live Docker Log Viewer

## Purpose

Dozzle provides a lightweight web interface for viewing live Docker container logs during operational troubleshooting.

It is a short-term operational view. Loki remains the central retained log platform.

## Current homelab role

Dozzle runs on TestServer as the `dozzle` service in the `management` Compose project.

Current live version:

```text
10.9.0
```

Current live configured immutable image:

```text
amir20/dozzle@sha256:7f01a2504f89788b60ad0efddd94472fd66f9a225c708356cdb815d9d8abd184
```

Current local image/config ID:

```text
sha256:88b0c06d1a3c881893d2162afa4b19d1b91262e1ae92a90e661d8ccc2a5549d9
```

Post-deployment verification on 03 September 2026 proved the container running, `restart=unless-stopped`, exact image identity, and Dozzle `v10.9.0` accepting connections on port `8080`.

```text
Docker container logs
      |
      +--> Dozzle (live operational view)
      |
      +--> Alloy/Loki where centrally collected
```

## Runtime and Compose authority

Reviewed Compose identity:

```text
host:               TestServer
project:            management
service/container:  dozzle
project directory:  /home/james/docker/stacks/management
compose file:       /home/james/docker/stacks/management/docker-compose.yml
image variable:     DOZZLE_IMAGE
network:            homelab_apps
published ports:    none
restart policy:     unless-stopped
privileged:         false
read-only rootfs:   false
runtime user:       empty string
```

Dozzle has exactly one reviewed Docker socket bind:

```text
/var/run/docker.sock -> /var/run/docker.sock
read-only
```

### Current authority state

The live runtime is now 10.9.0, but the last fully closed durable Stage 6 authority baseline remains the previously promoted 10.8.0 state until the 10.9.0 authority/catalogue/steady-state closure is completed.

The 10.9.0 update must therefore not be described as `SUCCESS_CLOSED` yet. The remaining closure work is to promote the exact successful 10.9.0 immutable image into Git Compose authority, update the estate catalogue, generate/install the new steady-state manifest, and run non-mutating `VERIFY_CLOSED`.

## Monitoring and health

Dozzle does not publish a host port and does not define a Docker healthcheck.

Stage 6 therefore uses the reviewed `container-http` health strategy:

```text
network:         homelab_apps
container port:  8080
path:            /
expected status: 200
```

The Stage 6 inspector dynamically resolves the current Dozzle container address on `homelab_apps`; the IP is not hard-coded in configuration or documentation.

## Stage 6 10.9.0 deployment — 03 September 2026

Jenkins job `stage6-generic-service-update`, build **#34**, successfully performed the reviewed 10.8.0 -> 10.9.0 update.

Reviewed rollback/current identity before deployment:

```text
version: 10.8.0
configured image: amir20/dozzle@sha256:243666b0593ff33ed1373901575236f0d6bed8a2d6b451cdae4345969a7b6d5c
image ID: sha256:eca1774c3ff18eb6ff177d0d557b2ff37da5df6f7c617450b4eca48327f20ce8
```

Reviewed candidate:

```text
version: 10.9.0
immutable image: amir20/dozzle@sha256:7f01a2504f89788b60ad0efddd94472fd66f9a225c708356cdb815d9d8abd184
platform manifest: sha256:dedcf5fc948e8eb5a325182d2743a59d8540e4a6ca740e0c064826e0e86c1fa9
image/config ID: sha256:88b0c06d1a3c881893d2162afa4b19d1b91262e1ae92a90e661d8ccc2a5549d9
platform: linux/arm64
```

Jenkins proved:

- reviewed manifest schema and security invariants;
- pinned source/host route;
- read-only pre-approval inspection;
- exact rollback and candidate identities with `deployment=false`;
- explicit human approval;
- second read-only inspection with exact zero drift;
- executor credential exposure only after approval and zero drift;
- exact update arm;
- exact local immutable candidate deployment with `--pull never` semantics;
- runtime/health acceptance;
- rollback not required;
- one-shot execution authority disarmed.

Final Jenkins result:

```text
STAGE 6 dozzle RESULT: DEPLOYED EXACT CANDIDATE AND DISARMED
Finished: SUCCESS
```

Independent post-deploy verification then proved:

```text
running=true
image_id=sha256:88b0c06d1a3c881893d2162afa4b19d1b91262e1ae92a90e661d8ccc2a5549d9
configured_image=amir20/dozzle@sha256:7f01a2504f89788b60ad0efddd94472fd66f9a225c708356cdb815d9d8abd184
restart=unless-stopped
```

and logs reported:

```text
Dozzle version v10.9.0
Connected to Docker
Accepting connections on :8080
```

## Container recreation boundary

The Stage 6 pipeline does not recreate Dozzle during preparation, candidate cache acquisition, inspection, approval, zero-drift reinspection, executor preflight or arm.

The running container is recreated only by the actual deployment stage, using the equivalent of:

```text
docker compose up -d --no-deps --no-build --pull never --force-recreate dozzle
```

Closure and `VERIFY_CLOSED` must not recreate an already-healthy candidate.

## Validator synchronization lesson

The first 10.9.0 attempt failed safely before approval because TestServer still had an older installed Stage 6 validator.

The repository validator accepted the reviewed chained-update manifest, where the 10.8.0 rollback `configured_image` is the exact immutable rollback reference. The stale target validator still required an exact tagged rollback image and rejected it.

Repository validator SHA-256 at the successful update preparation point:

```text
85aa0c1e3bfe7fa92fd2acd98195d1f96fb622f36a0d08b1a9361f74ad06cc8d
```

The reviewed validator was synchronized to:

```text
/usr/local/libexec/homelab-stage6-validate-service-manifest
```

and hash-verified before the clean retry.

Operational rule: target-side Stage 6 validators/inspectors must match or be explicitly proven against reviewed repository source before deployment inspection. Framework drift must fail closed; validation must not be weakened to bypass it.

## Preparation reset proof

Before the successful build #34 run, the earlier 10.9.0 preparation state was reset without touching the live 10.8.0 container:

- the prior installed transition manifest was restored;
- the cached 10.9.0 candidate was removed;
- the reviewed validator was synchronized;
- the reviewed 10.9.0 transition manifest was reinstalled and validated;
- the exact 10.9.0 ARM64 candidate was reacquired into the local image cache;
- live Dozzle remained on the reviewed 10.8.0 rollback identity until the deployment stage.

This proved candidate/cache preparation is separate from runtime mutation.

## Remaining Stage 6 closure

The 10.9.0 deployment is successful, but durable closure remains outstanding until all of the following pass:

- promote the exact 10.9.0 immutable image into Git Compose authority;
- synchronize authority without recreating/restarting Dozzle;
- promote the estate catalogue to 10.9.0;
- generate/review/install the 10.9.0 steady-state manifest;
- run non-mutating `VERIFY_CLOSED`;
- require authority, catalogue, runtime, image identity and health to agree.

## Backup and recovery

Dozzle is largely stateless/configuration-driven. Recovery depends on restoring:

- the Git-controlled Compose authority;
- the exact reviewed image identity;
- the read-only Docker socket mount;
- the external `homelab_apps` network;
- the Stage 6 catalogue and steady-state definition where governed recovery is required.

Historical log recovery belongs to Loki or the underlying logging system, not Dozzle.

## Security

Docker logs can contain internal addresses, request details and occasionally sensitive application output. Dozzle access should remain restricted.

Although the Docker socket is mounted read-only, Docker API access remains security-sensitive. Stage 6 therefore treats Dozzle as medium risk and requires the exact reviewed socket shape.

## Change and maintenance rules

- Do not treat Dozzle as the retained audit log.
- Do not expose Dozzle publicly without a deliberate protected design.
- Preserve the read-only Docker socket policy.
- Do not hard-code the current container IP; use the reviewed Docker network for health resolution.
- Use immutable image authority for approved versions.
- Preparation/inspection/closure must not recreate the running container.
- Future updates must preserve reviewed manifest validation, explicit approval, zero-drift proof, separate authority levels and `--pull never` deployment.

## Related documentation

- [03 September daily actions](../daily-actions/2026-09-03/daily-actions.md)
- [03 September TODO](../daily-actions/2026-09-03/todo.md)
- [31 August Stage 6 container-update closeout](../daily-actions/2026-08-31/stage6-container-update-closeout.md)
- [Jenkins](jenkins.md)
- [Loki](loki.md)
- [Grafana Alloy](alloy.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
