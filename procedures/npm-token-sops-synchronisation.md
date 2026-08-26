# NPM token SOPS synchronisation

For token creation or rotation, first follow [NPM API token creation and rotation](npm-api-token-rotation.md).

Run [`scripts/sync-npm-token-sops.sh`](../scripts/sync-npm-token-sops.sh) on **TestServer**. It updates only the encrypted
recovery source and deliberately stops before committing or pushing.

## 1. Install the script

Use the repository script on TestServer:

```bash
cd /home/james/docker
chmod 0700 scripts/sync-npm-token-sops.sh
bash -n scripts/sync-npm-token-sops.sh
```

## 2. Run the guarded synchronisation

```bash
scripts/sync-npm-token-sops.sh
```

Expected final status:

```text
NPM SOPS recovery-source synchronisation: PASS
```

The script:

1. confirms it is running on TestServer;
2. validates the protected live file and operational age identity;
3. fetches `origin/main`;
4. creates `/var/tmp/docker-env-npm-sops` on branch
   `security/sync-npm-token-sops`;
5. decrypts only into protected RAM-backed storage;
6. copies the three NPM values into the recovery declaration;
7. re-encrypts using the repository SOPS policy;
8. confirms the encrypted result exactly matches the live NPM variables;
9. checks for private identity material; and
10. stages exactly `secrets/testserver/nginx-proxy-manager.sops.env`.

It does not display credentials, modify the protected live file, commit, push,
deploy, or change any container or service.

## 3. Stop for independent recovery validation

Do not commit immediately. Validate the staged encrypted file using the
protected recovery identity on DietPi, without displaying plaintext. This is a
separate control and should not involve permanently copying the recovery
identity to TestServer.

After that validation passes, review the staged allowlist and commit the single
encrypted file. Record the commit against `docker-env` issue 10, then merge and
delete the temporary branch.

## Recovery if the script stops

Nothing live has been changed. Inspect safely with:

```bash
git -C /var/tmp/docker-env-npm-sops status --short
git -C /var/tmp/docker-env-npm-sops branch --show-current
```

Do not delete a worktree until any useful staged candidate has been reviewed.
