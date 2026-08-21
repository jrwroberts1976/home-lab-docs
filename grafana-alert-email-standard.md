# Grafana Alert Email Standard

## Purpose

All homelab Grafana email alerts should use one consistent notification format so alert messages are easy to scan and do not expose Grafana's noisy default payload.

The standard deliberately omits Grafana links.

## Runtime configuration

The active monitoring stack is defined at:

```text
/home/james/docker/stacks/monitoring/docker-compose.yml
```

Grafana SMTP is enabled through `GF_SMTP_*` environment settings in the Compose service. The SMTP password is injected from the monitoring stack environment and must not be copied into this repository.

Relevant runtime files/paths include:

```text
/home/james/docker/stacks/monitoring/docker-compose.yml
/home/james/docker/stacks/monitoring/.env
/etc/resolv.conf                         # ids-01 host DNS
/etc/resolv.conf inside grafana          # Docker-generated container DNS state
```

## Template group

```text
homelab-email
```

Reusable template names:

```text
homelab.email.subject
homelab.email.message
```

## Standard subject

Firing alerts:

```text
⚠️ [FIRING] <Alert Name> — <host or instance>
```

Resolved alerts:

```text
✅ [RESOLVED] <Alert Name> — <host or instance>
```

If `host` is not available, `instance` is used. If neither label exists, the alert name is used on its own.

## Standard body

The body renders only useful fields when they are present:

```text
⚠️ ALERT FIRING

<Alert Name>

Severity: <severity>
Category: <category>
Host: <host>
Instance: <instance>
Component: <component>

Summary
<summary annotation>

Description
<description annotation>
```

Resolved messages use the same structure with:

```text
✅ ALERT RESOLVED
```

This means individual alert rules should continue to provide good `summary` and `description` annotations. Alert-specific details such as MAC, IP, router, event, filesystem, service or threshold belong in the rule description rather than being hard-coded into the common email template.

## Example: blocked MAC

```text
⚠️ ALERT FIRING

Blocked MAC Detected

Severity: critical
Category: security
Instance: 192.168.2.242:9100
Component: network

Summary
Blocked MAC detected on the network

Description
A watched or blocked MAC address has appeared in the ASUS router log.

MAC: BE:BA:54:D7:EC:6F
Name: Unknown iPhone
IP: 192.168.2.159
Router: 192.168.2.1
Event: DHCPREQUEST
```

## Deployment script

Repository copy:

```text
scripts/deploy-grafana-email-standard.sh
```

Recommended runtime location:

```text
/home/james/scripts/deploy-grafana-email-standard.sh
```

The script:

1. creates or updates the `homelab-email` notification template group;
2. discovers all Grafana contact-point integrations with `type=email`;
3. preserves each contact point's existing address and other settings;
4. sets its subject to `{{ template "homelab.email.subject" . }}`;
5. sets its message to `{{ template "homelab.email.message" . }}`.

Required environment variable:

```text
GRAFANA_TOKEN
```

Optional environment variable:

```text
GRAFANA_URL
```

Default:

```text
http://localhost:3001
```

Run:

```bash
export GRAFANA_TOKEN='...'
/home/james/scripts/deploy-grafana-email-standard.sh
```

Secrets are not stored in this repository.

## Notification-path health

A firing Grafana alert does not prove email delivery is healthy. When alert emails stop, first distinguish rule evaluation from notifier delivery.

Useful log check:

```bash
docker logs --since 24h grafana 2>&1 \
  | grep -Ei 'smtp|email.*(sent|fail|error)|notification.*(fail|error)' \
  | tail -80
```

On 21 August 2026 Grafana was evaluating alerts and sending them to its local notifier, but delivery repeatedly failed with:

```text
failed to send email: dial tcp: lookup smtp.gmail.com on 127.0.0.11:53: server misbehaving
```

This affected multiple unrelated alert rules, proving the common notification path was broken rather than the individual rules.

## Docker DNS failure mode

Grafana normally uses Docker's embedded DNS resolver:

```text
nameserver 127.0.0.11
```

The failed Grafana container showed:

```text
NO EXTERNAL NAMESERVERS DEFINED
```

while the `ids-01` host itself had both Pi-hole resolvers configured:

```text
192.168.2.48
192.168.2.242
```

DNS resolution failed even when executed as root inside the Grafana container, ruling out a Grafana-user permission issue.

Check the container with:

```bash
docker exec grafana cat /etc/resolv.conf
docker exec grafana getent hosts smtp.gmail.com
```

If the host has working DNS but the existing container reports no external nameservers, recreate only Grafana from the monitoring stack:

```bash
cd /home/james/docker/stacks/monitoring
docker compose up -d --force-recreate grafana
```

After the 21 August 2026 recovery, the regenerated resolver reported:

```text
ExtServers: [host(192.168.2.48) host(192.168.2.242)]
```

and `smtp.gmail.com` resolved successfully. A Grafana contact-point test email was then received.

Do not change SMTP credentials or individual alert rules when the observed failure is DNS resolution. Recreate the stale container first when the host resolver is already correct. If the recreated container still has no usable upstream DNS, investigate Docker daemon/host DNS before adding service-specific DNS overrides.

## Post-change validation

After any monitoring-stack or DNS change:

```bash
docker exec grafana getent hosts smtp.gmail.com

docker logs --since 5m grafana 2>&1 \
  | grep -Ei 'smtp|email|notification.*(fail|error)|failed to send'
```

Then use:

```text
Grafana -> Alerting -> Contact points -> Homelab Email Alerts -> Test
```

and confirm the test message arrives.

## API note

The deployment currently uses Grafana's `/api/v1/provisioning/templates` and `/api/v1/provisioning/contact-points` endpoints because this matches the existing homelab automation. Grafana currently documents these routes as operational but deprecated in favour of the newer `/apis/...` App Platform APIs. A future Grafana upgrade should include a review of this deployment script.

## Related SOP

- [Log Ingestion and Grafana Alert Email Recovery](sop/log-ingestion-and-grafana-email-recovery.md)
