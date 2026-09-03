# Automated Host Decommission Runbook

## Purpose

This runbook defines the standard observability cleanup for a retired homelab host.

The automation is provided by:

```text
scripts/homelab-decommission-host
```

Installed runtime path:

```text
/usr/local/sbin/homelab-decommission-host
```

The tool removes the retired host from **current** monitoring state while preserving historical telemetry.

It covers:

- persistent network-discovery inventory
- generated Grafana Network Host dashboards
- target-exclusive Grafana alert provisioning
- current Prometheus network-inventory series
- final Grafana database verification

It does **not** delete:

- historical Prometheus samples
- historical Loki logs
- unrelated Grafana dashboards
- shared/mixed Grafana alert files
- Proxmox VM storage
- Terraform/OpenTofu state

The Proxmox/IaC destroy step remains a separate lifecycle action.

---

## Control host

Run this automation on:

```text
ids-01
```

The current implementation expects:

```text
Grafana provisioning:
/home/james/docker/data/monitoring/grafana/provisioning

Grafana data:
/home/james/docker/data/monitoring/grafana

Monitoring compose stack:
/home/james/docker/stacks/monitoring

Network discovery state:
/var/lib/homelab-network-discovery/devices.json

Network discovery textfile metrics:
/var/lib/node_exporter/textfile_collector/homelab_network_discovery.prom

Prometheus:
http://127.0.0.1:9090

Grafana health:
http://127.0.0.1:3001/api/health
```

These locations can be overridden with environment variables documented in the script.

---

## Safety model

The default mode is **dry-run**.

A decommission is not performed unless `--apply` is explicitly supplied.

The script fails closed when:

- it is not running on `ids-01`
- Grafana is not running
- the MAC address is invalid
- the MAC belongs to a different known hostname
- the host is currently online
- a generated dashboard cannot be safely identified
- dashboard deletion is disabled in the Grafana provider
- a matching Grafana alert file contains multiple alert UIDs
- a matching Grafana alert file has an unexpected provisioning structure
- the retired MAC reappears after network discovery is regenerated
- Grafana does not become healthy after a restart
- the retired dashboard or alert remains in the Grafana database
- the retired MAC remains in current Prometheus inventory

A mixed/shared alert file is deliberately **not** rewritten automatically.

That case requires a reviewed alerting change first.

---

## Install or update the runtime command

From a clean `home-lab-docs` checkout on `ids-01`:

```bash
cd /home/james/projects/home-lab-docs

git pull --ff-only

sudo install \
  -o root \
  -g root \
  -m 0750 \
  scripts/homelab-decommission-host \
  /usr/local/sbin/homelab-decommission-host

sudo /usr/local/sbin/homelab-decommission-host --help
```

Expected runtime ownership:

```text
root:root
```

Expected mode:

```text
0750
```

---

## Stage 1 — dry-run

Always run the dry-run first.

Example:

```bash
sudo /usr/local/sbin/homelab-decommission-host \
  --hostname app-platform-01 \
  --mac BC:24:11:08:A2:33 \
  --ip 192.168.2.253
```

Because `--apply` is absent, no decommission changes are made.

Expected ending:

```text
===== DRY RUN RESULT =====
changes_applied=NO
historical_prometheus_data=UNCHANGED
historical_loki_logs=UNCHANGED

PASS: DECOMMISSION PRE-FLIGHT COMPLETE
```

Review all discovered dashboard and alert files before proceeding.

---

## Stage 2 — apply

Only after the dry-run passes:

```bash
sudo /usr/local/sbin/homelab-decommission-host \
  --hostname app-platform-01 \
  --mac BC:24:11:08:A2:33 \
  --ip 192.168.2.253 \
  --apply
```

The automation performs the following sequence.

### 1. Authority and identity gates

It verifies:

- control host is `ids-01`
- Grafana container is running
- persistent network-discovery state is readable
- MAC address syntax is valid
- known hostname for the MAC is compatible with the requested hostname

### 2. Current-online gate

Before deletion, the automation starts:

```text
homelab-network-discovery.service
```

It then checks the current network-discovery textfile metric.

A value of:

```text
1
```

means the host is currently online and the decommission is refused.

A value of:

```text
0
```

or an absent current series can proceed to the remaining safety gates.

### 3. Dashboard discovery

Generated Network Host dashboards are matched using:

- exact dashboard title
- hostname in dashboard description
- MAC address in dashboard description
- supplied IP address in dashboard description

The Grafana `network-hosts` provider must permit deletion:

```yaml
disableDeletion: false
```

### 4. Alert discovery

The automation searches active Grafana alert provisioning while excluding historical `backups` directories.

If a matching alert file contains exactly one UID:

- an existing `deleteRules` file is treated as a deletion tombstone
- a live single-rule `groups` file is converted into a deletion tombstone

If a matching file contains multiple UIDs, the automation stops.

This prevents accidental removal of another host's alerts from a shared file.

### 5. Backup

Before applying deletions the tool creates:

```text
/var/tmp/homelab-decommission-<hostname>-<timestamp>
```

The backup directory is mode:

```text
0700
```

It preserves the relevant pre-change state, including as available:

- `devices.json`
- current network-discovery Prometheus textfile
- matching generated dashboard JSON
- matching alert provisioning files
- `network-hosts.yml`

