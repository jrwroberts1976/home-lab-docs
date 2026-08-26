# Script and deployment assets

This directory contains repository copies of operational scripts used by the home lab. Runtime paths are recorded separately because the repository path is not necessarily where a script executes.

| Repository file | Runtime host | Runtime path / purpose |
| --- | --- | --- |
| `homelab-network-discovery.py` | `ids-01` | `/usr/local/bin/homelab-network-discovery.py` — discovers LAN devices, maintains MAC-based inventory and writes Node Exporter textfile metrics. |
| `watch-blocked-macs.py` | `ids-01` | `/usr/local/bin/watch-blocked-macs.py` — checks the ASUS router syslog for watched/blocked MAC addresses and writes Prometheus textfile metrics. |
| `deploy-blocked-mac-alert.sh` | `ids-01` | `/home/james/scripts/deploy-blocked-mac-alert.sh` — creates or updates the Grafana `blocked_mac_detected` alert through the provisioning API. Requires `GRAFANA_TOKEN` in the environment. |
| `deploy-grafana-email-standard.sh` | Grafana host / management shell | `/home/james/scripts/deploy-grafana-email-standard.sh` — creates the reusable `homelab-email` notification template group and applies its subject/message templates to all Grafana email contact-point integrations. Requires `GRAFANA_TOKEN`. |
| `pihole-stage0-backup.sh` | `ids-01` | Captures and backs up the current Grafana Pi-hole alert/provisioning configuration before latency changes. |
| `pihole-stage1-group-interval.sh` | `ids-01` | Guarded dry-run/apply helper for changing only the Pi-hole policy-category `group_interval` from `5m` to `30s`. |
| `pihole-latency-test.sh` | `ids-01` | Generates a category-block DNS request and measures when the corresponding metric becomes visible in Prometheus. |
| `pihole-collector-flock-wrapper.sh` | Pi-hole collector host | Adds non-blocking `flock` protection around the existing collector. Do not install into cron/systemd until the current invocation has been checked. |

## Pi-hole alert latency scripts — how to run

Run these from the `home-lab-docs` repository on `ids-01`. The current clone is under `/home/james/projects/home-lab-docs`.

### 1. Update the repository

```bash
cd ~/projects/home-lab-docs
git pull
chmod +x scripts/pihole-*.sh
```

### 2. Stage 0 — backup and record the baseline

Always run this before changing the Grafana notification policy:

```bash
sudo ./scripts/pihole-stage0-backup.sh
```

Check that the output records the Pi-hole policy route, Grafana evaluation interval and 300-second event lookback, and that a timestamped backup was created.

### 3. Stage 1 — dry-run the notification change

```bash
./scripts/pihole-stage1-group-interval.sh --dry-run
```

The expected diff is only:

```diff
-        group_interval: 5m
+        group_interval: 30s
```

Do not apply the change if anything else is modified.

### 4. Apply the notification change

After reviewing the dry-run:

```bash
sudo ./scripts/pihole-stage1-group-interval.sh --apply
```

The helper creates another timestamped backup. It deliberately does not restart Grafana.

### 5. Restart and verify Grafana

```bash
docker restart grafana
docker ps --filter name=grafana
docker logs --since 2m grafana | grep -Ei 'error|fail|provision|alert'
```

Confirm that alert provisioning finishes successfully and the alert scheduler starts. Backup files in the provisioning directory may be reported as skipped because their suffix is not `.yaml`, `.yml` or `.json`; this is expected.

### 6. Determine the correct DNS client IP

The latency script's `CLIENT` value must be the source IP of the machine running the DNS query, not the Pi-hole server IP. On `ids-01`, determine it with:

```bash
ip route get 192.168.2.48
```

Use the address shown after `src`. For the current `ids-01` route to DietPi this is `192.168.2.242`.

### 7. Test DietPi first

```bash
CLIENT=192.168.2.242 ./scripts/pihole-latency-test.sh dietpi www.betfred.com
```

The DNS result should be blocked (`0.0.0.0` / `::`). Leave the script running while it polls Prometheus. A successful measurement reports the Pi-hole event timestamp, Prometheus visibility timestamp and DNS-to-Prometheus delay.

Do not move on to the second Pi-hole until the DietPi result has been reviewed. If the test times out, check the client label and collector/metric path before changing Grafana timing further.

### 8. Test `ids-01`

Once the DietPi path is understood, run the second-node test:

```bash
CLIENT=<correct-source-IP> ./scripts/pihole-latency-test.sh ids-01 flashcasino.com
```

Determine the correct source/client label for that test rather than assuming it is the same as the DietPi test.

### 9. Collector `flock` hardening — later stage

`pihole-collector-flock-wrapper.sh` is intentionally not installed automatically. Before using it, inspect the existing DietPi cron entry and the `ids-01` systemd service/timer, then point the existing scheduler at the wrapper only after confirming the exact collector invocation.

Do not change the collector schedule and introduce the wrapper at the same time; make one controlled change and verify it before continuing.

## Related operational scripts not copied into this repository

The Engineering Portfolio deployment and maintenance scripts are versioned with their owning application/runtime workflow rather than duplicated here.

| Runtime host | Runtime path | Purpose |
| --- | --- | --- |
| `TestServer` | `/home/james/projects/engineering-portfolio/scripts/deploy-production.sh` | Guarded production deployment for `me.jrwroberts.co.uk`; enables maintenance mode, builds/recreates the application, waits for readiness, performs smoke tests and restores service on success. |
| `TestServer` | `/home/james/docker/stacks/maintenance-page/enable-maintenance.sh` | Validates the expected Nginx Proxy Manager proxy host, starts/continues change control and routes the site to the maintenance container. |
| `TestServer` | `/home/james/docker/stacks/maintenance-page/disable-maintenance.sh` | Completes change control and restores the normal `engineering-portfolio:80` upstream after validation. |

The validated maintenance Compose/Nginx configuration is source-controlled in the dedicated `jrwroberts1976/homelab-container-version-control` project under `pilot/maintenance-page/`.

Full operating detail is documented in [`engineering-portfolio-deployment.md`](../engineering-portfolio-deployment.md).

## Related repository assets

The blocked-MAC watcher also has reproducible supporting files:

```text
config/blocked-macs.txt
systemd/watch-blocked-macs.service
systemd/watch-blocked-macs.timer
```

Runtime destinations on `ids-01` are:

```text
/etc/homelab/blocked-macs.txt
/etc/systemd/system/watch-blocked-macs.service
/etc/systemd/system/watch-blocked-macs.timer
```

The common alert-email format is documented at:

```text
grafana-alert-email-standard.md
```

Secrets are deliberately not stored in this repository. In particular, the ASUS SSH private key, Grafana API token and Nginx Proxy Manager token remain external to Git.

## NPM recovery validation

- `prepare-npm-sops-recovery-validation.sh` — packages the staged encrypted NPM source and a one-way protected-source checksum, then transfers them to DietPi.
- `dietpi/validate-npm-sops-recovery-identity.sh` — decrypts the transferred NPM source with the protected recovery identity in RAM, verifies the checksum and removes temporary material.
