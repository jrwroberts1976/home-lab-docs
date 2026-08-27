# Stage 5 Authority Installation Rehearsal

**Date:** 27 August 2026  
**Status:** COMPLETE — REHEARSAL ONLY, NO AUTHORITY INSTALLED

## Purpose

Record the exact reviewed installation identities and prove that the Stage 5 `maintenance-page` authority package can be prepared while remaining fail-closed and uninstalled.

## Reviewed implementation authority

```text
homelab-container-version-control
6112d3dcf1f38dad88e71cd322672c7e58b4ba6a
```

## Exact source hashes

```text
authority gate
9868b006b9c9f03fad15e31640a698bee7eed48450bef882f05724dd2302b124

inner helper
a0df7b46aa01ffc9ef3fbf43cea43caeef34681ef22b759ae822ed2832cfc42a

review-only SSH wrapper
3c73412eef16d2577a68f56520b0c474c7c0753d9ca01f80db2be66b18100d03
```

## Proposed disabled policy

The rehearsal filled the implementation placeholders with the exact reviewed hashes while retaining:

```text
mode=execution-template-disabled
deployment.allowed=false
deployment.performed=false
deploy_command_enabled=false
rollback_command_enabled=false
```

Proposed disabled policy SHA256:

```text
bdfeedc3f77bc897cba90690910a610650a883e773586dc91f6f2b4e6e8e3691
```

## Git and live configuration identity

`docker-env` authority:

```text
f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883
```

Live and authoritative hashes matched exactly:

```text
docker-compose.yml
26fb63ff74360932f0dbf9eb27876c67bb3212767aaa6a11ea6c3370750eeadf

nginx/default.conf
5f776d04e520489a0958d2f267dcf034448a3c385b88f142ae7aa67d53a34d13

html/index.html
9497b740f24af80568843efdf500544a25b47f4dd3fe248161c31c4cd202eb29
```

Both immutable images were local as Linux/ARM64:

```text
rollback
nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752

candidate
nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913
```

The live `maintenance-page` container still ran the exact rollback digest.

## Proposed installed manifest

```text
/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate
  root:root 0755

/usr/local/libexec/homelab-stage5-maintenance-page
  root:root 0755

/etc/homelab-stage5/maintenance-page.policy.json
  root:root 0600

/var/lib/homelab-stage5/maintenance-page/
  root:root 0700

/var/lib/homelab-stage5/authority/docker-env
  root-controlled detached clean checkout
  exact commit f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883
```

The following remained explicitly absent:

```text
/etc/homelab-stage5/maintenance-page.enable
Stage 5 sudo rule
Stage 5 Jenkins credential
Stage 5 execution SSH wrapper
Jenkins deploy/rollback pipeline stages
```

## Account boundary reviewed

```text
account: homelab-stage5-pilot
password: locked
interactive password login: disabled
Docker group: NO
unrestricted sudo: NO
SSH source: 172.30.255.250 only
PTY: disabled
X11 forwarding: disabled
TCP forwarding: disabled
agent forwarding: disabled
arbitrary shell: disabled
eventual sudo target: authority gate only
inner helper direct sudo: forbidden
```

## Result

```text
PASS: exact merged gate/helper hashes calculated
PASS: proposed installed policy remained disabled
PASS: live configuration equalled merged Git authority
PASS: candidate and rollback images were local ARM64
PASS: maintenance-page still ran rollback identity
PASS: install paths/account remained absent
PASS: review-only SSH wrapper still blocked deploy/rollback

NO ACCOUNT CREATED
NO SSH KEY CREATED
NO SUDO RULE CREATED
NO FILE INSTALLED
NO ENABLE FILE CREATED
NO AUTHORITY CHECKOUT INSTALLED
NO JENKINS CREDENTIAL CREATED
NO CONTAINER CHANGED
NO STAGE 5 DEPLOYMENT AUTHORITY ENABLED
NO STAGE 5 DEPLOYMENT PERFORMED
```

## Follow-up design finding

The rehearsal confirmed that the merged SSH wrapper was still review-only and that the merged authority gate accepted only mutating actions. A real pre-approval Stage 5 inspection therefore required a separate read-only inspection path that could operate while deployment remained disabled.

That follow-up work is isolated in implementation draft PR #30 (`stage5/maintenance-page-inspect-approval-review`). Its design goal is to allow a real `inspect maintenance-page` artifact with no enable file and no deploy-capable sudo path. Deployment remains a later, separately reviewed phase.
