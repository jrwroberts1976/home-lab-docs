#!/usr/bin/env bash
set -u

# Read-only Pi-hole Grafana notifier/routing inspection.
# Shows provisioned notification policy, Pi-hole rule labels, and notifier logs.
# Usage: ./scripts/pihole-notifier-inspect.sh [YYYY-MM-DDTHH:MM:SS]

START="${1:-2026-08-22T05:57:00}"
GRAFANA_CONTAINER="${GRAFANA_CONTAINER:-grafana}"
BASE="${GRAFANA_PROVISIONING:-/home/james/docker/data/monitoring/grafana/provisioning/alerting}"
POLICY="$BASE/pihole-notification-policy.yml"
RULES="$BASE/pihole-policy-alerts.yml"

printf '# Pi-hole notifier inspection\n'
printf 'captured_at=%s\n' "$(date '+%F %T %Z')"
printf 'start=%s\n' "$START"
printf 'grafana_container=%s\n' "$GRAFANA_CONTAINER"
printf 'provisioning=%s\n\n' "$BASE"

printf '## Pi-hole notification policy\n'
if [[ -r "$POLICY" ]]; then
  nl -ba "$POLICY" | sed -n '1,120p'
else
  printf 'NOT READABLE: %s\n' "$POLICY"
fi
printf '\n'

printf '## Pi-hole alert rule\n'
if [[ -r "$RULES" ]]; then
  nl -ba "$RULES" | sed -n '1,180p'
else
  printf 'NOT READABLE: %s\n' "$RULES"
fi
printf '\n'

printf '## Relevant routing/timing lines\n'
if [[ -r "$POLICY" ]]; then
  grep -nE 'receiver:|group_by:|group_wait:|group_interval:|repeat_interval:|service|alert_type|category|host' "$POLICY" || true
fi
printf '\n'

printf '## Pi-hole rule labels and annotations\n'
if [[ -r "$RULES" ]]; then
  grep -nE 'uid:|title:|labels:|annotations:|service:|alert_type:|category|host|client|domain' "$RULES" || true
fi
printf '\n'

printf '## Grafana Pi-hole notifier/state logs since %s\n' "$START"
docker logs --since "$START" "$GRAFANA_CONTAINER" 2>&1 \
  | grep -Ei 'pihole-policy-category-detected|ngalert.*(sender|state|notify)|notifier|notification|smtp|email|contact' \
  | tail -n 500 || true
printf '\n'

printf '## Errors/failures since %s\n' "$START"
docker logs --since "$START" "$GRAFANA_CONTAINER" 2>&1 \
  | grep -Ei '(pihole|ngalert|notifier|notification|smtp|email).*(error|fail|timeout)|level=error.*(alert|notify|smtp|email)' \
  | tail -n 200 || true
printf '\n'

printf 'Interpretation:\n'
printf '%s\n' '- Confirm the Pi-hole route matches service=pihole and alert_type=policy-category.'
printf '%s\n' '- Confirm group_wait/group_interval/repeat_interval are the intended values.'
printf '%s\n' '- Compare rule labels with group_by: labels determine whether several alert instances share one notification group.'
printf '%s\n' '- A sender.router line proves Grafana handed alert instances to its local notifier, but does not by itself prove SMTP delivery.'
printf '%s\n' '- SMTP/notifier errors in the final section identify delivery failures; no errors plus no email points us toward grouping/state suppression.'
printf '%s\n' '- This script is read-only and does not restart or modify Grafana.'
