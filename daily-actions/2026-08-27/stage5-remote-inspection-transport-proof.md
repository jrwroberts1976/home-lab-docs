# Stage 5 remote inspection transport proof

Date: 2026-08-27

## Status

**PASS — Stage 5 remote inspection transport and denial boundary proven end to end.**

No Stage 5 deployment was performed. Deployment capability remains absent.

## Identity and transport

Jenkins used credential:

- ID: `homelab-stage5-testserver-inspector`
- Username: `homelab-stage5-pilot`
- Public-key fingerprint: `SHA256:nvCBuAboTuAqiBCGj3Rj7DPNQW9um7FZByjKZHH0naI`

Transport path:

- Jenkins validation source: `172.30.255.250`
- TestServer validation destination: `172.30.255.249:22`
- TestServer pinned ED25519 host-key fingerprint: `SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk`
- `StrictHostKeyChecking=yes`
- `IdentitiesOnly=yes`
- `BatchMode=yes`

TestServer journal evidence confirmed successful public-key authentication for `homelab-stage5-pilot` from `172.30.255.250` using the exact expected Stage 5 key fingerprint.

## Trust-file model

The persistent TestServer trust remains root-controlled and readable but not writable by the Stage 5 account:

- `/var/lib/homelab-stage5-pilot/.ssh`: `root:homelab-stage5-pilot`, mode `0750`
- `/var/lib/homelab-stage5-pilot/.ssh/authorized_keys`: `root:homelab-stage5-pilot`, mode `0640`
- Authorized-key options remain `restrict,from="172.30.255.250"`
- The Stage 5 account can traverse/read the trust path but cannot modify `.ssh` or `authorized_keys`.

The account-level sshd policy remains forced through `/usr/local/sbin/homelab-stage5-pilot-ssh` with public-key-only authentication and no TTY, forwarding, agent forwarding, tunnel, user RC, or password authentication.

## Positive-path proof

### Jenkins -> TestServer ping

A temporary Jenkins Pipeline bound the real Stage 5 credential and executed remote `ping`.

Result: **PASS**.

The forced Stage 5 wrapper returned inspection-only readiness JSON including:

- `mode = stage5-inspection-only`
- `inspection.allowed = true`
- `deployment.allowed = false`
- `deployment.performed = false`
- `deploy_command_enabled = false`
- `rollback_command_enabled = false`
- `result = ready`

### Jenkins -> `inspect maintenance-page`

A second temporary Jenkins Pipeline executed `inspect maintenance-page` using the same credential and pinned host identity.

Result: **PASS**.

Jenkins parsed and independently asserted the returned artifact:

- `mode = stage5-preapproval-inspect`
- `artifact = pilot-inspection`
- `pilot_id = stage5-maintenance-page-nginx-1.31.4-20260827`
- `service = maintenance-page`
- `host = TestServer`
- Docker authority commit = `f0430e1d9ee91ba4dfba7db34d0e9f0e201a8883`
- Current immutable rollback digest = `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`
- Candidate immutable digest = `nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913`
- Candidate ARM64 image ID = `sha256:c961b530972080b857d1f447363cc411023cf31727e06e14aba0f76cebee6aa5`
- Rollback ARM64 image ID = `sha256:28c4e91555d001bb0f6b2796e565bfa75302711a0d6e67c5562eb2f7d54d2483`
- `runtime.health_result = pass`
- `approval.required = true`
- `approval.granted = false`
- `inspection.allowed = true`
- `inspection.performed = true`
- `deployment.allowed = false`
- `deployment.performed = false`
- `deploy_command_enabled = false`
- `rollback_command_enabled = false`
- `result = ready-for-human-review`

Protected-state evidence showed Jenkins and Jenkins-Docker container identities/restart counters in the artifact, with no deployment action taken.

## Negative-path proof

A third temporary Jenkins Pipeline used the exact same Stage 5 credential. SSH authentication succeeded first, then the forced Stage 5 wrapper rejected every forbidden request:

- `deploy maintenance-page` -> rejected, return code 2
- `rollback maintenance-page` -> rejected, return code 2
- `inspect jenkins` -> rejected, return code 2
- `docker ps` -> rejected, return code 2
- `shell` -> rejected, return code 2

The TestServer journal contained multiple successful Stage 5 SSH authentication events from `172.30.255.250`, proving rejection occurred after identity authentication at the forced-command boundary rather than through transport failure.

## Post-flight invariants

After positive and negative tests:

- All container IDs and restart counts were unchanged.
- `maintenance-page` remained on exact rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`.
- Stage 5 deployment helper remained absent.
- Stage 5 enable file remained absent.
- Deploy/rollback sudo authority remained absent.
- Temporary Jenkins proof jobs were removed.
- Temporary Jenkins CLI/API-token files were removed.
- No private key material was exposed in logs.

## Jenkins OpenSSH note

An earlier runtime capability check incorrectly invoked `docker exec jenkins command -v ssh`; `command` is a shell builtin, so that check falsely reported that SSH was missing. The corrected check `docker exec jenkins sh -c 'command -v ssh'` proved `/usr/bin/ssh` and `/usr/bin/ssh-keygen` were already present in the unchanged Jenkins container.

`docker-env` PR #17 nevertheless made `openssh-client` an explicit Jenkins image dependency for reproducibility. No Jenkins rebuild or restart was required for this Stage 5 proof.

## Conclusion

The Stage 5 inspection-only remote path is now proven end to end:

`Jenkins credential store -> credentials binding -> pinned SSH transport -> TestServer public-key authentication -> forced Stage 5 wrapper -> inspection authority gate`

The same authenticated identity cannot deploy, roll back, inspect an unapproved service, execute Docker directly, or obtain a shell.

**Stage 5 remote inspection transport phase: COMPLETE.**

**Deployment authority: NOT ENABLED.**
