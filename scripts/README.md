# Script and deployment assets

This directory contains repository copies of operational scripts used by the home lab. Runtime paths are recorded separately because the repository path is not necessarily where a script executes.

| Repository file | Runtime host | Runtime path / purpose |
| --- | --- | --- |
| `homelab-network-discovery.py` | `ids-01` | `/usr/local/bin/homelab-network-discovery.py` — discovers LAN devices, maintains MAC-based inventory and writes Node Exporter textfile metrics. |
| `watch-blocked-macs.py` | `ids-01` | `/usr/local/bin/watch-blocked-macs.py` — checks the ASUS router syslog for watched/blocked MAC addresses and writes Prometheus textfile metrics. |
| `deploy-blocked-mac-alert.sh` | `ids-01` | `/home/james/scripts/deploy-blocked-mac-alert.sh` — creates or updates the Grafana `blocked_mac_detected` alert through the provisioning API. Requires `GRAFANA_TOKEN` in the environment. |
| `deploy-grafana-email-standard.sh` | Grafana host / management shell | `/home/james/scripts/deploy-grafana-email-standard.sh` — creates the reusable `homelab-email` notification template group and applies its subject/message templates to all Grafana email contact-point integrations. Requires `GRAFANA_TOKEN`. |

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
