#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="/var/lib/homelab-greenbone/reports"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: run this script with sudo." >&2
    exit 1
fi

show_file() {
    local title="$1"
    local path="$2"
    echo
    echo "===== ${title} ====="
    if [[ -r "$path" ]]; then
        sed -n '1,360p' "$path"
    else
        echo "NOT FOUND OR NOT READABLE: $path"
    fi
}

echo "===== ENGINEERING RUNBOOK TIMERS ====="
systemctl list-timers --all --no-pager | grep -Ei 'greenbone|engineering|security|report|runbook' || true

show_file "GREENBONE AI SERVICE" "/etc/systemd/system/homelab-greenbone-ai-review.service"
show_file "GREENBONE AI TIMER" "/etc/systemd/system/homelab-greenbone-ai-review.timer"
show_file "ENGINEERING EMAIL SERVICE" "/etc/systemd/system/homelab-greenbone-engineering-email.service"
show_file "ENGINEERING EMAIL TIMER" "/etc/systemd/system/homelab-greenbone-engineering-email.timer"
show_file "GREENBONE AI RUNNER" "/usr/local/sbin/homelab-greenbone-ai-review"
show_file "ENGINEERING EMAIL GENERATOR" "/usr/local/sbin/homelab-greenbone-engineering-email"
show_file "GREENBONE AI REVIEW PYTHON" "/usr/local/lib/homelab-greenbone/ai_review.py"

echo
echo "===== LATEST ENGINEERING REPORT ====="
if [[ -L "${REPORT_DIR}/latest.md" || -f "${REPORT_DIR}/latest.md" ]]; then
    ls -l "${REPORT_DIR}/latest.md"
    readlink -f "${REPORT_DIR}/latest.md" || true
    echo
    sed -n '1,360p' "$(readlink -f "${REPORT_DIR}/latest.md")"
else
    echo "No latest Greenbone engineering report found."
fi

echo
echo "===== RECENT GREENBONE AI JOURNAL ====="
journalctl -u homelab-greenbone-ai-review.service -n 80 --no-pager || true

echo
echo "===== RECENT ENGINEERING EMAIL JOURNAL ====="
journalctl -u homelab-greenbone-engineering-email.service -n 80 --no-pager || true
