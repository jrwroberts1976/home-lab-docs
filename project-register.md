# Homelab Master Project Register

**Last reviewed:** 2026-08-31  
**Purpose:** single place to track active, parked, pending-verification and planned work across the homelab and closely related engineering projects.

This is the master programme view. Daily work remains recorded under `daily-actions/`, while implementation-specific repositories remain authoritative for their own code and detailed plans.

## Status legend

| Status | Meaning |
|---|---|
| 🔵 Current | Main workstream currently being progressed |
| 🟡 Active backlog | Open work that remains in scope |
| ⏸ Parked | Intentionally paused until a dependency completes |
| 🧪 Pending verification | Implementation is substantially complete but needs a real-world or scheduled validation |
| ✅ Complete | Closed or completed work retained only where useful for context |

## Programme rules

1. Git is the source of truth for reproducible infrastructure and operational automation.
2. OpenTofu, Ansible and Jenkins must never become dependent on undocumented GUI-only changes.
3. Jenkins may automate proven procedures, but a manual recovery route must remain available.
4. Monitoring, logging, patching, security and backup are part of the build definition, not afterthoughts.
5. Production migration follows proof on disposable or low-risk workloads first.
6. Backups for Proxmox workloads must have an off-host recovery path.
7. Destructive or disruptive operations require explicit approval and a rollback path.
8. Plaintext secrets must not be committed to Git.

## Current priority order

1. **Finish the Proxmox disposable reference VM to 100%.**
2. **Write the full “Build a New Proxmox VM From Scratch” runbook.**
3. **Complete the Stage 6 Jenkins candidate-acquisition and closed-state-verification path before any fresh container update.**
4. **Use Alloy as the first fresh service to prove the complete Jenkins update -> closure workflow.**
5. **Requalify the remaining previously deferred containers against the actual Stage 6 framework.**
6. **Build the parameterised Jenkins runbook pipeline for broader approved operational runbooks.**
7. **Build the Zabbix platform VM using the proven Proxmox pattern.**
8. Continue the wider Proxmox migration, DNS resilience, Home Assistant, k3s, monitoring, security and documentation backlog.

### Immediate Stage 6 restart point

Dozzle `10.8.0` is fully closed and must not be redeployed simply to obtain a green historical Jenkins build. The next Stage 6 session starts by adding a restricted Jenkins candidate-acquisition identity and a non-mutating `VERIFY_CLOSED` path, verifying Dozzle through Jenkins without recreation, and only then resuming Alloy.

See `daily-actions/2026-08-31/stage6-container-update-closeout.md` for the exact checkpoint.

---

# 1. Proxmox disposable reference VM — 🔵 CURRENT

**Repository:** `jrwroberts1976/proxmox`  
**Reference VM:** `debian-iac-test-01` / VM ID `100`

## Proven build baseline

- [x] Create the Debian VM through OpenTofu.
- [x] Configure CPU, RAM, disk, NIC and cloud-init through IaC.
- [x] Bootstrap SSH access and Ansible inventory.
- [x] Apply the Ansible baseline and prove idempotence.
- [x] Install and prove QEMU guest agent.
- [x] Install node_exporter and register the VM under Prometheus `linux-hosts`.
- [x] Forward systemd journal logs through Alloy to central Loki.
- [x] Feed VM SSH events from Loki into CrowdSec and prove parser/whitelist behaviour.
- [x] Prove the standard Grafana Linux alert baseline covers the VM.
- [x] Configure security-only unattended upgrades.
- [x] Explicitly disable automatic reboot.
- [x] Export patch-status metrics to Prometheus.
- [x] Deploy Grafana alerts for stale patch collection and outstanding security updates.
- [x] Build a controlled Ansible patch workflow with audit/apply/reboot controls.
- [x] Prove audit-only patch execution.
- [x] Prove apply-without-reboot execution.
- [x] Perform a deliberate VM reboot and prove recovery through SSH, QEMU agent, node_exporter, Alloy/Loki, unattended-upgrades, patch timer and Prometheus.

## Remaining acceptance work

