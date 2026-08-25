# Daily Homelab Actions — 24 August 2026

Operational security, monitoring and secrets-management work completed during the daily homelab review.

## Daily review status

The scheduled Daily Security & Recovery Brief reported **GREEN** with no confirmed compromise, malware, ransomware, successful exploitation or data loss.

The backup and recovery section reported:

- 4/4 systems backed up successfully.
- 4/4 integrity checks passed.
- 4/4 restore validations passed.
- Backup storage healthy.
- Off-host recovery copy healthy at report time.

The Engineering Security Runbook reported no immediate engineering action and no P1 items. Accepted risks remained recorded separately from active incidents.

## Grafana SMTP secret migration

**Status:** PILOT COMPLETE AND VALIDATED

Grafana SMTP authentication on `ids-01` was migrated to Compose-secret delivery using the supported `_FILE` mechanism.

Validation confirmed:

- Grafana started and remained healthy.
- SMTP authentication succeeded.
- The Grafana email contact point delivered a test message.
- All 29 alert rules remained present after the migration.
- The direct SMTP password was removed from the active configuration.
- 303 retired plaintext backup copies containing the previous secret material were removed.

This demonstrated the secret-delivery pattern without changing the Grafana alert-rule inventory.

## K3s Grafana alert rules

**Status:** DEPLOYED AND HEALTHY

Four Git-managed Grafana rules for k3s monitoring were deployed.

After correcting the rules to use instant-query evaluation:

- All four rules were `inactive`.
- All four rules reported health `ok`.
- No false active k3s condition remained.

## Alert and monitoring activity

Grafana notification and rule behaviour was exercised during monitoring changes. Alert emails included firing and resolved transitions for:

- Linux host availability.
- Backup replica health.
- Pi-hole block-enforcement health.
- Pi-hole configuration synchronisation.
- Network-device discovery.
- Hardware health on `k3s-node-01`.
- High CPU usage on `ids-01`.
- CrowdSec availability.

A dedicated `TestAlert` notification confirmed the contact-point path.

Several alerts resolved automatically after the underlying metric recovered. Backup-replica and CrowdSec conditions later required the deeper remediation recorded in the 25 August daily action document.

## Network and service observations

Monitoring evidence captured transient host/network instability during the evening. Later CrowdSec logs showed successful startup phases including:

- Console enrolment.
- Central API synchronisation.
- PAPI decision receiver startup.
- Local API startup.
- Firewall-bouncer decision streaming.

The subsequent CrowdSec failure caused by mandatory Loki acquisition at an obsolete endpoint was diagnosed and fixed on 25 August.

## Documentation and reporting

The daily operations brief and engineering runbook were generated successfully using the UTC-based evidence window. Timestamp handling was reviewed and confirmed correct for the daily pipeline.

The backup section at this point still described missing, failed or older-than-48-hour evidence generically. On 25 August this wording and the underlying replica-health threshold were corrected to distinguish daily local backups from intentional weekly off-host replication.

## Secrets-management follow-up

The Grafana SMTP pilot completed successfully, but the broader secrets programme remained open.

Carried-forward items:

- [ ] Migrate remaining service secrets to supported secret-file delivery.
- [x] Complete SOPS/age recovery procedures — completed and independently rehearsed on 25 August 2026.
- [ ] Review Jenkins secret handling.
- [ ] Test secret recovery and rebuild procedures.
- [ ] Preserve change-control and rollback evidence for each migration.

## Closed / completed

- [x] Grafana SMTP Compose-secret pilot completed.
- [x] SMTP authentication and contact-point delivery validated.
- [x] Grafana retained all 29 alert rules.
- [x] Active direct SMTP password removed.
- [x] 303 retired plaintext secret copies removed.
- [x] Four Git-managed k3s Grafana rules deployed.
- [x] K3s rule query mode corrected.
- [x] All four k3s rules verified inactive and healthy.
- [x] Daily pipeline timestamp handling confirmed.
- [x] Alert notification path proven.

## Follow-up carried into 25 August

- [x] Correct backup-replica freshness logic for the weekly replication schedule.
- [x] Restore TestServer CrowdSec and correct its Loki acquisition endpoints.
- [x] Update the daily email with explicit backup and CrowdSec health semantics.
- [x] Confirm no additional unresolved Grafana alerts remained.
