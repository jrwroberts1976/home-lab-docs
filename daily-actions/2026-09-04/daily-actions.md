# 04 September 2026 — Daily Actions

## Starting position

The CT201 Zabbix platform build is complete through the application/database layer.

Validated starting state:

```text
CT201=zabbix-lxc-01
IP=192.168.2.184
frontend=http://192.168.2.184:8080/

zabbix_server=ACTIVE
zabbix_agent2=ACTIVE
zabbix_frontend=ACTIVE
nginx=ACTIVE
php_fpm=ACTIVE
postgresql_version=17
postgresql=HEALTHY
timescaledb_extension=ACTIVE
zabbix_timescaledb_schema=CONVERTED
vendor_hypertables=COMPLETE
alloy=HEALTHY
systemd=HEALTHY
failed_units=ZERO
ansible_idempotence=PASS
```

The locale issue is closed. Both `en_GB.UTF-8` and `en_US.UTF-8` are managed by Ansible and the server default remains UK English.

The only unfinished Zabbix configuration item is frontend/API IaC.

Desired Geomap authority already exists in Git:

```text
Dashboard: Global view
Host:      Zabbix server
Location:  BH22 8QL, West Parley, Dorset, UK
Latitude:  50.79039
Longitude: -1.890218
Zoom:      15
```

Current Admin/API diagnostic carried from 3 September:

```text
username=Admin
attempt_failed=4
attempt_ip=192.168.2.220
```

Do not guess the Admin password again.

## P0 — Morning report triage

When the daily/nightly report arrives:

- [ ] Review new failures, warnings, security findings, backup/patch issues and monitoring gaps.
- [ ] Deduplicate findings against this TODO.
- [ ] Record whether the report adds a new task, confirms an existing task or needs no action.
- [ ] Do not allow report triage to overwrite the current Zabbix closure priority unless a genuine P0 incident is found.

## P0 — Close Zabbix Admin/API credential authority

- [ ] Confirm current Zabbix frontend remains healthy before credential work.
- [ ] Recover or reset the `Admin` credential using a controlled documented method; do not rebuild CT201.
- [ ] Generate/establish a unique non-default Admin password.
- [ ] Store the credential only in encrypted CT201 Ansible Vault as the frontend/API secret.
- [ ] Ensure no plaintext Admin password remains in Git, shell history, temporary files or logs.
- [ ] Clear/verify failed-login state where required.
- [ ] Prove browser/API authentication with the new credential.
- [ ] Prove the factory/default credential is not retained as BAU authority.

## P0 — Apply BH22 8QL frontend IaC

After API authentication is green:

- [ ] Run `ansible/playbooks/zabbix-frontend-iac.yml`.
- [ ] Set/verify Zabbix server inventory location as `BH22 8QL, West Parley, Dorset, UK`.
- [ ] Set/verify latitude `50.79039`.
- [ ] Set/verify longitude `-1.890218`.
- [ ] Set/verify Geomap zoom `15`.
- [ ] Confirm `Global view` centres on BH22 8QL.
- [ ] Require first run `failed=0`, `unreachable=0`.
- [ ] Require second run `changed=0`, `failed=0`, `unreachable=0`.

## P0 — Final CT201 closure

- [ ] Verify all required services remain active.
- [ ] Verify frontend HTTP health from CT201 and TestServer.
- [ ] Verify PostgreSQL remains localhost-only.
- [ ] Verify TimescaleDB vendor hypertables remain complete.
- [ ] Verify Alloy remains healthy.
- [ ] Verify systemd state is `running` with zero failed units.
- [ ] Run final OpenTofu `plan -detailed-exitcode` from `containers/zabbix-lxc`.
- [ ] Require OpenTofu exit code `0`.
- [ ] Require repository working tree clean.
- [ ] Update final Zabbix/CT201 documentation with credential/Geomap closure.
- [ ] Merge `feature/zabbix-lxc-foundation` only after all final acceptance gates are green.
- [ ] Remove stale feature branch after successful merge where safe.

## P1 — Zabbix monitoring onboarding

Only after CT201 platform closure:

- [ ] Review which existing Linux hosts should be onboarded to Zabbix first.
- [ ] Prefer existing Ansible-managed Agent 2 deployment rather than manual installs.
- [ ] Avoid duplicating or disrupting the existing Prometheus/Alloy monitoring authority.
- [ ] Define the first host/template onboarding proof and acceptance criteria.

## P1 — Dozzle / Stage 6 durable closure

- [ ] Complete any remaining Dozzle `10.9.0` durable closure evidence.
- [ ] Continue Stage 6 BAU hardening where still genuinely outstanding.
- [ ] Preserve the rule that a healthy target is recreated only by the reviewed deployment stage.

## P2 — Existing monitoring backlog

- [ ] Finish Grafana Patch collector stale alert investigation.
- [ ] Reconcile Linux Host Down live/Git rule drift.
- [ ] Continue ids-01 single-Prometheus-authority work only after parity proof.
- [ ] Continue Pi-hole policy-alert latency improvement when selected.

## P3 — Provisioning platform

After Zabbix closure, continue the reusable provisioning-platform design:

- Proxmox, Azure and AWS provider support;
- reusable OpenTofu and Ansible components;
- web/operator request flow;
- identity/collision validation;
- stable generated MAC lifecycle;
- Vault/provider secret isolation;
- audit trail without secret leakage.

## Change-control rules

1. Do not guess the Zabbix Admin password.
2. Do not rebuild CT201 to solve an application credential problem.
3. Keep secrets in Vault and out of Git/logs.
4. Put persistent changes into Ansible/OpenTofu.
5. Require idempotence after frontend-IaC changes.
6. Preserve PostgreSQL localhost-only exposure.
7. Preserve the completed TimescaleDB conversion.
8. Require final OpenTofu zero drift before closing the feature branch.
9. Record only evidence-backed completion in this file.

## Daily summary

### Completed today

- None yet — planned start-of-day document.

### Carried forward

- Zabbix Admin/API credential recovery and Vault authority.
- BH22 8QL Geomap/frontend IaC.
- Final CT201 service/idempotence/OpenTofu closure and feature-branch merge.
- Remaining Dozzle/monitoring/provisioning backlog after the active Zabbix closure.
