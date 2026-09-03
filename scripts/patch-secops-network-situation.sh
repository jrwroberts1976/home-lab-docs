#!/usr/bin/env bash
set -euo pipefail

TARGET="/usr/local/lib/homelab-secops-report/generate_report.py"

if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: $TARGET not found" >&2
    exit 1
fi

BACKUP="${TARGET}.bak-network-situation-$(date +%Y%m%d-%H%M%S)"

sudo cp -a "$TARGET" "$BACKUP"

sudo python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

if "## Network Security Situation" in text:
    raise SystemExit(
        "Network Security Situation already exists; refusing to duplicate it."
    )

needle = '''    report.append(f"## Overall Security Posture: {posture}")
    report.append("")
'''

if needle not in text:
    raise SystemExit("Could not find Overall Security Posture section.")

replacement = '''    report.append(f"## Overall Security Posture: {posture}")
    report.append("")

    # ------------------------------------------------------------
    # Network Security Situation
    #
    # Separates evidence of compromise from detected activity,
    # active enforcement and monitoring/recovery assurance gaps.
    #
    # This does not alter the existing posture calculation.
    # ------------------------------------------------------------

    ssh_failed = sec.get("ssh_failed", 0)
    ssh_successful = sec.get("ssh_successful", 0)
    suricata_alerts = sec.get("suricata_alerts", 0)
    crowdsec_blocks = sec.get("crowdsec_blocks", 0)

    total_policy_blocks = sum(
        event["attempts"]
        for event in pihole_events
    )

    report.append("## Network Security Situation")
    report.append("")

    report.append("### Confirmed Compromise")
    report.append("")

    if ssh_successful > 0:
        report.append(
            f"**Successful SSH sessions were recorded: "
            f"{ssh_successful}.** These require technical review "
            "to determine whether they were authorised."
        )
    else:
        report.append(
            "**No successful SSH sessions were recorded in the "
            "current security-review evidence.**"
        )

    report.append("")
    report.append(
        "The available report evidence does not currently identify "
        "a confirmed malware, ransomware or successful exploitation "
        "event. Detected activity should not automatically be "
        "interpreted as successful compromise."
    )
    report.append("")

    report.append("### Security Activity Detected")
    report.append("")

    report.append(
        f"- Suricata alerts: **{suricata_alerts}**"
    )
    report.append(
        f"- Failed SSH attempts: **{ssh_failed}**"
    )
    report.append(
        f"- Security/policy-related DNS blocks: "
        f"**{total_policy_blocks}**"
    )
    report.append("")

    report.append(
        "These figures represent detected activity in the available "
        "security-review evidence. Detection alone does not establish "
        "successful compromise."
    )
    report.append("")

    report.append("### Security Controls Enforcing")
    report.append("")

    report.append(
        f"- CrowdSec blocking actions: **{crowdsec_blocks}**"
    )

    if pihole_events:
        report.append(
            f"- Pi-hole security/policy DNS blocks: "
            f"**{total_policy_blocks}**"
        )
        report.append(
            f"- Distinct Pi-hole security/policy events: "
            f"**{len(pihole_events)}**"
        )
    else:
        report.append(
            "- Pi-hole security/policy DNS blocks: **0**"
        )

    report.append("")
    report.append(
        "These events demonstrate active security-policy enforcement. "
        "Blocked traffic is evidence that controls operated; it is not "
        "itself evidence that the attempted activity succeeded."
    )
    report.append("")

    report.append("### Assurance Gaps")
    report.append("")

    report.append(
        "The following limitations affect what can currently be "
        "proven about the environment:"
    )
    report.append("")

    report.append(
        f"- Security monitoring status: **{monitoring_status}**"
    )
    report.append(
        f"- Backup and recovery status: **{backup_status}**"
    )
    report.append(
        "- Automated test-restore verification: **NOT IMPLEMENTED**"
    )
    report.append(
        "- End-to-end Loki/Alloy ingestion assurance: **NOT INCLUDED**"
    )

    report.append("")
    report.append(
        "These are assurance limitations rather than evidence of a "
        "security compromise. They reduce confidence in what the "
        "monitoring system can prove and should therefore remain "
        "visible to management and engineering."
    )
    report.append("")

'''

text = text.replace(needle, replacement, 1)

path.write_text(text)
print(f"Patched: {path}")
PY

echo
echo "Backup created:"
echo "$BACKUP"