- [ ] Correct the OpenTofu `iothread` / SCSI-controller warning without manual Proxmox drift.
- [ ] Decide and prove the off-host backup destination for VM 100.
- [ ] Create and validate a backup of VM 100.
- [ ] Capture pre-destroy evidence needed for equivalence comparison.
- [ ] Destroy VM 100 through OpenTofu only.
- [ ] Recreate VM 100 entirely from Git/OpenTofu/cloud-init/Ansible.
- [ ] Prove the rebuilt VM is functionally equivalent.
- [ ] Re-prove SSH, QEMU agent, node_exporter, Prometheus, Grafana alerts, Alloy/Loki, CrowdSec, unattended upgrades and patch monitoring after rebuild.
- [ ] Restore the backup as a separate recovery proof.
- [ ] Prove the restored VM boots, is reachable and passes the health baseline.
- [ ] Close the disposable VM proof only after destroy/rebuild and restore both pass.

**Exit gate:** the VM can be built, patched, monitored, rebooted, backed up, destroyed, rebuilt from Git and independently restored without relying on undocumented GUI changes.

---

# 2. New Proxmox VM build runbook — 🟡 NEXT

Produce a detailed end-to-end guide using the reference VM as the proven implementation.

- [ ] Document prerequisites and required repositories.
- [ ] Document VM naming, VM-ID and IP/reservation decisions.
- [ ] Document OpenTofu provider/authentication setup without exposing secrets.
- [ ] Document cloud-image acquisition/checksum handling.
- [ ] Document VM resource definition and cloud-init configuration.
- [ ] Document plan/review/apply gates.
- [ ] Document first boot, DHCP/SSH and guest-agent verification.
- [ ] Document Ansible inventory and baseline application.
- [ ] Document node_exporter and Prometheus registration.
- [ ] Document Alloy/Loki enrolment.
- [ ] Document CrowdSec integration where applicable.
- [ ] Document patch policy, metrics and Grafana alert enrolment.
- [ ] Document controlled patch/reboot workflow.
- [ ] Document deliberate reboot/recovery proof.
- [ ] Document backup, destroy/rebuild and restore acceptance tests.
- [ ] Provide a concise new-VM checklist alongside the full runbook.

**Exit gate:** another VM can be built from scratch by following the documentation without reconstructing decisions from chat history.

---

# 3. Jenkins parameterised runbook pipeline — 🟡 PLANNED

Build a Jenkins pipeline that invokes approved operational runbooks/playbooks through controlled build parameters.

- [ ] Define the approved runbook catalogue.
- [ ] Add a build parameter for runbook/playbook selection.
- [ ] Add target host/group parameters where appropriate.
- [ ] Start with read-only/audit actions.
- [ ] Add syntax/validation gates before execution.
- [ ] Add safe parameter defaults.
- [ ] Separate patch approval from reboot approval.
- [ ] Require explicit approval for destructive/disruptive operations.
- [ ] Capture command, target, Git revision and result as build evidence.
- [ ] Protect credentials in Jenkins.
- [ ] Ensure logs do not expose secrets.
- [ ] Keep every Jenkins action reproducible manually from the command line.
- [ ] Add OpenTofu plan/validation operations only after the manual path is proven.
- [ ] Do not make Jenkins the sole recovery route.

**Initial candidate runbooks:** Linux patch audit, controlled patch apply, approved reboot/recovery validation, service-health checks and later container-upgrade operations.

---

# 4. Container upgrade and rollback process — 🧪 SUBSTANTIALLY PROVEN

**Repository:** `jrwroberts1976/homelab-container-version-control`

The Stage 6 work has moved beyond a manual-only proof. Real reviewed deployments have now exercised the generic framework on both TestServer and `ids-01`.

## Proven by 31 August

- [x] Record exact current and target image identities in reviewed manifests.
- [x] Pull/stage an exact immutable candidate without changing running containers through the reviewed candidate-acquisition helper.
- [x] Prove pre-approval runtime/authority/health state read-only.
- [x] Require human approval.
- [x] Reinspect and require exact zero drift after approval.
- [x] Expose executor authority only after approval/zero drift.
- [x] Recreate only the intended Compose service with `--no-deps --no-build --pull never --force-recreate`.
- [x] Validate exact candidate identity and service health.
- [x] Protect unrelated Jenkins/control-plane containers by ID/restart-count checks.
- [x] Keep an explicit reviewed rollback route.
- [x] Prove generic multi-host deployment with Loki `3.7.7` on `ids-01`.
- [x] Requalify and deploy Dozzle `10.8.0` on TestServer.
- [x] Extend health support with reviewed internal Docker-network `container-http` checks.
- [x] Promote Dozzle to exact immutable Git Compose authority.
- [x] Promote Dozzle catalogue and steady-state records.
- [x] Complete final read-only Dozzle steady-state verification with `SUCCESS_CLOSED`.

