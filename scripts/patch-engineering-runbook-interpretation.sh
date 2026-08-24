#!/usr/bin/env bash
set -euo pipefail

# Patch the live Greenbone AI review generator used to produce the
# Engineering Security Runbook source report.
TARGET="/usr/local/lib/homelab-greenbone/ai_review.py"

if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: $TARGET not found" >&2
    exit 1
fi

BACKUP="${TARGET}.bak-runbook-interpretation-$(date +%Y%m%d-%H%M%S)"
sudo cp -a "$TARGET" "$BACKUP"

sudo python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

marker = "SECURITY INTERPRETATION MODEL"
if marker in text:
    raise SystemExit(
        "Engineering runbook interpretation model already present; refusing to patch twice."
    )

needle = '''instructions = """You are the security operations and remediation analyst for a managed homelab.\n'''
if needle not in text:
    raise SystemExit(
        "ERROR: Could not find the confirmed Greenbone AI instructions block."
    )

addition = '''SECURITY INTERPRETATION MODEL

Before writing the Engineering Security Runbook, classify every material
item in the supplied evidence into exactly one of these categories:

1. CONFIRMED COMPROMISE
   Evidence of successful unauthorised access, confirmed malware or
   ransomware, successful exploitation, confirmed data compromise, or
   another explicitly confirmed security breach.

2. SECURITY INCIDENT / INVESTIGATION
   Significant or unusual activity that requires investigation, while
   successful compromise has not been established.

3. DETECTED SECURITY ACTIVITY
   Failed authentication attempts, IDS/Suricata alerts, blocked DNS
   requests, scanner observations, threat-intelligence matches, or other
   attempted/observed security activity.

4. SECURITY CONTROLS ENFORCING
   CrowdSec blocking, Pi-hole policy enforcement, firewall blocking,
   or other controls demonstrably preventing or containing activity.

5. ASSURANCE / EVIDENCE LIMITATION
   Missing monitoring evidence, unavailable backup evidence, stale
   timestamps, missing restore-test verification, unavailable telemetry,
   or other limitations affecting what the environment can prove.

6. ROUTINE OPERATIONAL MAINTENANCE
   Available image updates, normal patching activity, feed updates,
   or other maintenance that is not independently evidence of a
   security vulnerability.

INTERPRETATION RULES

- Detected security activity is NOT automatically evidence of successful compromise.
- Failed SSH/authentication attempts do not establish successful access.
- IDS/Suricata alerts indicate detected activity unless the evidence explicitly establishes compromise.
- A threat-intelligence or hostile-IP match is not, by itself, proof that a host was compromised.
- Blocked DNS requests demonstrate enforcement and do not establish deliberate user behaviour, deliberate policy bypass, or successful access unless the evidence explicitly establishes that.
- CrowdSec/firewall blocking demonstrates active prevention; it does not establish that an attack succeeded.
- Scanner/Greenbone findings must retain their supplied severity, quality-of-detection and disposition.
- Accepted risks are not active vulnerabilities unless the source explicitly says they are.
- WARNING, ATTENTION, UNKNOWN or missing metrics are assurance/evidence issues unless the evidence explicitly establishes an actual security failure or incident.
- WUD/image-update availability is not, by itself, evidence of a vulnerability.
- Do not invent compromise, user intent, successful exploitation, or remediation outcomes.
- Keep confirmed findings, investigations, detected activity, controls and assurance gaps visibly distinct.
- If there is no confirmed compromise, state that clearly rather than implying one from activity counts.

'''

text = text.replace(needle, needle + addition, 1)
path.write_text(text, encoding="utf-8")
print(f"Patched: {path}")
PY

sudo python3 -m py_compile "$TARGET"

echo
echo "Engineering runbook generator patched successfully."
echo "Target: $TARGET"
echo "Backup: $BACKUP"
echo "Python syntax check: PASS"
