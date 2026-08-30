# TODO — 30 August 2026

## P0 — Complete disposable Proxmox IaC proof

1. ⬜ **Re-run the corrected Ansible baseline dry-run.**
   - command must use `--check --diff`;
   - QEMU guest-agent and node-exporter service-start tasks should skip in check mode;
   - require `failed=0` before any guest mutation.

2. ⬜ **Review and commit the baseline playbook.**
   - confirm it manages only the intended baseline:
     - timezone `Europe/London`;
     - `qemu-guest-agent`;
     - `prometheus-node-exporter`;
   - syntax-check;
   - commit and push before apply.

3. ⬜ **Apply the Ansible baseline to VM 100.**
   - no application/service migration;
   - require clean play recap;
   - record package/service changes.

4. ⬜ **Prove Ansible idempotence.**
   - re-run the same playbook;
   - target `changed=0`, `failed=0`;
   - investigate any recurring change rather than accepting it silently.

5. ⬜ **Verify guest-agent operation.**
   - service enabled/running inside the VM;
   - enable the corresponding Proxmox VM agent setting through OpenTofu only after the guest package is present;
   - verify Proxmox can query guest information.

6. ⬜ **Verify Prometheus node exporter.**
   - service enabled/running;
   - port `9100` listening;
   - `/metrics` reachable from the intended monitoring network/source;
   - do not add Prometheus scrape configuration until the endpoint itself is proven.

7. ⬜ **Correct the disk/controller warning through OpenTofu.**
   - current warning: `iothread is only valid with virtio disk or virtio-scsi-single controller, ignoring`;
   - choose the reviewed controller/disk combination rather than disabling a warning blindly;
   - plan first;
   - no manual `qm set` drift.

8. ⬜ **Re-run OpenTofu plan after baseline/controller work.**
   - require no unintended replacement/destruction;
   - after apply, require a clean no-change plan.

9. ⬜ **Review the cloud-init `user` deprecation.**
   - current cloud-init result is operationally successful;
   - determine whether the pinned provider supports a non-deprecated `users` model cleanly;
   - do not change working access until the replacement is validated.

## P0 — State, backup and recovery before production

10. ⬜ **Decide the OpenTofu state-storage approach.**
    - state must remain out of Git;
    - define backup, restore and credential handling;
    - TestServer local state is acceptable only for the disposable proof, not as an undocumented production dependency.

11. ⬜ **Define an off-host Proxmox backup destination.**
    - the local 480 GB SATA SSD is not sufficient as the sole backup copy;
    - preserve a recovery path if the Proxmox host itself fails.

12. ⬜ **Prove disposable VM destroy/rebuild from source.**
    - capture the evidence needed before destruction;
    - destroy only VM 100 / its managed resources;
    - rebuild through OpenTofu;
    - reapply Ansible baseline;
    - prove SSH, guest agent and node exporter again.

13. ⬜ **Prove backup/restore of the disposable VM.**
    - document backup creation;
    - perform a controlled restore/recovery test;
    - prove the guest boots and is reachable after recovery.

## P1 — Production Docker VM preparation, only after P0 gates pass

14. ⬜ **Define production Docker VM sizing and storage.**
    - account for current 8 GB host RAM and planned 32 GB upgrade;
    - avoid exhausting the hypervisor during migration overlap;
    - decide use of NVMe versus secondary SATA for OS/application data.

15. ⬜ **Define production VM networking/DNS/monitoring.**
    - stable address/reservation;
    - DNS independent of the VM;
    - monitoring available before workload migration;
    - recovery access independent of Jenkins.

16. ⬜ **Build the production Docker VM through the proven OpenTofu + Ansible pattern.**
    - no manual one-off build steps;
    - source of truth in Git;
    - validate before migrating services.

17. ⬜ **Migrate Homepage first as the low-risk service proof.**
    - leave TestServer source instance available until replacement is proven;
    - validate configuration, health, routing and monitoring;
    - document rollback;
    - do not move Prometheus/Loki early.

## Daily operational triage

18. 🔁 **Review nightly homelab reports.**
    - review the 29 August report if it was not already reviewed separately;
    - review the 30 August report when it arrives around 08:00;
    - triage security, patching, backups, monitoring and health;
    - add only genuine new evidence-backed tasks;
    - deduplicate against this list.

## Secondary backlog — visible but not today's P0

19. ⬜ Jenkins dashboard/folder organisation.
20. ⬜ PostgreSQL + TimescaleDB + Nginx Proxmox VM after the base VM pattern is proven.
21. ⬜ Home Assistant solution on the Proxmox/homelab platform.
22. ⬜ Read-only Kubernetes inspection backend and `demo/whoami` pilot.
23. ⬜ Homelab Defender controlled external publication.
24. ⬜ Grafana Host Overview coverage audit.

## Definition of a good stopping point today

A strong 30 August stopping point is reached when the Ansible baseline is applied and idempotent, the QEMU guest agent and node exporter are proven, the OpenTofu storage warning is resolved without unintended VM replacement, and the state/backup strategy is documented enough to proceed safely to destroy/rebuild testing.

Do not start production service migration merely to increase visible progress if those proof gates remain open.
