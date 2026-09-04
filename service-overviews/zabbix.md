# Zabbix — Infrastructure Monitoring and API Integration

## Purpose

Zabbix provides complementary infrastructure monitoring for the homelab. It is intended for host/service inventory, agent/API-based monitoring and Zabbix-native triggers while Prometheus, Loki, Grafana and Alloy continue to provide the established metrics/logging observability paths.

## Current deployment

The Zabbix platform runs as Proxmox LXC CT201:

```text
CT201:      zabbix-lxc-01
IPv4:       192.168.2.184
Frontend:   http://192.168.2.184:8080/
Zabbix:     7.0 LTS
PostgreSQL: 17
TimescaleDB: enabled
Nginx/PHP:  active
```

The platform was technically closed on 4 September 2026 with Ansible idempotence and OpenTofu zero drift.

## Architecture

```text
Proxmox
└── CT201 zabbix-lxc-01
    ├── Zabbix Server 7.0 LTS
    ├── Zabbix Agent 2
    ├── PostgreSQL 17 + TimescaleDB
    ├── Nginx + PHP 8.4 FPM
    └── Alloy

ids-01 Grafana
    |
    | dedicated read-only API token
    v
CT201 Zabbix API
```

Zabbix complements rather than replaces Prometheus/Loki/Alloy.

## Grafana integration

Grafana on `ids-01` uses:

```text
plugin:     alexanderzobnin-zabbix-app 6.6.0
datasource: Zabbix
uid:        zabbix
endpoint:   http://192.168.2.184:8080/api_jsonrpc.php
```

The dedicated Zabbix service identity is:

```text
role:       Grafana API Read Only
user group: Grafana Read Only
user:       grafana-zabbix
token:      grafana-datasource
```

The API role allows authenticated read methods only. The token is generated once and captured into SOPS-encrypted authority.

Final functional proof:

```text
grafana_to_zabbix=PASS
proxmox_group_visibility=PASS
```

This proves Grafana can query Zabbix and see the `Infrastructure/Proxmox` host group. It does not yet prove that the Proxmox VE host itself is enrolled in Zabbix.

## Secret authority

Encrypted source:

```text
jrwroberts1976/docker-env
secrets/ids-01/grafana-zabbix.sops.env
```

Runtime source on ids-01:

```text
/home/james/docker/secrets/zabbix-grafana-api-token
```

The validated Grafana-readable runtime state is owner UID `472`, mode `0400`.

Plaintext token values must not be printed, committed or copied into documentation.

## Monitoring and health

Validate:

- Zabbix frontend/API reachability;
- `zabbix-server`, `zabbix-agent2`, PostgreSQL, Nginx and PHP-FPM health;
- PostgreSQL remains localhost-only;
- TimescaleDB extension/hypertable state;
- Grafana Zabbix datasource connectivity;
- dedicated service token remains present and is not regenerated on routine IaC reruns.

## Backup and recovery

The pre-TimescaleDB conversion rollback dump is retained on CT201:

```text
/var/backups/zabbix/zabbix-pre-timescaledb-20260903-230800.dump
```

Infrastructure configuration is owned by OpenTofu/Ansible in `jrwroberts1976/proxmox`. The Grafana integration and SOPS token authority are split between the Proxmox and `docker-env` repositories.

## Current scope boundary

Complete:

- CT201 Zabbix platform foundation;
- Vault-backed administrative credential;
- TimescaleDB integration;
- BH22 8QL Geomap authority;
- dedicated Grafana API identity;
- SOPS-backed Grafana token authority;
- Grafana plugin/datasource integration.

Backlog:

- onboard the first monitored Linux-host batch;
- enroll the Proxmox VE host in Zabbix using the selected Proxmox integration/template;
- add Zabbix-native monitoring only where it adds value beyond existing Prometheus/Alloy coverage.

## Related documentation

- [Grafana](grafana.md)
- [Prometheus](prometheus.md)
- [Grafana Alloy](alloy.md)
- [SOPS and age secret recovery](sops-and-age-secret-recovery.md)
- [Service Overviews index](README.md)
