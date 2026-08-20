# Home Lab Documentation

Technical documentation for the `jrwroberts1976` home lab, including infrastructure, monitoring, networking, security, automation, backups, and hosted services.

## Network Discovery Dashboard

### Purpose

The network discovery dashboard provides a current view of devices present on the home LAN and shows how those devices are identified and monitored.

Grafana itself does **not** scan the network. The actual discovery takes place on `ids-01`. The discovery results are converted into Prometheus metrics, exposed through Node Exporter, scraped by Prometheus on TestServer, and then queried by Grafana.

## Architecture

```text
Home LAN (192.168.2.0/24)
        |
        | ARP discovery
        v
      ids-01
        |
        | nmap -sn -PR -n 192.168.2.0/24
        v
/usr/local/sbin/homelab-mac-watch
        |
        +--> IP / MAC / device state
        +--> new or changed MAC detection
        +--> optional alerting via msmtp
        |
        v
/var/lib/prometheus/node-exporter/homelab_mac_watch.prom
        |
        v
   Node Exporter
        |
        v
Prometheus on TestServer
        |
        v
      Grafana
        |
        v
Network Discovery Dashboard
```

## 1. Network discovery

Discovery runs on `ids-01` using:

```bash
nmap -sn -PR -n 192.168.2.0/24
```

The options mean:

- `-sn` — host discovery only; this is not a normal full port scan.
- `-PR` — use ARP discovery on the local Ethernet network.
- `-n` — disable reverse-DNS lookups.
- `192.168.2.0/24` — inspect the local IPv4 LAN, effectively addresses `192.168.2.1` through `192.168.2.254`.

ARP discovery is useful because a device on the same IPv4 Ethernet segment normally has to participate in ARP in order to communicate, even if it ignores ICMP echo requests.

## 2. Information acquired

The discovery process can establish:

- Whether a device is currently present on the LAN.
- Its current IPv4 address.
- Its MAC address.
- In some cases, the hardware vendor associated with the MAC OUI.

The IP-to-MAC relationship is important because DHCP can change an IP address while the interface MAC normally remains the same. This allows the monitoring logic to recognise the same interface after an address change.

For example:

```text
192.168.2.183 -> 24:b2:b9:30:f8:55
```

If the same interface later receives `192.168.2.207`, the MAC address can still be used to recognise it as the same network interface/device.

Vendor identification should not be confused with device-role identification. A MAC OUI may indicate Raspberry Pi, Intel, Apple, Espressif, or another manufacturer, but it does not by itself identify a device as the primary Pi-hole, a Kubernetes node, or another service role. Friendly names and roles require locally maintained inventory or mappings.

## 3. Collector

The discovery logic is wrapped by:

```text
/usr/local/sbin/homelab-mac-watch
```

A systemd timer runs the collector regularly, approximately once per minute.

Conceptually, the collector performs the following work:

```text
systemd timer
     |
     v
homelab-mac-watch
     |
     v
Nmap ARP discovery
     |
     +--> known device
     +--> new/unknown MAC
     +--> current IP address
     +--> device presence/state
     +--> change/alert logic
```

The collector interprets the raw Nmap results and turns them into monitoring data.

## 4. Prometheus textfile metrics

The collector writes Prometheus-formatted metrics to:

```text
/var/lib/prometheus/node-exporter/homelab_mac_watch.prom
```

This is the bridge between the custom discovery logic and the standard monitoring platform.

Instead of requiring Grafana to parse raw Nmap output, the collector produces structured metrics containing discovery state and labels such as IP address, MAC address, and related device information.

Conceptually, a metric may look similar to:

```text
homelab_network_device_info{ip="192.168.2.183",mac="24:b2:b9:30:f8:55"} 1
```

The exact metric names depend on the deployed collector version, but the data-flow principle remains the same.

## 5. Node Exporter

Node Exporter runs on `ids-01` and uses its textfile collector to expose the custom `.prom` file alongside normal operating-system metrics.

```text
homelab_mac_watch.prom
        |
        v
   node_exporter
        |
        v
http://ids-01:9100/metrics
```

This allows the same exporter to expose normal host telemetry such as CPU, memory, disk, load, and interfaces together with the custom network-discovery metrics.

## 6. Prometheus

The central Prometheus instance runs on TestServer.

Prometheus periodically scrapes Node Exporter on `ids-01` and stores the resulting time-series data.

The important direction of flow is:

```text
Prometheus --> GET /metrics --> ids-01 Node Exporter
```

The collector does not directly push discovery data into Prometheus. Prometheus pulls it from Node Exporter during its normal scrape cycle.

## 7. Grafana

Grafana is the presentation layer.

It queries Prometheus using PromQL and turns the results into dashboard panels such as tables, status indicators, and counts.

Typical dashboard questions are:

- How many devices are currently present?
- Which MAC addresses have been discovered?
- What IP address is associated with each device?
- Has a new or unexpected device appeared?
- Is the discovery collector still operating correctly?

Grafana does not perform active network discovery itself.

## 8. Separation from Suricata and Pi-hole

The home lab has multiple sources of network information, but they answer different questions.

### Nmap / ARP discovery

Answers:

> Which devices exist on the LAN?

This is the primary source for the network discovery inventory.

### Suricata

Answers:

> What are those devices doing on the network?

Suricata observes mirrored network traffic and produces security and traffic telemetry such as:

- Source IP.
- Destination IP.
- Protocol.
- Signature.
- Alert category.
- Severity.
- Network activity.

Suricata writes `eve.json`, which is collected separately into Loki for security monitoring.

Suricata is therefore complementary to discovery rather than being the authoritative discovery source.

### Pi-hole

Answers:

> Which clients are making DNS requests, which domains are being requested, and which requests are being blocked?

Pi-hole provides DNS activity and enforcement visibility, but it is not the authoritative source for device discovery.

## Component responsibilities

| Component | Responsibility |
|---|---|
| Nmap | Actively discovers devices on the LAN |
| ARP | Establishes local IP-to-MAC relationships |
| `homelab-mac-watch` | Processes, classifies, and records discovery results |
| systemd timer | Runs discovery regularly |
| `.prom` textfile | Stores discovery metrics in Prometheus format |
| Node Exporter | Exposes those metrics over HTTP |
| Prometheus | Scrapes and stores the time-series data |
| Grafana | Queries and displays the information |
| Suricata | Observes network traffic and security events separately |
| Pi-hole | Provides DNS-client, query, and blocking information separately |

## End-to-end summary

The networking discovery dashboard gets its authoritative device-presence information from a scheduled Nmap ARP discovery of `192.168.2.0/24` on `ids-01`. `homelab-mac-watch` converts the results into Prometheus metrics, Node Exporter exposes them, Prometheus on TestServer stores them, and Grafana displays them.
