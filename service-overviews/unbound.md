# Unbound — Recursive DNS Resolver

## Purpose

Unbound provides recursive DNS resolution upstream of Pi-hole. It allows the homelab DNS service to resolve internet names through a local recursive resolver rather than relying solely on a public forwarding DNS provider.

## Current homelab role

The Docker inventory records the secondary Unbound service on `ids-01` alongside the secondary Pi-hole. The primary DietPi DNS path also uses Unbound.

```text
LAN client
    |
    v
  Pi-hole
    |
    v
  Unbound
    |
    v
DNS root / authoritative hierarchy
```

The secondary Pi-hole/Unbound stack on `ids-01` uses Docker journald logging so Grafana Alloy can collect stable container-name-selected logs into Loki.

## Dependencies

Unbound depends on network access to the DNS hierarchy, correct local configuration, system time and the host/container networking required to serve Pi-hole on the configured upstream port.

## Monitoring and health

Validate:

- Pi-hole can query Unbound successfully;
- direct test queries to the configured Unbound listener succeed where appropriate;
- response latency is reasonable;
- logs show no persistent resolver failures;
- the Pi-hole DNS service continues to resolve external domains.

## Backup and recovery

Unbound is configuration-driven. Restore its configuration and container/service definition, then verify recursive resolution before declaring Pi-hole recovered. Cached DNS data is disposable and does not need to be restored.

## Security

Keep the resolver scoped to the intended Pi-hole/local network path. Avoid exposing a recursive resolver openly to the internet. Configuration changes should preserve DNSSEC/validation behaviour where enabled and intended.

## Change and maintenance rules

- Test Pi-hole and Unbound together after changes.
- Validate Docker network/DNS behaviour after container recreation.
- Keep primary and secondary resolver configurations aligned where resilience requires equivalent behaviour.

## Related documentation

- [Pi-hole](pihole.md)
- [Nebula Sync](nebula-sync.md)
- [Grafana Alloy](alloy.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
