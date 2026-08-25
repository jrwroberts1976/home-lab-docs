# SOPS and age secret recovery how-to

## Purpose

This procedure explains how to create, validate, update and recover the SOPS-encrypted credential sources used by the home lab.

It covers DietPi, k3s-node-01, TestServer and ids-01.

The encrypted files are recovery sources. They do not automatically replace protected host files, Docker Compose secrets, systemd environment files or Kubernetes runtime delivery.

For the architecture and implementation state, see [SOPS and age secret recovery](../service-overviews/sops-and-age-secret-recovery.md).

## Safety rules

1. Never display a plaintext credential or age private identity.
2. Never commit decrypted output, temporary plaintext or an age private identity.
3. Create plaintext working files only in a protected temporary directory.
4. Set `umask 077` before creating credential material.
5. Encrypt from the repository root so the correct `.sops.yaml` rule is selected.
6. Validate recovery with both approved identities before retiring plaintext.
7. Compare decrypted output without printing credential values.
8. Stage an exact path allowlist.
9. Inspect the staged diff and run security gates before committing.
10. Apply the smallest possible runtime change and validate health.
11. Remove temporary decrypted files and identities after validation.
12. Keep detached recovery media physically disconnected when not required.

## Architecture

Each participating host has a separate operational age identity stored outside Git.

Every encrypted source also includes the public recipient for the shared recovery identity.

The recovery private identity is held as:

- a protected online copy on DietPi backup storage;
- a passphrase-encrypted copy on detached removable media.

| Host | Purpose | Encrypted-source repository |
|---|---|---|
| DietPi | Primary DNS, backup and management services | `home-lab-docs` |
| k3s-node-01 | Kubernetes control plane and recovery declarations | `kubernetes-homelab` |
| TestServer | Docker services and deployment credentials | `docker-env` |
| ids-01 | Monitoring, security, Pi-hole and backup services | `home-lab-docs` |

## Credential boundaries

Private operational identities normally use:

```text
~/.config/sops/age/keys.txt
~/.config/sops/age/recipient.txt
```

The protected online recovery material is stored under:

```text
/mnt/backup/recovery/sops-age/
```

The validated detached package is stored on the designated recovery USB under:

```text
sops-age-recovery-20260825/
```

Never copy an age private identity into a Git repository, stack directory, container image, Compose environment or general-purpose backup archive.

Public age recipients may be committed in `.sops.yaml`. Private identities must not be committed.

## Prerequisites

Confirm the tools and repository state before changing an encrypted source:

```bash
hostname -s
age --version
age-keygen --version
sops --version
git branch --show-current
git status --short
```

Confirm the operational identity without displaying it:

```bash
test -s "$HOME/.config/sops/age/keys.txt"
test -s "$HOME/.config/sops/age/recipient.txt"
```

Use a clean checkout or an isolated Git worktree. Preserve unrelated and pre-existing changes.

## Classify the credential

Before encryption, record:

- credential and variable names;
- protected source path;
- current consumer;
- live delivery mechanism;
- expected ownership and permissions;
- existing encrypted recovery source;
- duplicate plaintext copies that may later be retired.

Suitable recovery sources include:

- single-value Docker Compose secret files;
- protected dotenv files;
- systemd environment files;
- Restic passwords and password files;
- API tokens consumed by protected scripts;
- recovery-only Kubernetes secret declarations.

Do not classify host addresses, ports, time zones, numeric IDs or public age recipients as credentials.

Do not copy databases, whole configuration trees or unrelated runtime state into a SOPS dotenv source.

## Create or update an encrypted source

### 1. Create protected temporary storage

Use memory-backed storage when available:

```bash
TEMP_DIR="$(mktemp -d /dev/shm/sops-update.XXXXXX)"
chmod 0700 "$TEMP_DIR"
umask 077
```

Build the smallest plaintext source that preserves the required recovery format. Do not print its values.

For a single-value credential represented as dotenv:

```bash
printf 'VARIABLE_NAME=%s\n' "$(tr -d '\n' <"$PROTECTED_SOURCE")" >"$TEMP_DIR/source.env"
chmod 0600 "$TEMP_DIR/source.env"
```

