# Daily Actions — 29 August 2026

## Starting position

The day began with Stage 6 container-version-control work still active. The immediate focus was to finish the reviewed estate-updater rollout without weakening immutable-image, rollback or protected-workload controls.

By the end of the day Stage 6 was formally closed and work had moved on to the Proxmox Infrastructure-as-Code migration proof.

## Completed today

### Stage 6 container-version-control closure

Stage 6 was completed and formally closed on 29 August.

Final reviewed closure evidence:

```text
STAGE6_REVIEW_COMPLETE=true
STAGE6_NORMALIZATIONS_COMPLETED=7
STAGE6_NORMALIZATIONS_CONSUMED=7
STAGE6_FORMAL_DEFERRALS=13
STAGE6_UNREVIEWED_TAGGED_EXTERNAL_SERVICES=0
SMOKEPING_DEFERRED=true
SMOKEPING_AUTHORITY_RECONCILED=true
ROLLBACK_REQUIRED=false
STAGE6_CLOSED=true
```

- Seven image-normalization contracts were completed and consumed.
- Thirteen tagged services were formally deferred with explicit technical reasons rather than weakening policy.
- Zero unreviewed tagged external services remained.
- SmokePing authority was reconciled while keeping its unsupported named-volume case deferred.
- Jenkins and Jenkins DinD remained protected.
- No rollback was required.
- Closure evidence was merged in `homelab-container-version-control` PR #84.
- The project-plan timeline was updated to **Complete — 29 Aug, ahead of plan** in PR #85.
- Final Stage 6 project-plan merge commit: `7daa2f60615ccca11ddc964ae5eba269bb564626`.

The earlier open Stage 6 roll-forward, re-proof and normalization TODOs are therefore superseded by the reviewed closure record and must not be carried forward as active daily work.

### Proxmox host readiness

The HP ProDesk Proxmox host was validated as ready for the first disposable IaC proof.

- Proxmox VE remained healthy with no failed services after removing the irrelevant OpenIPMI failure state.
- Pending Proxmox library updates were applied without requiring a reboot.
- NVMe SMART/health remained good: no critical warning, 6% used, no media/data integrity errors.
- The 480 GB Kingston SATA SSD passed SMART and an extended self-test; suitable for VM/application data, but not as the sole backup destination.
- No pre-existing VMs or LXCs existed before the proof.

### Proxmox least-privilege IaC access

Created a dedicated Proxmox service identity rather than using root/Administrator access for IaC.

- User: `iac@pve`.
- Narrow custom roles created for VM, storage and node operations.
- ACLs limited to `/vms`, `local`, `local-lvm` and node `PROXMOX`.
- API token `iac@pve!opentofu` created with `privsep=0`, inheriting only the already-limited service-account permissions.
- Token material kept outside Git with restrictive filesystem permissions.
- The Proxmox 9 bridge permission requirement was discovered safely during first apply and resolved by granting the reviewed SDN-use permission for `vmbr0`; no broad Administrator role was added.

### OpenTofu control node and repository bootstrap

TestServer was established as the temporary direct recovery/control node.

- OpenTofu `1.12.6` installed on TestServer (`linux_arm64`).
- Existing Ansible, Git, curl, jq and Python tooling retained.
- Proxmox repository cloned to `/home/james/projects/proxmox`.
- Branch `iac/bootstrap-opentofu` created and pushed.
- Runtime state, plans, tfvars, environment files, credentials and private keys excluded from Git.
- BPG Proxmox provider pinned to `0.111.1`; lock file committed.
- Provider initialization and validation passed.
- API authentication from TestServer passed using exported environment variables without exposing the token.

### Disposable Debian IaC VM proof

OpenTofu successfully created the first disposable VM after the least-privilege ACL issue was corrected.

VM proof state:

```text
VM ID:       100
Name:        debian-iac-test-01
Node:        PROXMOX
CPU:         2 vCPU
Memory:      2048 MB
Disk:        24 GB local-lvm
Bridge:      vmbr0
Cloud-init:  DHCP, user james, SSH public key
On boot:     false
```

