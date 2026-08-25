# Homelab Master Project Register

**Last reviewed:** 2026-08-25  
**Purpose:** single place to track active, parked, pending-verification and planned work across the homelab and closely related engineering projects.

This register is intentionally broader than the day-to-day `README.md` todo list. It is the master programme view and should be updated when a project is started, paused, completed, or materially re-prioritised.

## Status legend

| Status | Meaning |
|---|---|
| 🔵 Current | Main workstream currently being progressed |
| 🟡 Active backlog | Open work that remains in scope |
| ⏸ Parked | Intentionally paused until another dependency completes |
| 🧪 Pending verification | Implementation is substantially complete but needs a real-world or scheduled validation |
| ✅ Complete | Closed; remove from active planning once documentation is final |

## Priority order

1. **Finish Jenkins Gradle Delivery Lab**
2. **Resume HP ProDesk / Proxmox migration**
3. **Complete BIOS → monitoring → IaC foundation → test VM → backup/restore proof**
4. **Continue Docker/container version-control work**
5. **Rework resilient DNS / Pi 4 BirdNET placement**
6. **Introduce Home Assistant**
7. **Begin production Docker workload migration**
8. Continue security, monitoring, documentation and recovery improvements in parallel

---

# 1. Jenkins Gradle Delivery Lab — 🔵 CURRENT

**Repository:** `jrwroberts1976/jenkins-gradle-delivery-lab`

- [ ] Finish the current Jenkins work before resuming the Proxmox project.
- [ ] Complete and validate the Jenkins pipeline end-to-end.
- [ ] Validate Gradle test stage.
- [ ] Validate package stage.
- [ ] Validate container build stage.
- [ ] Validate Trivy/container security scanning.
- [ ] Validate gated `PUBLISH_CONTAINER` behaviour.
- [ ] Run a clean pipeline from start to finish.
- [ ] Confirm Docker/DinD/socket arrangement is correct and documented.
- [ ] Finish project documentation.
- [ ] Document rebuild/recovery procedure.
- [ ] Decide how Jenkins will later invoke Proxmox Infrastructure as Code.
- [ ] Ensure Jenkins automates the workflow without becoming the only recovery path.

**Exit gate:** Jenkins build/test/container workflow is stable, documented and reproducible.

---

# 2. HP ProDesk / Proxmox Migration — ⏸ PARKED UNTIL JENKINS FINISHES

**Repository:** `jrwroberts1976/proxmox`

## Host bootstrap

- [x] Install Proxmox VE 9.2.
- [x] Disable PVE Enterprise repository.
- [x] Disable Ceph Enterprise repository.
- [x] Enable `pve-no-subscription`.
- [x] Fully patch the host.
- [x] Prove headless reboot/recovery.
- [x] Configure management address `192.168.2.70/24`.
- [x] Add ASUS DHCP reservation for `192.168.2.70`.
- [x] Hardware inventory.
- [x] NVMe SMART baseline.
- [x] Validate 1 Gbps full-duplex Ethernet.
- [x] Validate NTP/Chrony time synchronisation.
- [x] Validate Intel VT-x.
- [x] Validate Intel VT-d/IOMMU and IRQ remapping.
- [x] Capture CPU/PCH/NVMe temperature baseline.
- [x] Confirm `prometheus-node-exporter` is installed and serving metrics on port 9100.

## Firmware

- [ ] Verify latest supported HP Q23 BIOS for the ProDesk 400 G4 DM.
- [ ] Download only the official HP firmware package.
- [ ] Update BIOS if appropriate.
- [ ] Recheck VT-x after BIOS update.
- [ ] Recheck VT-d/IOMMU after BIOS update.
- [ ] Recheck headless boot after BIOS update.
- [ ] Recheck thermal baseline after BIOS update.

## Monitoring

- [ ] Add `192.168.2.70:9100` to Prometheus.
- [ ] Confirm Prometheus target reports `UP`.
- [ ] Add Proxmox host to Grafana.
- [ ] CPU/load panels.
- [ ] RAM/swap panels.
- [ ] Disk/NVMe capacity and I/O panels.
- [ ] Network throughput/error panels.
- [ ] CPU/PCH/NVMe temperature panels.
- [ ] Monitor NVMe unsafe-shutdown counter; baseline is 103.
- [ ] Add appropriate availability, thermal and storage alerts.

## Infrastructure as Code foundation

