# ASUS Router Monitoring

## Purpose

This document records the ASUS router health-monitoring path confirmed on 21 August 2026. It is intentionally separate from the LAN device-discovery collector that provides client MAC addresses and hostnames.

## Confirmed architecture

```text
ASUS routers
    |
    | SSH collection
    v
TestServer
/home/james/scripts/asus-router-temp.sh
    |
    | started by systemd
    v
/etc/systemd/system/asus-router-temp.service
    |
    | writes Prometheus textfile metrics
    v
/home/james/docker/data/monitoring/node-exporter/textfile/
    asus_router_health.prom
    |
    v
Node Exporter textfile collector
    |
    v
Prometheus
    |
    v
Grafana
```

## Collector

The collector script is:

```text
/home/james/scripts/asus-router-temp.sh
```

The script writes to:

```text
/home/james/docker/data/monitoring/node-exporter/textfile/asus_router_health.prom
```

The output file is actively refreshed. During verification on 21 August 2026 it had a modification timestamp of `2026-08-21 06:32:53 +0100`.

## Service ownership

The collector is started by systemd rather than cron:

```text
/etc/systemd/system/asus-router-temp.service
```

The service contains:

```text
ExecStart=/home/james/scripts/asus-router-temp.sh
```

No relevant cron entry or systemd timer was found during the investigation.

## Routers covered

The current textfile contained metrics for three ASUS RT-AC86U devices:

| Router | IP |
| --- | --- |
| `RT-AC86U-CCC8` | `192.168.2.1` |
| `RT-AC86U-5228` | `192.168.2.181` |
| `RT-AC86U-6238` | `192.168.2.218` |

At the time of verification all three exposed `asus_router_up = 1`.

## Metrics confirmed

The textfile currently exposes these metric families:

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

The router metrics carry labels such as:

```text
router="RT-AC86U-CCC8"
ip="192.168.2.1"
```

## What this collector does not provide

This collector does **not** provide LAN client MAC addresses or client hostnames.

It only reports health and operating statistics for the ASUS routers themselves. Therefore it is not the source of the Prometheus inventory metric:

```text
homelab_network_device_info
```

Client MAC addresses, IP addresses, vendors and friendly hostnames belong to the separate network-discovery path documented in [Network Discovery Dashboard](network-discovery-dashboard.md).

That collector runs on `ids-01` as:

```text
/usr/local/bin/homelab-network-discovery.py
```

and writes:

```text
/var/lib/prometheus/node-exporter/homelab_network_discovery.prom
```

The existing network-discovery documentation records that MAC discovery is based on Nmap ARP discovery and that friendly names are enriched from the ASUS router client list and dnsmasq lease information.

## Port 9106 finding

Prometheus was observed with a target named `asus-router` pointing at:

```text
192.168.2.220:9106
```

That target was `down` with a TCP timeout. Checks on TestServer showed:

- nothing listening on TCP port `9106`;
- no Docker container exposing `9106`;
- the router textfile metrics were nevertheless present and actively refreshing.

This means the working textfile-based router-health path does not depend on the observed `:9106` endpoint.

The `asus-router` scrape job on `:9106` should therefore be treated as **legacy or otherwise unverified** until its original purpose is confirmed. Do not remove it solely on the basis of this note; first inspect the active Prometheus configuration and any historical documentation.

## Troubleshooting

Check whether the textfile exists and is current:

```bash
stat /home/james/docker/data/monitoring/node-exporter/textfile/asus_router_health.prom
```

Inspect the current router metrics:

```bash
cat /home/james/docker/data/monitoring/node-exporter/textfile/asus_router_health.prom
```

Check the systemd service:

```bash
systemctl status asus-router-temp.service
```

Confirm where the output filename is configured:

```bash
grep -n "asus_router_health.prom" /home/james/scripts/asus-router-temp.sh
```

## Data-dictionary entry

| Field | Value |
| --- | --- |
| Dataset | ASUS router health |
| Collector host | `TestServer` |
| Collector script | `/home/james/scripts/asus-router-temp.sh` |
| Scheduler/service | `/etc/systemd/system/asus-router-temp.service` |
| Output file | `/home/james/docker/data/monitoring/node-exporter/textfile/asus_router_health.prom` |
| Export mechanism | Node Exporter textfile collector |
| Source devices | Three ASUS RT-AC86U routers |
| Key labels | `router`, `ip` |
| MAC/hostname source | Not provided by this collector |
| Related inventory collector | `/usr/local/bin/homelab-network-discovery.py` on `ids-01` |
| `:9106` status | Down during verification; legacy/unverified path |