## Still required before the process is considered fully automated/mature

- [ ] Move candidate acquisition into Jenkins using a dedicated restricted credential rather than a separate manual host step.
- [ ] Complete automatic post-deployment Compose authority/catalogue/steady-state closure inside Jenkins.
- [ ] Prove the complete fresh flow in one Jenkins run with `SUCCESS_CLOSED`.
- [ ] Prove a rollback on a deliberately safe candidate-failure/rejection scenario without compromising a production service.
- [ ] Repeat against at least one stateful or higher-risk service using its additional backup/migration controls.
- [ ] Write the final BAU container-upgrade SOP after the automated path is proven.

**Important:** Dozzle is already fully closed. Its historical Jenkins build #13 must not be rerun merely to obtain a green build because the one-shot update has been consumed.

**Exit gate:** a fresh service can be selected in Jenkins, the exact candidate acquired safely, approved, deployed/rolled back as required, promoted into durable authority/catalogue/steady state and read-only verified without routine manual SSH follow-up.

---

# 5. Containers not upgraded / requalification backlog — 🟡 HIGH PRIORITY

Previously deferred/skipped services must be re-tested against the current Stage 6 framework rather than permanently excluded based on older limitations.

Dozzle demonstrates why this matters: it was initially deferred because it had no published host port/healthcheck, but a narrow reviewed `container-http` extension made it safely manageable without weakening the framework.

For every previously skipped container:

- [ ] Record current container/service/image/version and runtime shape.
- [ ] Re-test it against the current generic framework before declaring a blocker.
- [ ] Record the exact remaining blocker if generic management still cannot support it.
- [ ] Decide `upgrade`, `migrate`, `replace`, `remain pinned`, or `retire`.
- [ ] Prefer narrow reviewed framework extensions over broad security relaxations.
- [ ] Keep privileged/device-backed/writable-Docker-socket/control-plane services in higher-risk categories until explicit controls are proven.
- [ ] For intentional pins, document the review date/condition for revisiting them.
- [ ] For migration-required services, create a dedicated migration task/runbook.
- [ ] Ensure no container silently falls outside the governed version-control process.

Known next low-risk candidate: TestServer Alloy, whose read-only requalification evidence passed on 31 August. It remains untouched until the Jenkins candidate-acquisition and Dozzle `VERIFY_CLOSED` work is complete.

---

# 6. Jenkins automation of container upgrades — 🔵 CURRENT STAGE 6 WORKSTREAM

The generic deployment core is now real and proven; remaining work is to complete the business-as-usual Jenkins workflow and remove routine manual closure steps.

## Proven

- [x] Reviewed Stage 6 manifests and validation.
- [x] Fixed reviewed TestServer/ids-01 routing and host-key pinning.
- [x] Read-only pre-approval inspector credentials.
- [x] Human approval.
- [x] Exact zero-drift reinspection.
- [x] Post-approval executor credential boundary.
- [x] Selected-service-only force recreation.
- [x] `--pull never` deployment.
- [x] Health/runtime/protected-container acceptance gates.
- [x] Explicit rollback operation.
- [x] One-shot arm/disarm model.
- [x] Loki generic multi-host deployment proof.
- [x] Dozzle deployment proof and final reviewed closure.

## Next implementation

- [ ] Add a dedicated candidate-acquisition SSH identity/forced command whose authority is limited to the reviewed image-cache acquisition helper.
- [ ] Pull and verify the exact immutable candidate inside Jenkins before human approval.
- [ ] Prove candidate acquisition cannot change container IDs/restarts/running state.
- [ ] Keep the full executor credential unavailable until after approval and zero drift.
- [ ] Add a reviewed service selector/dropdown generated from governed estate data rather than arbitrary live Docker names.
- [ ] Add a non-mutating `VERIFY_CLOSED` / equivalent action.
- [ ] Verify Dozzle through Jenkins without recreation and require `SUCCESS_VERIFIED_CLOSED`.
- [ ] Automate successful candidate promotion into `docker-env` immutable Compose authority.
- [ ] Synchronise live/root-owned authority without recreating the already-good service.
- [ ] Generate/update and validate catalogue + steady-state data automatically.
- [ ] Install the merged steady-state manifest automatically.
- [ ] Run final read-only steady-state verification.
- [ ] Archive deployment/closure evidence and return explicit result states.
- [ ] Use Alloy as the first fresh service to prove the completed flow and require `SUCCESS_CLOSED`.

