# DuckDNS — Dynamic DNS

## Purpose

DuckDNS keeps the homelab's DuckDNS hostname aligned with the current public IP address where that dynamic DNS path is still used.

## Current homelab role

The DuckDNS updater runs on TestServer (`main`). It periodically communicates with DuckDNS so external DNS does not retain an obsolete residential WAN address after an ISP address change.

```text
current public IP
      |
      v
 DuckDNS updater
      |
      v
 DuckDNS record
      |
      v
 external clients
```

## Dependencies

The updater depends on outbound internet/DNS access, a valid DuckDNS token and the external DNS service itself.

## Monitoring and health

Health should prove the record is correct, not only that the container is running. Compare the expected/public WAN address with the resolved DuckDNS record and inspect updater logs for failed API calls.

## Backup and recovery

The service is configuration-driven. Preserve the Compose definition and protected token source. After recovery, force or wait for an update and confirm DNS resolves to the correct public IP.

## Security

The DuckDNS token is a credential and must not be committed to plaintext Git or exposed in logs. The existence of a DNS record does not itself control access; published services still require appropriate reverse-proxy, TLS and authentication controls.

## Change and maintenance rules

- Confirm the service is still required before retaining multiple DDNS mechanisms.
- Verify record correctness after WAN/router changes.
- Keep tokens protected and rotate them if exposed.

## Related documentation

- [Cloudflare DDNS](cloudflare-ddns.md)
- [Nginx Proxy Manager](nginx-proxy-manager.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
