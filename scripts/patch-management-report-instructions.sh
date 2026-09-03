#!/usr/bin/env bash
set -euo pipefail

TARGET="/usr/local/lib/homelab-secops-report/generate_management_report.py"

if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: $TARGET not found" >&2
    exit 1
fi

BACKUP="${TARGET}.bak-management-$(date +%Y%m%d-%H%M%S)"
sudo cp -a "$TARGET" "$BACKUP"

sudo python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

old = """15. Do not use marketing language or generic cybersecurity filler.

Produce Markdown.
"""

new = """15. Do not use marketing language or generic cybersecurity filler.

SECURITY INTERPRETATION MODEL

Before writing the report, classify every material item in the
technical report into exactly one of these categories:

1. CONFIRMED COMPROMISE
   Evidence of successful unauthorised access, malware/ransomware,
   successful exploitation, confirmed data compromise, or another
   explicitly confirmed security breach.

2. SECURITY INCIDENT / INVESTIGATION
   Detected activity that is sufficiently significant or unusual
   to require investigation, but where successful compromise has
   not been established.

3. DETECTED SECURITY ACTIVITY
   Security telemetry such as failed authentication attempts,
   IDS alerts, blocked DNS requests or other attempted activity
   where there is no evidence that the activity succeeded.

4. SECURITY CONTROL ENFORCEMENT
   Evidence that a defensive control successfully operated, such
   as CrowdSec blocking traffic or Pi-hole blocking policy requests.

5. ASSURANCE GAP
   Missing telemetry, stale evidence, failed monitoring targets,
   missing backup verification, missing patch evidence, or other
   limitations on what the environment can currently prove.

6. ROUTINE OPERATIONAL FOLLOW-UP
   Non-security-critical maintenance such as available container
   image updates or normal patch-management housekeeping.

Do not promote an item from a lower category to a higher category
without explicit evidence in the source report.

In particular:

- Failed SSH attempts are NOT successful compromise.
- Suricata alerts are NOT successful compromise unless the source
  explicitly says exploitation succeeded.
- Blocked DNS requests are NOT evidence of deliberate user intent.
- CrowdSec blocks are evidence of defensive enforcement, not evidence
  that an attack succeeded.
- Pi-hole blocks are evidence of policy enforcement, not evidence
  that the requested connection succeeded.
- WUD image updates are NOT vulnerabilities unless vulnerability
  evidence is explicitly present.
- A monitoring or evidence gap is NOT a security incident.
- A backup without test-restore verification is an assurance gap,
  not evidence that backups are failing.

EXECUTIVE INTERPRETATION

The Executive Summary MUST answer these questions in order:

1. Is there evidence of successful compromise?
2. Is there a security incident requiring investigation?
3. What significant security activity was detected?
4. Which defensive controls are demonstrably operating?
5. Why is the overall posture GOOD, ATTENTION or ACTION REQUIRED?
6. What are the genuinely important management follow-ups?

Do not lead with raw event counts unless they materially affect
management risk.

CONTROL-STATE INTERPRETATION

Preserve every control state exactly as supplied by the technical
report. However, explain WHY the state exists.

If ATTENTION is caused by an assurance or evidence limitation rather
than an active security problem, explicitly say so.

Never imply that ATTENTION means compromise or active attack unless
the source report explicitly provides that evidence.

MANAGEMENT ATTENTION FILTER

Only include an item in Management Attention Required if the source
report indicates that management action, engineering investigation,
remediation, verification or follow-up is currently warranted.

Do NOT include the following merely because they occurred:

- routine blocked DNS requests,
- failed SSH attempts by themselves,
- ordinary Suricata alert counts by themselves,
- successful defensive blocking,
- accepted risks already suppressed from routine reporting,
- normal backup completion,
- container image updates unless the source identifies a
  security/vulnerability reason to act.

Where ATTENTION is caused solely by an assurance gap, label it
explicitly as an assurance or operational follow-up rather than
a security incident.

Produce Markdown.
"""

if old not in text:
    raise SystemExit("Expected instruction block not found.")

if "SECURITY INTERPRETATION MODEL" in text:
    raise SystemExit("Security interpretation model already present.")

path.write_text(text.replace(old, new, 1))
print(f"Patched: {path}")
print(f"Backup: {BACKUP}")
PY

echo
echo "===== PYTHON SYNTAX CHECK ====="
sudo python3 -m py_compile "$TARGET"

echo
echo "===== PATCH COMPLETE ====="
