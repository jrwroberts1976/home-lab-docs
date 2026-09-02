# 02 September 2026 — Daily Actions

## Starting position

01 September closed GREEN with the VM101 base lifecycle proven end-to-end under OpenTofu.

Current known-good application-platform state:

| Item | State |
| --- | --- |
| Proxmox VM | `101` / `app-platform-01` |
| IPv4 | `192.168.2.253` |
| MAC | `BC:24:11:08:A2:33` |
| Guest OS | Debian GNU/Linux 13 (`trixie`) |
| Storage | `vm-ssd` |
| Template | `9001` / `debian-13-cloud-template-qga` |
| OpenTofu lifecycle | unattended destroy/rebuild proven |
| QEMU guest agent | baked into template and validated |
| VM backup / restore | proven |
| OpenTofu final drift | zero |
| Proxmox repository | branch work reconciled into `main` |
| `home-lab-docs` | previous branch work reconciled into `main` |

Do not repeat the template-repair, VM101 recovery, backup/restore proof, or repository-reconciliation work unless a new validation failure requires it.

## Primary objective

Move VM101 from a proven **base VM lifecycle** to a proven **repeatable application-platform baseline**.

The desired build chain is:

```text
OpenTofu VM lifecycle
        |
        v
Linux security baseline
        |
        v
unattended-upgrades policy
        |
        v
Grafana Alloy observability
        |
        v
baseline validation / idempotence
        |
        v
PostgreSQL
        |
        v
TimescaleDB
        |
        v
Nginx
```

The infrastructure should remain Infrastructure-as-Code first. Manual guest changes should be treated as diagnostic or temporary unless they are subsequently represented in Ansible or the relevant repository automation.

## P1 — Morning VM101 health and drift gate

Before changing the guest, confirm yesterday's result still represents the live state.

- [ ] Confirm VM101 is running on `PROXMOX`.
- [ ] Confirm QEMU guest agent responds.
- [ ] Confirm hostname is `app-platform-01`.
- [ ] Confirm IPv4 remains `192.168.2.253`.
- [ ] Confirm MAC remains `BC:24:11:08:A2:33`.
- [ ] Confirm SSH access as `james` is non-interactive with the existing key.
- [ ] Confirm Debian release remains `trixie`.
- [ ] Run OpenTofu `fmt`, `validate`, and a detailed-exit-code plan.
- [ ] Require `plan_rc=0` before continuing with configuration work.
- [ ] Check current Git state before creating any new branch/worktree.

### Gate

```text
VM101 live identity = PASS
QEMU guest agent = PASS
SSH identity = PASS
OpenTofu plan_rc = 0
repository state understood = PASS
```

If the OpenTofu plan is not clean, stop and investigate rather than normalising unexpected drift.

## P1 — Make the guest baseline repeatable through Ansible

Yesterday proved the VM can be recreated automatically. Today should prove the required guest configuration can also be restored from code.

### Linux security baseline

- [ ] Review the existing validated Linux security-hardening role/runbook against VM101.
- [ ] Apply the security-hardening role through the VM101 inventory.
- [ ] Validate weak UMAC-64 SSH algorithms remain disabled.
- [ ] Validate IPv4 ICMP timestamp requests remain blocked.
- [ ] Confirm normal SSH and normal ICMP echo behaviour are not broken.
- [ ] Re-run the playbook and require idempotence.

Security hardening remains a mandatory build gate before database services.

### Unattended upgrades

- [ ] Run the VM101 unattended-upgrades role from the repository.
- [ ] Confirm the service/timer/package configuration is present and healthy.
- [ ] Confirm automatic reboot remains disabled.
- [ ] Confirm `Automatic-Reboot-WithUsers` remains disabled.
- [ ] Re-run the role and require zero unintended changes.

Required policy:

```text
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-WithUsers "false";
```

### Grafana Alloy

- [ ] Deploy/validate Alloy from the repository role rather than by manual package configuration.
- [ ] Confirm Alloy service is active.
- [ ] Confirm node metrics arrive at central Prometheus on `ids-01`.
- [ ] Confirm journal/log telemetry arrives at Loki on `ids-01`.
- [ ] Confirm VM101 remains visible in the normal Grafana Linux dashboards.
- [ ] Do not recreate the removed dedicated `alloy-app-platform-01-telemetry-missing` alert unless a new monitoring design explicitly requires it.
- [ ] Re-run the Alloy role and require idempotence.

## P1 — Extend the end-to-end build beyond OpenTofu

The current `scripts/vm101-end-to-end-rebuild.sh` proves the base VM lifecycle only. The next automation increment is to add controlled Ansible post-provisioning after the OpenTofu create/identity gates have passed.

- [ ] Review the current end-to-end script before editing.
- [ ] Add a post-provision Ansible stage only after VM identity, guest-agent, IP and SSH gates pass.
- [ ] Run security hardening before application services.
- [ ] Run unattended-upgrades configuration.
- [ ] Run Alloy observability configuration.
- [ ] Add machine-checkable PASS/FAIL validation for each Ansible stage.
- [ ] Add an Ansible idempotence gate.
- [ ] Preserve fail-closed behaviour: no database/service deployment after a failed baseline gate.
- [ ] Keep destructive approval scoped to the individual rebuild invocation rather than persistently exported.

