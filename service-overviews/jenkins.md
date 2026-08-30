# Jenkins — CI/CD Controller and Docker Build Runtime

## Purpose

Jenkins provides the homelab CI/CD orchestration layer for engineering projects and controlled delivery workflows. The Docker container inventory includes both `jenkins` and `jenkins-docker`; this page covers the logical Jenkins service including its Docker-in-Docker (DinD) build runtime.

## Current homelab role

Both containers run on TestServer (`main`).

```text
Git repositories
      |
      v
   Jenkins
      |
      +--> build / test / package
      +--> security gates
      +--> approval workflows
      |
      v
jenkins-docker (DinD)
      |
      +--> container build
      +--> registry interaction
      +--> controlled delivery tooling
```

Jenkins is an automation/orchestration layer. It must not become the only recovery path for infrastructure or applications; manually executable, documented workflows remain required.

## Dependencies

Jenkins depends on Docker, persistent Jenkins home data, Git/repository access, build credentials, the DinD service and any downstream deployment endpoints used by pipelines.

## Monitoring and health

Validate:

- both Jenkins and `jenkins-docker` are running;
- the controller UI is reachable;
- Jenkins can communicate with its Docker build runtime;
- representative jobs can check out code and run;
- credentials remain available without appearing in logs;
- controlled deployment jobs retain their approval and restricted-authority gates.

## Backup and recovery

Recovery must preserve or reconstruct:

- Jenkins home/configuration;
- plugin and tool requirements;
- credentials from protected recovery sources;
- job/pipeline definitions, preferably from Git;
- DinD/runtime configuration;
- registry/deployment connectivity.

A clean pipeline run should be part of recovery acceptance.

## Security

Jenkins can become a high-authority system. Credentials, Docker access and deployment identities must be tightly scoped. Human approval and restricted host-side executors are used where production mutation is possible. Unrestricted shell/Docker authority should not be introduced merely for convenience.

## Change and maintenance rules

- Keep pipeline definitions in Git where practical.
- Separate build authority from production mutation authority.
- Validate upgrades against representative pipelines.
- Preserve a manual recovery path for IaC and production services.

## Related documentation

- [Jenkins Operations](../jenkins/README.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [OpenTofu](opentofu.md)
- [Service Overviews index](README.md)
