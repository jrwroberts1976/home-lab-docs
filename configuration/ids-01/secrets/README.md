# ids-01 encrypted secret sources

These files are SOPS-encrypted recovery sources. Live services continue using protected host files or existing runtime delivery.

| Encrypted source | Variables or content | Consumer | Current delivery |
|---|---|---|---|
| `grafana-smtp.sops.env` | `GF_SMTP_PASSWORD` | Grafana | file-backed Compose secret |
| `grafana-api.sops.env` | `GRAFANA_TOKEN` | Grafana deployment scripts | protected host token file; four consumers default to `GRAFANA_TOKEN_FILE` |
| `pihole-secondary.sops.env` | `PIHOLE_PASSWORD` | Secondary Pi-hole | file-backed Compose secret using a validated entrypoint wrapper |
| `nebula-sync.sops.env` | `NEBULA_PRIMARY`, `NEBULA_REPLICAS` | Nebula Sync | two file-backed Compose secrets |
| `openai.sops.env` | `OPENAI_API_KEY` | Security management reporting | protected systemd environment file |
| `pihole-alert.sops.env` | `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `EMAIL_FROM`, `EMAIL_TO`, `IGNORED_CLIENTS` | Pi-hole alert service | protected systemd environment file |
| `greenbone-gmp.sops.env` | `GMP_PASSWORD` | Greenbone automation | protected environment file |
| `greenbone-smtp.sops.env` | `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_TO` | Greenbone email | protected environment file |
| `restic-backup.sops.env` | `RESTIC_PASSWORD` | ids-01 backup | protected password file |
| `restic-server.sops.env` | base64-encoded Rest Server `.htpasswd` | Rest Server | protected `PASSWORD_FILE` |

The Pi-hole alert and Greenbone SMTP passwords currently match but remain separately documented because they have distinct consumers and recovery files.

The existing `grafana-api-token` host file is invalid and must be replaced with the validated token before the monitoring `.env` copy is retired.

Never commit decrypted output or an age private identity.
A passphrase-encrypted detached recovery-identity copy and independent TestServer rehearsal were validated on 25 August 2026.

## ids-01 credential-delivery closure

- The Grafana API token is delivered through `/home/james/docker/secrets/grafana-api-token`; four consumers default to that protected file.
- The previous monitoring `.env` token declaration and two obsolete plaintext backups were removed.
- The secondary Pi-hole password is delivered through a read-only Compose secret and an entrypoint wrapper.
- Both protected values retain independently validated SOPS recovery sources.
