#!/usr/bin/env bash
set -euo pipefail

TARGET="/usr/local/lib/homelab-secops-report/generate_report.py"

if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: $TARGET not found" >&2
    exit 1
fi

BACKUP="${TARGET}.bak-pihole-assessment-$(date +%Y%m%d-%H%M%S)"
sudo cp -a "$TARGET" "$BACKUP"

sudo python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

# ------------------------------------------------------------
# 1. Add live Pi-hole assurance queries after pihole_events.
# ------------------------------------------------------------

needle = '''    pihole_events = read_pihole_security_events(
        "/var/lib/homelab-secops-report/state/pihole-security-events.tsv"
    )

'''

if "pihole_enforcement_healthy" not in text:
    replacement = '''    pihole_events = read_pihole_security_events(
        "/var/lib/homelab-secops-report/state/pihole-security-events.tsv"
    )

    # Live Pi-hole enforcement assurance from Prometheus.
    pihole_health_results = prometheus_query(
        prometheus_url,
        "pihole_blocklist_health"
    )

    pihole_tests_results = prometheus_query(
        prometheus_url,
        "pihole_block_tests_passed"
    )

    pihole_expected_results = prometheus_query(
        prometheus_url,
        "pihole_block_tests_expected"
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
        raise SystemExit("Could not find Pi-hole event block.")

    text = text.replace(needle, replacement, 1)

# ------------------------------------------------------------
# 2. Add explicit Current Assessment after the heading.
# ------------------------------------------------------------

needle = '''    report.append("## Network Security Situation")
    report.append("")

'''

if "### Current Assessment" not in text:
    replacement = '''    report.append("## Network Security Situation")
    report.append("")

    report.append("### Current Assessment")
    report.append("")

    if (
        pihole_enforcement_healthy
        and ssh_successful == 0
        and sec.get("authentication_events", 0) == 0
    ):
        report.append(
            "🟠 **AMBER** — security controls are operating and no "
            "evidence of successful compromise is currently identified. "
            "The AMBER status is driven by monitoring and "
            "recovery-assurance gaps rather than evidence of a "
            "successful attack."
        )
    else:
        report.append(
            "The current network security evidence requires "
            "engineering review."
        )

    report.append("")

'''

    if needle not in text:
        raise SystemExit("Could not find Network Security Situation heading.")

    text = text.replace(needle, replacement, 1)

# ------------------------------------------------------------
# 3. Add Pi-hole health to Security Controls Enforcing.
# ------------------------------------------------------------

needle = '''    report.append(
        f"- CrowdSec blocking actions: **{crowdsec_blocks}**"
    )

'''

if "Pi-hole enforcement health:" not in text:
    replacement = '''    report.append(
        f"- CrowdSec blocking actions: **{crowdsec_blocks}**"
    )

    if pihole_enforcement_healthy:
        report.append(
            f"- Pi-hole enforcement health: **HEALTHY — "
            f"{pihole_healthy_nodes}/{pihole_total_nodes} nodes**"
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
PY

echo
echo "Backup created:"
echo "$BACKUP"
