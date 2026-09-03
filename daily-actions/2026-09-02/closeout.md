# 02 September 2026 — Closeout

> **Day status: CLOSED.**
>
> 02 September finished with the VM101 application-platform rebuild proven end-to-end and the next Dozzle Stage 6 update prepared/reviewed but deliberately not deployed after fail-closed checks exposed stale target-side Stage 6 state. The unfinished items are carried into 03 September rather than remaining active against this date.

## Major outcome — VM101 application platform

The Proxmox VM101 application-platform work reached a full destructive end-to-end rebuild PASS.

Final VM identity:

```text
VMID:      101
Hostname:  zabbix-server-01
IP:        192.168.2.253
MAC:       BC:24:11:08:A2:33
Template:  9001 / debian-13-cloud-template-qga
OS:        Debian 13 trixie
```

The successful end-to-end path proved:

```text
OpenTofu backup/destroy/recreate
  -> QEMU Guest Agent identity
  -> guest IP discovery
  -> QGA-trusted ED25519 host-key verification
  -> strict SSH with the intended controller identity only
  -> Linux security hardening
  -> unattended-upgrades
  -> Grafana Alloy
  -> PostgreSQL 17
  -> TimescaleDB
  -> Nginx
  -> Zabbix Server
  -> Zabbix Agent 2
  -> live service/database/listener/frontend HTTP validation
  -> complete Ansible idempotence pass
  -> final OpenTofu zero-drift gate
  -> END-TO-END REBUILD PASS
```

Final rebuild evidence:

```text
===== END-TO-END REBUILD PASS =====
vmid=101
name=zabbix-server-01
ip=192.168.2.253
mac=BC:24:11:08:A2:33
state_backup=/home/james/tofu-state-backups/vm101-pre-e2e-20260902-075404.tfstate
vm_backup=/var/lib/vz/dump/vzdump-qemu-101-2026_09_02-07_56_51.vma.zst
log=/tmp/vm101-e2e-20260902-075404/run.log
```

## Automation defects found and corrected

### SSH host-key verification

Freshly rebuilt guests generate new SSH host keys. The E2E workflow now validates the network ED25519 key against the trusted key fingerprint read through QEMU Guest Agent before allowing SSH.

Duplicate `ssh-keyscan` output is reduced to unique fingerprints rather than treated as multiple independent host keys.

### SSH identity selection

The controller must use:

```text
-o IdentitiesOnly=yes
```

for direct SSH and Ansible so unrelated SSH-agent identities cannot interfere with the deterministic build path.

### Requested hostname identity gate

The E2E SSH identity gate was still hard-coded to expect `app-platform-01` even after VM101 was renamed to `zabbix-server-01`.

The gate was corrected to validate the requested runtime hostname instead of the historic fixed hostname.

## Ansible naming cleanup — carried forward

The guest itself is correctly named:

```text
zabbix-server-01
```

but Ansible play recaps still display the inventory alias:

```text
app-platform-01
```

Follow-up cleanup is required to rename the inventory alias to `zabbix-server-01` across all VM101 groups and documentation, followed by a full `changed=0`, `unreachable=0`, `failed=0` validation pass.

Tracked in `jrwroberts1976/proxmox#13`.

## Zabbix frontend PostgreSQL PHP support — carried forward

After the infrastructure and service E2E build passed, opening the Zabbix frontend at:

```text
http://192.168.2.253:8080/
```

reported:

```text
DB type "POSTGRESQL" is not supported by current setup. Possible values MYSQL.
```

This is an application/frontend acceptance defect, not a VM lifecycle failure.

Expected cause to validate: the PHP PostgreSQL module (`pgsql` / `pdo_pgsql`) is not installed or enabled for the PHP-FPM runtime. The fix must be represented in the Ansible `zabbix_server` role rather than applied as an undocumented manual guest change.

Acceptance after the fix:

- PostgreSQL is supported by the Zabbix frontend;
- PHP-FPM and Nginx remain healthy;
- frontend opens correctly;
- Zabbix Ansible rerun is `changed=0`;
- the one-button clean rebuild remains GREEN.

Tracked in:

```text
jrwroberts1976/proxmox#12
jrwroberts1976/home-lab-docs#56
```

