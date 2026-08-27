# Stage 5 Jenkins Credential Store Verification

Date: 2026-08-27
Host: TestServer

## Result

Read-only verification completed successfully before any Stage 5 SSH identity or Jenkins credential creation.

Proven Jenkins credential target:

- Store ID: `system::system::jenkins`
- Domain: `_` (global)
- Reference credential: `homelab-stage4-testserver-validator`

The Stage 4 reference credential was retrieved through Jenkins CLI using `get-credentials-as-xml` with secrets redacted by Jenkins. Sanitized metadata confirmed:

- Credential element: `com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey`
- Username: `homelab-validator`
- Scope: `GLOBAL`
- Private key source: `BasicSSHUserPrivateKey$DirectEntryPrivateKeySource`

## Safety State

At completion of this verification:

- `homelab-stage5-testserver-inspector` did not exist in Jenkins.
- `/var/lib/homelab-stage5-pilot/.ssh/authorized_keys` did not exist.
- `/usr/local/libexec/homelab-stage5-maintenance-page` did not exist.
- `/etc/homelab-stage5/maintenance-page.enable` did not exist.
- No deploy/rollback sudo authority existed for `homelab-stage5-pilot`.
- No Stage 5 deployment was performed.

This establishes the exact Jenkins store/domain target for the later controlled Stage 5 SSH credential creation without relying on assumed identifiers.