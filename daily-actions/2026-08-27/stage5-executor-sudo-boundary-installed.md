# Stage 5 executor sudo boundary installed

Date: 2026-08-27

## Result

The live `homelab-stage5-executor` sudo boundary was installed and validated on TestServer.

Exact allowed commands:

- `/usr/local/libexec/homelab-stage5-maintenance-page-transition arm`
- `/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate deploy`
- `/usr/local/libexec/homelab-stage5-maintenance-page-authority-gate rollback`
- `/usr/local/libexec/homelab-stage5-maintenance-page-transition disarm`

No shell, Docker, Compose, wildcard or general sudo authority was granted.

## Installed identities

- transition helper SHA256: `73eb78453b87e86760cb9fafd556e11c2a5c43c8df2b2d3e87fa0429902d64d1`
- authority gate SHA256: `561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda`
- executor wrapper SHA256: `2feea261deaccb92dccc1f9c982ed9f4360c6320ad84dba2d7b39e476582dc49`
- executor SSH fingerprint: `SHA256:0mY135q5LD0cNgH9UlSwz0IWW7GHOZfEdvWU8YpyPr0`

## Validation evidence

- `/etc/sudoers.d/homelab-stage5-executor` is `root:root` mode `0440`.
- Full `/etc/sudoers` validation passed with `visudo`.
- Each exact allowed command appears once in the effective sudo surface.
- Out-of-scope argument forms were rejected.
- Executor wrapper continued to reject inspection, Docker, shell and wrong-service commands.
- The separate inspection identity remained read-only with only authority-gate `inspect`.

## Activation state

At the end of the change:

- active policy SHA256 remained `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f` (`inspection-ready`);
- `/etc/homelab-stage5/maintenance-page.enable` remained absent;
- `arm maintenance-page` was not invoked;
- `deploy maintenance-page` was not invoked;
- `rollback maintenance-page` was not invoked;
- `disarm maintenance-page` was not invoked;
- `maintenance-page` remained at rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`;
- all container IDs and restart counts remained unchanged.

Status: `EXECUTION COMMAND AUTHORITY: INSTALLED BUT NOT ACTIVATED`.

No Stage 5 deployment was performed.
