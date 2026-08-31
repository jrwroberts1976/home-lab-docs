# Daily Homelab Actions — 31 August 2026

> **Day closed at 10:12 BST.** Planned P0 work is complete. Remaining monitoring/consolidation work is deliberately carried forward and is not active work for the rest of 31 August.

## Proxmox host observability

### Prometheus metrics — completed

The physical Proxmox host `PROXMOX` (`192.168.2.70`) already had `prometheus-node-exporter` installed, enabled and listening on port `9100`.

The Grafana-facing Prometheus instance on `ids-01` was confirmed to use:

```text
/home/james/docker/data/monitoring/prometheus/prometheus.yml
/home/james/docker/data/monitoring/prometheus/linux-hosts.yml
```

`PROXMOX` was added to the `linux-hosts` file with:

```yaml
- targets:
  - "192.168.2.70:9100"
  labels:
    env: homelab
    host: PROXMOX
    role: proxmox-host
    os: proxmox
```

The active configuration passed `promtool` validation, Prometheus was reloaded with `SIGHUP`, and the ids-01 Prometheus API returned:

```text
linux-hosts  192.168.2.70:9100  PROXMOX  proxmox-host  1
```

Grafana Explore, using the ids-01 Prometheus datasource, also returned the live PROXMOX series with `up=1`.

This proves that the Prometheus instance used by Grafana is scraping the Proxmox host successfully.

### Network discovery identity — completed

The existing network-discovery collector on `ids-01` already discovered the Proxmox device by stable MAC identity:

```text
MAC:    80:E8:2C:1C:55:D2
IP:     192.168.2.70
Vendor: Hewlett Packard
```

The discovered hostname was previously `APL-SD-C9243FXC`.

A manual hostname override was added to `/usr/local/bin/homelab-network-discovery.py` using the collector's existing override mechanism:

```python
"80:E8:2C:1C:55:D2": "PROXMOX",
```

After a successful discovery run, the ids-01 Prometheus API returned:

```text
80:E8:2C:1C:55:D2  192.168.2.70  PROXMOX  Hewlett Packard  1
```

The Network Hosts dashboard reconciler completed successfully and generated:

```text
/home/james/docker/data/monitoring/grafana/provisioning/network-hosts-json/generated-hosts/proxmox-1c55d2.json
```

This proves the Proxmox device is represented in the Network Hosts dashboard set with the correct friendly name and without creating a second device identity.

### Dedicated Proxmox Ansible access — completed

A dedicated Ed25519 automation key was created on TestServer for Proxmox management:

```text
~/.ssh/proxmox-automation
~/.ssh/proxmox-automation.pub
```

Fingerprint:

```text
SHA256:R/R28pDQBtG+/YHEH0R3OdrJ5nnc+uXKSrC4Jb5nPao
```

The public key was installed for `root@192.168.2.70`. Non-interactive access was proven with:

```text
host=PROXMOX user=root
```

The key is dedicated to Proxmox automation and is referenced by the Git-controlled Ansible inventory. The private key itself is not stored in Git.

### Alloy and Loki — completed

The Proxmox repository branch `iac/bootstrap-opentofu` was extended with a separate physical-host observability path rather than reusing the VM-specific baseline.

Git-controlled additions include:

```text
ansible/inventories/lab.yml
ansible/files/alloy/proxmox-host.alloy
ansible/playbooks/proxmox-host-observability.yml
```

The inventory now contains a `proxmox_hosts` group for:

```text
PROXMOX -> 192.168.2.70
ansible_user=root
ansible_ssh_private_key_file=/home/james/.ssh/proxmox-automation
```

The dedicated playbook installs the Grafana APT repository and Grafana Alloy, grants journal access, deploys the Proxmox-specific Alloy configuration and enables the service.

Pre-change controls passed:

```text
ansible-playbook ... --syntax-check
ansible ... PROXMOX -m ansible.builtin.ping
ansible-playbook ... --check --diff
```

The live Ansible deployment completed with:

