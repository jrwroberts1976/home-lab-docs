#!/usr/bin/env bash

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

set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3001}"

RULE_UID="pihole-config-sync-unhealthy"
RULE_TITLE="Pi-hole Configuration Sync Unhealthy"
RULE_GROUP="DNS"
FOLDER_TITLE="Homelab Alerts"

command -v curl >/dev/null || {
    echo "ERROR: curl is required"
    exit 1
}

command -v jq >/dev/null || {
    echo "ERROR: jq is required"
    exit 1
}

# ------------------------------------------------------------
# Authentication
#
# Supported:
#   GRAFANA_TOKEN
# or
#   GRAFANA_USER + GRAFANA_PASSWORD
#
# If neither is supplied, try local Grafana without auth.
# ------------------------------------------------------------

AUTH=()

if [[ -n "${GRAFANA_TOKEN:-}" ]]; then
    AUTH=(-H "Authorization: Bearer ${GRAFANA_TOKEN}")
elif [[ -n "${GRAFANA_USER:-}" && -n "${GRAFANA_PASSWORD:-}" ]]; then
    AUTH=(-u "${GRAFANA_USER}:${GRAFANA_PASSWORD}")
fi

echo "Grafana: ${GRAFANA_URL}"
echo

# ------------------------------------------------------------
# Find Homelab Alerts folder
# ------------------------------------------------------------

echo "Finding Grafana folder: ${FOLDER_TITLE}"

FOLDERS="$(
    curl -fsS \
        "${AUTH[@]}" \
        "${GRAFANA_URL}/api/folders?limit=1000"
)"

FOLDER_UID="$(
    printf '%s' "$FOLDERS" |
    jq -r --arg TITLE "$FOLDER_TITLE" \
        '.[] | select(.title == $TITLE) | .uid' |
    head -1
)"

if [[ -z "$FOLDER_UID" ]]; then
    echo "ERROR: Grafana folder '${FOLDER_TITLE}' not found"
    exit 1
fi

echo "Folder UID: ${FOLDER_UID}"

# ------------------------------------------------------------
# Find Prometheus datasource
# Prefer one literally called Prometheus.
# ------------------------------------------------------------

echo "Finding Prometheus datasource..."

DATASOURCES="$(
    curl -fsS \
        "${AUTH[@]}" \
        "${GRAFANA_URL}/api/datasources"
)"

PROM_UID="$(
    printf '%s' "$DATASOURCES" |
    jq -r '
        (
            [.[] | select(.type == "prometheus" and .name == "Prometheus")][0]
            //
            [.[] | select(.type == "prometheus")][0]
        ).uid // empty
    '
)"

if [[ -z "$PROM_UID" ]]; then
    echo "ERROR: No Prometheus datasource found"
    exit 1
fi

PROM_NAME="$(
    printf '%s' "$DATASOURCES" |
    jq -r --arg UID "$PROM_UID" \
        '.[] | select(.uid == $UID) | .name'
)"

echo "Prometheus: ${PROM_NAME}"
echo "Datasource UID: ${PROM_UID}"
echo

# ------------------------------------------------------------
# Alert expression
#
# Fires when ANY of these is true:
#
# 1. Nebula Sync has been unhealthy for the whole last 5m
# 2. Latest sync result is failed
# 3. Last successful sync is older than 45 minutes
# ------------------------------------------------------------

PROMQL='
(
  max_over_time(
    homelab_pihole_sync_up{host="ids-01"}[5m]
  ) == bool 0
)
+
(
  last_over_time(
    homelab_pihole_sync_last_result_success{host="ids-01"}[5m]
  ) == bool 0
)
+
(
  homelab_pihole_sync_age_seconds{host="ids-01"} > bool 2700
)
> bool 0
'

# ------------------------------------------------------------
# Build Grafana rule JSON
# ------------------------------------------------------------

RULE_JSON="$(
jq -n \
    --arg uid "$RULE_UID" \
    --arg title "$RULE_TITLE" \
    --arg group "$RULE_GROUP" \
    --arg folder "$FOLDER_UID" \
    --arg ds "$PROM_UID" \
    --arg expr "$PROMQL" \
