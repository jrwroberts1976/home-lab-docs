# Stage 5 remote inspection identity created

Date: 2026-08-27

## Outcome

The dedicated Stage 5 Jenkins-to-TestServer inspection identity was created successfully after a clean rollback of the first failed attempt.

Persistent Stage 5 inspection trust now consists of:

- Jenkins credential ID: `homelab-stage5-testserver-inspector`
- Jenkins credential username: `homelab-stage5-pilot`
- Jenkins credential scope: `GLOBAL`
- Jenkins credential class: `BasicSSHUserPrivateKey`
- Private key source: `BasicSSHUserPrivateKey$DirectEntryPrivateKeySource`
- Jenkins credential store: `system::system::jenkins`
- Jenkins credential domain: `_`
- TestServer authorized key path: `/var/lib/homelab-stage5-pilot/.ssh/authorized_keys`
- authorized key ownership/mode: `root:root 0600`
- `.ssh` ownership/mode: `root:root 0700`
- authorized-key restrictions: `restrict,from="172.30.255.250"`
- key type: `ssh-ed25519`
- public key fingerprint: `SHA256:nvCBuAboTuAqiBCGj3Rj7DPNQW9um7FZByjKZHH0naI`

The Stage 5 account cannot modify its own `authorized_keys` trust file.

## SSH boundary still enforced

The Stage 5 account-level sshd policy remains in force, including:

- `AuthenticationMethods publickey`
- `PubkeyAuthentication yes`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `PermitTTY no`
- `AllowTcpForwarding no`
- `AllowAgentForwarding no`
- `PermitTunnel no`
- `PermitUserRC no`
- `ForceCommand /usr/local/sbin/homelab-stage5-pilot-ssh`

The authorized key is additionally source-restricted to the Jenkins validation source `172.30.255.250`.

## Jenkins credential storage verification

The private half of the generated ED25519 identity was imported into Jenkins using the supported CLI `create-credentials-by-xml` command against the proven global system store and domain.

The created credential was retrieved through Jenkins in redacted form and verified to contain the expected metadata. The Jenkins on-disk `credentials.xml` did not contain an OpenSSH plaintext private-key block.

All transient private-key files and generated credential XML were deleted after import. Temporary Jenkins API-token authentication material and the temporary Jenkins CLI jar were also deleted.

## Deployment boundary

The identity creation did not enable deployment.

Verified after the write:

- deployment helper `/usr/local/libexec/homelab-stage5-maintenance-page` remains absent
- enable file `/etc/homelab-stage5/maintenance-page.enable` remains absent
- deploy/rollback sudo authority remains absent
- no container ID or restart count changed
- no Stage 5 deployment was performed

## Failed first attempt and rollback

The first identity-creation attempt failed before Jenkins credential creation because the Python invocation omitted the `-` required to execute the heredoc script. Python therefore attempted to execute the Stage 4 XML template and raised `SyntaxError`.

The failure handler removed the newly created `authorized_keys`, and a separate rollback verification proved:

- Stage 5 Jenkins credential absent
- Stage 5 `authorized_keys` absent
- Stage 5 `.ssh` directory absent
- transient private-key directories absent
- temporary Jenkins CLI/auth files absent
- sshd hardening still active
- inspection-only sudo authority still present
- deployment helper and enable file still absent
- maintenance-page still on the rollback image digest

A fresh keypair was generated for the successful retry. The fingerprint from the failed attempt is not valid and must not be reused.

## Next gate

The next step is end-to-end remote inspection proof from Jenkins using credential `homelab-stage5-testserver-inspector` against the dedicated TestServer Stage 5 SSH endpoint. The proof must verify the pinned host key, successful `ping`, successful `inspect maintenance-page`, rejection of deploy/rollback/arbitrary commands, unchanged container state, and continued absence of deployment authority.
