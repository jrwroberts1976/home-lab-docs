# Daily Actions — 28 August 2026

## Project direction

The container-version-control project remains on the established Stage 6 path:

> **Use Jenkins as the controlled orchestration layer for Docker container version updates, with immutable image identities, Git-backed authority, human approval, tightly scoped execution credentials, fail-closed validation, health verification, evidence capture and exact rollback.**

Jenkins must never receive unrestricted shell/Docker authority. The Jenkins controller and Jenkins-DinD remain protected control-plane exceptions.

## Daily operating step

🔁 **DAILY REPORT TRIAGE — Review the current day's nightly homelab report when it arrives (normally around 08:00 local time).**

- if the current day's report has already arrived, review it before starting planned project work;
- if work starts earlier, continue safe planned work and review the report as soon as it lands; do not substitute the previous day's report;
- review automated/nightly security, patching, backup, monitoring and health findings;
- identify genuine failures, warnings, regressions or follow-up actions;
- deduplicate against the existing TODO/backlog;
- add new actionable items to this file with enough evidence/context to make the next safe step clear;
- note in `daily-actions.md` whether the report produced new tasks, reinforced an existing task, or required no action;
- unresolved nightly findings must remain visible until completed or explicitly deferred with a reason.

## Priority TODO

1. ✅ COMPLETE — Dashy Stage 6 pilot.
   - Dashy successfully moved from `4.5.13` to `4.6.0` through the human-approved Stage 6 path;
   - current immutable image: `lissy93/dashy@sha256:40e3b27369002d4bce12cdffd5136b05924e1a7ea4e0d971a890557045fb1d59`;
   - current ARM64 image/config ID: `sha256:f7c93e5961154c8ee4a4bce7f4448d30b9ee46def5ed8eb3ebef3d111370de99`;
   - final state healthy, restart count `0`;
   - one-shot authority disarmed;
   - update-specific consumed evidence retained;
   - rollback was not required;
   - wait for the next real Dashy release before creating another Dashy transaction manifest.

2. ✅ COMPLETE — LibreSpeed Stage 6 suitability check.
   - running version `6.2.1`;
   - upstream/current version also `6.2.1`;
   - live container healthy with restart count `0`;
   - no update required;
   - do not force a no-op deployment.

3. ✅ COMPLETE — Prometheus 3.13.2 candidate acquisition and baseline discovery.
   - current version: `3.13.1`;
   - current immutable index digest: `sha256:3c42b892cf723fa54d2f262c37a0e1f80aa8c8ddb1da7b9b0df9455a35a7f893`;
   - current local ARM64 image ID: `sha256:4b91f0c2630ca36c5ed0275657a92a2e9270790b48d3ce7117adf1b468fceaa5`;
   - current binary revision: `73ff57ce2b8161059ac7fe5188f03f1c3d22b29a`;
   - candidate version: `3.13.2`;
   - candidate immutable index digest: `sha256:508729e0e2d18e11fd742a5a5ca70e557b940a93948c3c95fd0123a6fd538b69`;
   - candidate ARM64 platform manifest: `sha256:819dcd34085a183b908a439fc9379f1b504c0431a837b5e5b2d37a259b21c179`;
   - candidate local ARM64 image/config ID: `sha256:26bf7bb2ea9e4394b01ea4bd704e802ad4544eea9b2bc95a5dad244b342142d5`;
   - candidate binary revision: `bb5dff00cf8fdfbf5c65e0531aa835fa238a43a2`;
   - candidate created: `2026-07-30T12:02:05.288407376Z`;
   - candidate is already local on TestServer;
   - live Prometheus remained `3.13.1`, running, restart count `0`, `/-/ready` HTTP `200` throughout acquisition.

4. ✅ COMPLETE — Prometheus Compose image override prerequisite.
   - `docker-env` PR #19 merged;
   - merged authority revision: `ce591602bc6300cad001eb445269f8f4b8933c53`;
   - authoritative Compose SHA-256: `bcf38b612b8319fef2e3d077f3a3e70599cbe0ddbd26a8789f35ca1fd2836b1d`;
   - Prometheus image line is now `${PROMETHEUS_IMAGE:-prom/prometheus:v3.13.1}`;
   - default runtime remains `3.13.1` when the variable is unset;
   - an exact immutable candidate can be injected for Stage 6;
   - no deployment occurred as part of this source-only change.

