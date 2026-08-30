# Restic — Backup and Recovery

## Purpose

Restic is the homelab backup tool used to create encrypted, deduplicated, versioned backups of important host configuration and persistent data.

The backup service exists to support recovery after host loss, storage failure, accidental deletion, configuration corruption or a failed change. A successful Restic command is not the final objective; the objective is to maintain backups that can be enumerated, authenticated, restored and validated when needed.

The operating principle is:

> Back up the data required to rebuild the service, protect the repository credentials separately, monitor the backup path, and prove restores.

## Current architecture

The current Restic design contains both clients and a central REST endpoint.

```text
backup client host
      |
      |  restic backup
      v
HTTPS Rest Server on ids-01
      |
      v
Restic repository storage
      |
      +--> snapshots
      +--> retention / prune
      +--> recovery / restore
```

The Rest Server on `ids-01` is monitored as:

```text
container: restic-server
host:      ids-01
port:      8000/tcp
protocol:  HTTPS
```

The local health collector uses the endpoint:

```text
https://192.168.2.242:8000/
```

and, where available, validates TLS using:

```text
/home/homelab-backup/rest-server/tls/rest-server.crt
```

An unauthenticated HTTP `401` or `403` response is considered healthy for the reachability test because authentication rejection proves that the HTTPS service is reachable while correctly refusing anonymous access.

## Current protected components

The documented Restic-related estate includes:

- the `restic-server` Docker service on `ids-01`;
- a Restic health collector and systemd timer on `ids-01`;
- Grafana alerts for Restic server failure and stale health metrics;
- SOPS-encrypted recovery sources for Restic client/repository credentials;
- a scheduled DietPi Restic backup;
- Restic as a recovery dependency in the `ids-01` host-rebuild plan.

Restic is therefore part of the homelab recovery architecture, not just a standalone backup command.

## DietPi scheduled backup

DietPi has a dedicated Restic backup script:

```text
scripts/dietpi/restic-backup-dietpi
```

The live script sources protected environment configuration from:

```text
/etc/restic/dietpi.env
```

and backs up:

```text
/etc
/home
/usr/local
/var/lib
```

These paths are intended to capture the configuration, custom scripts, local application state and persistent service data needed to rebuild the Pi-hole/DNS host.

The backup then applies this retention policy:

```text
7 daily snapshots
4 weekly snapshots
12 monthly snapshots
5 yearly snapshots
```

with pruning enabled after the retention decision.

The systemd timer runs daily at:

```text
02:00
```

and is configured with `Persistent=true`, so a missed run can be triggered after the host returns rather than being silently skipped forever.

## Backup flow

The DietPi flow is conceptually:

```text
02:00 systemd timer
      |
      v
restic-dietpi-backup.service
      |
      v
restic-backup-dietpi
      |
      +--> load protected /etc/restic/dietpi.env
      |
      +--> restic backup /etc /home /usr/local /var/lib
      |
      +--> retention
      |
      +--> prune
      v
Restic repository
```

A future host using Restic should follow the same general model: explicit include scope, protected credentials, scheduled execution, retention, monitoring and tested restoration.

## Rest Server health monitoring

`ids-01` runs a dedicated health script:

```text
scripts/restic-server-health.sh
```

The check tests four independent conditions:

1. the `restic-server` container is running;
2. Docker reports TCP port `8000` as published;
3. the host is listening on TCP port `8000`;
4. the HTTPS endpoint responds with an expected status.

The overall metric is healthy only when all four checks pass.

Prometheus textfile metrics include:

```text
homelab_restic_server_up
homelab_restic_server_container_up
homelab_restic_server_port_published
homelab_restic_server_port_listening
homelab_restic_server_https_reachable
homelab_restic_server_health_timestamp_seconds
```

This prevents a misleading situation where the container is running but the actual backup endpoint is not usable.

## Alerting

The repository contains Grafana alert deployment for two Restic conditions.

### Restic Server Down

The rule evaluates:

```promql
homelab_restic_server_up < bool 1
```

and alerts after the unhealthy state persists for approximately two minutes.

The alert is intended to catch failures in any of the container, port-publication, listener or HTTPS layers.

### Restic Health Check Stale

The health collector exposes its execution timestamp. Grafana checks whether that timestamp is more than five minutes old.

This distinguishes:

```text
backup server has failed
```

from:

```text
monitoring of the backup server has stopped
```

Both conditions matter because a stale green metric is not valid evidence of current backup availability.

## Credentials and secret recovery

Restic credentials are not stored in plaintext Git configuration.

The `ids-01` secret-recovery structure includes SOPS-encrypted sources for:

```text
restic-backup.sops.env
restic-server.sops.env
```

The documented purposes are:

- `restic-backup.sops.env` — Restic backup password material;
- `restic-server.sops.env` — Rest Server authentication material, including the protected password-file content.

DietPi also has encrypted recovery sources for its Restic repository and REST endpoint configuration.

The important separation is:

```text
Git stores encrypted recovery material
        |
        v
protected host credential files
        |
        v
Restic client / Rest Server
```

Decrypted credentials and age private identities must never be committed.

## Backup scope

A Restic backup should contain the information required to recover the service, not simply every file on the filesystem.

Good candidates include:

- service configuration;
- Docker bind-mounted application data;
- systemd/custom scripts not already recoverable from Git;
- locally generated application state;
- important databases where file-level backup is supported and consistent;
- certificates and keys where they are part of the protected recovery design;
- configuration needed to locate or authenticate to dependent services.

The backup design must avoid blindly copying transient caches, logs or data that is already reproducible unless there is a specific recovery requirement.

## Databases and consistency

