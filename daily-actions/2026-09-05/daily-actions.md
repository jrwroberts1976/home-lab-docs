# 05 September 2026 — Daily Actions

## Starting position

The session began with recovery and storage work on `media-01`, followed by reconciliation of the Zabbix backlog against the live environment.

## Media-01 backup replica recovery and NVMe cleanup — COMPLETE

The former k3s NVMe remains mounted as the backup storage device and the live backup replica is bound into:

```text
/home/homelab-backup/replica
```

Validated recovery state:

- Restic source repository integrity check passed on `ids-01`;
- catch-up replication to `media-01` completed successfully;
- post-sync dry-run comparison reported zero created, deleted or transferred files;
- weekly replication timer was re-enabled;
- the replica remained readable and writable on the NVMe-backed mount.

Old inactive runtime/cache data was then removed from the retired k3s root without touching backup data, Docker volumes, MySQL/Zabbix data, Rancher, ntopng or `/home/james`.

Final NVMe space after the safe cleanup:

```text
/dev/nvme0n1p2  469G  240G  206G  54%
```

## Zabbix Linux-host onboarding reconciliation — COMPLETE

The live environment proved that the first Linux Agent 2 batch was already deployed and collecting, so no new agent installation or host recreation was performed.

Validated hosts:

```text
PROXMOX      hostid 10683
ids-01       hostid 10684
TestServer   hostid 10685
DietPi       hostid 10686
media-01     hostid 10687
```

For `ids-01`, `TestServer`, `DietPi` and `media-01`:

- Zabbix Agent 2 listener on TCP/10050 is reachable;
- the Zabbix agent interface reports available;
- current items are being collected;
- inherited/template-derived items are present;
- the only enabled unsupported items are non-critical network-interface speed reads on Wi-Fi/USB-style interfaces where Linux returns `EINVAL` for the sysfs speed file.

No broad new Zabbix alerting or duplicate Prometheus/Alloy monitoring was introduced.

## Zabbix backlog and documentation closure — COMPLETE

The Zabbix service overview, Proxmox README, Grafana/Zabbix integration documentation and operational TODO were reconciled to the live state.

Closed stale issues:

- `proxmox#18` — completed: Admin/Vault credential objective;
- `home-lab-docs#56` — completed: PostgreSQL PHP support;
- `proxmox#13` — closed not planned/superseded because VM101 is retired and CT201 is the active Zabbix platform.

The future provisioning-platform trackers remain open, but their obsolete Zabbix dependency wording was removed.

Zabbix is now treated as **BAU/maintenance**, not an active platform-build project.

## Next engineering work — Container Version Control Stage 6

The next active engineering checkpoint is the Jenkins Stage 6 security/BAU path.

Required order from the current project authority:

```text
restricted candidate acquisition
        |
        v
Dozzle VERIFY_CLOSED proof
        |
        v
fresh TestServer Alloy end-to-end SUCCESS_CLOSED proof
```

The first task is therefore to implement and validate the dedicated restricted Jenkins candidate-acquisition SSH identity/forced-command path before any fresh Alloy candidate acquisition or deployment.

## Daily summary

### Completed today

- Recovered and revalidated the Media-01 backup replica path.
- Completed successful catch-up replication and post-sync equality checks.
- Removed retired runtime/cache data from the old NVMe and increased free space to 206 GB.
- Proved the existing Zabbix Linux-host batch is already live and collecting.
- Closed stale Zabbix backlog/issues and updated current documentation.
- Reclassified Zabbix as BAU/maintenance.

### Carried forward

- Container Version Control Stage 6: implement the restricted Jenkins candidate-acquisition path.
- Add the non-mutating Dozzle `VERIFY_CLOSED` proof after the restricted acquisition route is ready.
- Use TestServer Alloy as the first fresh full Stage 6 `SUCCESS_CLOSED` proof after those controls pass.
- Existing monitoring/security backlog remains separate from the Stage 6 workstream.