```text
PROXMOX : ok=10 changed=6 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

Post-deployment runtime proof:

```text
enabled
active
alloy, version v1.19.2
```

The Proxmox Alloy configuration forwards the systemd journal to Loki on `ids-01` using:

```text
host="PROXMOX"
role="proxmox-host"
job="systemd-journal"
```

A unique journal marker was emitted on the Proxmox host:

```text
PROXMOX_ALLOY_TEST_1788157720
```

A Loki query on `ids-01` for the Proxmox labels returned the same marker:

```text
PROXMOX_ALLOY_TEST_1788157720
```

This proves the complete logging path:

```text
PROXMOX journal -> Alloy -> ids-01 Loki
```

### Grafana host alert coverage — completed

The live Grafana database on `ids-01` contains the four generic infrastructure alerts:

```text
High CPU Usage
High Memory Usage
Linux Host Down
Low Disk Space
```

The live rules use the ids-01 Prometheus `linux-hosts` job, so the `PROXMOX` target is included automatically.

PROXMOX was separately proved to expose the required node-exporter data:

- `node_cpu_seconds_total`: 48 matching time series;
- `node_memory_MemTotal_bytes`: present;
- root filesystem metrics for `mountpoint="/"`: present.

The live alert logic was inspected read-only from Grafana's SQLite database.

CPU uses a three-stage Grafana expression chain:

```text
A: 100 - (avg by(host) (rate(node_cpu_seconds_total{job="linux-hosts",mode="idle"}[5m])) * 100)
B: reduce A using last
C: threshold B > 90
for: 10 minutes
```

Memory uses:

```promql
100 * (1 - (node_memory_MemAvailable_bytes{job="linux-hosts"} / node_memory_MemTotal_bytes{job="linux-hosts"})) > 90
```

Disk uses the root filesystem:

```promql
100 - ((node_filesystem_avail_bytes{job="linux-hosts",fstype!="tmpfs",mountpoint="/"} / node_filesystem_size_bytes{job="linux-hosts",fstype!="tmpfs",mountpoint="/"}) * 100) > 85
```

Host down uses:

```promql
up{job="linux-hosts"} == 0
```

The live Host Down expression preserves the `host` label and therefore identifies `PROXMOX` specifically if its exporter becomes unavailable.

This completes the Proxmox CPU, memory, disk and host-down alert-coverage gate.

### Grafana alert Git/runtime drift — carried forward

The active Grafana alert rules are stored in Grafana's SQLite database; the mounted file-provisioning directory currently contains Pi-hole alert files only.

A drift was found between the live `Linux Host Down` rule and `jrwroberts1976/grafana-alerting`:

```text
live Grafana: up{job="linux-hosts"} == 0
Git source:   min(up{job="linux-hosts"}) < 1
```

The live expression is the desired per-host behaviour. Git/runtime authority should be reconciled separately so the repository represents the deployed rule accurately.

### Documentation — completed and merged

The 31 August documentation work includes:

- `infrastructure-topology.md` — host/service placement, authority and data-flow topology;
- `scripts/homelab-network-discovery.md` — detailed documentation for the LAN discovery collector;
- `daily-actions/2026-08-31/todo.md` — current Proxmox and Prometheus-consolidation work;
- this daily action record.

The documentation was merged to `home-lab-docs/main` through PR #53.

## Secondary Pi-hole post-reboot incident — completed

After the reboot, `pihole-secondary` retained its configured Compose `NetworkMode` and host port configuration but had no runtime Docker network attachment and no runtime published ports. This prevented resolution of the `unbound` alias and removed the host DNS/HTTP publication even though the container itself was present.

The secondary Pi-hole was force-recreated through its Compose project, restoring:

- attachment to `pihole-secondary_default`;
- resolution of the `unbound` service alias;
- direct Unbound DNS on port `5335`;
- DNS publication on TCP/UDP `53`;
- HTTP publication on host port `8081`;
- working external DNS queries;
- Nebula Sync health and successful synchronisation;
- Pi-hole blocklist and enforcement health metrics.

A boot reconciliation unit was added and enabled:

```text
/etc/systemd/system/pihole-secondary-reconcile.service
```

The unit starts Unbound and force-recreates the Pi-hole service after Docker/network-online at boot. A deliberate extra reboot was not performed solely to test the unit; it should be observed on the next normal reboot.

## Patch collector stale alert — carried forward

The live patch collector freshness metrics were inspected after the Grafana `Patch collector stale` warning.

`homelab_patch_check_timestamp_seconds` was fresh for all monitored Linux hosts, with ages measured in minutes rather than the alert's two-hour threshold. This means the collector itself was not stale at the time of inspection.

The separate `homelab_patch_last_success_timestamp_seconds` metric was much older on some hosts and is not an appropriate substitute for collector freshness. Current dashboards already use `homelab_patch_check_timestamp_seconds` for patch collector age.

The live Grafana alert rule still needs to be inspected/finished to determine whether its Prometheus query, reduce/threshold expression or label handling is responsible. The follow-up must use the live Grafana rule/API or provisioning source rather than editing SQLite directly.

## Repository consolidation — completed

All outstanding pull requests targeting `main` found during the closeout were merged across:

```text
jrwroberts1976/proxmox
jrwroberts1976/home-lab-docs
jrwroberts1976/engineering-portfolio
```

This included the Proxmox Ansible service-role foundation, Linux/Grafana monitoring documentation, Alloy installation and observability runbooks, Linux security-hardening Ansible work, the homelab infrastructure-topology documentation and the engineering-portfolio Astro patch update.

Several older Proxmox PRs were drafts created from the same earlier `main` baseline. Their README changes conflicted after sequential merges. Their content was preserved using Git tree/merge commits rather than dropping earlier README additions. Final live GitHub checks showed no open PRs targeting `main` in those three repositories.

## Configuration-authority risk

`/home/james/docker` on `ids-01` is runtime state and is not a Git checkout. The active Prometheus target change is therefore proven live but still has a source-of-truth gap.

This must be corrected as part of the later Prometheus consolidation work before TestServer Prometheus is retired.

## Daily summary

### Completed today

- Added the physical Proxmox host to the Grafana-facing Prometheus on `ids-01` and proved `up=1` in Prometheus and Grafana Explore.
- Corrected the Proxmox Network Hosts identity by stable MAC and generated the `proxmox-1c55d2.json` dashboard.
- Created and proved a dedicated TestServer-to-Proxmox automation SSH identity.
- Added a Git-controlled, physical-host-specific Ansible Alloy deployment path to `jrwroberts1976/proxmox`.
- Installed and enabled Alloy v1.19.2 on `PROXMOX` through Ansible.
- Proved the end-to-end `PROXMOX journal -> Alloy -> ids-01 Loki` path using marker `PROXMOX_ALLOY_TEST_1788157720`.
- Proved the live Grafana CPU, memory, root-disk and host-down alert rules cover `PROXMOX`.
- Confirmed the live Host Down rule already preserves per-host identity with `up{job="linux-hosts"} == 0`.
- Recovered the secondary Pi-hole after its post-reboot Docker network/port attachment failure and restored DNS, Unbound, Nebula Sync and monitoring health.
- Added and enabled the secondary Pi-hole boot reconciliation unit for future reboots.
- Merged the 31 August infrastructure topology and network-discovery documentation to `home-lab-docs/main`.
- Consolidated all outstanding PRs targeting `main` across `proxmox`, `home-lab-docs` and `engineering-portfolio`, resolving overlapping README conflicts without losing prior content.
- Closed the 31 August task list at 10:12 BST with all planned P0 work complete.

### Carried forward

- Finish the Grafana `Patch collector stale` alert investigation; the collector freshness metric itself is currently healthy.
- Reconcile Grafana alert-rule Git/runtime drift, especially the `Linux Host Down` expression.
- Restore `debian-iac-test-01` to the ids-01 Prometheus target set if still missing.
- Establish Git authority for the active ids-01 Prometheus configuration.
- After parity is proven, make ids-01 the single Prometheus authority and retire TestServer Prometheus.
- Complete the separate VM 100 backup/restore and later IaC destroy/rebuild/equivalence proof.

## Day closeout

**31 August 2026 is closed.** The carried-forward items above are intentionally deferred to a future homelab working session and should not be treated as unfinished work expected later today.