'
{
  uid: $uid,
  title: $title,
  ruleGroup: $group,
  folderUID: $folder,

  noDataState: "Alerting",
  execErrState: "Alerting",

  for: "0s",
  orgId: 1,
  condition: "B",

  annotations: {
    summary:
      "Pi-hole configuration synchronisation is unhealthy",

    description:
      "Configuration synchronisation from the DietPi primary Pi-hole to the ids-01 secondary is unhealthy, has failed, or has not completed successfully within 45 minutes.",

    affected_service:
      "DietPi -> ids-01 / pihole-secondary",

    recommended_action:
      "Check the nebula-sync container and review its recent logs.",

    technical_check:
      "docker logs --tail 100 nebula-sync"
  },

  labels: {
    severity: "warning",
    service: "pihole",
    component: "nebula-sync",
    host: "ids-01"
  },

  data: [
    {
      refId: "A",
      queryType: "",
      relativeTimeRange: {
        from: 600,
        to: 0
      },
      datasourceUid: $ds,

      model: {
        expr: $expr,
        hide: false,
        intervalMs: 1000,
        maxDataPoints: 43200,
        refId: "A"
      }
    },

    {
      refId: "B",
      queryType: "",
      relativeTimeRange: {
        from: 0,
        to: 0
      },
      datasourceUid: "-100",

      model: {
        conditions: [
          {
            evaluator: {
              params: [0],
              type: "gt"
            },
            operator: {
              type: "and"
            },
            query: {
              params: ["A"]
            },
            reducer: {
              params: [],
              type: "last"
            },
            type: "query"
          }
        ],

        datasource: {
          type: "__expr__",
          uid: "-100"
        },

        hide: false,
        intervalMs: 1000,
        maxDataPoints: 43200,
        refId: "B",
        type: "classic_conditions"
      }
    }
  ],

  isPaused: false
}
'
)"

# Keep a copy of exactly what was deployed.
RULE_FILE="/home/james/docker/stacks/nebula-sync/pihole-config-sync-alert.json"

printf '%s\n' "$RULE_JSON" > "$RULE_FILE"

# ------------------------------------------------------------
# Create or update
# ------------------------------------------------------------

CHECK_CODE="$(
    curl -sS \
        "${AUTH[@]}" \
        -o /dev/null \
        -w '%{http_code}' \
        "${GRAFANA_URL}/api/v1/provisioning/alert-rules/${RULE_UID}"
)"

if [[ "$CHECK_CODE" == "200" ]]; then

    echo "Existing rule found - updating..."

    RESPONSE="$(
        curl -fsS \
            "${AUTH[@]}" \
            -X PUT \
            -H 'Content-Type: application/json' \
            -H 'X-Disable-Provenance: true' \
            --data "$RULE_JSON" \
            "${GRAFANA_URL}/api/v1/provisioning/alert-rules/${RULE_UID}"
    )"

else

    echo "Rule does not exist - creating..."

    RESPONSE="$(
        curl -fsS \
            "${AUTH[@]}" \
            -X POST \
            -H 'Content-Type: application/json' \
            -H 'X-Disable-Provenance: true' \
            --data "$RULE_JSON" \
            "${GRAFANA_URL}/api/v1/provisioning/alert-rules"
    )"

fi

echo
echo "Rule deployed."
echo

# ------------------------------------------------------------
# Read it back from Grafana
# ------------------------------------------------------------

curl -fsS \
    "${AUTH[@]}" \
    "${GRAFANA_URL}/api/v1/provisioning/alert-rules/${RULE_UID}" |
jq '{
    uid,
    title,
    ruleGroup,
    folderUID,
    noDataState,
    execErrState,
    for,
    labels,
    isPaused
}'

echo
echo "Saved deployment JSON:"
echo "$RULE_FILE"
echo
echo "Pi-hole configuration sync alert deployment complete."
