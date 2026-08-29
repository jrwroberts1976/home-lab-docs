# TODO — 29 August 2026

## P0 — Stage 6 estate updater

1. ⬜ **Design the steady-state read-only inspection contract.**
   - do not reuse the existing pre-approval transition inspector;
   - model the currently deployed known-good immutable identity directly;
   - preserve exact authority, runtime-shape, mount, network, health and protected-workload checks;
   - include no arm, deploy, rollback or candidate-acquisition capability;
   - fail closed on stale authority, wrong image, runtime drift, health failure or unsupported workload class;
   - add positive and negative regression tests before host installation.

2. ⬜ **Implement the first steady-state inspector for Homepage on TestServer.**
   - current version: `2.1.2`;
   - exact immutable image: `ghcr.io/gethomepage/homepage@sha256:da9dca9ec258c628146bed1445da0853f2b88f0b10bafd97c091de807c363d60`;
   - exact local image ID: `sha256:3a2b25796deabbf5c77ed9efcca2e1cb270b64f00c70ca87cf797640e26705fe`;
   - retain the reviewed medium-risk read-only `/var/run/docker.sock` contract;
   - prove health `healthy`, restart count and runtime invariants without mutation;
   - prove the inspector cannot arm, deploy, rollback, pull or recreate anything.

3. ⬜ **Integrate the steady-state inspector into `homelab-update --action inspect`.**
   - caller still supplies only service/version/approved hosts/action;
   - backend selection must come from reviewed catalogue data;
   - contact only targets explicitly marked inspect-ready;
   - blocked targets must fail before host contact and report the exact blocker;
   - keep `prepare`, `deploy` and `rollback` unavailable.

4. ⬜ **Resolve TestServer shared authority roll-forward debt.**
   - Dashy and Prometheus transition manifests record older docker-env authority than the current authority checkout;
   - verify each relevant Compose file against the current authority revision before changing metadata;
   - Dashy also needs the dashboards Compose SHA rolled forward because the Homepage image-variable change modified the shared Compose file;
   - Prometheus monitoring Compose content should be checked independently rather than assuming only the revision changed;
   - do not rewrite historical consumed transaction evidence; create reviewed current-state/steady-state authority instead.

5. ⬜ **Make Prometheus/TestServer steady-state inspectable after authority reconciliation.**
   - current application version `3.13.2`;
   - preserve exact immutable candidate/live identity from the completed pilot;
   - prove TSDB directory, config files, ports, network, user and readiness contract;
   - keep Build #6's historical Jenkins result unchanged; document that the deployment succeeded and the comparison defect was fixed separately.

## P1 — second Docker host / cross-architecture proof

6. ⬜ **Design and review the ids-01 read-only Stage 6 inspection transport.**
   - host `ids-01`;
   - platform `linux/amd64`;
   - no broad SSH/sudo or Docker authority;
   - mirror the separate inspector/executor trust model even though this phase is inspection-only;
   - pin host key/identity and root-owned helper/config locations;
   - install nothing until source and negative tests pass.

7. ⬜ **Use Prometheus as the first ids-01 / amd64 proof.**
   - current ids-01 Prometheus: `3.13.1`;
   - estate desired version: `3.13.2`;
   - first prove read-only current-state inspection and cross-host reporting;
   - then separately acquire/verify the amd64 3.13.2 candidate;
   - only after complete review extend human-approved deployment to ids-01;
   - never assume the ARM64 platform manifest digest is valid for AMD64.

8. ⬜ **Add Blackbox Exporter as a no-change cross-host reporting case.**
   - TestServer and ids-01 both currently run `0.28.0`;
   - use it to prove same semantic version with architecture-specific runtime/image evidence;
   - do not perform a no-op deployment merely to exercise the framework.

## P1 — Kubernetes backend

