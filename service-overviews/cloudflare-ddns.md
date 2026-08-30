# Cloudflare DDNS — Dynamic Cloudflare DNS Updates

## Purpose

Cloudflare DDNS keeps selected Cloudflare DNS records aligned with the homelab's current public address so externally published services continue to resolve correctly when the WAN IP changes.

## Current homelab role

The `cloudflare-ddns` container runs on TestServer (`main`).

```text
current public IP
      |
      v
Cloudflare DDNS updater
      |
      v
Cloudflare DNS API
      |
      v
published DNS records
```

## Dependencies

The service depends on outbound internet access, Cloudflare API access, the intended zone/record configuration and a protected API token with only the permissions required to update the relevant DNS records.

## Monitoring and health

A useful health check verifies:

- the updater container is running;
- recent API updates have not failed;
- the Cloudflare record resolves to the expected public IP;
- downstream reverse-proxy endpoints still resolve and respond.

## Backup and recovery

Restore the authoritative Compose/configuration and protected Cloudflare credential, then verify a real record update or no-change reconciliation. The Cloudflare zone itself remains external service state and should be documented separately from the container.

## Security

Use a narrowly scoped Cloudflare API token rather than a broad account credential. Do not store the token in plaintext Git or expose it through logs. DNS correctness does not replace access control on the published application.

## Change and maintenance rules

- Keep the managed record list explicit.
- Verify the updater after router/WAN changes.
- Review whether DuckDNS and Cloudflare DDNS still have distinct purposes as the external access design evolves.

## Related documentation

- [DuckDNS](duckdns.md)
- [Nginx Proxy Manager](nginx-proxy-manager.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
