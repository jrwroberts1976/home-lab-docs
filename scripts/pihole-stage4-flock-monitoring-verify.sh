#!/usr/bin/env bash
set -euo pipefail

WRAPPER="/usr/local/bin/pihole-query-metrics-locked.sh"
COLLECTOR="/usr/local/bin/pihole-query-metrics.sh"
STATE_DIR="/var/lib/pihole-collector-monitor"
LOCKFILE="/run/lock/pihole-query-metrics.lock"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run as root (sudo)." >&2
  exit 1
fi

fail=0
ok(){ echo "PASS: $*"; }
bad(){ echo "FAIL: $*"; fail=1; }

[[ -x "$COLLECTOR" ]] && ok "collector executable" || bad "collector missing/not executable"
[[ -x "$WRAPPER" ]] && ok "monitoring wrapper installed" || bad "monitoring wrapper missing"
[[ -d "$STATE_DIR" ]] && ok "state directory exists" || bad "state directory missing"

TEXTFILE_DIR="$(grep '^TEXTFILE_DIR=' "$WRAPPER" | head -1 | cut -d= -f2- | tr -d '"')"
HOST_LABEL="$(grep '^HOST_LABEL=' "$WRAPPER" | head -1 | cut -d= -f2- | tr -d '"')"
OUT="$TEXTFILE_DIR/pihole_collector_flock.prom"

[[ -n "$TEXTFILE_DIR" && -d "$TEXTFILE_DIR" ]] && ok "textfile directory resolved: $TEXTFILE_DIR" || bad "textfile directory unresolved"
[[ -f "$OUT" ]] && ok "metrics file exists: $OUT" || bad "metrics file missing: $OUT"

if [[ -f "$OUT" ]]; then
  grep -q '^homelab_pihole_collector_last_success_timestamp_seconds' "$OUT" && ok "last-success metric exported" || bad "last-success metric missing"
  grep -q '^homelab_pihole_collector_lock_skips_total' "$OUT" && ok "lock-skip counter exported" || bad "lock-skip counter missing"
  grep -q '^homelab_pihole_collector_last_run_success' "$OUT" && ok "last-run-success metric exported" || bad "last-run-success metric missing"
fi

before="$(cat "$STATE_DIR/lock_skips_total" 2>/dev/null || echo 0)"
exec 9>"$LOCKFILE"
if flock -n 9; then
  set +e
  output="$("$WRAPPER" 2>&1)"
  rc=$?
  set -e
  after="$(cat "$STATE_DIR/lock_skips_total" 2>/dev/null || echo 0)"
  if [[ $rc -eq 0 && "$output" == *"previous instance still running"* ]]; then
    ok "held-lock invocation skipped cleanly"
  else
    bad "held-lock invocation unexpected: rc=$rc output=$output"
  fi
  if [[ "$before" =~ ^[0-9]+$ && "$after" =~ ^[0-9]+$ && "$after" -eq $((before + 1)) ]]; then
    ok "lock skip counter incremented ($before -> $after)"
  else
    bad "lock skip counter did not increment as expected ($before -> $after)"
  fi
else
  bad "could not acquire test lock; collector may be running"
fi
exec 9>&-

if "$WRAPPER" >/dev/null 2>&1; then
  ok "normal wrapper run succeeds"
else
  bad "normal wrapper run failed"
fi

success_ts="$(cat "$STATE_DIR/last_success_timestamp_seconds" 2>/dev/null || echo 0)"
now="$(date +%s)"
if [[ "$success_ts" =~ ^[0-9]+$ && "$success_ts" -gt 0 && $((now-success_ts)) -lt 120 ]]; then
  ok "last-success timestamp is fresh ($((now-success_ts))s old)"
else
  bad "last-success timestamp is stale/invalid: $success_ts"
fi

last_run="$(cat "$STATE_DIR/last_run_success" 2>/dev/null || echo 0)"
[[ "$last_run" == "1" ]] && ok "last run recorded as successful" || bad "last run success metric is $last_run"

if command -v curl >/dev/null 2>&1 && curl -fsS http://localhost:9100/metrics >/dev/null 2>&1; then
  NODE_METRICS="$(curl -fsS http://localhost:9100/metrics)"
  printf '%s\n' "$NODE_METRICS" | grep -q 'homelab_pihole_collector_last_success_timestamp_seconds' && ok "node-exporter exposes Stage 4 metrics" || bad "node-exporter does not expose Stage 4 metrics"
else
  echo "INFO: localhost:9100 unavailable here; skip direct node-exporter check"
fi

echo
echo "Current Stage 4 metrics for host=$HOST_LABEL:"
cat "$OUT" 2>/dev/null || true

echo
if [[ $fail -eq 0 ]]; then
  echo "RESULT: PASS — Pi-hole flock monitoring is healthy on host=$HOST_LABEL"
else
  echo "RESULT: FAIL — review failures above"
fi
exit "$fail"
