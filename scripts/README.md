# Script and deployment assets

This directory contains repository copies of operational scripts used by the home lab. Runtime paths are recorded separately because the repository path is not necessarily where a script executes.

| Repository file | Runtime host | Runtime path / purpose |
| --- | --- | --- |
| `homelab-network-discovery.py` | `ids-01` | `/usr/local/bin/homelab-network-discovery.py` — discovers LAN devices, maintains MAC-based inventory and writes Node Exporter textfile metrics. |
| `watch-blocked-macs.py` | `ids-01` | `/usr/local/bin/watch-blocked-macs.py` — checks the ASUS router syslog for watched/blocked MAC addresses and writes Prometheus textfile metrics. |
| `deploy-blocked-mac-alert.sh` | `ids-01` | `/home/james/scripts/deploy-blocked-mac-alert.sh` — creates or updates the Grafana `blocked_mac_detected` alert through the provisioning API. Requires `GRAFANA_TOKEN` in the environment. |

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

Secrets are deliberately not stored in this repository. In particular, the ASUS SSH private key and Grafana API token remain external to Git.
