#!/usr/bin/env bash
set -euo pipefail

PROM_URL="${PROM_URL:-http://localhost:9090}"
LOOKBACK="${LOOKBACK:-300}"
METRIC="pihole_blocked_client_category_last_event_timestamp_seconds"
NOW="$(date +%s)"

query() {
  curl -fsS -G "$PROM_URL/api/v1/query" --data-urlencode "query=$1"
}

run_python() {
  local code="$1"
  shift
  python3 -c "$code" "$@"
}

printf '# Pi-hole policy alert diagnosis\n'
printf 'captured_at=%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
printf 'prometheus=%s\n' "$PROM_URL"
printf 'lookback=%ss\n\n' "$LOOKBACK"

printf '## Active policy-series inside %ss window\n' "$LOOKBACK"
query "($METRIC) > time() - $LOOKBACK" | run_python '
import json, sys, datetime
now=int(sys.argv[1])
d=json.load(sys.stdin)
r=d.get("data",{}).get("result",[])
if not r:
    print("NONE")
    raise SystemExit
rows=[]
for x in r:
    m=x.get("metric",{})
    ts=float(x["value"][1])
    age=now-ts
    rows.append((age,m,ts))
rows.sort(key=lambda row: (
    row[0],
    row[1].get("host",""),
    row[1].get("category",""),
    row[1].get("client",""),
    row[1].get("domain","")
))
for age,m,ts in rows:
    when=datetime.datetime.fromtimestamp(ts).astimezone().strftime("%Y-%m-%d %H:%M:%S %Z")
    print(f"age={age:6.1f}s event={when} host={m.get('host','?')} category={m.get('category','?')} client={m.get('client','?')} domain={m.get('domain','?')}")
' "$NOW"

printf '\n## Series count by host/category\n'
query "count by (host,category) (($METRIC) > time() - $LOOKBACK)" | run_python '
import json,sys
d=json.load(sys.stdin)
r=d.get("data",{}).get("result",[])
if not r:
    print("NONE")
else:
    for x in sorted(r, key=lambda y:(y["metric"].get("host",""),y["metric"].get("category",""))):
        m=x["metric"]
        print(f"host={m.get('host','?')} category={m.get('category','?')} active_series={x['value'][1]}")
'

printf '\n## Newest event age by host/category\n'
query "time() - max by (host,category) ($METRIC)" | run_python '
import json,sys
d=json.load(sys.stdin)
r=d.get("data",{}).get("result",[])
if not r:
    print("NONE")
else:
    for x in sorted(r, key=lambda y:(y["metric"].get("host",""),y["metric"].get("category",""))):
        m=x["metric"]
        print(f"host={m.get('host','?')} category={m.get('category','?')} newest_age_seconds={float(x['value'][1]):.1f}")
'

printf '\nInterpretation:\n'
printf -- '- Any series in the first section is still capable of satisfying the current 300s alert lookback.\n'
printf -- '- Multiple client/domain labelsets in one category can generate grouped firing/resolved updates even when they belong to different events.\n'
printf -- '- If the first section is NONE but Grafana still reports FIRING, inspect Grafana state/rule labels next.\n'
