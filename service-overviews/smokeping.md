# SmokePing — Network Latency and Packet-Loss Monitoring

## Purpose

SmokePing measures network latency and packet-loss behaviour over time. It is used to identify intermittent connectivity problems, jitter and long-running network quality trends that may not be obvious from simple up/down checks.

## Current homelab role

SmokePing runs on TestServer (`main`). It probes configured network targets on a schedule and stores historical latency/loss results for visual review.

```text
network targets
      |
      v
  SmokePing
      |
      +--> latency history
      +--> packet-loss history
      +--> trend evidence
```

## Dependencies

SmokePing depends on Docker, network reachability to probe targets, correct DNS where names are used and persistent storage for historical results/configuration.

## Monitoring and health

Validate:

- the container is running;
- the web interface is reachable;
- expected targets are present;
- graphs continue to receive fresh samples;
- failed probes reflect real reachability problems rather than a stopped collector.

## Backup and recovery

Preserve the authoritative Compose/configuration and persistent data if historical graphs are important. After recovery, confirm new samples are being collected. Loss of historical data does not prevent fresh monitoring but does remove long-term evidence.

## Security

Keep the web interface restricted to intended users/networks. Probe targets and internal hostnames can reveal network topology.

## Change and maintenance rules

- Keep probe targets purposeful and documented.
- Avoid aggressive polling that creates unnecessary traffic.
- Revalidate target names/addresses after network migrations.
- Use SmokePing as trend evidence alongside Prometheus and availability monitoring.

## Related documentation

- [Blackbox Exporter](blackbox-exporter.md)
- [Prometheus](prometheus.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
