# TODO — 31 August 2026

## P0 — Complete Proxmox host observability

- [ ] Add `PROXMOX` (`192.168.2.70:9100`) to the Prometheus instance on `ids-01` used by Grafana and prove `up{job="linux-hosts",host="PROXMOX"} = 1`.
- [ ] Prove the standard Linux host CPU, memory, disk and host-down alert rules cover `PROXMOX`.
- [ ] Correct the Network Hosts identity for MAC `80:E8:2C:1C:55:D2` from `APL-SD-C9243FXC` to `PROXMOX` without creating a duplicate device.
- [ ] Install/configure Alloy on `PROXMOX` through a controlled, documented configuration path.
- [ ] Forward the Proxmox systemd journal to Loki on `ids-01` with `host="PROXMOX"`, `role="proxmox-host"`, `job="systemd-journal"` and prove ingestion with a unique test journal marker.
- [ ] Record the completed Proxmox observability evidence in today's daily actions and infrastructure topology.

## Carried forward — observability consolidation

- [ ] Make `ids-01` the single Prometheus authority and retire the Prometheus instance on TestServer.
  - Put the `ids-01` Prometheus configuration under Git authority first.
  - Compare all TestServer and `ids-01` scrape jobs/targets and migrate anything missing.
  - Validate and prove Grafana, alerts and dashboards against `ids-01` Prometheus.
  - Prove no consumers still depend on TestServer `:9090`.
  - Stop, observe, then remove TestServer Prometheus only after parity is proven.
