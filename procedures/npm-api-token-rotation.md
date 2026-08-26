# Create or rotate the NPM API token

Use [`scripts/rotate-npm-api-token.sh`](../scripts/rotate-npm-api-token.sh) on **TestServer**:

```bash
cd /home/james/docker
chmod 0700 scripts/rotate-npm-api-token.sh
bash -n scripts/rotate-npm-api-token.sh
scripts/rotate-npm-api-token.sh
```

The script prompts privately for the Nginx Proxy Manager login email and
password. It then:

1. creates a temporary one-day login token through `POST /api/tokens`;
2. exchanges it through authenticated `GET /api/tokens?expiry=10y`;
3. requires an expiry at least nine years in the future;
4. validates access to the configured proxy-host ID;
5. atomically replaces `/home/james/docker/secrets/npm.env` with mode `0600`;
6. validates the installed token; and
7. restores the previous protected file automatically if final validation
   fails.

It does not display the password or tokens. It does not change any proxy host,
container or service.

After a successful rotation, immediately run:

```bash
scripts/sync-npm-token-sops.sh
```

That second procedure updates the TestServer SOPS recovery source and stops for
independent recovery-identity validation before commit.

## Important limitation

Nginx Proxy Manager 2.15 creates a normal login token with a one-day expiry.
The longer expiry is requested only through the authenticated token-refresh
route. Supplying `expiry` directly to the login POST is rejected by its API
schema.
