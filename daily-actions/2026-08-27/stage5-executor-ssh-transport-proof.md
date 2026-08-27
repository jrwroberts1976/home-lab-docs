# Stage 5 executor SSH transport proof

Date: 2026-08-27

## Result

Stage 5 Jenkins-to-TestServer executor SSH transport is proven while effective deployment authority remains false.

## Proven executor identity

- TestServer account: `homelab-stage5-executor`
- Jenkins credential ID: `homelab-stage5-testserver-executor`
- executor public-key fingerprint: `SHA256:0mY135q5LD0cNgH9UlSwz0IWW7GHOZfEdvWU8YpyPr0`
- Jenkins source: `172.30.255.250`
- TestServer SSH destination: `172.30.255.249:22`
- TestServer host-key fingerprint: `SHA256:PEDpP7QlmSztJSIYHzZ+YuIT7XurmpeWp85wRnlfZuk`
- forced command: `/usr/local/sbin/homelab-stage5-executor-ssh`

## Trust boundary

The executor SSH trust is root-controlled:

- `/var/lib/homelab-stage5-executor/.ssh`: `root:homelab-stage5-executor`, mode `0750`
- `authorized_keys`: `root:homelab-stage5-executor`, mode `0640`
- key option: `restrict,from="172.30.255.250"`
- target account can read but cannot modify the trust files
- executor account is not in the Docker group
- password is locked

The Jenkins credential is `BasicSSHUserPrivateKey`, GLOBAL scope. The plaintext OpenSSH private key is not present in `credentials.xml`.

## Remote proof

A temporary Jenkins job bound the exact executor credential and reported the same fingerprint:

`SHA256:0mY135q5LD0cNgH9UlSwz0IWW7GHOZfEdvWU8YpyPr0`

The forced-command remote `ping` returned:

```json
{
  "schema_version": 1,
  "mode": "stage5-executor",
  "service": "maintenance-page",
  "execution_identity": true,
  "result": "ready"
}
```

TestServer journal evidence recorded an accepted ED25519 public key for `homelab-stage5-executor` from `172.30.255.250` with the exact fingerprint above. The temporary proof job was removed afterward.

## Current safety state

- executor sudo authority: absent
- enable file: absent
- active policy remains exact inspection-ready policy `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`
- Stage 5 inspection identity remains read-only
- container IDs and restart counts unchanged
- maintenance-page not deployed

Effective deployment authority remains **false**.

## Sequencing decision

Do not install the executor `arm maintenance-page` sudo rule yet. Because the Jenkins executor credential and SSH trust now exist, adding that sudo rule would make the pilot armable before the reviewed Jenkins human-approval pipeline is in place. The next gate is therefore a **sudoers rehearsal only**: validate the exact intended four-command rule in a temporary file with `visudo`, while leaving live sudo authority unchanged.
