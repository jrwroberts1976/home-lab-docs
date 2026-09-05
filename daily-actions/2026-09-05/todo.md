# TODO — 05 September 2026

> **Day status: ACTIVE.**
>
> Zabbix platform build/onboarding is closed. Active engineering work moves to Container Version Control Stage 6.

## P1 — Container Version Control Stage 6 — ACTIVE

- [ ] Implement a dedicated restricted candidate-acquisition SSH identity/forced-command route for Jenkins.
- [ ] Require the acquisition wrapper to accept only a reviewed service name and derive the immutable candidate from installed reviewed authority.
- [ ] Prove candidate acquisition changes only the local image cache and does not create, restart, recreate or remove containers.
- [ ] Archive structured candidate-acquisition evidence in Jenkins.
- [ ] Keep the full deployment executor credential unavailable until human approval and exact zero-drift reinspection.
- [ ] Add the non-mutating `VERIFY_CLOSED` action.
- [ ] Run Dozzle through `VERIFY_CLOSED` and require `SUCCESS_VERIFIED_CLOSED` without recreation.
- [ ] After those controls pass, use TestServer Alloy as the first fresh full Stage 6 update intended to reach `SUCCESS_CLOSED`.
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
