# SOPS and age secret recovery

## Purpose

The homelab uses SOPS and age to retain encrypted, version-controlled recovery sources for approved credentials without committing plaintext values or private identities.

The foundation covers `DietPi`, `k3s-node-01`, `TestServer` and `ids-01`.

SOPS protects credential recovery sources in Git. It does not replace the protected files, Compose secrets, environment files or Kubernetes controls used by running services.

## Architecture

Each participating host has a separate operational age identity stored outside Git with mode `0600`.

Encrypted sources are created for two recipients:

1. the operational identity belonging to the host;
2. the shared public recovery recipient.

The corresponding private recovery identity is held on protected DietPi backup storage. Only its public recipient is distributed to the other hosts and stored in repository SOPS policies.

Private age identities must never be committed, displayed in logs or copied into application directories.

## Host coverage

| Host | Repository | Encrypted scope | Live delivery |
|---|---|---|---|
| `DietPi` | `home-lab-docs` | Pi-hole alert SMTP and Restic credentials | protected environment and password files |
| `k3s-node-01` | `kubernetes-homelab` | non-deployable recovery test and future application-managed credentials | SOPS foundation; generated Kubernetes Secrets remain outside Git |
| `TestServer` | `docker-env` | Cloudflare, DuckDNS, AutoKuma, Nginx Proxy Manager and archived contact credentials | Compose secrets and protected host files |
| `ids-01` | `home-lab-docs` | Grafana, Pi-hole, Nebula Sync, OpenAI, Greenbone, SMTP and Restic credentials | Compose secrets, protected files and restricted system environment files |

## Repository locations

### home-lab-docs

- `.sops.yaml`
- `configuration/dietpi/secrets/`
- `configuration/ids-01/secrets/`
- `configuration/ids-01/pihole-secondary/`
- `configuration/ids-01/grafana-token-consumers/`

### kubernetes-homelab

- `.sops.yaml`
- `secrets/README.md`
- `secrets/recovery-test.sops.yaml`

### docker-env

- `.sops.yaml`
- `secrets/testserver/`

Only files matching narrow SOPS creation rules are intended to be tracked beneath secret directories. Plaintext secret files remain ignored.

## Credential boundaries

An encrypted source may be added when:

- the credential is application-managed;
- its lifecycle is not owned by Kubernetes, Helm or another controller;
- its consumers and live delivery method are documented;
- both approved identities can decrypt it independently;
- plaintext and private-key scans pass before commit.

The following material must not be exported into SOPS merely to create a Git copy:

- K3s-generated Secrets;
- Kubernetes-generated Secrets;
- Helm-managed Secrets;
- MetalLB-managed Secrets;
- controller-generated credentials;
- unapproved TLS private keys;
- runtime databases, caches, query history or generated application state.

## Live delivery patterns

Encrypted Git files are recovery sources, not direct runtime mounts.

Approved live delivery patterns include:

- read-only Docker Compose secret files;
- restricted host files;
- restricted systemd environment files;
- temporary protected decryption during controlled recovery;
- application variables populated by a wrapper from a mounted secret.

Plaintext output must not be written into the repository or a general-purpose temporary directory.

## Creating or updating an encrypted source

1. Identify the credential owner, consumers and live delivery path.
2. Confirm that the credential is eligible for Git-managed recovery.
3. Create plaintext only in a mode `0700` memory-backed temporary directory.
4. Encrypt from the repository root so the intended `.sops.yaml` rule matches.
5. Confirm `sops filestatus` reports the file as encrypted.
6. Decrypt with the host operational identity and compare without displaying values.
7. Independently decrypt with the protected recovery identity.
8. Scan the proposed change for plaintext values and private age identities.
9. Update the variable register and operational documentation.
10. Stage only the explicit encrypted-source and documentation allowlist.
11. Merge through a controlled branch and delete it after remote-main verification.
12. Remove temporary plaintext immediately.

## Routine validation

Example encrypted-file status check:

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" \
  sops filestatus path/to/source.sops.env
```

Expected status:

```json
{
  "encrypted": true
}
```

Recovery validation should compare hashes or exact protected output without printing decrypted values.

## Recovery procedure

1. Use a protected temporary directory with mode `0700`.
2. Select either the host operational identity or approved recovery identity.
3. Decrypt the required SOPS source into the protected directory.
4. Validate the expected variable names and file structure.
5. Install the recovered live file with its documented owner and mode.
6. Validate the consumer configuration before restarting or recreating anything.
7. Change only the affected service.
8. Verify authentication, health and sibling-service isolation.
9. Remove all temporary plaintext.
10. Record recovery evidence without credential values.

Encrypted sources must never be applied directly to Kubernetes or Docker Compose unless explicitly documented as deployable.

## Implemented controls

- Separate operational age identity per host.
- Shared public recovery recipient.
- Two-recipient encryption.
- Independent two-identity decryption tests.
- Narrow repository creation rules.
- Private-key and plaintext gates before commit.
- Exact staged-path allowlists.
- Protected runtime files with restrictive permissions.
- Documented variable and consumer registers.
- Controlled branch, merge and deletion workflow.
- Daily-action evidence for each completed host.

## Current operational state

As of 25 August 2026:

- DietPi encrypted recovery sources are operational.
- K3s datastore encryption is enabled and all existing Kubernetes Secrets have been re-encrypted.
- The K3s SOPS and age foundation is operational; no application-managed Kubernetes credential currently requires migration.
- TestServer has five encrypted recovery sources and obsolete plaintext copies have been retired.
- ids-01 has ten encrypted recovery sources.
- The ids-01 secondary Pi-hole uses a read-only Compose secret instead of a direct password environment declaration.
- ids-01 Grafana automation defaults to a protected token file, and obsolete plaintext token copies have been removed.
- All tested encrypted sources passed operational and recovery-identity validation.

## Remaining control gap

The recovery identity stored on DietPi backup storage is protected but online.

Stage 2 recovery assurance is not complete until:

1. a detached offline copy of the recovery identity is created;
2. the offline copy is validated without exposing the private identity;
3. a complete recovery rehearsal is performed using only the offline material and repository sources;
4. the rehearsal evidence is documented;
5. the offline medium is returned to protected detached storage.

## Source-control evidence

- DietPi SOPS merge: `b0b17c4`
- K3s encryption merge: `dd8cb32`
- K3s SOPS merge: `cef4980`
- TestServer SOPS merges: `4e5190f`, `fd2c0e8` and `e152e15`
- ids-01 SOPS merge: `43cf236`
- ids-01 Pi-hole Compose-secret merge: `ea491f0`
- ids-01 Grafana token closure merge: `9372d66`
- ids-01 daily-action merge: `7c047b5`
