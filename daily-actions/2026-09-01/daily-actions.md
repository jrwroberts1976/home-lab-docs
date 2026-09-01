# 01 September 2026 — Daily Actions and Closeout

## Executive summary

01 September closed with two major workstreams completed:

1. the security-reporting / Greenbone reconciliation was closed GREEN; and
2. the first Proxmox application-platform VM lifecycle was proven end-to-end under OpenTofu, including backup, controlled destruction, unattended rebuild, guest-agent validation, network identity validation, SSH validation and final zero-drift verification.

The Proxmox repository was also reconciled so all branch-only history is now contained in `main` without restoring superseded configuration.

## Security reporting reconciliation

The full security-reporting investigation, disposition repair, Greenbone verification, metric refresh and management-report correction is recorded separately in:

- [`reporting-reconciliation.md`](reporting-reconciliation.md)

Final security reporting posture was GREEN across all reported domains, with reviewed Greenbone observations reconciled against persistent disposition state rather than reintroduced as new engineering work.

## Proxmox application-platform VM101

### Final VM identity

| Item | Value |
| --- | --- |
| VMID | `101` |
| Name | `app-platform-01` |
| Guest OS | Debian GNU/Linux 13 (`trixie`) |
| IPv4 | `192.168.2.253` |
| MAC | `BC:24:11:08:A2:33` |
| Storage | `vm-ssd` |
| vCPU | `2` |
| Memory | `4096 MB` |
| Boot disk | `64 GB` |
| OpenTofu resource | `proxmox_virtual_environment_vm.app_platform` |

The MAC address is explicitly pinned in OpenTofu so the DHCP identity remains stable across destroy/rebuild cycles.

### QEMU guest-agent template correction

The original Debian cloud template `9000` did not contain `qemu-guest-agent`. This caused the first automated rebuild attempt to wait indefinitely for guest-agent data even though the VM itself had booted successfully.

A controlled repair path was completed without modifying the original template in place:

1. clone template `9000` to temporary repair VM `9901`;
2. install and validate `qemu-guest-agent` through temporary cloud-init user-data;
3. clean cloud-init state, machine identity, SSH host keys and package cache;
4. remove the temporary `cicustom` data;
5. clone the cleaned repair source to new template `9001`;
6. convert `9001` to template `debian-13-cloud-template-qga`;
7. test it through an isolated full clone with its NIC set `link_down=1`.

The isolated template smoke test passed. Because the clone had no network connectivity and no repair snippet, successful `qemu-guest-agent` startup proved that the agent is genuinely baked into template `9001`.

Template `9000` remains preserved as the earlier source/rollback reference. New VM101 builds now use template `9001`.

### OpenTofu template migration

OpenTofu was updated from template `9000` to `9001`.

The migration plan was inspected in machine-readable JSON and confirmed to have exactly one replacement reason:

```text
resource=proxmox_virtual_environment_vm.app_platform
actions=["delete","create"]
replace_path=clone[0].vm_id
before=9000
after=9001
```

The end-to-end automation accepts this one controlled migration condition while continuing to reject any unrelated drift.

After the first migration/rebuild completed, the final OpenTofu plan returned zero drift.

## Backup and recovery evidence

Backup/recovery was proved before the final unattended lifecycle test.

A VM101 `vzdump` archive was validated with `zstd`, restored to isolated VM `102`, and the restored guest was checked for Debian 13 identity, Alloy service state and unattended-upgrades policy before VM102 was removed.

The final unattended rebuild also created fresh recovery evidence before destroying VM101.

Final end-to-end state backup:

```text
/home/james/tofu-state-backups/vm101-pre-e2e-20260901-215749.tfstate
```

Final pre-destroy VM backup:

```text
/var/lib/vz/dump/vzdump-qemu-101-2026_09_01-22_00_36.vma.zst
```

Final run log:

```text
/tmp/vm101-e2e-20260901-215749/run.log
```

## Unattended VM101 lifecycle automation

The repository now contains:

```text
scripts/vm101-end-to-end-rebuild.sh
```

The script is deliberately fail-closed and performs the following sequence:

