# Authelia — Authentication and Access Control

## Purpose

Authelia provides authentication and access-control protection for selected web services published through Nginx Proxy Manager. It reduces direct exposure of administrative or private applications by inserting a dedicated identity and policy layer.

## Current homelab role

Authelia runs on TestServer (`main`) and is used where a proxy host requires authentication before the upstream application is reached.

```text
client
  |
  v
Nginx Proxy Manager
  |
  v
Authelia policy/authentication
  |
  v
protected application
```

## Dependencies

Authelia depends on its configuration, identity/credential backend, session and secret material, network connectivity and correct reverse-proxy integration. NPM must forward the required authentication requests/headers correctly.

## Monitoring and health

Validate:

- the Authelia container is running;
- the service responds on its internal endpoint;
- a protected application redirects to authentication as expected;
- successful authentication returns the user to the application;
- an unauthorised request remains blocked;
- logs do not show configuration or backend failures.

## Backup and recovery

Recovery must restore the authoritative container/configuration, protected secrets and any persistent identity/state data used by the deployment. After restore, test a protected application end to end rather than only checking the Authelia container.

## Security

Authelia is a security control. Session secrets, storage/encryption keys and identity credentials must never be committed in plaintext. Changes to access rules should fail closed wherever practical and should be reviewed together with NPM routing.

## Change and maintenance rules

- Test both allowed and denied access after policy changes.
- Keep secrets outside Git.
- Avoid bypassing Authelia by exposing the protected upstream directly.
- Validate proxy/auth integration after NPM or application migrations.

## Related documentation

- [Nginx Proxy Manager](nginx-proxy-manager.md)
- [SOPS and age secret recovery](sops-and-age-secret-recovery.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