## Evening Stage 6 container-update work

The generic Stage 6 service-update workflow was extended and exercised against the next Dozzle transition.

Completed/reviewed on 02 September:

- automatic preparation of a missing reviewed Stage 6 manifest was added while preserving the rule that a newly generated manifest cannot deploy in the same run;
- the generic manifest validator was extended to accept the exact immutable rollback identity required for chained updates;
- the manifest filename regex defect was fixed;
- Dozzle `10.9.0` metadata and exact immutable image identities were prepared and reviewed into `config/services/dozzle-10.9.0.json`;
- the Stage 6 framework baseline was re-anchored to the reviewed framework state rather than weakening the source-drift gate;
- Jenkins repeatedly failed closed before approval/deployment while stale target-side state was discovered;
- live Dozzle remained on the already-approved `10.8.0` image throughout the 02 September investigation.

Merged container-version-control PRs:

```text
#109 automatic Stage 6 manifest preparation
#110 manifest filename regex fix
#111 reviewed Dozzle 10.9.0 manifest
#112 reviewed Stage 6 framework re-anchor
```

The final 02 September blocker was target-side Stage 6 preparation drift: the installed transition manifest/validator state did not yet match the newly reviewed chained-update contract. No unsafe bypass was used and no Dozzle deployment was performed on 02 September.

## Follow-up project — productionize the provisioning solution

After the Zabbix frontend issue and inventory-name cleanup are closed, turn the proven host-specific workflow into a reusable provisioning platform.

Target capabilities:

- deploy VMs/workloads to Proxmox, Microsoft Azure and AWS;
- keep provider-specific OpenTofu implementation behind one consistent workflow;
- reuse common Ansible roles and service acceptance gates across providers;
- provide a web frontend where the operator can select provider/platform, hostname, server/application role and sizing/profile;
- validate hostname, VM/instance identity, IP/DHCP identity and other collisions before deployment;
- preserve Vault/provider secret handling and never expose secrets in the web UI or logs;
- preserve SSH trust, idempotence, service health and drift gates;
- record each requested deployment and its result for audit without recording secrets.

### Unique MAC requirement

For Proxmox, every new VM build should receive a newly generated locally administered MAC address rather than reusing the current fixed VM101 MAC. The generated MAC should become stable managed state for the lifetime of that VM instance. A later replacement/new instance receives a new MAC.

Azure and AWS network identity should remain provider-managed where their virtual networking model does not expose equivalent customer-controlled MAC lifecycle semantics.

Tracked in:

```text
jrwroberts1976/proxmox#11
jrwroberts1976/home-lab-docs#57
```

## Daily summary

### Completed today

- VM101 destructive OpenTofu rebuild and complete Ansible application-platform bootstrap passed end-to-end.
- Linux hardening, unattended upgrades, Alloy, PostgreSQL 17, TimescaleDB, Nginx, Zabbix Server and Zabbix Agent 2 were included in the reproducible build.
- Ansible idempotence and final OpenTofu zero drift passed.
- Rebuild SSH host-key trust, `IdentitiesOnly=yes`, and requested-hostname validation defects were corrected.
- Generic Stage 6 missing-manifest preparation and reviewed chained-update support were merged.
- Reviewed Dozzle 10.9.0 transition data was prepared without changing the live Dozzle 10.8.0 container.
- All observed Stage 6 failures remained pre-deployment and fail-closed.

### Carried forward to 03 September

- Complete the Dozzle 10.9.0 Stage 6 run from a clean synchronized target-side starting point, then close authority/catalogue/steady-state evidence.
- Update container-update documentation with the Dozzle 10.9.0 proof and the exact container-recreation boundary.
- Fix Zabbix frontend PostgreSQL PHP support in Ansible and re-prove idempotence/frontend acceptance.
- Rename the VM101 Ansible inventory alias from `app-platform-01` to `zabbix-server-01` and revalidate.
- Harden the generic Stage 6 BAU preparation path so target manifest/validator/candidate preparation does not require manual repair.
- Continue the wider provisioning-platform design only after the current Zabbix solution is fully closed.

02 September is closed. Unfinished work above is intentionally transferred to the 03 September task list.