- Official Debian 13 Trixie generic cloud image downloaded and checksum-pinned.
- First failed VM-create attempt stopped cleanly at a Proxmox `SDN.Use` permission check; the image was retained in OpenTofu state and no orphan VM was created.
- Fresh plan then showed exactly `1 to add, 0 to change, 0 to destroy`.
- VM 100 was created successfully and initially left stopped for inspection.
- API inspection proved the expected CPU, memory, disk, cloud-init drive, network and `onboot=0` configuration.
- OpenTofu reported no configuration drift after creation.
- VM start was subsequently changed through Git/OpenTofu rather than by manual `qm start`.
- Start apply completed `0 added, 1 changed, 0 destroyed`.

A non-fatal Proxmox warning remains to be corrected: `iothread=true` is ignored with the current `virtio-scsi-pci` controller. This is configuration debt, not a failed VM boot.

### Guest boot, cloud-init and network proof

The first guest boot completed successfully.

- DHCP lease: `192.168.2.120`.
- MAC: `BC:24:11:71:7E:65`.
- SSH key authentication as `james` succeeded.
- Hostname: `debian-iac-test-01`.
- OS: Debian GNU/Linux 13 (trixie), x86-64, KVM.
- Kernel: `6.12.95+deb13-cloud-amd64`.
- Clock synchronized by NTP.
- 24 GB virtual disk expanded correctly to the root filesystem.
- cloud-init completed with no errors; only a recoverable deprecation warning for the legacy `user` field was reported.

### Ansible control proof

The Ansible control path from TestServer was proven without manually configuring the guest.

- Ad-hoc Ansible ping succeeded over SSH.
- Repository inventory `ansible/inventories/lab.yml` created and committed.
- Python interpreter pinned to `/usr/bin/python3.13` for deterministic Ansible execution.
- Repository-inventory ping succeeded.
- `become`/sudo proof returned UID `0`.

Proven chain:

```text
Git -> OpenTofu -> Proxmox -> cloud-init -> DHCP -> SSH -> Ansible inventory -> sudo/root
```

### First Ansible baseline playbook preparation

A first baseline playbook was drafted to manage:

- timezone `Europe/London`;
- `qemu-guest-agent`;
- `prometheus-node-exporter`.

Syntax validation passed.

The first `--check --diff` run correctly exposed a check-mode sequencing issue: the package install is only simulated, so the following service task cannot find `qemu-guest-agent`. The service tasks were therefore guarded with `when: not ansible_check_mode`, and syntax validation passed again. A clean second dry-run still needs to be executed on 30 August before any baseline changes are applied.

## Safety / rollback position at close

- Existing TestServer services were not migrated or cut over.
- DNS and security services remain independent of Proxmox.
- VM 100 is explicitly disposable and remains part of the proof phase only.
- No production workload depends on VM 100.
- OpenTofu state remains local to TestServer and excluded from Git; production state/backup strategy is still to be decided.
- The source Docker platform remains available for future service-by-service migration and rollback.

## Daily report triage

No evidence was recorded in this daily-actions record that the 29 August nightly report was reviewed. Do not infer a clean report. If it was not reviewed separately, treat that as an operational follow-up on 30 August alongside the new day's report triage.

## Daily summary

### Completed today

- Stage 6 container-version-control rollout formally closed ahead of plan: 7 completed/consumed normalizations, 13 formal deferrals and zero unreviewed tagged external services.
- Proxmox host readiness and least-privilege IaC access established.
- OpenTofu control path bootstrapped on TestServer and committed to the Proxmox repository.
- Disposable Debian VM 100 created, inspected and started through OpenTofu.
- Cloud-init, DHCP, SSH and Debian guest boot validated.
- Ansible inventory, connectivity and sudo/root control validated.
- First baseline playbook drafted and syntax-checked.

### Carried forward

- Re-run the corrected Ansible baseline in `--check --diff` mode and require `failed=0` before applying it.
- Commit/push the baseline playbook, apply it, then prove idempotence.
- Install/prove QEMU guest agent and Prometheus node exporter through Ansible.
- Correct the Proxmox `iothread`/SCSI-controller warning through OpenTofu.
- Reconcile the cloud-init deprecated `user` field where supported by the provider.
- Decide and document the OpenTofu state-storage/backup approach before production infrastructure.
- Complete disposable-VM destroy/rebuild and backup/restore proof before building the production Docker VM.
- Review the 29 August nightly report if it was not already reviewed elsewhere.
