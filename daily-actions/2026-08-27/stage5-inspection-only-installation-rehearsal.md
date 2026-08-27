# Stage 5 inspection-only installation rehearsal

Date: 2026-08-27

## Result

PASS — exact merged inspection-only source rehearsed. No host installation, credential, enable file, deployment helper, container change or deployment authority was introduced.

## Authoritative source

- implementation commit: `dfb773c81770fe12936d25558b427a279ebafd83`
- docker-env authority: `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`

## Reviewed merged hashes

- authority gate: `561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda`
- inspector: `64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213`
- inspection SSH wrapper: `85ad4a488325a07316cc17bc3b245f5f0b4136a920b126e25fb35c659ccdd6a6`
- final inspection-ready policy SHA256: `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`

## Inspection-only policy

The rehearsed policy remains `mode=inspection-ready` with:

- `inspection.allowed=true`
- `inspection.performed=false`
- `deployment.allowed=false`
- `deployment.performed=false`
- `deployment.deploy_command_enabled=false`
- `deployment.rollback_command_enabled=false`
- helper identity recorded as `NOT-INSTALLED-INSPECTION-PHASE`

The inspection installed-context path was proven not to reference the mutating inner helper. The execution installed-context path still requires the helper, enable file and helper hash.

## Proposed host boundary

Dedicated account: `homelab-stage5-pilot`

- password locked;
- not in Docker group;
- forced-command SSH only;
- source restricted to Jenkins fixed identity `172.30.255.250`;
- home and `authorized_keys` root controlled so the service account cannot replace its own SSH trust;
- intended forced command `/usr/local/sbin/homelab-stage5-pilot-ssh`.

Proposed sudo rule is inspection-only:

```text
homelab-stage5-pilot ALL=(root) NOPASSWD: /usr/local/libexec/homelab-stage5-maintenance-page-authority-gate inspect
```

No `deploy` or `rollback` sudo authority is present.

## Proposed inspection-only installed files

- `/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate`
- `/usr/local/libexec/homelab-stage5-maintenance-page-inspect`
- `/usr/local/sbin/homelab-stage5-pilot-ssh`
- `/etc/homelab-stage5/maintenance-page.policy.json`
- `/var/lib/homelab-stage5/authority/docker-env` at exact detached clean docker-env authority commit
- `/var/lib/homelab-stage5-pilot/.ssh/authorized_keys`
- `/etc/sudoers.d/homelab-stage5-pilot-inspect`

## Explicitly absent during inspection phase

- `/usr/local/libexec/homelab-stage5-maintenance-page` deployment helper;
- `/etc/homelab-stage5/maintenance-page.enable`;
- deploy sudo authority;
- rollback sudo authority;
- Jenkins deploy stage;
- Stage 5 deployment authority.

## Rehearsal evidence

- merged implementation authority matched exactly;
- reviewed hashes survived the merge;
- final inspection-ready policy remained deployment-disabled;
- inspection required no mutating helper;
- execution still requires helper + enable file;
- proposed root-controlled authorized-keys design passed;
- proposed inspect-only sudo rule parsed successfully with `visudo`;
- live `docker-compose.yml`, `nginx/default.conf` and `html/index.html` matched Git authority;
- no proposed install path existed before installation;
- running maintenance-page remained on the exact rollback digest;
- all container IDs/restart counts remained unchanged.

## Next gate

Perform the host-side inspection-only installation with the exact reviewed files and policy, while keeping the deployment helper and enable file absent. Jenkins credential creation and Jenkins inspection execution remain a later separately validated step. No deployment authority may be introduced during host installation.
