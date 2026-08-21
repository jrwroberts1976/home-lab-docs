# Daily Homelab Actions — 21 August 2026

Operational follow-up notes from the automated daily homelab security and recovery emails.

### Daily Security Brief Review

**Status:** CLOSED / MONITOR NEXT RUN

The daily security brief reported two P2 findings: a Suricata collection timeout and a CrowdSec reporting synchronisation/DNS failure. Both occurred during a host reboot and are assessed as transient restart effects rather than new security incidents.

- **Suricata:** collection timeout coincided with the reboot; no evidence of compromise was identified.
- **CrowdSec:** reporting/DNS synchronisation briefly failed during restart, but local firewall enforcement recovered successfully and the firewall bouncer loaded 5,518 decisions.
- **Backup/recovery:** all 4 systems passed backup, repository integrity and restore validation; the off-host replica and backup storage were healthy.
- **Impact:** no material service outage or confirmed compromise identified.
- **Action:** no new standing engineering action required.
- **Follow-up:** verify the next daily run completes normally; reopen only if either condition recurs outside a reboot or maintenance window.

### Docker image update review

**Status:** OPEN — TODAY

WUD reported four available updates on TestServer. The following actions were agreed for today:

- [ ] **Dozzle:** update `v10.7.2` → `v10.7.3`.
- [ ] **Maintenance page / nginx:** update the `nginx:alpine` image digest from `1dd3048a04f4` → `57744b8fa99a`. The maintenance routing/configuration defect is fixed and documented, but this image-update action remains separate and is not marked complete by the routing fix.
- [ ] **Homepage:** review `v2.0.0` → `v2.1.0` before applying the update.
- [ ] **Alloy / WUD:** investigate tag matching. WUD is offering `v1.19.0-rc.3-windowsservercore-ltsc2022` as an upgrade from Linux Alloy `v1.18.0`; do not apply that image. Tighten tag filtering so RC/Windows variants are not presented as valid Linux upgrades.

### Engineering Portfolio deployment and maintenance

**Status:** CLOSED

- [x] Confirmed the original deployment failure was an application-readiness race rather than a failed build or broken container.
- [x] Updated the deployment script to wait for `/healthz` with a bounded retry loop and fail early on Docker `unhealthy`.
- [x] Added `/projects/container-version-control/` to production route smoke testing.
- [x] Merged the readiness fix to the Engineering Portfolio `main` branch and completed a successful full production deployment.
- [x] Fixed maintenance mode so non-root application paths no longer return 404 by using `try_files $uri $uri/ /index.html;`.
- [x] Persisted the Nginx fallback through a read-only Compose bind mount.
- [x] Force-recreated the maintenance container, passed `nginx -t`, and verified HTTP 200 for `/`, `/about/`, `/projects/`, `/projects/container-version-control/`, and `/this-page-does-not-exist/` while maintenance mode was active.
- [x] Added the validated maintenance Compose/Nginx pattern to `jrwroberts1976/homelab-container-version-control` as a pilot artifact.
- [x] Added the deployment and maintenance operating model to `home-lab-docs`.

### Documentation follow-up

- Document where the daily-email actions log is maintained.
- Document which automation/script generates the daily emails.
- Document how to add and close actions.
- Document how reboot/maintenance-related transient findings are recorded and reviewed.
