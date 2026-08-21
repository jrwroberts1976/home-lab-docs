# Important Scripts

This page records home-lab scripts that are operationally important enough to know by name. For every script, the **Server / Host** field is explicit so it is clear where the script actually runs.

## `/usr/local/bin/homelab-network-discovery.py`

**Server / Host:** `ids-01`

**Repository copy:** [`scripts/homelab-network-discovery.py`](scripts/homelab-network-discovery.py)

**Purpose:** Discover devices on the home LAN, keep a persistent inventory keyed by MAC address, enrich device names from the ASUS router, and expose the inventory as Prometheus metrics.

### Discovery input

The script runs Nmap ARP discovery on `192.168.2.0/24` using interface `wlo1`:

```bash
nmap -sn -PR -e wlo1 -oX - 192.168.2.0/24
```

From the Nmap XML output it collects:

- IPv4 address
- MAC address
- MAC/OUI vendor
- Nmap hostname where available

The MAC address is used as the stable device identity, so a DHCP IP-address change does not create a new logical device.

### ASUS hostname enrichment

The script SSHes from `ids-01` to the main ASUS router at `192.168.2.1` as `james` using the key:

```text
/var/lib/homelab-network-discovery/asus_network_discovery
```

It reads:

```bash
nvram get custom_clientlist
cat /var/lib/misc/dnsmasq.leases
cat /tmp/var/lib/misc/dnsmasq.leases
```

This produces a MAC-to-hostname lookup which can replace or improve the hostname found by Nmap.

### Persistent state

The script stores the known-device inventory at:

```text
/var/lib/homelab-network-discovery/devices.json
```

Each MAC can retain:

- first-seen timestamp
- last-seen timestamp
- IP address or addresses
- vendor
- hostname
- baseline state

Known devices are retained even when offline.

### Prometheus output

The script writes:

```text
/var/lib/prometheus/node-exporter/homelab_network_discovery.prom
```

Important metrics include:

```text
homelab_network_scan_success
homelab_network_last_scan_timestamp_seconds
homelab_network_devices_online
homelab_network_devices_known
homelab_network_device_info
homelab_network_device_last_seen_timestamp_seconds
homelab_network_device_new
homelab_network_device_new_24h
homelab_network_learning_mode
```

`homelab_network_device_info` carries labels for MAC, IP, vendor and hostname. Its value is `1` when the MAC was seen in the latest scan and `0` when the device remains in inventory but is currently offline.

### New-device logging

A previously unseen non-baseline MAC is written to the system log with tag `network-discovery` and message prefix:

```text
NEW_NETWORK_DEVICE
```

A known MAC returning later does not count as a newly discovered device; return detection should therefore use its MAC-specific online state rather than the `new` metric.

---

## `/home/james/scripts/asus-router-temp.sh`

**Server / Host:** `TestServer`

**Purpose:** Collect health telemetry from the three ASUS routers over SSH and write Prometheus textfile metrics for Node Exporter.

### Monitored routers

```text
RT-AC86U-CCC8  192.168.2.1
RT-AC86U-5228  192.168.2.181
RT-AC86U-6238  192.168.2.218
```

### Service

The script is started by systemd using:

```text
/etc/systemd/system/asus-router-temp.service
```

with:

```text
ExecStart=/home/james/scripts/asus-router-temp.sh
```

### Prometheus output

The script writes:

```text
/home/james/docker/data/monitoring/node-exporter/textfile/asus_router_health.prom
```

Confirmed metric families include:

```text
asus_router_up
asus_router_cpu_temperature_celsius
asus_router_load1
asus_router_load5
asus_router_load15
asus_router_uptime_seconds
asus_router_memory_total_bytes
asus_router_memory_free_bytes
asus_router_memory_used_bytes
asus_router_memory_used_percent
```

The working monitoring path is:

```text
ASUS routers
  -> asus-router-temp.sh on TestServer
  -> asus_router_health.prom
  -> Node Exporter textfile collector
  -> Prometheus
  -> Grafana
```

This collector provides router-health telemetry only. It is not the source of LAN client MAC addresses or hostnames; those come from `homelab-network-discovery.py` on `ids-01`.

## Maintenance rule

When adding another operational script to this page, always record at least:

- **Server / Host**
- script path
- repository copy, where one exists
- purpose
- inputs or upstream data source
- output file, metric endpoint or log destination
- scheduler/service/timer that starts it
- downstream consumer such as Prometheus, Loki or Grafana
