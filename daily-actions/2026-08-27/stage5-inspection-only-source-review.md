# Stage 5 inspection-only source review

Date: 27 August 2026

Status: COMPLETE — SOURCE REVIEWED AND MERGED; NOTHING INSTALLED

## Purpose

Provide a real live Stage 5 pre-approval inspection path for the `maintenance-page` pilot while keeping deployment authority disabled.

## Reviewed pull request

- repository: `jrwroberts1976/homelab-container-version-control`
- PR: `#30 Add Stage 5 inspection-only preapproval path`
- reviewed head: `9bbe780a1f0fafc025d1914475cd6dc7ffa6acdb`
- merged as: `ad3e85e2e6afe576d57dec186cefea58bddc8a20`
- base before merge: `6112d3dcf1f38dad88e71cd322672c7e58b4ba6a`

## Reviewed scope

Exactly five files changed:

- `config/stage5-maintenance-page-execution-policy.template.json`
- `ops/testserver/homelab-stage5-maintenance-page-authority-gate`
- `ops/testserver/homelab-stage5-maintenance-page-inspect`
- `ops/testserver/homelab-stage5-pilot-ssh-inspect`
- `scripts/validate-stage5-inspect-review.sh`

Stage 4 `Jenkinsfile` and Stage 4 forced-command wrapper were unchanged.

## Inspection policy boundary

The reviewed template uses:

```text
mode=inspection-ready
inspection.allowed=true
inspection.performed=false
deployment.allowed=false
deployment.performed=false
deploy_command_enabled=false
rollback_command_enabled=false
```

Inspection explicitly requires `/etc/homelab-stage5/maintenance-page.enable` to be absent.

The authority gate now has separate paths:

```text
inspect -> inspection policy checks -> read-only inspector

deploy|rollback -> execution policy checks -> inner helper
```

The inspect-only SSH wrapper allows only:

```text
ping
inspect maintenance-page
```

and explicitly rejects `deploy maintenance-page`, `rollback maintenance-page`, non-pilot inspection and arbitrary commands.

## Reviewed source hashes

```text
authority gate
6d7fe8cb319b6187f8c6a23fb08da6b5de82f382484fa734439260b385c3de6f

inspector
64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213

inner helper
a0df7b46aa01ffc9ef3fbf43cea43caeef34681ef22b759ae822ed2832cfc42a

inspect-only SSH wrapper
85ad4a488325a07316cc17bc3b245f5f0b4136a920b126e25fb35c659ccdd6a6
```

## TestServer validation result

Exact head `9bbe780a1f0fafc025d1914475cd6dc7ffa6acdb` was checked out and validated.

PASS:

- five-file inspection-only change scope;
- Stage 4 unchanged;
- inspection policy remains deployment-disabled;
- authority gate separates inspection and execution;
- inspector contains no mutation path;
- inspect-only SSH wrapper exposes privileged inspect only;
- deploy/rollback/arbitrary commands rejected;
- authority gate and inspector cannot execute from a source checkout;
- maintenance-page, Jenkins and Jenkins-DinD IDs/restart counts unchanged;
- running maintenance-page remains the rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`;
- HTTP returns `200` with expected `Planned Maintenance | James Roberts` marker.

## Explicitly not performed

```text
NO Stage 5 account created
NO SSH key installed
NO sudo rule created
NO Stage 5 file installed
NO authority checkout installed
NO Jenkins credential created
NO enable file created
NO container changed
NO Stage 5 deployment authority enabled
NO Stage 5 deployment performed
```

## Next gate

Build and review the exact post-merge **inspection-only installation manifest** from merge `ad3e85e2e6afe576d57dec186cefea58bddc8a20` before creating any account, SSH key, sudo rule, root-owned files, authority checkout or Jenkins credential. The installed policy must remain `inspection-ready`, deployment-disabled, and the enable file must remain absent.
