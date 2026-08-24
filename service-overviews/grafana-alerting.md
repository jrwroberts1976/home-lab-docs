# Grafana Alerting

## Purpose

Grafana on `ids-01` is the central alert-evaluation and email-notification service for the homelab.

## Runtime ownership

- Host: `ids-01`
- Container: `grafana`
- Image: `grafana/grafana:13.2.0`
- Compose stack: `/home/james/docker/stacks/monitoring`
- Default receiver: `Homelab Email Alerts`
- Git-managed rules: `jrwroberts1976/grafana-alerting`

## SMTP credential delivery

The Gmail application password is supplied through a Docker Compose secret using:

```text
GF_SMTP_PASSWORD__FILE=/run/secrets/grafana_smtp_password
```

The source secret remains outside Git under `/home/james/docker/secrets`. Its parent directory is mode `0700`; the file is mode `0444` so the non-root Grafana container can read the bind mount while other host users cannot traverse the protected directory.

## Validation completed

On 24 August 2026, direct Gmail authentication, Grafana secret loading, Grafana health and contact-point email delivery all passed. All 29 rules, including four K3s compliance rules, survived the scoped recreation. No direct password remained in active Compose, `.env` or runtime, and 303 retired plaintext Compose copies were removed.

## Recovery rule

Documentation may record the secret name, path and required permissions, but never its value. After changing the secret, recreate only Grafana and verify health, secret loading and contact-point delivery.
