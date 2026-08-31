# Jenkins — CI/CD Controller and Controlled Automation Runtime

## Purpose

Jenkins provides the homelab CI/CD and controlled-operations orchestration layer. The Docker inventory includes both `jenkins` and `jenkins-docker`; this page covers the logical Jenkins service including its Docker-in-Docker build runtime and the guarded Stage 6 Docker/Compose service-update workflow.

## Current homelab role

Both Jenkins containers run on TestServer.

```text
Git repositories
      |
      v
   Jenkins
      |
      +--> build / test / package
      +--> security gates
      +--> approval workflows
      +--> Stage 6 reviewed service updates
      |
      v
jenkins-docker (DinD)
      |
      +--> container build
      +--> registry interaction
      +--> controlled delivery tooling
```

Jenkins is an automation/orchestration layer. It must not become the only recovery path for infrastructure or applications; manually executable, documented workflows remain required.

## Stage 6 Docker/Compose service updates

The `homelab-container-version-control` project now has a real generic Jenkins update path rather than being assessment-only.

Current proven controls include:

- Git-reviewed Stage 6 service manifests;
- fixed reviewed host routing for TestServer and `ids-01`;
- strict SSH host-key checking and pinned host fingerprints;
- dedicated inspector and executor credentials;
- read-only pre-approval inspection;
- exact rollback and candidate identity checks;
- runtime, health and protected-container invariants;
- explicit human approval;
- second read-only inspection after approval;
- exact zero-drift comparison;
- executor credential exposure only after approval and zero drift;
- one-shot arm/deploy/disarm authority;
- exact selected-service recreation with `--no-deps --no-build --pull never --force-recreate`;
- reviewed rollback path when deployment acceptance fails;
- Docker health, fixed HTTP and internal `container-http` health strategies.

The pipeline must not accept arbitrary SSH destinations, credentials, container names, Compose paths or image references from the operator.

## Current Stage 6 qualification status

### Loki

The generic multi-host Jenkins route successfully deployed Loki `3.7.7` on `ids-01` and completed the deployment/disarm portion of Stage 6.

That test exposed a separate closure gap: successful runtime deployment did not automatically promote Git Compose authority, the estate catalogue or a steady-state definition.

### Dozzle

Dozzle `10.8.0` was deployed by Jenkins build #13 after human approval and zero-drift proof.

The exact candidate deployment succeeded, but the build subsequently failed during disarm because the transition helper did not yet support the newly added `container-http` terminal-health strategy.

The framework was corrected, and Dozzle was safely disarmed and fully closed without a second recreation. The durable Compose authority, catalogue and steady-state definition now all match the running exact immutable 10.8.0 image.

Dozzle therefore has a final service state of:

```text
SUCCESS_CLOSED
```

but it has **not** yet produced a single clean Jenkins build that performs the complete end-to-end closure itself.

Do not rerun the consumed Dozzle deployment merely to create a green historical build.

## Next Jenkins Stage 6 changes

Two changes are required before the next fresh service update.

### Jenkins-owned candidate acquisition

Jenkins should pull the exact immutable candidate before human approval rather than requiring a separate manual candidate-staging command.

Candidate acquisition must use a new narrowly scoped credential/forced-command identity that can invoke only the reviewed candidate-acquisition helper.

That helper must continue to:

- derive the candidate only from the installed reviewed manifest;
- pull the exact immutable reference rather than a floating tag;
- verify local image/config ID, RepoDigest and platform;
- prove that no container ID, restart count or running state changed;
- perform no Compose deployment or container recreation.

The powerful Stage 6 executor credential must **not** be exposed merely to pull an image before approval. It remains reserved for post-approval arm/deploy/rollback/disarm operations.

Deployment must continue using `--pull never` after candidate verification.

### Closed-state verification

Jenkins also needs a non-mutating `VERIFY_CLOSED` or equivalent action for services that are already completely deployed and closed.

For Dozzle this path should verify, without recreation:

- reviewed catalogue state;
- installed steady-state manifest;
- Git/root-owned authority revision and Compose SHA;
- exact configured immutable image and local image ID;
- runtime invariants;
- health;
- protected-container state.

A useful explicit success result is:

```text
SUCCESS_VERIFIED_CLOSED
```

This will allow the corrected Jenkins control path to be tested against Dozzle without violating its consumed one-shot deployment state.

## Dependencies

Jenkins depends on Docker, persistent Jenkins home data, Git/repository access, build credentials, the DinD service and downstream deployment endpoints used by pipelines.

Stage 6 additionally depends on:

- `homelab-container-version-control` reviewed manifests and framework source;
- `docker-env` as Compose authority;
- root-owned Stage 6 authority/manifests on the target host;
- fixed inspector/executor SSH routes;
- candidate images being verified before deployment;
- service-specific health and rollback definitions.

## Monitoring and health

Validate:

- both Jenkins and `jenkins-docker` are running;
- the controller UI is reachable;
- Jenkins can communicate with its Docker build runtime;
- representative jobs can check out code and run;
- credentials remain available without appearing in logs;
- Stage 6 host-key and credential boundaries remain intact;
- controlled deployment jobs retain approval, zero-drift and one-shot authority gates.

## Backup and recovery

Recovery must preserve or reconstruct:

- Jenkins home/configuration;
- plugin and tool requirements;
- credentials from protected recovery sources;
- job/pipeline definitions from Git;
- DinD/runtime configuration;
- registry/deployment connectivity;
- Stage 6 restricted SSH identities and host-key pins.

A clean representative pipeline run should be part of recovery acceptance. For Stage 6, a read-only verification path should be preferred before any fresh deployment after recovery.

## Security

Jenkins can become a high-authority system. Credentials, Docker access and deployment identities must remain tightly scoped.

Important boundaries are:

- inspector credentials are read-only;
- candidate acquisition must have image-cache-only authority;
- deployment executor credentials remain unavailable until after explicit approval and zero-drift reinspection;
- manifests cannot choose arbitrary credentials or SSH destinations;
- deployment never performs an uncontrolled image pull;
- Jenkins must not become the sole recovery route.

## Change and maintenance rules

- Keep pipeline definitions and Stage 6 framework source in Git.
- Separate inspection, candidate acquisition and deployment authority.
- Validate upgrades against representative pipelines.
- Preserve manual recovery procedures for exceptional failure states.
- Never weaken host-key pinning or credential routing to simplify onboarding.
- Do not bypass the one-shot/consumed update model to repeat an already-successful deployment.
- Record final authority, catalogue and steady-state closure rather than treating container start-up as completion.

## Related documentation

- [Jenkins Operations](../jenkins/README.md)
- [31 August Stage 6 container-update closeout](../daily-actions/2026-08-31/stage6-container-update-closeout.md)
- [Dozzle](dozzle.md)
- [Loki](loki.md)
- [Docker Container Inventory](docker-container-inventory.md)
- [OpenTofu](opentofu.md)
- [Service Overviews index](README.md)
