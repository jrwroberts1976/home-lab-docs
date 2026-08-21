# SOP: Log Ingestion and Grafana Alert Email Recovery

## Purpose

This SOP records the recovery work completed on `ids-01` on 21 August 2026 after several monitoring and alerting paths were found to be fragile or partially broken.

The work covered:

- Greenbone AI review report ingestion into Loki;
- Pi-hole secondary and Unbound container logging;
- CrowdSec engine and Local API logging;
- Grafana alert-email delivery through Gmail SMTP;
- the configuration files and runtime locations involved.

The objective was to remove dependencies on container IDs and fragile file permissions, preserve the Loki labels used by dashboards and AI review tooling, and restore end-to-end alert email delivery.

## Scope

Primary host:

```text
ids-01
```

Relevant services:

```text
Grafana Alloy
Loki
Grafana
CrowdSec
CrowdSec Local API
CrowdSec firewall bouncer
Pi-hole secondary
Unbound
Greenbone AI review
```

## 1. Greenbone AI review report ingestion

### Symptom

Alloy reported `permission denied` when attempting to read a generated Greenbone AI review under:

```text
/var/lib/homelab-greenbone/reports/greenbone-review-*.md
```

The report generator created files as `root:root` with mode `0600`, while Alloy runs as the `alloy` user.

### Immediate repair

Existing report files were made readable by the Alloy group:

```bash
sudo chgrp alloy /var/lib/homelab-greenbone/reports
sudo chmod 750 /var/lib/homelab-greenbone/reports
sudo find /var/lib/homelab-greenbone/reports \
  -maxdepth 1 -type f -name 'greenbone-review-*.md' \
  -exec chgrp alloy {} + \
  -exec chmod 640 {} +
```

### Permanent repair

The generator script:

```text
/usr/local/sbin/homelab-greenbone-ai-review
```

was changed from installing reports with mode `0600` to:

```bash
install -o root -g alloy -m 0640 "$report_tmp" "$report_file"
```

The reports directory remains traversable by the Alloy group.

### Validation

A unique marker was appended to the current report and retrieved from Loki using the `greenbone-review` stream, proving:

```text
Greenbone report -> Alloy -> Loki
```

A subsequent scheduled/new report should still be checked to prove the generator-side permission fix remains effective without manual intervention.

## 2. Pi-hole secondary and Unbound: Docker JSON logs to journald

### Problem

Alloy had dedicated `loki.source.file` blocks that referenced Docker JSON log paths by container ID. This caused two problems:

- a recreated container changed its ID and made the configured path stale;
- Alloy could encounter permission errors reading Docker's container log files directly.

### Docker Compose change

The stack is located at:

```text
/home/james/docker/stacks/pihole-secondary/compose.yml
```

Both the `pihole` and `unbound` services were changed to use Docker's journald logging driver:

```yaml
logging:
  driver: journald
```

The stack was recreated with:

```bash
cd /home/james/docker/stacks/pihole-secondary
docker compose up -d
```

### Alloy change

The old hard-coded Docker JSON file sources were replaced with journal sources selected by stable container names.

Pi-hole secondary:

```alloy
loki.source.journal "pihole_secondary" {
  matches = "CONTAINER_NAME=pihole-secondary"

  labels = {
    job       = "pihole",
    host      = "ids-01",
    env       = "homelab",
    service   = "pihole",
    container = "pihole-secondary",
  }

  forward_to = [loki.write.loki.receiver]
}
```

Unbound:

```alloy
loki.source.journal "pihole_unbound" {
  matches = "CONTAINER_NAME=pihole2-unbound"

  labels = {
    job       = "unbound",
    host      = "ids-01",
    env       = "homelab",
    service   = "unbound",
    container = "pihole2-unbound",
  }

  forward_to = [loki.write.loki.receiver]
}
```

The stale Pi-hole/Unbound container-ID exclusions were also removed from the generic Docker JSON-file source because these two containers no longer use the JSON-file logging driver.

### Validation

Both streams were queried directly from Loki and returned current entries:

```logql
{job="pihole",host="ids-01"}
{job="unbound",host="ids-01"}
```

This proved:

```text
Pi-hole secondary -> Docker journald -> Alloy -> Loki
Unbound -> Docker journald -> Alloy -> Loki
```

The path no longer depends on Docker container IDs or ACLs on `/var/lib/docker/containers/...`.

## 3. CrowdSec agent and Local API: file logs to syslog/journald

### Problem

Alloy reported a permission error reading:

