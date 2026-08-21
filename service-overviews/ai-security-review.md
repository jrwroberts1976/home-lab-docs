# AI Security Review

## Purpose

The homelab AI security review on `ids-01` consolidates security and operational evidence from Loki, Prometheus and Greenbone into a single structured review. Its job is not to replace the underlying monitoring systems; it uses their evidence to produce an advisory security summary and highlight items that may need investigation.

The primary reader is:

```text
/usr/local/bin/homelab-security-reader.py
```

**Server / Host:** `ids-01`

## High-level flow

```text
Suricata alerts ───────────────┐
Pi-hole / DNS events ─────────┤
SSH / authentication events ──┤
CrowdSec logs ─────────────────┤
Syslog ────────────────────────┤
                              ├─> Loki ─> homelab-security-reader.py ─> AI security review
Prometheus security metrics ──┤
                              │
Greenbone findings/metrics ───┴─> Greenbone AI review ─> latest.md
                                              │
                                              └─> Alloy ─> Loki
```

The Greenbone report is therefore both an AI-generated review artifact and a Loki-searchable operational record. Loki data is not fed back into the Greenbone AI review itself; the general security reader is the component that queries Loki and combines multiple evidence sources.

## Loki inputs

The security reader contains a reusable `query_loki()` function and explicit collectors for several Loki sources.

### Suricata

The Suricata collector queries:

```logql
{job="suricata-alerts",host="ids-01"}
```

This provides security-relevant network IDS events for AI review.

### Pi-hole / DNS

The DNS collector queries Loki for Pi-hole query and blocking records, including gravity-blocked and blocked-domain events. This evidence is used to distinguish observed DNS activity from confirmed blocking activity and to avoid claiming certainty when the source is unknown.

### Authentication / SSH

The authentication collector analyses failed and successful login activity, including:

- failed login attempts
- successful logins
- top failed-login sources
- successful-login sources
- repeated failures followed by a successful login

This allows the AI review to identify suspicious authentication patterns rather than only counting failures.

### CrowdSec

The CrowdSec collector queries three streams:

```logql
{job="crowdsec",host="ids-01"}
{job="crowdsec-api",host="ids-01"}
{job="crowdsec-bouncer",host="ids-01"}
```

These streams provide CrowdSec engine, Local API and firewall-bouncer evidence to the review. All three sources must be readable by Alloy and present in Loki for this evidence to be complete.

### Syslog

The syslog collector queries:

```logql
{job="syslog",host=~".+"}
```

This provides broader host and service log evidence that may not belong to one of the dedicated security streams.

## Prometheus inputs

The reader also contains a `prometheus_query()` function and uses Prometheus metrics alongside log evidence. This gives the AI review current state and health indicators in addition to event text.

Examples include Greenbone and other homelab security/monitoring metrics collected by the script's individual collectors.

## Greenbone integration

Greenbone has a separate AI review workflow. The scheduled service:

```text
homelab-greenbone-ai-review.service
```

runs:

```text
/usr/local/sbin/homelab-greenbone-ai-review
```

and writes timestamped reports under:

```text
/var/lib/homelab-greenbone/reports/greenbone-review-*.md
```

with:

```text
/var/lib/homelab-greenbone/reports/latest.md
```

pointing to the latest review.

The general security reader references the latest Greenbone report and also has its own `collect_greenbone()` path, allowing Greenbone evidence to be represented in the wider security review.

## Greenbone report ingestion into Loki

Grafana Alloy on `ids-01` tails:

```text
/var/lib/homelab-greenbone/reports/greenbone-review-*.md
```

with labels:

```text
job="greenbone-review"
host="ids-01"
env="homelab"
service="greenbone"
```

and forwards the content to central Loki at:

```text
http://192.168.2.242:3100/loki/api/v1/push
```

A live end-to-end test on 21 August 2026 appended a unique marker to the current Greenbone report and successfully retrieved it from Loki using:

```logql
{job="greenbone-review",host="ids-01",service="greenbone"} |= "GREENBONE_LOKI_TEST_"
```

This proved:

```text
Greenbone report -> Alloy -> Loki
```

## File-permission requirement

Alloy runs as:

```text
alloy:alloy
```

The Greenbone reports directory therefore needs to be traversable by the `alloy` group and generated reports need to be readable by that group.

The Greenbone report generator was corrected so new reports are installed as:

```text
root:alloy
0640
```

using:

```bash
install -o root -g alloy -m 0640 "$report_tmp" "$report_file"
```

This replaces the previous `0600` mode which prevented Alloy from tailing newly generated reports.

## Operational checks

To verify Greenbone ingestion from Alloy:

```bash
sudo journalctl -u alloy --since "10 minutes ago" -l --no-pager \
  | grep -Ei 'greenbone_review|permission denied'
```

To query Greenbone review entries directly from Loki:

```bash
curl -sG 'http://192.168.2.242:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job="greenbone-review",host="ids-01",service="greenbone"}' \
  --data-urlencode 'limit=20' \
  --data-urlencode 'direction=backward'
```

## Data-quality principle

The AI review is only as complete as the evidence available to its collectors. A configured collector does not prove that its underlying log stream is healthy. Loki ingestion permissions, source freshness and Prometheus collector health should therefore be monitored independently.

For example, if `crowdsec-api` cannot be read by Alloy, the security reader can still execute but its CrowdSec API evidence will be incomplete.

## Related components

```text
/usr/local/bin/homelab-security-reader.py
/usr/local/sbin/homelab-greenbone-ai-review
/etc/alloy/config.alloy
/var/lib/homelab-greenbone/reports/
Loki :3100
Prometheus
Grafana
```
