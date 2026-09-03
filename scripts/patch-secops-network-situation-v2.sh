#!/usr/bin/env bash
set -euo pipefail

TARGET="/usr/local/lib/homelab-secops-report/generate_report.py"

if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: $TARGET not found" >&2
    exit 1
fi

BACKUP="${TARGET}.bak-network-v2-$(date +%Y%m%d-%H%M%S)"
sudo cp -a "$TARGET" "$BACKUP"

sudo python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

if "def prometheus_query(" in text:
    raise SystemExit(
        "Prometheus helper already exists; refusing to patch twice."
    )

# ------------------------------------------------------------
# Add Prometheus query helper before main()
# ------------------------------------------------------------

needle = "\ndef main():\n"

helper = r'''
def prometheus_query(prometheus_url, query):
    """Return Prometheus instant-query vector results."""
    import json
    import urllib.parse
    import urllib.request

    url = (
        prometheus_url.rstrip("/")
        + "/api/v1/query?"
        + urllib.parse.urlencode({"query": query})
    )

    try:
        with urllib.request.urlopen(url, timeout=10) as response:
            payload = json.loads(response.read().decode())

        if payload.get("status") != "success":
            return []

        return payload.get("data", {}).get("result", [])

    except Exception:
        return []


def prometheus_number(prometheus_url, query, default=0):
    """Return the first numeric Prometheus result."""
    results = prometheus_query(prometheus_url, query)

    if not results:
        return default

    try:
        return float(results[0]["value"][1])
    except (KeyError, IndexError, TypeError, ValueError):
        return default


'''

if needle not in text:
    raise SystemExit("Could not find main() insertion point.")

text = text.replace(needle, helper + needle, 1)

# ------------------------------------------------------------
# Add Pi-hole assurance collection
# ------------------------------------------------------------

needle = '''    pihole_events = read_pihole_security_events(
        "/var/lib/homelab-secops-report/state/pihole-security-events.tsv"
    )

'''

replacement = '''    pihole_events = read_pihole_security_events(
        "/var/lib/homelab-secops-report/state/pihole-security-events.tsv"
    )

    # Pi-hole enforcement assurance is derived from live Prometheus
    # telemetry rather than from historical blocked-DNS events.
    pihole_health_results = prometheus_query(
        prometheus_url,
        'pihole_blocklist_health'
    )

    pihole_tests_results = prometheus_query(
        prometheus_url,
        'pihole_block_tests_passed'
    )

    pihole_expected_results = prometheus_query(
        prometheus_url,
        'pihole_block_tests_expected'
    )

    pihole_total_nodes = len(pihole_health_results)

    pihole_healthy_nodes = sum(
        1
        for result in pihole_health_results
        if str(result.get("value", ["", "0"])[1]) == "1"
    )

    pihole_tests_passed = sum(
        float(result.get("value", ["", "0"])[1])
        for result in pihole_tests_results
    )

    pihole_tests_expected = sum(
        float(result.get("value", ["", "0"])[1])
        for result in pihole_expected_results
    )

    pihole_enforcement_healthy = (
        pihole_total_nodes > 0
        and pihole_healthy_nodes == pihole_total_nodes
        and pihole_tests_expected > 0
        and pihole_tests_passed == pihole_tests_expected
    )

'''

if needle not in text:
    raise SystemExit("Could not find Pi-hole event collection block.")

text = text.replace(needle, replacement, 1)

# ------------------------------------------------------------
# Replace simplistic Suricata ATTENTION logic.
#
# Detection is activity, not compromise.
# Keep intrusion status as GOOD unless there is corroborating
# evidence such as authentication/security events.
# ------------------------------------------------------------

old = '''    if sec["suricata_alerts"] > 0:
        intrusion_status = "ATTENTION"
    else:
        intrusion_status = "GOOD"

'''

new = '''    # Suricata alerts represent detected network security activity.
    # They do not, by themselves, establish successful intrusion.
    # Escalation is driven by corroborating authentication/security
    # evidence rather than by alert count alone.
    if sec["authentication_events"] > 0:
        intrusion_status = "ATTENTION"
    elif sec["ssh_successful"] > 0:
        intrusion_status = "ATTENTION"
    else:
        intrusion_status = "GOOD"

'''

if old not in text:
    raise SystemExit("Could not find existing Suricata posture logic.")

text = text.replace(old, new, 1)

# ------------------------------------------------------------
# Add explicit network assessment immediately after the new
# Network Security Situation heading.
# ------------------------------------------------------------

needle = '''    report.append("## Network Security Situation")
    report.append("")

'''

replacement = '''    report.append("## Network Security Situation")
    report.append("")

    if (
        pihole_enforcement_healthy
        and sec["ssh_successful"] == 0
        and sec["authentication_events"] == 0
    ):
        report.append("### Current Assessment")
        report.append("")
        report.append(
            "🟠 AMBER — security controls are operating and no evidence "
            "of successful compromise is currently identified. The "
            "AMBER status is driven by monitoring and recovery-assurance "
            "gaps rather than evidence of a successful attack."
        )
        report.append("")
    else:
        report.append("### Current Assessment")
        report.append("")
        report.append(
            "The network security evidence requires engineering review."
        )
        report.append("")

'''

if needle not in text:
    raise SystemExit("Could not find Network Security Situation heading.")

text = text.replace(needle, replacement, 1)

# ------------------------------------------------------------
# Add Pi-hole health to Security Controls Enforcing.
# ------------------------------------------------------------

needle = '''    report.append(
        f"- CrowdSec blocking actions: **{crowdsec_blocks}**"
    )

'''

replacement = '''    report.append(
        f"- CrowdSec blocking actions: **{crowdsec_blocks}**"
    )

    if pihole_enforcement_healthy:
        report.append(
            f"- Pi-hole enforcement health: **HEALTHY — "
            f"{pihole_healthy_nodes}/{pihole_total_nodes} nodes**"
        )
        report.append(
            f"- Pi-hole block tests: **{int(pihole_tests_passed)}/"
            f"{int(pihole_tests_expected)} passing**"
        )
    else:
        report.append(
            f"- Pi-hole enforcement health: **ATTENTION — "
            f"{pihole_healthy_nodes}/{pihole_total_nodes} nodes healthy**"
        )
        report.append(
            f"- Pi-hole block tests: **{int(pihole_tests_passed)}/"
            f"{int(pihole_tests_expected)} passing**"
        )

'''

if needle not in text:
    raise SystemExit("Could not find CrowdSec section.")

text = text.replace(needle, replacement, 1)

path.write_text(text)
print(f"Patched: {path}")
print(f"Backup: {backup if False else 'created before modification'}")
PY

echo "Patch complete."
echo "Backup: $BACKUP"
