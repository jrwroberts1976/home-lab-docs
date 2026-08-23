#!/bin/bash
set -euo pipefail

set -a
. /home/homelab-backup/.restic-rest-env
set +a

export RESTIC_REPOSITORY="rest:https://192.168.2.242:8000/dietpi/"
export RESTIC_PASSWORD_FILE=/home/homelab-backup/.restic-password
export RESTIC_CACERT=/home/homelab-backup/certs/rest-server.crt
export HOME=/home/homelab-backup
export XDG_CACHE_HOME=/var/cache/restic-dietpi

LOG=/home/homelab-backup/logs/dietpi-backup.log
STAGING=/home/homelab-backup/staging
METRICS=/var/lib/prometheus/node-exporter/homelab_backup_dietpi.prom
TMP="${METRICS}.tmp"

START_EPOCH=$(date +%s)

write_metrics() {
    local success="$1"
    local snapshot="$2"
    local duration="$3"
    local now
    now=$(date +%s)

    cat > "$TMP" <<METRICS
# HELP homelab_backup_success Whether the last DietPi backup succeeded.
# TYPE homelab_backup_success gauge
homelab_backup_success{host="DietPi"} $success

# HELP homelab_backup_last_success_timestamp Last successful DietPi backup timestamp.
# TYPE homelab_backup_last_success_timestamp gauge
homelab_backup_last_success_timestamp{host="DietPi"} ${LAST_SUCCESS:-0}

# HELP homelab_backup_last_run_timestamp Timestamp when the last DietPi backup started.
# TYPE homelab_backup_last_run_timestamp gauge
homelab_backup_last_run_timestamp{host="DietPi"} $START_EPOCH

# HELP homelab_backup_duration_seconds Duration of the last DietPi backup.
# TYPE homelab_backup_duration_seconds gauge
homelab_backup_duration_seconds{host="DietPi"} $duration

# HELP homelab_backup_snapshot_info Information about the last DietPi Restic snapshot.
# TYPE homelab_backup_snapshot_info gauge
homelab_backup_snapshot_info{host="DietPi",snapshot="$snapshot"} 1

# HELP homelab_backup_metrics_timestamp_seconds Timestamp when DietPi backup metrics were generated.
# TYPE homelab_backup_metrics_timestamp_seconds gauge
homelab_backup_metrics_timestamp_seconds{host="DietPi"} $now
METRICS

    chown prometheus:prometheus "$TMP"
    chmod 644 "$TMP"
    mv "$TMP" "$METRICS"
}

{
    echo "===== $(date -Is) backup start ====="

    echo "Refreshing Pi-hole database snapshots..."

    rm -f \
      "$STAGING/gravity.db" \
      "$STAGING/pihole-FTL.db"

    sqlite3 /etc/pihole/gravity.db \
      ".backup $STAGING/gravity.db"

    sqlite3 /etc/pihole/pihole-FTL.db \
      ".backup $STAGING/pihole-FTL.db"

    chown homelab-backup:homelab-backup \
      "$STAGING/gravity.db" \
      "$STAGING/pihole-FTL.db"

    chmod 600 \
      "$STAGING/gravity.db" \
      "$STAGING/pihole-FTL.db"

    echo "Checking staged databases..."

    sqlite3 "$STAGING/gravity.db" \
      "PRAGMA integrity_check;"

    sqlite3 "$STAGING/pihole-FTL.db" \
      "PRAGMA integrity_check;"

    echo
    echo "Running Restic backup..."

    RESTIC_OUTPUT=$(
      restic backup \
        --files-from /home/homelab-backup/scripts/dietpi-files.txt \
        --exclude-file /home/homelab-backup/scripts/dietpi-excludes.txt \
        --tag dietpi \
        --tag pihole \
        --tag config \
        --host DietPi 2>&1
    )

    RESTIC_STATUS=$?

    echo "$RESTIC_OUTPUT"

    END_EPOCH=$(date +%s)
    DURATION=$((END_EPOCH - START_EPOCH))

    if [ "$RESTIC_STATUS" -eq 0 ]; then
        SNAPSHOT=$(echo "$RESTIC_OUTPUT" \
          | sed -n 's/^snapshot \([a-f0-9]\+\) saved$/\1/p' \
          | tail -1)

        LAST_SUCCESS=$END_EPOCH

        write_metrics 1 "$SNAPSHOT" "$DURATION"

        echo "===== $(date -Is) backup complete ====="
        echo "Snapshot: $SNAPSHOT"
        echo "Duration: ${DURATION}s"

        exit 0
    else
        LAST_SUCCESS=0

        write_metrics 0 "none" "$DURATION"

        echo "===== $(date -Is) BACKUP FAILED ====="
        exit "$RESTIC_STATUS"
    fi
} >> "$LOG" 2>&1
