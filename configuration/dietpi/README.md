# DietPi operational state

This directory records the non-secret desired state for the DietPi Pi-hole and Unbound host.

## Managed content

- Pi-hole adlist declarations
- Unbound local overrides
- custom systemd services and timers
- Pi-hole monitoring and security exporters
- patch and vulnerability collectors
- Restic backup orchestration
- software-inventory metrics
- ICMP timestamp blocking

Runtime executables are stored under `scripts/dietpi/`. Custom systemd units are stored under `systemd/dietpi/`.

## Secret handling

The repository contains environment-file templates and approved SOPS-encrypted recovery sources. Plaintext live values and private age identities remain outside Git with restricted permissions.

See [DietPi encrypted secret sources](secrets/README.md) for the variable register, recipient model and controlled restoration requirements.

The following must never be committed:

- `/etc/pihole/pihole.toml`
- `/etc/pihole/gravity.db`
- `/etc/pihole/pihole-FTL.db`
- `/etc/pihole-block-alert/email.env`
- `/etc/restic/dietpi.env`
- `/home/homelab-backup/.restic-rest-env`
- Restic password files
- TLS private keys
- generated Prometheus textfiles
- Pi-hole query history, caches and backups

## Pi-hole adlists

`pihole/adlists.tsv` is a declarative inventory exported from Pi-hole's Gravity database. It is documentation and recovery input; it is not a copy of the live database.

## Deployment

Review source and configuration differences before installing anything. Install scripts and units with root ownership, preserve executable modes and run syntax and systemd validation before enabling or restarting services.

Environment files must be created separately with protected permissions.

See [DietPi recovery validation](RECOVERY.md) for the tested reconstruction order, validation gates and 24 August 2026 rehearsal evidence.