### Target end-to-end chain

```text
backup
  -> OpenTofu destroy
  -> OpenTofu create from template 9001
  -> guest agent / IP / SSH identity
  -> Linux security hardening
  -> unattended-upgrades
  -> Alloy
  -> Ansible idempotence
  -> OpenTofu zero drift
  -> end-to-end PASS
```

The existing restore-tested VM backup and OpenTofu state-backup safeguards must remain in place.

## P2 — Application platform services

Begin application services only after the baseline gates above are GREEN.

### PostgreSQL

- [ ] Review `runbooks/postgresql-install.md` and the repository PostgreSQL Ansible role.
- [ ] Confirm supported PostgreSQL version and package source before applying.
- [ ] Deploy PostgreSQL through Ansible.
- [ ] Confirm service health and local connectivity.
- [ ] Confirm database/user ownership and authentication policy.
- [ ] Validate filesystem/storage locations and backup implications.
- [ ] Re-run the role and require idempotence.

### TimescaleDB

- [ ] Start only after PostgreSQL acceptance passes.
- [ ] Review `runbooks/timescaledb-install.md`.
- [ ] Deploy TimescaleDB through Ansible.
- [ ] Confirm required preload configuration.
- [ ] Confirm extension creation.
- [ ] Validate a test hypertable/query path.
- [ ] Re-run and require idempotence.

### Nginx

- [ ] Start only after the database layer is stable.
- [ ] Review `runbooks/nginx-install.md`.
- [ ] Deploy through Ansible.
- [ ] Require `nginx -t` before reload/restart.
- [ ] Confirm intended listen interfaces and exposure only.
- [ ] Validate service health and rollback path.
- [ ] Re-run and require idempotence.

## P2 — Monitoring and operational acceptance

As services are added, extend monitoring rather than waiting until the stack is complete.

- [ ] Confirm Linux host metrics/logs after each material configuration stage.
- [ ] Add PostgreSQL service/database health telemetry when PostgreSQL is commissioned.
- [ ] Add TimescaleDB-specific checks where they provide operational value.
- [ ] Add Nginx service/HTTP health monitoring when Nginx is commissioned.
- [ ] Ensure alerts distinguish actual service failure from planned maintenance/rebuild activity.
- [ ] Keep dashboards and alerting configuration under version control.

## P3 — Zabbix workstream

Zabbix remains a separate planned monitoring workstream and should not block the VM101 application-platform build unless it is deliberately selected as today's primary task.

- [ ] Review the prepared Zabbix server/client Ansible runbooks before deployment.
- [ ] Decide the target host/architecture and whether Zabbix complements or duplicates the existing Prometheus/Grafana/Loki stack.
- [ ] Do not install Zabbix on VM101 merely because the runbooks exist; first confirm its intended role in the target architecture.

## P3 — Proxmox follow-up backlog

These remain valid platform tasks but are not prerequisites for today's VM101 software build unless a related problem appears:

- [ ] Review/update HP ProDesk BIOS firmware.
- [ ] Continue central Proxmox host monitoring/dashboard work where still incomplete.
- [ ] Complete remaining Proxmox host security-baseline items.
- [ ] Continue Jenkins IaC integration planning after the VM/Ansible workflow is stable.
- [ ] Continue wider workload migration planning only after the first application-platform stack is accepted.

## Change-control rules for today

1. Use repository-backed OpenTofu/Ansible as the source of truth.
2. Never apply an unexpected OpenTofu plan.
3. Do not place generated plans, credentials, state or temporary evidence files inside Git.
4. Keep temporary/destructive VMIDs ownership-gated before deletion.
5. Back up before destructive lifecycle testing.
6. Validate each service before proceeding to the next layer.
7. Require Ansible idempotence for completed roles.
8. Commit coherent changes with clear validation evidence.
9. Merge completed work back to `main` before end-of-day closeout where safe.
10. Update this daily-actions record with actual outcomes rather than marking intended work as completed prematurely.

## Suggested execution order

```text
1. VM101 morning health + OpenTofu zero-drift gate
2. Linux security-hardening validation
3. unattended-upgrades Ansible validation
4. Alloy Ansible validation
5. integrate the three baseline stages into end-to-end rebuild automation
6. prove rebuilt VM returns to the full baseline automatically
7. PostgreSQL
8. TimescaleDB
9. Nginx
10. monitoring/acceptance and documentation closeout
```

## Definition of done for a strong day

A strong 02 September result would be:

- VM101 remains zero-drift under OpenTofu;
- Linux security hardening, unattended-upgrades and Alloy are all reproducible and idempotent through Ansible;
- the end-to-end rebuild automation restores that baseline without manual guest repair;
- PostgreSQL deployment is either completed and idempotent, or its next action is documented with a clean validated stopping point;
- all changes are committed, pushed and documented;
- no unexplained branch-only work or uncommitted production changes remain at closeout.

PostgreSQL/TimescaleDB/Nginx progress beyond that is valuable, but should not be achieved by weakening the baseline, validation or recovery gates.
