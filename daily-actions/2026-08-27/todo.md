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

5. ✅ COMPLETE — Select and fully review the Stage 5 pilot source boundary.
   - selected pilot: `maintenance-page`;
   - selection record: `daily-actions/2026-08-27/stage5-pilot-selection-maintenance-page.md`;
   - live audit confirmed one non-privileged nginx container, restart count `0`, no Docker socket, no writable data/database mounts, two read-only binds, one LAN HTTP endpoint and one external `homelab_apps` membership;
   - current runtime image ID: `sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483`;
   - immutable rollback image: `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752` = nginx `1.31.3-alpine`;
   - selected immutable candidate: `nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913` = nginx `1.31.4-alpine`;
   - candidate ARM64 manifest: `sha256:57744b8fa99abc438b1fbde6bd69e4270d0984ccfdee60c661ec22243047373a`;
   - source reconciliation proved `docker-compose.yml`, `nginx/default.conf` and `html/index.html` matched the authoritative baseline byte-for-byte; `html/change.json` is expected runtime-generated change-control state and local `docker-compose.yml.bak-*` files are inert residue;
   - deterministic smoke check: `http://192.168.2.220:8088/` returns `200` and contains `Planned Maintenance | James Roberts`;
   - `dozzle` rejected for first pilot because it mounts the Docker socket; Homepage/Dashy/LibreSpeed/Filebrowser rejected because they include writable application/config/data state;
   - `docker-env` PR #16 parameterised the immutable candidate as the default with `MAINTENANCE_PAGE_IMAGE` reserved for the root-policy rollback override; validation proved candidate/rollback rendering, live relative-mount resolution, one-service dry-run scope, no image pull, no container/restart mutation and healthy HTTP baseline; PR #16 merged as `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`;
   - non-mutating Stage 5 command-boundary PR #28 passed exact-checkout validation and merged as `f05da1a31caa904c10b1a4b7455d2daf823be721`; Stage 4 remained unchanged, `ping`/`inspect maintenance-page` stayed read-only, and deploy/rollback/arbitrary commands were rejected;
   - guarded deployment-source PR #29 introduced a disabled execution-policy template, mandatory root-owned docker-env authority gate, inner one-service helper and source-review validator;
   - review found and fixed an authority-proof gap before merge: the mandatory gate now requires clean root-owned authority checkout `/var/lib/homelab-stage5/authority/docker-env`, exact merged `docker-env` commit `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`, matching authority/live configuration hashes and reviewed installed identities before handoff;
   - exact PR #29 head `00d5d50b33c95d8f70a3a10f797900f8dde4847f` passed authority-gate revalidation: gate contains no Docker/Compose mutation, source-checkout deploy/rollback cannot execute, Stage 4 remains unchanged, maintenance-page/Jenkins/DinD IDs and restart counts remain unchanged, and HTTP baseline remains healthy;
   - PR #29 merged as reviewed source only at `6112d3dcf1f38dad88e71cd322672c7e58b4ba6a`;
   - merged source still installs/enables nothing: no Stage 5 host account/key, sudo rule, Docker-group membership, helper/gate, execution policy, authority checkout, enable file, Jenkins credential or pipeline deployment stage exists;
   - authority-installation preflight then passed: GitHub implementation authority is exactly `6112d3dcf1f38dad88e71cd322672c7e58b4ba6a`; GitHub `docker-env` authority is exactly `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`; live Compose differs from merged authority only by the expected reviewed image declaration; `nginx/default.conf` and `html/index.html` match authority byte-for-byte;
   - preflight found no existing `homelab-stage5-pilot` account, no Stage 5 Docker-group membership, no proposed install-path collisions, no Stage 5 sudoers references and no Stage 5 SSH references; existing Jenkins validation UFW rule remains `172.30.255.250 -> tcp/22`;
   - rollback digest is locally available as Linux/ARM64 and remains the exact running maintenance-page identity; candidate digest is not yet local; maintenance-page remains running with restart count `0`, Jenkins remains restart count `0`, Jenkins DinD remains restart count `1`, and HTTP/content baseline remains healthy;
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

Stage the exact reviewed candidate image locally **without changing any container or enabling deployment authority**. Pull only `nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913`, verify Docker resolves it as Linux/ARM64 and that the remote Linux/ARM64 child remains `sha256:57744b8fa99abc438b1fbde6bd69e4270d0984ccfdee60c661ec22243047373a`, verify the rollback digest remains local/current, and prove all container IDs/restart counts plus the maintenance-page HTTP baseline are unchanged. Do not create/install the Stage 5 account, key, sudo rule, helper/gate, policy/enable file, authority checkout, Jenkins credential or deployment stage during image staging.

## Safety boundary carried forward

```text
Stage 4 = COMPLETE
READ-ONLY
credential-store execution proven
deployment.allowed=false
deployment.performed=false
Stage 5 pilot = maintenance-page selected
Stage 5 candidate = nginx 1.31.4 immutable digest selected
Stage 5 rollback = nginx 1.31.3 immutable digest pinned and local
Stage 5 candidate config PR #16 = MERGED as f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883
Stage 5 review boundary PR #28 = MERGED as f05da1a31caa904c10b1a4b7455d2daf823be721
Stage 5 guarded helper-source PR #29 = MERGED as 6112d3dcf1f38dad88e71cd322672c7e58b4ba6a
Stage 5 authority-installation preflight = COMPLETE
Stage 5 candidate image local = NO
Stage 5 authority installation = NOT STARTED
Stage 5 deployment authority = NOT ENABLED
Stage 5 deployment performed = NO
```

Do not install Docker/Compose deployment authority until candidate image staging is proven and the account/key/sudo/installed-policy/authority-checkout/Jenkins approval path has been separately reviewed and proven fail-closed.

Publishing Homelab Defender is a separate Kubernetes/public-edge change. It must not widen Jenkins, registry or Kubernetes management exposure.