- [ ] Establish repository structure for IaC.
- [ ] Select OpenTofu/Terraform Proxmox provider.
- [ ] Create restricted Proxmox API credentials.
- [ ] Store secrets outside Git and enforce `.gitignore`/SOPS policy as appropriate.
- [ ] Create reusable VM definitions/modules.
- [ ] Establish cloud-init templates.
- [ ] Establish Ansible inventory.
- [ ] Build common Linux Ansible role.
- [ ] Automate users, SSH, packages, updates and base hardening.
- [ ] Automate node_exporter deployment/configuration.
- [ ] Build Docker-host Ansible role.
- [ ] Document manual IaC workflow.
- [ ] Integrate IaC execution into Jenkins only after the manual path is proven.

## IaC proof

- [ ] Create the first disposable Debian VM through code, not the GUI.
- [ ] Configure it with cloud-init.
- [ ] Configure it with Ansible.
- [ ] Add monitoring automatically.
- [ ] Destroy it through IaC.
- [ ] Recreate it from Git.
- [ ] Prove the rebuilt VM is functionally equivalent.

## Backup and recovery

- [ ] Decide external Proxmox backup destination.
- [ ] Configure VM backup jobs.
- [ ] Back up disposable test VM.
- [ ] Delete test VM.
- [ ] Restore test VM.
- [ ] Validate restored VM.
- [ ] Document disaster-recovery procedure.
- [ ] Ensure no critical backup relies only on the Proxmox NVMe.

## Security

- [ ] Review Proxmox firewall policy.
- [ ] Review SSH configuration.
- [ ] Review whether `rpcbind` / port 111 is required.
- [ ] Remove unnecessary exposed services where safe.
- [ ] Add Proxmox host to Greenbone scanning.
- [ ] Run baseline vulnerability scan.
- [ ] Scan IaC-created VMs.

## Capacity

- [ ] Decide RAM upgrade path from current 8 GB.
- [ ] Likely target: 32 GB using 2 x 16 GB DDR4 SO-DIMM.
- [ ] Decide storage expansion before Loki/Prometheus migration.
- [ ] Measure actual 24x7 electricity consumption.

**Rule:** production VMs should be created through IaC rather than manually in the Proxmox GUI.

---

# 3. Docker / Container Version Control — 🟡 ACTIVE BACKLOG

**Repository:** `jrwroberts1976/homelab-container-version-control`

- [ ] Continue Stage 0 inventory of TestServer and ids-01 Compose declarations.
- [ ] Compare declared image tags/digests with actually running containers.
- [ ] Classify drift.
- [ ] Classify floating tags.
- [ ] Classify unmanaged containers.
- [ ] Inventory secret locations without committing secrets.
- [ ] Establish version-pinning policy.
- [ ] Establish controlled update workflow.
- [ ] Add drift detection.
- [ ] Decide how WUD fits into the governed update path.
- [ ] Bring remaining production Compose definitions into Git.
- [ ] Document rollback and recovery.
- [ ] Use the maintenance-page stack as a production pilot pattern.

**Related BAU:** one successful scheduled WUD scan with `0 errors` remains as final verification of the recent DNS/WUD repair.

---

# 4. Docker Workload Migration to Proxmox — 🟡 PLANNED

- [ ] Inventory every current Docker workload.
- [ ] Classify each service as `migrate`, `keep`, `rebuild`, or `retire`.
- [ ] Build Debian Docker VM through IaC.
- [ ] Configure Docker host through Ansible.
- [ ] Put Compose definitions into Git.
- [ ] Establish persistent-data layout.
- [ ] Establish secret-handling model.
- [ ] Establish backup strategy.
- [ ] Migrate low-risk services first.
- [ ] Validate each migration independently.
- [ ] Keep old instance available until new instance passes acceptance testing.
- [ ] Move Grafana later in the migration.
- [ ] Move Loki later in the migration.
- [ ] Move Prometheus only after the replacement monitoring path is proven.
- [ ] Review the future role of the existing TestServer Pi.

---

# 5. DNS Resilience / Raspberry Pi Reorganisation — 🟡 PLANNED

## Pi 4 — garden room

Target role: **BirdNET-Go + Pi-hole + Unbound + monitoring** over wired Cat 6.

- [ ] Prepare Pi 4 for final role.
- [ ] Install/configure BirdNET-Go.
- [ ] Configure Pi-hole.
- [ ] Configure Unbound.
- [ ] Add monitoring/exporters.
- [ ] Test BirdNET-Go and DNS concurrently.
- [ ] Check CPU/RAM/thermal behaviour under combined load.
- [ ] Move Pi 4 to garden room.
- [ ] Verify wired Cat 6 link after relocation.
- [ ] Verify BirdNET audio capture.
- [ ] Verify DNS after relocation.

## Pi 3

- [ ] Configure/retain independent Pi-hole.
- [ ] Configure Unbound.
- [ ] Add monitoring.
- [ ] Ensure it has no dependency on Pi 4 or Proxmox.

