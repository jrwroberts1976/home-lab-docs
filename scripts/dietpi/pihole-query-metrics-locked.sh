#!/usr/bin/env bash
set -u

COLLECTOR="${COLLECTOR:-/usr/local/bin/pihole-query-metrics.sh}"
LOCKFILE="${LOCKFILE:-/run/lock/pihole-query-metrics.lock}"
STATE_DIR="${STATE_DIR:-/var/lib/pihole-collector-monitor}"
TEXTFILE_DIR="/var/lib/prometheus/node-exporter"
HOST_LABEL="dietpi"
OUT="$TEXTFILE_DIR/pihole_collector_flock.prom"
STATE_LOCK="$STATE_DIR/state.lock"
SKIPS_FILE="$STATE_DIR/lock_skips_total"
SUCCESS_FILE="$STATE_DIR/last_success_timestamp_seconds"
LAST_RUN_FILE="$STATE_DIR/last_run_success"

mkdir -p "$(dirname "$LOCKFILE")" "$STATE_DIR" "$TEXTFILE_DIR"
[[ -f "$SKIPS_FILE" ]] || printf '0\n' > "$SKIPS_FILE"
[[ -f "$SUCCESS_FILE" ]] || printf '0\n' > "$SUCCESS_FILE"
[[ -f "$LAST_RUN_FILE" ]] || printf '0\n' > "$LAST_RUN_FILE"

write_metrics() {
  local skips success last tmp
  skips="$(cat "$SKIPS_FILE" 2>/dev/null || echo 0)"
  success="$(cat "$SUCCESS_FILE" 2>/dev/null || echo 0)"
  last="$(cat "$LAST_RUN_FILE" 2>/dev/null || echo 0)"
  tmp="${OUT}.$$"
  cat > "$tmp" <<METRICS
# HELP homelab_pihole_collector_last_success_timestamp_seconds Unix timestamp of the most recent successful Pi-hole query collector run.
# TYPE homelab_pihole_collector_last_success_timestamp_seconds gauge
homelab_pihole_collector_last_success_timestamp_seconds{host="$HOST_LABEL",collector="pihole-query-metrics"} $success
# HELP homelab_pihole_collector_lock_skips_total Number of collector starts skipped because another instance held the flock lock.
# TYPE homelab_pihole_collector_lock_skips_total counter
homelab_pihole_collector_lock_skips_total{host="$HOST_LABEL",collector="pihole-query-metrics"} $skips
# HELP homelab_pihole_collector_last_run_success Whether the last collector execution that obtained the lock completed successfully.
# TYPE homelab_pihole_collector_last_run_success gauge
homelab_pihole_collector_last_run_success{host="$HOST_LABEL",collector="pihole-query-metrics"} $last
METRICS
  chmod 0644 "$tmp"
  mv "$tmp" "$OUT"
}

[[ -x "$COLLECTOR" ]] || { echo "ERROR: collector is not executable: $COLLECTOR" >&2; exit 1; }

# The main lock owns collector single-instance execution.
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  # Serialize state modification separately from the collector execution lock.
  exec 8>"$STATE_LOCK"
  flock 8
  skips="$(cat "$SKIPS_FILE" 2>/dev/null || echo 0)"
  [[ "$skips" =~ ^[0-9]+$ ]] || skips=0
  printf '%s\n' "$((skips + 1))" > "$SKIPS_FILE"
  write_metrics
  flock -u 8
  logger -t pihole-query-metrics "collector skipped: previous instance still running"
  echo "collector skipped: previous instance still running" >&2
  exit 0
fi

"$COLLECTOR" "$@"
rc=$?

exec 8>"$STATE_LOCK"
flock 8
if [[ $rc -eq 0 ]]; then
  date +%s > "$SUCCESS_FILE"
  printf '1\n' > "$LAST_RUN_FILE"
else
  printf '0\n' > "$LAST_RUN_FILE"
fi
write_metrics
flock -u 8

exit "$rc"