9. ⬜ **Design a read-only Kubernetes inspection backend for k3s-node-01.**
   - inspection only in the first increment;
   - no apply, patch, rollout, Helm upgrade or resource mutation capability;
   - use reviewed namespace/kind/name/image identity from the estate catalogue;
   - report generation/observedGeneration, desired/ready replicas, current image and imageID;
   - fail closed on ownership/authority ambiguity or workload drift.

10. ⬜ **Use `demo/whoami` as the first Kubernetes inspection pilot.**
    - Deployment `demo/whoami`;
    - two replicas currently ready;
    - Deployment and active ReplicaSet are digest-pinned to `sha256:c4717a8d1f0134a7444e24f881160e033991f23027c6c5a9a3f8fd22e70d1d44`;
    - distinguish direct-manifest authority from Helm-managed resources;
    - no Kubernetes mutation in this pilot.

11. ⬜ **Keep platform/network-critical Kubernetes workloads outside generic mutation.**
    - CoreDNS, local-path-provisioner, metrics-server and Traefik remain platform-managed;
    - MetalLB remains pinned/manual pending a dedicated Helm/network-critical contract;
    - host-network MetalLB components must not be treated as ordinary application workloads;
    - ArgoCD namespace presence must not be described as GitOps authority while `argoproj.io` CRDs/Applications are absent.

## P1 — estate coverage classification

12. ⬜ **Continue classification of the remaining Docker estate.**
    - standard registry candidates;
    - medium-risk read-only Docker socket candidates;
    - stateful workloads;
    - local-build provenance workloads;
    - privileged/device workloads;
    - host-network workloads;
    - writable Docker socket workloads;
    - proxy/DNS/backup/security-critical coupled services.

13. ⬜ **Do not weaken policy for Portainer/WUD/cAdvisor/etc.**
    - TestServer Portainer, Portainer Agent and WUD use writable Docker socket access;
    - cAdvisor is privileged/device-backed;
    - BirdNET-Go is device-backed;
    - `crowdsec-exporter` uses host networking and a local build;
    - these require explicit new contracts or deliberate manual/pinned status.

## Daily operational step

14. 🔁 **Review the 29 August nightly homelab report when it arrives around 08:00.**
    - triage security, patching, backup, monitoring and health findings;
    - add only new evidence-backed actions;
    - deduplicate against this list;
    - update `daily-actions.md` with the result.

## Secondary backlog — keep visible, do not displace P0

15. ⬜ **Tidy Jenkins dashboard/folder organisation.**
    - group service update jobs by container/service;
    - keep control-plane/admin jobs separate;
    - preserve history, credentials, triggers, parameters and security boundaries;
    - archive obsolete smoke/debug jobs only after evidence is retained.

16. ⬜ **Plan the Proxmox VM Infrastructure-as-Code project.**
    - Terraform for Proxmox VM provisioning;
    - Ansible for PostgreSQL, TimescaleDB and Nginx configuration;
    - define sizing, storage, networking, DNS, backup/restore, monitoring and secrets model;
    - use reviewed Git/IaC with reproducible rebuild/recovery acceptance tests.

17. ⬜ **Plan phased migration of the current Docker platform to Proxmox.**
    - inventory dependencies and state;
    - define target VM/LXC/Docker architecture;
    - plan migration waves, parallel validation, data movement, DNS/ingress cutover and rollback;
    - use the VM/IaC project as the Terraform/Ansible proving ground.

18. ⬜ **Publish Homelab Defender through the controlled external route.**
    - expose only the intended application surface;
    - keep Jenkins, registry and Kubernetes controls private;
    - validate external TLS/application behaviour before linking from the Engineering Portfolio.

19. ⬜ **Audit Grafana Host Overview coverage.**
    - establish intended host list;
    - distinguish collection gaps from dashboard-query/variable gaps;
    - validate deliberate exclusions and final host count.

## Definition of a good stopping point today

A clean stopping point is reached when the work completed during the day is merged/reviewed, live runtime state is known, no partial authority is left armed, no unreviewed host changes remain, and every unfinished item has an explicit next safe action recorded here.
