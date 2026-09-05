# TODO — 05 September 2026

> **Day status: ACTIVE.**
>
> Zabbix platform build/onboarding is closed. Active engineering work moves to Container Version Control Stage 6.

## P1 — Container Version Control Stage 6 — ACTIVE

Already proven:

- [x] Generic non-mutating `VERIFY_CLOSED` path merged.
- [x] Dozzle closed-state verification proved without recreation.
- [x] Dozzle 10.9.0 deployed through the generic Stage 6 Jenkins path.
- [x] Dozzle 10.9.0 durable Compose authority, estate catalogue and steady-state closure completed.
- [x] Reviewed TestServer Alloy 1.19.2 Stage 6 manifest exists.

Next:

- [x] Merge source authority for the dedicated restricted candidate-acquisition SSH/sudo/authorized-key boundary through `homelab-container-version-control#115`.
- [x] Require the acquisition wrapper to accept only a reviewed service name and derive the immutable candidate from installed reviewed authority.
- [x] Install the live `homelab-stage6-acquirer` identity from merged authority and prove the forced-command/sudo boundary.
- [x] Store the proven dedicated acquirer private key in Jenkins credentials, prove the stored credential over real SSH, and remove all loose temporary key material.
- [ ] Run the first merged Jenkins-owned candidate-acquisition proof. Alloy 1.19.2 is already cached, so Alloy can prove safe/idempotent acquisition with zero container mutation; reserve the fresh absent→present cache-mutation proof for a later genuinely uncached candidate.
- [x] Wire the proven acquirer credential into the Git-controlled Jenkins pipeline before pre-approval inspection, with raw-output preservation and exact JSON acquisition assertions.
- [ ] Keep the full deployment executor credential unavailable until human approval and exact zero-drift reinspection.
- [ ] Replace free-text `STAGE6_MANIFEST` entry with reviewed Git-controlled service discovery/selection.
- [ ] Complete the fail-closed Jenkins pre-acquisition live-authority gate before the first Alloy Jenkins run. PR #118 framework is now installed and source-vs-live proof PASS on TestServer with backup retained at `/var/backups/homelab-stage6/live-authority-20260905T125635Z`; next wire Jenkins comparison before acquirer credential use.
- [ ] Use TestServer Alloy 1.19.2 as the next fresh end-to-end Stage 6 update after those controls pass.
- [ ] Keep normal BAU free from manual SSH/manual pull/manual Compose/catalogue closure steps.

## Zabbix — CLOSED / BAU

- [x] CT201 Zabbix platform.
- [x] PostgreSQL/TimescaleDB/Nginx/PHP.
- [x] Vault-backed Admin/API authority.
- [x] Grafana ↔ Zabbix integration.
- [x] Proxmox VE onboarding.
- [x] Linux Agent 2 batch: ids-01, TestServer, DietPi and media-01.
- [x] Live item collection and interface availability validation.
- [x] Stale Zabbix issues/documentation reconciled.
- [ ] BAU only: correct Grafana token materialisation ownership automatically (UID 472, mode 0400) before future Grafana recreation.
- [ ] BAU only: review harmless interface-speed unsupported items only if they become noisy.

## P2 — Proxmox BIOS / PCIe follow-up

- [ ] Upgrade HP ProDesk 400 G4 DM BIOS when convenient.
- [ ] Reboot and establish a fresh PCIe AER baseline.
- [ ] If correctable `RxErr` continues, inspect/reseat the NVMe connection before considering power-management workarounds.

## P2/P3 — Other carried backlog

- [ ] Re-baseline the next overnight Greenbone run after duplicate-task removal.
- [ ] Grafana Patch collector stale alert.
- [ ] ids-01 Prometheus authority parity work.
- [ ] Pi-hole policy-alert latency improvement.
- [ ] Full solution/hosting architecture review.
- [ ] Reusable Proxmox/Azure/AWS provisioning platform when selected.
