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
- final `.ssh` ownership/mode: `root:homelab-stage5-pilot 0750`
- final `authorized_keys` ownership/mode: `root:homelab-stage5-pilot 0640`
- authorized-key restrictions: `restrict,from="172.30.255.250"`
- key type: `ssh-ed25519`
- public key fingerprint: `SHA256:nvCBuAboTuAqiBCGj3Rj7DPNQW9um7FZByjKZHH0naI`

The Stage 5 account can traverse/read the root-controlled SSH trust path, but cannot modify `.ssh` or `authorized_keys`.

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

## Trust readability correction and proof

The identity was initially installed as root-only `.ssh` `0700` and `authorized_keys` `0600`. Remote Jenkins authentication then failed with `Permission denied (publickey)` even though:

- Jenkins bound the correct private key;
- the expected public fingerprint matched;
- the TestServer host-key pin passed; and
- the connection reached TestServer from the expected source `172.30.255.250`.

Diagnosis showed the target account needed read/traverse access to the configured `AuthorizedKeysFile`. The final trust model was therefore corrected to root-owned, group-readable but non-writable permissions:

- `.ssh` -> `root:homelab-stage5-pilot 0750`
- `authorized_keys` -> `root:homelab-stage5-pilot 0640`

The public key is not secret; integrity and write protection are the security boundary. Validation proved the account can traverse/read the path but cannot write either object. The fingerprint and `restrict,from="172.30.255.250"` policy remained unchanged.

## Deployment boundary

Identity creation and trust correction did not enable deployment.

Verified throughout:

- deployment helper `/usr/local/libexec/homelab-stage5-maintenance-page` remains absent
- enable file `/etc/homelab-stage5/maintenance-page.enable` remains absent
- deploy/rollback sudo authority remains absent
- no container ID or restart count changed during identity establishment
- no Stage 5 deployment was performed

## Transport proof status

The subsequent end-to-end Jenkins transport proof is complete and recorded in `stage5-remote-inspection-transport-proof.md`.

The real Jenkins credential now successfully authenticates from `172.30.255.250` and is limited by the forced wrapper. Jenkins has proven:

- `ping` succeeds;
- `inspect maintenance-page` succeeds;
- `deploy maintenance-page` is rejected;
- `rollback maintenance-page` is rejected;
- `inspect jenkins` is rejected;
- `docker ps` is rejected;
- `shell` is rejected.

## Next gate

The next Stage 5 phase is the execution-transition design and preflight. Deployment must remain disabled until the reviewed deployment helper, execution policy, one-shot enable state, sudo boundary, human approval stage, candidate/rollback locality, exact Git authority, health checks, and rollback path are revalidated together and fail closed.
