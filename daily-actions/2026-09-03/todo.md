# TODO — 03 September 2026

> **Day status: ACTIVE.**
>
> Dozzle `10.9.0` deployment itself is already complete and must not be carried as outstanding. The active container-update work is durable closure and BAU hardening.

## P0 — Finish Dozzle 10.9.0 closure

- [ ] Promote exact successful Dozzle `10.9.0` immutable image into durable Git Compose authority.
- [ ] Synchronize authority without recreating/restarting the healthy container.
- [ ] Promote the estate catalogue to `10.9.0`.
- [ ] Generate/review/install the `10.9.0` steady-state manifest.
- [ ] Run non-mutating `VERIFY_CLOSED` and require final closed-state success.
- [ ] Record final deployment/closure evidence.

## P0 — Container-update documentation — COMPLETE

- [x] Add Dozzle `10.9.0` Jenkins build #34 to the container-version-control documentation.
- [x] Document the exact recreation boundary: only `Deploy exact candidate` recreates the target container.
- [x] Document that preparation, candidate acquisition, inspection, approval, zero-drift inspection and closure must not recreate it.
- [x] Document the stale installed-validator lesson and required target framework synchronization.
- [x] Update Dozzle/service-update documentation in `home-lab-docs`.

Merged documentation:

```text
homelab-container-version-control PR #113
home-lab-docs PR #63
```

## P1 — Zabbix VM101 application acceptance

- [ ] Fix PostgreSQL PHP support in the `zabbix_server` Ansible role.
- [ ] Validate Zabbix frontend, PHP-FPM and Nginx.
- [ ] Require Ansible idempotence after the fix.
- [ ] Re-prove through the clean rebuild path when appropriate.

## P1 — VM101 inventory cleanup

- [ ] Rename Ansible alias `app-platform-01` -> `zabbix-server-01` everywhere relevant.
- [ ] Validate all VM101 groups/references.
- [ ] Require `unreachable=0`, `failed=0`, then a second run with `changed=0`.

## P1 — Stage 6 BAU hardening

- [ ] Fix trimmed-manifest-name propagation into the missing-manifest preparation helper.
- [ ] Automate/formalize reviewed target manifest synchronization.
- [ ] Automate/formalize reviewed validator/inspector synchronization or preflight proof.
- [ ] Move exact target candidate acquisition into the restricted Jenkins path where appropriate.
- [ ] Add deterministic host selection/disambiguation beyond the current TestServer default.
- [ ] Preserve separate candidate-acquisition and deployment authority boundaries.
- [ ] Preserve `--pull never`, immutable refs, approval and zero-drift gates.

## P2 — Monitoring backlog

- [ ] Finish Grafana Patch collector stale alert investigation.
- [ ] Reconcile Linux Host Down live/Git rule drift.
- [ ] Continue ids-01 single-Prometheus-authority work only after parity proof.
- [ ] Continue Pi-hole policy-alert latency improvement when selected.

## P3 — Provisioning platform

- [ ] Continue multi-cloud/web provisioning design after Zabbix closes.
- [ ] Retain generated stable MAC lifecycle for new Proxmox VM instances.
- [ ] Keep provider/Vault secrets outside UI/logs/Git.

## Already completed today — do not reopen

- [x] Reset Dozzle Stage 6 preparation to known-good state.
- [x] Synchronize reviewed Stage 6 validator on TestServer.
- [x] Install/validate reviewed Dozzle `10.8.0 -> 10.9.0` transition manifest.
- [x] Acquire exact Dozzle `10.9.0` ARM64 candidate without container mutation.
- [x] Jenkins build #34 approval and zero-drift gates passed.
- [x] Exact Dozzle `10.9.0` candidate deployed successfully.
- [x] Rollback skipped because acceptance passed.
- [x] One-shot deployment authority disarmed.
- [x] Post-deploy exact image identity and Dozzle `v10.9.0` logs verified.
- [x] Container-update documentation updated and merged to `main` in both documentation repositories.
