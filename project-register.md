# Homelab Master Project Register

**Last reviewed:** 2026-08-30  
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
3. **Build a parameterised Jenkins runbook pipeline.**
4. **Prove a repeatable container-upgrade and rollback process manually.**
5. **Classify and resolve containers that were not upgraded.**
6. **Automate the proven container-upgrade process through Jenkins.**
7. **Build the Zabbix platform VM using the proven Proxmox pattern.**
8. Continue the wider Proxmox migration, DNS resilience, Home Assistant, k3s, monitoring, security and documentation backlog.

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

# 4. Container upgrade and rollback process — 🟡 HIGH PRIORITY

The existing container-version-control work establishes authority and candidate discovery; the next requirement is to prove the actual upgrade procedure safely.

**Repository:** `jrwroberts1976/homelab-container-version-control`

- [ ] Select representative low-risk/stateless container candidates.
- [ ] Record current image tag/digest and runtime identity before each test.
- [ ] Identify the proposed target version/digest.
- [ ] Review release notes and breaking changes.
- [ ] Confirm configuration/data backup or rollback point.
- [ ] Pull/stage the candidate image without changing production first where practical.
- [ ] Run candidate security/Trivy checks where applicable.
- [ ] Recreate only the intended container/service.
- [ ] Validate container health.
- [ ] Validate application functionality.
- [ ] Check startup/migration logs.
- [ ] Validate monitoring and alerting.
- [ ] Validate Loki/log ingestion where applicable.
- [ ] Observe the upgraded service for an agreed period.
- [ ] Record the deployed version/digest in Git.
- [ ] Prove rollback to the previous known-good image/version.
- [ ] Repeat on at least one stateful or higher-risk service with the additional backup/migration controls it needs.
- [ ] Write the resulting container-upgrade SOP.

**Exit gate:** upgrades and rollbacks are repeatable, evidence-backed and safe enough to automate.

---

# 5. Containers not upgraded / exception backlog — 🟡 HIGH PRIORITY

Create a complete list of containers skipped or excluded from earlier upgrade work and record why.

Classify each skipped container as one of:

- already current;
- deliberately pinned;
- locally built image;
- architecture/platform limitation;
- no compatible newer image;
- major-version migration required;
- stateful/database service requiring special controls;
- abandoned/deprecated upstream image;
- previous upgrade failure;
- unclear ownership or image authority.

For every exception:

- [ ] Record current container/service/image/version.
- [ ] Record the reason it was skipped.
- [ ] Decide `upgrade`, `migrate`, `replace`, `remain pinned`, or `retire`.
- [ ] Record the evidence and owner/source-of-truth repository.
- [ ] For intentional pins, document the review date/condition for revisiting them.
- [ ] For migration-required services, create a dedicated migration task/runbook.
- [ ] Ensure no container silently falls outside the governed version-control process.

---

# 6. Jenkins automation of container upgrades — 🟡 PLANNED

Start only after the manual container upgrade/rollback process is proven.

- [ ] Expose candidate selection through controlled Jenkins parameters.
- [ ] Generate a non-secret deployment plan before mutation.
- [ ] Require authority/clean-Git checks.
- [ ] Require current runtime and target digest evidence.
- [ ] Require security/Trivy gate where defined.
- [ ] Require backup/rollback readiness.
- [ ] Require human approval before deployment.
- [ ] Upgrade only the selected service.
- [ ] Run service/application/monitoring/logging validation.
- [ ] Provide an explicit rollback operation.
- [ ] Record outcome and deployed image authority.

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

- [ ] Add/confirm `192.168.2.70:9100` in Prometheus.
- [ ] Confirm persistent target `UP`.
- [ ] Add the Proxmox host to Grafana host dashboards.
- [ ] Add CPU/RAM/load/filesystem panels.
- [ ] Add disk-I/O/network panels.
- [ ] Add CPU/package, PCH and NVMe temperatures.
- [ ] Add host-down alerting.
- [ ] Add disk-space alerting.
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

---

# Near-term execution sequence

```text
Finish VM 100 completely
        |
        v
Full new-VM build runbook
        |
        v
Jenkins parameterised runbook pipeline
        |
        v
Manually prove container upgrade + rollback
        |
        v
Resolve skipped-container exceptions
        |
        v
Automate container upgrades in Jenkins
        |
        v
Build Zabbix platform VM
        |
        v
Wider Proxmox migration and remaining backlog
```

# Programme-level acceptance criteria

The wider homelab programme is materially mature when:

- important infrastructure is reproducible from Git/IaC;
- Jenkins automates proven workflows without becoming a single point of recovery;
- container image versions and upgrades are governed, tested and rollback-capable;
- Proxmox workloads have off-host backup and tested restore paths;
- DNS survives the loss of either physical DNS node and remains independent of Proxmox;
- monitoring, logging, patching and security cover new infrastructure before production use;
- production services can be rebuilt or restored without undocumented manual steps;
- documentation accurately reflects the live platform.