Recommended result states include:

```text
SUCCESS_CLOSED
SUCCESS_VERIFIED_CLOSED
DEPLOYED_BUT_CLOSURE_INCOMPLETE
ROLLED_BACK_CLOSED
PRE_DEPLOYMENT_FAILED
MANUAL_REVIEW_REQUIRED
```

**Exit gate:** normal operation is select reviewed service -> Jenkins acquires exact candidate -> review/approve -> Jenkins deploys/verifies/rolls back -> Jenkins closes Git authority/catalogue/steady state -> final read-only verification, with no routine SSH follow-up.

---

# 7. Zabbix platform on Proxmox — 🟡 PLANNED

This project includes the previously separate PostgreSQL + TimescaleDB + Nginx VM idea. It is not a separate project anymore.

**Dependency:** start after the reference Proxmox VM build is 100% complete.

- [ ] Define Zabbix architecture and sizing.
- [ ] Provision the VM through OpenTofu.
- [ ] Bootstrap through cloud-init.
- [ ] Configure the host through Ansible.
- [ ] Deploy PostgreSQL.
- [ ] Deploy TimescaleDB.
- [ ] Deploy Nginx.
- [ ] Deploy the required Zabbix server/frontend/agent components.
- [ ] Manage configuration and secrets through the approved Git/SOPS model.
- [ ] Apply the standard Linux monitoring baseline.
- [ ] Apply Alloy/Loki logging.
- [ ] Apply CrowdSec/security controls where appropriate.
- [ ] Apply security-only unattended upgrades and patch-status monitoring.
- [ ] Use the controlled patch/reboot workflow.
- [ ] Add application/database-specific monitoring and alerts.
- [ ] Define database backup and recovery.
- [ ] Back up the VM off-host.
- [ ] Perform reboot/recovery testing.
- [ ] Perform restore testing.
- [ ] Make the complete Zabbix platform rebuildable from Git.

---

# 8. Proxmox backup and disaster recovery — 🟡 ACTIVE BACKLOG

- [ ] Select a physically separate backup destination.
- [ ] Decide whether Proxmox Backup Server or standard Proxmox backup jobs are used initially.
- [ ] Define retention policy.
- [ ] Define encryption requirements.
- [ ] Define backup schedules.
- [ ] Configure backup monitoring and alerting.
- [ ] Prove a disposable VM backup.
- [ ] Prove independent restore.
- [ ] Document the complete recovery procedure.
- [ ] Ensure no production workload relies solely on backup storage inside the Proxmox host.

---

# 9. Proxmox host monitoring — 🟡 ACTIVE BACKLOG

The basic Proxmox host observability baseline was substantially completed on 31 August: node-exporter is scraped by the Grafana-facing ids-01 Prometheus, Network Hosts identity is corrected to `PROXMOX`, standard CPU/memory/root-disk/host-down alert coverage is proven, and Alloy forwards the systemd journal to ids-01 Loki.

Remaining enhancement work:

- [x] Add/confirm `192.168.2.70:9100` in Prometheus and prove persistent target `UP`.
- [x] Add the Proxmox host to the Network Hosts/Grafana host view.
- [x] Prove CPU/RAM/root-filesystem metric availability.
- [x] Prove standard host-down/disk/CPU/memory alert coverage.
- [x] Forward the Proxmox systemd journal to Loki through Alloy.
- [ ] Add dedicated disk-I/O/network panels where useful.
- [ ] Add CPU/package, PCH and NVMe temperatures to the desired Grafana views.
- [ ] Add temperature alerting.
- [ ] Add SMART/NVMe reporting where practical.
- [ ] Track the NVMe unsafe-shutdown baseline for increases.
- [ ] Evaluate a Proxmox API exporter once node-level monitoring is stable.

