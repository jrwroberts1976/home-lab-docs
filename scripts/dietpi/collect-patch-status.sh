#!/usr/bin/env bash

set -euo pipefail

OUT_DIR="/var/lib/prometheus/node-exporter"
OUT_FILE="${OUT_DIR}/patch_status.prom"
TMP_FILE="${OUT_FILE}.tmp"

mkdir -p "$OUT_DIR"

# Refresh package metadata quietly.
sudo apt-get update -qq

# Count all available package updates.
UPDATES_AVAILABLE=$(
  apt list --upgradable 2>/dev/null |
  tail -n +2 |
  wc -l
)

# Count security-related updates.
SECURITY_UPDATES=$(
  apt list --upgradable 2>/dev/null |
  grep -ciE 'security|Debian-Security' || true
)

# Check whether a reboot is required.
if [ -f /var/run/reboot-required ]; then
  REBOOT_REQUIRED=1
else
  REBOOT_REQUIRED=0
fi

# Inspect DietPi's native automatic APT-upgrade mode.
APT_UPDATE_MODE=$(
  sed -n '
    /^[[:blank:]]*CONFIG_CHECK_APT_UPDATES=/ {
      s/^[^=]*=//
      p
      q
    }
  ' /boot/dietpi.txt
)

if [ "${APT_UPDATE_MODE:-0}" = "2" ]; then
  UNATTENDED_ENABLED=1
else
  UNATTENDED_ENABLED=0
fi

# DietPi applies upgrades from its daily cron script.
if [ "$UNATTENDED_ENABLED" -eq 1 ] &&
   [ -x /etc/cron.daily/dietpi ] &&
   systemctl is-active cron >/dev/null 2>&1
then
  UNATTENDED_ACTIVE=1
else
  UNATTENDED_ACTIVE=0
fi

# Preserve the most recent successful automated patch-state check.
SUCCESS_STATE="${OUT_DIR}/.patch-last-success"

if [ "$UNATTENDED_ACTIVE" -eq 1 ] &&
   [ "$UPDATES_AVAILABLE" -eq 0 ]
then
  date +%s > "$SUCCESS_STATE"
fi

if [ -s "$SUCCESS_STATE" ]; then
  LAST_SUCCESS=$(cat "$SUCCESS_STATE")
else
  LAST_SUCCESS=0
fi

#
# Timestamp for a successful DietPi patch-status collector run.
#
DIETPI_PATCH_FILE_TIMESTAMP=$(date +%s)

#
# Write Prometheus metrics atomically.
#
{
  echo '# HELP homelab_updates_available Number of available APT package updates.'
  echo '# TYPE homelab_updates_available gauge'
  echo "homelab_updates_available ${UPDATES_AVAILABLE}"

  echo '# HELP homelab_security_updates_available Number of available security updates.'
  echo '# TYPE homelab_security_updates_available gauge'
  echo "homelab_security_updates_available ${SECURITY_UPDATES}"

  echo '# HELP homelab_reboot_required Whether the host requires a reboot.'
  echo '# TYPE homelab_reboot_required gauge'
  echo "homelab_reboot_required ${REBOOT_REQUIRED}"

  echo '# HELP homelab_unattended_upgrades_enabled Whether automatic APT upgrades are enabled for this host.'
  echo '# TYPE homelab_unattended_upgrades_enabled gauge'
  echo "homelab_unattended_upgrades_enabled ${UNATTENDED_ENABLED}"

  echo '# HELP homelab_unattended_upgrades_active Whether the automatic APT upgrade mechanism is operational.'
  echo '# TYPE homelab_unattended_upgrades_active gauge'
  echo "homelab_unattended_upgrades_active ${UNATTENDED_ACTIVE}"

  echo '# HELP homelab_patch_last_success_timestamp_seconds Last successful automated patch-state verification timestamp.'
  echo '# TYPE homelab_patch_last_success_timestamp_seconds gauge'
  echo "homelab_patch_last_success_timestamp_seconds ${LAST_SUCCESS}"

  echo '# HELP homelab_patch_check_timestamp_seconds Last patch status collection time.'
  echo '# TYPE homelab_patch_check_timestamp_seconds gauge'
  echo "homelab_patch_check_timestamp_seconds ${DIETPI_PATCH_FILE_TIMESTAMP}"

  echo '# HELP homelab_dietpi_patch_file_timestamp_seconds Last successful DietPi patch collector timestamp.'
  echo '# TYPE homelab_dietpi_patch_file_timestamp_seconds gauge'
  echo "homelab_dietpi_patch_file_timestamp_seconds ${DIETPI_PATCH_FILE_TIMESTAMP}"

} > "$TMP_FILE"

mv "$TMP_FILE" "$OUT_FILE"
