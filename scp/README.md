# Service Continuity Plans (SCPs)

This section contains continuity, recovery and rebuild plans for restoring homelab services after failure or disruption.

## Current SCPs

- [Host Recovery Inventory and Rebuild](host-recovery-inventory-and-rebuild.md) — captures the rebuild requirements of a healthy Linux node, produces a recovery evidence bundle, and generates a host-specific recovery SCP from that data.

Each SCP should cover where relevant:

- service scope and criticality
- recovery prerequisites
- dependencies and recovery order
- backup sources and restore steps
- rebuild procedure
- rollback or fallback path
- validation and health checks
- recovery evidence
- known limitations and accepted risks
- links to the related Service Overview and SOPs

The goal is to make recovery reproducible and testable rather than dependent on memory.
