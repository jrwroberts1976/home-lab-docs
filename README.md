# Home Lab Documentation

Technical documentation for the `jrwroberts1976` home lab, including infrastructure, monitoring, networking, security, automation, backups, and hosted services.

## Network Discovery Dashboard

### Purpose

The network discovery system provides a current inventory of devices on the home LAN and automatically creates a dedicated Grafana dashboard for each discovered MAC address.

Grafana itself does **not** scan the network. Discovery takes place on `ids-01`, where the results are converted into Prometheus metrics. A separate dashboard-generator service reads that inventory from Prometheus, generates one Grafana JSON dashboard per MAC address, and Grafana file provisioning loads those dashboards into the **Network Hosts** folder.

## Architecture

```text
Home LAN (192.168.2.0/24)
        |
        | ARP discovery
        v
      ids-01
        |
        | nmap -sn -PR -e wlo1 -oX - 192.168.2.0/24
        v
/usr/local/bin/homelab-network-discovery.py
        |
        +--> persistent MAC inventory
        +--> IP / vendor / hostname
        +--> new-device state
        |
        v
/var/lib/prometheus/node-exporter/
    homelab_network_discovery.prom
        |
        v
   Node Exporter
        |
        v
Prometheus on TestServer
        |
        +------------------------------+
        |                              |
        v                              v
Network Discovery              homelab-network-host-
Dashboard                      dashboards.py
                                       |
                                       v
                              generated-hosts/*.json
                                       |
                                       v
                              Grafana file provider
                                       |
                                       v
                              Network Hosts folder
```

## 1. Network discovery

Discovery runs on `ids-01` using Nmap ARP discovery. The current script executes the equivalent of:

```bash
nmap -sn -PR -e wlo1 -oX - 192.168.2.0/24
```

The important options are:

- `-sn` — host discovery only; this is not a normal full port scan.
- `-PR` — use ARP discovery on the local Ethernet network.
- `-e wlo1` — use the selected local network interface.
- `-oX -` — return XML to standard output so the Python collector can parse it reliably.
- `192.168.2.0/24` — inspect the local IPv4 LAN.

ARP discovery is useful because a device on the same IPv4 Ethernet segment normally has to participate in ARP in order to communicate, even if it ignores ICMP echo requests.

## 2. Information acquired

For each discovered device, the collector records:

- MAC address.
- Current IPv4 address or addresses.
- Nmap/OUI vendor information where available.
- Friendly hostname where one can be resolved.
- First-seen timestamp.
- Last-seen timestamp.
- Whether the device is currently online.
- Whether it is newly discovered.

The MAC address is the stable inventory key. DHCP can change a device's IP address while its interface MAC normally remains the same, so an IP change does not automatically create a new logical device.

For example:

```text
MAC 24:B2:B9:30:F8:55
        |
        +--> today: 192.168.2.183
        |
        +--> later: 192.168.2.207
```

Both addresses can still represent the same device because the MAC identity is unchanged.

## 3. Friendly names and persistent inventory

The live discovery collector is:

```text
/usr/local/bin/homelab-network-discovery.py
```

It maintains persistent state in:

```text
/var/lib/homelab-network-discovery/devices.json
```

The state is keyed by MAC address and retains information such as `first_seen`, `last_seen`, IP addresses, vendor, hostname, and baseline state.

Friendly names are enriched from the ASUS router. The collector connects to the router and reads its custom client list and dnsmasq lease information, allowing a MAC address to acquire a useful local hostname when the router knows it.

If no hostname is known but a vendor is known, the temporary friendly name becomes:

```text
Unknown — <Vendor>
```

For example:

```text
Unknown — Nintendo
```

The same MAC can later acquire a proper friendly name. Because the inventory is MAC-based, this is treated as an update to the existing device rather than a different device.

A small manual hostname map is also available for devices that need an explicit local override.

## 4. Detecting a new MAC address

After each scan, the collector compares the MAC addresses it has just found with the persistent `devices.json` inventory.

Conceptually:

```text
MAC seen in scan
      |
      v
Already in devices.json?
      |
   +--+--+
   |     |
  yes    no
   |     |
update   create new inventory record
state    first_seen = now
         last_seen  = now
         IP/vendor/hostname recorded
             |
             v
       mark as new device
```

When the network is not in baseline-learning mode, a previously unseen MAC is also logged as a `NEW_NETWORK_DEVICE` event.

