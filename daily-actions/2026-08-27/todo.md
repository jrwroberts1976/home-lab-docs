# Daily Actions — 27 August 2026

## Priority TODO

1. ✅ COMPLETE — Sync local working checkouts to the newly merged `main` branches before starting any new Stage 5 work.
   - `jrwroberts1976/homelab-container-version-control` -> `683e3c13357770931f28808767a1ffffa010b54f`;
   - `jrwroberts1976/home-lab-docs` -> `e5cc9a585642f2ad035b1c1128adc9726b57fa41`;
   - `jrwroberts1976/jenkins-gradle-delivery-lab` -> `8a5519afda4e3a1bfbae3e78c88af2fe9bcd86af`;
   - `jrwroberts1976/engineering-portfolio` -> `b96596459b6b23d12e98cee2711b0d3244b29b80`;
   - all four local working copies fast-forwarded cleanly to the authoritative remote `main` heads;
   - live dirty `/home/james/docker` checkout was left untouched and is not treated as the authoritative working copy.

2. ✅ COMPLETE — Reconfirm the Stage 4 baseline after sync.
   - implementation PR #26 merge `0adfc1a9e5ad76f42a3eb4a2970dcd5014e79505` confirmed as an ancestor of current implementation `main`;
   - documentation PR #40 merge `5d29f963fdc9a96fdb83e3a147133c376c7f4ff5` confirmed as an ancestor of current documentation `main`;
   - critical Stage 4 `Jenkinsfile` and forced-command wrapper are unchanged from implementation PR #26;
   - Jenkins credential-store-only Build #5 remains the accepted execution baseline;
   - Jenkins still independently asserts `deployment.allowed=false`;
   - Jenkins still independently asserts `deployment.performed=false`;
   - explicit `Stop before deployment` stage remains present;
   - final result: `PASS: STAGE 4 BASELINE RECONFIRMED`;
   - no Stage 5 deployment authority is enabled.

3. ✅ COMPLETE — Design and implement a durable Jenkins network identity.
   - rejected the allocator-assigned `172.18.0.23` on shared `homelab_apps` as a durable security identity and rejected any subnet-wide SSH allowance;
   - dedicated validation network implemented as `jenkins_validation` = `172.30.255.248/29`;
   - TestServer bridge gateway / Stage 4 SSH destination = `172.30.255.249`;
   - Jenkins declarative fixed validation identity = `172.30.255.250`;
   - Jenkins controller remains on `homelab_apps` for existing application/DinD connectivity; `jenkins-docker` remains excluded from `jenkins_validation`;
   - authoritative Jenkins Compose definition is `jrwroberts1976/docker-env/stacks/jenkins`, merged in PR #15 as `1f95b0a2d6f8da5500a6a02d0d8416393107e8df`;
   - implementation PR #27 changed only `STAGE4_HOST` from `172.18.0.1` to `172.30.255.249` and merged as `efcbc7199b435497f2b624b3efbb54bc50b274f6`;
   - strict TestServer ED25519 host-key pin remains `SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk`;
   - validator public-key fingerprint remains `SHA256:DcO1PigKb2GXD6clI/1uCNHlX2MVryivfL5BbhkNe7k`;
   - accepted Stage 4 run proved source `172.30.255.250 -> 172.30.255.249:22` in the TestServer SSH journal and exact `/32` UFW counter;
   - Jenkins controller was deliberately recreated from the merged Git-owned Compose authority; the container ID changed, Jenkins returned `running` with restart count `0`, and `jenkins_validation=172.30.255.250` with gateway `172.30.255.249` survived declaratively;
   - Jenkins HTTP recovered with `200`; persistent SSH host-key state survived recreation;
   - Jenkins DinD was not recreated, remained only on `homelab_apps`, and retained its pre-existing restart count `1`;
   - post-recreation Stage 4 `dozzle` validation succeeded with `deployment.allowed=false`, `deployment.performed=false`, and `Stop before deployment`;
   - temporary rollback trust was then retired: old UFW source `172.18.0.23` removed, validator key reduced to `from="172.30.255.250"`, and old `172.18.0.1` Jenkins `known_hosts` entry removed;
   - final trust boundary is now UFW `172.30.255.250/32 -> tcp/22`, validator key `from="172.30.255.250"`, and Jenkins `known_hosts` containing the durable destination `172.30.255.249`;
   - final post-cutover Stage 4 Jenkins run at `06:24` checked out exact merge `efcbc7199b435497f2b624b3efbb54bc50b274f6`, passed reviewed-input/SSH preflight, received the deployment-plan artifact, returned `dozzle -> no-change / none`, independently reconfirmed `deployment.allowed=false` and `deployment.performed=false`, executed `Stop before deployment`, archived the artifact, and finished `SUCCESS` with the old trust path already absent;
   - backups retained under `/var/backups`, including pre-cutover authorized-key and known-hosts copies;
   - no Stage 5 deployment authority has been introduced;
   - design record `daily-actions/2026-08-27/jenkins-durable-network-identity-design.md` is now `COMPLETE — LIVE CUTOVER PROVEN`.

