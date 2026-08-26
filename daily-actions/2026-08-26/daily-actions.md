# Daily Homelab Actions — 26 August 2026

Operational incident review, secrets-recovery follow-up, procedure documentation and GitHub repository consolidation.

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

## Priority follow-up

1. Validate Jenkins credential handling and log masking, then run a fresh end-to-end delivery test against the Kubernetes-owned desired state.
2. Reconcile the successful Jenkins release into `kubernetes-homelab` and complete the delivery documentation.
3. Review and separately commit the preserved Terraform course addition in `training-platform-manager`.
4. Continue watching for Linux exporter availability recurrence and identify the affected instance if it returns.
