# Daily Actions — 27 August 2026

## Project direction

The container-version-control project remains on the original path:

> **Use Jenkins as the controlled orchestration layer for Docker container version updates.**

Jenkins should detect or receive a version change, identify the exact immutable candidate, validate the plan, require human approval, invoke only a narrowly allow-listed service-scoped deployment action, run post-change health checks, record the result, and provide an exact rollback path.

Jenkins must never receive unrestricted shell/Docker authority, and Jenkins itself remains a permanent self-deployment exception.

## Priority TODO

1. ✅ COMPLETE — Stage 4 read-only validation baseline.
   - credential-store execution proven;
   - durable Jenkins source identity `172.30.255.250` on `jenkins_validation`;
   - TestServer SSH destination `172.30.255.249`;
   - pinned TestServer host key `SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk`;
   - Jenkins independently proves `deployment.allowed=false` and `deployment.performed=false`;
   - explicit `Stop before deployment` remains enforced.

2. ✅ COMPLETE — Stage 5 pilot boundary and pilot selection.
   - selected pilot: `maintenance-page`;
   - one-service scope only;
   - human approval required before any deployment;
   - exact Git authority, immutable current/candidate/rollback identities, health checks and rollback required;
   - unrestricted Docker/Compose/general shell forbidden;
   - Jenkins controller and CI/CD control plane excluded from automatic deployment.

3. ✅ COMPLETE — Stage 5 maintenance-page candidate and rollback preparation.
   - rollback: `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752` (`nginx 1.31.3-alpine`);
   - rollback ARM64 image ID: `sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483`;
   - candidate: `nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913` (`nginx 1.31.4-alpine`);
   - candidate ARM64 child: `sha256:57744b8fa99abc438b1fbde6bd69e4270d0984ccfdee60c661ec22243047373a`;
   - candidate local ARM64 image ID: `sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5`;
   - candidate and rollback both confirmed local by the live Stage 5 inspection artifact;
   - health endpoint `http://192.168.2.220:8088/` returns `200` with marker `Planned Maintenance | James Roberts`;
   - maintenance-page remains on the rollback digest; no Stage 5 deployment has occurred.

4. ✅ COMPLETE — Stage 5 source review and merge chain.
   - `docker-env` PR #16 maintenance-page immutable candidate/config authority merged as `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`;
   - implementation PR #28 review boundary merged as `f05da1a31caa904c10b1a4b7455d2daf823be721`;
   - implementation PR #29 guarded helper source merged as `6112d3dcf1f38dad88e71cd322672c7e58b4ba6a`;
   - implementation PR #30 inspection-only preapproval path merged as `ad3e85e2e6afe576d57dec186cefea58bddc8a20`;
   - implementation PR #31 helper-free inspection hardening merged as `dfb773c81770fe12936d25558b427a279ebafd83`;
   - `docker-env` PR #17 explicitly added `openssh-client` to the Jenkins image definition and merged as `b8058c667cac59dc741587f0554437ee000f6486`;
   - no open PRs remain across `docker-env`, `homelab-container-version-control`, or `home-lab-docs` for this Stage 5 work;
   - all remaining Stage 5 branch refs compare `ahead_by=0` against `main`, so no unmerged Stage 5 code remains on them.

5. ✅ COMPLETE — Stage 5 inspection-only TestServer installation.
   - account `homelab-stage5-pilot`, uid `996`, gid `983`, password locked, not in Docker group;
   - authority gate installed and pinned SHA256 `561499a0e327f02e4df7fdabf40ab1d0660dc5ed51622061c568f9deaaa4dbda`;
   - inspector installed and pinned SHA256 `64dc6526e66a9e6878ca23c1703a9d7bb11c82b7f60cf7b8aae714b2ed9cb213`;
   - forced SSH wrapper installed and pinned SHA256 `85ad4a488325a07316cc17bc3b245f5f0b4136a920b126e25fb35c659ccdd6a6`;
   - inspection-ready policy SHA256 `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`;
   - root-owned authority checkout `/var/lib/homelab-stage5/authority/docker-env`;
   - only sudo handoff is `authority-gate inspect`;
   - mutating deployment helper absent;
   - enable file absent;
   - deploy/rollback sudo authority absent.

6. ✅ COMPLETE — Stage 5 SSH hardening and Jenkins credential.
   - public-key-only authentication;
   - account-level `ForceCommand /usr/local/sbin/homelab-stage5-pilot-ssh`;
   - no TTY, TCP forwarding, agent forwarding, tunnel or user RC;
   - Jenkins credential ID `homelab-stage5-testserver-inspector`;
   - credential username `homelab-stage5-pilot`;
   - credential fingerprint `SHA256:nvCBuAboTuAqiBCGj3Rj7DPNQW9um7FZByjKZHH0naI`;
   - source restriction `restrict,from="172.30.255.250"`;
   - final trust path `.ssh` = `root:homelab-stage5-pilot 0750`;
   - final `authorized_keys` = `root:homelab-stage5-pilot 0640`;
   - account can read/traverse but cannot modify trust;
   - private key imported via supported Jenkins credential CLI flow;
   - transient private-key and temporary CLI/API-token files removed.

