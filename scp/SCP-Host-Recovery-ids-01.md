# SCP — Recovery of ids-01

## Purpose

This Service Continuity Procedure (SCP) describes how to rebuild **ids-01** after complete host loss, storage failure, unrecoverable OS corruption, or replacement hardware deployment.

It was generated from the host recovery inventory bundle:

`host-recovery-ids-01-20260822-073601`

The inventory is evidence of the known-good host configuration. It is **not a backup**. Application data, databases, keys and secrets must be restored from Restic or other protected storage.

## Recovery objective

Restore the host to a state where:

- the operating system and network identity are correct;
- required packages and repositories are installed;
- custom systemd services, timers and cron jobs are restored;
- Docker/Kubernetes workloads are reconstructed where applicable;
- persistent data and secrets are restored from protected storage;
- monitoring/security agents are running;
- expected ports, services, timers, containers and alerts match the pre-failure inventory.

## Captured platform

- Host: **ids-01**
- Architecture: **GNU/Linux**
- OS evidence: **PRETTY_NAME="Debian GNU/Linux 13 (trixie)" NAME="Debian GNU/Linux" VERSION="13 (trixie)" **
- Installed packages recorded: **564**
- Manually selected packages recorded: **241**
- Docker/container rows recorded: **34**
- Compose files found: **13**
- Git repositories found: **5**
- Secret/key file locations inventoried: **71**

## Preconditions

Before starting recovery, obtain:

1. replacement hardware or repaired storage;
2. installation media for the same OS family and architecture;
3. this recovery inventory bundle;
4. Restic repository access and credentials/certificate material;
5. protected copies of secrets, SSH keys, API tokens and application credentials;
6. network information needed to restore the host IP, hostname and DNS behaviour;
7. access to Git repositories listed in `project-remotes.txt`.

## Recovery procedure

### 1. Rebuild the base operating system

Install the same OS family and architecture shown in:

- `os-release.txt`
- `uname.txt`
- `boot-files.txt`

Patch the system before restoring application workloads.

### 2. Restore host identity and network

Use these inventory files as the source of truth:

- `hostname.txt`
- `ip-address.txt`
- `ip-route.txt`
- `ip-rule.txt`
- `resolv.conf.txt`
- `network-config.txt`
- `nft-ruleset.txt` / `iptables-rules.txt` where present

Verify the recovered host can reach required DNS, gateways, peer nodes, backup endpoints and monitoring systems.

### 3. Recreate users and administrative access

Use:

- `passwd-summary.txt`
- `group-summary.txt`
- `sudoers-summary.txt`

Restore SSH keys from the secure secret backup, not from this inventory bundle.

### 4. Reinstall packages

Use `packages-manual.txt` as the primary reinstall list. Use `packages-installed.txt` for version/reference comparison after recovery.

Restore third-party APT repositories from `apt-sources.txt` before installing packages that depend on them.

### 5. Restore schedulers and custom services

Recreate custom service definitions and schedules using:

- `custom-systemd-units.txt`
- `systemd-enabled.txt`
- `systemd-timers.txt`
- `cron-system.txt`
- `cron-users.txt`

Do not enable application services until their persistent data and secrets are restored.

### 6. Restore Docker/container workloads

If Docker was present, use:

- `docker-version.txt`
- `docker-ps.txt`
- `docker-images.txt`
- `docker-container-config-summary.txt`
- `docker-compose-files.txt`
- `docker-networks.txt`
- `docker-volumes.txt`

Restore compose files and bind-mounted persistent data before starting stacks. Prefer the Git-backed compose definition where a repository exists rather than reconstructing containers manually from `docker inspect` output.

### 7. Restore Kubernetes/k3s workloads

If the inventory contains Kubernetes evidence, use:

- `k3s-version.txt`
- `kubernetes-summary.txt`
- `kubernetes-resources.txt`

Restore cluster-specific state according to the node's role. Do not blindly reapply generated resources that are owned by another controller or Helm release.

### 8. Restore persistent application data

Use `restore-paths.txt`, `backup-config-summary.txt` and `restic-repositories.txt` to identify what must be restored.

Restore application data **before** starting dependent services. For databases, use the supported restore mechanism where available rather than copying live database files into a running application.

### 9. Restore secrets

Use `secret-file-inventory.txt` as the checklist of expected secret locations. Restore the actual values only from the secure secret backup.

Confirm file ownership and permissions after restoring keys and credentials.

### 10. Restore scripts and Git-backed configuration

Use:

- `custom-scripts.txt`
- `project-repos.txt`
- `project-remotes.txt`

Clone Git repositories at the recorded locations, restore any non-Git local files from backup, and compare local modifications with the known-good inventory.

### 11. Re-enable monitoring and security

Use `monitoring-security-services.txt` to restore the node's monitoring/security role.

Verify, as applicable:

- node-exporter;
- Prometheus/Alloy/Promtail;
- Grafana dependencies;
- Suricata/CrowdSec/Greenbone;
- Pi-hole/Unbound/Nebula Sync;
- Restic health collectors;
- custom textfile collectors and timers.

### 12. Recovery validation

The recovery is not complete until all of the following have been checked:

- [ ] hostname and IP addressing match the inventory;
- [ ] DNS resolution works as expected;
- [ ] no unexpected failed systemd units;
- [ ] required timers and cron jobs are active;
- [ ] expected containers/services are running;
- [ ] expected listening ports match `listeners.txt`;
- [ ] backup access succeeds;
- [ ] latest backup can be enumerated;
- [ ] node-exporter/monitoring targets are UP;
- [ ] Grafana alerts are healthy or explainable;
- [ ] security tooling is active;
- [ ] application-specific smoke tests pass.

## Recovery evidence

After recovery, capture a fresh inventory and compare it to this one. Keep both inventories with the incident/change record.

Recommended comparison:

`diff -ru old-host-recovery-directory new-host-recovery-directory`

Expected differences include timestamps, ephemeral container IDs, package patch versions and runtime counters. Investigate structural differences in services, timers, compose files, network configuration, mount points, listeners or secret paths.

## Rollback / escalation

If recovery cannot be completed safely:

1. stop starting additional application services;
2. preserve the failed rebuild for evidence;
3. verify backup integrity and secret availability;
4. rebuild again from the last known-good base image/configuration;
5. restore only services whose dependencies and data are confirmed;
6. record any missing dependency in the recovery inventory/documentation before closing the incident.

## Source inventory files

The complete evidence bundle remains the authoritative technical source for this SCP. Verify its `MANIFEST.sha256` before relying on it during a recovery.
