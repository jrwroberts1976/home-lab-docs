# Docker Container Inventory

## Purpose

This page provides a human-readable inventory of the Docker services used by the homelab, what each service does, and where it fits into the network/operations platform.

The inventory is intended to answer a simple question: **what are we running, and why?**

It should be kept alongside the technical service documentation and updated when containers are added, removed, renamed, or repurposed.

> **Scope:** This is a service-purpose inventory, not a replacement for `docker ps`. Container names, image versions, ports and runtime health should be verified against the live hosts when performing an operational change.

## Container inventory

| Host | Container / service | Purpose in the network | Primary role |
|---|---|---|---|
| main | `prometheus` | Collects and stores time-series metrics from the homelab, including hosts, Docker, security controls, service health and Kubernetes state. | Monitoring / metrics |
| main | `loki` | Stores application and infrastructure logs for centralised log search and investigation. | Logging |
| main | `cadvisor` | Exposes Docker container resource and runtime metrics to Prometheus. | Monitoring / Docker telemetry |
| main | `blackbox-exporter` | Performs HTTP/HTTPS, TCP and ICMP-style external/service probes used by Prometheus. | Availability monitoring |
| main | `wud` | Watches container images for available updates and provides image currency information. | Container lifecycle / updates |
| main | `crowdsec` | Detects hostile behaviour and provides threat-prevention decisions for the homelab. | Security / threat prevention |
| main | `birdnet` | Provides BirdNET-based bird-sound detection used by the homelab monitoring/learning environment. | Application / learning |
| main | `uptime-kuma` | Provides service availability and uptime monitoring. | Availability monitoring |
| main | `autokuma` | Automates Uptime Kuma monitor management from homelab service definitions. | Availability automation |
| main | `nginx-proxy-manager` | Provides reverse-proxy and TLS termination for published web services. | Network / reverse proxy |
| main | `authelia` | Provides authentication and access-control protection for services behind the reverse proxy. | Security / authentication |
| main | `duckdns` | Maintains the external DuckDNS record used for dynamic public addressing. | Network / DNS |
| main | `portainer` | Provides Docker management and operational visibility through a web interface. | Docker management |
| main | `portainer-agent` | Provides Docker endpoint access for Portainer management. | Docker management |
| main | `dozzle` | Provides live Docker log viewing for operational troubleshooting. | Logging / operations |
| main | `filebrowser` | Provides web-based access to selected files and directories. | File services |
| main | `smokeping` | Measures network latency and packet-loss behaviour over time. | Network monitoring |
| main | `librespeed` | Provides internal network throughput testing. | Network testing |
| main | `jenkins` | Runs the Jenkins CI/CD controller for the engineering delivery lab. | CI/CD |
| main | `jenkins-docker` | Provides the Docker-in-Docker build environment used by the Jenkins delivery lab. | CI/CD / container builds |
| main | `engineering-portfolio` | Hosts the engineering portfolio application/site. | Web application |
| main | `cloudflare-ddns` | Maintains Cloudflare DNS records for services using dynamic addressing. | Network / DNS |
| main | `maintenance-page` | Provides the maintenance/availability page used during controlled service changes. | Web / change management |
| ids-01 | `prometheus` | Stores the metrics used by the live Grafana service, including the `kubernetes-state` target for Homelab Defender. | Monitoring / metrics |
| ids-01 | `grafana` | Provides the live homelab dashboards, central alert evaluation and email notification service. | Monitoring / visualisation / alerting |
| ids-01 | `loki` | Provides the Loki datasource used by the live Grafana service for central log investigation and log-backed alerting. | Logging |
| ids-01 | `blackbox-exporter` | Provides availability probes from the ids-01 monitoring stack. | Availability monitoring |
| ids-01 | `wud` | Watches ids-01 container images and provides image-update information. | Container lifecycle / updates |
| ids-01 | `cadvisor` | Exposes Docker/container resource metrics from the IDS host to Prometheus. | Monitoring / Docker telemetry |
| ids-01 | `pihole` | Provides secondary DNS filtering and security-policy enforcement for DNS resilience. | DNS / security |
| ids-01 | `unbound` | Provides recursive DNS resolution upstream of the secondary Pi-hole. | DNS / resolver |

## Monitoring topology

The homelab currently has more than one Prometheus instance. TestServer (`main`) has its own Prometheus, and `ids-01` also runs Prometheus as part of the live Grafana monitoring stack.

For Homelab Defender, both Prometheus instances were shown to scrape the same `kube-state-metrics` endpoint successfully, but the live Grafana datasource resolves to the Prometheus container on `ids-01`.

