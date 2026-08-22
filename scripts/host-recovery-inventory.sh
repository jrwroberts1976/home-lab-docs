#!/usr/bin/env bash
set -euo pipefail

HOST="$(hostname -s 2>/dev/null || hostname)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BASE_DIR="${OUTPUT_DIR:-$(pwd)}"
OUT_DIR="${BASE_DIR}/host-recovery-${HOST}-${STAMP}"
ARCHIVE="${OUT_DIR}.tar.gz"

mkdir -p "$OUT_DIR"

log(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }
run(){ local f="$1"; shift; { printf '# command:'; printf ' %q' "$@"; printf '\n\n'; "$@"; } >"$OUT_DIR/$f" 2>&1 || true; }
shrun(){ local f="$1"; shift; { printf '# shell command: %s\n\n' "$*"; bash -lc "$*"; } >"$OUT_DIR/$f" 2>&1 || true; }

log "Collecting recovery inventory for $HOST"

run hostname.txt hostnamectl
run uname.txt uname -a
run os-release.txt cat /etc/os-release
run date-timezone.txt timedatectl
run cpu.txt lscpu
run memory.txt free -h
run block-devices.txt lsblk -o NAME,KNAME,TYPE,SIZE,FSTYPE,FSVER,LABEL,UUID,PARTUUID,MOUNTPOINTS,MODEL,SERIAL
run filesystem.txt df -hT
run mounts.txt findmnt -a

shrun boot-files.txt 'for f in /boot/cmdline.txt /boot/firmware/cmdline.txt /boot/config.txt /boot/firmware/config.txt; do [ -f "$f" ] || continue; echo "### $f"; cat "$f"; echo; done'

if command -v dpkg-query >/dev/null 2>&1; then
  shrun packages-installed.txt "dpkg-query -W -f='\${binary:Package}\t\${Version}\n' | sort"
  shrun packages-manual.txt 'apt-mark showmanual | sort'
  shrun apt-sources.txt 'find /etc/apt -maxdepth 2 -type f \( -name "*.list" -o -name "*.sources" \) -print -exec sh -c '\''echo "### $1"; cat "$1"'\'' _ {} \;'
fi

run passwd-summary.txt getent passwd
run group-summary.txt getent group
shrun sudoers-summary.txt 'find /etc/sudoers.d -maxdepth 1 -type f -print -exec sh -c '\''echo "### $1"; cat "$1"'\'' _ {} \; 2>/dev/null; echo "### /etc/sudoers"; cat /etc/sudoers 2>/dev/null'

run ip-address.txt ip -br address
run ip-route.txt ip route show table all
run ip-rule.txt ip rule
run resolv.conf.txt cat /etc/resolv.conf
shrun network-config.txt 'for d in /etc/network/interfaces /etc/network/interfaces.d /etc/NetworkManager/system-connections /etc/systemd/network; do [ -e "$d" ] || continue; echo "### $d"; find "$d" -maxdepth 2 -type f -print 2>/dev/null; done'
run listeners.txt ss -lntup

command -v nft >/dev/null 2>&1 && run nft-ruleset.txt nft list ruleset || true
command -v iptables-save >/dev/null 2>&1 && run iptables-rules.txt iptables-save || true
command -v ip6tables-save >/dev/null 2>&1 && run ip6tables-rules.txt ip6tables-save || true

run systemd-enabled.txt systemctl list-unit-files --state=enabled
run systemd-failed.txt systemctl --failed --no-pager -l
run systemd-timers.txt systemctl list-timers --all --no-pager
shrun custom-systemd-units.txt 'find /etc/systemd/system -type f \( -name "*.service" -o -name "*.timer" -o -name "*.socket" -o -name "*.path" \) -print -exec sh -c '\''echo "### $1"; cat "$1"'\'' _ {} \; 2>/dev/null'

shrun cron-system.txt 'for f in /etc/crontab /etc/cron.d/*; do [ -f "$f" ] || continue; echo "### $f"; cat "$f"; echo; done'
shrun cron-users.txt 'while IFS=: read -r u _; do c=$(crontab -u "$u" -l 2>/dev/null || true); [ -n "$c" ] || continue; echo "### $u"; printf "%s\n" "$c"; echo; done < /etc/passwd'

