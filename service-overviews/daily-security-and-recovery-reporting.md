# Daily Security & Recovery Reporting

## Purpose

This page documents where the daily homelab security/recovery emails are generated, how they are scheduled, their evidence flow, and which components should be changed when improving report quality.

The two key emails are:

- **Homelab Daily Security & Recovery Brief / management report**
- **Homelab Engineering Security Runbook**

The live execution paths below were confirmed on `ids-01` on 22 August 2026.

## Reporting architecture

The two emails share security evidence but have separate reporting paths.

### Daily Security & Recovery Brief

```text
Security telemetry
       |
       +--> Prometheus
       +--> Loki / Alloy
       +--> Suricata
       +--> CrowdSec
       +--> Pi-hole
       +--> Greenbone
       |
       v
Technical security evidence
       |
       v
/usr/local/lib/homelab-secops-report/generate_report.py
       |
       v
/var/lib/homelab-secops-report/reports/latest.md
       |
       v
/usr/local/lib/homelab-secops-report/generate_management_report.py
       |
       v
OpenAI Responses API
       |
       v
/var/lib/homelab-secops-report/management/latest.md
       |
       v
Daily Security & Recovery Brief
```

The management brief is therefore an **interpretation of the authoritative technical SecOps report**, not a replacement for it.

### Engineering Security Runbook

```text
Greenbone
       |
       v
Greenbone AI security review
       |
       v
/var/lib/homelab-greenbone/reports/latest.md
       |
       v
/usr/local/sbin/homelab-greenbone-engineering-email
       |
       v
Homelab Engineering Security Runbook
```

The Engineering Security Runbook is a separate engineering-focused report derived from the Greenbone reporting path.

A detected security event is not automatically evidence of a successful compromise.

## Management report — confirmed execution chain

The management report runs daily at **08:30**:

```text
homelab-secops-management-report.timer
    -> homelab-secops-management-report.service
    -> /usr/local/sbin/homelab-secops-management-report
    -> /usr/local/sbin/homelab-secops-report
    -> refresh evidence
         -> /usr/local/sbin/homelab-secops-greenbone-evidence
         -> /usr/local/sbin/homelab-secops-network-inventory
         -> /usr/local/sbin/homelab-secops-pihole-evidence
    -> /usr/local/lib/homelab-secops-report/generate_report.py
    -> /var/lib/homelab-secops-report/reports/latest.md
    -> /usr/local/lib/homelab-secops-report/generate_management_report.py
    -> OpenAI Responses API
    -> /var/lib/homelab-secops-report/management/latest.md
```

The systemd service loads the OpenAI API environment from:

```text
/etc/homelab-openai/api-key
```

and currently sets:

```text
OPENAI_MANAGEMENT_MODEL=gpt-5.6-terra
```

The management generator uses the technical report at:

```text
/var/lib/homelab-secops-report/reports/latest.md
```

as its authoritative source. Its prompt explicitly requires the generated management report to preserve the technical report's overall posture and `GOOD`, `ATTENTION`, and `ACTION REQUIRED` states.

### Consequence

Incorrect underlying classification should normally be fixed in the technical report/evidence path first, particularly:

```text
/usr/local/lib/homelab-secops-report/generate_report.py
```

The management prompt should not be used to silently reinterpret or override incorrect technical evidence.

## Engineering Security Runbook — confirmed execution chain

The engineering runbook email is sent daily at **07:45**:

```text
homelab-greenbone-engineering-email.timer
    -> homelab-greenbone-engineering-email.service
    -> /usr/local/sbin/homelab-greenbone-engineering-email
    -> reads /var/lib/homelab-greenbone/reports/latest.md
    -> extracts from "## Priority Summary"
       up to "## Network IDS — Suricata"
    -> converts Markdown to HTML
    -> sends through msmtp
```

The email sender is therefore **not the engineering analysis generator**. It formats and sends an already-generated section of the Greenbone security report.

The subject is generated as:

```text
Homelab Engineering Security Runbook - <date>
```

SMTP configuration is read from:

```text
/etc/homelab-greenbone/msmtprc
/etc/homelab-greenbone/smtp.env
```

## Greenbone AI review — confirmed upstream path

The Greenbone AI review runs daily at **07:30**, with up to five minutes of randomized delay:

```text
homelab-greenbone-ai-review.timer
    -> homelab-greenbone-ai-review.service
    -> /usr/local/sbin/homelab-greenbone-ai-review
```

`/usr/local/bin/homelab-security-reader.py` directly references:

```text
/var/lib/homelab-greenbone/reports/latest.md
```

and contains the security/operational-risk prompt logic. It is therefore a primary component to inspect when changing the engineering runbook's classification and priority logic.

The engineering email runs after the AI review service, providing the intended sequence:

```text
07:30 Greenbone AI review
    -> generate/update Greenbone latest.md
07:45 engineering email
    -> extract Priority Summary
    -> email runbook
```