---

# 10. Proxmox host security and firmware — 🟡 ACTIVE BACKLOG

## Security

- [ ] Review Proxmox firewall configuration and policy.
- [ ] Review SSH and administrative access.
- [ ] Review whether `rpcbind` / port 111 is required.
- [ ] Remove unnecessary exposure where safe.
- [ ] Add the host to Greenbone scanning.
- [ ] Capture and accept/remediate the vulnerability baseline.
- [ ] Confirm the management UI is not externally exposed.
- [ ] Finish the documented host patch/update procedure.

## Firmware/readiness

- [ ] Verify the latest supported HP Q23 BIOS for the exact ProDesk model.
- [ ] Update using official HP firmware if appropriate.
- [ ] Re-prove VT-x and VT-d/IOMMU after any BIOS change.
- [ ] Re-prove headless boot.
- [ ] Revalidate networking.
- [ ] Revalidate temperatures and SMART health.

---

# 11. Reusable Proxmox IaC foundation — 🟡 ACTIVE BACKLOG

- [ ] Decide durable OpenTofu state storage/recovery.
- [ ] Formalise VM naming conventions.
- [ ] Formalise VM-ID allocation.
- [ ] Formalise production IP-address allocation.
- [ ] Create a reusable VM module.
- [ ] Turn the current Ansible baseline into a reusable Linux role.
- [ ] Create reusable monitoring/logging/patch enrolment roles where useful.
- [ ] Add formatting, linting and validation tooling.
- [ ] Preserve the documented manual OpenTofu/Ansible recovery path.

---

# 12. Docker workload migration to Proxmox — 🟡 PLANNED

- [ ] Inventory every current Docker workload.
- [ ] Classify each service as `migrate`, `keep`, `rebuild`, or `retire`.
- [ ] Build the production Docker VM through the proven IaC pattern.
- [ ] Configure Docker through Ansible.
- [ ] Put Compose definitions into Git.
- [ ] Establish persistent-data layout and backup policy.
- [ ] Establish secret-handling model.
- [ ] Migrate low-risk/stateless services first.
- [ ] Validate functionality, monitoring, logging and rollback per service.
- [ ] Keep the old instance until acceptance is complete.
- [ ] Migrate Grafana later.
- [ ] Migrate Loki later.
- [ ] Migrate Prometheus only after replacement observability is proven.
- [ ] Review the final role of TestServer after migration.

Suggested early order: Homepage/Dashy-style presentation services, Dozzle and other low-risk utilities, WUD-related tooling, other stateless services, then Uptime Kuma before observability-core services.

---

# 13. Home automation — 🟡 PLANNED

- [ ] Deploy Home Assistant OS on Proxmox.
- [ ] Provision through IaC where practical.
- [ ] Integrate Tapo devices.
- [ ] Investigate Tapo energy data and Grafana integration.
- [ ] Add monitoring/alerts where practical.
- [ ] Configure off-host backups.
- [ ] Perform restore testing.
- [ ] Document operation and recovery.

---

# 14. DNS resilience / Pi 4 garden-room role — 🟡 PLANNED

## Pi 4 target

**BirdNET-Go + Pi-hole + Unbound + monitoring over wired Cat 6.**

- [ ] Prepare the Pi 4 for the garden-room role.
- [ ] Validate BirdNET-Go.
- [ ] Configure/validate Pi-hole + Unbound alongside BirdNET-Go.
- [ ] Add/retain monitoring.
- [ ] Check CPU/RAM/thermal behaviour under combined load.
- [ ] Move the Pi 4 to the garden room and prove the wired link.

## Resilience

- [ ] Keep the Pi 3 as the other independent Pi-hole/Unbound node.
- [ ] Synchronise required DNS/blocking configuration.
- [ ] Re-test failover with either DNS node unavailable.
- [ ] Keep DNS independent of Proxmox.
- [ ] Document final failover/recovery procedure.

---

# 15. k3s-node-01 follow-up — 🟡 ACTIVE BACKLOG

