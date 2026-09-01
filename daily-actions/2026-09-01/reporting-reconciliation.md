# 01 September 2026 — Security Reporting Reconciliation

## Purpose

Record the reporting-path investigation and Greenbone finding-disposition reconciliation completed on 01 September 2026 so reviewed findings are not reintroduced as new engineering work.

## Reporting host and live path

The daily security / management reporting pipeline runs on **`ids-01`**. Do not begin troubleshooting these report generators on TestServer.

Relevant live paths on `ids-01`:

- `/usr/local/lib/homelab-secops-report/generate_report.py` — authoritative technical SecOps report;
- `/usr/local/lib/homelab-secops-report/generate_management_report.py` — management transformation;
- `/usr/local/bin/homelab-security-reader.py` — engineering / Greenbone interpretation;
- `/usr/local/sbin/homelab-secops-greenbone-evidence` — Greenbone evidence exporter wrapper;
- `/usr/local/lib/homelab-secops-report/export_greenbone_findings.py` — structured Greenbone finding exporter;
- `/etc/homelab-greenbone/dispositions.json` — persistent finding-disposition register;
- `/var/lib/homelab-secops-report/state/greenbone_findings.json` — exported structured Greenbone evidence.

The exporter receives the disposition register as a read-only bind mount:

```text
/etc/homelab-greenbone/dispositions.json
        -> /work/dispositions.json
        -> export_greenbone_findings.py
        -> /var/lib/homelab-secops-report/state/greenbone_findings.json
```

Disposition matching is by host, optional port, and optional Greenbone OID. The management report must follow the technical/evidence disposition. Incorrect classification must be corrected in the evidence path rather than hidden in the management prompt.

## Morning AMBER investigation

The 01 September Greenbone Engineering Security Runbook presented three P2 investigation groups involving:

- `192.168.2.49` — `garage-door-camera.jameshouse`;
- `192.168.2.70` — `PROXMOX`;
- `192.168.2.120` — `debian-iac-test-01`.

The current exported evidence showed eight unresolved finding instances because none of those three hosts had matching entries in the persistent disposition register.

The relevant Greenbone identities are:

| Finding | Port | OID |
| --- | --- | --- |
| Weak MAC Algorithm(s) Supported (SSH) | `22/tcp` | `1.3.6.1.4.1.25623.1.0.105610` |
| TCP Timestamps Information Disclosure | `general/tcp` | `1.3.6.1.4.1.25623.1.0.80091` |
| ICMP Timestamp Reply Information Disclosure | `general/icmp` | `1.3.6.1.4.1.25623.1.0.103190` |

## Independent validation completed

### Weak SSH MAC — `.70` and `.120`

For both Linux hosts:

- `/etc/ssh/sshd_config.d/90-homelab-macs.conf` explicitly removes `umac-64-etm@openssh.com` and `umac-64@openssh.com`;
- effective SSH policy does not include either `umac-64` algorithm;
- live network `ssh2-enum-algos` validation on 01 September confirmed neither reported weak algorithm is advertised.

These findings were independently non-reproducible and were later confirmed absent by the completed full-LAN Greenbone verification scan.

Final disposition: **`remediated`**.

### ICMP timestamps

Fresh ICMP Type 13 validation on 01 September showed:

- `.49` returned an ICMP Type 14 timestamp reply — genuine low-severity vendor-controlled behaviour;
- `.70` returned no Type 14 reply;
- `.120` returned no Type 14 reply.

Final disposition:

- `.49` — **`accepted_risk`**;
- `.70` — **`remediated`**;
- `.120` — **`remediated`**.

### TCP timestamps

`PROXMOX` and `debian-iac-test-01` both have `net.ipv4.tcp_timestamps = 1`. This is a reviewed low-severity information-disclosure observation. Disabling normal kernel TCP timestamp behaviour is not proportionate solely to make the report GREEN.

The `.49` camera finding is likewise a low-severity vendor-controlled observation.

Final disposition for `.49`, `.70`, and `.120`: **`accepted_risk`**.

## Persistent disposition register repaired

Before the initial change the live register contained:

```text
total=32
accepted_risk=30
remediated=1
remediated_pending_scan=1
```

A backup was taken first:

`/etc/homelab-greenbone/dispositions.json.bak-20260901-reviewed-findings`

Eight reviewed entries were then added using the exact host / port / OID identities from Greenbone.

Additional validation later in the reconciliation covered:

- `192.168.2.183` (`James-LT`) — Windows DCE/RPC endpoint mapper and TCP timestamp findings reviewed as accepted low-risk / standard host behaviour;
- `192.168.2.195` (`k3s-node-01`) — ICMP timestamp finding independently remediated by the existing firewall rule and confirmed absent from report `a789a027-2d58-4d36-a026-3795d4a0ca97`.

