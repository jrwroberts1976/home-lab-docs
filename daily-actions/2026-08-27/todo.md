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

3. 🔄 IN PROGRESS — Design and implement a durable Jenkins network identity.
   - baseline discovery confirmed Jenkins previously received dynamic `172.18.0.23` on shared external bridge `homelab_apps` (`172.18.0.0/16`, gateway `172.18.0.1`);
   - rejected: broadening SSH to `172.18.0.0/16` or treating dynamic `172.18.0.23` as durable identity;
   - selected dedicated validation network: `jenkins_validation` = `172.30.255.248/29`;
   - bridge gateway / Stage 4 SSH destination: `172.30.255.249`;
   - fixed Jenkins validation identity: `172.30.255.250`;
   - final intended UFW source restriction: `172.30.255.250/32`;
   - final intended validator key restriction: `from="172.30.255.250"`;
   - Jenkins controller/DinD configuration captured into authoritative Git path `jrwroberts1976/docker-env/stacks/jenkins`;
   - `docker-env` PR #15 merged as `1f95b0a2d6f8da5500a6a02d0d8416393107e8df` after exact Dockerfile/Compose/runtime validation;
   - post-merge Compose dry-run confirmed only `jenkins_validation` creation plus Jenkins controller recreation would be required; DinD remained outside the operation;
   - ✅ parallel migration trust prepared: UFW permits both old `172.18.0.23/32` and new `172.30.255.250/32`; validator key temporarily permits `from="172.18.0.23,172.30.255.250"`;
   - validator public-key fingerprint remained `SHA256:DcO1PigKb2GXD6clI/1uCNHlX2MVryivfL5BbhkNe7k`;
   - authorized-key backup: `/var/backups/homelab-validator-authorized_keys-20260827-055427`;
   - ✅ `jenkins_validation` created with Compose ownership labels and reviewed IPAM values;
   - ✅ running Jenkins attached without restart at `172.30.255.250`, while retaining `172.18.0.23` on `homelab_apps` for rollback;
   - ✅ DinD remained excluded from `jenkins_validation` and retained pre-existing restart count `1`; Jenkins restart count remained `0`;
   - ✅ SSH probe from Jenkins to `172.30.255.249:22` matched pinned TestServer ED25519 fingerprint `SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk`;
   - ✅ new exact `/32` UFW packet counter incremented from `0` to `1`, proving the probe used `172.30.255.250 -> 172.30.255.249:22`;
   - ✅ Jenkins `known_hosts` now pins both `172.18.0.1` and `172.30.255.249` to the same reviewed TestServer ED25519 key;
   - known-hosts backup: `/var/backups/stage4-testserver-known_hosts-20260827-055822`;
   - implementation PR #27 changed only `STAGE4_HOST` from `172.18.0.1` to `172.30.255.249` (1 file, 1 addition, 1 deletion) and merged as `efcbc7199b435497f2b624b3efbb54bc50b274f6`;
   - Jenkins job SCM branch was corrected from deleted `stage4/jenkins-integration` to merged `main` after an initial pre-pipeline fetch failure; that failed attempt executed no Jenkinsfile stages and made no infrastructure change;
   - ✅ successful post-merge Stage 4 Jenkins run checked out exact merge `efcbc7199b435497f2b624b3efbb54bc50b274f6`, passed reviewed-input/SSH preflight, received the deployment-plan artifact, returned `dozzle -> no-change / none`, independently reconfirmed `deployment.allowed=false` and `deployment.performed=false`, executed `Stop before deployment`, archived the artifact, and finished `SUCCESS`;
   - next step: correlate the successful run window (`06:11:34`–`06:11:52`) with TestServer SSH/firewall evidence to prove the accepted Jenkins run used source `172.30.255.250` before retiring the old `.23 -> .1` rollback trust;
   - do not remove the old `.23 -> .1` trust path until that source-path proof is accepted;
   - no Stage 5 deployment authority has been introduced;
   - design record: `daily-actions/2026-08-27/jenkins-durable-network-identity-design.md`.

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

## Safety boundary carried forward

```text
Stage 4 = COMPLETE
READ-ONLY
credential-store execution proven
deployment.allowed=false
deployment.performed=false
```

Do not add Docker/Compose deployment authority until the Stage 5 human-controlled pilot boundary has been explicitly reviewed.

Publishing Homelab Defender is a separate Kubernetes/public-edge change. It must not widen Jenkins, registry or Kubernetes management exposure.