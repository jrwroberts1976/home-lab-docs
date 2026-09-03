# 03 September 2026 — Daily Actions

## Starting position

02 September is closed.

The strongest completed platform result carried into today is the proven VM101 destructive rebuild:

```text
OpenTofu lifecycle
  -> Linux hardening
  -> unattended-upgrades
  -> Alloy
  -> PostgreSQL 17
  -> TimescaleDB
  -> Nginx
  -> Zabbix Server
  -> Zabbix Agent 2
  -> Ansible idempotence
  -> OpenTofu zero drift
  -> PASS
```

Two application/platform follow-ups remain from that work:

1. Zabbix frontend PostgreSQL PHP support must be corrected in Ansible.
2. The VM101 Ansible inventory alias must be renamed from `app-platform-01` to `zabbix-server-01` and revalidated.

The Stage 6 container-update workflow also enters today with the reviewed Dozzle `10.9.0` transition available but requiring a clean synchronized target-side run.

## Early-morning completed work — Dozzle 10.9.0

The Dozzle Stage 6 target preparation was reset to a known-good state and repeated cleanly.

Target-side preparation proved:

- live Dozzle remained untouched on `10.8.0` during preparation;
- the stale installed Stage 6 validator was identified by hash mismatch and replaced with the exact reviewed repository validator;
- the installed `dozzle.json` transition manifest was synchronized to the reviewed `10.8.0 -> 10.9.0` manifest;
- the exact immutable Dozzle `10.9.0` ARM64 candidate was acquired into the TestServer Docker image cache;
- candidate image ID, OS/architecture and RepoDigest matched the reviewed manifest;
- candidate acquisition did not restart or recreate Dozzle.

Jenkins build #34 then completed the guarded deployment path:

```text
reviewed manifest validation
  -> source/host-key preflight
  -> read-only pre-approval inspection
  -> exact identity/deployment=false assertion
  -> human approval by james
  -> second read-only inspection
  -> exact zero-drift assertion
  -> executor credential reachability only after approval/zero drift
  -> arm exact update
  -> deploy exact candidate
  -> host-side runtime/health invariants PASS
  -> rollback skipped
  -> disarm one-shot authority
  -> Jenkins SUCCESS
```

Jenkins terminal evidence:

```text
STAGE 6 dozzle RESULT: DEPLOYED EXACT CANDIDATE AND DISARMED
Finished: SUCCESS
```

Post-deployment live verification proved:

```text
version=v10.9.0
running=true
restart=unless-stopped
image_id=sha256:88b0c06d1a3c881893d2162afa4b19d1b91262e1ae92a90e661d8ccc2a5549d9
configured_image=amir20/dozzle@sha256:7f01a2504f89788b60ad0efddd94472fd66f9a225c708356cdb815d9d8abd184
Docker connection=PASS
HTTP listener=:8080
```

The actual deployment stage recreates the target Dozzle container. Preparation, candidate acquisition, read-only inspection, human approval, zero-drift inspection and post-deployment closure must not recreate the container.

## P0 — Close Dozzle 10.9.0 into durable Stage 6 state

The runtime deployment is successful, but durable closure still needs to be completed before the service is treated as fully closed at `10.9.0`.

- [ ] Promote the exact successful Dozzle `10.9.0` immutable image into durable Git Compose authority.
- [ ] Synchronize reviewed authority without recreating the already-healthy Dozzle container.
- [ ] Promote/update the estate catalogue to Dozzle `10.9.0`.
- [ ] Generate/review/install the Dozzle `10.9.0` steady-state manifest.
- [ ] Run the non-mutating `VERIFY_CLOSED` path against the final promoted state.
- [ ] Require `SUCCESS_VERIFIED_CLOSED` or the current reviewed equivalent with no second recreation.
- [ ] Archive/record the final authority, catalogue, steady-state and verification evidence.

## P0 — Container-update documentation

- [ ] Update `homelab-container-version-control` README and Stage 6 end-to-end documentation with the successful Dozzle `10.9.0` Jenkins build #34 proof.
- [ ] Explicitly document that the target container is recreated only during `Deploy exact candidate`.
- [ ] Record that candidate acquisition changes only the Docker image cache and must not restart/recreate the service.
- [ ] Record the stale target-validator lesson: repository and installed Stage 6 framework components must be synchronized before inspection.
- [ ] Update the `home-lab-docs` Dozzle/service-update documentation where appropriate.

## P1 — Zabbix application acceptance

- [ ] Validate the missing PHP PostgreSQL module diagnosis on `zabbix-server-01`.
- [ ] Add the required PostgreSQL PHP support to the `zabbix_server` Ansible role rather than applying an undocumented manual fix.
- [ ] Validate PHP-FPM and Nginx after the role change.
- [ ] Confirm the Zabbix frontend accepts PostgreSQL and opens correctly.
- [ ] Re-run the relevant Ansible playbook and require `changed=0`, `unreachable=0`, `failed=0`.
- [ ] Re-run the one-button rebuild when appropriate to prove the permanent role fix survives clean reconstruction.

Tracked in:

```text
jrwroberts1976/proxmox#12
jrwroberts1976/home-lab-docs#56
```

