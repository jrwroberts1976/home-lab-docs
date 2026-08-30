# Nginx Proxy Manager — Reverse Proxy and TLS Edge

## Purpose

Nginx Proxy Manager (NPM) provides the reverse-proxy and TLS termination layer for published homelab web services. It maps user-facing hostnames to internal applications and is part of the access path for services protected by Authelia.

## Current homelab role

NPM runs on TestServer (`main`).

```text
Internet / LAN client
        |
        v
Nginx Proxy Manager
        |
        +--> TLS termination
        +--> hostname routing
        +--> access integration
        |
        v
Authelia where required
        |
        v
published application
```

## Dependencies

NPM depends on Docker, DNS records, certificate issuance/renewal, upstream application reachability and protected API/authentication material where automation is used.

## Monitoring and health

Validate:

- the NPM container is healthy;
- the management interface is reachable from the intended network;
- representative proxy hosts return the expected application;
- TLS certificates are valid and not close to expiry;
- upstream applications are reachable from NPM;
- protected routes still enforce Authelia where intended.

## Backup and recovery

Recovery requires more than recreating the container. Preserve/restore:

- authoritative Compose definition;
- NPM persistent configuration/database;
- certificate state where applicable;
- proxy-host configuration;
- protected API/token recovery sources used by automation.

The homelab has an established SOPS synchronisation procedure for the NPM API token so the protected live token and encrypted recovery source remain aligned.

## Security

NPM is part of the external access boundary. Administrative access must be protected. API tokens and credentials must remain outside plaintext Git. Changes to proxy routing can unintentionally expose internal services, so review public hostnames and access policy together.

## Change and maintenance rules

- Test both direct application health and proxied health.
- Validate authentication on protected services after proxy changes.
- Keep certificate and DNS dependencies in mind during incidents.
- Use the documented token rotation/synchronisation process.

## Related documentation

- [Authelia](authelia.md)
- [NPM API token rotation](../procedures/npm-api-token-rotation.md)
- [NPM token SOPS synchronisation](../procedures/npm-token-sops-synchronisation.md)
- [SOPS and age secret recovery](sops-and-age-secret-recovery.md)
- [Docker Container Inventory](docker-container-inventory.md)
