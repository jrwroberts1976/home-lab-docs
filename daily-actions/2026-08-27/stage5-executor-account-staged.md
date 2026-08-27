# Stage 5 executor account staged — remote authentication disabled

Date: 2026-08-27

## Result

The dedicated Stage 5 executor identity has been created on TestServer, but it still has no remote authentication trust and no execution authority.

## Account

- account: `homelab-stage5-executor`
- uid: `995`
- gid: `982`
- primary group: `homelab-stage5-executor`
- home: `/var/lib/homelab-stage5-executor`
- shell: `/bin/bash`
- password: locked
- Docker group membership: absent
- home owner/mode: `root:root 0755`
- executor cannot write its home
- `.ssh`: absent
- `authorized_keys`: absent

## Installed forced-command SSH policy

File: `/etc/ssh/sshd_config.d/62-homelab-stage5-executor.conf`

Effective for Jenkins source `172.30.255.250`:

- `AuthenticationMethods publickey`
- `PubkeyAuthentication yes`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `X11Forwarding no`
- `AllowAgentForwarding no`
- `AllowTcpForwarding no`
- `PermitTunnel no`
- `PermitTTY no`
- `PermitUserRC no`
- `ForceCommand /usr/local/sbin/homelab-stage5-executor-ssh`

`sshd -t` passed and SSH reload succeeded.

Reviewed executor wrapper SHA256 remains:

`2feea261deaccb92dccc1f9c982ed9f4360c6320ad84dba2d7b39e476582dc49`

## Local wrapper proof

`ping` returned the expected non-mutating Stage 5 executor readiness artifact.

The wrapper rejected:

- `inspect maintenance-page`
- `docker ps`
- `shell`

No SSH trust was installed, so remote public-key authentication for this account is not yet possible.

## Existing identities preserved

- Stage 5 inspection SSH policy unchanged
- Stage 4 validator SSH policy unchanged
- Stage 5 inspection active policy unchanged at inspection-ready SHA256 `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`

## Activation boundary

Still absent:

- executor authorized key
- Jenkins executor credential
- executor sudo execution authority
- Stage 5 enable file

No container ID or restart count changed.

## Status

`STAGE 5 EXECUTOR ACCOUNT STAGED — REMOTE AUTHENTICATION DISABLED`

`JENKINS EXECUTION PATH: NOT ENABLED`

`NO STAGE 5 DEPLOYMENT PERFORMED`