The final result is also recorded in:

```text
result.txt
```

### 6. Network inventory removal

The MAC entry is removed from:

```text
/var/lib/homelab-network-discovery/devices.json
```

The JSON file's existing ownership and mode are preserved.

### 7. Generated dashboard removal

Matching generated dashboard source files are removed from:

```text
/home/james/docker/data/monitoring/grafana/provisioning/network-hosts-json/generated-hosts
```

### 8. Network discovery regeneration

The automation starts network discovery again.

This is an important post-delete safety gate.

If the physical or virtual host is still present on the LAN, its MAC will be detected again and the automation fails rather than hiding a live host.

The retired MAC must remain absent from:

```text
devices.json
```

and:

```text
homelab_network_discovery.prom
```

### 9. First Grafana reload

Grafana is restarted through the monitoring Compose stack.

This allows Grafana to process:

- dashboard source deletion
- alert-rule deletion tombstones

Grafana health must return:

```json
{
  "database": "ok"
}
```

### 10. Grafana database proof

The automation locates:

```text
grafana.db
```

and performs a read-only SQLite check.

The retired host must have:

```text
dashboard_rows=0
alert_rows=0
grafana_database_proof=PASS
```

### 11. Spent alert-tombstone cleanup

After Grafana has demonstrably removed the target alert rule, target-exclusive tombstone files are removed.

This leaves no active provisioning artifact whose only purpose was deleting the retired host.

### 12. Final Grafana reload

Grafana is restarted again and must become healthy.

### 13. Zero active provisioning references

Active Grafana provisioning is checked for the retired:

- hostname
- MAC address
- IP address

Historical provisioning backup directories are excluded from this active-state gate.

Expected:

```text
grafana_active_provisioning_references=ZERO
```

### 14. Current Prometheus inventory proof

The current instant query:

```promql
homelab_network_device_info{mac="<MAC>"}
```

must return no active series.

Expected:

```text
prometheus_current_inventory=ABSENT
```

This does not delete old Prometheus samples.

### 15. Final database proof

Grafana SQLite is checked again after the final restart.

Expected:

```text
dashboard_rows=0
alert_rows=0
grafana_database_proof=PASS
```

---

## Successful completion

A successful run ends with a result equivalent to:

```text
dashboard=REMOVED
grafana_alert=REMOVED_OR_ABSENT
grafana_active_provisioning_references=ZERO
network_inventory=REMOVED
current_prometheus_inventory=REMOVED
historical_prometheus_data=PRESERVED
historical_loki_logs=PRESERVED

PASS: HOMELAB HOST DECOMMISSION COMPLETE
```

At that point the host is closed from the current observability layer.

---

## Relationship to Proxmox / OpenTofu / Ansible

For IaC-managed VMs, this command should become the **observability decommission stage** of the VM lifecycle.

Recommended order:

```text
1. Application/service retirement
2. Dry-run observability decommission
3. Apply observability decommission
4. Confirm PASS
5. Remove host-specific DNS / proxy / backup configuration as applicable
6. OpenTofu destroy VM resources
7. Ansible inventory cleanup
8. Final repository/documentation closure
```

Do not put the destructive observability cleanup directly inside an OpenTofu `local-exec` destroy provisioner.

The safer model is an explicit wrapper/runbook stage that must pass before `tofu destroy`.

This keeps:

- dry-run visibility
- human-readable proof
- backups
- failure gates
- separation between monitoring cleanup and VM destruction

A future CI/Jenkins workflow can invoke this same command with the hostname/MAC supplied by the IaC inventory.

---

## Example IaC decommission wrapper

A controlled operator workflow can use:

```bash
HOST="app-platform-01"
MAC="BC:24:11:08:A2:33"
IP="192.168.2.253"

sudo /usr/local/sbin/homelab-decommission-host \
  --hostname "$HOST" \
  --mac "$MAC" \
  --ip "$IP"

sudo /usr/local/sbin/homelab-decommission-host \
  --hostname "$HOST" \
  --mac "$MAC" \
  --ip "$IP" \
  --apply

tofu plan -destroy
tofu destroy
```

The dry-run and applied cleanup remain explicit and reviewable before infrastructure destruction.

---

## Recovery

Every applied run creates a backup under:

```text
/var/tmp/homelab-decommission-<hostname>-<timestamp>
```

If a decommission was started for the wrong device, stop before further manual changes and inspect the backup.

Do not blindly restore Grafana SQLite.

Prefer restoring the backed-up source-of-truth files and allowing normal provisioning/discovery to reconcile Grafana.

Typical recovery sources are:

```text
devices.json
<generated dashboard>.json
<alert provisioning>.yml
network-hosts.yml
homelab_network_discovery.prom
```

After any recovery:

```bash
sudo systemctl start homelab-network-discovery.service

cd /home/james/docker/stacks/monitoring
docker compose restart grafana
```

Then re-run the dry-run to confirm current state.

---

## Historical-data policy

Host decommissioning removes the host only from **current operational monitoring**.

The automation intentionally does not call:

- Prometheus delete-series APIs
- Prometheus admin deletion endpoints
- Loki deletion APIs
- direct destructive SQLite delete statements

Historical telemetry remains available for retrospective investigation and audit.
