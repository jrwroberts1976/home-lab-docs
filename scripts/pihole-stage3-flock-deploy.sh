#!/usr/bin/env bash
set -euo pipefail

# Stage 3 Pi-hole collector hardening.
# Run locally on the Pi-hole host:
#   sudo bash scripts/pihole-stage3-flock-deploy.sh ids01
#   sudo bash scripts/pihole-stage3-flock-deploy.sh dietpi
#
# The actual collector is never modified. A locked wrapper is installed and
# only the scheduler is redirected to it. Backups are created before changes.

ROLE="${1:-}"
COLLECTOR="/usr/local/bin/pihole-query-metrics.sh"
WRAPPER="/usr/local/bin/pihole-query-metrics-locked.sh"
LOCKFILE="/run/lock/pihole-query-metrics.lock"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
  echo "ERROR: run as root (sudo)." >&2
  exit 1
fi

case "$ROLE" in
  ids01|dietpi) ;;
  *)
    echo "Usage: sudo $0 {ids01|dietpi}" >&2
    exit 2
    ;;
esac

if [[ ! -x "$COLLECTOR" ]]; then
  echo "ERROR: collector not found/executable: $COLLECTOR" >&2
  exit 1
fi

if ! command -v flock >/dev/null 2>&1; then
  echo "ERROR: flock not installed (normally provided by util-linux)." >&2
  exit 1
fi

cat > "$WRAPPER" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
COLLECTOR="${COLLECTOR:-/usr/local/bin/pihole-query-metrics.sh}"
LOCKFILE="${LOCKFILE:-/run/lock/pihole-query-metrics.lock}"

if [[ ! -x "$COLLECTOR" ]]; then
  echo "ERROR: collector is not executable: $COLLECTOR" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOCKFILE")"

# fd 9 owns the lock for the lifetime of the collector process.
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  logger -t pihole-query-metrics "collector skipped: previous instance still running"
  echo "collector skipped: previous instance still running" >&2
  exit 0
fi

exec "$COLLECTOR" "$@"
WRAPPER
chmod 0755 "$WRAPPER"

echo "Installed wrapper: $WRAPPER"
echo "Collector remains unchanged: $COLLECTOR"

if [[ "$ROLE" == "ids01" ]]; then
  SERVICE="pihole-query-metrics.service"
  TIMER="pihole-query-metrics.timer"

  if ! systemctl cat "$SERVICE" >/dev/null 2>&1; then
    echo "ERROR: expected service not found: $SERVICE" >&2
    exit 1
  fi

  if ! systemctl cat "$SERVICE" | grep -Fq "$COLLECTOR"; then
    echo "ERROR: $SERVICE does not currently reference $COLLECTOR; refusing automatic change." >&2
    systemctl cat "$SERVICE" >&2
    exit 1
  fi

  BACKUP_DIR="/root/pihole-stage3-backup-$STAMP"
  mkdir -p "$BACKUP_DIR"
  systemctl cat "$SERVICE" > "$BACKUP_DIR/${SERVICE}.txt"
  systemctl cat "$TIMER" > "$BACKUP_DIR/${TIMER}.txt" 2>/dev/null || true

  DROPIN_DIR="/etc/systemd/system/${SERVICE}.d"
  mkdir -p "$DROPIN_DIR"
  if [[ -f "$DROPIN_DIR/10-flock.conf" ]]; then
    cp -a "$DROPIN_DIR/10-flock.conf" "$BACKUP_DIR/10-flock.conf.preexisting"
  fi

  cat > "$DROPIN_DIR/10-flock.conf" <<EOF
[Service]
ExecStart=
ExecStart=$WRAPPER
EOF

  systemctl daemon-reload
  systemctl reset-failed "$SERVICE" || true
  systemctl start "$SERVICE"
  systemctl enable --now "$TIMER" >/dev/null 2>&1 || systemctl start "$TIMER"

  echo
  echo "ids-01 scheduler hardened."
  echo "Backup: $BACKUP_DIR"
  systemctl status "$SERVICE" --no-pager -l || true
  systemctl status "$TIMER" --no-pager -l || true

else
  # DietPi uses cron for this collector. Only change a line that directly calls
  # the known collector path. Preserve the complete root crontab first.
  CRON_BACKUP="/root/pihole-root-crontab-$STAMP.bak"
  CURRENT_CRON="$(mktemp)"
  NEW_CRON="$(mktemp)"
  trap 'rm -f "$CURRENT_CRON" "$NEW_CRON"' EXIT

  crontab -l > "$CURRENT_CRON" 2>/dev/null || true
  cp "$CURRENT_CRON" "$CRON_BACKUP"

  MATCHES="$(grep -F "$COLLECTOR" "$CURRENT_CRON" | grep -v '^#' | wc -l)"
  if [[ "$MATCHES" -ne 1 ]]; then
    echo "ERROR: expected exactly one active root cron line containing $COLLECTOR; found $MATCHES." >&2
    echo "No cron change made. Backup: $CRON_BACKUP" >&2
    grep -nF "$COLLECTOR" "$CURRENT_CRON" >&2 || true
    exit 1
  fi

  sed "s#${COLLECTOR}#${WRAPPER}#" "$CURRENT_CRON" > "$NEW_CRON"
  crontab "$NEW_CRON"

  echo
  echo "DietPi cron scheduler hardened."
  echo "Backup: $CRON_BACKUP"
  crontab -l | grep -nF "$WRAPPER" || true

  # Safe immediate functional run; this does not modify the collector itself.
  "$WRAPPER"
fi

echo
echo "Stage 3 deployment complete for role=$ROLE"
echo "Next: run scripts/pihole-stage3-flock-verify.sh locally on this host."
