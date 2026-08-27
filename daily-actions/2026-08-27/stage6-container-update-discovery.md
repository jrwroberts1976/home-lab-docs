# Stage 6 container-update discovery

Date: 2026-08-27

## Purpose

Use a single read-only TestServer inventory to identify which running Docker services are suitable for onboarding into the reusable Jenkins-managed container-update framework proven by the Stage 5 maintenance-page pilot.

## Host snapshot

- Host: `TestServer`
- Architecture: `aarch64`
- Docker: `26.1.5+dfsg1`
- Docker Compose: `2.26.1-4`
- Running containers: `30`
- Total containers: `30`

## Key findings

The inventory produced a first-pass suitability score based on Compose management, immutable image use, health checks, published ports, writable bind mounts, privilege, devices, host networking and Docker-socket access.

Top non-excluded results were:

| Service | Raw score | Initial Stage 6 decision |
|---|---:|---|
| maintenance-page | 80 | Completed Stage 5 pilot; reference implementation |
| cloudflare-ddns | 75 | Hold: public DNS/credential-bearing function is operationally higher risk than its raw score suggests |
| authelia | 73 | Hold: authentication/security control-plane role |
| dashy | 73 | Preferred next generic-service pilot candidate |
| engineering-portfolio | 73 | Separate local-image/build pipeline class |
| projects-jrwroberts-co-uk | 73 | Separate local-image/build pipeline class |
| blackbox-exporter | 70 | Hold initially: monitoring control-plane adjacency |
| librespeed | 68 | Preferred second generic-service pilot candidate |
| duckdns | 65 | Hold: DNS/credential-bearing external update function |
| filebrowser | 63 | Later: multiple writable bind mounts/data sensitivity |
| birdnet-exporter | 60 | Later: local-built image and writable bind mount |
| smokeping | 55 | Later: persistent data/config and `latest` style image reference |

## Recommended first Stage 6 service classes

### Dashy

- Compose project/service: `dashboards/dashy`
- Image: `lissy93/dashy:4.5.13`
- Network: `homelab_apps`
- Running container reports a health check
- One writable configuration bind mount
- No direct published host port in Compose; reached through existing application network/proxy path
- WUD labels already present

Dashy is a useful next step because it extends the Stage 5 pattern to a service with a writable configuration mount and container health check without introducing DNS, authentication, Docker-socket or infrastructure-control-plane risk.

### LibreSpeed

- Compose project/service: `availability/librespeed`
- Image: `ghcr.io/librespeed/speedtest:6.2.1`
- Network: `homelab_apps`
- Running container reports a health check
- One writable configuration bind mount
- No direct published host port in Compose
- WUD labels already present

LibreSpeed is a suitable second Stage 6 service and gives a second external-registry image pattern (`ghcr.io`) while retaining a low operational blast radius.

## Explicit holds / exclusions

Do not use the raw score alone for execution eligibility.

Initial Stage 6 rollout should continue to exclude or hold:

- Jenkins and Jenkins DinD
- registry / CI-CD control plane
- Prometheus, Grafana, Loki, Alloy and other monitoring control-plane services
- Pi-hole / Unbound / DNS-routing infrastructure
- Nginx Proxy Manager / proxy control plane
- CrowdSec / security control plane
- Authelia authentication service
- Portainer
- Docker-socket consumers
- privileged, host-network, host-root-mount or device-access containers
- Cloudflare/DDNS services until the generic framework is proven on lower-risk services

## Git authority finding

The live `/home/james/docker` checkout is not suitable as Stage 6 authority at this point because it is dirty:

- `stacks/maintenance-page/docker-compose.yml` modified
- `stacks/training-platform/training-platform-manager.backup` modified/nested-dirty

The existing Stage 5 authority checkout at `/var/lib/homelab-stage5/authority/docker-env` was clean at commit `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883` during discovery.

Stage 6 should therefore preserve the clean detached Git-authority model rather than trusting the live runtime checkout.

## Stage 6 direction

The reusable framework should define a per-service manifest containing only reviewed data such as:

- service / Compose project identity
- authority repository + exact commit
- Compose file path and configuration hashes
- current / candidate / rollback immutable image identities
- allowed architecture
- exact networks
- exact published-port shape, including none
- exact mount destinations, sources and read/write expectations
- expected health mechanism (Docker health and/or HTTP/TCP probe)
- protected-state invariants
- one-shot pilot ID
- exclusion / risk classification

The Jenkins workflow itself should remain common:

`inspect -> human approval -> re-inspect/drift compare -> bind executor -> arm -> exact service-scoped deploy -> validate -> rollback if required -> disarm -> archive evidence`

No live Stage 6 mutation was performed by the discovery run.
