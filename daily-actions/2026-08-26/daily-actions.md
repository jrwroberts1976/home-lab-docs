# Daily Homelab Actions — 26 August 2026

Operational incident review, secrets-recovery follow-up, procedure documentation, GitHub repository consolidation and Jenkins/Kubernetes monitoring validation.

## Morning alert review

**Overall status:** NO ACTIVE FIRING ALERT IDENTIFIED

The alert inbox was reviewed without marking, archiving or deleting messages.

### ids-01 high CPU

- Fired at 02:21 BST and resolved at 02:26 BST.
- The alert reported CPU usage above 90% for more than ten minutes.
- The timing coincided with the expected daily Greenbone vulnerability scan on `ids-01`.
- No incident response is required unless the condition persists beyond the scan window or begins recurring outside it.

### Transient Linux exporter availability

Two short `Linux Host Down` alert pairs were identified:

- 21:38–21:43 BST on 25 August;
- 23:02–23:07 BST on 25 August.

Each resolved automatically after approximately five minutes. The alert email template did not include the affected host or exporter instance. This remains a watch item; identify the instance and investigate if it recurs or remains unavailable.

### Redundant Training Platform pipeline

**Status:** COMPLETE

The recurring `docker-env` **Deploy Training Platform** GitHub Actions failures were confirmed to originate from a redundant pipeline and were not an infrastructure incident.

The workflow was retired through `docker-env#14` and merged as `232a364`. Its automatic `main` push, manual-dispatch and `content-updated` repository-dispatch paths were removed. The existing Training Platform retirement record now documents the automation closure and recovery constraints.

No container, image, route, proxy host, runner or service was changed. Preserved source, submodules and Git history remain available, while unrelated repository changes can no longer trigger deployment of the retired platform.

## NPM token recovery-source closure

**Status:** COMPLETE

The protected Nginx Proxy Manager API token was previously rotated through NPM's authenticated refresh route and validated with an expiry in 2036.

The encrypted recovery source passed all remaining controls:

- it contains exactly `NPM_URL`, `NPM_TOKEN` and `NPM_PROXY_ID`;
- SOPS encrypted-file status passed;
- the TestServer operational identity decrypted the candidate;
- the recovered values exactly matched the protected live `npm.env`;
- the encrypted validation package was transferred to DietPi without plaintext;
- the protected DietPi recovery identity independently decrypted the candidate;
- the recovered DietPi checksum matched the protected TestServer source;
- all transferred and decrypted validation material was removed; and
- no credential or private identity was displayed.

The single encrypted source was committed as `5c5d3e9` and merged through `docker-env` pull request `#11`. Merge commit: `a9dbee5`. Issue `docker-env#10` closed as completed.

The recovery validation evidence and final encrypted-source update were subsequently incorporated into `docker-env/main` at `2af459a`.

No container, Nginx Proxy Manager proxy host or service was changed during recovery-source synchronisation.

## NPM operational procedures

Two guarded procedures and reusable scripts were added to `home-lab-docs`.

### SOPS recovery-source synchronisation

- Procedure: `procedures/npm-token-sops-synchronisation.md`
- Script: `scripts/sync-npm-token-sops.sh`
- Pull request: `#22`
- Merge commit: `26e9269`

The script preserves a dirty original `docker-env` checkout, uses protected RAM-backed temporary storage, updates only the encrypted NPM recovery source, validates it with the operational identity and stops before commit or push.

The reusable Docker-repository copy was preserved through `docker-env#13` and merged as `0298931`. The documentation copy was marked executable through `home-lab-docs#27` and merged as `5a6e97a`.

### API-token creation and rotation

- Procedure: `procedures/npm-api-token-rotation.md`
- Script: `scripts/rotate-npm-api-token.sh`
- Pull request: `#23`
- Merge commit: `2808edd`

The script implements the NPM 2.15 two-step token flow: a temporary login token followed by authenticated refresh with `expiry=10y`. It validates the expiry and proxy-host access, installs the protected file atomically and restores the previous file if final validation fails.

No password, API token or private age identity is stored in the documentation.

## GitHub repository consolidation

**Status:** COMPLETE

Repository branches and pull requests were audited against their default `main` branches before deletion. Branches were removed only after ancestry or supersession was established.