```text
/var/log/crowdsec_api.log
```

An immediate `root:alloy 0640` permission change restored access, but this was not durable because CrowdSec creates and rotates its own logs.

The relevant CrowdSec configuration was found in:

```text
/etc/crowdsec/config.yaml
```

and contained:

```yaml
common:
  daemonize: true
  log_media: file
  log_level: info
  log_dir: /var/log/
```

### CrowdSec change

The main logging medium was changed to syslog:

```yaml
common:
  daemonize: true
  log_media: syslog
  log_level: info
```

The configuration was validated before restart:

```bash
sudo /usr/bin/crowdsec -c /etc/crowdsec/config.yaml -t -error
```

CrowdSec was then restarted and application messages were confirmed with:

```bash
sudo journalctl -u crowdsec --since "2 minutes ago" --no-pager
```

### Alloy change

The main CrowdSec and Local API file readers were replaced by a journal reader for:

```text
_SYSTEMD_UNIT=crowdsec.service
```

The base stream retains:

```text
job="crowdsec"
host="ids-01"
env="homelab"
service="crowdsec"
```

The Local API needs to preserve the existing `job="crowdsec-api"` label because `homelab-security-reader.py` and related review logic query that stream explicitly.

The first split attempted to match `module=lapi`. After changing CrowdSec to syslog, that structured suffix was not present in the journal line text. The selector was therefore changed to identify observed LAPI HTTP access lines by method and `/v1/` path:

```alloy
stage.match {
  selector = "{job=\"crowdsec\"} |~ \"(GET|POST|PUT|PATCH|DELETE) /v1/\""

  stage.static_labels {
    values = {
      job = "crowdsec-api",
    }
  }
}
```

### Validation

Fresh post-restart traffic was observed in Loki as:

```logql
{job="crowdsec-api",host="ids-01"}
```

including a current firewall-bouncer request to:

```text
GET /v1/decisions/stream
```

The generic CrowdSec stream also continued to receive current data.

Some `/v1/heartbeat` traffic was still observed under `job="crowdsec"`; this is currently treated as harmless classification noise rather than data loss and can be refined later if required.

### Firewall bouncer

The firewall bouncer remains a separate file-based source:

```text
/var/log/crowdsec-firewall-bouncer.log
```

with Loki job:

```text
job="crowdsec-bouncer"
```

It was already working and was deliberately left unchanged.

## 4. Grafana alert-email outage

### Symptom

Grafana alert rules were evaluating and the notification router was attempting delivery, but no alert emails were arriving.

Grafana logs showed repeated failures such as:

```text
failed to send email: dial tcp: lookup smtp.gmail.com on 127.0.0.11:53: server misbehaving
```

Affected alerts included Pi-hole health/configuration alerts and `Linux Host Down`, proving the failure was in the shared email delivery path rather than an individual alert rule.

### Root cause

Inside the existing Grafana container, `/etc/resolv.conf` contained Docker's embedded resolver:

```text
nameserver 127.0.0.11
```

but reported:

```text
NO EXTERNAL NAMESERVERS DEFINED
```

Running DNS resolution as both the normal Grafana user and root failed, ruling out a container-user permission problem.

The `ids-01` host itself had valid DNS configuration:

```text
nameserver 192.168.2.48
nameserver 192.168.2.242
```

The Grafana container had been created with stale Docker DNS state before those upstream resolvers were available to Docker.

### Recovery

The monitoring Compose stack was found at:

```text
/home/james/docker/stacks/monitoring/docker-compose.yml
```

Grafana was recreated without changing its SMTP settings:

```bash
cd /home/james/docker/stacks/monitoring
docker compose up -d --force-recreate grafana
```

The regenerated container resolver then showed:

```text
ExtServers: [host(192.168.2.48) host(192.168.2.242)]
```

and:

```bash
docker exec grafana getent hosts smtp.gmail.com
```

successfully returned an address.

A Grafana contact-point test email was then sent successfully.

### Important conclusion

The alert rules and SMTP credentials did not need changing. The outage was caused by stale Docker DNS state in the existing Grafana container.

## 5. Configuration files and locations discovered

These are the relevant files/paths identified during the work.

