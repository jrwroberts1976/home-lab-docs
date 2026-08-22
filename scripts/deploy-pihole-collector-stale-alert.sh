#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3001}"
PROM_DS_UID="${PROM_DS_UID:-PBFA97CFB590B2093}"
UID="pihole_collector_stale"
TITLE="Pi-hole Query Collector Stale"

if [[ -z "${GRAFANA_TOKEN:-}" ]]; then
  echo "ERROR: GRAFANA_TOKEN is not set" >&2
  exit 1
fi

for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: missing $cmd" >&2; exit 1; }
done

# Alert if either Pi-hole collector has not completed successfully for >5 minutes.
# Individual flock skips intentionally do not alert.
EXPR='(time() - homelab_pihole_collector_last_success_timestamp_seconds{collector="pihole-query-metrics"}) > bool 300'

RULE_JSON="$(jq -n \
  --arg uid "$UID" \
  --arg title "$TITLE" \
  --arg expr "$EXPR" \
  --arg ds "$PROM_DS_UID" '
  {
    uid:$uid,
    orgID:1,
    folderUID:"homelab-alerts",
    ruleGroup:"DNS",
    title:$title,
    condition:"C",
    data:[
      {
        refId:"A",
        queryType:"",
        relativeTimeRange:{from:600,to:0},
        datasourceUid:$ds,
        model:{
          datasource:{type:"prometheus",uid:$ds},
          editorMode:"code",
          expr:$expr,
          instant:true,
          intervalMs:1000,
          maxDataPoints:43200,
          range:false,
          refId:"A"
        }
      },
      {
        refId:"B",
        queryType:"",
        relativeTimeRange:{from:0,to:0},
        datasourceUid:"-100",
        model:{conditions:[],datasource:{type:"__expr__",uid:"-100"},expression:"A",hide:false,reducer:"last",refId:"B",type:"reduce"}
      },
      {
        refId:"C",
        queryType:"",
        relativeTimeRange:{from:0,to:0},
        datasourceUid:"-100",
        model:{
          conditions:[{evaluator:{params:[0.5],type:"gt"},operator:{type:"and"},query:{params:["C"]},reducer:{params:[],type:"last"},type:"query"}],
          datasource:{type:"__expr__",uid:"-100"},
          expression:"B",
          refId:"C",
          type:"threshold"
        }
      }
    ],
    noDataState:"Alerting",
    execErrState:"Alerting",
    for:"2m",
    annotations:{
      summary:"Pi-hole query collector has stopped updating",
      description:"One or more Pi-hole query collectors have not completed successfully for over 5 minutes. Check the collector scheduler, pihole-query-metrics-locked.sh, and recent flock skip activity.",
      recommended_action:"Check collector timer/cron, wrapper state, and whether repeated flock skips indicate an unusually long or stuck collector run."
    },
    labels:{severity:"warning",category:"dns",component:"pihole-query-collector",service:"pihole"}
  }')"

code="$(curl -s -o /tmp/${UID}.json -w '%{http_code}' \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "${GRAFANA_URL}/api/v1/provisioning/alert-rules/${UID}")"

if [[ "$code" == "200" ]]; then
  method=PUT
  url="${GRAFANA_URL}/api/v1/provisioning/alert-rules/${UID}"
  echo "Updating: $TITLE"
else
  method=POST
  url="${GRAFANA_URL}/api/v1/provisioning/alert-rules"
  echo "Creating: $TITLE"
fi

curl -fsS -X "$method" \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$RULE_JSON" "$url" \
  | jq '{uid,title,for,noDataState,execErrState,labels}'

echo
echo "Pi-hole collector stale alert deployed."
echo "Expression: $EXPR"
echo "Policy: individual flock skips are diagnostic only; stale successful collection is alertable."