## P1 — VM101 inventory naming cleanup

- [ ] Rename the Ansible inventory alias from `app-platform-01` to `zabbix-server-01` across all VM101 groups and references.
- [ ] Preserve the live guest hostname/IP/MAC identity.
- [ ] Run a full Ansible validation and require zero failures/unreachable hosts.
- [ ] Require a second run with `changed=0`.
- [ ] Update affected documentation.

Tracked in `jrwroberts1976/proxmox#13`.

## P1 — Stage 6 BAU hardening

Do not let the successful Dozzle deployment hide the manual preparation work that was required to reach it.

- [ ] Fix the manifest-parameter whitespace normalization bug so Jenkins passes the already-trimmed manifest name into the preparation helper.
- [ ] Formalize target-side reviewed manifest synchronization as a controlled generic prerequisite.
- [ ] Formalize reviewed Stage 6 validator/inspector synchronization so stale installed helpers fail with a clear repair path before a service update begins.
- [ ] Move exact target candidate acquisition fully into the restricted Jenkins preparation path where the reviewed contract allows it.
- [ ] Preserve the rule that candidate acquisition cannot expose arm/deploy/rollback/disarm authority.
- [ ] Add deterministic host selection/disambiguation so the manifest preparer is not implicitly TestServer-only.
- [ ] Keep deployment `--pull never` and exact immutable candidate enforcement.

## P2 — Legacy CentOS 7 upgrade investigation

- [ ] Inventory the unsupported CentOS 7 server and record application/service dependencies before any upgrade attempt.
- [ ] Confirm backup/rollback/recovery options.
- [ ] Validate the exact supported Leapp/ELevate migration path while preserving the requirement that the target remains within the CentOS family.
- [ ] Do not begin an irreversible OS upgrade until repository, boot, package and application blockers are understood.

## P2 — Raspberry Pi offline SSH/root recovery

- [ ] Continue the offline Pi root-login recovery from the mounted root filesystem.
- [ ] Resolve the chroot validation failure caused by missing `/dev/null` or required pseudo-filesystem/device setup.
- [ ] Re-run `sshd -t` against the mounted installation.
- [ ] Prove the intended `PermitRootLogin`/authentication settings without weakening unrelated SSH controls.

## P2 — LARC service deep dive

- [ ] Continue the read-only LARC service/configuration audit from the mounted filesystem.
- [ ] Map each LARC systemd service to its executable, environment/config files, dependencies, data paths and startup ordering.
- [ ] Document the operational purpose and recovery considerations before making any changes.

## P2 — Existing monitoring/backlog work

- [ ] Finish the Grafana Patch collector stale alert investigation without editing Grafana SQLite directly.
- [ ] Reconcile live/Git drift for the Linux Host Down alert rule.
- [ ] Continue the plan to make `ids-01` the single Prometheus authority only after scrape/consumer parity is proven.
- [ ] Continue remaining Proxmox BIOS/security/monitoring follow-up where still genuinely incomplete.
- [ ] Continue the Pi-hole policy-alert latency improvement runbook when it is selected as the active workstream.

## P3 — Provisioning-platform project

After the current Zabbix solution is closed, continue design of the reusable provisioning platform:

- Proxmox, Azure and AWS provider support;
- reusable OpenTofu provider modules and common Ansible roles;
- web-based operator request flow;
- collision/identity validation;
- stable generated MAC lifecycle for new Proxmox VMs;
- provider/Vault secret isolation;
- audit trail without secret leakage.

Tracked in:

```text
jrwroberts1976/proxmox#11
jrwroberts1976/home-lab-docs#57
```

## Change-control rules for today

1. Preserve fail-closed behaviour; do not bypass Stage 6 gates to make a pipeline green.
2. Treat successful runtime deployment and durable closure as separate evidence gates.
3. Do not recreate an already-healthy container during authority/catalogue/steady-state closure.
4. Keep Infrastructure-as-Code authoritative for VM/application configuration.
5. Put permanent guest fixes into Ansible rather than leaving manual configuration behind.
6. Require idempotence for completed Ansible work.
7. Keep secrets out of Git, logs and archived evidence.
8. Keep repositories clean: coherent branches, reviewed changes, merge completed work, then remove stale branches where safe.
9. Update this file as work completes and move only genuinely unfinished tasks forward.

## Daily summary

### Completed today

- Dozzle target-side Stage 6 preparation was reset and repeated from a known-good state.
- The installed stale Stage 6 validator was synchronized to the reviewed repository implementation.
- Dozzle `10.9.0` exact ARM64 candidate was acquired and identity-verified without container mutation.
- Jenkins build #34 passed pre-approval inspection, explicit approval, post-approval zero-drift inspection, exact deployment, host-side acceptance and disarm.
- Dozzle is live and healthy on exact immutable `10.9.0`.

### Carried forward / active

- Complete Dozzle `10.9.0` durable Stage 6 closure and documentation.
- Fix the Zabbix PostgreSQL PHP frontend support permanently in Ansible.
- Complete VM101 inventory naming cleanup.
- Harden Stage 6 target preparation into the normal generic BAU path.
- Continue other P2/P3 work only after the active P0/P1 items are stable.
