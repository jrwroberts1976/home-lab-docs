#!/usr/bin/env bash
set -euo pipefail

# Stage 4: add lightweight monitoring to the already-deployed Pi-hole flock wrapper.
# Run as root on each Pi-hole collector host:
#   sudo bash scripts/pihole-stage4-flock-monitoring-deploy.sh
#
# Exports:
#   homelab_pihole_collector_last_success_timestamp_seconds
#   homelab_pihole_collector_lock_skips_total
#   homelab_pihole_collector_last_run_success
#
# Individual lock skips are NOT alerts. Grafana should alert on stale successful
# collection; the skip counter is diagnostic/trending data.

WRAPPER="/usr/local/bin/pihole-query-metrics-locked.sh"
COLLECTOR="/usr/local/bin/pihole-query-metrics.sh"
LOCKFILE="/run/lock/pihole-query-metrics.lock"
STATE_DIR="/var/lib/pihole-collector-monitor"
STAMP="$(date +%Y%m%d-%H%M%S)"
HOST_LABEL="$(hostname -s | tr '[:upper:]' '[:lower:]')"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run as root (sudo)." >&2
  exit 1
fi

for cmd in flock awk grep mv mkdir chmod date hostname; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: missing command: $cmd" >&2; exit 1; }
done

[[ -x "$COLLECTOR" ]] || { echo "ERROR: collector missing/not executable: $COLLECTOR" >&2; exit 1; }
[[ -x "$WRAPPER" ]] || { echo "ERROR: Stage 3 wrapper missing/not executable: $WRAPPER" >&2; exit 1; }

# Determine the exact textfile directory node-exporter is configured to scrape.
# Prefer live process arguments, then Debian's environment file. Refuse to guess.
TEXTFILE_DIR=""
for pid in $(pgrep -f 'prometheus-node-exporter|node_exporter' 2>/dev/null || true); do
  [[ -r "/proc/$pid/cmdline" ]] || continue
  args="$(tr '\0' ' ' < "/proc/$pid/cmdline")"
  case "$args" in
    *--collector.textfile.directory=*)
      TEXTFILE_DIR="$(printf '%s\n' "$args" | sed -n 's/.*--collector\.textfile\.directory=\([^ ]*\).*/\1/p' | head -1)"
      [[ -n "$TEXTFILE_DIR" ]] && break
      ;;
  esac
done

if [[ -z "$TEXTFILE_DIR" && -r /etc/default/prometheus-node-exporter ]]; then
  TEXTFILE_DIR="$(sed -n 's/.*--collector\.textfile\.directory=\([^ "'"']*\).*/\1/p' /etc/default/prometheus-node-exporter | head -1)"
fi

if [[ -z "$TEXTFILE_DIR" ]]; then
  echo "ERROR: could not prove node-exporter textfile directory; refusing to guess." >&2
  echo "Inspect node-exporter arguments and rerun once --collector.textfile.directory is configured." >&2
  exit 1
fi

mkdir -p "$TEXTFILE_DIR" "$STATE_DIR"
OUT="$TEXTFILE_DIR/pihole_collector_flock.prom"

BACKUP="${WRAPPER}.bak-${STAMP}-stage4"
cp -a "$WRAPPER" "$BACKUP"

cat > "$WRAPPER" <<'WRAPPER'
#!/usr/bin/env bash
set -u

COLLECTOR="${COLLECTOR:-/usr/local/bin/pihole-query-metrics.sh}"
LOCKFILE="${LOCKFILE:-/run/lock/pihole-query-metrics.lock}"
STATE_DIR="${STATE_DIR:-/var/lib/pihole-collector-monitor}"
TEXTFILE_DIR="${TEXTFILE_DIR:?TEXTFILE_DIR must be set by installed wrapper}"
HOST_LABEL="${HOST_LABEL:?HOST_LABEL must be set by installed wrapper}"
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
WRAPPER

# Bake the detected host-specific values into the wrapper without changing its logic.
sed -i \
  -e "s#TEXTFILE_DIR=\"\${TEXTFILE_DIR:?TEXTFILE_DIR must be set by installed wrapper}\"#TEXTFILE_DIR=\"$TEXTFILE_DIR\"#" \
  -e "s#HOST_LABEL=\"\${HOST_LABEL:?HOST_LABEL must be set by installed wrapper}\"#HOST_LABEL=\"$HOST_LABEL\"#" \
  "$WRAPPER"
chmod 0755 "$WRAPPER"

# Seed metrics with one normal successful run.
"$WRAPPER"

echo "Stage 4 flock monitoring deployed."
echo "Host label:        $HOST_LABEL"
echo "Collector:         $COLLECTOR"
echo "Wrapper:           $WRAPPER"
echo "Wrapper backup:    $BACKUP"
echo "Textfile directory:$TEXTFILE_DIR"
echo "Metrics file:      $OUT"
echo
echo "Current metrics:"
cat "$OUT"
