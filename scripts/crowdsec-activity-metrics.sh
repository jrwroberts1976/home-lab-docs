#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="/home/james/docker/data/monitoring/node-exporter/textfile"
OUT="${OUT_DIR}/crowdsec_activity.prom"
TMP="$(mktemp "${OUT}.tmp.XXXXXX")"

trap 'rm -f "$TMP"' EXIT

NOW="$(date +%s)"

ALERTS="$(
  docker exec crowdsec \
    cscli alerts list --since 24h -o json
)"

LOCAL_DECISION_IPS="$(
  jq -r '
    [
      .[]? |
      .decisions[]? |
      select(
        (.scope // "" | ascii_downcase) == "ip"
      ) |
      .value //
      empty
    ] |
    unique |
    length
  ' <<< "$ALERTS"
)"

BLOCKED_PACKETS="$(
  journalctl -k --since "-24 hours" --no-pager -o cat |
  grep -c 'crowdsec:' ||
  true
)"

BLOCKED_SOURCE_IPS="$(
  journalctl -k --since "-24 hours" --no-pager -o cat |
  sed -n 's/.*crowdsec: .*SRC=\([^ ]*\).*/\1/p' |
  sort -u |
  awk 'NF { count++ } END { print count + 0 }'
)"

install -d -m 0755 "$OUT_DIR"

{
  echo '# HELP homelab_crowdsec_local_decision_ips_24h Unique IPs added to locally generated CrowdSec decisions during the last 24 hours.'
  echo '# TYPE homelab_crowdsec_local_decision_ips_24h gauge'
  echo "homelab_crowdsec_local_decision_ips_24h{host=\"main\"} ${LOCAL_DECISION_IPS}"

  echo '# HELP homelab_crowdsec_blocked_source_ips_24h Unique source IPs actually blocked by CrowdSec during the last 24 hours.'
  echo '# TYPE homelab_crowdsec_blocked_source_ips_24h gauge'
  echo "homelab_crowdsec_blocked_source_ips_24h{host=\"main\"} ${BLOCKED_SOURCE_IPS}"

  echo '# HELP homelab_crowdsec_blocked_packets_24h Packets blocked by CrowdSec during the last 24 hours.'
  echo '# TYPE homelab_crowdsec_blocked_packets_24h gauge'
  echo "homelab_crowdsec_blocked_packets_24h{host=\"main\"} ${BLOCKED_PACKETS}"

  echo '# HELP homelab_crowdsec_activity_check_timestamp_seconds Time of the latest CrowdSec activity check.'
  echo '# TYPE homelab_crowdsec_activity_check_timestamp_seconds gauge'
  echo "homelab_crowdsec_activity_check_timestamp_seconds{host=\"main\"} ${NOW}"
} > "$TMP"

chmod 0644 "$TMP"
mv "$TMP" "$OUT"
