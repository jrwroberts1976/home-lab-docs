#!/usr/bin/env bash
set -euo pipefail

ALERT_DIR="${ALERT_DIR:-/home/james/docker/data/monitoring/grafana/provisioning/alerting}"
POLICY="${POLICY:-$ALERT_DIR/pihole-notification-policy.yml}"
RULES="${RULES:-$ALERT_DIR/pihole-policy-alerts.yml}"
BACKUP_DIR="${BACKUP_DIR:-$ALERT_DIR/backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$BACKUP_DIR/pihole-latency-$STAMP"

for f in "$POLICY" "$RULES"; do
  if [[ ! -r "$f" ]]; then
    echo "ERROR: cannot read $f" >&2
    exit 1
  fi
done

mkdir -p "$DEST"
cp -a "$POLICY" "$DEST/"
cp -a "$RULES" "$DEST/"

{
  echo "# Pi-hole alert timing baseline"
  echo "captured_at=$(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "host=$(hostname -f 2>/dev/null || hostname)"
  echo
  echo "## Notification policy timing"
  grep -nE 'receiver:|service.*pihole|alert_type.*policy-category|group_wait|group_interval|repeat_interval' "$POLICY" || true
  echo
  echo "## Alert evaluation / lookback"
  grep -nE 'interval:|time\(\) - ' "$RULES" || true
  echo
  echo "## SHA256"
  sha256sum "$POLICY" "$RULES"
} | tee "$DEST/baseline.txt"

echo
echo "Backup created: $DEST"
echo "Expected before Stage 1:"
echo "  Pi-hole policy group_wait:      1s"
echo "  Pi-hole policy group_interval:  5m"
echo "  Pi-hole policy repeat_interval: 24h"
echo "  Grafana evaluation interval:    1m"
echo "  Lookback:                       time() - 300"