### docker-env

- Merged the reusable NPM SOPS synchronisation tool through pull request `#13`.
- Merge commit: `0298931`.
- Removed the completed NPM recovery and documentation branches.
- Preserved the unrelated local Terraform course edit in the nested Training Platform repository.

### home-lab-docs

- Merged the executable-bit correction for `scripts/sync-npm-token-sops.sh` through pull request `#27`.
- Merge commit: `5a6e97a`.
- Removed all completed documentation branches.
- Final remote state: `main` only, with no open pull requests.

### engineering-portfolio

- Merged the production deployment health-wait improvement through pull request `#9`.
- Merge commit: `b917d8f`.
- Closed pull request `#10` as superseded because `main` already contained a newer Container Version Control case study with Stage 2 completion evidence.
- Removed all completed and superseded branches.
- Final remote state: `main` only, with no open pull requests.

### Account-wide branch audit

The 35 repositories available through the connected GitHub account were checked for non-default branches and commits not contained in `main`.

One genuinely unmerged branch was found:

- Repository: `new-server-induction`
- Branch: `agent/add-induction-profiles`
- Outstanding work: 14 commits covering host induction, preflight, hardware detection, Prometheus configuration and role profiles.

The work was merged through `new-server-induction#2` as `7b37e53`. Its branch and two already-merged `jenkins-gradle-delivery-lab` branches were then removed.

Final audit result: no known unmerged remote branches remain in the connected GitHub repositories.

## Engineering Portfolio production deployment

**Status:** COMPLETE

The updated production deployment workflow was exercised after merging the health-wait improvement.

- Change reference: `CHG-20260826-9588`
- Source revision: `b917d8f`
- Astro build: PASS — 26 pages generated
- Container image build: PASS
- Container recreation: PASS
- Application readiness: PASS
- Nginx Proxy Manager connectivity: PASS
- Important route checks: PASS
- Container Version Control project route: PASS
- Maintenance mode removed: PASS
- Normal service restored: PASS

The live service was restored to `engineering-portfolio:80` after validation.

## Jenkins operations documentation

**Status:** BASELINE COMPLETE

A dedicated `jenkins/` operational documentation area was created through `home-lab-docs#30` and merged as `4502ecf`.

The area now records:

- service and source-of-truth ownership across TestServer, `jenkins-gradle-delivery-lab`, `kubernetes-homelab` and `home-lab-docs`;
- the 26 August pre-change Jenkins, DinD, Trivy, Gradle and Temurin baseline;
- current image IDs and registry digests;
- credential-binding and build-log masking evidence;
- the registry credential-cleanup hardening gap;
- update acceptance gates;
- the current build 14 release and rollback evidence; and
- outstanding recovery documentation and Git-ownership requirements.

No Jenkins controller, builder, image, credential, job, registry, Kubernetes resource or service was changed.

## Jenkins / Homelab Defender desired-state alignment and monitoring baseline

**Status:** MONITORING DATA PATH VALIDATED

The `jenkins-gradle-delivery-lab` repository was brought back to a clean, current `main` baseline and its remaining Kubernetes ownership wording was corrected.

- Starting `main`: `5e36490`.
- Documentation branch: `docs/align-kubernetes-ownership`.
- Documentation commit: `81d08eb`.
- Pull request: `jenkins-gradle-delivery-lab#3`.
- Merge commit: `d0e8e8b`.
- Updated files: `README.md` and `BEGINNERS_GUIDE.md` only.

The corrected documentation now records `jrwroberts1976/kubernetes-homelab/applications/homelab-defender-test` as the authoritative Kubernetes desired state, including the approved image tag and digest. The application repository retains the source code, Jenkins delivery workflow and restricted deployment implementation. The retired duplicate manifest is no longer described as authoritative.

### Kubernetes workload baseline

The running Homelab Defender workload was inspected without changing cluster state.

- Node `k3s-node-01`: Ready, K3s `v1.36.2+k3s1`.
- Namespace: `homelab-defender-test`.
- Deployment `homelab-defender`: desired `1`, available `1`, ready `1/1`.
- Pod: Running and ready.
- Current image: build `14` pinned to digest `sha256:325b28fe96cee8f59b3aeabf436923391d2a4df81483895b010cb3f943e8eb4a`.
- Pod restart total: `8`.
- Current pod resource sample: approximately `1m` CPU and `166Mi` memory.
- Kubernetes Metrics API: available through `metrics-server`.
- `kube-state-metrics`: already deployed in the `monitoring` namespace.

