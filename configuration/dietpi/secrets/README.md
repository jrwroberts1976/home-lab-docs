# DietPi encrypted secret sources

This directory stores SOPS-encrypted recovery sources for approved DietPi credentials. It never stores plaintext credentials or private age identities.

## Recipient model

Every encrypted file is recoverable by two distinct age recipients:

- the DietPi operational identity at `/home/dietpi/.config/sops/age/keys.txt`;
- the protected recovery identity at `/mnt/backup/recovery/sops-age/recovery-identity.txt`.

Only public recipients appear in `.sops.yaml`. Private identities must never be committed, printed in logs or copied into ordinary reports.

The recovery identity on `/mnt/backup` is the protected online copy. A passphrase-encrypted detached copy and independent TestServer recovery rehearsal were validated on 25 August 2026.

## Encrypted-source and variable register

| Encrypted source | Variables | Live destination | Consumer | Required owner and mode |
| --- | --- | --- | --- | --- |
| `pihole-block-alert.sops.env` | `EMAIL_FROM`, `EMAIL_TO`, `SMTP_HOST`, `SMTP_PASSWORD`, `SMTP_PORT`, `SMTP_USERNAME` | `/etc/pihole-block-alert/email.env` | `pihole-block-alert.service` through `EnvironmentFile=` | `root:root`, `0600` |
| `restic-rest.sops.env` | `RESTIC_REST_PASSWORD`, `RESTIC_REST_USERNAME` | `/home/homelab-backup/.restic-rest-env` | `/home/homelab-backup/scripts/backup-dietpi.sh` | `homelab-backup:homelab-backup`, `0600` |
| `restic-repository.sops.env` | `RESTIC_PASSWORD` | `/home/homelab-backup/.restic-password` | Restic through `RESTIC_PASSWORD_FILE` | `homelab-backup:homelab-backup`, `0600` |

`SOFTWARE_METRIC_DIR` is non-secret configuration in `/etc/default/homelab-software-metrics` and is intentionally excluded from SOPS.

Pi-hole databases, `pihole.toml`, query history, generated state, TLS private keys and certificates remain backup-managed artifacts rather than SOPS environment declarations.

## Controlled restoration

Before writing any live file:

1. Confirm the host is `DietPi` and Git is on the approved revision.
2. Validate the encrypted source and create a root-only temporary directory, preferably under `/dev/shm`.
3. Decrypt with either approved identity without displaying the output.
4. Validate the expected variable names and declaration count.
5. Back up any existing live destination.
6. Install using the documented owner and mode.
7. Validate the consumer before any restart.
8. Remove all plaintext temporary material.

For `restic-repository.sops.env`, write only the value of `RESTIC_PASSWORD` to `.restic-password`; never install the `RESTIC_PASSWORD=` prefix.

A decryption rehearsal must not restart a service or replace a live credential. Runtime restoration requires its own change window, rollback point and health validation.

## Rotation

Rotate the authoritative credential first, validate its consumer, rebuild the encrypted source in protected temporary storage, encrypt for both recipients, test both identities and commit only the encrypted result.
