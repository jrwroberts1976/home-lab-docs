# TODO — 29 August 2026

## P0 — Stage 6 estate updater

### Completed today

1. ✅ **Build the steady-state read-only inspection contract.**
   - separate from the pre-approval transition inspector;
   - validates reviewed authority, immutable image identity, runtime shape, mounts, networks, health and protected workloads;
   - contains no arm, deploy, rollback, pull or arbitrary command capability;
   - positive and negative regression coverage completed.

2. ✅ **Make Homepage and Dashy steady-state inspectable on TestServer.**
   - Homepage `2.1.2` proven under the reviewed medium-risk read-only Docker socket exception;
   - Dashy `4.6.0` proven under the standard-registry contract;
   - both route through the estate updater read-only inspection path.

3. ✅ **Integrate steady-state inspection into `homelab-update --action inspect`.**
   - caller-facing inputs remain limited to service/version/approved hosts/action;
   - backend selection comes from reviewed catalogue data;
   - unscoped hosts are not contacted;
   - `prepare`, `deploy` and `rollback` remain fail-closed in the current estate front end.

4. ✅ **Install and prove the ids-01 read-only Stage 6 inspection transport.**
   - fixed-command SSH/sudo boundary retained;
   - no broad shell or Docker authority introduced;
   - ids-01 framework files remain `root:root 0700`;
   - transport wrapper and sudoers boundaries preserved.

5. ✅ **Use Prometheus as the first ids-01 / amd64 Stage 6 proof.**
   - ids-01 Prometheus now `3.13.2`;
   - combined TestServer + ids-01 steady-state inspection passed;
   - both hosts independently proved immutable image/runtime/health invariants;
   - no mutation permitted during steady-state inspection.

6. ✅ **Add a narrow internal-network HTTP health strategy.**
   - `container-http` added for workloads with no reviewed host-published health endpoint;
   - reviewed network must already be declared in runtime networks;
   - container IP is derived at runtime, never hard-coded;
   - fixed URL, undeclared network, invalid port and unsafe path cases fail closed;
   - PR #76 merged as `1f78afcbb9041b4076c63b4d64b133e94f9a0896`;
   - reviewed inspector/validator installed on TestServer and ids-01 with all containers unchanged.

7. ✅ **Prepare Blackbox Exporter source authority on both hosts.**
   - TestServer and ids-01 both run `0.28.0`;
   - added `BLACKBOX_EXPORTER_IMAGE` override in reviewed `docker-env` source;
   - both live Compose files aligned to `docker-env` revision `d1ca9a5e10d151893573fd97d6a5c282ba912a1e`;
   - no image pull, container recreate, restart or deployment performed;
   - both Blackbox instances remain healthy.

8. ✅ **Reconcile the shared steady-state authority metadata in Git source.**
   - Dashy/Homepage retain unchanged dashboards Compose SHA-256;
   - TestServer Prometheus advances to monitoring Compose SHA-256 `b8a895bd8e23c9f528cf9209f70368be42bf53f8044cbd99ef35eae188e3d68b`;
   - ids-01 Prometheus advances to monitoring Compose SHA-256 `128a8e842a2b1bc54b966b93aac9d11ba1d7c0cc7d8eb89282c7f2ffa1f89ae9`;
   - all four steady-state manifests now target `docker-env` revision `d1ca9a5e10d151893573fd97d6a5c282ba912a1e` in reviewed source;
   - PR #77 merged as `60f6bc1d7bc8cbed12011b258bb2f12930f8f454`.

### Immediate open work

9. ⬜ **Roll the installed Stage 6 authority checkout/manifests forward to the merged reviewed state.**
   - target `docker-env` authority: `d1ca9a5e10d151893573fd97d6a5c282ba912a1e`;
   - install the reviewed current steady-state manifests coherently with the authority checkout;
   - preserve root ownership/security modes;
   - do not leave a partial state where manifests and the single authority checkout pin different revisions.

10. ⬜ **Re-prove the existing four inspect-ready instances after authority roll-forward.**
    - Dashy/TestServer `4.6.0`;
    - Homepage/TestServer `2.1.2`;
    - Prometheus/TestServer `3.13.2`;
    - Prometheus/ids-01 `3.13.2`;
    - require read-only success, mutation disabled and protected containers unchanged.

11. ⬜ **Resolve Blackbox immutable configured-image normalization without weakening rollback guarantees.**
    - current running configured image remains `prom/blackbox-exporter:v0.28.0`;
    - steady-state requires the reviewed immutable digest reference;
    - existing generic updater intentionally requires a genuinely different rollback digest/newer candidate and is not a truthful same-image normalization mechanism;
    - either design a separate reviewed tag-to-digest normalization contract with a real rollback model or wait for the next Blackbox release;
    - do not relax candidate/rollback identity checks merely to increase coverage.