The final disposition register state is:

```text
total=42
accepted_risk=36
remediated=6
remediated_pending_scan=0
false_positive=0
overdue_accepted_risk_reviews=0
```

The `.195` ICMP record was promoted from `remediated_pending_scan` to `remediated` with verification evidence dated 2026-09-01. Backup:

`/etc/homelab-greenbone/dispositions.json.bak-k3s-icmp-verified-20260901`

The disposition file remains `0644 root:root` because the Greenbone metrics/export containers consume it through a read-only bind mount while running as a non-root container user.

## 31 August management-report failure explained

The stale SecOps evidence initially looked like a reporting refresh problem. Investigation showed the 31 August 08:30 management report failed during the Pi-hole evidence stage because `pihole-secondary` was not running.

`ids-01` had rebooted at approximately `07:52` on 31 August. The Pi-hole secondary container remained unavailable through the 08:30 report run, producing:

```text
Error response from daemon: container ... is not running
```

The old Pi-hole container did not successfully return until approximately 09:07 and was later replaced/reconciled by the current healthy `pihole-secondary` container.

The same reboot exposed a broader Docker host-IP binding race on `ids-01`: Docker attempted to start containers before the dynamically configured Wi-Fi address `192.168.2.242` was present. `cadvisor` therefore failed to bind `192.168.2.242:8089`. It was recovered by reconnecting the existing container to the `monitoring` network; Prometheus subsequently reported the target healthy and the Security Monitoring domain returned to GOOD.

Permanent boot-order/address-readiness hardening remains a reliability follow-up; reporting collectors were not weakened to hide the real dependency failure.

## Greenbone verification completed

The `Weekly full LAN scan` covers `192.168.2.0/24` and was used as the controlled verification source.

Verification run:

- task: `Weekly full LAN scan`;
- task ID: `1ecedb51-bbbb-41e0-ad28-8a75e4803d69`;
- report ID: `a789a027-2d58-4d36-a026-3795d4a0ca97`;
- final state: **Done**.

The completed report confirmed absence of the four pending `.70` / `.120` host-OID combinations:

- `.70` + `1.3.6.1.4.1.25623.1.0.105610` — SSH weak MAC;
- `.120` + `1.3.6.1.4.1.25623.1.0.105610` — SSH weak MAC;
- `.70` + `1.3.6.1.4.1.25623.1.0.103190` — ICMP timestamp reply;
- `.120` + `1.3.6.1.4.1.25623.1.0.103190` — ICMP timestamp reply.

Those entries were promoted to **`remediated`**.

A direct GMP check also confirmed that `.195` was present in the report but had zero matches for OID `1.3.6.1.4.1.25623.1.0.103190`, allowing the final pending disposition to be promoted to **`remediated`**.

## Greenbone metric refresh

`homelab-greenbone-metrics.service` is the supported producer for:

`/var/lib/prometheus/node-exporter/homelab_greenbone.prom`

The service mounts the current disposition register read-only into `/work/dispositions.json`. The old AMBER state was partly caused by the metric file still containing the 07:01 pre-reconciliation snapshot.

After the final disposition reconciliation, the supported exporter was rerun at approximately 11:17. It completed successfully and emitted:

```text
homelab_greenbone_collector_success 1
weekly_full_lan actionable critical=0
weekly_full_lan actionable high=0
weekly_full_lan actionable medium=0
weekly_full_lan actionable low=0
weekly_full_lan remediation_pending critical=0
weekly_full_lan remediation_pending high=0
weekly_full_lan remediation_pending medium=0
weekly_full_lan remediation_pending low=0
```

Vulnerability Management then returned to **GOOD** without suppressing any genuine scanner finding.

## Patch-management reporting corrections

### Proxmox controlled manual patch policy

`PROXMOX` does not use `unattended-upgrades`; it is maintained under a controlled manual maintenance policy. The report previously interpreted the absence of unattended upgrades as a security failure even when the host had no outstanding updates.

The patch-report generator now supports documented manual-policy hosts through configuration. `PROXMOX` is recorded as a manual-policy host rather than a failed automatic-patching host.

Backup:

`/usr/local/lib/homelab-secops-report/generate_report.py.bak-proxmox-manual-policy-20260901`

### TestServer successful-patch evidence

`/home/james/collect-patch-status.sh` only recognised log text indicating packages had actually been upgraded. A healthy unattended-upgrades run reporting `No packages found that can be upgraded unattended` was therefore incorrectly exported as `last_success=0`.

The live collector was aligned with the canonical IaC behaviour so a successful no-op unattended-upgrade run records valid success evidence.