```text
explicit destructive approval
        |
        v
local tooling / file / repository gates
        |
        v
non-interactive Proxmox SSH gate
        |
        v
OpenTofu init / fmt / validate
        |
        v
current drift or controlled template-migration gate
        |
        v
isolated template-9001 guest-agent smoke test
        |
        v
OpenTofu state backup + SHA verification
        |
        v
fresh VM101 vzdump backup + zstd validation
        |
        v
exact one-resource destroy plan gate
        |
        v
apply exact destroy plan
        |
        v
state empty + VM absent gates
        |
        v
exact one-resource create plan gate
        |
        v
apply exact create plan from template 9001
        |
        v
VMID / MAC / running-state gate
        |
        v
QEMU guest-agent gate
        |
        v
192.168.2.253 guest-IP gate
        |
        v
SSH hostname / Debian trixie identity gate
        |
        v
final OpenTofu zero-drift gate
```

The temporary template-probe VMID is ownership-protected: if the configured temporary VMID already exists when the script starts, the script refuses to reuse or delete it.

The destructive approval variable is supplied only for the individual invocation rather than exported persistently.

### Final lifecycle result

The real unattended test completed successfully with no manual repair during the lifecycle:

```text
===== END-TO-END REBUILD PASS =====
vmid=101
name=app-platform-01
ip=192.168.2.253
mac=BC:24:11:08:A2:33
state_backup=/home/james/tofu-state-backups/vm101-pre-e2e-20260901-215749.tfstate
vm_backup=/var/lib/vz/dump/vzdump-qemu-101-2026_09_01-22_00_36.vma.zst
log=/tmp/vm101-e2e-20260901-215749/run.log
```

This proves the base VM lifecycle can now be recreated from code rather than relying on manual VM construction.

## VM101 observability handling

The dedicated Grafana alert rule `alloy-app-platform-01-telemetry-missing` was removed from Grafana provisioning and its absence was confirmed through the provisioning API.

The VM remains visible in normal Grafana dashboards. Only the dedicated alert was removed; dashboard observability was intentionally retained.

## Ansible work completed / prepared

The VM101 inventory exists under:

```text
ansible/inventories/vm101/hosts.yml
```

It defines VM101 for Alloy and unattended-upgrades management.

The unattended-upgrades role was previously applied idempotently to the live VM, with automatic reboot disabled:

```text
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
```

The next automation increment is to include the Ansible configuration stages in the end-to-end build after the OpenTofu base lifecycle has passed.

## Git / branch closeout

### Proxmox repository

The main VM101 work was merged through PR #9.

The remaining `iac/bootstrap-opentofu` branch had unique historical commits but conflicted with the current proven VM101 implementation. Its history was therefore merged using the current `main` tree as authoritative, preserving the old history without restoring superseded configuration. GitHub records this as merged PR #10.

After reconciliation, the previously listed Proxmox development/documentation branch tips have no commits ahead of `main`.

### home-lab-docs repository

All pre-existing non-main documentation branch tips checked during closeout were already fully contained in `main` (`ahead_by=0`). No branch-only documentation work remained to recover before this daily closeout was added.

## Important repository commits

Key Proxmox commits from the final VM101 work include:

- `52613bb` — pin VM101 network identity in OpenTofu;
- `3cc1028` — remove the dedicated VM101 Grafana alert;
- `626e6a2` — add VM101 end-to-end rebuild automation;
- `162db77` — switch to the QEMU guest-agent-enabled template and harden migration/temp-VM gates;
- `f6bdfed` — merge the VM101 OpenTofu foundation and unattended rebuild into `main`;
- `3a58923` — reconcile the legacy OpenTofu bootstrap history while retaining the current `main` tree.

## Next working session

The base VM lifecycle is now considered proven. The next planned sequence is:

1. extend the VM101 end-to-end flow with Ansible configuration;
2. automatically commission Alloy / Linux telemetry;
3. automatically apply and validate unattended-upgrades policy;
4. retain the security-hardening gate before application services;
5. continue the application-platform build with PostgreSQL;
6. add TimescaleDB;
7. add Nginx;
8. keep each service deployment IaC/Ansible-driven with idempotence, validation, backup and rollback gates.

## End-of-day status

**CLOSED GREEN.**

VM101 can now be destroyed and recreated unattended from the Proxmox/OpenTofu baseline with stable identity, validated backup evidence, a working QEMU guest agent and a final no-drift state.
