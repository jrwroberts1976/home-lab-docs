# `homelab-network-discovery.py`

## Purpose

`homelab-network-discovery.py` is the LAN inventory collector for the homelab. It runs on `ids-01` from:

```text
/usr/local/bin/homelab-network-discovery.py
```

Its job is to discover devices on the local network, maintain a persistent MAC-address inventory, enrich devices with useful names and vendor information, and publish the inventory as Prometheus metrics. Those metrics are then used by Grafana and the automatic **Network Hosts** dashboard generator.

The repository copy is:

```text
scripts/homelab-network-discovery.py
```

## Runtime host

```text
Host: ids-01
IP:   192.168.2.242
```

The collector belongs with the central observability/discovery services on `ids-01`.

## End-to-end flow

```text
Home LAN 192.168.2.0/24
        |
        | Nmap ARP discovery
        v
/usr/local/bin/homelab-network-discovery.py
        |
        +--> ASUS router hostname enrichment
        +--> persistent MAC inventory
        +--> manual hostname overrides
        +--> new-device detection
        |
        +--> /var/lib/homelab-network-discovery/devices.json
        |
        +--> /var/lib/prometheus/node-exporter/
             homelab_network_discovery.prom
                    |
                    v
               Node Exporter
                    |
                    v
                Prometheus
                    |
                    +--> Grafana discovery views
                    |
                    +--> homelab-network-host-dashboards.py
                              |
                              v
                         Network Hosts
```

## 1. LAN discovery

The script performs an Nmap ARP scan of the local IPv4 LAN using the `wlo1` interface:

```text
nmap -sn -PR -e wlo1 -oX - 192.168.2.0/24
```

The important options are:

- `-sn` — host discovery only; no normal port scan.
- `-PR` — use ARP discovery on the local Ethernet segment.
- `-e wlo1` — use the selected `ids-01` network interface.
- `-oX -` — return XML on stdout so the Python collector can parse it reliably.
- `192.168.2.0/24` — scan the home LAN.

For each discovered host the script collects, where available:

- IPv4 address;
- MAC address;
- MAC/OUI vendor;
- hostname.

The MAC address is treated as the stable device identity. An IP address can change without creating a new logical device.

## 2. ASUS router hostname enrichment

Nmap does not always return a useful hostname, so the collector also asks the main ASUS router for client naming information.

It connects to:

```text
james@192.168.2.1
```

using the protected SSH identity:

```text
/var/lib/homelab-network-discovery/asus_network_discovery
```

The collector reads the router's custom client list and dnsmasq lease information. Where the router has a useful name for a MAC address, that name can replace the weaker Nmap name.

The SSH private key is runtime-only and must not be committed to Git.

## 3. Persistent MAC inventory

Persistent state is stored in:

```text
/var/lib/homelab-network-discovery/devices.json
```

Each MAC record retains information such as:

- `first_seen`;
- `last_seen`;
- current IP address or addresses;
- vendor;
- hostname;
- whether the device was part of the initial/baseline learning period.

The script preserves useful identity information when a later scan temporarily loses a vendor or hostname. This avoids replacing a known device name with `Unknown` because of a transient lookup failure.

State is written through a temporary file and atomically replaced, reducing the chance of leaving a partially written inventory.

## 4. Baseline learning and new-device detection

The collector distinguishes known baseline devices from genuinely new MAC addresses.

The baseline-learning marker is:

```text
/var/lib/homelab-network-discovery/learning_until
```

When a MAC appears for the first time outside the learning period, the script records it as a new device and emits a journal/syslog event using the `network-discovery` tag:

```text
NEW_NETWORK_DEVICE mac=<MAC> ip=<IP> vendor="<vendor>"
```

This makes newly discovered devices available to the wider logging and security-monitoring pipeline.

## 5. Manual hostname overrides

Some devices need an explicit friendly-name override when automatic discovery returns an unhelpful name.

The script has a `manual_hostnames` map keyed by MAC address. The override is applied after automatic enrichment, so the manual value wins for a known MAC.