## Resilience validation

- [ ] Synchronise required blocklists/local DNS/policy.
- [ ] Advertise both DNS servers through DHCP.
- [ ] Configure Proxmox eventually to use both resolvers.
- [ ] Power down Pi 3 and prove DNS survives.
- [ ] Restore Pi 3.
- [ ] Power down Pi 4 and prove DNS survives.
- [ ] Restore Pi 4.
- [ ] Document recovery/failover procedure.

---

# 6. Home Automation — 🟡 PLANNED

- [ ] Deploy Home Assistant OS as a dedicated Proxmox VM.
- [ ] Provision via IaC where practical.
- [ ] Configure backups.
- [ ] Perform restore test.
- [ ] Integrate Tapo devices.
- [ ] Investigate Tapo energy-monitoring data.
- [ ] Decide which home-automation metrics should flow to Prometheus/Grafana.
- [ ] Add service monitoring and alerts.
- [ ] Document operation and recovery.

---

# 7. Pi-hole Policy Alert Latency — 🟡 PAUSED

Known historical end-to-end baseline: approximately **3m04s**.

- [ ] Resume Pi-hole Policy Alert Latency Improvement Runbook.
- [ ] Re-establish current latency baseline.
- [ ] Measure collector latency.
- [ ] Measure Prometheus scrape contribution.
- [ ] Measure Grafana evaluation contribution.
- [ ] Measure notification grouping contribution.
- [ ] Reduce collector delay if practical.
- [ ] Review scrape interval trade-offs.
- [ ] Review Grafana evaluation interval.
- [ ] Review notification grouping policy.
- [ ] Repeat end-to-end test.
- [ ] Document final configuration and measured result.

---

# 8. Pi-hole Maintenance / Reporting — 🟡 ACTIVE BACKLOG

- [ ] Remove synthetic Pi-hole enforcement-probe traffic from raw seven-day client/category Prometheus totals while retaining all five active DNS block tests.
- [ ] Maintain weekly automatic blocklist updates.
- [ ] Confirm list-update metrics and enforcement-health metrics.
- [ ] Continue category enforcement monitoring for general/adult/gambling/threat/bypass policies.
- [ ] Maintain Pi-hole dashboard/reporting.
- [ ] Maintain weekly email reporting.
- [ ] Ensure both future DNS nodes receive equivalent monitoring.

---

# 9. Monitoring / Grafana / Prometheus / Loki — 🟡 ONGOING

- [ ] Add Proxmox to Prometheus/Grafana.
- [ ] Continue Network Host Overview dashboard work.
- [ ] Finish/validate hostname-variable behaviour.
- [ ] Build installed-software/version/update dashboard.
- [ ] Add weekly software/update email report.
- [ ] Review cAdvisor usage and whether it remains justified.
- [ ] Review CrowdSec monitoring/usage.
- [ ] Investigate CrowdSec reporting synchronisation / DNS resolution.
- [ ] Continue Alloy migration review.
- [ ] Decide where Promtail can be retired after Alloy replacement is proven.
- [ ] Review elevated Promtail/cAdvisor CPU where applicable.
- [ ] Restore and verify Suricata 24-hour collection after collection timeout.
- [ ] Improve Suricata dashboards.
- [ ] Add Greenbone → Loki ingestion health check.
- [ ] Continue homelab Hardware Health dashboard validation.
- [ ] Tapo → Grafana proof of concept.

---

# 10. Security / Greenbone / IDS — 🟡 ONGOING

- [ ] Review current automated Greenbone findings.
- [ ] Continue daily/weekly scan automation validation.
- [ ] Finish any remaining Greenbone AI/security-reader runtime work.
- [ ] Review accepted-risk handling/suppression.
- [ ] Add Proxmox and future VMs to Greenbone.
- [ ] Add further internal scanning/pentesting capability to `ids-01`.
- [ ] Continue security baseline hardening.
- [ ] Review CrowdSec usage.
- [ ] Review unnecessary network services/ports.
- [ ] Secure/retire switch HTTP management if still applicable.
- [ ] Keep `ids-01` independent from Proxmox.

---

# 11. k3s Secrets Encryption — 🟡 UNFINISHED

- [ ] Resume investigation into secret-encryption start-stage failures.
- [ ] Inspect k3s server logs around encryption errors.
- [ ] Determine why start-stage validation fails.
- [ ] Validate persistent encryption configuration.
- [ ] Validate restart behaviour.
- [ ] Confirm encryption status.
- [ ] Confirm Kubernetes Secrets are encrypted at rest.
- [ ] Complete without unnecessary manual workload mutation.
- [ ] Document final result and recovery implications.

