# Nebula Sync — Pi-hole Configuration Replication

## Purpose

Nebula Sync provides configuration replication between the two Pi-hole DNS filtering nodes in the homelab.

The primary Pi-hole runs on **DietPi**. The secondary Pi-hole runs as **`pihole-secondary` on `ids-01`**. Nebula Sync copies selected Pi-hole configuration from the DietPi primary to the ids-01 secondary so that the secondary remains useful as a resilient DNS/filtering service if the primary becomes unavailable.

Nebula Sync is **not DNS failover itself**. DNS clients can use both Pi-hole nodes; Nebula Sync's role is to keep the secondary's filtering policy and selected DNS configuration aligned with the primary.

## Architecture

```text
                  configuration source
                         |
                         v
                +-----------------+
                | DietPi Pi-hole   |
                | primary          |
                +-----------------+
                         |
                         | Nebula Sync
                         | every 15 minutes
                         v
                +-----------------+
                | ids-01          |
                | pihole-secondary|
                +-----------------+
                         |
                         v
              resilient secondary DNS
```

Nebula Sync runs as a Docker container on `ids-01`:

```text
Container: nebula-sync
Image:     ghcr.io/lovelaze/nebula-sync:v0.11.2
Stack:     /home/james/docker/stacks/nebula-sync
Schedule:  */15 * * * *
Mode:      selective
Replicas:  1
```

Credentials/endpoints are supplied through Docker secrets using `PRIMARY_FILE` and `REPLICAS_FILE` rather than being embedded directly in the compose configuration.

## What is synchronised

The current deployment uses selective synchronisation rather than a full Pi-hole configuration copy.

Enabled areas include:

- Gravity domain lists.
- Groups.
- Clients.
- Client-to-group assignments.
- Adlists.
- Adlist-to-group assignments.
- Domain-list-to-group assignments.
- Selected DNS configuration.
- DNS hosts and CNAME records.
- Gravity rebuild after synchronisation.

Relevant current settings include:

```text
FULL_SYNC=false
SYNC_GRAVITY_CLIENT=true
SYNC_GRAVITY_CLIENT_BY_GROUP=true
SYNC_GRAVITY_AD_LIST=true
SYNC_GRAVITY_AD_LIST_BY_GROUP=true
SYNC_GRAVITY_DOMAIN_LIST=true
SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP=true
SYNC_GRAVITY_GROUP=true
SYNC_CONFIG_DNS=true
SYNC_CONFIG_DNS_INCLUDE=hosts,cnameRecords
RUN_GRAVITY=true
```

## What is deliberately not synchronised

Several Pi-hole configuration areas are disabled in the current design:

```text
SYNC_GRAVITY_DHCP_LEASES=false
SYNC_CONFIG_DHCP=false
SYNC_CONFIG_RESOLVER=false
SYNC_CONFIG_NTP=false
SYNC_CONFIG_DEBUG=false
SYNC_CONFIG_MISC=false
SYNC_CONFIG_DATABASE=false
```

This is intentional. Nebula Sync is being used to replicate the configuration required for consistent DNS filtering and selected DNS records, rather than blindly cloning every aspect of the primary node.

## Normal operation

Nebula Sync runs every 15 minutes. A normal cycle looks like:

```text
Running sync mode=selective replicas=1
Authenticating clients...
Syncing teleporters...
Syncing configs...
Running gravity...
Invalidating sessions...
Sync completed
```

`Sync completed` is the key successful completion message.

On 22 August 2026 the container was confirmed healthy and successfully completing synchronisation every 15 minutes, including runs at 06:00, 06:15, 06:30 and 06:45 BST.

## Why we use it

The homelab has two Pi-hole nodes for DNS resilience. Simply having a second DNS server running is not enough if its blocklists, groups, clients and DNS records drift away from the primary.

Nebula Sync reduces that configuration drift. If the DietPi primary fails, `pihole-secondary` on ids-01 should retain a recent copy of the important filtering policy and selected DNS configuration.

