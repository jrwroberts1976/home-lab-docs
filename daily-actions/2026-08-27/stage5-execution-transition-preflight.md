# Stage 5 execution-transition preflight

Date: 2026-08-27

## Status

**PASS — inspection-only state is internally consistent and ready for execution-transition design/review.**

The preflight was read-only. No deployment capability was enabled and no container was changed.

## Installed inspection boundary

The installed TestServer Stage 5 inspection components remain exact:

- policy: `/etc/homelab-stage5/maintenance-page.policy.json`, `root:root`, mode `0600`, SHA256 `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`
- authority gate: `/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate`, `root:root`, mode `0755`, SHA256 `561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda`
- inspector: `/usr/local/libexec/homelab-stage5-maintenance-page-inspect`, `root:root`, mode `0755`, SHA256 `64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213`
- forced SSH wrapper: `/usr/local/sbin/homelab-stage5-pilot-ssh`, `root:root`, mode `0755`, SHA256 `85ad4a488325a07316cc17bc3b245f5f0b4136a920b126e25fb35c659ccdd6a6`

The policy remains `mode=inspection-ready` with:

- `inspection.allowed=true`
- `inspection.performed=false`
- `deployment.allowed=false`
- `deployment.performed=false`
- `deploy_command_enabled=false`
- `rollback_command_enabled=false`

## Deployment authority still absent

Verified absent:

- `/usr/local/libexec/homelab-stage5-maintenance-page`
- `/etc/homelab-stage5/maintenance-page.enable`
- deploy sudo authority
- rollback sudo authority
- execution-enabled policy
- Jenkins deployment stage

The service account retains only the exact inspection sudo handoff:

`/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate inspect`

## SSH trust

The final trust model remains:

- `.ssh`: `root:homelab-stage5-pilot`, mode `0750`
- `authorized_keys`: `root:homelab-stage5-pilot`, mode `0640`
- account cannot modify either path
- key remains source-restricted to Jenkins validation identity `172.30.255.250`

## Git and live configuration authority

The root-owned Stage 5 docker-env authority checkout remains clean and pinned to:

`f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`

Authority and live maintenance-page files match exactly:

- Compose SHA256 `26fb63ff74360932f0dbf9eb27876c67bb3212767aaa6a11ea6c3370750eeadf`
- nginx config SHA256 `5f776d04e520489a0958d2f267dcf034448a3c385b88f142ae7aa67d53a34d13`
- index HTML SHA256 `9497b740f24af80568843efdf500544a25b47f4dd3fe248161c31c4cd202eb29`

## Runtime and image identities

maintenance-page remains unchanged on the exact rollback:

- container ID `163fcb4872f1795fe7c85d5025a5205888fa345fbb8be0fc493d4f5191f3eb1f`
- restart count `0`
- image ID `sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483`
- rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`

Both immutable images are local Linux/ARM64:

- rollback image ID `sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483`
- candidate digest `nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913`
- candidate image ID `sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5`

HTTP health remains `200` with marker `Planned Maintenance | James Roberts`.

Protected Jenkins state remained:

- Jenkins container `f451fb005c7f3e0b23ee15dd39dc89cdea042fe178d5a212a643e432100a893d`, restart `0`
- Jenkins-Docker container `6055f8a7d365779548a9dc6acd8babbb6856baf690e3ea193554d417d31d5548`, restart `1`

## Execution-transition sequencing finding

Review of merged implementation `dfb773c81770fe12936d25558b427a279ebafd83` confirmed a deliberate phase boundary:

- gate `inspect` requires `mode=inspection-ready` and the enable file to be absent;
- inspector also independently requires inspection-ready mode and no enable file;
- gate `deploy|rollback` requires `mode=execution-enabled`, an installed helper and a root-controlled enable file matching the pilot ID.

Therefore the transition cannot safely be implemented by merely widening the current inspection sudo rule. There must be an explicit reviewed **arm/transition step** between the successful Jenkins inspection/human approval and the deployment command.

The existing helper already provides useful execution controls: exact installed path, root ownership, policy/helper hash pinning, immutable candidate/rollback identities, local Linux/ARM64 checks, one-shot pilot consumption, exact Compose service scoping, `--no-deps --no-build --pull never --force-recreate`, health verification, and protected Jenkins/DinD/unrelated-container checks. Rollback requires that the pilot has been consumed and that the candidate digest is currently running.

## Required design work before execution

The next review must define, source-review and validate the smallest mechanism for:

1. Jenkins pre-approval inspection using the already-proven inspection credential.
2. Jenkins human `input` approval bound to the exact pilot/candidate/rollback identities.
3. A narrow, fail-closed arm transition from inspection-ready to execution-enabled.
4. A deployment identity/wrapper that cannot expose arbitrary shell, Docker or Compose arguments.
5. Exact deploy and rollback sudo handoffs only through the authority gate.
6. Post-deploy health and protected-state validation.
7. Rollback while the one-shot pilot remains armed if post-deploy validation fails.
8. Removal/disabling of execution authority after success or rollback.

No execution components should be installed until this transition has been reviewed and validated source-only.

## Result

`READY FOR EXECUTION-TRANSITION DESIGN/REVIEW`

`NOT EXECUTION-READY`

`NO STAGE 5 DEPLOYMENT PERFORMED`
