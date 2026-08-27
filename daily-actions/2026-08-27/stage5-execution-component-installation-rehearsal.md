# Stage 5 execution component installation rehearsal

Date: 2026-08-27

## Result

PASS. A disposable installation tree was built from the exact merged `homelab-container-version-control` source at `a7fb8258b2d7a401e4bb494846b8a764e95aa0fc` without changing the live TestServer execution boundary.

## Rehearsed source hashes

- transition helper: `73eb78453b87e86760cb9fafd556e11c2a5c43c8df2b2d3e87fa0429902d64d1`
- executor wrapper: `2feea261deaccb92dccc1f9c982ed9f4360c6320ad84dba2d7b39e476582dc49`
- deployment helper: `a0df7b46aa01ffc9ef3fbf43cea43caeef34681ef22b759ae822ed2832cfc42a`
- execution policy: `e8c629e34d16a02b2dc9a979dbe50da47dace810875bbc3296cead6285af2bc5`
- current inspection policy: `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`

## Rehearsed ownership and modes

- deployment helper: `root:root 0755`
- transition helper: `root:root 0755`
- executor wrapper: `root:root 0755`
- staged execution policy: `root:root 0600`
- copied inspection policy: `root:root 0600`
- Stage 5 pilot state directory: `root:root 0700`

The rehearsed bytes matched all reviewed hashes exactly.

## Live-host safety evidence

After the rehearsal:

- `/usr/local/libexec/homelab-stage5-maintenance-page` remained absent;
- `/usr/local/libexec/homelab-stage5-maintenance-page-transition` remained absent;
- `/usr/local/sbin/homelab-stage5-executor-ssh` remained absent;
- `/etc/homelab-stage5/maintenance-page.execution-policy.json` remained absent;
- `/etc/homelab-stage5/maintenance-page.enable` remained absent;
- `homelab-stage5-executor` account remained absent;
- live inspection policy remained exact SHA256 `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`;
- all container IDs and restart counts remained unchanged;
- `maintenance-page` remained on rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`.

## Compatibility check before live staging

The merged authority gate was re-reviewed before live staging. Its inspection path requires the enable file to be absent but does not require the deployment helper itself to be absent. Therefore the reviewed execution files can be staged in the inactive I1 state without breaking the existing inspection-only path, provided the enable file, executor identity and execution sudo authority remain absent.

## Status

Ready to stage exact execution components on TestServer while preserving effective deployment authority as false.

No live execution authority was installed during this rehearsal.

No Stage 5 deployment was performed.
