# LibreSpeed — Internal Throughput Testing

## Purpose

LibreSpeed provides an internal browser-based network throughput test. It is used for on-demand validation of LAN/client performance without relying on an internet speed-test provider.

## Current homelab role

LibreSpeed runs on TestServer (`main`) and acts as a controlled endpoint for testing client-to-server transfer performance, latency and related browser-visible network characteristics.

## Dependencies

LibreSpeed depends on Docker, LAN reachability and sufficient host/network capacity to avoid the test endpoint itself becoming the bottleneck.

## Monitoring and health

Validate the web interface is reachable and that a representative client can complete a test. Results should be interpreted against the known link speed, Wi-Fi conditions and load on both client and server.

## Backup and recovery

LibreSpeed is primarily stateless/configuration-driven. Restore its Compose definition and recreate the container. Any optional result-history feature should be backed up separately if enabled.

## Security

Keep the test endpoint LAN-only unless there is a deliberate reason to publish it. An externally accessible bandwidth test can consume substantial uplink/downlink capacity and provide unnecessary information about the network.

## Change and maintenance rules

- Do not treat one browser test as a substitute for long-term network monitoring.
- Compare results with SmokePing/router metrics when diagnosing network issues.
- Validate the service after Docker host or network migrations.

## Related documentation

- [SmokePing](smokeping.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [Service Overviews index](README.md)
