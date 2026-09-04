# 04 September 2026 — Daily Actions

## Starting position

CT201 entered the day with the Zabbix application/database stack already healthy. The remaining closure work was the frontend/API credential authority, BH22 8QL Geomap IaC, final idempotence and OpenTofu zero-drift proof.

## P0 — Zabbix Admin/API credential authority — COMPLETE

A unique Zabbix `Admin` credential is now stored only in the encrypted CT201 Ansible Vault.

The controlled bootstrap path proved:

```text
documented Admin recovery hash
  -> clear failed-login state
  -> API login using temporary recovery credential
  -> rotate Admin to unique Vault credential
  -> verify Vault credential
  -> create bootstrap marker
```

The factory/default credential is not retained as BAU authority.

Final evidence:

```text
Admin attempt_failed=0
admin-bootstrap-status=result=PASS mode=verify
admin-bootstrap-v1=PRESENT
marker_permissions=root:root 600
```

The frontend-IaC role owns its state under:

```text
/var/lib/homelab-zabbix-frontend-iac/
```

A failed assumption that `/var/lib/zabbix` existed was corrected in IaC. The Debian/Zabbix install on CT201 does not provide that directory.

## P0 — BH22 8QL frontend IaC — COMPLETE

Desired and applied authority:

```text
Dashboard: Global view
Host:      Zabbix server
Location:  BH22 8QL, West Parley, Dorset, UK
Latitude:  50.79039
Longitude: -1.890218
Zoom:      15
```

First successful application:

```text
zabbix-lxc-01 : ok=10 changed=5 unreachable=0 failed=0 skipped=0
```

Second-run idempotence proof:

```text
zabbix-lxc-01 : ok=7 changed=0 unreachable=0 failed=0 skipped=3
```

The frontend/Geomap authority is closed.

## P0 — Final CT201 closure — COMPLETE

Final OpenTofu drift proof:

```text
No changes. Your infrastructure matches the configuration.
tofu_exit_code=0
tofu_drift=ZERO
PASS: CT201 INFRASTRUCTURE AUTHORITY CLEAN
```

Final platform state remains:

```text
CT201=zabbix-lxc-01
IP=192.168.2.184
frontend=http://192.168.2.184:8080/

zabbix-server=active
zabbix-agent2=active
nginx=active
php8.4-fpm=active
postgresql=active
alloy=active
systemd=running
failed_units=ZERO
postgresql_scope=LOCALHOST_ONLY
timescaledb_extension=ACTIVE
zabbix_timescaledb_schema=CONVERTED
vendor_hypertables=COMPLETE
frontend_iac_changed=0
frontend_iac_failed=0
frontend_iac_unreachable=0
tofu_drift=ZERO
```

The CT201 Zabbix technical build is therefore **CLOSED**.

## Repository and documentation closure

Proxmox PR #20, **Close Zabbix LXC CT201 foundation**, was merged to `main`.

```text
PR:           #20
merge_commit: ca3998d39b0cf30d04c339e03fbd121df227bebd
state:        MERGED
```

Updated Proxmox authority includes:

- CT201 Zabbix LXC README final state;
- Zabbix installation runbook;
- Admin/Vault bootstrap and dedicated state directory;
- BH22 8QL Geomap authority;
- locale requirement;
- TimescaleDB conversion and rollback dump;
- Ansible idempotence evidence;
- OpenTofu zero-drift evidence.

## P1 — Zabbix monitoring onboarding

With the platform closed, the next Zabbix work is onboarding monitored systems:

- [ ] Define the first Linux-host onboarding batch.
- [ ] Prefer Ansible-managed Zabbix Agent 2 deployment rather than manual installs.
- [ ] Validate connectivity, item collection, availability and initial triggers.
- [ ] Keep Zabbix complementary to existing Prometheus/Alloy observability.

## P1 — Dozzle / Stage 6 durable closure

- [ ] Complete any genuinely outstanding Dozzle `10.9.0` durable closure.
- [ ] Continue Stage 6 BAU hardening where still outstanding.

## P2 — Existing monitoring backlog

- [ ] Finish Grafana Patch collector stale alert investigation.
- [ ] Reconcile Linux Host Down live/Git rule drift.
- [ ] Continue ids-01 single-Prometheus-authority work only after parity proof.
- [ ] Continue Pi-hole policy-alert latency improvement when selected.

## P3 — Provisioning platform

- [ ] Resume reusable Proxmox/Azure/AWS provisioning-platform design when selected.

## Daily summary

### Completed today

- Recovered the Zabbix Admin account without rebuilding CT201.
- Generated and stored a unique Admin/API credential in encrypted Ansible Vault.
- Proved Zabbix API authentication using the Vault-backed credential.
- Reset the failed-login state to zero.
- Reworked frontend-IaC state handling to use `/var/lib/homelab-zabbix-frontend-iac`.
- Applied the BH22 8QL host inventory and Global view Geomap.
- Proved frontend IaC idempotence with `changed=0`, `failed=0`, `unreachable=0`.
- Proved final OpenTofu zero drift with detailed-exitcode `0`.
- Closed the CT201 technical build.
- Updated the Proxmox Zabbix documentation for final closure.
- Merged Proxmox PR #20 to `main` at `ca3998d39b0cf30d04c339e03fbd121df227bebd`.
- Synchronized local `main` to the merge commit and deleted `feature/zabbix-lxc-foundation` locally and remotely.

### Carried forward

- First Zabbix monitored-host onboarding batch.
- Remaining Dozzle/Stage 6 BAU work.
- Existing monitoring backlog.
- Reusable provisioning-platform design.
