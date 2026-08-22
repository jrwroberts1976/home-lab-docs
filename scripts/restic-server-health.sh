#!/usr/bin/env bash
set -euo pipefail

CONTAINER="${RESTIC_CONTAINER:-restic-server}"
HOST_IP="${RESTIC_HOST_IP:-192.168.2.242}"
PORT="${RESTIC_PORT:-8000}"
URL="${RESTIC_URL:-https://${HOST_IP}:${PORT}/}"
CACERT="${RESTIC_CACERT:-/home/homelab-backup/rest-server/tls/rest-server.crt}"

OUTDIR="${NODE_EXPORTER_TEXTFILE_DIR:-/home/james/docker/data/monitoring/node-exporter/textfile}"
if [[ ! -d "$OUTDIR" ]]; then
  for d in /var/lib/node_exporter/textfile_collector /var/lib/node_exporter/textfile /var/lib/prometheus/node-exporter; do
    if [[ -d "$d" ]]; then OUTDIR="$d"; break; fi
  done
fi
mkdir -p "$OUTDIR"
OUTFILE="$OUTDIR/homelab_restic_server_health.prom"
TMP="${OUTFILE}.tmp"

container_up=0
port_published=0
port_listening=0
https_reachable=0

if docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -qx true; then
  container_up=1
fi

if docker inspect "$CONTAINER" --format '{{json .NetworkSettings.Ports}}' 2>/dev/null | grep -q '8000/tcp'; then
  port_published=1
fi

if ss -ltn 2>/dev/null | awk '{print $4}' | grep -Eq "(^|:)${PORT}$"; then
  port_listening=1
fi

curl_args=(-sS -o /dev/null --connect-timeout 3 --max-time 5 -w '%{http_code}' "$URL")
if [[ -r "$CACERT" ]]; then
  curl_args=(--cacert "$CACERT" "${curl_args[@]}")
else
  curl_args=(-k "${curl_args[@]}")
fi
http_code="$(curl "${curl_args[@]}" 2>/dev/null || true)"
# 401 is healthy here because unauthenticated access is expected to be rejected.
if [[ "$http_code" =~ ^(200|401|403)$ ]]; then
  https_reachable=1
fi

up=0
if [[ "$container_up" -eq 1 && "$port_published" -eq 1 && "$port_listening" -eq 1 && "$https_reachable" -eq 1 ]]; then
  up=1
fi

cat > "$TMP" <<EOF
# HELP homelab_restic_server_up Overall Restic REST server health (1 healthy, 0 unhealthy).
# TYPE homelab_restic_server_up gauge
homelab_restic_server_up{host="ids-01",service="restic-server"} $up
# HELP homelab_restic_server_container_up Whether the Restic Docker container is running.
# TYPE homelab_restic_server_container_up gauge
homelab_restic_server_container_up{host="ids-01",service="restic-server"} $container_up
# HELP homelab_restic_server_port_published Whether Docker reports port ${PORT}/tcp as published.
# TYPE homelab_restic_server_port_published gauge
homelab_restic_server_port_published{host="ids-01",service="restic-server"} $port_published
# HELP homelab_restic_server_port_listening Whether TCP port ${PORT} is listening on ids-01.
# TYPE homelab_restic_server_port_listening gauge
homelab_restic_server_port_listening{host="ids-01",service="restic-server"} $port_listening
# HELP homelab_restic_server_https_reachable Whether the Restic HTTPS endpoint responds locally.
# TYPE homelab_restic_server_https_reachable gauge
homelab_restic_server_https_reachable{host="ids-01",service="restic-server"} $https_reachable
# HELP homelab_restic_server_health_timestamp_seconds Time the Restic server health check ran.
# TYPE homelab_restic_server_health_timestamp_seconds gauge
homelab_restic_server_health_timestamp_seconds{host="ids-01",service="restic-server"} $(date +%s)
EOF

chmod 0644 "$TMP"
mv "$TMP" "$OUTFILE"

printf 'restic_server_up=%s container=%s published=%s listening=%s https=%s http_code=%s\n' \
  "$up" "$container_up" "$port_published" "$port_listening" "$https_reachable" "${http_code:-none}"
