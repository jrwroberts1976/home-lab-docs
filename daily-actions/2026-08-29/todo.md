# TODO — 29 August 2026 — CLOSED

## Day status

29 August is closed.

The original Stage 6 TODO was overtaken by later work completed on the same day. Stage 6 is now formally complete and must not be carried forward as active work.

## Completed / closed today

### P0 — Stage 6 estate updater

1. ✅ Build the steady-state read-only inspection contract.
2. ✅ Make Homepage and Dashy steady-state inspectable on TestServer.
3. ✅ Integrate steady-state inspection into the estate updater.
4. ✅ Install and prove the ids-01 read-only Stage 6 inspection transport.
5. ✅ Use Prometheus as the first ids-01 / amd64 Stage 6 proof.
6. ✅ Add the narrow internal-network `container-http` health strategy.
7. ✅ Prepare Blackbox Exporter source authority on both hosts.
8. ✅ Reconcile shared steady-state authority metadata in Git source.
9. ✅ Roll the installed Stage 6 authority/manifests through the reviewed rollout required for closure.
10. ✅ Re-prove the managed Stage 6 state through the final reviewed rollout.
11. ✅ Resolve remaining tagged-image cases by either reviewed normalization or explicit formal deferral; rollback guarantees were not weakened.
12. ✅ Close Blackbox/other remaining Stage 6 cases under the final reviewed Stage 6 closure decision.
13. ✅ Complete the remaining standard-registry Stage 6 review scope required for closure.
14. ✅ Complete final estate classification required for Stage 6 closure.
15. ✅ Preserve dedicated treatment/deferral for higher-risk Portainer/WUD/cAdvisor/BirdNET/etc. cases rather than weakening policy.
16. ✅ Consume the reusable normalization work where valid; completed one-shot contracts must not be rerun.

Final closure:

```text
STAGE6_NORMALIZATIONS_COMPLETED=7
STAGE6_NORMALIZATIONS_CONSUMED=7
STAGE6_FORMAL_DEFERRALS=13
STAGE6_UNREVIEWED_TAGGED_EXTERNAL_SERVICES=0
ROLLBACK_REQUIRED=false
STAGE6_CLOSED=true
```

Closure documentation was merged in `homelab-container-version-control` PR #84 and the project plan was marked complete in PR #85.

### Proxmox migration project activated

17. ✅ Move the Proxmox VM Infrastructure-as-Code project from secondary planning into active implementation.
18. ✅ Validate Proxmox host readiness and storage health.
19. ✅ Create a least-privilege `iac@pve` service identity and API token model.
20. ✅ Establish TestServer as the direct OpenTofu/Ansible control node.
21. ✅ Bootstrap OpenTofu with the pinned BPG Proxmox provider and protected local state/secret exclusions.
22. ✅ Create the disposable Debian 13 IaC proof VM as VM 100.
23. ✅ Prove the VM configuration while stopped and prove zero drift after creation.
24. ✅ Start the VM through Git/OpenTofu rather than manual hypervisor mutation.
25. ✅ Prove cloud-init, DHCP, SSH and Debian guest boot.
26. ✅ Add repository Ansible inventory and prove Ansible ping plus sudo/root control.
27. ✅ Draft and syntax-check the first Ansible baseline playbook.

## Explicitly carried forward to 30 August

1. ⬜ Re-run the corrected Ansible baseline with `--check --diff` and require `failed=0`.
2. ⬜ Commit and push the baseline playbook after the clean dry-run.
3. ⬜ Apply the baseline through Ansible: timezone, `qemu-guest-agent`, `prometheus-node-exporter`.
4. ⬜ Re-run the baseline and prove idempotence (`changed=0`, `failed=0`).
5. ⬜ Verify QEMU guest-agent status and node-exporter port/metrics from outside the VM.
6. ⬜ Correct the OpenTofu `iothread`/SCSI-controller warning without manual VM edits.
7. ⬜ Re-run OpenTofu plan and require zero unintended changes.
8. ⬜ Decide and document the OpenTofu state-storage/backup/recovery approach before production VM work.
9. ⬜ Complete disposable VM destroy/rebuild proof from Git/OpenTofu/Ansible.
10. ⬜ Design and prove an off-host Proxmox backup/restore path before migrating production services.
11. ⬜ Review the 29 August nightly report if it was not already reviewed elsewhere.

## Deferred / backlog — not active 30 August P0 unless reprioritised

- Read-only Kubernetes inspection backend / `demo/whoami` pilot.
- Jenkins dashboard/folder organisation.
- PostgreSQL + TimescaleDB + Nginx Proxmox VM project after the base VM pattern is proven.
- Home Assistant deployment.
- Homelab Defender controlled external publication.
- Grafana Host Overview coverage audit.
- Higher-risk container-update contracts already formally deferred by Stage 6 closure.

## Closed stopping point

29 August closed with Stage 6 formally complete and the new Proxmox IaC path proven through:

```text
Git -> OpenTofu -> Proxmox -> cloud-init -> DHCP -> SSH -> Ansible -> sudo/root
```

No production service was migrated and no existing source service was removed.
