# BirdNET-Go — Bird Audio Detection

## Purpose

BirdNET-Go provides automated bird-sound detection for the homelab. It listens to a connected audio source, analyses captured sound for bird vocalisations, records detections and makes the resulting observations available for review.

The service is useful both as a practical home application and as an engineering workload because it combines:

- continuous audio capture;
- local processing/inference;
- persistent application data;
- a web/service interface;
- host resource usage;
- monitoring and recovery requirements.

The homelab objective is to run BirdNET-Go as a managed service with clear placement, monitoring, backup and recovery rather than as an undocumented standalone application.

## Current and target state

The current Docker inventory records a bird-detection workload named:

```text
birdnet
```

on TestServer.

The planned target architecture is different. The homelab project register defines a Raspberry Pi 4 in the garden room as the future combined host for:

```text
BirdNET-Go
Pi-hole
Unbound
monitoring
```

over wired Cat 6 Ethernet.

The target move is not complete until the service has been installed, tested in the garden room, and proven to coexist safely with the DNS workload.

This Service Overview therefore distinguishes between:

- **current workload:** bird-detection service on TestServer;
- **target workload:** BirdNET-Go on the garden-room Raspberry Pi 4.

## Target architecture

The planned BirdNET-Go path is:

```text
outdoor / garden audio
        |
        v
microphone / audio input
        |
        v
BirdNET-Go on Raspberry Pi 4
        |
        +--> local bird detections
        +--> application data / history
        +--> web interface
        |
        +--> host/service monitoring
        |       |
        |       v
        |   Prometheus
        |       |
        |       v
        |     Grafana
        |
        v
wired Cat 6 LAN
```

The same Pi 4 is also planned to run Pi-hole and Unbound, so the final architecture must prove that BirdNET-Go's continuous audio/inference workload does not reduce DNS reliability.

## Why the garden-room Pi 4 is the target

Bird audio capture benefits from being physically close to the microphone and the area being monitored.

Using the garden-room Pi 4 provides:

- a suitable physical location for audio capture;
- wired Cat 6 rather than depending on Wi-Fi;
- a dedicated edge-compute location close to the source;
- an opportunity to reuse the Pi as part of the resilient DNS design;
- separation from future Proxmox-hosted server workloads.

The trade-off is that BirdNET-Go becomes a co-tenant with an infrastructure service. That makes resource and stability testing mandatory.

## Service dependencies

BirdNET-Go depends on more than the application process itself.

Important dependencies include:

- a supported microphone/audio device;
- stable USB/audio-device enumeration where applicable;
- host CPU capacity for continuous inference;
- sufficient RAM;
- local storage for configuration and detection data;
- correct system time;
- wired LAN connectivity for administration and monitoring;
- DNS/network access where the application requires external metadata or integrations;
- a stable service/container definition;
- monitoring of the host and application lifecycle.

A failure in the microphone path can leave the application technically running while producing no useful detections, so audio-input health is a separate concern from process health.

## Co-location with Pi-hole and Unbound

The planned Pi 4 has two very different responsibilities:

```text
BirdNET-Go = CPU/audio/application workload
Pi-hole + Unbound = infrastructure/DNS workload
```

DNS availability takes priority over bird-detection throughput.

Before the Pi 4 is accepted in the combined role, test:

- BirdNET-Go running continuously;
- Pi-hole query handling under normal household load;
- Unbound recursive resolution;
- CPU load during frequent bird detections;
- RAM usage;
- CPU temperature and throttling;
- storage growth;
- network latency;
- DNS response behaviour while BirdNET-Go is busy;
- service restart/recovery behaviour.

If BirdNET-Go causes material DNS latency, instability or thermal pressure, the workloads should be separated rather than weakening the DNS service objective.

## Monitoring requirements

The target host should be monitored through the same Prometheus/Grafana platform as the rest of the homelab.

At minimum, monitor:

### Host health

- host `up` state;
- CPU usage/load;
- RAM and swap;
- filesystem capacity;
- network errors/throughput;
- CPU temperature;
- throttling/thermal events where available;
- uptime/reboots.

### BirdNET-Go service health

- process/container running state;
- expected listener/web interface reachability;
- restart count where available;
- recent application errors;
- detection/output freshness where it can be measured reliably;
- microphone/audio-input failures.

### DNS co-tenant health

Because Pi-hole and Unbound are planned on the same Pi, retain independent checks for:

- Pi-hole availability;
- Unbound availability;
- DNS query success;
- policy/blocking enforcement;
- collector freshness.

BirdNET-Go being healthy must never mask a failing DNS service, and vice versa.

## Detection freshness

A simple process-up metric cannot prove that BirdNET-Go is hearing usable audio.

A more meaningful future control would distinguish:

```text
application running
```

from:

```text
audio pipeline active
```

and, where appropriate:

```text
recent detection/output activity
```

Care is required because an absence of bird detections can be completely normal. A freshness alert should therefore monitor the audio/input pipeline or application processing activity rather than assuming that there must always be a bird detection within a fixed period.

## Storage and data lifecycle

BirdNET-Go can create several types of data with very different recovery value.

Possible data classes include:

- application configuration;
- species/model settings;
- location/settings metadata;
- detection database/history;
- generated clips or recordings;
- raw or temporary audio;
- logs and caches.

These should not all receive the same backup policy.

A sensible recovery priority is:

1. configuration required to recreate the service;
2. detection/history data that is considered worth preserving;
3. selected recordings/clips where they have long-term value;
4. transient caches/raw audio only if there is an explicit reason to retain them.

