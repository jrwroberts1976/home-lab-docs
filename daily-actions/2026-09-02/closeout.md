# 02 September 2026 — Closeout

## Major outcome

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

## Ansible naming cleanup

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

## OPEN — Zabbix frontend PostgreSQL PHP support

After the infrastructure and service E2E build passed, opening the Zabbix frontend at:

```text
http://192.168.2.253:8080/
```

reported:

```text
DB type "POSTGRESQL" is not supported by current setup. Possible values MYSQL.
```

This is an application/frontend acceptance defect, not a VM lifecycle failure.

Expected cause to validate this evening: the PHP PostgreSQL module (`pgsql` / `pdo_pgsql`) is not installed or enabled for the PHP-FPM runtime.

Next diagnostic:

```bash
ssh james@192.168.2.253 '
php -m | grep -Ei "pgsql|mysqli|pdo"
dpkg -l | grep -E "php.*pgsql" || true
php-fpm8.4 -v 2>/dev/null || php -v
'
```

If confirmed, fix the Ansible `zabbix_server` role rather than installing the package manually. The expected Debian 13 package is `php8.4-pgsql`.

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

## Follow-up project — productionize the provisioning solution

After the current Zabbix frontend issue and inventory-name cleanup are closed, turn the proven host-specific workflow into a reusable provisioning platform.

Target capabilities:

- deploy VMs/workloads to Proxmox, Microsoft Azure and AWS;
- keep provider-specific OpenTofu implementation behind one consistent workflow;
- reuse common Ansible roles and service acceptance gates across providers;
- provide a web frontend where the operator can select:
  - provider/platform;
  - hostname;
  - server/application role;
  - sizing/profile where appropriate;
- validate hostname, VM/instance identity, IP/DHCP identity and other collisions before deployment;
- preserve Vault/provider secret handling and never expose secrets in the web UI or logs;
- preserve SSH trust, idempotence, service health and drift gates;
- record each requested deployment and its result for audit without recording secrets.

### Unique MAC requirement

For Proxmox, every **new VM build** should receive a newly generated locally administered MAC address rather than reusing the current fixed VM101 MAC.

The generated MAC should become stable managed state for the lifetime of that VM instance. A later replacement/new instance receives a new MAC.

Azure and AWS network identity should remain provider-managed where their virtual networking model does not expose equivalent customer-controlled MAC lifecycle semantics.

Tracked in:

```text
jrwroberts1976/proxmox#11
jrwroberts1976/home-lab-docs#57
```

## Current stopping point

The infrastructure automation objective for the morning is complete and reproducible. The remaining work is application polish rather than a rebuild failure.

Priority on return:

1. fix Zabbix PHP PostgreSQL frontend support in Ansible;
2. validate frontend and idempotence;
3. rename Ansible inventory alias to `zabbix-server-01`;
4. update/close documentation and issues;
5. begin design work for the multi-cloud/web-based production provisioning project only after the Zabbix solution is fully closed.
