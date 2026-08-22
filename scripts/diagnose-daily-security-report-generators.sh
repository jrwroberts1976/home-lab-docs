#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-./daily-security-generator-diagnostics-$(hostname)-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT"

log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
run(){
  local name="$1"; shift
  log "$name"
  { "$@"; } >"$OUT/$name.txt" 2>&1 || true
}

log "Collecting daily security/recovery report generator diagnostics"
printf 'host=%s\ndate=%s\nuname=%s\n' "$(hostname)" "$(date -Is)" "$(uname -a)" > "$OUT/identity.txt"

# The two priority generators. Capture code, permissions and hashes, but never secrets.
for f in \
  /usr/local/lib/homelab-secops-report/generate_report.py \
  /usr/local/bin/homelab-security-reader.py \
  /usr/local/lib/homelab-secops-report/generate_management_report.py \
  /usr/local/sbin/homelab-secops-report \
  /usr/local/sbin/homelab-secops-management-report \
  /usr/local/sbin/homelab-greenbone-ai-review \
  /usr/local/sbin/homelab-greenbone-engineering-email; do
  if [[ -f "$f" ]]; then
    safe="$(echo "$f" | sed 's#^/##; s#[^A-Za-z0-9._-]#_#g')"
    stat "$f" > "$OUT/${safe}.stat.txt" 2>&1 || true
    sha256sum "$f" > "$OUT/${safe}.sha256.txt" 2>&1 || true
    cp -p "$f" "$OUT/$safe" 2>/dev/null || true
  else
    echo "MISSING: $f" > "$OUT/$(echo "$f" | sed 's#^/##; s#[^A-Za-z0-9._-]#_#g').missing.txt"
  fi
done

run systemd-timers systemctl list-timers --all --no-pager
run relevant-units systemctl list-unit-files --no-pager
run security-review-service systemctl cat security-review.service
run security-review-timer systemctl cat security-review.timer
run secops-management-service systemctl cat homelab-secops-management-report.service
run secops-management-timer systemctl cat homelab-secops-management-report.timer
run greenbone-ai-service systemctl cat homelab-greenbone-ai-review.service
run greenbone-ai-timer systemctl cat homelab-greenbone-ai-review.timer
run engineering-email-service systemctl cat homelab-greenbone-engineering-email.service
run engineering-email-timer systemctl cat homelab-greenbone-engineering-email.timer

# Capture the actual report products and metadata, without API keys or SMTP credentials.
for d in /var/lib/homelab-secops-report /var/lib/homelab-greenbone/reports; do
  [[ -d "$d" ]] || continue
  safe="$(basename "$d")"
  find "$d" -maxdepth 3 -type f -printf '%p\t%TY-%Tm-%Td %TH:%TM:%TS\t%s bytes\n' \
    > "$OUT/${safe}-files.txt" 2>&1 || true
  for f in "$d"/management/latest.md "$d"/latest.md; do
    [[ -f "$f" ]] || continue
    cp -p "$f" "$OUT/$(basename "$d")-$(basename "$f")" 2>/dev/null || true
  done
done

# Report the evidence sources used by the two generators. This helps identify
# where an apparently healthy report is being produced from stale/incomplete data.
run failed-units systemctl --failed --no-pager
run active-services systemctl --type=service --state=active --no-pager
run recent-secops-journal journalctl --since '24 hours ago' --no-pager -o short-iso \
  -u homelab-secops-management-report.service \
  -u homelab-secops-report.service \
  -u homelab-greenbone-ai-review.service \
  -u homelab-greenbone-engineering-email.service
run recent-security-review-journal journalctl --since '24 hours ago' --no-pager -o short-iso -u security-review.service

# Safe environment/config inventory: names and permissions only, never contents.
for d in /etc/homelab-openai /etc/homelab-greenbone; do
  if [[ -d "$d" ]]; then
    find "$d" -maxdepth 2 -type f -printf '%p\t%M\t%U:%G\t%s bytes\n' > "$OUT/$(basename "$d")-files.txt" 2>&1 || true
  fi
done

# Python syntax checks for the two primary targets.
for f in /usr/local/lib/homelab-secops-report/generate_report.py /usr/local/bin/homelab-security-reader.py; do
  [[ -f "$f" ]] || continue
  python3 -m py_compile "$f" > "$OUT/pycompile-$(basename "$f").txt" 2>&1 || true
done

cat > "$OUT/README.md" <<EOF
# Daily Security Report Generator Diagnostics

Host: `hostname`
Collected: `date -Is`

This bundle is diagnostic evidence for reviewing:

- `/usr/local/lib/homelab-secops-report/generate_report.py`
- `/usr/local/bin/homelab-security-reader.py`

It deliberately does **not** collect API keys, passwords, SMTP credentials or secret contents.

Review the copied generator source, service/timer definitions, report timestamps, recent service logs and Python compile results.
EOF

sha256sum "$OUT"/* > "$OUT/MANIFEST.sha256" 2>/dev/null || true

tar -czf "${OUT}.tar.gz" -C "$(dirname "$OUT")" "$(basename "$OUT")"

log "Diagnostics complete"
echo "Directory: $OUT"
echo "Archive:   ${OUT}.tar.gz"
