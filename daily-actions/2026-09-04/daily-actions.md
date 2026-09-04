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

## P1 — Grafana ↔ Zabbix IaC integration — COMPLETE

The Grafana-to-Zabbix integration was completed after CT201 closure.

Final architecture:

```text
CT201 zabbix-lxc-01 (192.168.2.184)
        |
        | dedicated read-only Zabbix API token
        v
ids-01 Grafana 13.2.0
        |
        +-- alexanderzobnin-zabbix-app 6.6.0
        +-- provisioned datasource uid=zabbix
```

Zabbix IaC now owns:

```text
role:       Grafana API Read Only
user group: Grafana Read Only
user:       grafana-zabbix
token:      grafana-datasource
host group: Infrastructure/Proxmox
```

The authenticated role allow-list was corrected to `*.get` only after Zabbix 7.0.30 rejected `apiinfo.version` as an authenticated role method. The user-group frontend mode was also corrected for Grafana-Zabbix compatibility without exposing or retaining a usable service-user password.

Token authority is SOPS-encrypted in the `docker-env` ids-01 secret tree. Cross-host SOPS decrypt/encrypt was proven on TestServer and ids-01. The token was not regenerated after authority existed:

```text
authority_present=yes
result=PASS
token=PRESENT
token_generated=NO
plaintext_staging=PASS_ABSENT
```

Grafana runtime preparation installed the tracked plugin/datasource provisioning and protected runtime token. The first Grafana recreation exposed a Docker-secret permission boundary: the source file was `james:0600` while Grafana runs as UID `472`. Correcting the runtime source to UID `472`, mode `0400` restored normal startup.

Final Grafana evidence:

```text
Grafana version=13.2.0
database=ok
alexanderzobnin-zabbix-app=6.6.0
datasource name=Zabbix uid=zabbix
grafana_to_zabbix=PASS
proxmox_group_visibility=PASS
```

The unrelated disabled-dashboard empty-title warning remains outside this work item.

**Scope boundary:** the Grafana↔Zabbix integration is complete. The Proxmox VE host itself has not yet been enrolled into Zabbix; that remains onboarding backlog.

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
- Created the dedicated read-only `grafana-zabbix` API identity and token authority through Ansible IaC.
- Stored the Grafana Zabbix token only as SOPS-encrypted authority in `docker-env`.
- Installed/provisioned Grafana Zabbix plugin 6.6.0 and datasource `uid=zabbix` on ids-01.
- Corrected the Grafana runtime secret ownership boundary to UID 472 / mode 0400.
- Proved final Grafana → Zabbix API access and `Infrastructure/Proxmox` group visibility.
- Closed the CT201 technical build.
- Updated the Proxmox Zabbix documentation for final closure.
- Merged Proxmox PR #20 to `main` at `ca3998d39b0cf30d04c339e03fbd121df227bebd`.
- Synchronized local `main` to the merge commit and deleted `feature/zabbix-lxc-foundation` locally and remotely.

### Carried forward

- First Zabbix monitored-host onboarding batch, including Proxmox VE host enrollment.
- Reconcile the ids-01 deployment helper so future token materialisation preserves Grafana UID 472 / mode 0400 automatically.
- Remaining Dozzle/Stage 6 BAU work.
- Existing monitoring backlog.
- Reusable provisioning-platform design.
