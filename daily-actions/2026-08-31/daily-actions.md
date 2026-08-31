# Daily Homelab Actions — 31 August 2026

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

### Documentation — completed in working branch

The `home-lab-docs` branch `docs/infrastructure-topology-20260831` now contains:

- `infrastructure-topology.md` — host/service placement, authority and data-flow topology;
- `scripts/homelab-network-discovery.md` — detailed documentation for the LAN discovery collector;
- `daily-actions/2026-08-31/todo.md` — current Proxmox and Prometheus-consolidation work;
- this daily action record.

PR #53 tracks the documentation changes.

## Open verification

### Proxmox alert coverage

The remaining Proxmox observability gate is to prove that the Grafana/Linux host alerting used by the ids-01 observability stack covers `PROXMOX` for:

- host down;
- high CPU;
- high memory;
- root filesystem/disk usage.

The existing Linux Host Down expression also needs review because the Git source currently uses `min(up{job="linux-hosts"}) < 1`, which collapses the failing host label. The intended correction is to preserve per-host identity before relying on the rule for Proxmox alerting.

## Configuration-authority risk

`/home/james/docker` on `ids-01` is runtime state and is not a Git checkout. The active Prometheus target change is therefore proven live but still has a source-of-truth gap.

This must be corrected as part of the later Prometheus consolidation work before TestServer Prometheus is retired.

## Daily summary

### Completed today

- Added the physical Proxmox host to the Grafana-facing Prometheus on `ids-01` and proved `up=1`.
- Corrected the Proxmox Network Hosts identity by stable MAC and generated the `proxmox-1c55d2.json` dashboard.
- Created and proved a dedicated TestServer-to-Proxmox automation SSH identity.
- Added a Git-controlled, physical-host-specific Ansible Alloy deployment path to `jrwroberts1976/proxmox`.
- Installed and enabled Alloy v1.19.2 on `PROXMOX` through Ansible.
- Proved the end-to-end `PROXMOX journal -> Alloy -> ids-01 Loki` path using marker `PROXMOX_ALLOY_TEST_1788157720`.
- Added infrastructure topology and network-discovery script documentation to `home-lab-docs` PR #53.

### Carried forward

- Prove and, where necessary, correct Grafana/Linux host alert coverage for `PROXMOX`.
- Restore `debian-iac-test-01` to the ids-01 Prometheus target set if still missing.
- Establish Git authority for the active ids-01 Prometheus configuration.
- After parity is proven, make ids-01 the single Prometheus authority and retire TestServer Prometheus.
- Complete the separate VM 100 backup/restore and later IaC destroy/rebuild/equivalence proof.
