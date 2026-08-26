# Daily Actions — 27 August 2026

## Priority TODO

1. Sync local working checkouts to the newly merged `main` branches before starting any new Stage 5 work.
   - `jrwroberts1976/homelab-container-version-control`
   - `jrwroberts1976/home-lab-docs`
   - keep the live dirty `/home/james/docker` checkout untouched and do not treat it as the authoritative working copy.

2. Reconfirm the Stage 4 baseline after sync.
   - implementation PR #26 merged as `0adfc1a9e5ad76f42a3eb4a2970dcd5014e79505`;
   - documentation PR #40 merged as `5d29f963fdc9a96fdb83e3a147133c376c7f4ff5`;
   - Jenkins credential-store-only Build #5 proof remains the accepted execution baseline;
   - `deployment.allowed=false`;
   - `deployment.performed=false`.

3. Design a durable Jenkins network identity.
   - preserve the current narrow SSH source restriction;
   - do not broaden the firewall rule to the full Docker subnet as a shortcut;
   - make the restriction survive Jenkins controller recreation;
   - document the chosen approach before changing the live controller/network.

4. Define the Stage 5 pilot boundary before enabling any deployment authority.
   - explicit human approval point;
   - one low-risk pilot service only;
   - exact current-to-candidate identity captured before deployment;
   - health/smoke checks defined in advance;
   - automatic stop on failed validation;
   - explicit rollback path;
   - Jenkins controller remains a platform exception and must not automatically deploy or recreate itself.

5. Select the Stage 5 pilot service only after the deployment-control design is reviewed.
   - avoid Jenkins itself;
   - prefer a reversible, low-impact service;
   - confirm ownership, secrets, architecture, security and rollback readiness before selection.

6. Update the project tracker and daily-actions documentation as Stage 5 decisions are made.

## Safety boundary carried forward

```text
Stage 4 = COMPLETE
READ-ONLY
credential-store execution proven
deployment.allowed=false
deployment.performed=false
```

Do not add Docker/Compose/Kubernetes deployment authority until the Stage 5 human-controlled pilot boundary has been explicitly reviewed.