- [ ] Standardise security-only unattended upgrades after the disposable VM patch model is fully accepted.
- [ ] Keep automatic reboot disabled.
- [ ] Add patch-status metrics and alerting.
- [ ] Add the controlled patch/reboot workflow.
- [ ] Add Kubernetes-specific reboot gates: k3s service healthy, node Ready, workloads recovered.
- [ ] Resume and complete the unfinished k3s Secrets Encryption work.
- [ ] Prove encrypted-at-rest status and restart behaviour.
- [ ] Merge/close any remaining secret-encryption branch cleanly.

---

# 16. Monitoring, Grafana and security housekeeping — 🟡 ONGOING

- [ ] Reconcile `grafana-alerting` Git definitions with live Grafana where drift remains.
- [ ] Reconcile the older Git `Linux Host Down` definition with the newer host-preserving live rule.
- [ ] Selectively merge useful recovered patch-dashboard panels rather than bulk-restoring old dashboards.
- [ ] Continue the Network Host Overview work.
- [ ] Review cAdvisor usage.
- [ ] Review CrowdSec monitoring/reporting.
- [ ] Finish Alloy migration review and retire Promtail only when safe.
- [ ] Restore/verify Suricata 24-hour collection and improve dashboards.
- [ ] Add Greenbone → Loki ingestion health checking.
- [ ] Continue vulnerability scanning and accepted-risk handling.
- [ ] Keep `ids-01` independent from Proxmox.

---

# 17. Pi-hole, router and unknown-device follow-up — 🟡 ONGOING

- [ ] Resume Pi-hole policy-alert latency work when higher-priority Proxmox/Jenkins work permits.
- [ ] Maintain blocklist/update/enforcement monitoring and weekly reporting.
- [ ] Remove synthetic enforcement-probe traffic from raw client/category totals where still outstanding.
- [ ] Validate blocked-MAC monitoring on a real trigger.
- [ ] Keep the investigated blocked MAC blocked unless positively identified.
- [ ] Get useful ASUS router syslog into Alloy/Loki.
- [ ] Retain DHCP/client events and correlate them with Pi-hole and Suricata.
- [ ] Add useful unknown-device alerting.

---

# 18. Documentation, recovery, secrets and portfolio — 🟡 ONGOING

- [ ] Keep this project register aligned with actual state.
- [ ] Keep dated daily-action records current.
- [ ] Maintain SOP/SCP/Service Overview indexes.
- [ ] Keep important script/service/timer inventories current.
- [ ] Continue SOPS/age recovery testing and documentation.
- [ ] Verify secret/configuration backups can actually be restored.
- [ ] Keep plaintext secrets out of Git.
- [ ] Continue homelab data-dictionary work.
- [ ] Continue Engineering Portfolio/public project documentation.
- [ ] Use completed homelab projects as evidence of engineering, operations and leadership practice.

---

# Pending-verification items to close opportunistically

- [ ] Scheduled WUD scan completes with `0 errors` after the repaired DNS path.
- [ ] High CPU Usage Grafana alert validates on the next real trigger.
- [ ] Blocked-MAC monitoring validates on a real trigger.
- [ ] Suricata 24-hour collection returns to expected operation.
- [ ] Secondary Pi-hole boot reconciliation unit proves itself on the next normal reboot.

---

# Near-term execution sequence

```text
Finish VM 100 completely
        |
        v
Full new-VM build runbook
        |
        +-------------------------------+
        |                               |
        v                               v
Stage 6 Jenkins completion       Jenkins runbook pipeline
(candidate acquisition +
 VERIFY_CLOSED)
        |
        v
Verify closed Dozzle in Jenkins
without recreation
        |
        v
Fresh Alloy end-to-end Stage 6
SUCCESS_CLOSED proof
        |
        v
Requalify remaining containers
        |
        v
Build Zabbix platform VM and
continue wider migration/backlog
```

# Programme-level acceptance criteria

The wider homelab programme is materially mature when:

- important infrastructure is reproducible from Git/IaC;
- Jenkins automates proven workflows without becoming a single point of recovery;
- container image versions and upgrades are governed, tested, rollback-capable and durably closed into Git authority;
- Proxmox workloads have off-host backup and tested restore paths;
- DNS survives the loss of either physical DNS node and remains independent of Proxmox;
- monitoring, logging, patching and security cover new infrastructure before production use;
- production services can be rebuilt or restored without undocumented manual steps;
- documentation accurately reflects the live platform.
