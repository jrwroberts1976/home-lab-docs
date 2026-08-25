GRAFANA_TOKEN_FILE="${GRAFANA_TOKEN_FILE:-/home/james/docker/secrets/grafana-api-token}"

if [[ -z "${GRAFANA_TOKEN:-}" ]]; then
    if [[ ! -r "$GRAFANA_TOKEN_FILE" ]]; then
        echo "ERROR: Grafana token file is not readable: $GRAFANA_TOKEN_FILE" >&2
        return 1 2>/dev/null || exit 1
    fi

    IFS= read -r GRAFANA_TOKEN <"$GRAFANA_TOKEN_FILE"
fi

if [[ -z "$GRAFANA_TOKEN" ]]; then
    echo "ERROR: Grafana token is empty" >&2
    return 1 2>/dev/null || exit 1
fi

GRAFANA_URL="http://192.168.2.242:3001"

echo "=== VERIFY AUTHENTICATION ==="
curl -fsS \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "${GRAFANA_URL}/api/user" |
jq '{login, orgName}'

echo
echo "=== FIND LOKI UID ==="
LOKI_UID="$(
  curl -fsS \
    -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    "${GRAFANA_URL}/api/datasources/name/Loki" |
  jq -r '.uid'
)"

if [ -z "${LOKI_UID}" ] || [ "${LOKI_UID}" = "null" ]; then
  echo "Could not find the Loki datasource UID."
  exit 1
fi

echo "Loki UID found: ${LOKI_UID}"

echo
echo "=== ENSURE ALERT FOLDER EXISTS ==="
if ! curl -fsS \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "${GRAFANA_URL}/api/folders/uid/homelab-alerts" \
  >/dev/null 2>&1; then

  curl -fsS \
    -X POST \
    -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    -H "Content-Type: application/json" \
    "${GRAFANA_URL}/api/folders" \
    --data-binary @- <<'EOF' |
{
  "uid": "homelab-alerts",
  "title": "Homelab Alerts"
}
EOF
  jq .
else
  echo "Homelab Alerts folder already exists."
fi

echo
echo "=== CHECK FOR EXISTING RULE ==="
if curl -fsS \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "${GRAFANA_URL}/api/v1/provisioning/alert-rules" |
jq -e '.[] | select(.title == "Hardware fault detected")' \
  >/dev/null; then
  echo "Hardware fault alert already exists; nothing changed."
  exit 0
fi

echo
echo "=== BUILD ALERT RULE ==="
ALERT_FILE="$(mktemp /tmp/hardware-alert.XXXXXX.json)"

cat >"${ALERT_FILE}" <<'EOF'
{
  "orgID": 1,
  "folderUID": "homelab-alerts",
  "ruleGroup": "Hardware Health",
  "title": "Hardware fault detected",
  "condition": "C",
  "data": [
    {
      "refId": "A",
      "queryType": "",
      "relativeTimeRange": {
        "from": 300,
        "to": 0
      },
      "datasourceUid": "__LOKI_UID__",
      "model": {
        "datasource": {
          "type": "loki",
          "uid": "__LOKI_UID__"
        },
        "editorMode": "code",
        "expr": "sum by (host) (count_over_time({job=\"systemd-journal\"} |~ \"(?i)(buffer I/O error|blk_update_request|critical medium error|uncorrectable|bad sector|SMART.*fail|pending sector|reallocated sector|nvme.*(critical|reset|timeout|abort)|EXT4-fs error|XFS.*error|BTRFS.*error|remounting filesystem read-only|machine check|mce:|hardware error|EDAC|memory failure|PCIe Bus Error|thermal.*critical|watchdog.*lockup|kernel panic)\" [5m]))",
        "instant": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "queryType": "range",
        "refId": "A"
      }
    },
    {
      "refId": "B",
      "queryType": "",
      "relativeTimeRange": {
        "from": 0,
        "to": 0
      },
      "datasourceUid": "__expr__",
      "model": {
        "conditions": [],
        "datasource": {
          "type": "__expr__",
          "uid": "__expr__"
        },
        "expression": "A",
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }
    },
    {
      "refId": "C",
      "queryType": "",
      "relativeTimeRange": {
        "from": 0,
        "to": 0
      },
      "datasourceUid": "__expr__",
      "model": {
        "conditions": [
          {
            "evaluator": {
              "params": [0],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": ["C"]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "__expr__"
        },
        "expression": "B",
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "refId": "C",
        "type": "threshold"
      }
    }
  ],
  "noDataState": "OK",
  "execErrState": "Error",
  "for": "1m",
  "annotations": {
    "summary": "Hardware fault detected on {{ $labels.host }}",
    "description": "Loki detected {{ $values.B.Value }} hardware-related kernel or SMART events on {{ $labels.host }} during the last five minutes. Review the Homelab Hardware Health dashboard and the host journal."
  },
  "labels": {
    "severity": "critical",
    "category": "hardware",
    "service": "infrastructure"
  },
  "isPaused": false
}
EOF

jq --arg uid "${LOKI_UID}" \
  '(.data[0].datasourceUid) = $uid |
   (.data[0].model.datasource.uid) = $uid' \
  "${ALERT_FILE}" >"${ALERT_FILE}.resolved"

echo
echo "=== CREATE ALERT ==="
curl -fsS \
  -X POST \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  -H "Content-Type: application/json" \
  "${GRAFANA_URL}/api/v1/provisioning/alert-rules" \
  --data-binary @"${ALERT_FILE}.resolved" |
jq '{uid, title, folderUID, ruleGroup, noDataState, execErrState, for}'

echo
echo "=== CLEAN UP ==="
rm -f "${ALERT_FILE}" "${ALERT_FILE}.resolved"
unset GRAFANA_TOKEN LOKI_UID

echo "Hardware alert installation complete."