For an existing protected dotenv file:

```bash
cp "$PROTECTED_SOURCE" "$TEMP_DIR/source.env"
chmod 0600 "$TEMP_DIR/source.env"
```

### 2. Check the SOPS creation rule

From the repository root, confirm that `.sops.yaml` contains one matching creation rule for the target path and only public recipients.

```bash
cd "$REPOSITORY"
sops filestatus "$TARGET" 2>/dev/null || true
```

If no rule matches, update `.sops.yaml` before encryption. Never place a private identity in that policy.

### 3. Encrypt from the repository root

```bash
cd "$REPOSITORY"
sops --encrypt "$TEMP_DIR/source.env" >"$TARGET"
test -s "$TARGET"
```

When the temporary filename does not match the repository creation rule, supply the intended repository filename to SOPS using the supported filename override or place the protected temporary input at the matching repository-relative path.

A zero-byte target is a failed encryption, even when the path exists. Remove it before retrying.

### 4. Validate encrypted status

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" \\
  sops filestatus "$TARGET" |
  jq -e '.encrypted == true'
```

### 5. Validate the operational identity

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" \\
  sops --decrypt "$TARGET" >"$TEMP_DIR/decrypted.env"

cmp --silent "$TEMP_DIR/source.env" "$TEMP_DIR/decrypted.env"
```

A successful command and exact comparison are both required.

### 6. Validate the recovery identity

Transfer only the encrypted source to the recovery host. Decrypt it there using the protected recovery identity and return a digest, not the plaintext.

Compare the operational and recovery digests locally. Remove all remote temporary files afterwards.

A source is not ready for plaintext retirement until both approved identities recover the same content.

## Restore a protected live credential

Restoration changes live credential delivery. Confirm the exact target, consumer, owner, mode and rollback source before proceeding.

### 1. Decrypt into protected temporary storage

```bash
TEMP_DIR="$(mktemp -d /dev/shm/sops-restore.XXXXXX)"
chmod 0700 "$TEMP_DIR"
umask 077

SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" \\
  sops --decrypt "$ENCRYPTED_SOURCE" >"$TEMP_DIR/recovered.env"
chmod 0600 "$TEMP_DIR/recovered.env"
```

Validate declaration names and expected counts without displaying values.

### 2. Build the required live format

Use the format expected by the consumer:

| Delivery pattern | Required live format |
|---|---|
| Compose secret | Single-value protected host file |
| Protected script input | Dotenv or single-value host file |
| systemd `EnvironmentFile` | Root-owned dotenv file |
| Restic password file | Value only, with no variable name |
| Kubernetes recovery declaration | Apply only through the approved cluster workflow |

For a single-value file, extract only the approved variable into a temporary candidate. Do not echo it to the terminal.

### 3. Install atomically

Create the replacement beside the destination, apply its owner and mode, and then rename it over the exact target.

Typical protection is:

```bash
chmod 0400 "$TEMP_FILE"
chown "$EXPECTED_OWNER:$EXPECTED_GROUP" "$TEMP_FILE"
mv "$TEMP_FILE" "$LIVE_FILE"
```

Use the permissions required by the consumer. Root-owned systemd files commonly require mode `0600`; a user-owned Docker secret may use `0400`.

### 4. Validate desired state before runtime change

For Docker Compose:

```bash
docker compose --project-directory "$STACK" config --quiet
```

For systemd:

```bash
sudo systemd-analyze verify "$UNIT_FILE"
```

For scripts, use the appropriate syntax checker, such as `bash -n`.

### 5. Apply the smallest runtime change

Recreate or restart only the consumer that requires the new credential. Record container IDs, service states and restart counts beforehand.

Validate:

- service or container health;
- authentication using the protected credential;
- expected application behaviour;
- sibling-service isolation;
- absence of direct sensitive runtime environment variables where file delivery is intended.

### 6. Retire superseded plaintext

Delete a plaintext copy only after encrypted recovery, live delivery and rollback gates pass.

Resolve an exact allowlist of retirement targets first. Revalidate their absence and confirm that no consumer still references them.

### 7. Clean temporary material

```bash
rm -rf -- "$TEMP_DIR"
```

