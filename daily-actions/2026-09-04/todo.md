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
- [ ] delete the merged `feature/zabbix-lxc-foundation` branch after synchronizing the local checkout.

Final proof:

```text
zabbix-lxc-01 : ok=7 changed=0 unreachable=0 failed=0 skipped=3
tofu_exit_code=0
tofu_drift=ZERO
merge_commit=ca3998d39b0cf30d04c339e03fbd121df227bebd
```

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
