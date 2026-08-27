# Stage 5 executor sudoers rehearsal

Date: 2026-08-27

## Result

The executor sudo surface was rehearsed from a temporary file only. No live sudoers rule was installed and effective deployment authority remained false.

Proposed exact commands:

```text
homelab-stage5-executor ALL=(root) NOPASSWD: /usr/local/libexec/homelab-stage5-maintenance-page-transition arm
homelab-stage5-executor ALL=(root) NOPASSWD: /usr/local/libexec/homelab-stage5-maintenance-page-authority-gate deploy
homelab-stage5-executor ALL=(root) NOPASSWD: /usr/local/libexec/homelab-stage5-maintenance-page-authority-gate rollback
homelab-stage5-executor ALL=(root) NOPASSWD: /usr/local/libexec/homelab-stage5-maintenance-page-transition disarm
```

`visudo -cf` parsed the proposed file successfully. The rule count was exactly four. No wildcard, general shell, Docker or Compose authority was present.

Reviewed installed hashes remained exact:

- transition helper: `73eb78453b87e86760cb9fafd556e11c2a5c43c8df2b2d3e87fa0429902d64d1`
- executor wrapper: `2feea261deaccb92dccc1f9c982ed9f4360c6320ad84dba2d7b39e476582dc49`
- authority gate: `561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda`

## Negative proof

With no live executor sudo authority installed, all four executor actions remained ineffective:

- `arm maintenance-page` -> rc=1, `sudo: a password is required`
- `deploy maintenance-page` -> rc=1
- `rollback maintenance-page` -> rc=1
- `disarm maintenance-page` -> rc=1

The Stage 5 inspection account retained only `authority-gate inspect` sudo authority. The active policy remained the exact inspection-ready policy `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`. The enable file remained absent. `maintenance-page` remained on rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`.

## Next gate

Do not install the live executor sudo rule yet. First create and review the source-only Jenkins human-approval pipeline and prove that the executor credential is not bound before the Jenkins `input` approval and second inspection/drift check.

No Stage 5 deployment was performed.