Do not back up unlimited raw audio by default without first understanding storage growth and retention requirements.

## Backup and recovery

Before the Pi 4 migration is considered complete, define exactly which BirdNET-Go paths are persistent and which are disposable.

The recovery design should make it possible to:

- rebuild the Pi OS/base host;
- restore the BirdNET-Go service definition;
- restore configuration;
- reconnect the microphone/audio device;
- restore detection data if required;
- restart the service;
- verify the web/service interface;
- verify fresh audio processing;
- verify Pi-hole/Unbound still operate correctly.

Where configuration can be represented safely in Git, Git should be the primary configuration source. Secrets or private tokens must remain outside plaintext Git.

Restic can be used for persistent data that cannot be recreated from configuration, subject to an explicit backup scope and restore test.

## Security and privacy

BirdNET-Go processes microphone audio, so its security model should account for audio capture as well as normal web-service exposure.

Controls should include:

- keep the service LAN-only unless external access is deliberately required;
- if published externally, place it behind the established reverse-proxy/authentication controls;
- avoid exposing microphone/audio streams unnecessarily;
- protect any API tokens or external-service credentials;
- limit filesystem/device permissions to what the application requires;
- keep software/container updates under the same controlled version-management process as other homelab workloads;
- document what audio or clips are retained and for how long.

The microphone should be positioned and configured for garden bird detection rather than unnecessary indoor/private audio capture.

## Availability expectations

BirdNET-Go is not a critical infrastructure service. If it is unavailable, DNS and other household infrastructure should continue operating normally.

However, once the Pi 4 becomes a DNS host, failure of the shared host has a different impact:

```text
BirdNET-Go outage only      -> low infrastructure impact
Pi 4 host outage            -> BirdNET-Go + one DNS node unavailable
```

The wider DNS design therefore relies on an independent second Pi-hole/Unbound node so the household does not depend on the BirdNET host remaining online.

## Migration acceptance gates

The BirdNET-Go migration should not be closed simply because the application starts.

Acceptance should include:

- [ ] Raspberry Pi 4 prepared for its final role;
- [ ] BirdNET-Go installed/configured;
- [ ] microphone/audio capture confirmed;
- [ ] wired Cat 6 link confirmed in the garden room;
- [ ] BirdNET-Go web/service interface reachable;
- [ ] real bird detections observed;
- [ ] Pi-hole configured on the same host;
- [ ] Unbound configured on the same host;
- [ ] monitoring/exporters installed;
- [ ] CPU/RAM/temperature measured under combined load;
- [ ] storage growth understood;
- [ ] BirdNET-Go and DNS tested concurrently;
- [ ] DNS failover tested with the Pi 4 offline;
- [ ] BirdNET-Go recovery path documented;
- [ ] backup scope defined and restore-tested where required.

## Operational checks

The exact commands will depend on whether the final BirdNET-Go deployment uses Docker or a native/systemd installation. The operational checks should nevertheless cover the same layers.

### Host

```bash
uptime
free -h
df -h
ip -br addr
```

### Audio hardware

Confirm the expected microphone/input device exists and remains the device BirdNET-Go is configured to use.

### Service

Verify the BirdNET-Go process/container is running and inspect recent logs for audio-device, model or database errors.

### Network/interface

Confirm the application interface responds from the LAN and that the host remains reachable over wired Ethernet.

### Monitoring

Confirm the Pi 4's Node Exporter target is `up=1` in Prometheus and that any BirdNET-Go-specific service checks are current.

### DNS coexistence

Run representative DNS queries through both Pi-hole/Unbound nodes while BirdNET-Go is actively processing audio.

## Common failure modes

### Service running but no detections

Check:

- microphone/input device;
- permissions on the audio device;
- input gain/levels;
- application logs;
- model/configuration;
- whether the configured audio device changed after reboot.

### High CPU or temperature

Check inference load, model settings, cooling and concurrent DNS workload. Do not accept sustained thermal throttling on a combined DNS/BirdNET host.

### Storage fills unexpectedly

Identify whether recordings, clips, logs or database files are growing. Apply an explicit retention policy rather than manually deleting unknown application files.

### Garden-room network issue

Verify the wired Cat 6 link, negotiated speed, DHCP/static address and switch/router path before treating the application itself as failed.

### BirdNET change impacts DNS

Rollback or stop the BirdNET workload first and prove Pi-hole/Unbound health. DNS resilience is the higher-priority service objective.

## Change rules

1. Keep current and target placement clearly distinguished until migration is complete.
2. Treat DNS reliability as higher priority than BirdNET processing on the shared Pi 4.
3. Test audio capture after every host rebuild, device change or major application update.
4. Monitor CPU, RAM, storage and temperature before accepting the combined workload.
5. Keep the service LAN-only unless deliberate protected publication is required.
6. Define data retention before allowing recordings/history to grow indefinitely.
7. Back up configuration and valued persistent data, not uncontrolled raw/transient data by default.
8. Verify real audio processing, not just process/container state.
9. Maintain independent DNS failover so BirdNET host maintenance does not remove household DNS.
10. Document the final runtime, persistent paths, ports and recovery process once the Pi 4 migration is complete.

## Related documentation

- [Service Overviews index](README.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Prometheus — Metrics Collection and Time-Series Monitoring](prometheus.md)
- [Restic — Backup and Recovery](restic.md)
- [Homelab Master Project Register](../project-register.md)