This separates two resilience concerns:

1. **DNS availability** — clients can use more than one Pi-hole DNS server.
2. **Configuration consistency** — Nebula Sync keeps the secondary reasonably aligned with the primary.

## Monitoring

Nebula Sync itself and the monitoring of Nebula Sync are separate components.

Custom Prometheus metrics are used to represent synchronisation health:

```text
homelab_pihole_sync_up
homelab_pihole_sync_last_result_success
homelab_pihole_sync_last_success_timestamp_seconds
homelab_pihole_sync_last_failure_timestamp_seconds
homelab_pihole_sync_age_seconds
```

The Grafana alert **Pi-hole Configuration Sync Unhealthy** monitors the ids-01 replica. It is intended to detect:

- the sync component being unavailable;
- the most recent sync failing; or
- no successful sync within 45 minutes.

The rule is currently labelled:

```text
component=nebula-sync
host=ids-01
service=pihole
severity=warning
```

## Monitoring incident — 22 August 2026

A `Pi-hole Configuration Sync Unhealthy — ids-01` warning fired even though Nebula Sync was operating normally.

Prometheus reported:

```text
homelab_pihole_sync_up = 1
homelab_pihole_sync_last_result_success = 0
homelab_pihole_sync_last_success_timestamp_seconds = 0
homelab_pihole_sync_age_seconds = -1
```

However, the live `nebula-sync` container was healthy and its logs showed repeated successful `Sync completed` messages every 15 minutes.

The operational conclusion was therefore:

> **Nebula Sync was healthy; the custom monitoring collector was not correctly recognising successful sync results.**

This distinction is important when responding to future alerts. A Grafana sync warning does not by itself prove replication has failed. The Nebula Sync container and its recent logs should be checked before making configuration changes.

### Current follow-up

The custom collector that generates `homelab_pihole_sync_*` metrics needs to be located and corrected so that a successful `Sync completed` run sets the success metrics and timestamp correctly.

Until that fix is completed, the Grafana warning can produce false positives even while replication is functioning.

## Operational checks

Check the container:

```bash
docker ps -a | grep nebula-sync
```

Check recent synchronisation activity:

```bash
docker logs --tail 150 nebula-sync
```

A healthy running container should report successful cycles ending in:

```text
Sync completed
```

Check the Prometheus view:

```bash
curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query={__name__=~"homelab_pihole_sync_.*",host="ids-01"}' | jq
```

If the logs show successful syncs but the Prometheus success metrics remain `0`, investigate the monitoring collector rather than Nebula Sync itself.

## Dependencies

Nebula Sync depends on:

- DietPi primary Pi-hole being reachable for configuration reads.
- `pihole-secondary` on ids-01 being reachable for configuration writes.
- Valid Pi-hole API authentication/secrets.
- Docker on ids-01.
- Network connectivity between ids-01 and the primary Pi-hole.

Monitoring additionally depends on:

- the custom Pi-hole sync metrics collector;
- node-exporter textfile collection;
- Prometheus scraping ids-01;
- Grafana alert evaluation and notification delivery.

A failure in the monitoring chain must not automatically be interpreted as a failure of Nebula Sync.

## Security considerations

- Primary and replica credentials are supplied through Docker secrets/files rather than placed directly in the visible environment configuration.
- The secondary should receive only the configuration areas intentionally selected for replication.
- Changes to the selective sync flags should be treated as configuration changes because they can alter data on the secondary Pi-hole.

## Maintenance and change considerations

When changing Nebula Sync:

1. Review the selective sync flags before applying the change.
2. Confirm both Pi-hole nodes are healthy.
3. Check `docker logs nebula-sync` after the next scheduled run.
4. Confirm the run reaches `Sync completed`.
5. Confirm the custom Prometheus sync metrics agree with the container logs.
6. Confirm the Grafana sync alert remains healthy.

Do not diagnose a replication failure from the Grafana alert alone; correlate the alert with the actual Nebula Sync logs.
