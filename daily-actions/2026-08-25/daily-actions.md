# Daily Homelab Actions — 25 August 2026

Operational incident review and remediation completed from the Grafana alert inbox.

## Incident summary

**Overall status:** RESOLVED

Three alert conditions were reviewed:

1. `Backup Replica Failed` — false alert caused by a freshness threshold that no longer matched the intentional weekly replication schedule.
2. `CrowdSec Down` — genuine TestServer CrowdSec outage caused by mandatory Loki acquisition sources using an obsolete endpoint.
3. `Linux Host Down` — transient exporter outage that resolved automatically after approximately ten minutes.

At completion, the backup replica metric, TestServer CrowdSec engine, CrowdSec metrics endpoint and Prometheus scrape target were healthy. No other unresolved Grafana alert was found.

## Backup replica false alert

**Status:** FIXED

### Intended architecture

- `ids-01` creates a local Restic backup daily at 02:30.
- `ids-01` replicates its repositories off-host to `k3s-node-01` weekly on Sunday at 04:15.
- The weekly timer includes `Persistent=true` and up to five minutes of random delay.
- The replica destination is `homelab-backup@192.168.2.195`.
- The replica root is `/home/homelab-backup/replica/ids-01`.

### Detection

Grafana repeatedly fired the critical `Backup Replica Failed` alert. The destination remained reachable, SSH authentication succeeded, the replica directories existed with the expected ownership, and the last replication had completed successfully on 23 August 2026.

The live metric showed:

```text
homelab_backup_replica_health 0
homelab_backup_replica_age_seconds 183070
```

### Root cause

The off-host replication timer had intentionally been changed to weekly on 18 August, but `/usr/local/sbin/homelab-backup-metrics.sh` still declared the replica unhealthy after 172800 seconds, or 48 hours.

The metric therefore became unhealthy every Tuesday even though the next expected replication was Sunday.

### Remediation

The replica freshness threshold was changed to seven days plus two hours:

```bash
REPLICA_MAX_AGE_SECONDS=$((7 * 86400 + 2 * 3600))
```

The health check now uses:

```bash
[ "$replica_age" -lt "$REPLICA_MAX_AGE_SECONDS" ]
```

This permits the intentional weekly schedule and normal execution delay while detecting a missed Sunday replication approximately two hours after it becomes overdue.

The timer description was corrected from:

```text
Daily Homelab Backup Replication to k3s-node-01
```

to:

```text
Weekly Homelab Backup Replication to k3s-node-01
```

The schedule itself remained unchanged.

### Validation

- Metrics script syntax validation passed.
- Metrics service completed with `status=0/SUCCESS`.
- Replica health changed from `0` to `1`.
- The actual replica age continued to be exported.
- The destination, directory presence and repository-size checks remained enforced.
- Daily local-backup checks were not changed.

### Daily email update

`/usr/local/sbin/homelab-greenbone-email` was updated so the daily brief distinguishes the controls correctly:

- Daily backup evidence becomes overdue after 48 hours.
- Weekly off-host replication becomes overdue after seven days and two hours.
- The replica section explicitly identifies weekly replication to `k3s-node-01`.

Rollback copies were retained for the metrics and email scripts.

## TestServer CrowdSec outage

**Status:** FIXED

### Detection

Grafana fired `CrowdSec Down` because Prometheus could not resolve the configured target:

```text
crowdsec:6060
dial tcp: lookup crowdsec on 127.0.0.11:53: no such host
```

The separate `crowdsec-firewall` exporter remained up, but the TestServer `crowdsec` container had exited with code 1.

The independent CrowdSec service on `ids-01` remained healthy and was not the failed target.

### Root cause

The TestServer CrowdSec container had three mandatory Loki acquisition sources:

```text
ids-01-ssh.yaml
ids-01-greenbone.yaml
ids-01-nginx.yaml
```

All three used the obsolete Loki URL:

```text
http://192.168.2.242:3100
```

CrowdSec could not reach that address and terminated with:

```text
unable to start crowdsec routines: starting acquisition error:
loki is not ready: context deadline exceeded
```

Central Loki was running on TestServer and shared the `homelab_apps` Docker network with CrowdSec under the DNS name `loki`.

### Remediation

The three CrowdSec acquisition files were backed up and their Loki URLs changed to:

```text
http://loki:3100
```

Their existing Loki queries and labels were preserved.

