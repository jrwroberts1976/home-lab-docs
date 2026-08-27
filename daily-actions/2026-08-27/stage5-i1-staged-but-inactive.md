# Stage 5 I1 staged-but-inactive state

Date: 2026-08-27

Status: PROVEN

## Purpose

Record the first live host transition from inspection-only with no execution components installed to **I1: execution components staged but inactive**.

This state deliberately installs reviewed execution files on TestServer while preserving **effective deployment authority = false**.

No executor account, executor SSH trust, Jenkins executor credential, executor sudo authority, enable file, policy activation, container restart or deployment was performed.

## Merged source authority

`jrwroberts1976/homelab-container-version-control` merged source commit:

`a7fb8258b2d7a401e4bb494846b8a764e95aa0fc`

Reviewed installation hashes:

- deployment helper: `a0df7b46aa01ffc9ef3fbf43cea43caeef34681ef22b759ae822ed2832cfc42a`
- transition helper: `73eb78453b87e86760cb9fafd556e11c2a5c43c8df2b2d3e87fa0429902d64d1`
- executor forced-command wrapper: `2feea261deaccb92dccc1f9c982ed9f4360c6320ad84dba2d7b39e476582dc49`
- execution policy: `e8c629e34d16a02b2dc9a979dbe50da47dace810875bbc3296cead6285af2bc5`

## Files staged on TestServer

Installed root-owned files:

- `/usr/local/libexec/homelab-stage5-maintenance-page` — `root:root 0755`
- `/usr/local/libexec/homelab-stage5-maintenance-page-transition` — `root:root 0755`
- `/usr/local/sbin/homelab-stage5-executor-ssh` — `root:root 0755`
- `/etc/homelab-stage5/maintenance-page.execution-policy.json` — `root:root 0600`
- `/var/lib/homelab-stage5/maintenance-page` — `root:root 0700`

Installed bytes matched the exact reviewed hashes above.

## Activation boundary remains disabled

The active policy remained the exact inspection-only policy:

`adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`

It remained:

- `mode=inspection-ready`
- `inspection.allowed=true`
- `deployment.allowed=false`
- `deployment.performed=false`
- `deployment.deploy_command_enabled=false`
- `deployment.rollback_command_enabled=false`

The activation file remained absent:

`/etc/homelab-stage5/maintenance-page.enable`

The dedicated executor account remained absent:

`homelab-stage5-executor`

Executor sudo authority remained absent.

The existing inspection identity `homelab-stage5-pilot` retained only:

`NOPASSWD: /usr/local/libexec/homelab-stage5-maintenance-page-authority-gate inspect`

## Existing inspection path re-proved after staging

The installed Stage 5 inspection path still returned the expected pre-approval artifact:

- `mode=stage5-preapproval-inspect`
- `artifact=pilot-inspection`
- current exact rollback digest
- candidate exact pinned digest
- rollback exact pinned digest
- `approval.required=true`
- `approval.granted=false`
- `inspection.allowed=true`
- `inspection.performed=true`
- `deployment.allowed=false`
- `deployment.performed=false`
- `result=ready-for-human-review`

The inspection identity continued to reject:

- `arm maintenance-page`
- `deploy maintenance-page`
- `rollback maintenance-page`
- `disarm maintenance-page`
- `docker ps`
- `shell`

Therefore staging execution components did not widen the proven inspection identity.

## Runtime safety evidence

`maintenance-page` remained on the exact rollback digest:

`nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`

All container IDs and restart counts were unchanged before/after I1 staging.

No Stage 5 deployment was performed.

## Current state

**STAGE 5 I1 STAGED-BUT-INACTIVE STATE: PROVEN**

**EFFECTIVE DEPLOYMENT AUTHORITY: FALSE**

Next gate: create and prove the separate `homelab-stage5-executor` identity while leaving the enable file absent and without performing deployment.
