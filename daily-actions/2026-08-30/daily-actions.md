# Daily Actions — 30 August 2026

## Starting position

29 August closed with Stage 6 formally complete and the Proxmox migration project active.

The disposable VM proof has reached this validated chain:

```text
Git -> OpenTofu -> Proxmox -> cloud-init -> DHCP -> SSH -> Ansible inventory -> sudo/root
```

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
On boot:     false
State:       running
```

No production workload has been migrated to Proxmox yet. TestServer remains the live source platform.

## Current Proxmox IaC checkpoint

Repository: `jrwroberts1976/proxmox`

Active branch at the 29 August close:

```text
iac/bootstrap-opentofu
```

Latest pushed proof commit recorded during the work:

```text
95bd863 Add disposable Proxmox VM Ansible inventory
```

The branch contains the OpenTofu provider bootstrap, disposable VM definition, lifecycle start change and Ansible lab inventory.

### Proven

- Proxmox least-privilege API access from TestServer.
- OpenTofu `1.12.6` on TestServer.
- BPG Proxmox provider pinned to `0.111.1`.
- Official Debian 13 cloud image downloaded and checksum-pinned.
- VM 100 created through OpenTofu.
- VM configuration inspected before first boot.
- `on_boot=false` retained.
- DHCP and SSH key authentication proven.
- cloud-init completed with no fatal errors.
- Repository Ansible inventory works.
- Ansible `ping` works.
- Ansible `become`/sudo path reaches UID 0.

### Open technical debt

1. The first Ansible baseline dry-run needs to be repeated after making service-start tasks skip in check mode.
2. The baseline playbook is not yet committed/pushed.
3. The baseline has not yet been applied to the guest.
4. Proxmox warned that `iothread=true` is ignored with the current `virtio-scsi-pci` controller.
5. cloud-init reports a recoverable deprecation warning for the legacy `user` field.
6. OpenTofu state is currently local to TestServer; production state backup/recovery design is not yet complete.
7. Disposable VM destroy/rebuild and backup/restore proofs remain outstanding.

## Priority for today

Complete the disposable IaC VM proof before designing or creating the production Docker VM.

The safe order is:

1. clean Ansible check-mode proof;
2. commit the baseline configuration;
3. apply the baseline;
4. prove idempotence and monitoring/guest-agent operation;
5. correct the OpenTofu disk/controller warning;
6. prove zero unintended drift;
7. define state/backup recovery;
8. destroy and rebuild the disposable VM from source;
9. prove restore/recovery before production migration.

## Migration safety boundary

- Do not migrate Homepage or any other live service until the disposable proof is complete.
- Do not remove or repurpose TestServer during the proof.
- Keep Pi-hole/Unbound DNS independent of Proxmox.
- Keep `ids-01` security services independent of Proxmox.
- Keep Jenkins/Jenkins DinD protected and do not make Jenkins the only recovery path for infrastructure.
- Keep OpenTofu state and credentials out of Git.
- Require an off-host backup path before any production workload migration.
- Prometheus and Loki remain late-migration services so observability remains available during earlier waves.

## Daily report triage

The automated/nightly homelab report normally arrives at about 08:00 local time.

- If the 29 August report was not reviewed separately, review it and record any genuine evidence-backed follow-up.
- Review the 30 August report when it arrives.
- Deduplicate findings against `todo.md`.
- Do not infer clean security, backup, patching or monitoring state from project validation alone.

## Daily summary

### Completed today

- None recorded yet. Update this section only as evidence-backed work completes on 30 August.

### Carried forward

- Finish and prove the Ansible baseline.
- Correct the OpenTofu storage-controller warning.
- Define OpenTofu state recovery and Proxmox backup/restore strategy.
- Complete disposable VM destroy/rebuild and recovery proof.
- Only then begin the production Docker VM build and low-risk service migration sequence.