## Two report-generation brains

The main logic requiring review is now narrowed to two components:

### Technical SecOps / management source of truth

```text
/usr/local/lib/homelab-secops-report/generate_report.py
```

This controls the technical report that the management generator is required to trust.

### Engineering runbook / Greenbone interpretation

```text
/usr/local/bin/homelab-security-reader.py
```

This controls security/operational interpretation feeding the Greenbone report and engineering runbook.

## Management generator

The management transformation is implemented in:

```text
/usr/local/lib/homelab-secops-report/generate_management_report.py
```

It calls the OpenAI Responses API and writes the management report. Important existing prompt rules include:

- use only facts from the supplied technical report;
- do not invent, infer, exaggerate, downgrade, or alter findings;
- preserve the overall security posture exactly;
- preserve `GOOD`, `ATTENTION`, and `ACTION REQUIRED` states exactly;
- distinguish active findings, accepted risks, pending remediation, and evidence limitations;
- successful backup/replication is not proof of tested restoration;
- DNS requests must not be presented as deliberate user activity without evidence.

This is good separation of responsibilities, but it means the technical source must classify missing and degraded evidence correctly.

## Network security interpretation

The technical report now separates four different concepts:

### Confirmed compromise

Examples include:

- successful unauthorised authentication;
- confirmed malware execution;
- confirmed ransomware activity;
- confirmed exploitation;
- confirmed unauthorised access.

These require incident-level attention.

A failed SSH login is not a successful compromise.

A Suricata alert is not automatically successful exploitation.

A blocked Pi-hole request is not evidence that the requested activity succeeded.

### Security activity detected

Examples include:

- Suricata alerts;
- failed SSH attempts;
- blocked DNS requests;
- CrowdSec detections;
- other security-policy events.

These are important evidence and may require investigation, but they must not automatically be described as compromise.

### Security controls enforcing

Examples include:

- CrowdSec blocking activity;
- Pi-hole blocking policy requests;
- successful block tests;
- healthy DNS enforcement;
- active IDS collection.

A block is evidence that the control operated. It is not evidence that the attempted activity succeeded.

### Assurance gaps

Examples include:

- missing monitoring evidence;
- unhealthy Prometheus targets;
- missing patch timestamps;
- incomplete backup verification;
- lack of automated test restores;
- incomplete end-to-end Loki/Alloy assurance.

These reduce confidence in what the monitoring system can prove. They are not themselves evidence of compromise.

## Current reporting state — 22 August 2026

The technical report's Network Security Situation currently distinguishes:

- **Confirmed Compromise** — no successful SSH sessions in the current security-review evidence and no identified confirmed malware/ransomware or successful exploitation event;
- **Security Activity Detected** — 12 Suricata alerts, 10 failed SSH attempts and 19 security/policy-related DNS blocks;
- **Security Controls Enforcing** — 25 CrowdSec blocking actions, Pi-hole enforcement health **HEALTHY — 2/2 nodes**, and Pi-hole block tests **10/10 passing**;
- **Assurance Gaps** — monitoring and backup/recovery assurance limitations remain visible.

The report therefore explains an AMBER posture as an assurance condition rather than evidence of a successful attack.

## Pi-hole reporting

Both Pi-hole nodes are represented in the enforcement-health evidence.

Current successful state:

```text
Pi-hole enforcement health: HEALTHY — 2/2 nodes
Pi-hole block tests: 10/10 passing
```

The two nodes are:

- `dietpi`
- `ids-01`

The Pi-hole block tests cover the configured security categories.

A healthy enforcement result means that the configured blocking controls are operating.

It does not mean that there were no attempted policy violations.

Conversely, a blocked DNS request does not establish that a user deliberately attempted to bypass policy.

## Current reporting problems identified on 22 August 2026

The reports were found capable of understating operational risk by treating the absence of compromise as too close to overall operational health.

Examples identified during the review:

- backup job results were reported as unavailable without becoming engineering actions;
- off-host replica health was `UNKNOWN` but was not promoted into the work queue;
- backup storage health was `UNKNOWN` but was not treated as degraded visibility;
- a failed Pi-hole blocklist collector existed while high-level reporting still described Pi-hole collection as available;
- a transient CrowdSec local API refusal was correctly identified as an engineering P2 and was subsequently verified as recovered;
- the Pi-hole blocklist collector on `ids-01` was writing to the wrong node-exporter textfile directory and has now been corrected;
- a non-applicable OpenIPMI service produced failed-unit noise and has now been disabled/masked on `ids-01`;
- after remediation, `ids-01` had zero failed systemd units.

## Reporting rules to implement

Future report-generation logic should follow these principles:

