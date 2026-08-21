#!/usr/bin/env python3

import json
import os
import re
import subprocess
import time
from pathlib import Path

ROUTER = "192.168.2.1"

KEY = Path(
    "/var/lib/homelab-network-discovery/asus_network_discovery"
)

CONFIG = Path("/etc/homelab/blocked-macs.txt")

STATE = Path(
    "/var/lib/homelab-network-discovery/watched_macs_state.json"
)

METRICS = Path(
    "/var/lib/prometheus/node-exporter/watched_macs.prom"
)


def esc(value):
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", "\\n")
    )


def write_atomic(path, content, mode):
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content)
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def load_macs():
    macs = {}

    for raw_line in CONFIG.read_text().splitlines():
        line = raw_line.strip()

        if not line or line.startswith("#"):
            continue

        parts = line.split(None, 1)
        mac = parts[0].upper()
        name = parts[1].strip() if len(parts) > 1 else "Unknown"

        if re.fullmatch(r"(?:[0-9A-F]{2}:){5}[0-9A-F]{2}", mac):
            macs[mac] = name

    return macs


def get_router_matches(macs):
    if not macs:
        return {}

    pattern = "|".join(re.escape(mac) for mac in macs)

    command = (
        f"grep -iE '{pattern}' /tmp/syslog.log 2>/dev/null || true"
    )

    result = subprocess.run(
        [
            "/usr/bin/ssh",
            "-i", str(KEY),
            "-o", "BatchMode=yes",
            "-o", "ConnectTimeout=10",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            f"james@{ROUTER}",
            command,
        ],
        capture_output=True,
        text=True,
        timeout=20,
        check=True,
    )

    latest = {}

    for line in result.stdout.splitlines():
        upper_line = line.upper()

        for mac in macs:
            if mac in upper_line:
                latest[mac] = line.strip()

    return latest


def parse_event(line):
    event = "router_log"

    for name in (
        "DHCPDISCOVER",
        "DHCPOFFER",
        "DHCPREQUEST",
        "DHCPACK",
        "ASSOC",
        "AUTH",
        "DEAUTH",
        "DISASSOC",
    ):
        if name in line.upper():
            event = name
            break

    ip_match = re.search(
        r"\b(?:\d{1,3}\.){3}\d{1,3}\b",
        line,
    )

    ip = ip_match.group(0) if ip_match else ""

    return event, ip


now = int(time.time())
macs = load_macs()
watcher_up = 1

if STATE.exists():
    state = json.loads(STATE.read_text())
else:
    state = {}

try:
    matches = get_router_matches(macs)

    for mac, friendly_name in macs.items():
        record = state.setdefault(
            mac,
            {
                "last_line": "",
                "last_seen": 0,
                "event": "",
                "ip": "",
                "name": friendly_name,
            },
        )

        record["name"] = friendly_name

        latest = matches.get(mac, "")

        if not STATE.exists():
            record["last_line"] = latest

        elif latest and latest != record.get("last_line", ""):
            event, ip = parse_event(latest)

            record["last_line"] = latest
            record["last_seen"] = now
            record["event"] = event
            record["ip"] = ip

            subprocess.run(
                [
                    "/usr/bin/logger",
                    "-t",
                    "watched-mac",
                    f"WATCHED_MAC_DETECTED "
                    f"mac={mac} "
                    f'name="{friendly_name}" '
                    f"ip={ip} "
                    f"event={event} "
                    f'router_log="{latest}"',
                ],
                check=False,
            )

except Exception as exc:
    watcher_up = 0

    subprocess.run(
        [
            "/usr/bin/logger",
            "-t",
            "watched-mac",
            f"WATCHED_MAC_CHECK_FAILED error={exc}",
        ],
        check=False,
    )


write_atomic(
    STATE,
    json.dumps(state, indent=2, sort_keys=True) + "\n",
    0o640,
)

metrics = [
    "# HELP homelab_watched_mac_watcher_up Whether the ASUS router log check succeeded.",
    "# TYPE homelab_watched_mac_watcher_up gauge",
    f"homelab_watched_mac_watcher_up {watcher_up}",
    "# HELP homelab_watched_mac_last_seen_timestamp_seconds Latest new router-log detection for a watched MAC.",
    "# TYPE homelab_watched_mac_last_seen_timestamp_seconds gauge",
]

for mac in sorted(macs):
    record = state.get(mac, {})

    labels = (
        f'mac="{esc(mac)}",'
        f'name="{esc(macs[mac])}",'
        f'router="{esc(ROUTER)}",'
        f'ip="{esc(record.get("ip", ""))}",'
        f'event="{esc(record.get("event", ""))}"'
    )

    metrics.append(
        "homelab_watched_mac_last_seen_timestamp_seconds"
        f"{{{labels}}} {int(record.get('last_seen', 0))}"
    )

write_atomic(
    METRICS,
    "\n".join(metrics) + "\n",
    0o644,
)
