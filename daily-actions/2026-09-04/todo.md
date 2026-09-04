# TODO — 04 September 2026

> **Day status: ACTIVE.**
>
> CT201 Zabbix platform closure is complete. Remaining work is post-closure onboarding/backlog only.

## P0 — Zabbix Admin/API credential — COMPLETE

- [x] Confirm frontend health.
- [x] Recover/reset and rotate the `Admin` credential using a controlled method.
- [x] Use a unique non-default password.
- [x] Store the Admin/API password in encrypted CT201 Ansible Vault.
- [x] Prove API authentication from TestServer.
- [x] Verify failed-login state is cleared.
- [x] Verify the default/factory credential is not retained.
- [x] Create a durable one-time bootstrap marker/state path.

## P0 — BH22 8QL Geomap — COMPLETE

Applied authority:

```text
Location:  BH22 8QL, West Parley, Dorset, UK
Latitude:  50.79039
Longitude: -1.890218
Zoom:      15
Dashboard: Global view
```

- [x] Run Zabbix frontend IaC.
- [x] Apply host inventory location.
- [x] Apply Geomap default view.
- [x] First run `failed=0`.
- [x] Second run `changed=0`.
- [x] Second run `failed=0`, `unreachable=0`.

## P0 — Final CT201 acceptance — COMPLETE

- [x] zabbix-server active.
- [x] zabbix-agent2 active.
- [x] nginx active.
- [x] php8.4-fpm active.
- [x] postgresql active.
- [x] alloy active.
- [x] systemd running.
- [x] failed units zero.
- [x] frontend HTTP healthy.
- [x] PostgreSQL remains localhost-only.
- [x] TimescaleDB conversion/hypertables remain complete.
- [x] final frontend-IaC idempotence proof.
- [x] final OpenTofu zero-drift proof.
- [x] update final Zabbix/CT201 documentation.
- [x] merge Proxmox PR #20 to `main`.
- [x] delete the merged `feature/zabbix-lxc-foundation` branch locally and remotely after synchronizing `main`.

Final proof:

```text
zabbix-lxc-01 : ok=7 changed=0 unreachable=0 failed=0 skipped=3
tofu_exit_code=0
tofu_drift=ZERO
merge_commit=ca3998d39b0cf30d04c339e03fbd121df227bebd
```

## Overnight alert follow-up — 04 September 2026

### P0 — PROXMOX hardware event

- [ ] Investigate the PROXMOX hardware-fault alert that fired at approximately 04:00 BST and resolved at approximately 04:10 BST.
- [ ] Review the Homelab Hardware Health dashboard plus PROXMOX kernel journal and SMART/NVMe health evidence.
- [ ] Determine whether the Loki-detected hardware-related event represents a genuine disk/kernel fault or alert noise.

### P1 — Linux Host Down event

- [ ] Identify which Linux node exporter was unreachable during the approximately 05:21–05:26 BST outage.
- [ ] Review the affected host/service logs around the outage and determine the cause.
- [ ] Update the Grafana `Linux Host Down` notification so it includes both `Host` and `Instance` labels.

### P2 — ids-01 overnight CPU

- [ ] Review the ids-01 high-CPU event around 02:21 BST and correlate it with scheduled overnight scans, backups, reports or maintenance.
- [ ] Confirm whether the >90% CPU condition was expected and transient; escalate only if unexplained or recurring.

> k3s-node-01 security-update alert requires no task: it resolved by approximately 06:31 BST and the 04 September daily operations brief reports no outstanding security updates.

## P1 — Zabbix host onboarding

- [ ] Define the first monitored Linux-host batch.
- [ ] Decide which existing systems should receive/validate Agent 2 first.
- [ ] Validate host availability, item collection and initial triggers.
- [ ] Keep Zabbix complementary to existing Prometheus/Alloy observability.

## P1 — Dozzle / Stage 6

- [ ] Complete any genuinely outstanding Dozzle `10.9.0` durable closure.
- [ ] Continue Stage 6 BAU hardening.

## P2 — Monitoring backlog

- [ ] Grafana Patch collector stale alert.
- [ ] Linux Host Down live/Git drift.
- [ ] ids-01 Prometheus authority parity work.
- [ ] Pi-hole policy-alert latency improvement.

## P2 — Solution and hosting review

