#!/usr/bin/env bash
set -euo pipefail

SERVICE="${SERVICE:-pihole-query-metrics.service}"
TIMER="${TIMER:-pihole-query-metrics.timer}"
DB="${DB:-/home/james/docker/stacks/pihole-secondary/etc-pihole/pihole-FTL.db}"
TEXTFILE_DIR="${TEXTFILE_DIR:-/home/james/docker/data/monitoring/node-exporter/textfile}"
COLLECTOR="${COLLECTOR:-/usr/local/bin/pihole-query-metrics.sh}"

printf '# ids-01 Pi-hole collector inspection\n'
printf 'captured_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
printf 'host=%s\n\n' "$(hostname -f 2>/dev/null || hostname)"

printf '## systemd timer\n'
systemctl status "$TIMER" --no-pager || true
printf '\n## systemd service\n'
systemctl status "$SERVICE" --no-pager || true
printf '\n## unit definitions\n'
systemctl cat "$TIMER" || true
printf '\n'
systemctl cat "$SERVICE" || true

printf '\n## current collector\n'
if [[ -f "$COLLECTOR" ]]; then
  ls -l "$COLLECTOR"
  printf '\n-- first 220 lines --\n'
  sed -n '1,220p' "$COLLECTOR"
else
  echo "MISSING: $COLLECTOR"
fi

printf '\n## recent service logs\n'
journalctl -u "$SERVICE" --since '-15 min' --no-pager || true

printf '\n## collector process check\n'
ps -ef | grep '[p]ihole-query-metrics' || true

printf '\n## candidate Prometheus textfiles\n'
if [[ -d "$TEXTFILE_DIR" ]]; then
  find "$TEXTFILE_DIR" -maxdepth 1 -type f \( -name '*pihole*' -o -name '*query*' \) -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' 2>/dev/null | sort
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    printf '\n### %s\n' "$f"
    grep -E 'pihole_blocked_client_category_last_event_timestamp_seconds|adult|gambling|threat|bypass' "$f" | tail -n 80 || true
  done < <(find "$TEXTFILE_DIR" -maxdepth 1 -type f \( -name '*pihole*' -o -name '*query*' \) -print 2>/dev/null | sort)
else
  echo "MISSING DIR: $TEXTFILE_DIR"
fi

printf '\n## newest FTL query rows\n'
if [[ -r "$DB" ]]; then
  if command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 -readonly -header -column "$DB" '
      SELECT id,
             datetime(timestamp, "unixepoch", "localtime") AS event_time,
             timestamp,
             type,
             status,
             domain,
             client,
             reply_type,
             reply_time
      FROM queries
      ORDER BY timestamp DESC
      LIMIT 40;
    ' || true
  else
    echo 'sqlite3 not installed'
  fi
else
  echo "DB not readable: $DB"
fi

printf '\n## suspicious recent category domains in textfile output\n'
if [[ -d "$TEXTFILE_DIR" ]]; then
  grep -RHE 'xhamstersexvideo\.com\.123freedownload\.com|ss\.0001\.xyz|vip\.039-vip6\.com|tz\.0-0\.site' "$TEXTFILE_DIR" 2>/dev/null || true
fi

printf '\nInterpretation hints:\n'
printf -- '- If all four categories receive the same timestamp on every service run, the collector is likely refreshing synthetic/category-cache data rather than exporting true last-seen query times.\n'
printf -- '- Compare the .prom timestamps with the newest SQLite query rows and the systemd run times.\n'
printf -- '- Do not change Grafana or the collector schedule from this script; it is inspection-only.\n'
