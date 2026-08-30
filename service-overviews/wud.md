# What's Up Docker (WUD) — Container Image Update Visibility

## Purpose

What's Up Docker (WUD) watches container images and reports whether newer image versions are available. In the homelab it is an **update-discovery** service, not the authority that is allowed to deploy arbitrary container updates.

## Current homelab role

WUD runs on both TestServer (`main`) and `ids-01`. It contributes image-currency information used during maintenance and reporting.

```text
Running container images
        |
        v
       WUD
        |
        +--> update visibility
        +--> reporting / review
        |
        v
controlled image-version workflow
```

The governed container-version-control project remains responsible for increasingly controlled inspection, approval, deployment and rollback. WUD discovering an update is not permission to recreate a production service.

## Dependencies

WUD depends on Docker/container metadata, DNS and outbound access to the relevant image registries. Registry or Docker DNS failures can make images appear unchecked rather than truly current.

## Monitoring and health

Check:

- the WUD container is running;
- scheduled scans complete without errors;
- registry DNS works from inside the container;
- expected containers are discovered;
- update results are fresh.

A recent `ids-01` incident showed that stale Docker DNS state could break external registry lookups until the container was recreated with valid upstream resolvers.

## Backup and recovery

WUD is primarily configuration-driven. Restore the authoritative Compose configuration and any required persistent state, then verify one complete successful scan. Image deployment state belongs to the actual service Compose definitions, not WUD.

## Security

Any Docker API/socket access granted to WUD is security-sensitive because it exposes detailed runtime metadata. WUD should receive only the access required for inspection and should not become an unrestricted deployment path.

## Change and maintenance rules

- Treat WUD as advisory discovery.
- Verify actual running image identity before updating.
- Use controlled, reviewed service-specific deployment workflows.
- Distinguish registry lookup failure from 'no update available'.

## Related documentation

- [Docker Container Inventory](docker-container-inventory.md)
- [Jenkins Operations](../jenkins/README.md)
- [Service Overviews index](README.md)