---

# 12. Unknown Client / Blocked-MAC Monitoring — 🧪 PENDING VERIFICATION

Known investigated client: `192.168.2.159`; blocked MAC `be:ba:54:d7:ec:6f`.

- [x] Blocked-MAC monitoring implementation completed.
- [ ] Validate on a real blocked-MAC trigger.
- [ ] Keep MAC blocked unless positively identified.
- [ ] Alert if the device returns.
- [ ] Improve generic unknown-MAC alerting.
- [ ] Correlate Pi-hole, ASUS DHCP and Suricata evidence.
- [ ] Capture DNS/network activity if the device returns.
- [ ] Close investigation when identification/confidence is sufficient.

---

# 13. ASUS Router / Network Log Ingestion — 🟡 BACKLOG

- [ ] Get useful ASUS router syslog into the logging platform.
- [ ] Route logs through Alloy/Loki.
- [ ] Confirm DHCP/client events are retained.
- [ ] Build queries/dashboard for new clients.
- [ ] Correlate router logs with Pi-hole and Suricata.
- [ ] Add alerting for genuinely unknown devices.

---

# 14. Secrets, Backup and Configuration Management — 🟡 ONGOING

- [ ] Complete `.env`/secret backup to USB.
- [ ] Maintain interim protected backup under `/home/james` where required.
- [ ] Verify secrets/config backups can actually be restored.
- [ ] Continue moving Compose/fig definitions into Git.
- [ ] Keep plaintext secrets out of Git.
- [ ] Continue SOPS/age recovery documentation and testing.
- [ ] Document locations/recovery of critical configuration.
- [ ] Apply the same rules to Proxmox IaC.

---

# 15. Engineering Portfolio / Public Project Documentation — 🟡 BACKLOG

- [ ] Continue `projects.jrwroberts.co.uk` documentation.
- [ ] Add/finish Greenbone/OpenVAS project material.
- [ ] Finish ITIL experience article.
- [ ] Include RACI material and links to related leadership/project content.
- [ ] Portfolio/contact form work.
- [ ] Replace the default Astro starter README in the Engineering Portfolio repo with a project-specific README.
- [ ] Keep production deployment/maintenance workflow documentation current.
- [ ] Continue using homelab projects as evidence of engineering, operations and leadership practice.

---

# 16. Homelab Documentation / Data Dictionary — 🟡 ONGOING

- [ ] Continue homelab data dictionary.
- [ ] Keep SOP/SCP/Service Overview indexes current.
- [ ] Classify legacy root-level operational docs progressively without breaking links.
- [ ] Keep important scripts inventory current.
- [ ] Keep service/timer inventories current as hosts change.
- [ ] Keep daily action records in dated folders.
- [ ] Keep this project register aligned with actual project state.

---

# 17. Video Decode Investigation — 🟡 MONITORING

- [ ] Leave increased logging enabled long enough to catch another event.
- [ ] Record the exact timestamp if playback corruption occurs again.
- [ ] Query Loki around the event.
- [ ] Determine whether the issue is decode, stream, client or server related.
- [ ] Restore normal log level once sufficient evidence is captured.

---

# 18. Career / Job Search — 🟡 ONGOING, NON-HOMELAB

Target: leadership-oriented roles that are remote or within roughly 30 minutes of Bournemouth.

- [ ] Continue checking suitable vacancies.
- [ ] Prioritise engineering/IT leadership roles.
- [ ] Apply selectively to strong matches.
- [ ] Track applications/interviews/feedback.
- [ ] Keep portfolio and homelab engineering evidence current for applications.

---

# Pending-verification items to close quickly

These are good candidates for short follow-up checks because most implementation work is already complete:

- [ ] Scheduled WUD scan completes with `0 errors`.
- [ ] High CPU Usage Grafana alert validates on next real trigger.
- [ ] Blocked-MAC monitoring validates on a real trigger.
- [ ] Suricata 24-hour collection returns to expected operation.

---

# Programme-level acceptance criteria

The wider homelab programme can be considered materially complete when:

- Jenkins CI/CD is stable and documented.
- Proxmox is patched, monitored, secured, backed up and recoverable.
- New infrastructure is declared in Git and reproducible through IaC.
- Docker workload definitions and image versions are controlled in Git.
- DNS survives loss of either physical DNS node and does not depend on Proxmox.
- Home Assistant is deployed with backup/restore coverage.
- Production workloads can be rebuilt or restored without relying on undocumented manual steps.
- Monitoring, security scanning and alerting cover the new platform.
- Operational documentation, recovery procedures and project state are current.
