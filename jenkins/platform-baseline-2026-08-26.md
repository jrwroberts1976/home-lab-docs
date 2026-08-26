# Jenkins Platform Baseline — 26 August 2026

**Status:** PRE-CHANGE BASELINE  
**Host:** TestServer  
**Purpose:** establish the evidence-backed starting position before image pinning, scanner updates, credential-cleanup hardening and a new end-to-end release.

## Baseline summary

The Jenkins delivery path is operational. Build 14 previously completed the entire source-to-Kubernetes path successfully. The controller and DinD engine are current, credential binding is active and no Groovy secret-interpolation warning was found in the latest successful build log.

The baseline also identifies deliberately outstanding work:

- replace floating Jenkins and DinD declarations with controlled version/digest pins;
- update Trivy from `0.72.0` to `0.74.0`;
- refresh and pin application build/runtime bases;
- use a temporary Docker credential directory with guaranteed logout/removal;
- run a new end-to-end release; and
- reconcile the approved tag and digest into the Kubernetes desired-state repository.

## Runtime ownership

| Item | Baseline |
|---|---|
| Compose project | `projects` |
| Compose file | `/home/james/projects/docker-compose.yml` |
| Compose working directory | `/home/james/projects` |
| Controller container | `jenkins` |
| Builder container | `jenkins-docker` |
| Controller data | `/home/james/docker/data/jenkins` |
| DinD data | `/home/james/docker/data/jenkins-docker` |
| DinD TLS client material | `/home/james/docker/data/jenkins-docker-certs` |
| Docker network | external `homelab_apps` |
| Jenkins port | TestServer TCP `8096` |
| Registry | `192.168.2.220:5000` |
| K3s deployment host | `192.168.2.195` |

## Controller baseline

| Evidence | Value |
|---|---|
| Declared custom image | `homelab-jenkins:lts-jdk21` |
| Running image ID | `sha256:6e741be9f639690e44915f54c89d30a1fd2c1fe688b40f1349cb598a262b490f` |
| Jenkins core | `2.568.2` |
| Java line | JDK 21 |
| Upstream base declaration | `jenkins/jenkins:lts-jdk21` |
| Upstream base digest | `sha256:8547df3b0db2803d158ecc9499207a056bb30c23fddc18bb5b4a4dc14e77dd09` |
| Local upstream-base digest | same as current upstream |
| Container state | running for four days at capture |
| Security option | `no-new-privileges:true` |
| PID limit | `256` |

The Jenkins LTS changelog identified `2.568.2` as the current LTS at capture. No core-version upgrade was required.

## Docker-in-Docker baseline

| Evidence | Value |
|---|---|
| Declared image | `docker:dind` |
| Running image ID | `sha256:003cd9eb3b560f4155b9476b6d7f8c87f904a2028a2a8aaca22f860e1a18c4ac` |
| Registry digest | `sha256:12e683a161823b2a839aeea999b9d960e6e1f9a97b1679ad6b441982e2d9cf07` |
| Docker client/server | `29.7.2` |
| API version | `1.55` |
| containerd | `v2.3.3` |
| runc | `1.4.3` |
| Architecture | `linux/arm64` |
| TLS | enabled through `DOCKER_TLS_CERTDIR=/certs` |
| Registry exception | `--insecure-registry=192.168.2.220:5000` |

The running DinD digest matched the current upstream `docker:dind` digest at capture. No engine-version update was required, but the declaration remained floating.

## Pipeline image baseline

| Purpose | Declaration | Baseline state |
|---|---|---|
| Gradle build image | `gradle:9.7.0-jdk21` | local cached digest `sha256:86e1c174075288adf17b93172e07a4f018073735ae317134986c0ad55d0244db`; current upstream digest `sha256:0e7bf60670121777c3366f97e33f5fc26298c31118e38b88043f1d6a7a7f8a74` |
| Gradle Wrapper | `9.7.0` | aligned with Dockerfile builder version |
| Runtime image | `eclipse-temurin:21-jre-jammy` | current upstream digest `sha256:eebd356ad7358b7094758e5787a6726f332917cfd56feab6457c56dab895cdbf`; DinD cached digest capture pending |
| Trivy scanner | `aquasec/trivy:0.72.0` | local digest `sha256:cffe3f5161a47a6823fbd23d985795b3ed72a4c806da4c4df16266c02accdd6f` |
| Trivy candidate | `aquasec/trivy:0.74.0` | upstream digest `sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969`; not locally cached at capture |