if command -v docker >/dev/null 2>&1; then
  run docker-version.txt docker version
  run docker-info.txt docker info
  run docker-ps.txt docker ps -a --no-trunc
  run docker-images.txt docker image ls --digests --no-trunc
  run docker-networks.txt docker network ls
  run docker-volumes.txt docker volume ls
  shrun docker-container-config-summary.txt 'docker ps -aq | while read -r id; do docker inspect "$id" --format '\''{{.Name}}|image={{.Config.Image}}|restart={{.HostConfig.RestartPolicy.Name}}|network={{.HostConfig.NetworkMode}}|ports={{json .HostConfig.PortBindings}}|mounts={{json .Mounts}}'\''; done'
  shrun docker-compose-files.txt 'find /home /opt /srv -xdev -type f \( -name compose.yml -o -name compose.yaml -o -name docker-compose.yml -o -name docker-compose.yaml \) -print 2>/dev/null | sort'
fi

command -v k3s >/dev/null 2>&1 && run k3s-version.txt k3s --version || true
if command -v kubectl >/dev/null 2>&1; then
  run kubectl-version.txt kubectl version --client
  shrun kubernetes-summary.txt 'kubectl get nodes -o wide; echo; kubectl get ns; echo; kubectl get all -A -o wide'
  shrun kubernetes-resources.txt 'kubectl get deploy,statefulset,daemonset,svc,ingress,pvc,storageclass,configmap -A -o yaml'
fi

shrun monitoring-security-services.txt 'systemctl list-unit-files | grep -Ei "prometheus|grafana|alloy|promtail|suricata|crowdsec|greenbone|gvm|node-exporter|cadvisor|pihole|unbound|restic|nebula|jenkins" || true'
shrun custom-scripts.txt 'find /usr/local/bin /home -xdev -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" \) -printf "%p\n" 2>/dev/null | sort'
shrun project-repos.txt 'find /home /opt /srv -xdev -type d -name .git -printf "%h\n" 2>/dev/null | sort -u'
shrun project-remotes.txt 'find /home /opt /srv -xdev -type d -name .git -printf "%h\n" 2>/dev/null | sort -u | while read -r r; do echo "### $r"; git -C "$r" remote -v 2>/dev/null || true; git -C "$r" status --short --branch 2>/dev/null || true; echo; done'

shrun backup-config-summary.txt 'find /etc/systemd/system /home /root -xdev -type f \( -iname "*restic*" -o -iname "*backup*" \) -printf "%p\n" 2>/dev/null | sort'
shrun restic-repositories.txt 'grep -RhsE "RESTIC_REPOSITORY|rest:https?://|s3:|sftp:" /etc/systemd/system /home /root 2>/dev/null | sed -E "s#(https?://)[^/@:]+:[^/@]+@#\\1***:***@#g" | sort -u'

# Secret inventory by path only. Secret contents are deliberately excluded.
shrun secret-file-inventory.txt 'find /etc /home /root /opt /srv -xdev -type f \( -name ".env" -o -name "*.env" -o -iname "*secret*" -o -iname "*password*" -o -iname "*token*" -o -name "id_rsa" -o -name "id_ed25519" -o -name "*.key" -o -name "*.pem" \) -printf "%m\t%u:%g\t%s\t%p\n" 2>/dev/null | sort'

shrun restore-paths.txt 'for d in /etc /usr/local/bin /home/*/docker /home/*/scripts /home/*/homelab /home/*/projects /var/lib/prometheus /var/lib/grafana /var/lib/node_exporter /etc/pihole /etc/unbound /etc/suricata /etc/crowdsec; do [ -e "$d" ] || continue; stat -c "%A %U:%G %s %n" "$d"; done'

cat > "$OUT_DIR/RECOVERY-README.md" <<EOF
# Host Recovery Inventory — $HOST

Captured: $(date -Is)

This bundle is an inventory, not a backup. Use it with Restic/other protected data to rebuild this host.

## Recovery order
1. Reinstall the same base OS/architecture and patch it.
2. Restore hostname, network addressing, DNS and firewall rules.
3. Recreate users/groups and SSH/sudo access.
4. Install manually-selected packages from \`packages-manual.txt\`.
5. Restore custom systemd units, timers and cron jobs.
6. Install Docker/container runtime if present; restore compose files and persistent data.
7. Restore application data from backup before starting dependent services.
8. Restore custom scripts and Git repositories.
9. Restore secrets from secure storage using \`secret-file-inventory.txt\` as the checklist.
10. Re-enable monitoring/security tooling and validate alerts.
11. Compare listeners, timers, services and containers against this inventory.
EOF

( cd "$OUT_DIR" && sha256sum ./* 2>/dev/null | sort > MANIFEST.sha256 || true )
tar -C "$BASE_DIR" -czf "$ARCHIVE" "$(basename "$OUT_DIR")"

log "Inventory complete"
echo "Directory: $OUT_DIR"
echo "Archive:   $ARCHIVE"
echo "Next: bash scripts/host-recovery-scp-generate.sh '$OUT_DIR'"
