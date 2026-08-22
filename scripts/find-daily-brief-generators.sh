#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-./report-generator-discovery-$(hostname -s)-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT_DIR"

log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

SEARCH_ROOTS=(
  /usr/local/bin
  /usr/local/sbin
  /etc/systemd
  /etc/cron.d
  /etc/cron.daily
  /etc/cron.hourly
  /etc/cron.weekly
  /home/james/scripts
  /home/james/projects
  /home/james/docker
)

PATTERN='Homelab Daily Security.*Recovery Brief|Homelab Engineering Security Runbook|Daily Operations Brief|Engineering Security Runbook|Security.*Recovery|Recovery.*Brief|Engineering.*Runbook'

log "Searching for report generator references"
sudo grep -RniE --binary-files=without-match "$PATTERN" "${SEARCH_ROOTS[@]}" 2>/dev/null \
  | tee "$OUT_DIR/exact-and-likely-title-matches.txt" || true

log "Capturing systemd timers and services"
systemctl list-timers --all --no-pager \
  | grep -Ei 'security|brief|runbook|report|daily|recovery' \
  | tee "$OUT_DIR/systemd-timers.txt" || true

systemctl list-unit-files --no-pager \
  | grep -Ei 'security|brief|runbook|report|daily|recovery' \
  | tee "$OUT_DIR/systemd-unit-files.txt" || true

log "Capturing cron references"
sudo grep -RniE 'security|brief|runbook|report|daily|recovery' \
  /etc/cron* /var/spool/cron 2>/dev/null \
  | tee "$OUT_DIR/cron-matches.txt" || true

crontab -l 2>/dev/null > "$OUT_DIR/user-crontab.txt" || true
sudo crontab -l 2>/dev/null > "$OUT_DIR/root-crontab.txt" || true

log "Capturing mail-related script references"
sudo grep -RniE --binary-files=without-match \
  'mailx|sendmail|msmtp|smtp|smtplib|gmail|subject=|Subject:|Homelab Operations|Homelab Security Engineering' \
  /usr/local/bin /usr/local/sbin /home/james/scripts /home/james/projects /home/james/docker \
  2>/dev/null | tee "$OUT_DIR/mail-sending-matches.txt" || true

log "Capturing likely evidence-source references"
sudo grep -RniE --binary-files=without-match \
  'prometheus|grafana|suricata|crowdsec|pihole|restic|greenbone|systemctl --failed|backup|restore|integrity' \
  /usr/local/bin /usr/local/sbin /home/james/scripts \
  2>/dev/null | tee "$OUT_DIR/evidence-source-matches.txt" || true

cat > "$OUT_DIR/README.txt" <<EOF
Host: $(hostname -f 2>/dev/null || hostname)
Generated: $(date --iso-8601=seconds)

Purpose: identify the generator and scheduler for:
- Homelab Daily Security & Recovery Brief
- Homelab Engineering Security Runbook

Review exact-and-likely-title-matches.txt first, then systemd/cron files, then mail-sending-matches.txt.
EOF

log "Discovery complete: $OUT_DIR"
