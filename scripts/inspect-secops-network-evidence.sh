#!/usr/bin/env bash
set -euo pipefail

echo "===== SECURITY TEXTFILE ====="
sudo cat /var/lib/prometheus/node-exporter/security_review.prom 2>/dev/null || true

echo
echo "===== PROMETHEUS SECURITY METRICS ====="

curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query={__name__=~"homelab_security_.*"}' |
  jq .

echo
echo "===== SURICATA RECENT COUNTS ====="

curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=sum(increase(homelab_security_suricata_alerts[24h]))' |
  jq .

echo
echo "===== CROWDSEC RECENT COUNTS ====="

curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=sum(increase(homelab_security_crowdsec_blocks[24h]))' |
  jq .

echo
echo "===== PI-HOLE HEALTH ====="

curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=pihole_blocklist_health' |
  jq .

echo
echo "===== PI-HOLE BLOCK TESTS ====="

curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=pihole_block_tests_passed' |
  jq .

echo
echo "===== MONITORING TARGETS ====="

curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=up' |
  jq '.data.result[] |
      {
        job: .metric.job,
        instance: .metric.instance,
        host: .metric.host,
        value: .value[1]
      }'

echo
echo "===== RECENT SURICATA LOG VOLUME ====="

curl -sG 'http://localhost:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job="suricata"}' \
  --data-urlencode 'limit=20' |
  jq '{status,streams: (.data.result | length)}' 2>/dev/null || true

echo
echo "===== COMPLETE ====="