The collector exposes two useful new-device metrics:

```text
homelab_network_device_new
homelab_network_device_new_24h
```

The short-lived `new` flag identifies a newly discovered non-baseline device for roughly the first ten minutes, while `new_24h` keeps the device identifiable as recently discovered for 24 hours.

Importantly, the dashboard-generation process does **not** need to wait for a human to approve or manually create a Grafana page. Once the new MAC exists in the inventory metric, it becomes eligible for automatic dashboard generation.

## 5. Prometheus textfile metrics

The discovery collector writes Prometheus-formatted metrics to:

```text
/var/lib/prometheus/node-exporter/homelab_network_discovery.prom
```

The main inventory metric is:

```text
homelab_network_device_info
```

A typical series looks like:

```text
homelab_network_device_info{
  mac="D8:3A:DD:5A:51:44",
  ip="192.168.2.220",
  vendor="Raspberry Pi Trading",
  hostname="TestServer"
} 1
```

The value is `1` while the device is online and `0` when it is retained in the known inventory but was not seen by the current scan.

Other discovery metrics include:

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

## 6. Node Exporter and Prometheus

Node Exporter on `ids-01` uses its textfile collector to expose `homelab_network_discovery.prom` alongside the normal operating-system metrics.

```text
homelab_network_discovery.prom
        |
        v
   node_exporter
        |
        v
http://ids-01:9100/metrics
```

Prometheus on TestServer scrapes Node Exporter and stores the resulting time-series data.

The direction of flow is:

```text
Prometheus --> GET /metrics --> ids-01 Node Exporter
```

The discovery collector therefore does not push directly to Grafana or to Prometheus.

## 7. Grafana network discovery view

Grafana queries Prometheus using PromQL and turns the inventory metrics into tables, counts, status indicators, and links to individual devices.

Typical questions answered by the discovery dashboard include:

- How many devices are currently online?
- How many MAC addresses are known?
- Which devices are new?
- What manufacturer/vendor is associated with a MAC?
- What is the current IP address?
- When was the device last seen?
- What friendly hostname is currently known?

## 8. Automatic per-device Grafana page creation

The per-device dashboards are generated independently of the discovery scan by:

```text
/usr/local/bin/homelab-network-host-dashboards.py
```

It is run by:

```text
homelab-network-host-dashboards.timer
        |
        v
homelab-network-host-dashboards.service
```

The generator queries Prometheus for:

```promql
homelab_network_device_info
```

This means the Prometheus inventory is the hand-off point between **device discovery** and **dashboard creation**.

### New-MAC page-creation flow

```text
1. New device joins the LAN
           |
           v
2. Nmap ARP scan sees a new MAC
           |
           v
3. homelab-network-discovery.py
   adds the MAC to devices.json
           |
           v
4. homelab_network_device_info{
     mac="...",
     ip="...",
     vendor="...",
     hostname="..."
   }
           |
           v
5. Node Exporter exposes the metric
           |
           v
6. Prometheus stores the new series
           |
           v
7. homelab-network-host-dashboards.py
   sees the new MAC in Prometheus
           |
           v
8. A dedicated Grafana dashboard JSON
   is generated for that MAC
           |
           v
9. Grafana file provisioning notices
   the new JSON
           |
           v
10. The page appears automatically in
    Grafana -> Network Hosts
```

There is no manual Grafana import step in this flow.

### Generated dashboard files

The generator writes dashboards under:

```text
/home/james/docker/data/monitoring/grafana/provisioning/
    network-hosts-json/generated-hosts/
```

Each known MAC gets its own generated JSON file. Filenames contain a friendly-name slug plus a MAC-derived suffix, for example:

```text
james-lt-30f855.json
light-bulb-7c7b80.json
testserver-5a5144.json
```

The generated dashboards also use UIDs in the form:

```text
net-host-<digest>
```

This prevents the human-readable hostname alone from being the device identity.

### The dashboard follows the MAC, not a fixed IP

A key part of the design is that a generated host dashboard does not permanently hard-code the current DHCP address as its identity.

The generated dashboard contains an IP variable which resolves the current address from Prometheus using the MAC, for example:

```promql
label_values(
  homelab_network_device_info{mac="40:ED:00:7C:7B:80"},
  ip
)
```

So the relationship is:

