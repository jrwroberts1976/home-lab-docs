# Daily Homelab Actions — 23 August 2026

Operational engineering, recovery and compliance work completed during the daily homelab review.

## Daily review status

The scheduled 07:40 Daily Security & Recovery Brief initially reported **AMBER**. The 07:45 Engineering Security Runbook identified P2 findings including an Express application exposing error detail on `192.168.2.242:3002/tcp` and TCP timestamp disclosure.

Later controlled report-generation runs produced GREEN/no-active-priority outputs after evidence and classification work. These repeat messages were validation runs, not separate incidents.

No confirmed compromise, malware, ransomware, successful exploitation or data loss was evidenced.

## DietPi recovery documentation

**Status:** COMPLETE

The DietPi/Pi-hole recovery documentation set was completed and validated.

Captured recovery scope included:

- 14 operational scripts.
- The Pi-hole blocked-query alert application.
- 18 relevant systemd units.
- Five Pi-hole adlists.
- Unbound configuration overrides.
- DNS and blocking configuration required to rebuild the service.

The documentation change was committed as `a97a69c` and merged into `home-lab-docs/main` through PR #16 as merge commit `17a574ff`.

## DietPi non-destructive recovery rehearsal

**Status:** PASSED

A non-destructive recovery rehearsal rebuilt the captured recovery set into a temporary destination.

Validation results:

- 38 files reconstructed.
- 14 executable files restored with executable permissions.
- Reconstructed files matched the source hashes.
- Pi-hole configuration was present.
- Unbound configuration was present.
- Pi-hole and Unbound remained healthy; the live host was not replaced or disrupted.

The recovery runbook was merged through PR #17 as merge commit `f3da789d`.

## Container baseline and policy work

**Status:** STAGE 0 AND STAGE 1 COMPLETE

A container-policy baseline was established across the monitored estate.

Results:

- 61 containers inventoried.
- Zero unmanaged containers detected.
- Zero registry-image drift detected.
- Local-build checks, including the CrowdSec exporter, reported `revision-match`.
- Guarded adoption checks passed container health, HTTP and monitoring validation.

This established an evidence baseline for future container-version and ownership drift.

## K3s compliance extension

**Status:** COMPLETE

The container compliance model was extended to the k3s estate.

Validation covered 16 active instances and found:

- Zero floating images.
- Zero image drift.
- Zero unknown ownership.
- Zero unready containers.

Prometheus textfile export and central ingestion were verified operational.

## Security-report classification work

**Status:** VALIDATED THROUGH CONTROLLED RUNS

The daily management and engineering reports were reviewed to ensure missing or stale evidence could not silently appear healthy.

The review reinforced these operating rules:

- UNKNOWN must not be represented as HEALTHY.
- No evidence of compromise does not automatically mean there is no operational incident.
- Recovery and monitoring integrity must be assessed separately from compromise status.
- Failed, stale or missing collectors must be visible.
- Accepted risks must not be carried as active engineering incidents.
- Overall status must reflect the worst meaningful unresolved condition.

Multiple controlled daily-email runs were generated while verifying the revised classification behaviour.

## Closed / completed

- [x] DietPi recovery and DNS documentation captured.
- [x] DietPi recovery documentation merged through PR #16.
- [x] Non-destructive DietPi recovery rehearsal passed.
- [x] Recovery runbook merged through PR #17.
- [x] Container baseline completed for 61 containers.
- [x] Zero unmanaged-container and registry-drift baseline recorded.
- [x] K3s compliance evidence exported and centrally ingested.
- [x] Daily report classification validated through controlled test runs.

## Follow-up carried forward

- [ ] Continue remaining host recovery inventories and SCPs.
- [ ] Continue secrets-management migration and recovery testing.
- [ ] Continue monitoring alert-quality review where service health and evidence freshness can diverge.