4. ✅ COMPLETE — Define the Stage 5 pilot boundary before enabling any deployment authority.
   - design record: `daily-actions/2026-08-27/stage5-pilot-boundary-design.md`;
   - one-service pilot only;
   - explicit human approval after the read-only plan and before execution;
   - immutable current/candidate identities required;
   - exact authoritative Git commit required;
   - pre-defined health/smoke checks and rollback target required before approval;
   - drift detection must fail closed;
   - restricted allow-listed wrapper required; unrestricted Docker/Compose or general shell authority forbidden;
   - Jenkins controller remains a permanent platform exception and must never automatically deploy/recreate itself;
   - design is policy-only and did not enable any deployment command or Stage 5 authority.

5. ✅ COMPLETE — Select the Stage 5 pilot service after boundary review.
   - selected pilot: `maintenance-page`;
   - selection record: `daily-actions/2026-08-27/stage5-pilot-selection-maintenance-page.md`;
   - live audit confirmed one non-privileged nginx container, restart count `0`, no Docker socket, no writable data/database mounts, two read-only binds, one LAN HTTP endpoint and one external `homelab_apps` membership;
   - current runtime image ID: `sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483`;
   - immutable rollback image: `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`;
   - authoritative Git stack is `jrwroberts1976/docker-env/stacks/maintenance-page` at selection-time `main` `1f95b0a2d6f8da5500a6a02d0d8416393107e8df`;
   - deterministic smoke check: `http://192.168.2.220:8088/` must succeed and contain `Planned Maintenance | James Roberts`;
   - `dozzle` rejected for first pilot because it mounts the Docker socket; Homepage/Dashy/LibreSpeed/Filebrowser rejected because they include writable application/config/data state;
   - current Git image reference `nginx:alpine` is mutable and is explicitly blocked as a Stage 5 candidate;
   - before deployment authority is installed, the candidate must be pinned to one reviewed digest and the exact live pilot source must be reconciled to authoritative `docker-env` Git;
   - no Stage 5 deployment authority has been enabled and no deployment has been performed.

6. Publish Homelab Defender through a controlled external route and link it from the Engineering Portfolio.
   - start from validated build 15 unless a newer immutable release has completed the same validation and Git reconciliation;
   - choose and record a dedicated public Defender hostname;
   - expose only the Defender application through the existing Cloudflare/reverse-proxy model;
   - keep Jenkins, the private Docker registry and Kubernetes control paths private;
   - validate TLS, browser/game behaviour and monitoring from an external client;
   - add a build-time `PUBLIC_HOMELAB_DEFENDER_URL` to the Engineering Portfolio;
   - render a `Play Homelab Defender` link only when the public URL is configured and proven;
   - deploy the portfolio through its controlled production path and verify the external link;
   - retain a quick route-disable/publication rollback path.
   - publication runbook: `jrwroberts1976/jenkins-gradle-delivery-lab/PUBLICATION_GUIDE.md`.

7. Keep the new container-management user guides aligned with Stage 5 implementation.
   - `docs/user-guides/create-new-container.md`;
   - `docs/user-guides/update-existing-container.md`;
   - `docs/user-guides/README.md`;
   - update them when the actual Stage 5 deployment command, approval gate and rollback implementation are proven.

8. Audit the Grafana Host Overview dashboard and confirm that all intended hosts are represented.
   - establish the authoritative list of hosts that should appear;
   - inspect Prometheus active targets and identify missing/down exporters before changing Grafana;
   - compare available host labels/hostnames with the dashboard variable query;
   - check whether `homelab_network_device_info` is emitted for every intended host or is unintentionally filtering the list;
   - verify each dashboard panel uses a metric available for all host classes rather than only Docker/Linux subsets;
   - distinguish collection gaps from dashboard-query/filtering gaps;
   - correct the dashboard only after the underlying metric coverage is proven;
   - validate the final host count and record any deliberate exclusions.

9. Update the project tracker and daily-actions documentation as Stage 5, Defender publication and Host Overview decisions are made.

## Next Stage 5 action

Design the restricted `maintenance-page` Stage 5 deployment wrapper and Jenkins dry-run contract. This next phase must remain non-deploying: choose/pin the candidate digest, prove drift checks, preview exact one-service recreation and rollback actions, and prove the pipeline still stops before deployment until a separate reviewed authority-installation step.

## Safety boundary carried forward

```text
Stage 4 = COMPLETE
READ-ONLY
credential-store execution proven
deployment.allowed=false
deployment.performed=false
Stage 5 pilot = maintenance-page selected
Stage 5 deployment authority = NOT ENABLED
Stage 5 deployment performed = NO
```

Do not add Docker/Compose deployment authority until the restricted wrapper and human-controlled pilot implementation have been separately reviewed.

Publishing Homelab Defender is a separate Kubernetes/public-edge change. It must not widen Jenkins, registry or Kubernetes management exposure.