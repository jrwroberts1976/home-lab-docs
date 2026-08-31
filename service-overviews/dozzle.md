# Dozzle — Live Docker Log Viewer

## Purpose

Dozzle provides a lightweight web interface for viewing live Docker container logs during operational troubleshooting.

It is a short-term operational view. Loki remains the central retained log platform.

## Current homelab role

Dozzle runs on TestServer as the `dozzle` service in the `management` Compose project.

Current reviewed version:

```text
10.8.0
```

Current configured immutable image:

```text
amir20/dozzle@sha256:243666b0593ff33ed1373901575236f0d6bed8a2d6b451cdae4345969a7b6d5c
```

Current local image/config ID:

```text
sha256:eca1774c3ff18eb6ff177d0d557b2ff37da5df6f7c617450b4eca48327f20ce8
```

At the 31 August Stage 6 closeout the running container had restart count `0` and state `running`.

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

The durable `docker-env` Compose default now resolves to the exact immutable 10.8.0 image. The authority promotion was merged as:

```text
ba183402d11b8a2def59bf7f50893c1667aff9ac
```

Reviewed Compose SHA-256:

```text
80215935aa7815ed39853483934e834ef44c96dce8d0939f9644764c289a2485
```

Both the live and root-owned Stage 6 authority checkouts were synchronised to that exact commit without recreating Dozzle.

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

Final 31 August verification returned HTTP `200`.

## Stage 6 management state

Dozzle is the first previously deferred service requalified against the generic Stage 6 framework using internal-container HTTP health and a read-only Docker socket.

The estate catalogue now records:

```text
desired_version:       10.8.0
current_version:       10.8.0
coverage:              managed-tested
class:                 readonly-docker-socket
inspect_ready:         true
manifest:              dozzle-10.8.0.json
steady_state_manifest: dozzle.json
```

The catalogue/steady-state promotion was merged in `homelab-container-version-control` as:

```text
95f4a0f32828547488370f372e314c76e263239c
```

Installed steady-state manifest:

```text
/etc/homelab-stage6/steady-state/dozzle.json
```

The final read-only steady-state inspection completed with:

```text
SUCCESS_CLOSED: Dozzle 10.8.0 fully closed and steady-state verified
```

## Jenkins qualification note

Dozzle was deployed by Jenkins build #13 after reviewed pre-approval inspection, human approval and zero-drift reinspection.

The exact 10.8.0 deployment succeeded, but the historical Jenkins build later failed during disarm because the transition helper did not yet support `container-http` terminal health.

That framework gap was subsequently fixed and the already-deployed update was disarmed without a second recreation. Git authority, catalogue and steady state were then completed through reviewed recovery steps.

Therefore:

- Dozzle itself is fully closed and healthy;
- Jenkins build #13 must not be rerun merely to obtain a green historical build;
- the consumed Dozzle update must not be redeployed;
- the next Jenkins proof for Dozzle should be a non-mutating closed-state verification action.

The desired verification result is conceptually:

```text
SUCCESS_VERIFIED_CLOSED
```

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
- Do not manually recreate Dozzle to retest the already-consumed 10.8.0 Stage 6 update.
- Future updates should use the completed Jenkins Stage 6 flow once candidate acquisition and end-to-end closure are integrated.

## Related documentation

- [31 August Stage 6 container-update closeout](../daily-actions/2026-08-31/stage6-container-update-closeout.md)
- [Jenkins](jenkins.md)
- [Loki](loki.md)
- [Grafana Alloy](alloy.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
