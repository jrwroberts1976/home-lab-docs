# Engineering Portfolio Deployment and Maintenance

This page documents the production deployment and maintenance-mode workflow for `me.jrwroberts.co.uk` on TestServer.

## Service locations

**Server / Host:** `TestServer`

```text
Operator clone:      /home/james/projects/engineering-portfolio
Deployment source:   /home/james/docker/stacks/engineering-portfolio-git
Production stack:    /home/james/docker/stacks/engineering-portfolio
Maintenance stack:   /home/james/docker/stacks/maintenance-page
```

The application container is:

```text
engineering-portfolio
```

Nginx Proxy Manager runs in container:

```text
npm
```

The normal upstream target is:

```text
engineering-portfolio:80
```

## Normal deployment command

From the operator clone:

```bash
cd /home/james/projects/engineering-portfolio
git pull --ff-only
./scripts/deploy-production.sh
```

The deployment script also updates its own deployment-source clone under `/home/james/docker/stacks/engineering-portfolio-git`. The existence of both clones is a known improvement item because the initial operator `git pull` and the script's internal source update operate on different working copies.

## Guarded deployment flow

The production script performs the following sequence:

1. validates prerequisites and required paths;
2. loads Nginx Proxy Manager credentials from `$HOME/docker/secrets/npm.env` without printing secret values;
3. enables maintenance mode and creates a change-control record;
4. updates the deployment source from Git;
5. runs `npm ci` and the Astro production build;
6. synchronises the built source into the production stack;
7. validates the production Compose configuration;
8. builds the production container image;
9. recreates the application container;
10. waits for the container to enter `running`;
11. waits separately for application readiness;
12. validates Nginx Proxy Manager connectivity and application routes;
13. disables maintenance mode only after the required checks pass.

On failure, the script keeps maintenance mode enabled and surfaces useful container status/log evidence instead of automatically restoring a potentially broken application.

## Application readiness fix

The first production test exposed a race: Docker reported the container as `running` before Nginx inside it was ready to accept `/healthz` connections. A one-shot health request therefore produced a false deployment failure while Docker health was still `starting`.

The corrected workflow, merged to the Engineering Portfolio `main` branch on 21 August 2026, now:

- retries `/healthz` up to 30 times with a 2-second interval;
- allows up to approximately 60 seconds for application readiness;
- fails immediately if Docker reports `unhealthy`;
- reports the final Docker health state when the application probe succeeds;
- includes `/projects/container-version-control/` in route smoke tests.

A subsequent full production deployment completed successfully with this logic.

## Maintenance-mode workflow

Maintenance mode is controlled by:

```text
/home/james/docker/stacks/maintenance-page/enable-maintenance.sh
/home/james/docker/stacks/maintenance-page/disable-maintenance.sh
```

The scripts validate the expected Nginx Proxy Manager proxy host before changing the upstream target and maintain a change-control record for the maintenance window.

The maintenance stack uses `maintenance-page`, published locally on:

```text
192.168.2.220:8088 -> container port 80
```

and attached to external Docker network:

```text
homelab_apps
```

## All-path maintenance fallback

The original stock Nginx configuration only served existing files. When Nginx Proxy Manager forwarded a request such as `/projects/...` to the maintenance container, Nginx looked for that filesystem path and returned 404.

The persistent configuration now bind-mounts:

```text
/home/james/docker/stacks/maintenance-page/nginx/default.conf
    -> /etc/nginx/conf.d/default.conf:ro
```

with:

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

This preserves real static assets and falls back every unknown application path to the maintenance page.

After a forced container recreation, `nginx -t` passed and the following public paths all returned HTTP 200 while maintenance mode was active:

```text
/
/about/
/projects/
/projects/container-version-control/
/this-page-does-not-exist/
```

This proves the fix survives container recreation and covers both known and unknown application paths.

## Version-control ownership

The validated maintenance Compose/Nginx pattern is now maintained as part of the dedicated project:

`jrwroberts1976/homelab-container-version-control`

Repository path:

```text
pilot/maintenance-page/
```

The live TestServer stack remains the runtime copy. The project repository is the reference pattern to be brought under the wider image-version and drift-control workflow.

## Known follow-up items

- record the candidate image ID/digest before recreation;
- record the previous image ID/digest for deterministic rollback;
- reconcile the duplicate Engineering Portfolio source checkouts;
- confirm whether the production `.env` warning is an expected no-secret case or an undocumented configuration gap;
- bring `nginx:alpine` under the project image-pinning policy rather than silently changing the floating tag during documentation work.