Confirm that no decrypted credential or temporary private identity remains.

## Rotate a credential

Credential rotation and SOPS metadata rotation are separate operations.

To rotate a live credential:

1. create the new credential in the authoritative application;
2. validate it without displaying its value;
3. build and encrypt the updated recovery source;
4. validate both operational and recovery identities;
5. update the protected live delivery file;
6. apply the smallest required runtime change;
7. validate authentication and service health;
8. revoke the superseded credential;
9. remove obsolete plaintext copies;
10. document the rotation evidence.

Do not revoke the old credential until recovery and live-delivery validation for the replacement have passed.

## Update SOPS recipients or data keys

When an approved age recipient changes, first update the matching creation rule in `.sops.yaml`.

Use SOPS to update the encrypted file keys rather than decrypting and manually rebuilding every value:

```bash
cd "$REPOSITORY"
sops updatekeys "$TARGET"
```

For deliberate data-key rotation, use the supported SOPS rotation operation:

```bash
sops rotate --in-place "$TARGET"
```

After either operation:

- confirm encrypted file status;
- validate decryption with every approved identity;
- run plaintext and private-key gates;
- review the encrypted-only Git diff;
- record why the metadata changed.

Remove a recipient only after confirming it is no longer required and at least two approved recovery paths remain where policy requires them.

## Routine validation

Perform routine validation without displaying decrypted content.

For every encrypted source:

```bash
sops filestatus path/to/source.sops.env |
  jq -e '.encrypted == true'
```

Then verify:

- the file is non-empty;
- the expected creation rule matches its repository path;
- the operational identity decrypts it;
- the recovery identity decrypts it;
- declaration names match the variable register;
- no age private identity is present in tracked content;
- no plaintext credential value is present in tracked content;
- protected live files retain the expected owner and mode;
- consumers still use the documented delivery mechanism.

Use digests for cross-host comparison and remove all temporary evidence after the check.

A full detached-media recovery rehearsal should also be repeated after material recovery-policy changes or replacement of the offline medium.

## Detached offline recovery

The validated recovery medium is the removable USB filesystem with UUID `43FA-9542`.

Never identify removable media by `/dev/sdX` alone. Device names can change between hosts and boots.

### Media handling controls

- verify the expected host, USB transport, removable flag and filesystem UUID;
- exclude the mounted DietPi online backup filesystem;
- mount the USB read-only for inspection and recovery;
- validate `SHA256SUMS` before decrypting anything;
- copy only the encrypted package into protected RAM;
- unmount the USB before entering the passphrase;
- never store the passphrase on the USB or in Git;
- remove all recovered identity and plaintext material from RAM;
- physically detach the USB after validation.

### 1. Identify and mount the medium read-only

```bash
EXPECTED_UUID="43FA-9542"
PARTITION_UUID="$(lsblk -dn -o UUID "$PARTITION" | xargs)"
test "$PARTITION_UUID" = "$EXPECTED_UUID"
if findmnt --source "$PARTITION" >/dev/null 2>&1; then
  echo "Partition is already mounted; stop and review."
fi

MOUNT_DIR="$(mktemp -d /tmp/offline-recovery.XXXXXX)"
sudo mount -o ro,nosuid,nodev,noexec "$PARTITION" "$MOUNT_DIR"
```

### 2. Validate and copy the encrypted package

```bash
sudo sh -c "cd '$MOUNT_DIR/sops-age-recovery-20260825' && sha256sum --check SHA256SUMS"

REHEARSAL_ROOT="$(mktemp -d /dev/shm/offline-recovery.XXXXXX)"
chmod 0700 "$REHEARSAL_ROOT"
sudo cp -a "$MOUNT_DIR/sops-age-recovery-20260825" "$REHEARSAL_ROOT/package"
sudo chown -R "$(id -u):$(id -g)" "$REHEARSAL_ROOT/package"
```

### 3. Unmount before passphrase entry

```bash
sudo umount "$MOUNT_DIR"
rmdir "$MOUNT_DIR"
```

Confirm the partition is unmounted before continuing.

### 4. Recover the identity into protected RAM

