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

## P1 — Zabbix CT201 LXC build — COMPLETE

The VM101 application workstream was retired and replaced by the native CT201 LXC proof-of-pattern.

Completed and validated today:

```text
CT201 zabbix-lxc-01
  -> Debian 13 unprivileged LXC
  -> hardening
  -> unattended-upgrades
  -> Alloy
  -> PostgreSQL 17
  -> TimescaleDB
  -> Nginx
  -> Zabbix Server 7.0
  -> Zabbix Agent 2
  -> PHP 8.4 FPM frontend
  -> standard Zabbix schema
  -> vendor TimescaleDB conversion
  -> locale correction
  -> idempotence PASS
```

Final validated service state:

```text
zabbix_server=ACTIVE
zabbix_agent2=ACTIVE
zabbix_frontend=ACTIVE
nginx=ACTIVE
php_fpm=ACTIVE
postgresql=HEALTHY
timescaledb_extension=ACTIVE
zabbix_timescaledb_schema=CONVERTED
vendor_hypertables=COMPLETE
alloy=HEALTHY
systemd=HEALTHY
failed_units=ZERO
ansible_idempotence=PASS
```

Frontend:

```text
http://192.168.2.184:8080/
```

A pre-conversion PostgreSQL dump was retained on CT201:

```text
/var/backups/zabbix/zabbix-pre-timescaledb-20260903-230800.dump
```

### Locale correction — COMPLETE

The Zabbix frontend reported that `en_US` was unavailable. The permanent Ansible fix now generates both:

```text
en_GB.UTF-8
en_US.UTF-8
```

while keeping the server default:

```text
LANG=en_GB.UTF-8
LANGUAGE=en_GB:en
```

The frontend is running normally after the fix.

### Frontend IaC / Geomap — DEFERRED

The desired Geomap state is already in Git:

```text
Location:  BH22 8QL, West Parley, Dorset, UK
Latitude:  50.79039
Longitude: -1.890218
Zoom:      15
Dashboard: Global view
```

The frontend-IaC helper could not authenticate to the Zabbix API. Read-only database inspection showed:

```text
username=Admin
attempt_failed=4
attempt_ip=192.168.2.220
```

No further password guesses were made.

Next safe action is controlled Admin credential recovery/rotation, storage of the unique credential in Ansible Vault, API login proof, Geomap application and a second `changed=0` frontend-IaC run.

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

- Dozzle `10.9.0` exact candidate deployment passed the guarded Stage 6 Jenkins path and live runtime validation.
- Container-update documentation was updated with the Dozzle deployment/recreation-boundary evidence.
- VM101 was superseded as the active Zabbix target by native Proxmox LXC CT201.
- CT201 infrastructure, hardening, unattended upgrades and Alloy observability were completed.
- PostgreSQL 17 and the `zabbix` database were configured with localhost-only exposure.
- TimescaleDB was installed, preloaded and enabled.
- Nginx, PHP 8.4 FPM, Zabbix Server 7.0 and Zabbix Agent 2 were deployed.
- The standard Zabbix schema was loaded.
- The packaged Zabbix TimescaleDB conversion completed and all vendor-declared hypertables were verified.
- Pre-conversion database backup was retained at `/var/backups/zabbix/zabbix-pre-timescaledb-20260903-230800.dump`.
- The Zabbix locale warning was permanently fixed in Ansible by managing both `en_GB.UTF-8` and `en_US.UTF-8`.
- Zabbix application, database, frontend, Alloy and systemd health gates passed.
- Relevant Ansible roles passed second-run idempotence with `changed=0`.
- Proxmox documentation/runbook authority was updated for CT201.

### Carried forward

- Recover/rotate the Zabbix `Admin` credential without further guessing and store the unique credential in Ansible Vault.
- Prove Zabbix API login using the Vault-backed credential.
- Apply the existing BH22 8QL frontend/Geomap IaC and require a second run with `changed=0`.
- Run final CT201/OpenTofu zero-drift and end-to-end acceptance proof.
- Close/merge the `feature/zabbix-lxc-foundation` branch when all final frontend/drift gates are green.
- Complete remaining Dozzle durable Stage 6 closure/BAU hardening where still outstanding.
- Continue other P2/P3 backlog only after the active Zabbix closure work is complete.
