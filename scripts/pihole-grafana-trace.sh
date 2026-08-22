#!/usr/bin/env bash
set -u

# Read-only helper for tracing a known Pi-hole latency test through Grafana.
# Usage:
#   ./scripts/pihole-grafana-trace.sh [YYYY-MM-DDTHH:MM:SS]
# Example:
#   ./scripts/pihole-grafana-trace.sh 2026-08-22T05:57:00

START="${1:-2026-08-22T05:57:00}"
GRAFANA_CONTAINER="${GRAFANA_CONTAINER:-grafana}"
PROMETHEUS="${PROMETHEUS:-http://localhost:9090}"

printf '# Pi-hole Grafana trace\n'
printf 'captured_at=%s\n' "$(date '+%F %T %Z')"
printf 'start=%s\n' "$START"
printf 'grafana_container=%s\n' "$GRAFANA_CONTAINER"
printf 'prometheus=%s\n\n' "$PROMETHEUS"

printf '## Grafana container\n'
docker ps --filter "name=${GRAFANA_CONTAINER}" --format 'name={{.Names}} image={{.Image}} status={{.Status}} ports={{.Ports}}' || true
printf '\n'

printf '## Current Pi-hole policy series\n'
QUERY='pihole_blocked_client_category_last_event_timestamp_seconds'
RESP="$(curl -fsS -G "$PROMETHEUS/api/v1/query" --data-urlencode "query=$QUERY" 2>&1)" || {
  printf 'Prometheus query failed: %s\n\n' "$RESP"
  RESP=''
}
if [[ -n "$RESP" ]]; then
  python3 -c '
import json,sys,datetime
j=json.loads(sys.argv[1])
rows=j.get("data",{}).get("result",[])
if not rows:
    print("NONE")
for x in sorted(rows,key=lambda y:(y.get("metric",{}).get("host",""),y.get("metric",{}).get("category",""),y.get("metric",{}).get("client",""))):
    m=x.get("metric",{})
    try:
        ts=float(x.get("value",[0,0])[1])
        when=datetime.datetime.fromtimestamp(ts).astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")
    except Exception:
        when="?"
    print("host=%s category=%s client=%s event=%s value=%s" % (m.get("host","?"),m.get("category","?"),m.get("client","?"),when,x.get("value",["?","?"])[1]))
' "$RESP" || true
fi
printf '\n'

printf '## Grafana logs since %s\n' "$START"
# Broad alert/notifier terms first. This is read-only and deliberately does not restart Grafana.
docker logs --since "$START" "$GRAFANA_CONTAINER" 2>&1 \
  | grep -Ei 'pihole|alert|ngalert|scheduler|notifier|notification|contact|email|smtp|state|firing|resolved|eval' \
  | tail -n 500 || true
printf '\n'

printf '## Focused notification/error lines\n'
docker logs --since "$START" "$GRAFANA_CONTAINER" 2>&1 \
  | grep -Ei 'notify|notifier|notification|email|smtp|error|failed|failure|timeout' \
  | tail -n 250 || true
printf '\n'

printf 'Interpretation:\n'
printf '%s\n' '- Look for the first rule/state transition after Prometheus visibility.'
printf '%s\n' '- Then look for notification-policy/notifier/email activity after that transition.'
printf '%s\n' '- If the Prometheus event is present but no Grafana transition appears, inspect the provisioned rule/query next.'
printf '%s\n' '- If Grafana transitions to firing but no notifier/email activity follows, inspect notification routing/group timing next.'
printf '%s\n' '- This script is read-only; it does not modify or restart Grafana.'
