#!/bin/bash

HOST="dietpi"
DB="/etc/pihole/gravity.db"
OUT="/var/lib/prometheus/node-exporter/pihole_blocklists.prom"
TMP="${OUT}.tmp"

sql() {
  pihole-FTL sqlite3 "$DB" "$1" 2>/dev/null
}

now=$(date +%s)

enabled=$(sql "SELECT COUNT(*) FROM adlist WHERE enabled=1;")
total=$(sql "SELECT COUNT(*) FROM adlist;")
gravity_domains=$(sql "SELECT COUNT(DISTINCT domain) FROM gravity;")
failed=$(sql "SELECT COUNT(*) FROM adlist WHERE enabled=1 AND status IN (3,4);")
hard_failed=$(sql "SELECT COUNT(*) FROM adlist WHERE enabled=1 AND status=4;")
latest_update=$(sql "SELECT COALESCE(MAX(date_updated),0) FROM adlist WHERE enabled=1;")

if [ "${latest_update:-0}" -gt 0 ]; then
  gravity_age=$((now - latest_update))
else
  gravity_age=-1
fi

# -------------------------------
# Active DNS block tests
# -------------------------------

test_dns_block() {
  local domain="$1"
  local result

  result=$(dig @127.0.0.1 "$domain" A +short +time=2 +tries=1 2>/dev/null | head -1)

  # Pi-hole default NULL blocking returns 0.0.0.0.
  # Empty response and :: are also accepted blocking responses.
  if [ "$result" = "0.0.0.0" ] || [ "$result" = "::" ] || [ -z "$result" ]; then
    echo 1
  else
    echo 0
  fi
}

block_general=$(test_dns_block "ad-assets.futurecdn.net")
block_adult=$(test_dns_block "xhamstersexvideo.com.123freedownload.com")
block_gambling=$(test_dns_block "vip.039-vip1.com")
block_bypass=$(test_dns_block "ss.0001.xyz")
block_threat=$(test_dns_block "tz.0-0.site")

block_tests_expected=5
block_tests_passed=$(
  echo "$block_general + $block_adult + $block_gambling + $block_bypass + $block_threat" | bc
)

if [ "$block_tests_passed" -eq "$block_tests_expected" ]; then
  enforcement_health=1
else
  enforcement_health=0
fi

# List/download health
if [ "${enabled:-0}" -ge 5 ] && [ "${hard_failed:-0}" -eq 0 ]; then
  list_health=1
else
  list_health=0
fi

# Overall health requires both list health AND DNS enforcement
if [ "$list_health" -eq 1 ] && [ "$enforcement_health" -eq 1 ]; then
  health=1
else
  health=0
fi

{
  echo '# HELP pihole_blocklists_total Number of configured Pi-hole blocklists'
  echo '# TYPE pihole_blocklists_total gauge'
  echo "pihole_blocklists_total{host=\"$HOST\"} ${total:-0}"

  echo '# HELP pihole_blocklists_enabled Number of enabled Pi-hole blocklists'
  echo '# TYPE pihole_blocklists_enabled gauge'
  echo "pihole_blocklists_enabled{host=\"$HOST\"} ${enabled:-0}"

  echo '# HELP pihole_blocklists_failed Number of enabled lists unavailable during last update'
  echo '# TYPE pihole_blocklists_failed gauge'
  echo "pihole_blocklists_failed{host=\"$HOST\"} ${failed:-0}"

  echo '# HELP pihole_blocklists_hard_failed Lists unavailable with no local copy'
  echo '# TYPE pihole_blocklists_hard_failed gauge'
  echo "pihole_blocklists_hard_failed{host=\"$HOST\"} ${hard_failed:-0}"

  echo '# HELP pihole_gravity_domains Total unique domains currently in Gravity'
  echo '# TYPE pihole_gravity_domains gauge'
  echo "pihole_gravity_domains{host=\"$HOST\"} ${gravity_domains:-0}"

  echo '# HELP pihole_gravity_age_seconds Seconds since the newest blocklist update'
  echo '# TYPE pihole_gravity_age_seconds gauge'
  echo "pihole_gravity_age_seconds{host=\"$HOST\"} ${gravity_age:-1}"

  echo '# HELP pihole_blocklist_health Overall Pi-hole blocklist and enforcement health'
  echo '# TYPE pihole_blocklist_health gauge'
  echo "pihole_blocklist_health{host=\"$HOST\"} ${health}"

  echo '# HELP pihole_blocklist_download_health Pi-hole blocklist download/configuration health'
  echo '# TYPE pihole_blocklist_download_health gauge'
  echo "pihole_blocklist_download_health{host=\"$HOST\"} ${list_health}"

  echo '# HELP pihole_block_enforcement_health Overall active DNS blocking test health'
  echo '# TYPE pihole_block_enforcement_health gauge'
  echo "pihole_block_enforcement_health{host=\"$HOST\"} ${enforcement_health}"

  echo '# HELP pihole_block_tests_expected Number of active DNS blocking tests expected'
  echo '# TYPE pihole_block_tests_expected gauge'
  echo "pihole_block_tests_expected{host=\"$HOST\"} ${block_tests_expected}"

  echo '# HELP pihole_block_tests_passed Number of active DNS blocking tests currently passing'
  echo '# TYPE pihole_block_tests_passed gauge'
  echo "pihole_block_tests_passed{host=\"$HOST\"} ${block_tests_passed}"

  echo '# HELP pihole_block_test Active Pi-hole DNS blocking test by category'
  echo '# TYPE pihole_block_test gauge'
  echo "pihole_block_test{host=\"$HOST\",category=\"general\"} ${block_general}"
  echo "pihole_block_test{host=\"$HOST\",category=\"adult\"} ${block_adult}"
  echo "pihole_block_test{host=\"$HOST\",category=\"gambling\"} ${block_gambling}"
  echo "pihole_block_test{host=\"$HOST\",category=\"bypass\"} ${block_bypass}"
  echo "pihole_block_test{host=\"$HOST\",category=\"threat\"} ${block_threat}"

  echo '# HELP pihole_blocklist_info Per-list Pi-hole blocklist information'
  echo '# TYPE pihole_blocklist_info gauge'

  pihole-FTL sqlite3 -separator '|' "$DB" \
    "SELECT id, address, enabled, COALESCE(comment,''), COALESCE(status,0), COALESCE(number,0), COALESCE(invalid_domains,0), COALESCE(date_updated,0) FROM adlist ORDER BY id;" |
  while IFS='|' read -r id address enabled comment status number invalid updated; do
    comment=$(printf '%s' "$comment" | sed 's/\\/\\\\/g; s/"/\\"/g')
    address=$(printf '%s' "$address" | sed 's/\\/\\\\/g; s/"/\\"/g')

    echo "pihole_blocklist_info{id=\"$id\",name=\"$comment\",address=\"$address\",enabled=\"$enabled\",status=\"$status\"} 1"
    echo "pihole_blocklist_domains{id=\"$id\",name=\"$comment\"} ${number:-0}"
    echo "pihole_blocklist_invalid_domains{id=\"$id\",name=\"$comment\"} ${invalid:-0}"
    echo "pihole_blocklist_last_update_seconds{id=\"$id\",name=\"$comment\"} ${updated:-0}"
  done
} > "$TMP"

chown prometheus:prometheus "$TMP"
chmod 0644 "$TMP"
mv "$TMP" "$OUT"
