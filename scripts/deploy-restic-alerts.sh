#!/bin/bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3001}"
PROM_DS_UID="PBFA97CFB590B2093"

if [[ -z "${GRAFANA_TOKEN:-}" ]]; then
  echo "ERROR: GRAFANA_TOKEN is not set"
  exit 1
fi

for cmd in curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: missing $cmd"; exit 1; }
done

deploy_rule() {
  local uid="$1" title="$2" expr="$3" for_time="$4" no_data="$5" summary="$6" description="$7"

  local rule_json
  rule_json=$(jq -n \
    --arg uid "$uid" \
    --arg title "$title" \
    --arg expr "$expr" \
    --arg for_time "$for_time" \
    --arg no_data "$no_data" \
    --arg summary "$summary" \
    --arg description "$description" \
    --arg ds "$PROM_DS_UID" '
    {
      uid:$uid,
      orgID:1,
      folderUID:"homelab-alerts",
      ruleGroup:"Backup",
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
      noDataState:$no_data,
      execErrState:"Alerting",
      for:$for_time,
      annotations:{summary:$summary,description:$description},
      labels:{severity:"critical",category:"backup",component:"restic",service:"restic-server"}
    }')

  local code method url
  code=$(curl -s -o /tmp/${uid}.json -w '%{http_code}' -H "Authorization: Bearer ${GRAFANA_TOKEN}" "${GRAFANA_URL}/api/v1/provisioning/alert-rules/${uid}")
  if [[ "$code" == "200" ]]; then
    method=PUT
    url="${GRAFANA_URL}/api/v1/provisioning/alert-rules/${uid}"
    echo "Updating: $title"
  else
    method=POST
    url="${GRAFANA_URL}/api/v1/provisioning/alert-rules"
    echo "Creating: $title"
  fi

  curl -fsS -X "$method" \
    -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$rule_json" "$url" | jq '{uid,title,for,noDataState,labels}'
}

deploy_rule \
  "restic_server_down" \
  "Restic Server Down" \
  'homelab_restic_server_up < bool 1' \
  "2m" \
  "OK" \
  "Restic backup server is unavailable" \
  'The Restic REST server on ids-01 is unhealthy. One or more checks failed: container running, Docker port publication, TCP/8000 listener, or HTTPS response. This can cause scheduled host backups to fail.'

deploy_rule \
  "restic_health_check_stale" \
  "Restic Health Check Stale" \
  '(time() - homelab_restic_server_health_timestamp_seconds) > bool 300' \
  "2m" \
  "Alerting" \
  "Restic health monitoring has stopped updating" \
  'The Restic server health metric has not updated for more than 5 minutes, or the metric is missing. Check restic-server-health.timer/service and the node-exporter textfile collector on ids-01.'

echo
echo "Restic alert rules deployed."
