#!/usr/bin/env bash
set -euo pipefail

# Guarded Stage 2 change for Pi-hole notification grouping.
# Adds a route-local group_by so individual Pi-hole alert instances are not
# folded together by the broad parent policy grouping.
#
# Usage:
#   ./scripts/pihole-stage2-group-by.sh --dry-run
#   sudo ./scripts/pihole-stage2-group-by.sh --apply

MODE="${1:---dry-run}"
FILE="${PIHOLE_POLICY_FILE:-/home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-notification-policy.yml}"

case "$MODE" in
  --dry-run|--apply) ;;
  *) echo "Usage: $0 [--dry-run|--apply]" >&2; exit 2 ;;
esac

[[ -f "$FILE" ]] || { echo "ERROR: not found: $FILE" >&2; exit 1; }
[[ -r "$FILE" ]] || { echo "ERROR: not readable: $FILE" >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

python3 - "$FILE" "$TMP" <<'PY'
import sys
src,dst=sys.argv[1:]
lines=open(src).read().splitlines(True)
start=None
end=None
for i,line in enumerate(lines):
    if "- receiver: Homelab Email Alerts" in line:
        block="".join(lines[i:i+8])
        if "['service', '=', 'pihole']" in block and "['alert_type', '=', 'policy-category']" in block:
            start=i
            break
if start is None:
    raise SystemExit("ERROR: Pi-hole policy-category route not found")
for i in range(start+1,len(lines)):
    if lines[i].startswith("      - receiver:"):
        end=i
        break
if end is None:
    end=len(lines)
block=lines[start:end]
if any("group_by:" in x for x in block):
    raise SystemExit("ERROR: Pi-hole route already has group_by; refusing automatic change")
insert=None
for j,x in enumerate(block):
    if "repeat_interval:" in x:
        insert=j
        break
if insert is None:
    raise SystemExit("ERROR: repeat_interval not found in Pi-hole route")
block[insert:insert]=[
    "        group_by:\n",
    "          - '...'\n",
]
lines[start:end]=block
open(dst,"w").writelines(lines)
PY

echo "Target: $FILE"
echo ""
echo "Proposed diff:"
DIFF="$(diff -u "$FILE" "$TMP" || true)"
printf '%s\n' "$DIFF"
echo ""

# Safety: require exactly two added YAML lines and no removals.
# Use awk rather than grep pipelines so a zero-match count does not trip set -e.
ADDED="$(printf '%s\n' "$DIFF" | awk '/^\+/ && !/^\+\+\+/ {c++} END {print c+0}')"
REMOVED="$(printf '%s\n' "$DIFF" | awk '/^-/ && !/^---/ {c++} END {print c+0}')"
if [[ "$ADDED" != "2" || "$REMOVED" != "0" ]]; then
  echo "ERROR: unexpected diff (added=$ADDED removed=$REMOVED); refusing." >&2
  exit 1
fi

if [[ "$MODE" == "--dry-run" ]]; then
  echo "DRY RUN ONLY. No file changed."
  echo "Expected addition inside only the Pi-hole route:"
  echo "        group_by:"
  echo "          - '...'"
  echo ""
  echo "After reviewing the diff, run:"
  echo "  sudo $0 --apply"
  exit 0
fi

[[ $EUID -eq 0 ]] || { echo "ERROR: --apply must be run with sudo/root" >&2; exit 1; }
BACKUP="${FILE}.bak-$(date +%Y%m%d-%H%M%S)-stage2"
cp -a "$FILE" "$BACKUP"
install -m "$(stat -c '%a' "$FILE")" -o "$(stat -c '%u' "$FILE")" -g "$(stat -c '%g' "$FILE")" "$TMP" "$FILE"

echo "Applied Pi-hole route-local group_by only."
echo "Backup: $BACKUP"
echo ""
echo "Verification:"
grep -nE "receiver:|service|alert_type|group_by:|'\.\.\.'|group_wait:|group_interval:|repeat_interval:" "$FILE" || true
echo ""
echo "IMPORTANT: this script deliberately does NOT restart Grafana."
echo "Use the established Grafana restart/reload procedure and inspect provisioning logs before another test."