```text
MAC address
    |
    +--> stable device identity
    |
    +--> Prometheus looks up current IP
              |
              v
         Grafana panels
```

If DHCP changes the IP, the same generated host page can continue to follow the device through its MAC-backed inventory record.

### Unknown device becomes a known device

The naming process is also automatic.

For a new MAC where only the OUI vendor is known, discovery may initially publish something such as:

```text
hostname="Unknown — Nintendo"
```

Later, the router's custom-client list, dnsmasq lease information, or a manual hostname override may identify the same MAC with a better name.

On a later discovery pass:

```text
same MAC
   |
   +--> hostname updated in devices.json
   |
   +--> hostname label updated in Prometheus
   |
   +--> dashboard generator sees new friendly name
   |
   +--> generated dashboard metadata/title is refreshed
```

The important point is that **the MAC has not changed**, so the device remains the same logical inventory item even though its displayed name becomes more useful.

### How Grafana picks up generated pages

Grafana has a file-provisioning provider called `network-hosts`:

```yaml
providers:
  - name: 'network-hosts'
    orgId: 1
    folder: 'Network Hosts'
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 30
    options:
      path: /etc/grafana/provisioning/network-hosts-json
```

The host path containing the generated JSON is mounted into Grafana's provisioning path. Grafana checks that location every 30 seconds.

Therefore, after the dashboard generator creates or updates a JSON file, Grafana automatically imports the change into the **Network Hosts** folder.

### Why the automation is useful

This design means:

- A new MAC can create its own Grafana host page without manual dashboard work.
- Device identity is based around MAC rather than a transient DHCP address.
- A changed IP does not require hand-editing a dashboard.
- Friendly names can improve later without redefining the device.
- Known devices remain in persistent discovery state even while offline.
- Grafana provisioning automatically notices generated dashboard files.
- The same dashboard design is applied consistently to every discovered host.

## 9. Separation from Suricata and Pi-hole

The home lab has multiple sources of network information, but they answer different questions.

### Nmap / ARP discovery

Answers:

> Which devices exist on the LAN?

This is the primary source for the network discovery inventory.

### Suricata

Answers:

> What are those devices doing on the network?

Suricata observes mirrored network traffic and produces security and traffic telemetry such as source IP, destination IP, protocol, signature, alert category, severity, and network activity.

Suricata writes `eve.json`, which is collected separately into Loki for security monitoring. It is complementary to discovery rather than being the authoritative discovery source.

### Pi-hole

Answers:

> Which clients are making DNS requests, which domains are being requested, and which requests are being blocked?

Pi-hole provides DNS activity and enforcement visibility, but it is not the authoritative source for device discovery.

## Component responsibilities

| Component | Responsibility |
|---|---|
| Nmap / ARP | Actively discovers devices on the LAN |
| `homelab-network-discovery.py` | Parses discovery, maintains MAC inventory, enriches names, and creates Prometheus metrics |
| `devices.json` | Persistent MAC-keyed device state |
| `homelab-network-discovery.timer` | Schedules network discovery |
| `homelab_network_discovery.prom` | Prometheus textfile representation of the inventory |
| Node Exporter | Exposes custom discovery metrics over HTTP |
| Prometheus | Scrapes and stores the network inventory time series |
| `homelab-network-host-dashboards.py` | Generates one Grafana dashboard JSON per discovered/known MAC |
| `homelab-network-host-dashboards.timer` | Schedules regeneration of per-device dashboards |
| `generated-hosts/` | Holds generated per-device Grafana JSON files |
| Grafana `network-hosts` provider | Imports generated JSON into the `Network Hosts` folder |
| Grafana | Displays discovery and per-device information |
| Suricata | Observes network traffic and security events separately |
| Pi-hole | Provides DNS-client, query, and blocking information separately |

## End-to-end summary

The system is split into two automated loops.

**Discovery loop:**

```text
LAN -> Nmap/ARP -> homelab-network-discovery.py
    -> Node Exporter -> Prometheus
```

**Dashboard-generation loop:**

```text
Prometheus homelab_network_device_info
    -> homelab-network-host-dashboards.py
    -> generated-hosts/*.json
    -> Grafana file provisioning
    -> Network Hosts
```

As a result, a new MAC address discovered on the LAN can move from first detection to a dedicated Grafana host page automatically, while subsequent hostname and IP changes continue to be associated with the same MAC-backed inventory identity.
