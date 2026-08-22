# Daily Security & Recovery Reporting

## Purpose

This page documents where the daily homelab security/recovery emails are generated, how they are scheduled, and which components should be reviewed when changing the report logic.

The two key emails are:

- **Homelab Daily Security & Recovery Brief**
- **Homelab Engineering Security Runbook**

## Current generator components

### Core report-generation logic

The main report-generation logic is implemented in:

```text
/usr/local/bin/homelab-security-reader.py
```

Relevant sections found during discovery include text around:

```text
You are preparing the daily security and operational risk report
# Daily Security & Operational Risk Report
```

This script should be treated as the primary candidate for changing how evidence is interpreted and how GREEN / AMBER / RED or engineering priorities are derived.

## Management brief path

The daily management-style brief is associated with:

```text
homelab-secops-management-report.timer
homelab-secops-management-report.service
```

Observed schedule on 22 August 2026:

```text
08:30 BST daily
```

The service definition should be inspected with:

```bash
systemctl cat homelab-secops-management-report.service
systemctl cat homelab-secops-management-report.timer
```

Recent execution evidence can be checked with:

```bash
journalctl -u homelab-secops-management-report.service --since "24 hours ago" --no-pager -l
```

## Engineering runbook path

The engineering runbook email is associated with:

```text
homelab-greenbone-engineering-email.timer
homelab-greenbone-engineering-email.service
```

The timer description is:

```text
Daily engineering security runbook email
```

The service description is:

```text
Email engineering security runbook
```

Inspect with:

```bash
systemctl cat homelab-greenbone-engineering-email.service
systemctl cat homelab-greenbone-engineering-email.timer
```

Recent execution evidence can be checked with:

```bash
journalctl -u homelab-greenbone-engineering-email.service --since "24 hours ago" --no-pager -l
```

## Related daily security components

The host also contains these related units:

```text
security-review.timer
security-review.service
homelab-greenbone-ai-review.timer
homelab-greenbone-email.timer
homelab-secops-report.timer
homelab-secops-report.service
```

These may contribute source evidence or generate related reports. They should not be modified until their role in the data flow is confirmed.

## Current reporting problem identified on 22 August 2026

The daily reports can understate operational risk by treating the absence of compromise as equivalent to overall operational health.

Examples found during the 22 August review included:

- backup job results reported as unavailable without becoming engineering actions;
- off-host replica health reported as unknown but not promoted into the work queue;
- backup storage health reported as unknown but not treated as degraded visibility;
- a failed Pi-hole blocklist collector existed while high-level reporting still described Pi-hole collection as available;
- a transient CrowdSec local API refusal was correctly identified as an engineering P2;
- a non-applicable OpenIPMI service failure added noise to the host failure state.

## Reporting rules to implement

Future report-generation logic should follow these principles:

1. **UNKNOWN is not HEALTHY.** Missing or unavailable evidence must be represented explicitly.
2. **No compromise does not mean no incident.** Security posture and operational resilience must be scored separately.
3. **Freshness matters.** A timer or service existing is not enough; collector output must be fresh and successfully scraped.
4. **Failed units must be classified.** Actionable service failures should affect the report; intentionally masked/non-applicable services should not.
5. **Backup status must distinguish PASS / FAIL / UNKNOWN.** Unknown backup, replica or storage state should produce at least a planned engineering action unless intentionally suppressed.
6. **Overall status should be derived from the worst meaningful unresolved condition**, not solely from security-compromise evidence.

## Recommended report dimensions

The management brief should independently assess:

- Security posture
- DNS / policy enforcement
- Backup & recovery
- Infrastructure availability
- Monitoring integrity

The engineering runbook should classify findings as:

- **P1** — active outage, compromise, or critical protection/recovery failure
- **P2** — degraded resilience/control requiring investigation today
- **P3** — improvement, monitoring gap, or recovery risk requiring planned work
- **HEALTHY** — positively verified control with sufficient current evidence

## Discovery commands

A reusable discovery script is stored in the docs repository:

```text
scripts/find-daily-brief-generators.sh
```

Run on ids-01 with:

```bash
cd ~/projects/home-lab-docs
git pull
sudo bash scripts/find-daily-brief-generators.sh
```

The script searches for:

- exact and likely report titles;
- systemd services and timers;
- cron references;
- mail-sending logic;
- likely evidence-source references.

## Next investigation

Before modifying report logic, capture the exact execution chain for each report:

```bash
systemctl cat homelab-secops-management-report.service
systemctl cat homelab-secops-management-report.timer
systemctl cat homelab-greenbone-engineering-email.service
systemctl cat homelab-greenbone-engineering-email.timer
```

Then inspect the invoked scripts and trace their inputs back to `/usr/local/bin/homelab-security-reader.py` or any intermediate files.

The final documented flow should be expressed as:

```text
collector/evidence sources
    -> security review / aggregation
    -> homelab-security-reader.py
    -> management brief generator
    -> engineering runbook generator
    -> email sender
```