The Defender monitoring path is therefore:

```text
Homelab Defender on k3s-node-01
        |
        v
kube-state-metrics 192.168.2.211:8080
        |
        v
Prometheus on ids-01
        |
        v
Grafana on ids-01
```

The live Grafana Prometheus datasource is:

```text
name: Prometheus
uid: PBFA97CFB590B2093
url: http://prometheus:9090
```

The live Loki datasource is:

```text
name: Loki
uid: P8E80F9AEF21F6940
url: http://loki:3100
```

A more general metrics relationship remains:

```text
Hosts / containers / network devices / Kubernetes state
            |
            +--> node-exporter / cAdvisor / exporters / kube-state-metrics
            |
            v
       Prometheus instance
            |
            +--> Grafana dashboards
            +--> Grafana alerting
            +--> SecOps reporting
```

The central logging path is:

```text
Applications / Docker / security services
            |
            v
       Alloy / log collectors
            |
            v
           Loki
            |
            v
     Grafana on ids-01
```

The network security path includes:

```text
Network traffic
      |
      +--> Suricata on ids-01
      +--> CrowdSec on main
      +--> Pi-hole + Unbound
      |
      v
Prometheus / Loki / SecOps reporting
```

The reverse-proxy path is:

```text
Internet / LAN client
        |
        v
Nginx Proxy Manager
        |
        v
Authelia (where protected)
        |
        v
Published application
```

## Host-specific monitoring stacks

The TestServer and `ids-01` monitoring Compose definitions are materially different and should not be treated as two copies of one host-independent file.

The `ids-01` stack contains Grafana, its own Prometheus and Loki, WUD, Blackbox Exporter and the `monitoring` Docker network. TestServer has a different service composition, bindings and network ownership.

Do not overwrite one host's Compose file with the other merely to remove apparent drift. Shared service definitions or Grafana assets should be handled explicitly while host-specific runtime configuration remains host-specific.

## cAdvisor incident — 22 August 2026

On 22 August 2026, the `ids-01` cAdvisor Prometheus target reported down:

```text
job=cadvisor
host=ids-01
instance=192.168.2.242:8089
up=0
```

Initial Docker inspection showed that the cAdvisor container itself had exited, but its logs showed normal cAdvisor startup and registration of the Docker/systemd factories. After restarting the container, cAdvisor was running, but Prometheus remained unable to scrape it.

The investigation identified an inconsistent Docker network state:

- The container configuration specified `NetworkMode=monitoring`.
- The configured port binding was `192.168.2.242:8089 -> 8080/tcp`.
- The container's runtime network attachment was empty.
- The `monitoring` Docker bridge contained Prometheus, Grafana, Loki, WUD and Blackbox Exporter, but not cAdvisor.

The container was reattached to the `monitoring` network without rebuilding or replacing the image.

After the repair:

```text
Prometheus target:
job=cadvisor
host=ids-01
instance=192.168.2.242:8089
up=1
```

cAdvisor also served its metrics endpoint successfully, confirming that the monitoring path was restored.

### Lesson learned

A container can appear healthy and still be unavailable to Prometheus if its Docker network attachment is missing or inconsistent. For container monitoring incidents, check all three layers:

1. **Container state** — is the container running?
2. **Network state** — is it attached to the expected Docker network?
3. **Scrape state** — can Prometheus reach the expected endpoint and report `up=1`?

A successful container restart alone does not prove that monitoring has recovered.

## Operational checks

For a quick live inventory:

```bash
sudo docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
```

For Docker networks:

```bash
sudo docker network ls
sudo docker network inspect monitoring
```

For Prometheus scrape health, query the Prometheus instance on the host being investigated. On `ids-01`:

```bash
curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=up' | jq .
```

For cAdvisor specifically on `ids-01`:

```bash
sudo docker inspect cadvisor \
  --format '{{json .NetworkSettings.Networks}}' | jq .

sudo ss -ltnp | grep ':8089'

curl -s --max-time 5 \
  http://192.168.2.242:8089/metrics | head

curl -sG 'http://localhost:9090/api/v1/query' \
  --data-urlencode 'query=up{job="cadvisor",host="ids-01"}' | jq .
```

## Maintenance rule

When adding a new container, document:

- host;
- container name;
- purpose;
- network role;
- monitoring/health endpoint where applicable;
- whether it is internet-facing, LAN-only or infrastructure-only;
- dependency on another service;
- backup/recovery importance.

The objective is to make the Docker estate understandable without having to infer purpose from image names, ports or container labels.
