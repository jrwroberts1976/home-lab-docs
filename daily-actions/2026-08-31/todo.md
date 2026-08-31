# TODO — 31 August 2026

> **Day status: CLOSED — 10:12 BST.**
>
> All planned P0 work for today is complete. Remaining work has been deliberately carried forward and is **not active for 31 August**. No further work is required today unless the day is explicitly reopened.

## P0 — Complete Proxmox host observability

- [x] Add `PROXMOX` (`192.168.2.70:9100`) to the Prometheus instance on `ids-01` used by Grafana and prove `up{job="linux-hosts",host="PROXMOX"} = 1`.
- [x] Prove the standard Linux host CPU, memory, disk and host-down alert rules cover `PROXMOX` through the live Grafana alert database and ids-01 Prometheus datasource.
- [x] Correct the Network Hosts identity for MAC `80:E8:2C:1C:55:D2` from `APL-SD-C9243FXC` to `PROXMOX` without creating a duplicate device.
- [x] Install/configure Alloy on `PROXMOX` through the Git-controlled `jrwroberts1976/proxmox` Ansible path.
- [x] Forward the Proxmox systemd journal to Loki on `ids-01` with `host="PROXMOX"`, `role="proxmox-host"`, `job="systemd-journal"` and prove ingestion with unique marker `PROXMOX_ALLOY_TEST_1788157720`.
- [x] Record the completed Proxmox observability evidence in today's daily actions and infrastructure topology.

## Additional closeout completed today

- [x] Recover the secondary Pi-hole after its post-reboot Docker network/port attachment failure and restore DNS, Unbound reachability, Nebula Sync and Pi-hole health metrics.
- [x] Add and enable the `pihole-secondary-reconcile.service` boot reconciliation unit so the secondary Pi-hole is recreated onto the expected Compose network after future boots.
- [x] Merge all outstanding pull requests targeting `main` across `jrwroberts1976/proxmox`, `jrwroberts1976/home-lab-docs` and `jrwroberts1976/engineering-portfolio`.
- [x] Resolve overlapping README/documentation conflicts without dropping previously merged content.
- [x] Confirm the three repositories have no remaining open pull requests targeting `main`.

## Carried forward — not active today

- [ ] Finish the Grafana **Patch collector stale** alert investigation. Current `homelab_patch_check_timestamp_seconds` data is fresh on all monitored hosts; inspect the live Grafana alert rule/expressions and correct the rule or label preservation as required. Do not edit Grafana SQLite directly.
- [ ] Reconcile Grafana alert-rule Git/runtime drift: the live `Linux Host Down` rule is `up{job="linux-hosts"} == 0`, while the current `jrwroberts1976/grafana-alerting` source still contains `min(up{job="linux-hosts"}) < 1`.
- [ ] Make `ids-01` the single Prometheus authority and retire the Prometheus instance on TestServer.
  - Put the `ids-01` Prometheus configuration under Git authority first.
  - Compare all TestServer and `ids-01` scrape jobs/targets and migrate anything missing.
  - Restore `debian-iac-test-01` (`192.168.2.120:9100`) to ids-01 Prometheus if it remains absent.
  - Validate and prove Grafana, alerts and dashboards against `ids-01` Prometheus.
  - Prove no consumers still depend on TestServer `:9090`.
  - Stop, observe, then remove TestServer Prometheus only after parity is proven.
- [ ] Complete the separate VM 100 backup/restore proof and later IaC destroy/rebuild/equivalence proof.

## Closeout

The 31 August task list is closed. The unchecked items above are future-session work and should be reviewed when the next homelab working session starts rather than treated as overdue work for today.
