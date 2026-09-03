# TODO — 04 September 2026

> **Day status: PLANNED.**
>
> Primary goal: finish CT201 Zabbix frontend/API IaC and close the Zabbix LXC feature branch.

## P0 — Zabbix Admin/API credential

- [ ] Do not make another password guess.
- [ ] Confirm frontend health at `http://192.168.2.184:8080/`.
- [ ] Recover/reset and rotate the `Admin` credential using a controlled method.
- [ ] Use a unique non-default password.
- [ ] Store the Admin/API password in encrypted CT201 Ansible Vault.
- [ ] Prove API authentication from TestServer.
- [ ] Verify failed-login state is cleared/normal.
- [ ] Verify the default/factory credential is not retained.

## P0 — BH22 8QL Geomap

Desired authority is already defined:

```text
Location:  BH22 8QL, West Parley, Dorset, UK
Latitude:  50.79039
Longitude: -1.890218
Zoom:      15
Dashboard: Global view
```

- [ ] Run Zabbix frontend IaC.
- [ ] Verify host inventory location.
- [ ] Verify Geomap default view.
- [ ] Require first run `failed=0`.
- [ ] Require second run `changed=0`.

## P0 — Final CT201 acceptance

- [ ] zabbix-server active.
- [ ] zabbix-agent2 active.
- [ ] nginx active.
- [ ] php8.4-fpm active.
- [ ] postgresql active.
- [ ] alloy active.
- [ ] systemd running.
- [ ] failed units zero.
- [ ] frontend HTTP healthy.
- [ ] PostgreSQL still localhost-only.
- [ ] TimescaleDB conversion/hypertables still complete.
- [ ] final Ansible idempotence proof.
- [ ] final OpenTofu zero-drift proof.
- [ ] repository clean.
- [ ] update final docs.
- [ ] merge and clean up `feature/zabbix-lxc-foundation`.

## P1 — After Zabbix closure

- [ ] Define first Zabbix host-onboarding batch.
- [ ] Decide which existing Linux systems should receive/validate Agent 2 first.
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

- [ ] Resume reusable Proxmox/Azure/AWS provisioning-platform design after Zabbix closure.

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
- [x] VM101 retirement/decommission.