Example:

```python
manual_hostnames = {
    "80:E8:2C:1C:55:D2": "PROXMOX",
}
```

On 31 August 2026 this mechanism was used to correct the Proxmox host from the discovered hostname:

```text
APL-SD-C9243FXC
```

to:

```text
PROXMOX
```

The resulting Prometheus inventory was proved as:

```text
MAC:      80:E8:2C:1C:55:D2
IP:       192.168.2.70
Hostname: PROXMOX
Vendor:   Hewlett Packard
Online:   1
```

Do not create a dashboard-specific hostname workaround when the device identity can be corrected here. The discovery inventory should remain the authoritative source for the Network Hosts naming path.

## 6. Prometheus textfile output

The script writes its metrics to:

```text
/var/lib/prometheus/node-exporter/homelab_network_discovery.prom
```

Node Exporter's textfile collector exposes this file to Prometheus.

The main inventory metric is:

```text
homelab_network_device_info
```

Example:

```text
homelab_network_device_info{
  mac="80:E8:2C:1C:55:D2",
  ip="192.168.2.70",
  vendor="Hewlett Packard",
  hostname="PROXMOX"
} 1
```

The value is `1` when the device was detected by the current scan and `0` when it remains in the known inventory but is currently offline/not seen.

Other emitted metrics include:

```text
homelab_network_scan_success
homelab_network_last_scan_timestamp_seconds
homelab_network_devices_online
homelab_network_devices_known
homelab_network_device_last_seen_timestamp_seconds
homelab_network_device_new
homelab_network_device_new_24h
homelab_network_learning_mode
```

## 7. Network Hosts dashboard relationship

The collector itself does not create Grafana dashboards.

Its responsibility ends at the persistent inventory and Prometheus metrics. The separate dashboard generator:

```text
/usr/local/bin/homelab-network-host-dashboards.py
```

queries `homelab_network_device_info` from Prometheus and generates the per-device dashboard JSON used by Grafana's **Network Hosts** folder.

Therefore the relationship is:

```text
homelab-network-discovery.py
        |
        v
homelab_network_device_info
        |
        v
homelab-network-host-dashboards.py
        |
        v
Grafana Network Hosts
```

If a device is missing or incorrectly named in Network Hosts, first check the `homelab_network_device_info` series for its MAC before changing the dashboard generator.

## 8. Operational checks

### Validate Python syntax

```bash
python3 -m py_compile /usr/local/bin/homelab-network-discovery.py
```

No output means the Python syntax check passed.

### Run one scheduled service cycle

```bash
sudo systemctl start homelab-network-discovery.service
```

### Check the service

```bash
systemctl status homelab-network-discovery.service --no-pager
```

### Check a device by MAC in Prometheus on `ids-01`

```bash
curl -sG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=homelab_network_device_info{mac="80:E8:2C:1C:55:D2"}' |
jq -r '.data.result[]? | [.metric.mac,.metric.ip,.metric.hostname,.metric.vendor,.value[1]] | @tsv'
```

Expected for the current Proxmox host:

```text
80:E8:2C:1C:55:D2  192.168.2.70  PROXMOX  Hewlett Packard  1
```

## 9. Change-control guidance

Before changing the live script:

1. copy the current runtime file to a timestamped or temporary rollback location;
2. make one focused change;
3. run `python3 -m py_compile`;
4. run one discovery cycle;
5. verify the expected MAC/IP/hostname in Prometheus;
6. verify the Network Hosts dashboard regeneration path;
7. synchronise the validated runtime change back to the Git repository copy;
8. record the material change in the current day's `daily-actions.md`.

Do not commit SSH private keys, passwords or other credentials used by the router-enrichment path.

## Related documentation

- [`../network-discovery-dashboard.md`](../network-discovery-dashboard.md) — full discovery-to-Grafana architecture and per-host dashboard generation.
- [`../infrastructure-topology.md`](../infrastructure-topology.md) — current homelab host/service placement and observability topology.
- [`README.md`](README.md) — index of operational script assets.
