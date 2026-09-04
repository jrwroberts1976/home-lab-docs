# TODO — 05 September 2026

> **Day status: PLANNED.**
>
> Continue the `k3s-node-01` → `media-01` cleanup, complete monitoring retirement, rebuild backup coverage through IaC, and review the Grafana dashboard estate for stale targets and drift.

## P1 — media-01 backup rebuild

- [ ] Inventory every backup, replication, restore-test and monitoring dependency that previously referenced `k3s-node-01`.
- [ ] Decide the required `media-01` backup scope: OS/config, Kodi configuration, Ansible-managed files, and any future media paths once data migration resumes.
- [ ] Rebuild the backup client/replication configuration for `media-01` using Ansible/IaC rather than manual configuration.
- [ ] Replace old `k3s-node-01` hostnames, paths and labels with `media-01` where the backup function is still required.
- [ ] Retire the old `homelab-replication-k3s.service` and `homelab-replication-k3s.timer` only after their replacement requirements have been captured.
- [ ] Create the replacement `media-01` backup service/timer if ids-01 replication to this host remains part of the target architecture.
- [ ] Validate backup credentials/repository access without exposing secret material.
- [ ] Run a controlled first backup and verify a new snapshot is created successfully.
- [ ] Perform a controlled restore test and record evidence.
- [ ] Restore Prometheus backup metrics using the `media-01` identity.
- [ ] Update Grafana backup dashboards and alerts so they no longer expect `k3s-node-01`.
- [ ] Preserve historical `k3s-node-01` backup metrics and snapshots as historical evidence; do not delete historical Prometheus/Loki data solely because the host was renamed/rebuilt.
- [ ] Document the final `media-01` backup/recovery architecture and operating procedure in Git.

## P1 — retire stale k3s monitoring identity

- [ ] Update the Prometheus Linux host target for `192.168.2.195:9100` from `host=k3s-node-01`, `role=k3s-node` to the approved `media-01` identity/role.
- [ ] Retire the dead `kubernetes-state` target at `192.168.2.211:8080` if no replacement k3s cluster exists.
- [ ] Retire the dead WUD target at `192.168.2.195:3002` unless WUD is intentionally rebuilt on `media-01`.
- [ ] Reconcile the blackbox ICMP target so `192.168.2.195` is no longer presented as `k3s-node-01` / Kubernetes.
- [ ] Retire the `K3s Image Inventory Failed` alert and any k3s-specific collectors that no longer have a valid workload.
- [ ] Preserve historical Prometheus/Loki telemetry for the retired `k3s-node-01` identity.
- [ ] Prove no stale `k3s-node-01` active targets remain after the change.

## P1 — Grafana dashboard estate review

- [ ] Inventory every Grafana dashboard and record purpose, datasource(s), source/owner and whether it is still required.
- [ ] Check every dashboard for retired hosts/services, especially `k3s-node-01`, VM101 and anything replaced during the Proxmox/Zabbix work.
- [ ] Verify `media-01` replaces `k3s-node-01` only where appropriate; retire genuinely k3s-specific dashboards/panels rather than renaming them blindly.
- [ ] Review all panels for broken queries, `No data`, stale metrics, invalid variables and obsolete labels.
- [ ] Review Prometheus queries for correct `host`, `instance`, `job`, `role` and current label usage.
- [ ] Review Loki panels for current hostnames, jobs and log labels.
- [ ] Review Zabbix-backed panels and confirm intended hosts/templates/items are represented correctly.
- [ ] Identify duplicate dashboards/panels and consolidate where sensible.
- [ ] Remove dashboards that represent retired functionality rather than keeping dead monitoring.
- [ ] Review dashboard variables/drop-downs so retired hosts no longer appear as current choices.
- [ ] Review time ranges, refresh intervals, query cost, units, legends, titles, descriptions and thresholds.
- [ ] Review all Grafana alert rules alongside their associated dashboards for stale targets, incorrect severity and obsolete services.
- [ ] Confirm Linux Host Down retains the corrected logic and Host + Instance annotations.
- [ ] Confirm PROXMOX correctable PCIe AER remains warning-level rather than critical.
- [ ] Check dashboard provisioning/Git authority and identify any live-vs-Git drift.
- [ ] Put retained dashboards under clear Git/IaC authority where practical.
- [ ] Produce a final dashboard register with disposition: `KEEP`, `FIX`, `CONSOLIDATE`, or `RETIRE`.
- [ ] Complete a final Grafana acceptance pass with no unexplained broken panels, stale host references or obsolete firing alerts.

## P0/P1 — Proxmox hardware maintenance

- [ ] Upgrade HP ProDesk 400 G4 DM BIOS Q23 from `02.07.00` to the current verified HP Q23 release during the planned workshop maintenance window.
- [ ] Reboot and establish a fresh PCIe AER baseline.
- [ ] If correctable NVMe `RxErr` events recur, reseat the NVMe and inspect the M.2 connection before testing power-management workarounds.

## P2 — ids-01 overnight Greenbone re-baseline

- [ ] Review the next overnight Greenbone run after duplicate-scan cleanup.
- [ ] Confirm only one `Daily managed Linux hosts` scan ran.
- [ ] Confirm ids-01 CPU usage is materially lower than the 04 September duplicate-scan event.

## P1/P2 — remaining monitoring / platform backlog

- [ ] Update the ids-01 Grafana-Zabbix deployment helper so token materialisation preserves owner UID `472` and mode `0400` automatically.
- [ ] Grafana Patch collector stale alert investigation.
- [ ] ids-01 Prometheus authority parity work.
- [ ] Pi-hole policy-alert latency improvement.
- [ ] Complete any genuinely outstanding Dozzle `10.9.0` durable closure and continue Stage 6 BAU hardening.
- [ ] Continue repository/issue cleanup only for work that is still genuinely outstanding after today’s merges.