The Gradle upstream digest had moved since the locally cached copy. Trivy `0.74.0` was the current upstream release at capture and is the planned scanner update.

## Credential and log-handling baseline

The most recent Jenkins build log was:

```text
/var/jenkins_home/jobs/homelab-defender/branches/main/builds/14/log
```

Evidence:

| Check | Result |
|---|---:|
| Jenkins masking declarations | 2 |
| Groovy secret-interpolation warnings | 0 |
| `REGISTRY_PASSWORD` variable-name mentions | 1 |
| `K3S_SSH_KEY` variable-name mentions | 1 |
| Printed/redacted secret-value markers | 0 |
| Successful completion markers | 1 |

Interpretation:

- Jenkins credential binding was active for registry and SSH credentials.
- The pipeline used single-quoted Groovy shell blocks, avoiding Groovy interpolation of secrets.
- Registry authentication used `--password-stdin`.
- `set +x` disabled shell tracing in both credential-bearing stages.
- No credential value needed to be printed and redacted.
- The temporary SSH key is managed by Jenkins credential binding.

Identified hardening gap: if registry publication fails before `docker logout`, the current script may leave authentication in the agent's default Docker configuration. The planned fix is a mode-`0700` temporary `DOCKER_CONFIG` with an EXIT trap that attempts logout and removes the directory on success or failure.

No credential value, private key or registry password is recorded in this document.

## Delivery and Kubernetes baseline

| Evidence | Value |
|---|---|
| Pipeline repository revision at latest TestServer sync | `5e36490` |
| Last fully automated successful build | Jenkins build `14` |
| Published/deployed image | `192.168.2.220:5000/homelab-defender:14` |
| Namespace | `homelab-defender-test` |
| Deployment | `homelab-defender` |
| Service | private ClusterIP `homelab-defender` |
| Health endpoint | `/healthz` |
| Build 14 Trivy result | 0 HIGH/CRITICAL findings |
| Build 14 health result | passed on attempt 1/15 |
| Rollback evidence | build 13 automatically restored build 12 after transient health failure |

Jenkins may advance the live release only through the restricted `jenkins-deploy` forced command:

```text
deploy BUILD_NUMBER
```

Kubernetes object structure and the approved image tag/digest belong in `jrwroberts1976/kubernetes-homelab/applications/homelab-defender-test`. A successful Jenkins release must be reconciled back into that repository before the desired-state manifest is reapplied.

## Source and recovery observations

The application, pipeline and restricted deploy implementation are Git-owned. At baseline capture, the Jenkins Compose definition and custom controller Dockerfile were located directly under `/home/james/projects` and were not yet identified as belonging to a dedicated Git repository.

This is a recovery gap. Before declaring Jenkins fully documented and reproducible:

1. bring the Compose file and custom controller Dockerfile under controlled Git ownership;
2. document Jenkins data backup and restore;
3. document DinD data/cache recovery expectations;
4. record credential IDs and purpose without recording secret values;
5. validate recovery of jobs, plugins, credentials metadata and build history; and
6. retain a manual recovery path that does not depend on Jenkins itself.

## Update acceptance gates

The baseline will be superseded only after all applicable gates pass:

- pinned Jenkins and DinD references resolve for `linux/arm64`;
- updated Trivy runs successfully against the candidate image;
- Gradle tests and package stages pass;
- candidate application image builds from refreshed pinned bases;
- Trivy reports no policy-breaking HIGH/CRITICAL findings;
- registry credentials are isolated and cleaned on success/failure;
- Jenkins controller data, jobs and credentials remain present after any recreation;
- the new image publishes successfully;
- restricted K3s deployment and rollout pass;
- ClusterIP `/healthz` passes;
- rollback remains available;
- the approved release is reconciled into `kubernetes-homelab`; and
- after-state evidence is added to this documentation area and the daily-actions log.
