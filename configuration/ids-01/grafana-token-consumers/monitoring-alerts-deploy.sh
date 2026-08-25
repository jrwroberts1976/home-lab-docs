#!/bin/bash

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


set -e

GRAFANA_URL="http://localhost:3001"


shopt -s nullglob
RULES=(rules/*.json)

if [ ${#RULES[@]} -eq 0 ]; then
    echo "ERROR: No rule files found"
    exit 1
fi

EXISTING=$(curl -s \
  -H "Authorization: Bearer $GRAFANA_TOKEN" \
  "$GRAFANA_URL/api/v1/provisioning/alert-rules")

for rule in "${RULES[@]}"; do

    TITLE=$(jq -r '.title' "$rule")

    RULE_UID=$(echo "$EXISTING" | jq -r \
      --arg TITLE "$TITLE" \
      '.[] | select(.title==$TITLE) | .uid' | head -n1)

    if [ "$RULE_UID" != "" ] && [ "$RULE_UID" != "null" ]; then

        echo "Updating: $TITLE ($RULE_UID)"

        curl -s -X PUT \
          -H "Authorization: Bearer $GRAFANA_TOKEN" \
          -H "Content-Type: application/json" \
          "$GRAFANA_URL/api/v1/provisioning/alert-rules/$RULE_UID" \
          -d @"$rule" >/dev/null

    else

        echo "Creating: $TITLE"

        curl -s -X POST \
          -H "Authorization: Bearer $GRAFANA_TOKEN" \
          -H "Content-Type: application/json" \
          "$GRAFANA_URL/api/v1/provisioning/alert-rules" \
          -d @"$rule" >/dev/null

    fi

done

echo "Alert deployment complete"