The CrowdSec Compose configuration validated successfully and the existing container was started without deleting or replacing its persisted configuration or database.

### Validation

- CrowdSec container state: running.
- Restart count: `0`.
- Exit code: `0`.
- No fatal, Loki, route, timeout or acquisition errors after startup.
- `http://192.168.2.220:6060/metrics` returned live CrowdSec metrics.
- Prometheus reported `crowdsec:6060 up`.
- Firewall exporter remained healthy.
- Persistent acquisition-file backups were retained under `before-loki-dns-fix`.

### Daily email update

The daily email generator now reports service health separately from activity totals:

- TestServer CrowdSec engine health uses `up{job="crowdsec",host="main"}`.
- Firewall enforcement-metrics health uses `min(up{job="crowdsec-firewall"})`.
- Existing 24-hour decision, blocked-source and blocked-packet totals remain unchanged.
- Both new live health queries returned `1` during validation.

This prevents a healthy exporter or historical activity total from masking a stopped CrowdSec engine.

## Transient Linux host outage

**Status:** RESOLVED AUTOMATICALLY

Grafana fired `Linux Host Down` at 05:21 BST because a Linux node-exporter target had been unreachable for more than five minutes. It resolved at 05:31 BST.

The timing overlaps the network instability observed during the CrowdSec/Loki investigation. No continuing Linux-host outage remained after recovery.

## Final state

- [x] Weekly backup replica health metric corrected and healthy.
- [x] Weekly replication timer description corrected.
- [x] Daily email updated with correct backup freshness semantics.
- [x] TestServer CrowdSec restored.
- [x] CrowdSec Loki acquisitions moved to stable Docker DNS.
- [x] CrowdSec metrics endpoint verified.
- [x] Prometheus CrowdSec target verified up.
- [x] Daily email updated with explicit CrowdSec engine and firewall health.
- [x] Transient Linux host alert confirmed resolved.
- [x] No additional unresolved Grafana alerts found.

## Rollback evidence

Rollback copies retained during the work include:

```text
/usr/local/sbin/homelab-backup-metrics.sh.before-weekly-replica-threshold
/etc/systemd/system/homelab-replication-k3s.timer.before-description-fix
/usr/local/sbin/homelab-greenbone-email.before-weekly-replica-wording
/usr/local/sbin/homelab-greenbone-email.before-crowdsec-health
/home/james/docker/data/security/crowdsec/config/acquis.d/before-loki-dns-fix/
```


## K3s datastore encryption at rest

**Status:** COMPLETED

K3s datastore encryption was enabled and closed under controlled recovery, rotation and health gates on `k3s-node-01`.

### Recovery preparation

- Confirmed the single-server K3s v1.36.2+k3s1 cluster used the embedded SQLite datastore.
- Verified non-root users could not traverse the root-only datastore directories.
- Confirmed the daily backup uses SQLite `.backup` and that the staged database passed `PRAGMA quick_check`.
- Created root-only pre-encryption and pre-rotation recovery points containing a consistent database backup and the required recovery material.
- Verified recovery-file checksums before advancing the encryption state.

### Encryption transition

- Added the persistent K3s server flag `--secrets-encryption`.
- Enabled AES-CBC datastore encryption.
- Resolved the intermediate `prepare` stage by following the staged K3s workflow rather than repeating the consolidated `rotate-keys` command.
- Completed `rotate`, controlled restart, `reencrypt`, and final controlled restart.
- K3s emitted `SecretsUpdateComplete` after re-encrypting 14 Secret objects.

### Final validation

- Encryption status: `Enabled`.
- Rotation stage: `reencrypt_finished`.
- Server encryption hashes: all match.
- Secret API: all 14 Secret objects readable.
- Node: `Ready`.
- Unexpected pod states: `0`.
- SQLite quick check: `ok`.
- K3s service: active and running with successful status.

The startup 503 and readiness messages observed during controlled restarts cleared as the API server became ready. No workload declaration or Secret value was manually changed.

### Source-control closure

The persistent installation argument, security guidance, operations procedure, progress record and project timeline were merged into `kubernetes-homelab/main` at revision `dd8cb32`. The merged working branch was deleted after verification.

Recovery-sensitive database, token and encryption-configuration material remains root-restricted and excluded from Git. SOPS + age for Git-managed Kubernetes secret declarations remains a future Stage 2 activity.

## DietPi SOPS and age secrets foundation

DietPi began the Stage 2 SOPS and age pilot on 25 August 2026.

