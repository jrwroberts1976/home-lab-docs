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

These findings are independently non-reproducible but require Greenbone re-scan confirmation before final closure.

Current disposition: **`remediated_pending_scan`**.

### ICMP timestamps

Fresh ICMP Type 13 validation on 01 September showed:

- `.49` returned an ICMP Type 14 timestamp reply — genuine low-severity vendor-controlled behaviour;
- `.70` returned no Type 14 reply;
- `.120` returned no Type 14 reply.

Current disposition:

- `.49` — **`accepted_risk`**;
- `.70` — **`remediated_pending_scan`**;
- `.120` — **`remediated_pending_scan`**.

### TCP timestamps

`PROXMOX` and `debian-iac-test-01` both have `net.ipv4.tcp_timestamps = 1`. This is a reviewed low-severity information-disclosure observation. Disabling normal kernel TCP timestamp behaviour is not proportionate solely to make the report GREEN.

The `.49` camera finding is likewise a low-severity vendor-controlled observation.

Current disposition for `.49`, `.70`, and `.120`: **`accepted_risk`**.

## Persistent disposition register repaired

Before the change the live register contained:

```text
total=32
accepted_risk=30
remediated=1
remediated_pending_scan=1
```

A backup was taken first:

`/etc/homelab-greenbone/dispositions.json.bak-20260901-reviewed-findings`

Eight reviewed entries were then added using the exact host / port / OID identities from Greenbone.

After validation and installation:

```text
total=40
accepted_risk=34
remediated=1
remediated_pending_scan=5
```

The eight new records are:

| Host | Finding | Disposition |
| --- | --- | --- |
| `.49` | TCP timestamps | `accepted_risk` |
| `.49` | ICMP timestamp replies | `accepted_risk` |
| `.70` | TCP timestamps | `accepted_risk` |
| `.120` | TCP timestamps | `accepted_risk` |
| `.70` | SSH weak UMAC-64 finding | `remediated_pending_scan` |
| `.120` | SSH weak UMAC-64 finding | `remediated_pending_scan` |
| `.70` | ICMP timestamp replies | `remediated_pending_scan` |
| `.120` | ICMP timestamp replies | `remediated_pending_scan` |

The Greenbone SecOps evidence exporter was rerun successfully. Current exported finding status counts after reconciliation are:

```text
accepted_risk=24
remediated_pending_scan=4
```

This confirms the four accepted-risk instances are no longer actionable and only the four scanner-verification items remain pending.

## 31 August management-report failure explained

The stale SecOps evidence initially looked like a reporting refresh problem. Investigation showed yesterday's 08:30 management report failed during the Pi-hole evidence stage because `pihole-secondary` was not running.

`ids-01` had rebooted at approximately `07:52` on 31 August. The Pi-hole secondary container remained unavailable through the 08:30 report run, producing:

```text
Error response from daemon: container ... is not running
```

The old Pi-hole container did not successfully return until approximately 09:07 and was later replaced/reconciled by the current healthy `pihole-secondary` container.

Conclusion: this was a real post-reboot dependency-unavailable condition, not evidence that the SecOps reporting collector itself was broken. No reporting-code change was made merely to hide that failure.

## Greenbone verification scan in progress

The existing `Managed Linux verification` task does **not** cover `.70` or `.120`; it targets `.48`, `.195`, `.220`, and `.242`.

The existing `Weekly full LAN scan` targets `192.168.2.0/24`, so it does cover both `.70` and `.120` and is being used for controlled scanner verification.

Verification run started 01 September:

- task: `Weekly full LAN scan`;
- task ID: `1ecedb51-bbbb-41e0-ad28-8a75e4803d69`;
- report ID: `a789a027-2d58-4d36-a026-3795d4a0ca97`;
- last observed state: **Running**;
- last observed progress: **1%**.

The scan must specifically confirm absence of these four host/OID combinations:

- `.70` + `1.3.6.1.4.1.25623.1.0.105610` — SSH weak MAC;
- `.120` + `1.3.6.1.4.1.25623.1.0.105610` — SSH weak MAC;
- `.70` + `1.3.6.1.4.1.25623.1.0.103190` — ICMP timestamp reply;
- `.120` + `1.3.6.1.4.1.25623.1.0.103190` — ICMP timestamp reply.

If all four are absent from the completed verification report, promote the four corresponding disposition entries from `remediated_pending_scan` to **`remediated`**, retaining the verification task/report evidence.

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

## Next action

1. Allow report `a789a027-2d58-4d36-a026-3795d4a0ca97` to complete.
2. Check the four pending `.70` / `.120` host-OID pairs.
3. Promote verified-absent findings to `remediated` with report evidence.
4. Refresh `greenbone_findings.json`.
5. Regenerate the technical SecOps report.
6. Regenerate the Greenbone Engineering Security Runbook and management brief.
7. Confirm GREEN only when there are no genuine unresolved actionable findings or assurance failures.

Do not manually edit generated email/report output or suppress genuine findings merely to change the colour.