12. ⬜ **Complete Blackbox steady-state onboarding only after item 11 is resolved.**
    - add TestServer and ids-01 steady-state manifests;
    - TestServer may use the existing reviewed host HTTP health endpoint;
    - ids-01 should use reviewed `container-http` on network `monitoring`, port `9115`, path `/-/healthy`;
    - add catalogue routing only after immutable runtime identity is true;
    - final target is six inspect-ready service/host instances with no deployment performed by inspection.

## P1 — remaining Docker estate

13. ⬜ **Continue onboarding standard-registry candidates first.**
    - prefer low-risk stateless services with no Docker socket, device, privilege, host networking or critical state;
    - reuse the reviewed steady-state framework wherever the workload already fits it;
    - batch shared framework improvements rather than creating one-off exceptions per service.

14. ⬜ **Continue classification of the remaining Docker estate by risk class.**
    - standard registry;
    - medium-risk read-only Docker socket;
    - stateful registry workloads;
    - local-build provenance workloads;
    - privileged/device workloads;
    - host-network workloads;
    - writable Docker socket workloads;
    - proxy/DNS/backup/security-critical coupled services.

15. ⬜ **Do not weaken policy for Portainer/WUD/cAdvisor/BirdNET/etc.**
    - Portainer and Portainer Agent use writable Docker socket authority;
    - TestServer WUD uses writable Docker socket authority;
    - cAdvisor is privileged/device-backed;
    - BirdNET-Go is device-backed;
    - `crowdsec-exporter` uses host networking and a local build;
    - these need dedicated contracts or deliberate pinned/manual status.

16. ⬜ **Use successful Blackbox normalization, if built, as a reusable onboarding primitive.**
    - the value should be broader than Blackbox alone;
    - target other services that already run the correct image bytes but were started from a mutable/tagged configured image;
    - retain explicit human approval and truthful rollback semantics for any runtime recreation.

## P1 — Kubernetes backend

17. ⬜ **Design a read-only Kubernetes inspection backend for k3s-node-01.**
    - inspection only in the first increment;
    - no apply, patch, rollout, Helm upgrade or resource mutation capability;
    - use reviewed namespace/kind/name/image identity from the estate catalogue;
    - report generation/observedGeneration, desired/ready replicas, current image and imageID;
    - fail closed on ownership/authority ambiguity or workload drift.

18. ⬜ **Use `demo/whoami` as the first Kubernetes inspection pilot.**
    - distinguish direct-manifest authority from Helm-managed resources;
    - verify current digest-pinned Deployment/ReplicaSet identity;
    - no Kubernetes mutation in this pilot.

19. ⬜ **Keep platform/network-critical Kubernetes workloads outside generic mutation.**
    - CoreDNS, local-path-provisioner, metrics-server and Traefik remain platform-managed;
    - MetalLB remains pinned/manual pending a dedicated Helm/network-critical contract;
    - host-network components must not be treated as ordinary application workloads.

## Daily operational step

20. 🔁 **Review the 29 August nightly homelab report.**
    - triage security, patching, backup, monitoring and health findings;
    - add only genuine new evidence-backed actions;
    - deduplicate against this list;
    - update `daily-actions.md` with the result.

## Secondary backlog — keep visible, do not displace P0

21. ⬜ **Tidy Jenkins dashboard/folder organisation.**
    - group service update jobs by container/service;
    - keep control-plane/admin jobs separate;
    - preserve history, credentials, triggers, parameters and security boundaries.

22. ⬜ **Plan the Proxmox VM Infrastructure-as-Code project.**
    - Terraform for Proxmox VM provisioning;
    - Ansible for PostgreSQL, TimescaleDB and Nginx configuration;
    - define sizing, storage, networking, DNS, backup/restore, monitoring and secrets model.

23. ⬜ **Plan phased migration of the current Docker platform to Proxmox.**
    - inventory dependencies and state;
    - define target VM/LXC/Docker architecture;
    - plan migration waves, parallel validation, data movement, DNS/ingress cutover and rollback.

24. ⬜ **Publish Homelab Defender through the controlled external route.**
    - expose only the intended application surface;
    - keep Jenkins, registry and Kubernetes controls private;
    - validate external TLS/application behaviour before linking from the Engineering Portfolio.

25. ⬜ **Audit Grafana Host Overview coverage.**
    - establish intended host list;
    - distinguish collection gaps from dashboard-query/variable gaps;
    - validate deliberate exclusions and final host count.

## Definition of a good stopping point today

A clean stopping point is reached when the installed authority and manifests match reviewed Git source, the four existing steady-state targets have been re-proven, no update is armed, no partial authority state remains, and Blackbox is either safely normalized under a reviewed contract or explicitly left pending with its immutable-image blocker documented.