- Installed Debian `age` 1.2.1 and checksum-verified SOPS 3.13.3 for ARM64.
- Created separate DietPi operational and protected recovery age identities without displaying private key material.
- Verified that both identities independently decrypt a two-recipient test payload.
- Created encrypted sources for the Pi-hole alert email environment, Restic REST credentials and Restic repository password.
- Confirmed both identities decrypt all three sources to matching protected working copies.
- Confirmed no private identity or plaintext credential is present in the repository candidate.
- Left all live credentials, Pi-hole databases, services and configuration unchanged.

The recovery identity under `/mnt/backup/recovery/sops-age/` remains the protected online copy. A passphrase-encrypted detached copy and independent TestServer recovery rehearsal are now validated.

## K3s SOPS and age foundation

The Stage 2 SOPS and age foundation for `k3s-node-01` was completed on 25 August 2026.

### Implementation

- Installed Debian `age` 1.1.1 and checksum-verified SOPS 3.13.3 for ARM64.
- Created a K3s-specific operational age identity outside Git.
- Reused only the shared public recovery recipient; the private recovery identity remained on protected DietPi backup storage.
- Added a narrow `.sops.yaml` policy and encrypted non-deployable recovery-test artifact.
- Confirmed that no application-managed Kubernetes credential currently requires migration.
- Explicitly excluded K3s-generated, Kubernetes-generated, Helm-managed and MetalLB-managed Secrets from Git.

### Validation

- The K3s operational identity decrypted the two-recipient artifact successfully.
- The protected recovery identity independently decrypted the same artifact to matching content.
- The merged artifact contains no Kubernetes `apiVersion` or deployable `Secret` kind.
- No private age identity or plaintext credential was committed.
- The K3s node remained Ready with zero unexpected pod states.
- Datastore encryption remained enabled at `reencrypt_finished` with matching server hashes.

### Source-control closure

- `kubernetes-homelab` implementation commit: `000df3a`.
- `kubernetes-homelab/main` merge commit: `cef4980`.
- The feature branch was deleted locally and remotely; `main` is the only remote branch.

### Remaining control

The recovery identity now has protected online and passphrase-encrypted detached copies. The detached copy passed an independent TestServer recovery rehearsal.

## TestServer SOPS and age foundation

The Stage 2 SOPS and age foundation for `TestServer` was completed on 25 August 2026.

### Secret inventory

- Added encrypted recovery sources for Cloudflare DDNS, DuckDNS, AutoKuma, Nginx Proxy Manager deployment automation and archived contact credentials.
- Recorded every active, non-secret, archived and retired variable in `docker-env/secrets/testserver/README.md`.
- Confirmed that LibreSpeed `PASSWORD` is an unused image default rather than an operator-managed credential.

### Identity and recovery validation

- Installed Debian `age` 1.2.1 and checksum-verified SOPS 3.13.3 for ARM64.
- Created a TestServer-specific operational age identity outside Git.
- Used the shared public recovery recipient while keeping the private recovery identity on protected DietPi backup storage.
- Verified all five encrypted sources independently with both approved identities.
- Confirmed that no private identity or plaintext credential was committed.

### Plaintext retirement

- Removed unused CrowdSec, retired Watchtower and retired TestServer Grafana `.env` files.
- Removed the archived plaintext contact file after encrypted recovery validation.
- Removed an obsolete DuckDNS environment-file duplicate after confirming it matched the active Compose secret.
- Kept active Cloudflare DDNS, DuckDNS and AutoKuma file-backed Compose secrets unchanged.
- Kept the protected Nginx Proxy Manager host file because deployment and maintenance scripts consume it directly.

### Runtime validation

- All affected Compose projects validated after plaintext retirement.
- Every running container retained the same container ID.
- No container or service was recreated, restarted or changed.

### Source-control closure

- Initial encrypted-source commit: `8dec2bd`; merge: `4e5190f`.
- Contact recovery-source commit: `c46ae02`; merge: `fd2c0e8`.
- Variable-register closure commit: `3d2e4b8`; final `docker-env/main`: `e152e15`.
- All temporary TestServer branches were deleted locally and remotely.

### Remaining control

The shared recovery identity now has a validated passphrase-encrypted offline copy. An independent recovery rehearsal completed successfully on TestServer.

## ids-01 SOPS and protected credential delivery

The Stage 2 SOPS and age foundation for `ids-01` was completed on 25 August 2026.

### SOPS foundation

