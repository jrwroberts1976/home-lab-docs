#!/usr/bin/env bash
set -euo pipefail

SERVICE="homelab-secops-management-report.service"
REPORT_DIR="/var/lib/homelab-secops-report/management"

if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: run this script with sudo." >&2
    exit 1
fi

echo "===== CURRENT MANAGEMENT REPORT ====="
if [[ -L "${REPORT_DIR}/latest.md" || -f "${REPORT_DIR}/latest.md" ]]; then
    ls -l "${REPORT_DIR}/latest.md"
else
    echo "No existing management report found."
fi

echo
echo "===== RUNNING MANAGEMENT REPORT SERVICE ====="
systemctl start "${SERVICE}"

echo

echo "===== SERVICE STATUS ====="
systemctl status "${SERVICE}" --no-pager --full || true

echo
echo "===== RECENT SERVICE JOURNAL ====="
journalctl -u "${SERVICE}" -n 60 --no-pager

echo
echo "===== LATEST MANAGEMENT REPORT ====="
if [[ -f "${REPORT_DIR}/latest.md" || -L "${REPORT_DIR}/latest.md" ]]; then
    ls -l "${REPORT_DIR}/latest.md"
    readlink -f "${REPORT_DIR}/latest.md" || true
else
    echo "ERROR: management report was not created." >&2
    exit 1
fi

echo
echo "Management report regeneration/email job completed."
