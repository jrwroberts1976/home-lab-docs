# Engineering Portfolio — Public Project Site

## Purpose

The Engineering Portfolio is the web application/site used to present engineering work, project evidence and professional material. It is a production-style workload in the homelab and is also used to prove guarded deployment and maintenance patterns.

## Current homelab role

The `engineering-portfolio` container runs on TestServer (`main`) and is published through the homelab web edge.

```text
source repository
      |
      v
build / deployment workflow
      |
      v
engineering-portfolio container
      |
      v
Nginx Proxy Manager / TLS
      |
      v
users
```

A separate maintenance-page path can be activated during controlled changes.

## Dependencies

The site depends on Docker, its application image, reverse proxy/DNS/TLS, deployment automation and any external services used by site features such as a contact form.

## Monitoring and health

Validation should include:

- container running state;
- application readiness/health endpoint where configured;
- HTTP response through the normal published route;
- key route smoke tests;
- maintenance-route behaviour during controlled changes.

The deployment workflow deliberately distinguishes Docker `running` from actual application readiness.

## Backup and recovery

The site should be reproducible from its Git repository and deployment configuration. Persistent or external application data, secrets and DNS/proxy configuration must be recovered separately where relevant.

## Security

Treat the public application as internet-facing. Keep dependencies patched, avoid exposing internal administrative interfaces, protect secrets and maintain the reverse-proxy/TLS boundary.

## Change and maintenance rules

- Use guarded deployment/readiness checks.
- Validate representative routes after deployment.
- Use the maintenance page for controlled public-facing changes where appropriate.
- Keep the project-specific README and operational documentation current.

## Related documentation

- [Engineering Portfolio Deployment and Maintenance](../engineering-portfolio-deployment.md)
- [Maintenance Page](maintenance-page.md)
- [Nginx Proxy Manager](nginx-proxy-manager.md)
- [Docker Container Inventory](docker-container-inventory.md)