- Installed Debian `age` 1.2.1 and checksum-verified SOPS 3.13.3 for AMD64.
- Created a host-specific operational age identity outside Git.
- Reused only the shared public recovery recipient held by DietPi.
- Added ten SOPS-encrypted recovery sources for Docker, systemd, Pi-hole, Greenbone, OpenAI and Restic credentials.
- Verified all ten encrypted sources independently with the ids-01 and protected recovery identities.
- Kept all private identities and plaintext credential values outside Git.

### Secondary Pi-hole migration

- Created a protected file for the secondary Pi-hole web/API password with mode `0400`.
- Replaced direct Compose environment delivery with a read-only Compose secret.
- Added an entrypoint wrapper that reads the secret before executing Pi-hole `start.sh`.
- Recreated only `pihole-secondary`; its sibling Unbound container was unchanged.
- Confirmed healthy runtime state, DNS resolution and authenticated API access.
- Removed `PIHOLE_PASSWORD` from the live stack `.env` file.
- Recorded the non-secret Compose desired state and recovery procedure in Git.

### Grafana API token closure

- Identified the valid Grafana API token and repaired the stale protected token file.
- Confirmed the protected token authenticates successfully with HTTP 200.
- Updated four Grafana automation scripts to use `GRAFANA_TOKEN_FILE` by default while retaining explicit environment override support.
- Removed the obsolete token declaration from the monitoring `.env` file.
- Permanently removed two obsolete plaintext token backups after validating SOPS recovery.
- Confirmed Grafana remained running without recreation or restart.
- Stored non-secret recovery copies of the four token consumers in Git.

### Source-control closure

- SOPS implementation commit: `b2aab9d`; merge commit: `43cf236`.
- Pi-hole Compose-secret implementation commit: `7939e18`; merge commit: `ea491f0`.
- Grafana token-consumer implementation commit: `773694b`; merge commit: `9372d66`.
- All associated feature branches were removed after their merge commits reached `main`.

### Remaining recovery control

The recovery age identity now has a validated passphrase-encrypted offline copy, and the independent TestServer recovery rehearsal passed.

## SOPS and age service overview

- Created the consolidated SOPS and age service overview.
- Recorded the four-host architecture, credential boundaries, live-delivery patterns and recovery workflow.
- Recorded the detached offline recovery package and successful independent recovery rehearsal as completed Stage 2 controls.

## Detached offline SOPS recovery rehearsal

The Stage 2 detached recovery control was completed on 25 August 2026.

### Offline package creation

- Used removable media with UUID `43FA-9542`.
- Preserved and revalidated the three existing host-secret archives.
- Stored the private recovery identity only in passphrase-encrypted form.
- Stored the public recipient, recovery instructions and a SHA-256 package manifest.
- Discarded an initial temporary encryption attempt before any media write because its autogenerated passphrase was displayed.
- Recreated and validated the accepted package using private terminal passphrase input.
- Verified the USB copy byte-for-byte against the protected construction source.
- Removed the temporary construction package and cleanly unmounted the USB.

### Independent TestServer rehearsal

- Confirmed that no recovery private identity was already installed on TestServer.
- Mounted the USB read-only and validated the recovery-package checksums.
- Copied only the encrypted package into protected memory and unmounted the USB.
- Decrypted the recovery identity using the separately retained passphrase.
- Confirmed that the recovered identity derived the approved public recipient.
- Used an isolated `HOME` and explicit `SOPS_AGE_KEY_FILE` to prevent use of the TestServer operational identity.
- Decrypted all five TestServer SOPS sources using only the offline recovery identity.
- Matched the four active recovered sources exactly against their protected live files.
- Validated the archived contact source variable structure.
- Removed all temporary private identity and plaintext credential material.
- Confirmed that all 30 running containers remained untouched.
- Physically detached the USB after the rehearsal.

### Final control state

The shared recovery identity now has protected online and detached offline copies. The offline copy and independent recovery workflow are validated. The passphrase is retained separately from the USB.

## Complete multi-repository SOPS documentation

- Updated DietPi, ids-01, TestServer and Kubernetes recovery status references to reflect the completed detached-media control.
- Added the canonical SOPS and age creation, validation, restoration, rotation and recovery how-to.
- Added operational safety gates, rollback handling, source-control requirements and an evidence checklist.
- Began alignment of the `home-lab-docs`, `kubernetes-homelab` and `docker-env` documentation sets.
