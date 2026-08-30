# Daily Actions — 30 August 2026

## Starting position

29 August closed with Stage 6 formally complete and the Proxmox migration project active. The disposable Debian VM had been created through OpenTofu and reached the first Ansible connectivity/sudo proof, but its monitoring, patching, reboot and recovery baseline still needed to be completed.

Current disposable VM:

```text
VM ID:       100
Name:        debian-iac-test-01
IP:          192.168.2.120
MAC:         BC:24:11:71:7E:65
OS:          Debian 13 (trixie)
CPU:         2 vCPU
Memory:      2048 MB
Disk:        24 GB local-lvm
State:       running
```

No production workload has been migrated to Proxmox. TestServer remains the live source platform.

## Proxmox IaC authority

Repository: `jrwroberts1976/proxmox`  
Branch: `iac/bootstrap-opentofu`

Significant checkpoints reached today include:

```text
c4fa06e Add Debian patch management baseline
941047f Add controlled Debian patch workflow
```

The branch was pushed and local/remote authority was verified at `941047f` during the reboot/recovery proof.

## Completed today

### VM monitoring, logging and security baseline

- [x] Proved the Ansible baseline and repeatable/idempotent operation.
- [x] Proved QEMU guest-agent operation.
- [x] Proved node_exporter and Prometheus coverage for `debian-iac-test-01` under `linux-hosts`.
- [x] Proved Alloy systemd-journal forwarding to central Loki.
- [x] Proved CrowdSec consumes the VM SSH stream from Loki and correctly parses/whitelists private-network SSH traffic.
- [x] Proved the standard Grafana Linux host alert baseline covers the VM.

### Patch-management baseline

- [x] Added `unattended-upgrades` as the automated security-patching mechanism.
- [x] Restricted automatic installation to Debian security origins.
- [x] Explicitly disabled automatic reboot.
- [x] Added the patch-status collector, systemd service and hourly timer.
- [x] Exported pending updates, security updates, reboot-required state, unattended-upgrades state and patch timestamps through node_exporter.
- [x] Proved those metrics in Prometheus.
- [x] Added Grafana alert `Patch collector stale` with a two-hour freshness threshold and five-minute hold.
- [x] Added Grafana alert `Security updates available` with a two-hour hold.
- [x] Merged the Grafana alert definitions to `jrwroberts1976/grafana-alerting` and deployed only the two intended live rules.

### Controlled patch/reboot workflow

- [x] Added `ansible/playbooks/patch.yml`.
- [x] Default behaviour is audit-only.
- [x] `patch_apply=true` is required to install updates.
- [x] `patch_reboot=true` is separately required before a reboot is permitted.
- [x] The playbook rejects reboot approval unless patch application is also approved.
- [x] Audit-only run passed with `failed=0`.
- [x] Apply-without-reboot run passed with `failed=0`.
- [x] Baseline service verification covers QEMU guest agent, node_exporter, Alloy and the patch-status timer.

### Deliberate reboot and recovery proof

Pre-reboot boot ID:

```text
ff3b030b-f673-4c9a-b7f7-985476e16f91
```

Post-reboot boot ID:

```text
57bd9094-345f-42ea-92c1-a7f23cc66cd8
```

- [x] Ansible deliberately rebooted the VM and reported `rebooted=true`.
- [x] VM returned successfully.
- [x] Boot-ID change proved a real reboot occurred.
- [x] QEMU guest agent recovered.
- [x] node_exporter recovered.
- [x] Alloy recovered.
- [x] patch-status timer recovered.
- [x] unattended-upgrades recovered.
- [x] patch metrics reported zero pending/security updates and zero reboot requirement.
- [x] Prometheus saw `up=1` after reboot.
- [x] Patch metric age was fresh after reboot.
- [x] Loki contained post-reboot systemd-journal entries from the VM.

## End-of-day position

The **VM operating baseline is complete**: provisioning, Ansible configuration, monitoring, logging, CrowdSec integration, patch policy, patch metrics, Grafana alerts and reboot recovery are all proven.

The **overall disposable-VM acceptance is not yet complete** because the recovery/rebuild gates remain outstanding.

### Remaining P0 work

1. Correct the OpenTofu `iothread` / SCSI-controller warning through IaC.
2. Define/prove an off-host backup destination.
3. Back up VM 100 and validate the backup.
4. Capture pre-destroy equivalence evidence.
5. Destroy VM 100 through OpenTofu.
6. Recreate VM 100 entirely from Git/OpenTofu/cloud-init/Ansible.
7. Prove functional equivalence after rebuild.
8. Restore the backup separately and prove recovery.
9. Produce the full “Build a New Proxmox VM From Scratch” runbook.

## New planned work recorded today

### Jenkins parameterised runbook pipeline

After the reference VM reaches 100%, build a Jenkins pipeline where approved runbooks/playbooks are selected through build parameters. Begin with safe/audit actions, preserve manual execution, and require explicit approval for disruptive operations.

### Container upgrade and rollback process

Manually prove a standard upgrade flow before Jenkins automation: identify current/target image identity, review release notes, verify backup/rollback readiness, upgrade only the intended container, validate application/monitoring/logging, observe, record Git authority and prove rollback.

### Containers that were not upgraded

Create an exception inventory for skipped containers and classify the reason: current, pinned, local build, platform limitation, incompatible target, major migration, stateful/database safeguards, deprecated image, previous failure or unclear ownership. Every skipped container must end with an explicit `upgrade`, `migrate`, `replace`, `remain pinned`, or `retire` decision.

### Zabbix platform

The previously separate PostgreSQL + TimescaleDB + Nginx Proxmox VM idea is now part of the Zabbix project. After the reference VM is fully proven, build the Zabbix platform through OpenTofu + Ansible and apply the same monitoring, logging, security, patching, backup and recovery standards.

## Stopping-point decision

30 August is closed at a safe boundary. Do not start the Zabbix build or production workload migration until the disposable VM destroy/rebuild and backup/restore proofs are complete.

See [`todo.md`](todo.md) for the carried-forward actions and [`../../project-register.md`](../../project-register.md) for the master programme backlog.
