# ids-01 secondary Pi-hole

This directory records the non-secret Compose desired state for the secondary Pi-hole and its local Unbound resolver on `ids-01`.

## Secret delivery

The Pi-hole web/API password is not declared directly in Compose or in the stack `.env` file.

- Encrypted recovery source: `configuration/ids-01/secrets/pihole-secondary.sops.env`
- Protected live file: `/home/james/docker/secrets/pihole-secondary-password`
- Container mount: `/run/secrets/pihole_password`
- Runtime variable: `FTLCONF_webserver_api_password`

The entrypoint wrapper reads the protected Compose secret, exports the runtime variable and then executes the image `start.sh` entrypoint.

## Deployment

Create the protected secret file with owner `james:james` and mode `0400`, populate `pihole-secondary.env.example`, then validate before deployment:

```bash
docker compose --env-file pihole-secondary.env.example config --quiet
```

Never commit the decrypted password or a populated environment file.