5. ✅ COMPLETE — Generic persistent-directory / digest-pinned Stage 6 framework change.
   - `homelab-container-version-control` PR #49 merged;
   - reviewed source commit: `18e431aac7777a31a931053ca7b4a4198098d0b8`;
   - merge commit: `5daee1d5f14b717180a4b87ffb5d52b73c7c043e`;
   - exact four-file scope:
     - `config/service-update-manifest.schema.json`;
     - `ops/testserver/homelab-stage6-execute`;
     - `ops/testserver/homelab-stage6-inspect`;
     - `scripts/validate-stage6-service-manifest.py`;
   - persistent bind-mounted directories can now be represented explicitly with `source_kind: directory` and `sha256: null`;
   - file bind mounts remain SHA-256 pinned and default to `source_kind: file` for backward compatibility;
   - inspector and executor reject symlink bind sources;
   - `metadata_verification: digest-pinned` supports images without OCI version/revision labels while retaining exact config ID, OS, architecture and RepoDigest gates;
   - unknown metadata modes fail closed;
   - JSON Schema validation errors now return concise `FAIL:` output without a Python traceback;
   - Dashy backward compatibility and generic source guards passed;
   - no host installation and no Prometheus deployment occurred as part of this merge.

6. ✅ COMPLETE — Prometheus restricted Stage 6 source boundary onboarding.
   - `homelab-container-version-control` PR #50 merged;
   - reviewed source commit: `a812ad61a62026dec00bee6eca2f738fb160559b`;
   - merge commit: `6a2452001c008439188c5d78660b8fd0dcfe08eb`;
   - inspector source now permits only literal `inspect dashy` and `inspect prometheus` commands;
   - executor source now permits only literal `arm/deploy/rollback/disarm` commands for `dashy` and `prometheus`;
   - sudoers source contains the matching exact finite allowlists;
   - source validators require the exact ordered command surfaces and reject variable service/action forwarding;
   - malformed and unknown commands fail closed before sudo;
   - shell syntax, sudoers syntax, generic inspector/execution guards and independent PR patch review passed;
   - reviewed source is merged but has **not yet been installed on TestServer**;
   - no Prometheus deployment occurred.

7. ▶ NEXT — Create and validate `config/services/prometheus-3.13.2.json`.
   - rollback/current = `3.13.1`;
   - candidate = `3.13.2`;
   - authority revision = `ce591602bc6300cad001eb445269f8f4b8933c53`;
   - Compose SHA-256 = `bcf38b612b8319fef2e3d077f3a3e70599cbe0ddbd26a8789f35ca1fd2836b1d`;
   - use `metadata_verification: digest-pinned` because the Prometheus image does not publish the OCI version/revision labels required by the original Dashy inspector path;
   - represent Prometheus TSDB data as an exact persistent directory mount with `sha256: null`;
   - keep file bind mounts content-hashed;
   - collect exact SHA-256 values for `prometheus.yml` and `linux-hosts.yml` immediately before manifest review;
   - retain network `homelab_apps`, user `1000:1000`, restart `unless-stopped`, no Docker socket, no devices and no privileged mode;
   - use HTTP readiness `http://127.0.0.1:9090/-/ready` / expected `200` as the service health contract.

8. ⬜ Build the Prometheus Jenkins human-approval path.
   - derive from the proven Dashy Stage 6 sequence rather than creating a new security model;
   - pre-approval read-only inspection;
   - exact current/candidate identity display;
   - human approval;
   - post-approval reinspection and zero-drift check;
   - only then bind the restricted executor credential;
   - arm one-shot authority;
   - deploy exact immutable `3.13.2` with `--no-deps --no-build --pull never --force-recreate`;
   - verify readiness and runtime invariants;
   - rollback only if an actual consumed deployment fails;
   - disarm and retain immutable evidence.

9. ⬜ Run a Prometheus read-only smoke test before any deployment.
   - prove the inspector can inspect `prometheus` but cannot inspect arbitrary services;
   - prove executor `ping` still works;
   - prove Prometheus execution commands are unavailable before the reviewed host boundary is installed;
   - prove Jenkins and Jenkins-DinD container IDs/restart counts remain unchanged;
   - prove live Prometheus remains exact `3.13.1` and ready.

10. ⬜ Perform the human-approved Prometheus `3.13.1 → 3.13.2` deployment only after all preceding gates pass.
   - capture before/after container state;
   - verify current TSDB/config mounts remain exact;
   - verify `/-/ready` returns `200` after recreate;
   - verify unrelated containers unchanged;
   - verify one-shot authority consumed then disarmed;
   - retain rollback path to exact `3.13.1` immutable image;
   - document final Jenkins build evidence and host state.

