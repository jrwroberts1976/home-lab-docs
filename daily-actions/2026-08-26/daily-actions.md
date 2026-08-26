# Daily Homelab Actions — 26 August 2026

Operational incident review, secrets-recovery follow-up and procedure documentation.

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

The recurring `docker-env` **Deploy Training Platform** GitHub Actions failures were confirmed to originate from a redundant pipeline and are not an infrastructure incident.

Follow-up: retire or disable the obsolete workflow and document its removal so it no longer generates failure notifications.

## NPM token recovery-source closure

**Status:** IN PROGRESS

The protected Nginx Proxy Manager API token was previously rotated through NPM's authenticated refresh route and validated with an expiry in 2036.

Today's preflight confirmed:

- the protected live file remains readable;
- it contains exactly `NPM_URL`, `NPM_TOKEN` and `NPM_PROXY_ID`;
- the operational age identity is available;
- the existing SOPS source differs from the rotated live token, as expected;
- no private identity was found in the repository; and
- no credential value was displayed.

An existing isolated worktree was identified at:

```text
/var/tmp/docker-env-npm-sops
```

It is registered on branch `security/sync-npm-token-sops`, based on `docker-env/main` commit `28f7208`, and contains one unstaged modification:

```text
secrets/testserver/nginx-proxy-manager.sops.env
```

The candidate must be validated against the protected live source with the operational identity, staged through the exact allowlist, and independently validated using the DietPi recovery identity before commit or push.

No live credential, proxy host, container or service was changed during these checks.

## NPM operational procedures

Two guarded procedures and reusable scripts were added to `home-lab-docs`.

### SOPS recovery-source synchronisation

- Procedure: `procedures/npm-token-sops-synchronisation.md`
- Script: `scripts/sync-npm-token-sops.sh`
- Pull request: `#22`
- Merge commit: `26e9269`

The script preserves a dirty original `docker-env` checkout, uses protected RAM-backed temporary storage, updates only the encrypted NPM recovery source, validates it with the operational identity and stops before commit or push.

### API-token creation and rotation

- Procedure: `procedures/npm-api-token-rotation.md`
- Script: `scripts/rotate-npm-api-token.sh`
- Pull request: `#23`
- Merge commit: `2808edd`

The script implements the NPM 2.15 two-step token flow: a temporary login token followed by authenticated refresh with `expiry=10y`. It validates the expiry and proxy-host access, installs the protected file atomically and restores the previous file if final validation fails.

No password, API token or private age identity is stored in the documentation.

## Priority follow-up

1. Complete the NPM SOPS candidate validation using both approved age identities.
2. Commit and merge the single encrypted recovery-source update against `docker-env` issue 10.
3. Retire the redundant Training Platform workflow.
4. Continue watching for Linux exporter availability recurrence.
5. Begin the Docker image version-control Stage 0 inventory after security-critical recovery closure.
