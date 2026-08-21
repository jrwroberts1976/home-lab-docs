# Grafana Alert Email Standard

## Purpose

All homelab Grafana email alerts should use one consistent notification format so alert messages are easy to scan and do not expose Grafana's noisy default payload.

The standard deliberately omits Grafana links.

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

## API note

The deployment currently uses Grafana's `/api/v1/provisioning/templates` and `/api/v1/provisioning/contact-points` endpoints because this matches the existing homelab automation. Grafana currently documents these routes as operational but deprecated in favour of the newer `/apis/...` App Platform APIs. A future Grafana upgrade should include a review of this deployment script.