11. ⬜ AFTER PROMETHEUS PILOT — assess `3.14.0` separately.
   - do not combine the 3.13.2 pilot with the later minor-version move;
   - first prove 3.13.2 through the complete Stage 6 path;
   - review 3.14.0 release/compatibility notes before a separate transaction manifest.

12. ⬜ Publish Homelab Defender through a controlled external route and link it from the Engineering Portfolio.
   - expose only Defender through the existing Cloudflare/reverse-proxy model;
   - keep Jenkins, registry and Kubernetes control paths private;
   - validate TLS/browser/game/monitoring externally;
   - add the public Defender URL to the portfolio only after the route is proven;
   - retain a quick route-disable rollback.

13. ⬜ Audit Grafana Host Overview coverage.
   - establish the authoritative intended host list;
   - compare Prometheus targets and emitted labels with the Grafana hostname variable;
   - distinguish collection gaps from dashboard-query gaps before changing Grafana;
   - validate the final host count and deliberate exclusions.

14. ⬜ Tidy the Jenkins dashboard and organise container pipelines into folders.
   - create a clear Jenkins folder for each managed container/service so its inspection, candidate/update, approval and deployment pipelines are grouped together;
   - use predictable folder/job naming so the dashboard quickly shows which pipelines belong to which container;
   - keep shared Jenkins platform/control-plane, credential-validation and infrastructure utility jobs in a separate administrative folder rather than mixing them with service pipelines;
   - preserve existing job history, build numbers, credentials, triggers, parameters and security boundaries when jobs are moved or recreated;
   - do not broaden executor permissions or change the Stage 6 deployment security model as part of this UI/organisation tidy-up;
   - identify and remove/archive obsolete temporary smoke/debug jobs only after their evidence is retained in Git/docs;
   - document the final Jenkins folder layout so future container onboarding follows the same structure.

15. ⬜ Plan the Proxmox VM Infrastructure-as-Code project.
   - target a VM environment on the Proxmox platform for PostgreSQL, TimescaleDB and Nginx;
   - provision VM/infrastructure resources with Terraform and configure the guest/services with Ansible;
   - define the target VM sizing, storage, networking, DNS, addressing and backup/restore model before implementation;
   - decide how PostgreSQL/TimescaleDB data volumes, retention, backup, restore testing and monitoring will be handled;
   - define Nginx's role and exposure model, keeping management/control interfaces private;
   - define secrets handling so credentials are not embedded in Terraform state, Ansible source or Git;
   - build the project as reviewed IaC in Git with a repeatable create/configure/validate/destroy or recovery workflow;
   - document estimated effort, prerequisites, implementation stages, acceptance tests and rollback/rebuild path before starting the build.

16. ⬜ Plan the long-term migration of the Docker platform onto Proxmox.
   - treat this as a phased platform migration, not a single big-bang move;
   - inventory the current TestServer Docker estate, Compose projects, networks, bind mounts/volumes, secrets, dependencies, ingress, DNS, monitoring and backup requirements;
   - classify services by migration risk and dependency order, keeping Jenkins/control-plane, DNS/routing/security and stateful services in separately reviewed waves;
   - define the target Proxmox architecture: VM/LXC boundaries, Docker hosts, storage, networking/VLANs, backup, restore and resilience model;
   - decide which existing services should remain containers, which should move to dedicated VMs, and which should be retired or consolidated;
   - preserve Git/Compose/IaC authority so services can be rebuilt rather than manually recreated;
   - plan data migration, parallel-run validation, DNS/ingress cutover, monitoring continuity and per-wave rollback;
   - use the Proxmox VM/IaC project as an early proving ground for Terraform/Ansible patterns that can later support the broader migration;
   - create a staged migration roadmap before moving production homelab workloads.

## Safety boundary carried forward

```text
Dashy Stage 6 pilot = COMPLETE
Dashy current = 4.6.0
Dashy armed = false
Dashy completed update consumed = true
LibreSpeed current = 6.2.1
LibreSpeed update required = NO
Prometheus current = 3.13.1
Prometheus candidate local = 3.13.2
Prometheus ready HTTP = 200
Prometheus deployment performed = NO
Prometheus Stage 6 manifest created = NO
Prometheus boundary source merged = YES
Prometheus executor authority installed = NO
Prometheus inspector authority installed = NO
Generic persistent-directory support merged = YES
Generic persistent-directory support installed = NO
Jenkins unrestricted Docker/shell authority = NO
```

Do not deploy Prometheus until the manifest, reviewed host installation, Jenkins human-approval path and predeployment zero-drift inspection have all been separately reviewed and proven fail-closed.
