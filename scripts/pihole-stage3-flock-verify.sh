#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:-}"
WRAPPER="/usr/local/bin/pihole-query-metrics-locked.sh"
COLLECTOR="/usr/local/bin/pihole-query-metrics.sh"
LOCKFILE="/run/lock/pihole-query-metrics.lock"

case "$ROLE" in
  ids01|dietpi) ;;
  *) echo "Usage: sudo $0 {ids01|dietpi}" >&2; exit 2 ;;
esac

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run this verifier as root: sudo $0 $ROLE" >&2
  exit 2
fi

RUN_OUT="$(mktemp /tmp/pihole-flock-verify-run.XXXXXX)"
RUN_ERR="$(mktemp /tmp/pihole-flock-verify-run.XXXXXX)"
cleanup(){ rm -f "$RUN_OUT" "$RUN_ERR"; }
trap cleanup EXIT

fail=0
ok(){ echo "PASS: $*"; }
bad(){ echo "FAIL: $*"; fail=1; }

[[ -x "$COLLECTOR" ]] && ok "collector executable" || bad "collector missing/not executable: $COLLECTOR"
[[ -x "$WRAPPER" ]] && ok "locked wrapper installed" || bad "wrapper missing/not executable: $WRAPPER"
command -v flock >/dev/null 2>&1 && ok "flock available" || bad "flock unavailable"

if [[ "$ROLE" == "ids01" ]]; then
  systemctl cat pihole-query-metrics.service | grep -Fq "$WRAPPER" \
    && ok "systemd service points at locked wrapper" \
    || bad "systemd service is not using locked wrapper"

  systemctl is-active --quiet pihole-query-metrics.timer \
    && ok "collector timer active" \
    || bad "collector timer not active"
else
  crontab -l 2>/dev/null | grep -v '^#' | grep -Fq "$WRAPPER" \
    && ok "root cron points at locked wrapper" \
    || bad "root cron is not using locked wrapper"
fi

# Functional run. Unique temp files avoid stale ownership collisions from
# earlier verifier runs.
if "$WRAPPER" >"$RUN_OUT" 2>"$RUN_ERR"; then
  ok "wrapper executes collector successfully"
else
  bad "wrapper functional run failed"
  cat "$RUN_ERR" >&2 || true
fi

# Concurrency proof: hold the lock ourselves and confirm the wrapper exits
# cleanly instead of starting a second collector.
exec 9>"$LOCKFILE"
if flock -n 9; then
  start="$(date +%s)"
  set +e
  output="$("$WRAPPER" 2>&1)"
  rc=$?
  set -e
  elapsed=$(( $(date +%s) - start ))
  if [[ $rc -eq 0 && "$output" == *"previous instance still running"* && $elapsed -lt 10 ]]; then
    ok "overlap attempt skipped cleanly (rc=0, ${elapsed}s)"
  else
    bad "overlap test unexpected: rc=$rc elapsed=${elapsed}s output=$output"
  fi
else
  bad "could not acquire test lock; another collector may already be running"
fi
exec 9>&-

# Confirm no stacked collector processes remain.
count="$(pgrep -fc '[p]ihole-query-metrics.sh' || true)"
if [[ "$count" -le 1 ]]; then
  ok "no stacked collector processes detected (count=$count)"
else
  bad "multiple collector processes detected (count=$count)"
fi

# Show recent skip evidence if available.
echo
echo "Recent flock/collector log evidence:"
if command -v journalctl >/dev/null 2>&1; then
  journalctl --since '-10 min' --no-pager 2>/dev/null | grep -F 'collector skipped: previous instance still running' | tail -5 || true
fi

echo
if [[ $fail -eq 0 ]]; then
  echo "RESULT: PASS — Pi-hole collector single-instance protection is working for role=$ROLE"
else
  echo "RESULT: FAIL — review failures above before considering Stage 3 complete"
fi
exit "$fail"
