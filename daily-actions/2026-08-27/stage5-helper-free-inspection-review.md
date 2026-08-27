# Stage 5 Helper-Free Inspection Review — 27 August 2026

## Status

**COMPLETE — REVIEWED SOURCE MERGED, NO HOST INSTALLATION**

## Purpose

Harden the Stage 5 `maintenance-page` pre-approval inspection phase so TestServer does not need the mutating deployment helper installed merely to produce live inspection evidence.

## Review authority

Repository: `jrwroberts1976/homelab-container-version-control`

PR: `#31` — `Keep Stage 5 deploy helper off inspection-only hosts`

Reviewed head:

```text
0247d5e4fe04aebef9f55880aa316a444f6286ea
```

Merged as:

```text
dfb773c81770fe12936d25558b427a279ebafd83
```

## Reviewed change scope

Only two files changed from merged PR #30 authority:

```text
ops/testserver/homelab-stage5-maintenance-page-authority-gate
scripts/validate-stage5-inspect-review.sh
```

Stage 4 remained unchanged.

## Accepted inspection boundary

The inspection installed context now requires:

```text
root execution through the installed authority gate
root-owned/non-writable authority gate
root-owned/non-writable inspector
root-owned/non-writable inspection policy
root-owned clean docker-env authority checkout
exact gate + inspector hashes
enable file ABSENT
inspection-ready policy
deployment flags all false
```

It explicitly does **not** require the mutating inner deployment helper.

The separate execution installed context still requires:

```text
root-owned/non-writable inner helper
root-owned/non-writable enable file
policy-pinned helper SHA256
execution-enabled policy
```

## Reviewed source hashes

```text
authority gate
561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda

inspector
64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213

inspection-only SSH wrapper
85ad4a488325a07316cc17bc3b245f5f0b4136a920b126e25fb35c659ccdd6a6
```

## TestServer validation result

PASS:

- exact PR #31 head reproduced;
- two-file scope confirmed;
- inspection context contains no `INNER_HELPER` requirement;
- execution context still requires helper + enable file + helper hash;
- automated inspection-only source validator passed;
- no Stage 5 host installation existed;
- all container IDs and restart counts remained unchanged;
- `maintenance-page` remained on rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`;
- HTTP returned `200` with expected maintenance marker.

## Safety state after merge

```text
Stage 5 inspection-only source = MERGED
Stage 5 mutating helper on TestServer = ABSENT
Stage 5 account = ABSENT
Stage 5 SSH key = ABSENT
Stage 5 sudo rule = ABSENT
Stage 5 policy = NOT INSTALLED
Stage 5 authority checkout = NOT INSTALLED
Stage 5 Jenkins credential = ABSENT
Stage 5 enable file = ABSENT
Stage 5 deployment authority = NOT ENABLED
Stage 5 deployment performed = NO
```

## Next gate

Perform a post-merge **inspection-only installation rehearsal** against merge `dfb773c81770fe12936d25558b427a279ebafd83`.

The rehearsal must calculate the exact merged gate/inspector/SSH-wrapper hashes, build the final `inspection-ready` policy with deployment flags false, define root ownership/modes, root-owned authorized-key handling, exact inspect-only sudo target and pinned docker-env authority checkout, while creating none of those objects.