Backup:

`/home/james/collect-patch-status.sh.bak-last-success-20260901`

Patch Management subsequently returned to **GOOD** with no outstanding security updates and no managed host requiring reboot.

## Reporting status-policy corrections

### Threat Prevention

Successful authenticated SSH sessions were previously enough to force the Threat Prevention domain to `ATTENTION`. That conflated ordinary authenticated administration with a security exception.

The policy now retains successful SSH sessions as operational telemetry while status escalation remains driven by actual authentication security events or excessive failed SSH activity.

Backup:

`/usr/local/lib/homelab-secops-report/generate_report.py.bak-threat-status-policy-20260901`

### Container Security

WUD image-update availability was previously enough to force Container Security to `ATTENTION`, even though the same report correctly stated that a newer image version is not evidence of a vulnerability.

Container image updates remain fully visible for normal change-management assessment, but update availability alone no longer creates a security exception. Stopped/unhealthy container evidence remains actionable.

At final reconciliation there were two routine update candidates:

- `birdnet-go`: `20260716` -> `20260823` (major);
- `alloy`: `v1.18.0` -> `v1.19.2` (minor).

Backup:

`/usr/local/lib/homelab-secops-report/generate_report.py.bak-container-update-policy-20260901`

### Network security narrative

The legacy narrative treated any successful SSH session as requiring engineering review and even emitted an AMBER-specific message under otherwise healthy conditions. The prose was changed to follow the calculated report posture and explicitly state that successful authenticated SSH telemetry does not by itself indicate compromise.

Backup:

`/usr/local/lib/homelab-secops-report/generate_report.py.bak-network-green-narrative-20260901`

## Management-email source corrected

The management report generator now produces the authoritative report at:

`/var/lib/homelab-secops-report/management/latest.md`

The existing `/usr/local/sbin/homelab-greenbone-email` sender was still parsing the retired `/var/lib/homelab-greenbone/reports/latest.md` `Daily Management Brief` format.

The sender was updated to consume the authoritative SecOps management report and map its sections as follows:

- `## Executive Summary` -> main email body;
- `Overall Security Posture: GOOD / ATTENTION / ACTION REQUIRED` -> GREEN / AMBER / RED badge;
- `## Management Attention Required` -> management-action box;
- `## Management Conclusion` -> conclusion / stand-up box.

Backup:

`/usr/local/sbin/homelab-greenbone-email.bak-secops-management-source-20260901`

The parser dry run against the final report returned:

```text
source_status=GOOD
email_status=GREEN
executive_summary=PASS
management_attention=PASS
management_conclusion=PASS
```

## Final GREEN evidence

Final technical report generated on 01 September:

`/var/lib/homelab-secops-report/reports/secops-report-20260901-103149.md`

Final domain state:

| Security domain | Status |
| --- | --- |
| Vulnerability Management | GOOD |
| Intrusion Detection | GOOD |
| Threat Prevention | GOOD |
| Web & DNS Security | GOOD |
| Patch Management | GOOD |
| Container Security | GOOD |
| Backup & Recovery | GOOD |
| Security Monitoring | GOOD |
| Service Exposure | GOOD |

Final management report:

`/var/lib/homelab-secops-report/management/management-report-20260901-103210.md`

It states:

- overall security posture **GOOD**;
- no evidence of successful compromise;
- no current security matters requiring management action, engineering investigation, remediation, or assurance verification;
- two container updates remain routine normal change-management work rather than security findings.

The corrected management brief was sent through `homelab-greenbone-email.service` at approximately 11:40 BST. The service completed with `status=0/SUCCESS` and exported:

```text
homelab_greenbone_email_success 1
```

## Reporting rule

Before a Greenbone observation is emitted as `INVESTIGATE`, the reporting path must reconcile it against persistent disposition state.

Expected lifecycle states include:

1. active / unresolved;
2. remediated pending scanner verification;
3. remediated and scanner verified;
4. accepted risk with rationale and review date;
5. stale / non-reproducible evidence requiring review;
6. retired or no-longer-applicable asset.

A fresh scan must not silently discard an existing reviewed disposition. If current scanner evidence genuinely conflicts with the stored disposition, surface that conflict for revalidation rather than presenting an old finding as a new incident.

Do not manually edit generated email/report output or suppress genuine findings merely to change the colour.

## Follow-up

The security-reporting reconciliation is **closed GREEN**.

Remaining operational follow-up is outside the current security exception queue:

- assess the BirdNET-Go and Alloy image updates through normal change management;
- harden `ids-01` reboot ordering/address readiness so Docker containers with host-IP-specific binds do not race the dynamic `192.168.2.242` address.
