# ids-01 Grafana API token consumers

These scripts are recovery copies of the validated Grafana API automation on `ids-01`.

## Credential delivery

- Encrypted recovery source: `configuration/ids-01/secrets/grafana-api.sops.env`
- Protected live file: `/home/james/docker/secrets/grafana-api-token`
- Default variable: `GRAFANA_TOKEN_FILE`
- Runtime variable: `GRAFANA_TOKEN`

Each script uses an explicitly supplied `GRAFANA_TOKEN` when present. Otherwise it reads the protected token file. The token is never embedded in these scripts.

## Recorded consumers

| Recovery copy | Live source |
|---|---|
| `hardware-fault-alert.sh` | `/home/james/docker/new.sh` |
| `monitoring-alerts-deploy.sh` | `/home/james/docker/stacks/monitoring/grafana-alerting/deploy-alerts.sh` |
| `monitoring-alerts-live-deploy.sh` | `/home/james/docker/stacks/monitoring/grafana-alerting-live/deploy-alerts.sh` |
| `nebula-sync-alert-deploy.sh` | `/home/james/docker/stacks/nebula-sync/deploy-grafana-alert.sh` |

The obsolete `GRAFANA_TOKEN` declarations and plaintext backups were retired after authentication through the protected file returned HTTP 200.

Deploying these scripts can change Grafana alerting resources. Review their source and target URL before execution.
