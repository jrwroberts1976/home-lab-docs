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

The current repository state is ahead of the older tracker wording:

- generic `VERIFY_CLOSED` is already implemented and merged;
- Dozzle non-mutating closed-state verification is already proven;
- Dozzle 10.9.0 was deployed by Jenkins build #34 and its durable authority/catalogue/steady-state closure is complete;
- TestServer Alloy 1.19.2 already has a reviewed Stage 6 manifest.

The next active engineering checkpoint is therefore the remaining Jenkins BAU hardening:

1. move exact candidate acquisition into a dedicated restricted Jenkins SSH identity/forced-command path;
2. remove the free-text manifest-filename operator dependency by resolving reviewed service choices from Git-controlled estate data;
3. formalize/synchronize target-side Stage 6 manifest/validator/inspector authority and prove hashes before deployment inspection;
4. then use TestServer Alloy as the next fresh end-to-end Stage 6 service update.

The full deployment executor must remain unavailable until human approval and exact zero-drift reinspection.

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
- Replace free-text Stage 6 manifest selection with reviewed Git-controlled service discovery/selection.
- Formalize target-side Stage 6 framework synchronization/hash proof.
- Use TestServer Alloy 1.19.2 as the next fresh full Stage 6 update after those controls pass.
- Existing monitoring/security backlog remains separate from the Stage 6 workstream.