- [ ] Review the full homelab solution set for better architectural or operational choices.
- [ ] Identify duplicated capabilities, overlapping tools and unnecessary complexity.
- [ ] Review whether current components should be retained, consolidated, replaced or removed.
- [ ] Review hosting placement for each major service: physical host, Proxmox VM/LXC, Docker, k3s, Raspberry Pi, or external/cloud hosting where appropriate.
- [ ] Compare current choices against simpler, more reliable, lower-maintenance or more supportable alternatives.
- [ ] Review observability architecture specifically, including Alloy, Prometheus, Loki, Grafana, Zabbix and exporters, and define clear ownership for metrics, logs, alerting and host monitoring.
- [ ] Produce a recommended target architecture and migration/backlog actions before making platform-wide changes.

## P1/P2 — Repository-wide unfinished-work reconciliation

Repository audit scope: all 34 repositories owned by `jrwroberts1976`, checking open PRs/issues, non-main branches and recent project activity.

### P1 — Unmerged / orphaned branch work

- [ ] Review `proxmox/feature/zabbix-grafana-monitoring-iac`: branch is 9 commits ahead of `main`; either validate and merge through the normal workflow or explicitly retire it.
- [ ] Review `docker-env/feature/ids01-zabbix-grafana-monitoring`: branch is 4 commits ahead of `main`; preserve/merge the Grafana-Zabbix secret authority work or explicitly retire it.
- [ ] Reconcile `proxmox/feature/vm101-monitoring-retirement` against current `main`; it still contains one unique divergent commit affecting `scripts/vm101-decommission.sh`.
- [ ] Reconcile `proxmox/fix/zabbix-php-postgresql-support` against current `main`; confirm its unique historical commits are fully superseded by the completed CT201/Zabbix authority before deletion.
- [ ] Verify and remove stale branches that are behind `main` with no commits ahead: `proxmox/feature/zabbix-geomap-bh22`, `proxmox/fix/zabbix-postgresql-php-authority`, `proxmox/promote/vm101-build-authority`, and `home-lab-docs/ops/automate-host-decommission-20260903`.

### P1 — Open issue reconciliation

- [ ] Close or update stale completed Zabbix issues after verifying main-branch evidence: `proxmox#18` (Admin password rotation) and `home-lab-docs#56` (PostgreSQL PHP support).
- [ ] Decide the disposition of `proxmox#13`: `ansible/inventories/vm101/hosts.yml` still uses `app-platform-01`, but VM101 is now retired. Either perform the naming cleanup for retained reusable VM101 IaC or close the issue as superseded by CT201.
- [ ] Reconcile the duplicate/related provisioning-platform trackers `proxmox#11` and `home-lab-docs#57` with the existing P3 provisioning-platform backlog item.

### P2 — Started/planned work missing from today's explicit backlog

- [ ] `home-lab-docs#61` — complete the controlled Smokeping container update preflight and decide whether to proceed with the update.
- [ ] `home-lab-docs#18` — document SOPS/age BAU operations, ownership, cadence, recovery validation and evidence requirements.
- [ ] `home-lab-docs#41` — continue Host Overview new-device discovery, targeted Nmap enrichment and persistent host-information database design.
- [ ] `home-lab-docs#42` — harden the Homelab Security Posture dashboard for expected-host/control coverage and telemetry freshness.
- [ ] Reconcile `home-lab-docs#9` with `homelab-container-version-control#1` and update the container-version-control project tracker to reflect the actual Stage 6 position, preserving any genuinely unfinished policy, secrets, validation, rollback, observability and closure work rather than tracking only Dozzle.

> Audit result: no open pull requests were found. All other repositories currently show only `main` (or are empty) and no open issue/branch signal requiring addition to today's homelab backlog.

## P3 — Provisioning platform

- [ ] Resume reusable Proxmox/Azure/AWS provisioning-platform design when selected.

## Already complete — do not reopen

- [x] CT201 LXC infrastructure.
- [x] Linux hardening.
- [x] unattended upgrades.
- [x] Alloy.
- [x] PostgreSQL 17.
- [x] TimescaleDB extension/preload.
- [x] Nginx.
- [x] Zabbix Server 7.0.
- [x] Zabbix Agent 2.
- [x] PHP frontend.
- [x] standard Zabbix schema.
- [x] Zabbix TimescaleDB conversion.
- [x] vendor hypertable verification.
- [x] Zabbix locale correction.
- [x] Vault-backed Admin/API credential.
- [x] BH22 8QL frontend/Geomap IaC.
- [x] frontend IaC idempotence.
- [x] OpenTofu zero drift.
- [x] VM101 retirement/decommission.