7. ✅ COMPLETE — Stage 5 remote positive-path proof.
   - Jenkins bound the exact Stage 5 credential;
   - TestServer accepted public-key authentication from `172.30.255.250` using the exact expected fingerprint;
   - remote `ping` succeeded through the forced wrapper;
   - remote `inspect maintenance-page` succeeded;
   - Jenkins parsed and independently asserted the returned `pilot-inspection` artifact;
   - `approval.required=true`;
   - `approval.granted=false`;
   - `inspection.allowed=true`;
   - `inspection.performed=true`;
   - `deployment.allowed=false`;
   - `deployment.performed=false`;
   - `deploy_command_enabled=false`;
   - `rollback_command_enabled=false`;
   - result `ready-for-human-review`;
   - all container IDs/restart counts unchanged;
   - maintenance-page remained exact rollback.

8. ✅ COMPLETE — Stage 5 remote negative-path proof.
   - same successfully authenticated Jenkins identity used;
   - `deploy maintenance-page` rejected, rc `2`;
   - `rollback maintenance-page` rejected, rc `2`;
   - `inspect jenkins` rejected, rc `2`;
   - `docker ps` rejected, rc `2`;
   - `shell` rejected, rc `2`;
   - TestServer journal proved SSH authentication succeeded before command rejection;
   - temporary proof jobs and CLI/API-token files removed;
   - no container changed or restarted;
   - deployment helper/enable/deploy sudo remained absent.

9. ▶ NEXT — Stage 5 execution-transition preflight.
   - **Do not deploy yet.**
   - re-pin current `homelab-container-version-control/main` and `docker-env/main`;
   - revalidate the reviewed mutating helper source and exact hash;
   - prove inspection gate/inspector/wrapper/policy hashes remain exact;
   - prove root-owned authority checkout is clean and exact;
   - prove candidate and rollback immutable images remain local Linux/ARM64 and match expected identities;
   - prove maintenance-page still equals rollback and health marker still passes;
   - prove Jenkins and Jenkins-Docker protected state unchanged;
   - define the exact transition from inspection-ready policy to execution-ready policy;
   - define root-owned one-shot enable/state lifecycle;
   - define the minimal deploy/rollback sudo commands with no arbitrary arguments;
   - wire the Jenkins **human approval** stage;
   - prove approval cannot be bypassed or replayed;
   - define post-deploy health and smoke checks;
   - define exact rollback action and rollback-health verification;
   - define evidence/recording output;
   - ensure execution authority is consumed/disabled immediately after the approved action.

10. ⬜ AFTER PILOT — Generalise Jenkins container-version updates cautiously.
   - apply only to explicitly approved services;
   - per-service current/candidate/rollback policy;
   - immutable digests, never floating deployment intent;
   - pre-stage candidate before approval;
   - no general Docker socket or shell access;
   - exclude Jenkins/DinD, DNS/routing/firewall/identity/secrets/storage/monitoring control plane/k3s and other high-risk services unless separately designed;
   - retain human approval until a later, separately reviewed policy proves a safer automation tier is appropriate.

11. ⬜ Publish Homelab Defender through a controlled external route and link it from the Engineering Portfolio.
   - expose only Defender through the existing Cloudflare/reverse-proxy model;
   - keep Jenkins, registry and Kubernetes control paths private;
   - validate TLS/browser/game/monitoring externally;
   - add `PUBLIC_HOMELAB_DEFENDER_URL` to the portfolio only after the route is proven;
   - retain quick route-disable rollback.

12. ⬜ Audit Grafana Host Overview coverage.
   - establish authoritative intended host list;
   - compare Prometheus targets and emitted labels with Grafana hostname variable;
   - distinguish collection gaps from dashboard-query gaps before changing Grafana;
   - validate final host count and deliberate exclusions.

## Documentation records

Key Stage 5 records include:

- `stage5-pilot-boundary-design.md`
- `stage5-pilot-selection-maintenance-page.md`
- `stage5-maintenance-page-candidate-dry-run.md`
- `stage5-live-compose-authority-sync.md`
- `stage5-helper-free-inspection-review.md`
- `stage5-inspection-only-installation-rehearsal.md`
- `stage5-inspection-only-host-install.md`
- `stage5-jenkins-credential-store-verification.md`
- `stage5-remote-inspection-identity-created.md`
- `stage5-remote-inspection-transport-proof.md`
- `stage5-inspection-phase-complete-and-container-update-path.md`

## Safety boundary carried forward

```text
Stage 4 = COMPLETE
Stage 5 inspection phase = COMPLETE
Jenkins stored credential = PROVEN
Jenkins source = 172.30.255.250
TestServer destination = 172.30.255.249
Stage 5 positive inspection = PROVEN
Stage 5 forbidden-command boundary = PROVEN
Stage 5 candidate image local = YES
Stage 5 rollback image local = YES
approval.required = true
approval.granted = false
deployment.allowed = false
deployment.performed = false
Stage 5 deployment helper installed = NO
Stage 5 enable file = ABSENT
Stage 5 deploy/rollback sudo authority = ABSENT
maintenance-page current = rollback digest
Stage 5 deployment performed = NO
```

Do not install or enable deployment authority until the execution-transition preflight and Jenkins human-approval path have been separately reviewed and proven fail-closed.
