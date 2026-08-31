# TODO — 31 August 2026

> **Day status: CLOSED — final evening closeout.**
>
> The original planned P0 work was completed and closed at 10:12 BST. The day was later reopened for a separate Stage 6 container-version-control session. That evening session is also now closed. Remaining work below is deliberately carried forward and is **not active for 31 August**.

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
- [x] Confirm the three repositories had no remaining open pull requests targeting `main` at the original daytime closeout.

## Evening Stage 6 container-update work — completed

- [x] Prove the generic multi-host Stage 6 Jenkins deployment path with Loki 3.7.7 on `ids-01`.
- [x] Extend the generic Stage 6 framework with reviewed `container-http` health support.
- [x] Fix the generic runtime-user handling so an explicitly reviewed empty Docker `Config.User` remains valid.
- [x] Requalify Dozzle as a generic Stage 6 service with a read-only Docker socket and direct container HTTP health.
- [x] Acquire and verify the exact immutable Dozzle 10.8.0 candidate without mutating any container.
- [x] Deploy Dozzle 10.8.0 through Jenkins build #13 with human approval, zero-drift proof and protected-container checks.
- [x] Diagnose the post-deployment disarm failure as missing `container-http` support in the transition helper rather than an application failure.
- [x] Fix and merge the transition-helper `container-http` terminal-health path.
- [x] Disarm the already-deployed Dozzle update without a second container recreation.
- [x] Promote `docker-env` Dozzle authority to the exact immutable 10.8.0 image and synchronise both live/root-owned authority checkouts without recreating Dozzle.
- [x] Promote the Dozzle catalogue entry to `managed-tested` / `inspect_ready=true`.
- [x] Add and install the Dozzle 10.8.0 steady-state manifest.
- [x] Run the final read-only steady-state inspection and reach `SUCCESS_CLOSED` for Dozzle.
- [x] Collect the initial read-only Alloy Stage 6 requalification evidence.
- [x] Stop before Alloy candidate acquisition or deployment.
- [x] Record the detailed evening evidence in `stage6-container-update-closeout.md`.

## Carried forward — next Stage 6 session

- [ ] Add a dedicated restricted Jenkins candidate-acquisition identity/forced-command route. It must be able to invoke only the reviewed candidate-acquisition helper and must not expose deploy/rollback/arm/disarm authority.
- [ ] Move exact immutable candidate pulling into Jenkins before human approval. The candidate pull must verify digest/platform/local image identity and prove container state is unchanged.
- [ ] Keep the powerful Stage 6 executor credential unavailable until after approval and zero-drift reinspection.
- [ ] Add a non-mutating `VERIFY_CLOSED` / equivalent Jenkins action for already-completed services.
- [ ] Test that verification action against Dozzle without recreating or restarting it; require a clear `SUCCESS_VERIFIED_CLOSED` result.
- [ ] Do **not** rerun the consumed Dozzle 10.8.0 deployment.
- [ ] Resume Alloy only after the Dozzle Jenkins closed-state proof passes.
- [ ] Use Alloy as the first fresh update intended to prove the complete Jenkins path: Jenkins-owned candidate pull -> approval -> deployment -> disarm -> authority -> catalogue -> steady state -> `SUCCESS_CLOSED`.
- [ ] Continue requalifying previously deferred services against the actual Stage 6 framework rather than preserving old exclusions without live testing.

## Other carried-forward work — not active today

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
