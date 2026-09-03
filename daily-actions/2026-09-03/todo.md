# TODO — 03 September 2026

> **Day status: CLOSED.**
>
> The CT201 Zabbix platform build is complete through TimescaleDB conversion and locale correction. Only frontend/API credential closure and the BH22 8QL Geomap are carried to 04 September.

## Completed today — Zabbix CT201

- [x] Provision and commission unprivileged Debian 13 LXC CT201.
- [x] Validate nesting, systemd health and OpenTofu ownership.
- [x] Apply Linux security hardening.
- [x] Apply unattended upgrades.
- [x] Deploy Alloy and prove Prometheus/Loki ingestion.
- [x] Deploy PostgreSQL 17.
- [x] Create Zabbix database/user under Ansible authority.
- [x] Keep PostgreSQL listening on localhost only.
- [x] Install and preload TimescaleDB.
- [x] Enable TimescaleDB extension in the Zabbix database.
- [x] Deploy Nginx baseline.
- [x] Deploy Zabbix Server 7.0 LTS.
- [x] Deploy Zabbix Agent 2.
- [x] Deploy PHP 8.4 FPM frontend.
- [x] Import the standard Zabbix PostgreSQL schema.
- [x] Take pre-conversion database backup.
- [x] Convert Zabbix history/trend tables using the packaged TimescaleDB schema.
- [x] Verify all vendor-declared hypertables.
- [x] Verify Zabbix database is marked as TimescaleDB-backed.
- [x] Fix Zabbix locale support in Ansible.
- [x] Generate both `en_GB.UTF-8` and `en_US.UTF-8`.
- [x] Keep UK English as the system default.
- [x] Prove Zabbix/Nginx/PHP/PostgreSQL/Alloy/systemd health.
- [x] Prove relevant Ansible playbooks are idempotent with `changed=0`.
- [x] Update CT201 README and Zabbix installation runbook.

## Deferred to 04 September — Zabbix frontend IaC

- [ ] Recover/rotate the Zabbix `Admin` credential without further password guessing.
- [ ] Store the unique Admin credential in CT201 Ansible Vault.
- [ ] Prove Zabbix API login from TestServer.
- [ ] Apply the existing BH22 8QL Geomap/frontend IaC.
- [ ] Require frontend-IaC second pass `changed=0`.
- [ ] Run final service/frontend/database acceptance.
- [ ] Run final OpenTofu zero-drift proof.
- [ ] Merge/close `feature/zabbix-lxc-foundation` when final gates pass.

Current API-auth diagnostic:

```text
username=Admin
attempt_failed=4
attempt_ip=192.168.2.220
```

Do not continue guessing the Admin password.

## Other carried-forward work

### Dozzle Stage 6 durable closure / BAU hardening

- [ ] Complete any remaining durable Dozzle `10.9.0` closure evidence.
- [ ] Continue generic Stage 6 preparation/hardening work where still outstanding.

### Monitoring backlog

- [ ] Finish Grafana Patch collector stale alert investigation.
- [ ] Reconcile Linux Host Down live/Git rule drift.
- [ ] Continue ids-01 single-Prometheus-authority work only after parity proof.
- [ ] Continue Pi-hole policy-alert latency improvement when selected.

### Provisioning platform

- [ ] Continue reusable Proxmox/Azure/AWS provisioning-platform design after Zabbix closure.

## Do not reopen

- [x] VM101 Zabbix workstream — retired/decommissioned.
- [x] CT201 PostgreSQL/TimescaleDB construction.
- [x] CT201 Nginx/Zabbix/PHP deployment.
- [x] CT201 locale correction.
