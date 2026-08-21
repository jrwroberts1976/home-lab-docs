#!/bin/bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3001}"
TEMPLATE_GROUP="homelab-email"

if [[ -z "${GRAFANA_TOKEN:-}" ]]; then
  echo "ERROR: GRAFANA_TOKEN is not set"
  exit 1
fi

for cmd in curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd"
    exit 1
  fi
done

read -r -d '' TEMPLATE <<'EOF' || true
{{ define "homelab.email.subject" -}}
{{ if gt (len .Alerts.Firing) 0 }}⚠️ [FIRING]{{ else }}✅ [RESOLVED]{{ end }} {{ .CommonLabels.alertname }}{{ with .CommonLabels.host }} — {{ . }}{{ else }}{{ with .CommonLabels.instance }} — {{ . }}{{ end }}{{ end }}
{{- end }}

{{ define "homelab.email.message" -}}
{{ range .Alerts.Firing }}
⚠️ ALERT FIRING

{{ .Labels.alertname }}

{{ with .Labels.severity }}Severity: {{ . }}
{{ end }}{{ with .Labels.category }}Category: {{ . }}
{{ end }}{{ with .Labels.host }}Host: {{ . }}
{{ end }}{{ with .Labels.instance }}Instance: {{ . }}
{{ end }}{{ with .Labels.component }}Component: {{ . }}
{{ end }}
{{ with .Annotations.summary }}Summary
{{ . }}
{{ end }}
{{ with .Annotations.description }}
Description
{{ . }}
{{ end }}
{{ end }}
{{ range .Alerts.Resolved }}
✅ ALERT RESOLVED

{{ .Labels.alertname }}

{{ with .Labels.severity }}Severity: {{ . }}
{{ end }}{{ with .Labels.category }}Category: {{ . }}
{{ end }}{{ with .Labels.host }}Host: {{ . }}
{{ end }}{{ with .Labels.instance }}Instance: {{ . }}
{{ end }}{{ with .Labels.component }}Component: {{ . }}
{{ end }}
{{ with .Annotations.summary }}Summary
{{ . }}
{{ end }}
{{ with .Annotations.description }}
Description
{{ . }}
{{ end }}
{{ end }}
{{- end }}
EOF

TEMPLATE_JSON=$(jq -n --arg template "$TEMPLATE" '{template:$template}')

echo "Creating/updating Grafana notification template group: ${TEMPLATE_GROUP}"
curl -fsS \
  -X PUT \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "X-Disable-Provenance: true" \
  -d "$TEMPLATE_JSON" \
  "${GRAFANA_URL}/api/v1/provisioning/templates/${TEMPLATE_GROUP}" \
  | jq

echo
echo "Finding Grafana email contact points..."
CONTACT_POINTS=$(curl -fsS \
  -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
  "${GRAFANA_URL}/api/v1/provisioning/contact-points")

EMAIL_COUNT=$(jq '[.[] | select(.type == "email")] | length' <<<"$CONTACT_POINTS")

if [[ "$EMAIL_COUNT" -eq 0 ]]; then
  echo "No email contact points found. Template group deployed, but no contact point was changed."
  exit 0
fi

while IFS= read -r CP; do
  UID=$(jq -r '.uid' <<<"$CP")
  NAME=$(jq -r '.name' <<<"$CP")

  UPDATE_JSON=$(jq \
    --arg subject '{{ template "homelab.email.subject" . }}' \
    --arg message '{{ template "homelab.email.message" . }}' \
    '{uid,name,type,settings,disableResolveMessage}
     | .settings.subject = $subject
     | .settings.message = $message' <<<"$CP")

  echo "Updating email contact point: ${NAME} (${UID})"
  curl -fsS \
    -X PUT \
    -H "Authorization: Bearer ${GRAFANA_TOKEN}" \
    -H "Content-Type: application/json" \
    -H "X-Disable-Provenance: true" \
    -d "$UPDATE_JSON" \
    "${GRAFANA_URL}/api/v1/provisioning/contact-points/${UID}" \
    | jq
  echo
done < <(jq -c '.[] | select(.type == "email")' <<<"$CONTACT_POINTS")

echo "Grafana homelab email standard deployed to ${EMAIL_COUNT} email contact point(s)."
echo "Subject template: homelab.email.subject"
echo "Message template: homelab.email.message"
