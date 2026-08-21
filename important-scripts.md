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

---

## `/usr/local/bin/watch-blocked-macs.py`

**Server / Host:** `ids-01`

**Repository copy:** [`scripts/watch-blocked-macs.py`](scripts/watch-blocked-macs.py)

**Purpose:** Watch the main ASUS router syslog for any MAC addresses that are deliberately blocked or otherwise being monitored, and expose the latest detection time as Prometheus metrics.

This exists because a device blocked by the Wi-Fi access list may never remain on the LAN long enough to be seen by the normal Nmap-based network-discovery scan, while the ASUS router can still record DHCP, authentication or association activity for that MAC.

### Watched MAC configuration

The watcher reads:

```text
/etc/homelab/blocked-macs.txt
```

Format:

```text
# MAC                  Friendly name
BE:BA:54:D7:EC:6F     Unknown iPhone
```

One MAC can be added per line, so the watcher is reusable and does not require editing the Python script whenever another address needs monitoring.

### Router input

The watcher SSHes from `ids-01` to the main ASUS router at `192.168.2.1` using:

```text
/var/lib/homelab-network-discovery/asus_network_discovery
```

It searches:

```text
/tmp/syslog.log
```

for each configured MAC address.

Relevant events can include:

```text
DHCPDISCOVER
DHCPOFFER
DHCPREQUEST
DHCPACK
AUTH
ASSOC
DEAUTH
DISASSOC
```

The watcher uses the latest matching router-log line for each configured MAC.

### Baseline behaviour

On the first run, an existing historical router-log match is stored as the baseline and does **not** count as a fresh detection. This prevents old log entries from immediately triggering an alert when the watcher is first deployed.

A later matching log line that differs from the stored baseline is recorded as a new detection.

### Persistent state

State is stored at:

```text
/var/lib/homelab-network-discovery/watched_macs_state.json
```

For each configured MAC this retains the latest matched log line, latest detection timestamp, event type, IP address and friendly name.

### Local logging

A fresh match is also sent to the local system log with tag:

```text
watched-mac
```

and message prefix:

```text
WATCHED_MAC_DETECTED
```

Failures to query the router are logged with:

```text
WATCHED_MAC_CHECK_FAILED
```

### Prometheus output

The watcher writes:

```text
/var/lib/prometheus/node-exporter/watched_macs.prom
```

Metrics:

```text
homelab_watched_mac_watcher_up
homelab_watched_mac_last_seen_timestamp_seconds
```

`homelab_watched_mac_watcher_up` is `1` when the most recent router-log query succeeded.

`homelab_watched_mac_last_seen_timestamp_seconds` carries labels for:

```text
mac
name
router
ip
event
```

A value of `0` means no fresh detection has occurred since the watcher baseline was created.

The confirmed initial metric for the currently watched MAC was:

```text
homelab_watched_mac_last_seen_timestamp_seconds{mac="BE:BA:54:D7:EC:6F",name="Unknown iPhone",router="192.168.2.1",ip="",event=""} 0
```

### Scheduler

The watcher is intended to run as a systemd oneshot service:

```text
/etc/systemd/system/watch-blocked-macs.service
```

with:

```text
ExecStart=/usr/local/bin/watch-blocked-macs.py
```

and a recurring timer:

```text
/etc/systemd/system/watch-blocked-macs.timer
```

configured to run approximately once per minute.

### Alert path

```text
ASUS router /tmp/syslog.log
  -> watch-blocked-macs.py on ids-01
  -> watched_macs_state.json
  -> watched_macs.prom
  -> Node Exporter textfile collector
  -> Prometheus
  -> Grafana alert
```

A Grafana alert can detect a recent event using the timestamp metric, for example by testing whether the last-seen timestamp is within a short window such as five minutes.

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
