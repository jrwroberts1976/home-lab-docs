# Stage 5 inspection-only host installation

Date: 27 August 2026

## Result

PASS — the Stage 5 maintenance-page inspection-only host authority is installed and proven locally on TestServer.

## Authoritative implementation

- `homelab-container-version-control` merge: `dfb773c81770fe12936d25558b427a279ebafd83`
- `docker-env` authority: `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`

## Installed inspection-only components

- authority gate: `/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate`
- inspector: `/usr/local/libexec/homelab-stage5-maintenance-page-inspect`
- inspection forced-command wrapper: `/usr/local/sbin/homelab-stage5-pilot-ssh`
- inspection policy: `/etc/homelab-stage5/maintenance-page.policy.json`
- exact detached/clean docker-env authority checkout: `/var/lib/homelab-stage5/authority/docker-env`
- dedicated locked service account: `homelab-stage5-pilot`
- inspect-only sudo rule: `/etc/sudoers.d/homelab-stage5-pilot-inspect`

## Reviewed installed identities

- authority gate SHA256: `561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda`
- inspector SHA256: `64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213`
- SSH wrapper SHA256: `85ad4a488325a07316cc17bc3b245f5f0b4136a920b126e25fb35c659ccdd6a6`
- inspection policy SHA256: `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`

## Proven inspection boundary

Local execution through the exact service-account sudo rule produced a real `pilot-inspection` artifact with:

- `approval.required=true`
- `approval.granted=false`
- `inspection.allowed=true`
- `inspection.performed=true`
- `deployment.allowed=false`
- `deployment.performed=false`
- `deploy_command_enabled=false`
- `rollback_command_enabled=false`
- result `ready-for-human-review`

The forced-command wrapper also passed `ping` and live `inspect maintenance-page` locally through the service account.

Negative tests proved the wrapper rejects:

- `deploy maintenance-page`
- `rollback maintenance-page`
- `inspect jenkins`
- `docker ps`
- arbitrary shell requests

Direct sudo tests proved `deploy` and `rollback` are denied for `homelab-stage5-pilot`.

## Deployment objects deliberately absent

- no `/usr/local/libexec/homelab-stage5-maintenance-page` deployment helper
- no `/etc/homelab-stage5/maintenance-page.enable`
- no deploy sudo authority
- no rollback sudo authority
- no SSH key / `authorized_keys`
- no remote Stage 5 login path
- no Jenkins Stage 5 credential
- no Jenkins deploy stage

The service account is locked and has no Docker-group membership.

## Live safety proof

- all container IDs/restart counts remained unchanged
- maintenance-page remained on rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`
- HTTP returned `200`
- content marker `Planned Maintenance | James Roberts` remained present
- no Stage 5 deployment was performed

## Next safe action

Inspect the existing Jenkins Stage 4 SSH credential-store implementation and credential APIs before introducing a Stage 5 key. Mirror the proven credential-store pattern rather than placing a persistent private key in the Jenkins filesystem. The next phase must not add deployment helper, enable file, or deploy/rollback sudo authority.
