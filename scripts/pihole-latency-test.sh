#!/usr/bin/env bash
set -euo pipefail

PROM_URL="${PROM_URL:-http://localhost:9090}"
OUT_DIR="${OUT_DIR:-$HOME/pihole-latency-tests}"
CLIENT="${CLIENT:-}"
POLL_SECONDS="${POLL_SECONDS:-3}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"

usage() {
  echo "Usage: $0 dietpi|ids-01 [domain]"
  echo
  echo "Examples:"
  echo "  $0 dietpi www.betfred.com"
  echo "  $0 ids-01 flashcasino.com"
  echo "  CLIENT=192.168.2.220 $0 dietpi www.betfred.com"
}

[[ $# -ge 1 ]] || { usage; exit 2; }

case "$1" in
  dietpi)
    HOST="dietpi"
    DNS_SERVER="192.168.2.48"
    DOMAIN="${2:-www.betfred.com}"
    ;;
  ids-01)
    HOST="ids-01"
    DNS_SERVER="192.168.2.242"
    DOMAIN="${2:-flashcasino.com}"
    ;;
  *)
    usage
    exit 2
    ;;
esac

CATEGORY="${CATEGORY:-gambling}"
mkdir -p "$OUT_DIR"
stamp="$(date +%Y%m%d-%H%M%S)"
log="$OUT_DIR/${stamp}-${HOST}-${CATEGORY}.csv"
details="$OUT_DIR/${stamp}-${HOST}-${CATEGORY}.txt"

selector="host=\"$HOST\",category=\"$CATEGORY\""
if [[ -n "$CLIENT" ]]; then
  selector+=",client=\"$CLIENT\""
fi
query="pihole_blocked_client_category_last_event_timestamp_seconds{$selector}"

prom_value() {
  curl -fsS -G "$PROM_URL/api/v1/query" \
    --data-urlencode "query=$query" |
    python3 -c '
import json,sys
d=json.load(sys.stdin)
r=d.get("data",{}).get("result",[])
print(r[0]["value"][1] if r else "")
'
}

old="$(prom_value || true)"
start_epoch="$(date +%s)"
start_text="$(date '+%Y-%m-%d %H:%M:%S %Z')"

{
  echo "test_id,host,category,domain,dns_server,dns_start_epoch,dns_start,pihole_event_epoch,prom_visible_epoch,prom_visible,email_receipt_epoch,email_receipt,end_to_end_seconds"
  echo -n "$stamp,$HOST,$CATEGORY,$DOMAIN,$DNS_SERVER,$start_epoch,\"$start_text\","
} > "$log"

{
  echo "Pi-hole policy latency test"
  echo "Test ID:       $stamp"
  echo "Host:          $HOST"
  echo "DNS server:    $DNS_SERVER"
  echo "Domain:        $DOMAIN"
  echo "Category:      $CATEGORY"
  echo "Client filter: ${CLIENT:-<none>}"
  echo "Prometheus:    $PROM_URL"
  echo "Previous metric timestamp: ${old:-<none>}"
  echo
  echo "TEST START: $start_text"
} | tee "$details"

nslookup "$DOMAIN" "$DNS_SERVER" | tee -a "$details"
echo "TEST DNS END: $(date '+%Y-%m-%d %H:%M:%S %Z')" | tee -a "$details"

deadline=$((start_epoch + TIMEOUT_SECONDS))
event=""
visible_epoch=""
while (( $(date +%s) <= deadline )); do
  v="$(prom_value || true)"
  if [[ -n "$v" ]]; then
    iv="${v%.*}"
    if [[ "$v" != "$old" && "$iv" -ge $((start_epoch - 10)) ]]; then
      event="$v"
      visible_epoch="$(date +%s)"
      break
    fi
  fi
  sleep "$POLL_SECONDS"
done

if [[ -z "$event" ]]; then
  echo "ERROR: new Prometheus event not observed within ${TIMEOUT_SECONDS}s" | tee -a "$details" >&2
  echo ",,,,,," >> "$log"
  exit 1
fi

visible_text="$(date -d "@$visible_epoch" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S %Z')"
event_int="${event%.*}"
event_text="$(date -d "@$event_int" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || echo "$event")"

echo "PI-HOLE EVENT:      $event_text ($event)" | tee -a "$details"
echo "PROMETHEUS VISIBLE: $visible_text" | tee -a "$details"
echo "DNS -> Prometheus:  $((visible_epoch-start_epoch)) seconds" | tee -a "$details"

echo "$event,$visible_epoch,\"$visible_text\",,,," >> "$log"

echo
echo "Result files:"
echo "  $details"
echo "  $log"
echo
echo "When the Grafana email arrives, record its receipt time."
echo "End-to-end latency = email receipt epoch - $start_epoch"
