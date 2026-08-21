#!/bin/bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3001}"
PROM_DS_UID="PBFA97CFB590B2093"
RULE_UID="blocked_mac_detected"

if [[ -z "${GRAFANA_TOKEN:-}" ]]; then
    echo "ERROR: GRAFANA_TOKEN is not set"
    exit 1
fi

RULE_JSON=$(cat <<JSON
{
  "uid": "${RULE_UID}",
  "orgID": 1,
  "folderUID": "homelab-alerts",
  "ruleGroup": "Security",
  "title": "Blocked MAC Detected",
  "condition": "C",
  "data": [
    {
      "refId": "A",
      "queryType": "",
      "relativeTimeRange": {
        "from": 300,
        "to": 0
      },
      "datasourceUid": "${PROM_DS_UID}",
      "model": {
        "datasource": {
          "type": "prometheus",
          "uid": "${PROM_DS_UID}"
        },
        "editorMode": "code",
        "expr": "((time() - homelab_watched_mac_last_seen_timestamp_seconds) > bool 0) * ((time() - homelab_watched_mac_last_seen_timestamp_seconds) < bool 300)",
        "instant": true,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "range": false,
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
      "datasourceUid": "-100",
      "model": {
        "conditions": [],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
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
      "datasourceUid": "-100",
      "model": {
        "conditions": [
          {
            "evaluator": {
              "params": [0.5],
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
          "uid": "-100"
        },
        "expression": "B",
        "refId": "C",
        "type": "threshold"
      }
    }
  ],
  "noDataState": "OK",
  "execErrState": "Alerting",
  "for": "0s",
  "annotations": {
    "summary": "Blocked MAC detected on the network",
    "description": "A watched or blocked MAC address has appeared in the ASUS router log.\\n\\nMAC: {{ \\$labels.mac }}\\nName: {{ \\$labels.name }}\\nIP: {{ \\$labels.ip }}\\nRouter: {{ \\$labels.router }}\\nEvent: {{ \\$labels.event }}"
  },
  "labels": {
    "severity": "critical",
    "category": "security",
    "component": "network"
  }
}
JSON
)

HTTP_CODE=$(curl -s \
    -o /tmp/blocked-mac-rule-check.json \
    -w "%{http_code}" \
    -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    "${GRAFANA_URL}/api/v1/provisioning/alert-rules/${RULE_UID}")

if [[ "${HTTP_CODE}" == "200" ]]; then
    echo "Updating existing alert rule..."
    METHOD="PUT"
    URL="${GRAFANA_URL}/api/v1/provisioning/alert-rules/${RULE_UID}"
else
    echo "Creating alert rule..."
    METHOD="POST"
    URL="${GRAFANA_URL}/api/v1/provisioning/alert-rules"
fi

curl -sS \
    -X "${METHOD}" \
    -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${RULE_JSON}" \
    "${URL}" | jq

echo
echo "Blocked MAC alert deployed."
