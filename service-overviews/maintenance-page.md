# Maintenance Page — Controlled Service-Change Fallback

## Purpose

The Maintenance Page provides a predictable user-facing response while a published application is intentionally unavailable during maintenance or deployment. It prevents users seeing raw proxy errors and provides a controlled fallback path.

## Current homelab role

The `maintenance-page` container runs on TestServer (`main`) and is used with the Engineering Portfolio/Nginx Proxy Manager maintenance workflow.

```text
client
  |
  v
Nginx Proxy Manager
  |
  +--> normal application route
  |
  +--> maintenance-page during controlled change
```

The current Nginx maintenance configuration uses a fallback that serves `index.html` for arbitrary paths, allowing routes such as `/about/` or nonexistent paths to return the maintenance page instead of 404 errors while maintenance mode is active.

## Dependencies

The service depends on Docker, its Nginx/static content configuration and the reverse-proxy switching procedure.

## Monitoring and health

Validate:

- the container is running when required;
- `nginx -t` passes inside the maintenance container;
- `/` and representative nested paths return HTTP 200;
- switching to maintenance does not expose the unavailable upstream;
- switching back restores the real application.

## Backup and recovery

The service is largely configuration/static-content driven. The authoritative Compose and Nginx configuration should remain in Git so it can be recreated quickly. Recovery acceptance is route testing, not merely container startup.

## Security

The maintenance page should contain no sensitive operational detail. It must not create a bypass around authentication or expose internal upstream information.

## Change and maintenance rules

- Keep the all-path fallback behaviour tested.
- Validate both entry into and exit from maintenance mode.
- Treat the page as a resilience/change-control component, not the real application.

## Related documentation

- [Engineering Portfolio](engineering-portfolio.md)
- [Engineering Portfolio Deployment and Maintenance](../engineering-portfolio-deployment.md)
- [Nginx Proxy Manager](nginx-proxy-manager.md)
- [Docker Container Inventory](docker-container-inventory.md)
