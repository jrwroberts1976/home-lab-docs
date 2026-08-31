# Loki — Central Log Storage

## Purpose

Loki is the homelab log store used for central investigation, dashboards, alerting and security evidence. It receives labelled log streams from Grafana Alloy and other supported collectors so operational evidence does not remain isolated on individual hosts or containers.

## Current homelab role

Loki runs on both TestServer and `ids-01`. The live Grafana instance on `ids-01` uses the local Loki container as its primary Loki datasource.

```text
Hosts / containers / security services
              |
              v
         Grafana Alloy
              |
              v
             Loki
              |
              +--> Grafana dashboards
              +--> log-backed alerts
              +--> security investigation
              +--> AI/SecOps evidence readers
```

The `ids-01` logging path includes streams for Pi-hole, Unbound, CrowdSec, CrowdSec Local API, the firewall bouncer and Greenbone review output. Stable labels are important because dashboards and scripts query those labels directly.

## ids-01 Stage 6 update state — 31 August 2026

The `ids-01` Loki service was updated through the generic multi-host Stage 6 Jenkins path from `3.7.6` to `3.7.7`.

Current verified immutable runtime image:

```text
grafana/loki@sha256:d70e4659623f3e109af669cae76fe2a5dd5be54e2298fe8aed380d982fbc2500
```

Current local image ID:

```text
sha256:d70e4659623f3e109af669cae76fe2a5dd5be54e2298fe8aed380d982fbc2500
```

Reviewed platform manifest:

```text
sha256:550d599ec4efacd8ebc0a5871766855057cba2bd0c669c0711d898c00d6d901f
```

OCI config digest:

```text
sha256:a52a3f3d29ceb505474cb493a7d61f7d810ac666ecd98dff41c676299f5bf684
```

Platform:

```text
linux/amd64
```

Independent post-deployment verification showed:

```text
state=running
restart=0
/ready -> ready
```

Grafana and Prometheus remained running and unchanged during the deployment.

## What the Loki Stage 6 test proved

The Jenkins run successfully exercised:

- reviewed multi-host routing to `ids-01`;
- pinned host-key verification;
- read-only pre-approval inspection;
- explicit human approval;
- post-approval zero-drift reinspection;
- executor credential binding only after those gates;
- exact one-shot arm;
- recreation of only Loki using the already-local immutable candidate;
- `--no-deps --no-build --pull never --force-recreate` deployment semantics;
- runtime/health/protected-container verification;
- rollback skip because acceptance passed;
- disarm.

This is the successful generic multi-host deployment proof for Stage 6.

## Loki closure gap still carried forward

The Loki test happened before the full end-to-end closure process was completed.

The `ids-01` runtime is on 3.7.7, but the durable Git Compose authority/catalogue/steady-state records were not automatically promoted as part of that successful Jenkins build.

At the 31 August closeout the known gap remained:

- `docker-env` still has the older Loki fallback/default authority that needs deliberate promotion;
- the estate catalogue still carries stale Loki state;
- no final Loki steady-state manifest has yet been closed to match the 3.7.7 runtime.

This is a metadata/authority closure task, not an instruction to redeploy the already-healthy Loki container.

The later Dozzle work established the desired closure pattern: promote immutable Compose authority, synchronise authority without recreation, promote catalogue and steady state, install the reviewed steady-state definition and run a final read-only verification.

Loki should eventually be reconciled through that same reviewed closure model without unnecessary container recreation.

## Dependencies

Loki depends on reliable storage, the Docker runtime on the host, valid collector configuration and network reachability from Alloy. Grafana and security/reporting consumers depend on Loki being available and on expected streams continuing to arrive.

## Monitoring and health

Health must cover more than whether the container is running. Validate:

- the Loki process is reachable;
- `/ready` reports ready;
- Grafana can query the datasource;
- expected streams contain recent entries;
- Alloy is not reporting rejected or failed writes;
- storage has sufficient free space;
- ingestion has not silently stopped for critical streams.

A healthy Loki container with stale streams is an ingestion failure, not a healthy logging service.

## Data, backup and recovery

Loki data is operational evidence and should be treated as persistent state. Recovery priorities are:

1. restore the authoritative Compose/configuration;
2. restore persistent Loki data where retention of historical evidence is required;
3. restore Alloy collectors;
4. confirm current ingestion before relying on dashboards or reports.

Where historical logs are not part of the restore objective, the service can be rebuilt from configuration, but loss of retained security/incident evidence must be explicitly accepted.

## Security

Loki should remain infrastructure-only unless there is a deliberate authenticated publishing requirement. Logs can contain internal hostnames, IP addresses, usernames, request paths and security evidence, so unrestricted access is inappropriate.

## Change and maintenance rules

- Preserve stable labels used by dashboards, alerts and scripts.
- Validate ingestion after collector or logging-driver changes.
- Do not assume a container restart proves log recovery.
- Check storage growth and retention before increasing collection scope.
- Keep host-specific monitoring stacks distinct where their Compose definitions differ.
- Do not redeploy `ids-01` Loki merely to close stale Git/catalogue metadata; reconcile closure without unnecessary runtime mutation.
- Future Stage 6 updates should use Jenkins-owned candidate acquisition and complete end-to-end authority/catalogue/steady-state closure.

## Related documentation

- [31 August Stage 6 container-update closeout](../daily-actions/2026-08-31/stage6-container-update-closeout.md)
- [Grafana Alloy](alloy.md)
- [Grafana](grafana.md)
- [Jenkins](jenkins.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Log ingestion and Grafana email recovery SOP](../sop/log-ingestion-and-grafana-email-recovery.md)
- [Service Overviews index](README.md)
