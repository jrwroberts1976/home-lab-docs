# SCP — Host Recovery Inventory and Rebuild

## Purpose

This SCP defines how to prepare for, execute and validate recovery of a homelab Linux host after complete host loss, storage failure, unrecoverable OS corruption or hardware replacement.

The approach is deliberately evidence-driven. A recovery inventory is captured from each healthy node and then converted into a host-specific SCP. The inventory records what must be reinstalled, restored and validated without copying secret contents into the documentation repository.

## Tooling

Two scripts are used:

```text
scripts/host-recovery-inventory.sh
scripts/host-recovery-scp-generate.sh
```

### Inventory script

`host-recovery-inventory.sh` captures the current rebuild requirements of a host, including:

- OS, kernel, architecture and boot configuration;
- filesystems, block devices, mounts and storage identifiers;
- manually installed and complete package inventories;
- APT repository configuration;
- users, groups and sudo configuration;
- network addressing, routes, DNS and listeners;
- firewall rules;
- enabled systemd units, custom units and timers;
- system and per-user cron jobs;
- Docker version, containers, images, networks, volumes and compose-file locations;
- k3s/Kubernetes state where present;
- monitoring and security tooling;
- custom scripts and Git repositories;
- backup/Restic configuration references;
- likely restore paths;
- secret, key and token file locations by path/permissions only.

The script deliberately does **not** copy secret values. Secret contents must remain in protected secret backup/storage.

The output is a timestamped directory and compressed archive:

```text
host-recovery-<hostname>-<timestamp>/
host-recovery-<hostname>-<timestamp>.tar.gz
```

A SHA-256 manifest is included for evidence integrity.

### SCP generator

`host-recovery-scp-generate.sh` consumes an inventory directory and creates a host-specific Markdown SCP. It derives a recovery checklist and records the captured platform, package/container counts, recovery order, restore evidence and validation requirements.

Example:

```bash
bash scripts/host-recovery-scp-generate.sh \
  /path/to/host-recovery-ids-01-20260822-080000
```

The generated document is written into the inventory directory as:

```text
SCP-Host-Recovery-ids-01.md
```

## Creating a recovery baseline

Run the inventory script on every important host while it is healthy. Run as root so system-wide configuration is visible:

```bash
cd ~/projects/home-lab-docs
git pull
sudo bash scripts/host-recovery-inventory.sh
```

Then generate the host-specific SCP from the reported inventory path:

```bash
bash scripts/host-recovery-scp-generate.sh \
  ./host-recovery-<host>-<timestamp>
```

Review the generated SCP. Confirm that the inventory contains the expected services, timers, compose stacks, backup configuration, network settings and secret locations.

## Recovery order

The standard recovery order is:

1. rebuild the base OS and patch it;
2. restore hostname, network, DNS and firewall configuration;
3. recreate users/groups and administrative access;
4. reinstall manually selected packages and required third-party repositories;
5. restore custom systemd units, timers and cron schedules;
6. install Docker/k3s where required;
7. restore persistent application data from Restic/other protected backup;
8. restore compose files, custom scripts and Git-backed configuration;
9. restore secrets from secure storage;
10. start application services in dependency order;
11. restore monitoring and security agents;
12. validate listeners, services, timers, containers, backups and alerts against the pre-failure inventory.

## Backup relationship

The recovery inventory is **not a substitute for backup**. It answers:

> What do I have to rebuild and where does it belong?

Restic/other protected storage answers:

> Where is the data required to restore that workload?

A host is considered recoverable only if both parts exist:

- current rebuild inventory/SCP;
- usable backup and secret material.

## Secret handling

The inventory records secret-bearing files by path, owner, mode and size only. It does not place passwords, tokens, private keys or `.env` contents in Git.

During recovery, use `secret-file-inventory.txt` as a checklist and restore the actual values from the secure secret backup.

## Recovery validation

A recovered node is not complete merely because it boots. Validate at minimum:

- hostname and addressing match the expected configuration;
- DNS and upstream connectivity work;
- required mounts are present;
- no unexplained failed systemd units exist;
- required timers and cron jobs are active;
- expected containers and services are running;
- listening ports match the old inventory;
- Restic repository access works and snapshots can be listed;
- monitoring targets return UP;
- Grafana alerts are healthy or understood;
- security tooling is active;
- service-specific smoke tests pass.

After recovery, run `host-recovery-inventory.sh` again and compare the old and new directories:

```bash
diff -ru old-host-recovery new-host-recovery
```

Expected differences include timestamps, ephemeral container IDs, package patch versions and runtime counters. Structural differences in networking, mounts, services, timers, compose files or listeners require investigation.

## Refresh frequency

Create a new inventory after material infrastructure/configuration changes, especially:

- new or removed Docker stacks;
- new timers/services/collectors;
- storage/mount changes;
- network changes;
- Pi-hole/monitoring architecture changes;
- backup changes;
- new application dependencies;
- host role changes.

A periodic refresh is also recommended even without major changes so that package/repository state does not drift too far from the documented recovery baseline.

## Current next step

Run the inventory on the main recovery targets and review the generated SCPs before treating the host-recovery design as complete. Recommended initial targets are the core infrastructure nodes: `ids-01`, `TestServer`, `DietPi` and `k3s-node-01`.
