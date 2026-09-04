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

## P0/P1 — Grafana ↔ Zabbix integration — COMPLETE

- [x] Create a dedicated read-only Zabbix role/group/user for Grafana.
- [x] Restrict the authenticated API allow-list to `*.get`.
- [x] Create/generate the datasource token without exposing it in output.
- [x] Capture token authority in SOPS-encrypted `docker-env/secrets/ids-01/grafana-zabbix.sops.env`.
- [x] Prove SOPS decrypt on TestServer and ids-01.
- [x] Install/provision `alexanderzobnin-zabbix-app` 6.6.0.
- [x] Provision Grafana datasource `Zabbix`, UID `zabbix`.
- [x] Preserve the existing token on rerun: `token_generated=NO`.
- [x] Correct the runtime Docker-secret ownership boundary for Grafana UID `472`.
- [x] Prove Grafana health after recreation.
- [x] Prove Grafana → Zabbix API access.
- [x] Prove `Infrastructure/Proxmox` group visibility.

Final proof:

```text
grafana_to_zabbix=PASS
proxmox_group_visibility=PASS
```

Scope boundary: the Grafana↔Zabbix integration is complete; Proxmox VE host enrollment into Zabbix remains backlog.

## Overnight alert follow-up — 04 September 2026

### P0 — PROXMOX hardware event — DIAGNOSED / WEEKEND ACTION PENDING

- [x] Investigate the PROXMOX hardware-fault alert that fired at approximately 04:00 BST and resolved at approximately 04:10 BST.
- [x] Review PROXMOX kernel journal, PCIe AER counters and SMART/NVMe health evidence.
- [x] Classify the event: recurring correctable PCIe physical-layer `RxErr` on the WDC PC SN520 NVMe link; 10 correctable events observed, with 0 non-fatal/fatal AER errors, 0 NVMe media errors and 0 NVMe error-log entries.
- [ ] **PENDING — weekend maintenance:** upgrade HP ProDesk 400 G4 DM BIOS Q23 from `02.07.00` (2019) to the current verified HP Q23 release after moving the host to the workshop and attaching a monitor/keyboard.
- [ ] Reboot after BIOS update and establish a fresh PCIe AER baseline.
- [ ] Monitor for recurrence; if `RxErr` continues, reseat the NVMe and inspect the M.2 connection before testing PCIe/NVMe power-management workarounds.
- [x] Adjust the live Grafana hardware alert classification: critical rule now excludes correctable PCIe AER events; new `Correctable PCIe error detected` rule uses `severity=warning`. Historical Loki preflight proved the 04 September PROXMOX `RxErr` no longer matches critical and does match warning; live API verification passed. Git authority validated with `tracked_rules=3`, `drifted_rules=0`, `applied_rules=0`, `git_live_parity=PASS`; merged via `docker-env` PR #39 (`489083be320d5427a1567c41a69403d8f28479d5`).

### P1 — Linux Host Down event — INCIDENT CLOSED / GIT AUTHORITY PENDING

- [x] Identify the affected target: DietPi / `192.168.2.48:9100`.
- [x] Prove the host itself remained online; Pi-hole metrics continued through the event and no matching kernel/network outage was found.
- [x] Identify the actual failure: one Prometheus scrape at 05:16:00 hit the 10-second timeout, produced `up=0` and scraped 0 samples; the next scrape at 05:16:15 succeeded.
- [x] Identify the alert-rule defect: `up{job="linux-hosts"} == 0` was evaluated over a 10-minute range with a 5-minute `for`, allowing a single failed scrape to remain true long enough to fire a false `Linux Host Down` alert.
- [x] Correct the live Grafana rule via API: `max_over_time(up{job="linux-hosts"}[5m]) == 0`, instant query, `for=0s`.
- [x] Update the Grafana annotations to include both `host` and `instance`.
- [x] Verify the saved rule and confirm current firing target set is empty.
- [x] Bring the live Grafana rule under Git authority to remove live/Git drift — validated `grafana_rule_drift=ZERO`, `git_live_parity=PASS`, `provenance=api`, `current_firing_targets=0`; merged via `docker-env` PR #38 (`a616e5bacce4f703729a37d145974b040926abe3`).

### P2 — ids-01 overnight CPU — DUPLICATE REMOVED / RE-BASELINE PENDING

- [x] Review the ids-01 high-CPU event around 02:21 BST and correlate it with scheduled overnight scans, backups, reports or maintenance.
- [x] Identify the dominant workload: Greenbone/OpenVAS `ospd-openvas` consumed roughly 4–7 CPU cores during the event and accounts for the host saturation.
- [x] Correlate Greenbone activity: two tasks named `Daily managed Linux hosts` started together at approximately 02:00 BST and completed at approximately 03:14 BST; OpenVAS CPU returned to effectively idle by approximately 03:20 BST.
- [x] Confirm the two task IDs are operational duplicates: same target, same 02:00 schedule, same OpenVAS scanner, same Full and fast config, and the same three managed Linux hosts.
- [x] Retain task `d8dd2c23-0f1a-469e-8004-08ac92fe811e` and move duplicate task `3af3f82d-7e6d-4f8c-a577-c3cb669a070a` to Greenbone trash. Post-cleanup validation: retained task healthy; duplicate present in trash; shared target and schedule still present; `greenbone_duplicate_cleanup=PASS`.
- [ ] Re-baseline the next overnight Greenbone run and confirm ids-01 CPU is materially reduced with one daily scan.

> k3s-node-01 security-update alert requires no task: it resolved by approximately 06:31 BST and the 04 September daily operations brief reports no outstanding security updates.

## P1 — Zabbix host onboarding

- [ ] Onboard the Proxmox VE host using the approved Zabbix Proxmox integration/template.
- [ ] Define the first monitored Linux-host batch.
- [ ] Decide which existing systems should receive/validate Agent 2 first.
- [ ] Validate host availability, item collection and initial triggers.
- [ ] Keep Zabbix complementary to existing Prometheus/Alloy observability.

## P1 — Dozzle / Stage 6

- [ ] Complete any genuinely outstanding Dozzle `10.9.0` durable closure.
- [ ] Continue Stage 6 BAU hardening.

## P2 — Monitoring backlog

- [ ] Update the ids-01 Grafana-Zabbix deployment helper so token materialisation automatically preserves owner UID `472` and mode `0400` before any future Grafana recreation.
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

- [x] Merge/close `proxmox/feature/zabbix-grafana-monitoring-iac`: merged via PR #21 to `main` (`ea9c849b73fd42b1dc678dc9ea8f0823dc8d3ae4`).
- [x] Merge/close `docker-env/feature/ids01-zabbix-grafana-monitoring`: merged via PR #37 to `main` (`e1cf9ff6ad0527d37dfafbf91f1733fcb894805e`).
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
- [x] dedicated Grafana Zabbix API identity and SOPS token authority.
- [x] Grafana Zabbix plugin 6.6.0 and datasource provisioning.
- [x] Grafana → Zabbix end-to-end API proof.
- [x] frontend IaC idempotence.
- [x] OpenTofu zero drift.
- [x] VM101 retirement/decommission.