1. **UNKNOWN is not HEALTHY.** Missing or unavailable evidence must be represented explicitly.
2. **No compromise does not mean no operational problem.** Security posture and operational resilience must be assessed separately.
3. **Freshness matters.** A timer or service existing is not sufficient; collector output must be fresh and successfully exposed/scraped.
4. **Failed units must be classified.** Actionable failures should affect the report; intentionally masked or non-applicable services should not.
5. **Backup status must distinguish PASS / FAIL / UNKNOWN.** Unknown backup, replica, restore, or storage state should create an evidence limitation and normally at least a planned engineering action.
6. **Monitoring integrity is itself a control.** A failed collector can invalidate apparently healthy downstream results.
7. **Overall status should reflect the worst meaningful unresolved condition**, not solely compromise or vulnerability evidence.
8. **Evidence limitations must be visible.** Missing data must not silently disappear from priority/action sections.

## Recommended report dimensions

The management report should independently assess:

- Security posture
- DNS / policy enforcement
- Backup & recovery
- Infrastructure availability
- Monitoring integrity

The engineering runbook should classify findings as:

- **P1** — active outage, compromise, or critical protection/recovery failure
- **P2** — degraded resilience/control requiring investigation today
- **P3** — improvement, monitoring gap, evidence limitation, or recovery risk requiring planned work
- **HEALTHY** — positively verified control with sufficient current evidence

`HEALTHY` must require affirmative and sufficiently fresh evidence; it must not be inferred merely because no failure was observed.

## Useful inspection commands

### Management path

```bash
systemctl cat homelab-secops-management-report.service
systemctl cat homelab-secops-management-report.timer
sudo sed -n '1,320p' /usr/local/sbin/homelab-secops-management-report
sudo sed -n '1,320p' /usr/local/sbin/homelab-secops-report
sudo sed -n '1,360p' /usr/local/lib/homelab-secops-report/generate_management_report.py
```

### Engineering path

```bash
systemctl cat homelab-greenbone-ai-review.service
systemctl cat homelab-greenbone-ai-review.timer
systemctl cat homelab-greenbone-engineering-email.service
systemctl cat homelab-greenbone-engineering-email.timer
sudo sed -n '1,320p' /usr/local/sbin/homelab-greenbone-engineering-email
```

### Locate report readers/writers

```bash
sudo grep -Rni \
  '/var/lib/homelab-greenbone/reports/latest.md' \
  /usr/local/bin \
  /usr/local/sbin \
  /usr/local/lib \
  /etc/systemd/system \
  2>/dev/null
```

## Discovery script

A reusable discovery script is stored in the docs repository:

```text
scripts/find-daily-brief-generators.sh
```

Run on `ids-01` with:

```bash
cd ~/projects/home-lab-docs
git pull
sudo bash scripts/find-daily-brief-generators.sh
```

## Next engineering work

Before changing tomorrow's reports, inspect and document the classification logic in:

```text
/usr/local/lib/homelab-secops-report/generate_report.py
/usr/local/bin/homelab-security-reader.py
```

The objective is not simply to make the reports more pessimistic. The objective is to make them evidence-correct: verified healthy controls remain green, genuine failures become actions, and missing/stale evidence is represented explicitly rather than being interpreted as health.

## Management interpretation model

The management report must distinguish between detected security activity and evidence of a successful compromise.

Every material item should be interpreted using the following categories:

1. **Confirmed compromise**
   - Successful unauthorised access
   - Confirmed malware or ransomware
   - Successful exploitation
   - Confirmed data compromise
   - Another explicitly confirmed security breach

2. **Security incident / investigation**
   - Significant or unusual detected activity requiring investigation
   - Successful compromise has not been established

3. **Detected security activity**
   - Failed authentication attempts
   - IDS alerts
   - Blocked DNS requests
   - Other attempted or observed security activity

4. **Security controls enforcing**
   - CrowdSec blocking activity
   - Pi-hole security-policy enforcement
   - Other controls demonstrably preventing or blocking activity

5. **Assurance / evidence limitation**
   - Missing monitoring evidence
   - Missing patch-success timestamps
   - Lack of automated test-restore verification
   - Other limitations affecting what the environment can prove

6. **Routine operational maintenance**
   - Available container image updates
   - Normal patching activity
   - Other changes that are not independently evidence of a security vulnerability

### Interpretation rules

- A detected security event is **not automatically evidence of successful compromise**.
- Failed SSH attempts do not establish successful SSH access.
- Suricata alerts indicate detected network/security activity unless the underlying evidence establishes successful compromise.
- Blocked Pi-hole requests demonstrate policy enforcement; they do not establish deliberate user behaviour or successful access.
- CrowdSec blocking demonstrates active threat-prevention enforcement.
- WUD image-update availability is not, by itself, evidence of a vulnerability.
- Successful backup or replication is not proof that restoration has been tested.
- `ATTENTION` should not be described as a security incident unless the source evidence explicitly establishes one.
- The management report must preserve the authoritative technical report's overall posture and individual control states.

The purpose of this model is to prevent routine security telemetry and assurance gaps from being incorrectly presented to management as confirmed compromise.
