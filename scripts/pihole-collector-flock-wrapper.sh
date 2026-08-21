#!/usr/bin/env bash
set -euo pipefail

# Install this as a separate wrapper; do not overwrite the collector.
# Example runtime path:
#   /usr/local/bin/pihole-query-metrics-locked.sh
#
# Then point the existing cron job or systemd service at this wrapper
# AFTER checking the exact current invocation.

COLLECTOR="${COLLECTOR:-/usr/local/bin/pihole-query-metrics.sh}"
LOCKFILE="${LOCKFILE:-/run/lock/pihole-query-metrics.lock}"

if [[ ! -x "$COLLECTOR" ]]; then
  echo "ERROR: collector is not executable: $COLLECTOR" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOCKFILE")"

# -n = do not wait. If another run is active, exit cleanly instead of stacking.
if ! flock -n "$LOCKFILE" "$COLLECTOR" "$@"; then
  rc=$?
  if [[ $rc -eq 1 ]]; then
    logger -t pihole-query-metrics "collector skipped: previous instance still running"
    echo "collector skipped: previous instance still running" >&2
    exit 0
  fi
  exit "$rc"
fi