Restic is a file backup tool. A file being present in a snapshot does not automatically mean an application database was captured in a crash-consistent or application-consistent state.

For databases and other stateful services:

- use the application's supported dump/snapshot mechanism where appropriate;
- stop or quiesce the service if required by its recovery model;
- back up the resulting consistent artifact;
- document the restore sequence;
- test the restored application, not just the extracted files.

This will be especially important as PostgreSQL/TimescaleDB workloads are introduced on Proxmox.

## Availability expectations

The Rest Server does not need the same real-time availability as DNS or a reverse proxy, but it must be available during scheduled backup windows and during recovery.

An outage can cause:

- scheduled backups to fail;
- the age of the newest snapshot to grow unnoticed;
- host recovery to be delayed;
- a false sense of protection if monitoring only checks the client timer.

Backup monitoring should therefore eventually cover both:

```text
server path is available
```

and:

```text
a sufficiently recent successful snapshot exists
```

The current server-health collector covers the first part. Snapshot-age/success monitoring should remain part of ongoing backup assurance where not already implemented per host.

## Operational checks

### Check the Rest Server health collector

```bash
sudo systemctl status restic-server-health.timer --no-pager
sudo systemctl status restic-server-health.service --no-pager
```

Check the generated metrics through the local Node Exporter textfile collector.

### Check the Rest Server endpoint

Use the configured CA certificate where available rather than disabling TLS validation:

```bash
curl --cacert /home/homelab-backup/rest-server/tls/rest-server.crt \
  -I https://192.168.2.242:8000/
```

A `401` or `403` response can be expected without repository credentials.

### Check DietPi schedule

```bash
systemctl status restic-dietpi-backup.timer --no-pager
systemctl list-timers --all --no-pager | grep -i restic
```

### Check snapshots

From an authorised Restic client with its protected repository configuration loaded:

```bash
restic snapshots
```

A repository should not be considered healthy solely because the timer last ran successfully. Confirm that a recent snapshot exists for the intended host/path set.

## Restore model

A restore should be treated as a controlled recovery operation.

Typical flow:

```text
identify required snapshot
        |
        v
confirm repository access
        |
        v
restore into safe staging location
        |
        v
inspect ownership / permissions / content
        |
        v
stop dependent service if required
        |
        v
place recovered data
        |
        v
start service
        |
        v
functional validation
```

Restoring directly over a running service without understanding its consistency requirements should be avoided.

## Recovery assurance

A backup strategy is not proven until restoration has been tested.

The homelab recovery model should therefore retain evidence that:

- repository credentials can be recovered;
- the repository can be opened;
- snapshots can be listed;
- representative files can be restored;
- file ownership and permissions are correct after restore;
- service-specific recovery procedures work;
- restored services pass functional checks;
- backup monitoring resumes after recovery.

The `ids-01` Service Continuity Plan already treats Restic repository access and credentials/certificate material as preconditions for full-host recovery.

## Security controls

1. Keep repository passwords out of plaintext Git.
2. Protect Rest Server authentication files and TLS key material.
3. Prefer certificate validation over `curl -k` except for controlled diagnosis.
4. Restrict the REST endpoint to networks/hosts that require backup access.
5. Treat backup repositories as sensitive because they may contain application data, configuration and secrets.
6. Keep SOPS/age recovery material separate from live decrypted credential files.
7. Do not print secrets into logs, alert annotations or backup scripts.
8. Use distinct credentials/identities where isolation materially improves recovery or compromise containment.

## Common failure modes

### Container running but endpoint unavailable

Check published port, host listener and HTTPS response. The current health script deliberately tests all of these layers.

### Backup timer succeeds but no recent snapshot exists

Inspect the actual backup command output, repository selection and snapshot list. Monitor snapshot age rather than relying only on systemd timer activity.

### Authentication failure

Confirm the correct protected Restic environment/password file and Rest Server authentication source are installed. Recover from the SOPS source if required rather than creating an undocumented replacement credential.

### TLS validation failure

Check the server certificate, client CA path, hostname/IP use and expiry. Do not permanently disable TLS validation to suppress the error.

### Repository lock or interrupted prune

Inspect the repository state before forcing lock removal. A stale lock should be confirmed as stale before using any unlock operation.

### Restore files have wrong ownership

Restore into a staging location, compare expected UID/GID/mode and correct ownership deliberately before starting the dependent service.

## Change rules

1. Keep backup scripts and retention policy in version control where practical.
2. Store secrets only in protected live files and encrypted recovery sources.
3. Monitor the server endpoint and the monitoring freshness independently.
4. Add snapshot-age/success checks for important clients.
5. Test restores after material backup-scope or application changes.
6. Document database-consistency requirements before relying on file-level backups.
7. Do not delete or prune snapshots outside the defined retention process without understanding the recovery impact.
8. Treat a successful backup as provisional until repository/snapshot evidence is verified.
9. Keep at least one recovery path that does not depend on the host being recovered.
10. Update Service Continuity documentation when repository location, credentials, certificates or protected path scope changes.

## Related documentation

- [Service Overviews index](README.md)
- [SOPS and age secret recovery](sops-and-age-secret-recovery.md)
- [ids-01 Service and Timer Inventory](ids-01-service-inventory.md)
- [Daily Security & Recovery Reporting](daily-security-and-recovery-reporting.md)
- [ids-01 Host Recovery SCP](../scp/SCP-Host-Recovery-ids-01.md)
- [Restic server health collector](../scripts/restic-server-health.sh)
- [Restic alert deployment](../scripts/deploy-restic-alerts.sh)
- [DietPi Restic backup script](../scripts/dietpi/restic-backup-dietpi)
- [DietPi Restic backup timer](../systemd/dietpi/restic-dietpi-backup.timer)
