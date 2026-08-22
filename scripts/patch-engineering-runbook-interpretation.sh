#!/usr/bin/env bash
set -euo pipefail

# Patch the live engineering-security runbook generator so its AI/reporting
# instructions explicitly distinguish compromise from detected activity.
#
# The production generator is intentionally discovered on the host rather
# than hard-coded to a guessed repository path. The script refuses to patch
# when it cannot identify exactly one suitable Python generator.

SEARCH_ROOTS=(
    /usr/local/lib/homelab-greenbone
    /usr/local/lib/homelab-secops-report
    /usr/local/sbin
)

mapfile -t candidates < <(
    sudo grep -RIl \
        --include='*.py' \
        --include='*.sh' \
        -E 'Engineering Security Runbook|engineering security runbook' \
        "${SEARCH_ROOTS[@]}" 2>/dev/null \
        | sort -u
)

if [[ ${#candidates[@]} -eq 0 ]]; then
    echo "ERROR: Could not locate the engineering runbook generator." >&2
    echo "Search locations:" >&2
    printf '  %s\n' "${SEARCH_ROOTS[@]}" >&2
    exit 1
fi

# Prefer Python generators containing an instruction block. Email wrapper
# scripts are not patched automatically.
mapfile -t python_candidates < <(
    printf '%s\n' "${candidates[@]}" \
        | grep -E '\.py$' \
        | while read -r file; do
            if sudo grep -qE 'INSTRUCTIONS|Produce Markdown|system.*prompt|prompt' "$file"; then
                printf '%s\n' "$file"
            fi
        done
)

if [[ ${#python_candidates[@]} -ne 1 ]]; then
    echo "ERROR: Expected exactly one Python engineering runbook generator, found ${#python_candidates[@]}." >&2
    echo "Candidates requiring review:" >&2
    printf '  %s\n' "${python_candidates[@]:-${candidates[@]}}" >&2
    exit 1
fi

TARGET="${python_candidates[0]}"
BACKUP="${TARGET}.bak-runbook-interpretation-$(date +%Y%m%d-%H%M%S)"

sudo cp -a "$TARGET" "$BACKUP"

sudo python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

marker = "SECURITY INTERPRETATION MODEL"
if marker in text:
    raise SystemExit("Engineering runbook interpretation model already present; refusing to duplicate it.")

# We only patch a prompt/instruction block that already contains the normal
# Markdown output instruction. This avoids changing report-generation logic.
anchors = [
    "Produce Markdown.\n",
    "Produce Markdown.\r\n",
]
anchor = next((a for a in anchors if a in text), None)
if anchor is None:
    raise SystemExit("Could not find the engineering runbook Markdown instruction anchor.")

addition = r'''\nSECURITY INTERPRETATION MODEL\n\nBefore writing the engineering security runbook, classify every material\nitem in the supplied evidence into exactly one of these categories:\n\n1. CONFIRMED COMPROMISE\n   Evidence of successful unauthorised access, confirmed malware or\n   ransomware, successful exploitation, confirmed data compromise, or\n   another explicitly confirmed security breach.\n\n2. SECURITY INCIDENT / INVESTIGATION\n   Significant or unusual activity that requires investigation, while\n   successful compromise has not been established.\n\n3. DETECTED SECURITY ACTIVITY\n   Failed authentication attempts, IDS alerts, blocked DNS requests,\n   scanner observations, or other attempted/observed security activity.\n\n4. SECURITY CONTROLS ENFORCING\n   CrowdSec blocking, Pi-hole policy enforcement, firewall blocking,\n   or other controls demonstrably preventing or containing activity.\n\n5. ASSURANCE / EVIDENCE LIMITATION\n   Missing monitoring evidence, unavailable backup evidence, stale\n   timestamps, missing test-restore verification, or other limitations\n   affecting what the environment can prove.\n\n6. ROUTINE OPERATIONAL MAINTENANCE\n   Available image updates, normal patching activity, feed updates,\n   or other maintenance that is not independently evidence of a\n   security vulnerability.\n\nINTERPRETATION RULES\n\n- Detected security activity is not automatically evidence of successful compromise.\n- Failed SSH/authentication attempts do not establish successful access.\n- IDS/Suricata alerts indicate detected activity unless the evidence explicitly establishes compromise.\n- Blocked DNS requests demonstrate enforcement and do not establish deliberate user behaviour or successful access.\n- CrowdSec blocking demonstrates active prevention; it does not establish that an attack succeeded.\n- Scanner/Greenbone results must retain their stated severity and disposition.\n- Accepted risks are not active vulnerabilities unless the source explicitly says they are.\n- Warning/attention/assurance states must not be described as confirmed security incidents unless the evidence explicitly establishes one.\n- Do not invent compromise, user intent, successful exploitation, or remediation outcomes.\n- Keep confirmed findings, investigations, detected activity, controls and assurance gaps visibly distinct.\n\n'''

text = text.replace(anchor, addition + anchor, 1)
path.write_text(text, encoding="utf-8")
print(f"Patched: {path}")
PY

sudo python3 -m py_compile "$TARGET"

echo
echo "Engineering runbook generator patched successfully."
echo "Target: $TARGET"
echo "Backup: $BACKUP"
