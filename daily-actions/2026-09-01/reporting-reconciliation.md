# 01 September 2026 — Security Reporting Reconciliation

## Purpose

Record the reporting-path location and the finding-disposition issue identified on 01 September so previously remediated or accepted Greenbone findings are not accidentally reintroduced as active engineering work.

## Reporting host

The daily security / management reporting pipeline runs on **`ids-01`**. Do not begin troubleshooting the report generators on TestServer.

Relevant live paths documented for `ids-01` include:

- `/usr/local/lib/homelab-secops-report/generate_report.py` — technical SecOps / management source of truth;
- `/usr/local/lib/homelab-secops-report/generate_management_report.py` — management transformation;
- `/usr/local/bin/homelab-security-reader.py` — engineering / Greenbone interpretation path;
- `/usr/local/lib/homelab-greenbone/ai_review.py` — Greenbone AI review implementation where present.

The management report must follow the technical report's disposition. Incorrect classification should be corrected in the technical/evidence path rather than hidden in the management prompt.

## 01 September stale-disposition incident

The morning Engineering Security Runbook presented three P2 investigations involving `192.168.2.49`, `192.168.2.70`, and `192.168.2.120`. Review showed that several findings had already been remediated or dispositioned previously, but that state had not been reconciled into the new report.

Asset identification confirmed:

- `192.168.2.49` — `garage-door-camera.jameshouse`, embedded/vendor-controlled camera;
- `192.168.2.70` — `PROXMOX`, Debian 13;
- `192.168.2.120` — `debian-iac-test-01`, Debian 13.

### Weak SSH MAC finding

For both `192.168.2.70` and `192.168.2.120`:

- `/etc/ssh/sshd_config.d/90-homelab-macs.conf` explicitly removes `umac-64-etm@openssh.com` and `umac-64@openssh.com`;
- effective `sshd -T` output does not include either `umac-64` algorithm;
- live `nmap --script ssh2-enum-algos` enumeration on 01 September confirmed neither algorithm is advertised.

Disposition: **remediated / not reproducible**. Do not return this finding to the active engineering queue solely because an older Greenbone result still exists.

### ICMP timestamp finding

Fresh Type 13 probes on 01 September showed:

- `192.168.2.49` replies with ICMP Type 14 timestamp responses;
- `192.168.2.70` did not return a Type 14 reply during the validation;
- `192.168.2.120` did not return a Type 14 reply during the validation.

The camera behaviour is an embedded/vendor-controlled low-severity finding and should remain under its reviewed disposition rather than being treated as a newly discovered incident unless the accepted-risk state changes.

### TCP timestamps

`PROXMOX` and `debian-iac-test-01` both have `net.ipv4.tcp_timestamps = 1`. TCP timestamp exposure is a low-severity information-disclosure observation and must retain its reviewed risk disposition. Do not disable TCP timestamps merely to make the management report green.

## Reporting rule

Before a Greenbone observation is emitted as `INVESTIGATE`, the reporting path must reconcile it against the persistent disposition state:

1. active/unresolved finding;
2. remediated and independently revalidated;
3. accepted risk with rationale/review date;
4. not reproducible / stale scanner evidence;
5. retired or no-longer-applicable asset.

A fresh scan result must not silently overwrite an existing accepted/remediated disposition. If the evidence genuinely conflicts with the disposition, report the conflict for revalidation rather than presenting the old finding as new.

## Next action

On `ids-01`, inspect the live Greenbone / SecOps report-generation chain and identify where accepted-risk and remediation state should be persisted and reconciled before the engineering queue and management posture are generated.

After correcting the source-of-truth logic:

- regenerate the technical report;
- regenerate the Engineering Security Runbook;
- regenerate the management brief;
- require GREEN only when there are no genuine unresolved actionable findings or assurance failures.

Do not manually edit a generated email or suppress genuine findings simply to change the colour.