| Path | Purpose / finding |
| --- | --- |
| `/etc/alloy/config.alloy` | Main Alloy configuration. Contains Greenbone, Pi-hole, Unbound, CrowdSec, bouncer and other Loki sources. |
| `/etc/crowdsec/config.yaml` | CrowdSec main configuration. `common.log_media` changed from `file` to `syslog`. |
| `/usr/lib/systemd/system/crowdsec.service` | CrowdSec systemd unit. Runs `/usr/bin/crowdsec -c /etc/crowdsec/config.yaml`. |
| `/var/log/crowdsec.log` | Legacy CrowdSec agent file log after migration to syslog; no longer the intended Alloy source for new main-agent events. |
| `/var/log/crowdsec_api.log` | Legacy Local API file log after migration; was the source of the original Alloy permission error. |
| `/var/log/crowdsec-firewall-bouncer.log` | Separate firewall-bouncer log; remains in use by its dedicated Alloy source. |
| `/home/james/docker/stacks/pihole-secondary/compose.yml` | Pi-hole secondary and Unbound Compose definition. Both services now use `logging.driver: journald`. |
| `/home/james/docker/stacks/monitoring/docker-compose.yml` | Monitoring stack definition containing Grafana, Prometheus and Loki. Grafana SMTP settings are supplied here/environment. |
| `/home/james/docker/stacks/monitoring/.env` | Monitoring-stack environment file. Treat as secret-bearing; do not copy its values into documentation. |
| `/etc/resolv.conf` | Host resolver configuration. At recovery time contained both Pi-hole resolvers. |
| `/etc/resolv.conf` inside `grafana` | Docker-generated resolver state. Used to prove the stale/no-upstream DNS condition and the successful regenerated state. |
| `/usr/local/sbin/homelab-greenbone-ai-review` | Greenbone AI report generator; corrected to create reports as `root:alloy 0640`. |
| `/var/lib/homelab-greenbone/reports/` | Generated Greenbone AI review reports consumed by Alloy. |
| `/usr/local/bin/homelab-security-reader.py` | General AI security reader; queries Loki/Prometheus and depends on stable job labels including `crowdsec-api`. |

## 6. Backups created during the change

Backups observed/created during the work include:

```text
/etc/crowdsec/config.yaml.bak-20260821-journald
/etc/alloy/config.alloy.bak-20260821-journald
/etc/alloy/config.alloy.bak-20260821-crowdsec-journal
/home/james/docker/stacks/pihole-secondary/compose.yml.bak-20260821
/usr/local/sbin/homelab-greenbone-ai-review.bak-20260821
```

The monitoring directory also contains timestamped `docker-compose.yml.autosync-*` and manual backup files. These are useful for recovery but should not be assumed to be the desired current configuration without comparison.

## 7. Validation checklist

After changes to any of these components, verify all of the following.

### Alloy

```bash
sudo /usr/bin/alloy validate /etc/alloy/config.alloy
sudo systemctl status alloy --no-pager
```

### CrowdSec

```bash
sudo /usr/bin/crowdsec -c /etc/crowdsec/config.yaml -t -error
sudo systemctl status crowdsec --no-pager
sudo journalctl -u crowdsec --since "5 minutes ago" --no-pager
```

### Pi-hole / Unbound journal sources

```bash
sudo journalctl CONTAINER_NAME=pihole-secondary -n 10 --no-pager
sudo journalctl CONTAINER_NAME=pihole2-unbound -n 10 --no-pager
```

### Loki

Confirm current entries for:

```logql
{job="pihole",host="ids-01"}
{job="unbound",host="ids-01"}
{job="crowdsec",host="ids-01"}
{job="crowdsec-api",host="ids-01"}
{job="crowdsec-bouncer",host="ids-01"}
{job="greenbone-review",host="ids-01"}
```

### Grafana email DNS

```bash
docker exec grafana cat /etc/resolv.conf
docker exec grafana getent hosts smtp.gmail.com
```

Then use Grafana's email contact-point **Test** action and confirm receipt.

### Grafana delivery errors

```bash
docker logs --since 15m grafana 2>&1 \
  | grep -Ei 'smtp|email|notification.*(fail|error)|failed to send'
```

No new DNS/SMTP delivery errors should appear after a successful test.

## 8. Follow-up work

- Verify the next newly generated Greenbone report automatically has `root:alloy 0640` and reaches Loki.
- Add ingestion-health monitoring for the Greenbone review stream.
- Monitor `crowdsec-api` freshness and refine heartbeat classification if useful.
- Consider detecting Grafana notification-path failures so SMTP/DNS outages cannot remain silent.

## Related documentation

- [AI Security Review](../service-overviews/ai-security-review.md)
- [Grafana Alert Email Standard](../grafana-alert-email-standard.md)
