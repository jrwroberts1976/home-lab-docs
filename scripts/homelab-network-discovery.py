#!/usr/bin/env python3

import json
import os
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

STATE = Path("/var/lib/homelab-network-discovery/devices.json")
METRICS = Path(
    "/var/lib/node_exporter/textfile_collector/"
    "homelab_network_discovery.prom"
)


def esc(value):
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )


def get_router_hostnames():
    """Return friendly router names indexed by uppercase MAC."""
    command = (
        'printf "%s\\n" "$(nvram get custom_clientlist)"; '
        'printf "\\n===LEASES===\\n"; '
        'cat /var/lib/misc/dnsmasq.leases 2>/dev/null; '
        'cat /tmp/var/lib/misc/dnsmasq.leases 2>/dev/null; true'
    )

    try:
        result = subprocess.run(
            [
                "/usr/bin/ssh",
                "-i",
                (
                    "/var/lib/homelab-network-discovery/"
                    "asus_network_discovery"
                ),
                "-o",
                "BatchMode=yes",
                "-o",
                "ConnectTimeout=10",
                "-o",
                "StrictHostKeyChecking=no",
                "-o",
                "UserKnownHostsFile=/dev/null",
                "james@192.168.2.1",
                command,
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=20,
        )
    except (OSError, subprocess.SubprocessError):
        return {}

    custom_data, separator, lease_data = result.stdout.partition(
        "\n===LEASES===\n"
    )

    names = {}

    for name, mac in re.findall(
        r"<([^>]*)>([0-9A-Fa-f:]{17})>",
        custom_data,
    ):
        name = name.strip()
        if name and name != "*":
            names[mac.upper()] = name

    if separator:
        for line in lease_data.splitlines():
            fields = line.split()

            if len(fields) < 4:
                continue

            mac = fields[1].upper()
            hostname = fields[3].strip()

            if hostname and hostname != "*":
                names.setdefault(mac, hostname)

    return names


router_hostnames = get_router_hostnames()


scan = subprocess.run(
    [
        "/usr/bin/nmap",
        "-sn",
        "-PR",
        "-e",
        "wlo1",
        "-oX",
        "-",
        "192.168.2.0/24",
    ],
    check=True,
    capture_output=True,
    text=True,
    timeout=120,
)

root = ET.fromstring(scan.stdout)
found = {}

for host in root.findall("host"):
    addresses = host.findall("address")

    ipv4 = next(
        (
            item.get("addr")
            for item in addresses
            if item.get("addrtype") == "ipv4"
        ),
        None,
    )

    hostname_item = host.find("hostnames/hostname")
    hostname = (
        hostname_item.get("name")
        if hostname_item is not None
        else "Unknown"
    )

    mac_item = next(
        (
            item
            for item in addresses
            if item.get("addrtype") == "mac"
        ),
        None,
    )

    if not ipv4 or mac_item is None:
        continue

    mac = mac_item.get("addr", "").upper()
    vendor = mac_item.get("vendor", "Unknown")

    router_hostname = router_hostnames.get(mac)
    if router_hostname:
        hostname = router_hostname

    if mac == "24:4B:FE:5E:CC:C8":
        hostname = "Main Router"

    if hostname == "Unknown" and vendor != "Unknown":
        hostname = vendor

    device = found.setdefault(
        mac,
        {
            "ips": [],
            "vendor": vendor,
            "hostname": hostname,
        },
    )

    if ipv4 not in device["ips"]:
        device["ips"].append(ipv4)

now = int(time.time())
initial = not STATE.exists()
learning_file = Path(
    "/var/lib/homelab-network-discovery/learning_until"
)
learning = initial or (
    learning_file.exists()
    and now < int(learning_file.read_text().strip())
)

if initial:
    state = {}
else:
    state = json.loads(STATE.read_text())

new_macs = []

for mac, device in found.items():
    device["ips"].sort(
        key=lambda ip: tuple(
            int(part) for part in ip.split(".")
        )
    )

    if mac not in state:
        state[mac] = {
            "first_seen": now,
            "last_seen": now,
            "ips": device["ips"],
            "vendor": device["vendor"],
            "hostname": device["hostname"],
            "baseline": learning,
        }

        if not learning:
            new_macs.append(mac)
    else:
        state[mac]["last_seen"] = now
        state[mac]["ips"] = device["ips"]

        # Preserve useful identity information if a later scan temporarily
        # loses it. MAC remains the stable device identity.
        if (
            device["vendor"] != "Unknown"
            or state[mac].get("vendor", "Unknown") == "Unknown"
        ):
            state[mac]["vendor"] = device["vendor"]

        current_hostname = state[mac].get("hostname", "Unknown")
        discovered_hostname = device["hostname"]

        current_unknown = (
            current_hostname == "Unknown"
            or current_hostname.startswith("Unknown — ")
        )
        discovered_unknown = (
            discovered_hostname == "Unknown"
            or discovered_hostname.startswith("Unknown — ")
        )

        # Always allow an unknown name to improve. Once we have a real
        # hostname, do not downgrade it because of a transient lookup miss.
        # A newly discovered real hostname may still replace an older one.
        if current_unknown or not discovered_unknown:
            state[mac]["hostname"] = discovered_hostname


manual_hostnames = {
    "58:02:05:FD:E1:8B": "Rosie Laptop",
    "24:4B:FE:5E:CC:C8": "Main Router",
    "5C:34:00:50:DF:B3": "Main TV",
    "14:7F:67:6D:E5:98": "Bedroom TV",
    "60:83:E7:F3:BF:3D": "TP-Link IoT F3-BF-3D",
    "60:83:E7:F4:0B:2E": "TP-Link IoT F4-0B-2E",
}

for manual_mac, manual_hostname in manual_hostnames.items():
    if manual_mac in state:
        state[manual_mac]["hostname"] = manual_hostname


temporary_state = STATE.with_suffix(".tmp")
temporary_state.write_text(
    json.dumps(state, indent=2, sort_keys=True) + "\n"
)
os.chmod(temporary_state, 0o640)
os.replace(temporary_state, STATE)

metrics = [
    "# HELP homelab_network_scan_success Latest scan succeeded.",
    "# TYPE homelab_network_scan_success gauge",
    "homelab_network_scan_success 1",
    "# HELP homelab_network_last_scan_timestamp_seconds "
    "Latest successful scan time.",
    "# TYPE homelab_network_last_scan_timestamp_seconds gauge",
    f"homelab_network_last_scan_timestamp_seconds {now}",
    "# HELP homelab_network_devices_online Devices online now.",
    "# TYPE homelab_network_devices_online gauge",
    f"homelab_network_devices_online {len(found)}",
    "# HELP homelab_network_devices_known Known device inventory.",
    "# TYPE homelab_network_devices_known gauge",
    f"homelab_network_devices_known {len(state)}",
    "# HELP homelab_network_device_info Device inventory.",
    "# TYPE homelab_network_device_info gauge",
    "# HELP homelab_network_device_last_seen_timestamp_seconds "
    "Unix timestamp when the device was last detected.",
    "# TYPE homelab_network_device_last_seen_timestamp_seconds gauge",
    "# HELP homelab_network_device_new Newly discovered device.",
    "# TYPE homelab_network_device_new gauge",
    "# HELP homelab_network_device_new_24h "
    "Device discovered within 24 hours.",
    "# TYPE homelab_network_device_new_24h gauge",
]

metrics.extend(
    [
        "# HELP homelab_network_learning_mode "
        "One while baseline learning is active.",
        "# TYPE homelab_network_learning_mode gauge",
        f"homelab_network_learning_mode {int(learning)}",
    ]
)

for mac in sorted(state):
    device = state[mac]
    online = int(mac in found)
    age = max(0, now - int(device["first_seen"]))
    baseline = bool(device.get("baseline", False))
    new = int(not baseline and age <= 600)
    new_24h = int(not baseline and age <= 86400)

    labels = (
        f'mac="{esc(mac)}",'
        f'ip="{esc(",".join(device["ips"]))}",'
        f'vendor="{esc(device["vendor"])}",'
        f'hostname="{esc(device.get("hostname", "Unknown"))}"'
    )

    metrics.append(
        f"homelab_network_device_info{{{labels}}} {online}"
    )
    metrics.append(
        "homelab_network_device_last_seen_timestamp_seconds"
        f"{{{labels}}} {int(device['last_seen'])}"
    )
    metrics.append(
        f"homelab_network_device_new{{{labels}}} {new}"
    )
    metrics.append(
        f"homelab_network_device_new_24h"
        f"{{{labels}}} {new_24h}"
    )

temporary_metrics = METRICS.with_suffix(".tmp")
temporary_metrics.write_text("\n".join(metrics) + "\n")
os.chmod(temporary_metrics, 0o644)
os.replace(temporary_metrics, METRICS)

for mac in new_macs:
    device = state[mac]

    subprocess.run(
        [
            "/usr/bin/logger",
            "-t",
            "network-discovery",
            "NEW_NETWORK_DEVICE "
            f"mac={mac} "
            f'ip={",".join(device["ips"])} '
            f'vendor="{device["vendor"]}"',
        ],
        check=False,
    )

print(
    json.dumps(
        {
            "baseline_created": initial,
            "devices_online": len(found),
            "devices_known": len(state),
            "new_devices": new_macs,
        }
    )
)
