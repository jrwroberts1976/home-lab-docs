#!/usr/bin/env bash
set -euo pipefail

POLICY="${POLICY:-/home/james/docker/data/monitoring/grafana/provisioning/alerting/pihole-notification-policy.yml}"
MODE="${1:---dry-run}"

if [[ "$MODE" != "--dry-run" && "$MODE" != "--apply" ]]; then
  echo "Usage: $0 [--dry-run|--apply]" >&2
  exit 2
fi

if [[ ! -r "$POLICY" ]]; then
  echo "ERROR: cannot read $POLICY" >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

python3 - "$POLICY" "$tmp" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
lines = src.read_text().splitlines(True)
starts = []
for i, line in enumerate(lines):
    stripped = line.lstrip()
    if stripped.startswith("- receiver:"):
        starts.append(i)
starts.append(len(lines))

matches = []
for n in range(len(starts)-1):
    a, b = starts[n], starts[n+1]
    block = "".join(lines[a:b])
    if ("service" in block and "pihole" in block and
        "alert_type" in block and "policy-category" in block):
        matches.append((a, b))

if len(matches) != 1:
    raise SystemExit(
        f"REFUSING CHANGE: expected exactly one Pi-hole policy-category route; found {len(matches)}"
    )

a, b = matches[0]
gi = [i for i in range(a, b) if lines[i].lstrip().startswith("group_interval:")]
if len(gi) != 1:
    raise SystemExit(
        f"REFUSING CHANGE: expected exactly one group_interval in target route; found {len(gi)}"
    )

i = gi[0]
old = lines[i]
value = old.split(":", 1)[1].strip()
if value not in {"5m", "30s"}:
    raise SystemExit(f"REFUSING CHANGE: unexpected current group_interval={value!r}")

indent = old[:len(old)-len(old.lstrip())]
lines[i] = f"{indent}group_interval: 30s\n"
dst.write_text("".join(lines))

print(f"Target route lines: {a+1}-{b}")
print(f"Current value: {value}")
print("Proposed value: 30s")
PY

echo
echo "Diff:"
diff -u "$POLICY" "$tmp" || true

if [[ "$MODE" == "--dry-run" ]]; then
  echo
  echo "DRY RUN ONLY. No file changed."
  echo "After reviewing the diff, run with sudo:"
  echo "  sudo $0 --apply"
  exit 0
fi

if cmp -s "$POLICY" "$tmp"; then
  echo "No change required; target route is already group_interval: 30s"
  exit 0
fi

stamp="$(date +%Y%m%d-%H%M%S)"
backup="${POLICY}.bak-${stamp}"
cp -a "$POLICY" "$backup"
cat "$tmp" > "$POLICY"

echo
echo "Applied only the Pi-hole policy-category group_interval change."
echo "Backup: $backup"
echo
echo "Verification:"
grep -nE 'receiver:|service.*pihole|alert_type.*policy-category|group_wait|group_interval|repeat_interval' "$POLICY" || true
echo
echo "IMPORTANT: this script deliberately does NOT restart Grafana."
echo "Use the established Grafana restart/reload procedure, then check provisioning logs."
