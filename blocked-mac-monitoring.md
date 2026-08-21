# Blocked MAC Monitoring

## Purpose

This control detects future activity from MAC addresses that are deliberately blocked or being watched on the home network.

The main use case is a device that is blocked by the ASUS Wi-Fi access list. A blocked device may never remain connected long enough to appear in the normal Nmap-based LAN discovery inventory, but the ASUS router can still record DHCP, authentication, association, deauthentication, or related activity in its local syslog.

The watcher therefore checks the router log directly and exposes a timestamp metric to Prometheus for Grafana alerting.

## Runtime host

**Server / Host:** `ids-01`

**Runtime script:**

```text
/usr/local/bin/watch-blocked-macs.py
```

**Repository copy:**

```text
scripts/watch-blocked-macs.py
```

## Watched MAC configuration

The script reads a reusable configuration file:

```text
/etc/homelab/blocked-macs.txt
```

Format:

```text
# MAC                  Friendly name
BE:BA:54:D7:EC:6F     Unknown iPhone
```

One MAC address is stored per line. Adding another blocked or watched device therefore does not require changing the Python script.

## Why router logs are used

The watched MAC `BE:BA:54:D7:EC:6F` was previously recorded by the main ASUS router on 20 August 2026 with DHCP activity including an address assignment to `192.168.2.159` and DHCP hostname `iPhone`.

The router log contained events including:

```text
DHCPDISCOVER
DHCPOFFER
DHCPREQUEST
DHCPACK
```

Because the device is now blocked in the Wi-Fi access list, the normal `homelab-network-discovery.py` Nmap scan is not sufficient as the only detection source. The router syslog is closer to the connection attempt and can record activity even when the device does not remain available on the LAN.

## Router connection

The watcher connects from `ids-01` to the main ASUS router:

```text
192.168.2.1
```

using the existing SSH key:

```text
/var/lib/homelab-network-discovery/asus_network_discovery
```

It searches:

```text
/tmp/syslog.log
```

for every MAC listed in `/etc/homelab/blocked-macs.txt`.

Recognised event types include:

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

If a matching line does not contain one of those recognised tokens, the event is retained as a generic router-log event.

## Baseline behaviour

The first execution deliberately baselines any existing historical matching router-log line.

This is important because the router already contained the known 20 August 2026 entries for `BE:BA:54:D7:EC:6F`. Those historical entries must not generate a new alert when the watcher is first installed.

On first run:

```text
existing latest line -> stored as baseline -> last_seen remains 0
```

On a later run:

```text
new matching line != stored baseline -> fresh detection
```

## Persistent state

The watcher stores state in:

```text
/var/lib/homelab-network-discovery/watched_macs_state.json
```

For each MAC the state can retain:

- latest matched router-log line
- last fresh-detection timestamp
- parsed event type
- IP address, where present
- configured friendly name

## Local log events

A fresh detection is also written to the local system log using tag:

```text
watched-mac
```

with message prefix:

```text
WATCHED_MAC_DETECTED
```

A router-query failure is logged as:

```text
WATCHED_MAC_CHECK_FAILED
```

## Prometheus metrics

The watcher writes Node Exporter textfile metrics to:

```text
/var/lib/prometheus/node-exporter/watched_macs.prom
```

Metrics:

```text
homelab_watched_mac_watcher_up
homelab_watched_mac_last_seen_timestamp_seconds
```

### Watcher health

```text
homelab_watched_mac_watcher_up 1
```

means the most recent ASUS router-log query succeeded.

Prometheus was confirmed to ingest this metric from:

```text
host="ids-01"
instance="192.168.2.242:9100"
job="linux-hosts"
role="ids"
```

### Watched MAC timestamp

The confirmed normal-state series is:

```text
homelab_watched_mac_last_seen_timestamp_seconds{
  mac="BE:BA:54:D7:EC:6F",
  name="Unknown iPhone",
  router="192.168.2.1"
} 0
```

A value of `0` means no fresh router-log detection has occurred since the historical baseline was established.

After a fresh event, the metric also carries the detected `ip` and `event` labels and its value becomes the Unix timestamp of that detection.

## systemd service and timer

The script runs as a oneshot service:

```text
/etc/systemd/system/watch-blocked-macs.service
```

with:

```text
ExecStart=/usr/local/bin/watch-blocked-macs.py
```

It is scheduled by:

```text
/etc/systemd/system/watch-blocked-macs.timer
```

The timer is enabled and was confirmed active on `ids-01`, running approximately once per minute.

Operational check:

```bash
systemctl status watch-blocked-macs.timer
systemctl list-timers | grep watch-blocked
```

## Grafana alert

The Grafana alert rule was deployed through the provisioning API.

```text
Title:      Blocked MAC Detected
UID:        blocked_mac_detected
Folder:     Homelab Alerts
Rule group: Security
Severity:   critical
Category:   security
Component:  network
No data:    OK
```

The Prometheus expression converts the last-seen timestamp into a Boolean recent-detection signal:

```promql
((time() - homelab_watched_mac_last_seen_timestamp_seconds) > bool 0)
*
((time() - homelab_watched_mac_last_seen_timestamp_seconds) < bool 300)
```

This evaluates to:

```text
0 = no watched MAC seen in the last five minutes
1 = watched MAC seen in the last five minutes
```

Grafana then performs:

```text
A: instant Prometheus query
B: reduce A using last
C: threshold B > 0.5
```

Using an instant query followed by an explicit reduce avoids the Grafana alert error where unreduced time-series data is used directly as an alert condition.

The alert description includes labels when available:

```text
MAC
Name
IP
Router
Event
```

## End-to-end synthetic test

A safe test was performed without requiring the unknown device to reconnect.

The systemd timer was temporarily stopped and the Prometheus textfile metric was given a current timestamp with test labels:

```text
mac="BE:BA:54:D7:EC:6F"
name="Unknown iPhone"
ip="192.168.2.159"
event="TEST"
```

Prometheus successfully returned the synthetic recent event, proving that the timestamp and labels propagated through Node Exporter into Prometheus.

The original metric was then restored, the timer restarted, and the watcher run normally again. The final confirmed state returned to:

```text
homelab_watched_mac_last_seen_timestamp_seconds{mac="BE:BA:54:D7:EC:6F",name="Unknown iPhone",router="192.168.2.1"} 0
```

## Monitoring flow

```text
/etc/homelab/blocked-macs.txt
        |
        v
watch-blocked-macs.py on ids-01
        |
        | SSH
        v
ASUS router 192.168.2.1
/tmp/syslog.log
        |
        v
watched_macs_state.json
        |
        v
watched_macs.prom
        |
        v
Node Exporter :9100
        |
        v
Prometheus
        |
        v
Grafana: Blocked MAC Detected
        |
        v
Alert notification
```

## Current status

**Completed — pending real trigger.**

The watcher, timer, Node Exporter metric, Prometheus ingestion, Grafana alert rule, and synthetic metric path have all been configured and verified. The remaining real-world validation is the first future router-log appearance of a watched MAC address.