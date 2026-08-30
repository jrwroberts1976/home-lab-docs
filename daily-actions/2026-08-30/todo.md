# TODO — 30 August 2026 — Closeout

## Status at end of day

Today reached a good stopping point on the disposable Proxmox VM proof. The operating baseline is built and verified; the remaining work is recovery/rebuild acceptance rather than day-to-day guest configuration.

## Completed today

- [x] Proved the Ansible VM baseline and idempotence.
- [x] Proved QEMU guest-agent operation.
- [x] Proved node_exporter and Prometheus coverage.
- [x] Proved Alloy systemd-journal forwarding to central Loki.
- [x] Proved CrowdSec SSH parsing/whitelisting for the VM log stream.
- [x] Proved the standard Grafana Linux alert baseline covers VM 100.
- [x] Added the Debian security-only unattended-upgrades policy.
- [x] Confirmed automatic reboot is disabled.
- [x] Added hourly patch-status metrics.
- [x] Proved patch metrics through node_exporter and Prometheus.
- [x] Added and deployed Grafana `Patch collector stale` alerting.
- [x] Added and deployed Grafana `Security updates available` alerting.
- [x] Added the controlled Ansible patch/reboot playbook.
- [x] Proved audit-only patch execution.
- [x] Proved patch-apply execution with reboot disabled.
- [x] Performed a deliberate VM reboot.
- [x] Proved post-reboot recovery of SSH, QEMU guest agent, node_exporter, Alloy, patch timer and unattended-upgrades.
- [x] Proved Prometheus recovery and fresh patch metrics after reboot.
- [x] Proved post-reboot journal ingestion in Loki.

## P0 — finish disposable VM acceptance

1. ⬜ **Correct the OpenTofu `iothread` / SCSI-controller warning.**
   - fix through OpenTofu;
   - plan first;
   - no manual Proxmox GUI/qm drift.

2. ⬜ **Define and prove an off-host Proxmox backup destination.**
   - backup must survive loss of the HP/NVMe;
   - document retention/encryption/restore assumptions.

3. ⬜ **Back up VM 100 and validate the backup.**

4. ⬜ **Capture pre-destroy equivalence evidence.**

5. ⬜ **Destroy VM 100 through OpenTofu.**

6. ⬜ **Recreate VM 100 entirely from Git/OpenTofu/cloud-init/Ansible.**

7. ⬜ **Prove rebuilt functional equivalence.**
   - SSH;
   - QEMU guest agent;
   - node_exporter / Prometheus;
   - Grafana alerts;
   - Alloy / Loki;
   - CrowdSec;
   - unattended security updates;
   - patch metrics and controlled patch workflow.

8. ⬜ **Restore the backup separately and prove recovery.**

9. ⬜ **Complete the full “Build a New Proxmox VM From Scratch” runbook.**

## Next projects after VM 100 reaches 100%

10. ⬜ **Build the parameterised Jenkins runbook pipeline.**
    - select approved runbooks/playbooks through build parameters;
    - safe/audit defaults;
    - target selection where appropriate;
    - validation and human approval gates;
    - separate patch and reboot approval;
    - preserve the manual recovery route.

11. ⬜ **Manually prove the standard container upgrade/rollback process.**
    - current and target image/digest evidence;
    - release-note/breaking-change review;
    - backup/rollback readiness;
    - targeted recreate;
    - application, monitoring and logging validation;
    - observation period;
    - rollback proof.

12. ⬜ **Inventory and resolve containers that were not upgraded.**
    - classify why each was skipped;
    - choose upgrade, migrate, replace, remain pinned or retire;
    - ensure every exception has an evidence-backed disposition.

13. ⬜ **Automate the proven container-upgrade process through Jenkins.**

14. ⬜ **Build the Zabbix platform on Proxmox.**
    - this includes PostgreSQL, TimescaleDB and Nginx;
    - provision with OpenTofu;
    - configure with Ansible;
    - apply the standard monitoring/logging/security/patch/backup baseline;
    - prove recovery and rebuildability from Git.

## Secondary backlog

- ⬜ Proxmox host monitoring, security, firmware and capacity work.
- ⬜ Reusable OpenTofu VM module and reusable Ansible Linux roles.
- ⬜ Wider Docker workload migration to Proxmox.
- ⬜ Home Assistant deployment and recovery testing.
- ⬜ Pi 4 garden-room BirdNET-Go + Pi-hole + Unbound role.
- ⬜ k3s-node-01 patch-management standardisation and Kubernetes recovery gates.
- ⬜ Finish k3s Secrets Encryption work.
- ⬜ Grafana/Git drift reconciliation and monitoring housekeeping.
- ⬜ Pi-hole/router/unknown-device follow-up.
- ⬜ Ongoing documentation, recovery, secrets and portfolio work.

## Next-session starting point

Start with the OpenTofu disk/controller warning and off-host backup design. Do not start the Zabbix build or production service migration until the disposable VM destroy/rebuild and restore gates are complete.

The master programme backlog is maintained in [`../../project-register.md`](../../project-register.md).