```bash
age --decrypt \\
  --output "$REHEARSAL_ROOT/recovery-identity.txt" \\
  "$REHEARSAL_ROOT/package/recovery-identity.txt.age" \\
  </dev/tty

chmod 0600 "$REHEARSAL_ROOT/recovery-identity.txt"
```

Enter the separately stored passphrase through `/dev/tty`. Never pass it as a command argument or environment variable.

Validate that the recovered identity derives the public recipient contained in the package without printing the private identity.

### 5. Rehearse encrypted-source recovery

Use an isolated home and explicitly select only the recovered offline identity:

```bash
ISOLATED_HOME="$REHEARSAL_ROOT/isolated-home"
mkdir -m 0700 "$ISOLATED_HOME"

HOME="$ISOLATED_HOME" \\
SOPS_AGE_KEY_FILE="$REHEARSAL_ROOT/recovery-identity.txt" \\
  sops --decrypt "$ENCRYPTED_SOURCE" >"$REHEARSAL_ROOT/decrypted.env"
```

Validate declaration names, counts and protected-source comparisons without displaying values.

The TestServer rehearsal recovered all five encrypted sources and left all 30 running containers untouched.

### 6. Remove recovery material

```bash
rm -rf -- "$REHEARSAL_ROOT"
```

Confirm that the USB is unmounted, temporary recovery material is absent and the device is physically detached.

## Failure and rollback handling

Stop and review the change when any gate fails.

| Failure | Required response |
|---|---|
| No matching SOPS creation rule | Correct the repository-relative rule before encryption |
| Zero-byte encrypted output | Remove the failed output and repeat encryption from the repository root |
| `filestatus` does not report encrypted | Do not stage or commit the file |
| Operational identity cannot decrypt | Preserve the live source and correct identity or policy selection |
| Recovery identity cannot decrypt | Do not retire plaintext or revoke the old credential |
| Decrypted comparison differs | Determine whether formatting or credential content changed |
| Configuration validation fails | Do not restart or recreate the consumer |
| Health or authentication fails | Restore the exact protected backup and reapply the previous desired state |
| USB checksum fails | Do not decrypt or trust the package |
| Private identity appears in Git content | Remove it immediately and assess whether identity rotation is required |

Keep rollback evidence outside Git when it contains plaintext. Remove it after successful closure.

## Source-control procedure

Use a dedicated branch based on current remote `main`.

Stage only the exact approved files:

```bash
git add -- \\
  .sops.yaml \\
  path/to/source.sops.env \\
  path/to/README.md
```

Review the staged paths and content:

```bash
git diff --cached --name-only
git diff --cached --stat
git diff --cached --check
git status --short
```

Before committing, verify:

- every intended source reports encrypted status;
- no private identity marker is present;
- no known plaintext credential value is present;
- no unexpected plaintext file exists;
- documentation identifies variables, consumers and live delivery;
- unrelated user changes are excluded.

After committing, push the branch, merge it through the approved workflow, verify remote `main`, and remove the merged branch.

## Evidence checklist

Record evidence without secret values:

- host and architecture gates;
- tool versions;
- encrypted source names and declaration counts;
- operational identity recovery result;
- recovery identity recovery result;
- exact or digest comparison result;
- live source owner and mode;
- configuration validation result;
- service health and authentication result;
- unchanged sibling containers or services;
- plaintext retirement targets and absence validation;
- temporary-material cleanup;
- branch, implementation commit and merge commit;
- remote-main verification and branch deletion;
- detached-media checksum, unmount and physical-detachment evidence when applicable.

Update the daily action record whenever a SOPS source, delivery mechanism, recovery identity or recovery control materially changes.

## Related documentation

- [SOPS and age secret recovery overview](../service-overviews/sops-and-age-secret-recovery.md)
- [DietPi recovery procedure](../configuration/dietpi/RECOVERY.md)
- [DietPi encrypted source register](../configuration/dietpi/secrets/README.md)
- [ids-01 encrypted source register](../configuration/ids-01/secrets/README.md)
- [Secondary Pi-hole protected delivery](../configuration/ids-01/pihole-secondary/README.md)
- [Grafana token consumers](../configuration/ids-01/grafana-token-consumers/README.md)
