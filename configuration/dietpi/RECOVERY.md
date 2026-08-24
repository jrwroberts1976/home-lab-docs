# DietPi recovery validation

## Purpose

This runbook restores the Git-owned, non-secret operational state for the DietPi Pi-hole and Unbound host. It does not restore credentials, live Pi-hole databases, query history, TLS private keys, generated Prometheus metrics or Restic repository state.

## Authoritative source

The required source is stored in:

- `configuration/dietpi/`
- `scripts/dietpi/`
- `systemd/dietpi/`

Protected environment files and backup credentials must be recovered separately from the approved secret backup.

## Recovery order

1. Install the base operating system, Pi-hole, Unbound, node-exporter, Restic and required packages.
2. Restore protected credentials and environment files through the approved secret-recovery process.
3. Install scripts from `scripts/dietpi/` at the paths referenced by the systemd units.
4. Install units from `systemd/dietpi/` into `/etc/systemd/system/`.
5. Install the Unbound overrides from `configuration/dietpi/unbound/`.
6. Recreate the approved Pi-hole adlists using `configuration/dietpi/pihole/adlists.tsv`.
7. run shell, Python and `systemd-analyze verify` validation.
8. reload systemd, enable only the documented services and timers, then verify Pi-hole, Unbound and monitoring health.

## Required validation

Before enabling services:

- compare installed files with the Git source using SHA-256;
- verify executable modes and intended ownership;
- run `bash -n` for shell sources;
- compile Python sources without executing them;
- run privileged `systemd-analyze verify` against all restored units;
- confirm no plaintext secret or runtime database was reconstructed from Git.

After enabling services:

- confirm `pihole-FTL.service` and `unbound.service` are active;
- confirm `node_textfile_scrape_error 0`;
- confirm Pi-hole enforcement health is `1`;
- confirm all five active DNS blocking tests pass.

## Verified rehearsal

A non-destructive restore rehearsal completed on **24 August 2026** from Git revision `17a574ff25493fafbd057f65619364440495d0d8`.

The rehearsal:

- reconstructed 38 files beneath an isolated `/var/tmp` root;
- restored 14 executable operational sources;
- preserved hashes and expected file modes;
- passed shell and Python syntax validation;
- passed privileged systemd unit validation;
- passed the secret-exclusion gate;
- verified the generated SHA-256 manifest;
- confirmed Pi-hole FTL and Unbound remained active;
- made no changes to live files, services, databases or credentials.

The rehearsal evidence was retained locally under `/var/tmp/dietpi-restore-rehearsal-20260824-044159`. This path is operational evidence, not durable Git content.

## Remaining limitation

This proves source completeness and non-destructive reconstruction. A full clean-host recovery, including protected secret restoration and controlled service activation, remains a disaster-recovery exercise and must be performed in an isolated maintenance window.