`kube-state-metrics` itself showed 31 restarts and the Defender pod showed 8, with both most recently restarting at approximately the same time. This is a watch item because it may indicate a wider node or service event rather than an application-only failure; no root cause was asserted from the snapshot alone.

### Prometheus integration

No additional Kubernetes exporter or Prometheus scrape configuration was required.

The TestServer Prometheus instance was independently validated first:

- Prometheus image: `prom/prometheus:v3.13.1`.
- Host binding: `192.168.2.220:9090`.
- Readiness endpoint: PASS.
- Existing scrape job: `kubernetes-state`.
- Existing target: `192.168.2.211:8080`.
- Target health: `up`.

Prometheus already stores the required Defender metrics:

- `kube_deployment_spec_replicas` = `1`;
- `kube_deployment_status_replicas_available` = `1`;
- `kube_pod_container_status_ready` = `1`; and
- `kube_pod_container_status_restarts_total` = `8`.

### Live Grafana and operational monitoring path

Further inventory established that the live Grafana service runs on `ids-01`, not TestServer.

- Grafana image: `grafana/grafana:13.2.0`.
- Host port: `3001` mapped to container port `3000`.
- Grafana and Prometheus share the `monitoring` Docker network on `ids-01`.
- The provisioned datasource is `http://prometheus:9090`.
- `prometheus` resolves successfully from inside the Grafana container.
- The Prometheus readiness endpoint returns ready from the Grafana network.
- A live Defender query through that datasource returned `kube_deployment_status_replicas_available = 1`.

The live operational path is therefore:

```text
Homelab Defender on k3s-node-01
        |
        v
kube-state-metrics 192.168.2.211:8080
        |
        v
Prometheus on ids-01
        |
        v
Grafana on ids-01
```

The TestServer Prometheus path remains valid, but the Defender dashboard and alerts should use the existing datasource behind the live `ids-01` Grafana service.

### Grafana source ownership

The live `ids-01:/home/james/docker` monitoring tree is deployment state and is not itself a Git checkout.

The `home-lab-docs` repository contains monitoring documentation and runbooks but does not currently hold the live dashboard JSON or alert-rule YAML as deployable source.

`docker-env` already owns stack configuration under `stacks/monitoring`, so reusable Defender Grafana assets should be introduced there under a controlled source layout such as:

```text
stacks/monitoring/grafana/
  dashboards/homelab-defender-kubernetes.json
  alerting/homelab-defender-alerts.yml
```

The proposed paths are not ignored by the current `docker-env` Git rules.

The TestServer and `ids-01` monitoring Compose definitions are materially different host-specific stacks. They must not be made identical merely to remove drift. The Defender monitoring change should add reusable Grafana assets only and leave both host-specific Compose definitions unchanged unless a separate controlled change explicitly addresses them.

A focused record of this architecture is maintained in `jenkins/homelab-defender-monitoring-baseline-2026-08-26.md`.

The next monitoring step remains Grafana-only: add a Homelab Defender operational dashboard and alert rules using the existing Prometheus datasource. Initial alerting should detect unavailable replicas, a not-ready container and **new** restarts, rather than alerting merely because the historical restart counter is already eight.

No Kubernetes object, Prometheus target, Jenkins runtime, registry, Grafana runtime or application deployment was changed during this monitoring validation.

## Priority follow-up

1. Add the Git-owned Homelab Defender Grafana dashboard and alert assets under `docker-env/stacks/monitoring/grafana`, validate them, then deploy only those assets to the existing `ids-01` Grafana mounts.
2. Validate Jenkins credential handling and log masking, then run a fresh end-to-end delivery test against the Kubernetes-owned desired state.
3. Reconcile each future approved Jenkins release tag and digest into `kubernetes-homelab` so Git remains authoritative.
4. Review and separately commit the preserved Terraform course addition in `training-platform-manager`.
5. Continue watching for Linux exporter availability recurrence and identify the affected instance if it returns.
