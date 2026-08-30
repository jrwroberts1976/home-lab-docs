# OpenTofu — Infrastructure as Code

## Purpose

OpenTofu is the Infrastructure-as-Code (IaC) tool used to define and control infrastructure in the homelab from version-controlled configuration rather than building systems manually through web interfaces.

The first implementation is the Proxmox virtual-machine platform. OpenTofu is being used to describe the desired state of virtual machines — including CPU, memory, disks, networking, cloud-init and lifecycle settings — and then apply those definitions through the Proxmox API.

The goal is not simply to automate VM creation. The goal is to make infrastructure **repeatable, reviewable, recoverable and auditable from Git**.

## What OpenTofu is

OpenTofu is an open-source Infrastructure-as-Code tool. Its configuration language is declarative: instead of writing a script containing every individual command needed to build a server, the configuration describes what the finished infrastructure should look like.

For example, a VM definition can state that a machine should have:

```text
2 CPU cores
2048 MiB RAM
24 GiB disk
vmbr0 network connection
Debian cloud image
cloud-init configuration
QEMU guest-agent support
```

OpenTofu compares that desired state with the infrastructure it already manages and produces a **plan** showing what would need to change.

A typical lifecycle is:

```text
Configuration in Git
        |
        v
    tofu validate
        |
        v
      tofu plan
        |
        v
   human review
        |
        v
     tofu apply
        |
        v
   Proxmox API
        |
        v
 desired VM state
```

OpenTofu keeps a state record so that it can associate objects in the configuration with the real infrastructure it manages.

## Why OpenTofu is being used

The homelab is moving toward a model where infrastructure should be reproducible from source control rather than dependent on undocumented manual configuration.

OpenTofu provides several benefits for this model.

### Repeatability

A VM can be recreated from the same definition instead of relying on somebody remembering which settings were selected in the Proxmox GUI.

### Change visibility

Infrastructure changes appear as normal Git changes. A CPU, RAM, disk or lifecycle change can therefore be reviewed as a diff before anything is altered on the hypervisor.

### Plan before change

`tofu plan` shows the proposed infrastructure mutation before `tofu apply` performs it. This is an important safety gate for the homelab.

### Recovery

If a disposable or replaceable VM is lost, the intention is that its infrastructure definition can be used to rebuild it. Recovery must still include application data, backups and secrets; OpenTofu does not replace those.

### Reduced configuration drift

Repeated planning can show whether the infrastructure still matches the configuration. A zero-change plan provides evidence that the managed infrastructure remains aligned with Git.

### Automation without losing manual recovery

The OpenTofu workflow can later be run from Jenkins, but the same workflow will remain manually executable from an authorised control node. Jenkins must not become the only way to rebuild infrastructure.

## Why OpenTofu instead of manual Proxmox configuration

The Proxmox GUI remains useful for observation and troubleshooting, but manually creating production VMs in the GUI would create configuration that is difficult to reproduce reliably.

The project therefore treats Git/OpenTofu as the authority for managed VM configuration.

The operating principle is:

> Define in Git, review the plan, then change the infrastructure.

Manual changes to OpenTofu-managed VM configuration should be avoided because they can create drift between the source configuration and the live hypervisor.

## OpenTofu and Ansible have different jobs

OpenTofu is not intended to configure everything inside the guest operating system.

The homelab separates responsibilities:

```text
Git
 |
 +--> OpenTofu
 |      |
 |      +--> Proxmox API
 |             |
 |             +--> create VM
 |             +--> CPU / RAM
 |             +--> disk
 |             +--> network
 |             +--> cloud-init
 |             +--> VM lifecycle
 |
 +--> Ansible
        |
        +--> configure Debian
        +--> packages
        +--> services
        +--> monitoring agents
        +--> later application configuration
```

In simple terms:

- **OpenTofu builds and controls the infrastructure.**
- **cloud-init performs the initial guest bootstrap.**
- **Ansible configures the operating system and services.**
- **Jenkins may later orchestrate the workflow.**

Keeping these responsibilities separate makes the automation easier to understand, test and recover.

## Current implementation

The current proof-of-concept uses:

```text
Control node: TestServer
Hypervisor: PROXMOX
OpenTofu: 1.12.6
Provider: bpg/proxmox 0.111.1
Proxmox API identity: iac@pve
Test VM: VM 100 / debian-iac-test-01
```

The first disposable Debian VM has been created through OpenTofu with:

```text
2 vCPU
2048 MiB RAM
24 GiB local-lvm disk
vmbr0 networking
DHCP IPv4
Debian 13 cloud image
cloud-init SSH bootstrap
on-boot disabled
```

The initial control path has proven:

```text
Git
 -> OpenTofu
 -> Proxmox API
 -> VM creation
 -> cloud-init
 -> DHCP
 -> SSH
 -> Ansible
 -> sudo/root configuration
```

The disposable VM is deliberately being used to prove the whole lifecycle before any production workload is migrated.

## Example OpenTofu concept

A simplified VM resource looks conceptually like this:

```hcl
resource "proxmox_virtual_environment_vm" "example" {
  name      = "debian-example-01"
  node_name = "PROXMOX"
  vm_id     = 100

  started = true
  on_boot = false

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = "vmbr0"
  }
}
```

The real Proxmox repository contains additional disk, cloud-image, cloud-init, security and lifecycle configuration.

The important point is that these settings live in source control instead of existing only inside the hypervisor configuration database.

## Change-control workflow

The current manual workflow is deliberately cautious.

### 1. Change the source

Make the required OpenTofu change in the Proxmox Git repository.

### 2. Inspect the Git diff

Confirm that only the intended configuration has changed.

### 3. Commit the intended state

The source change is committed before infrastructure mutation wherever practical.

### 4. Validate

Run:

```bash
tofu fmt -check
tofu validate
```

### 5. Create a saved plan

Run `tofu plan` and save the resulting plan file.

### 6. Review the complete plan

Do not rely only on the summary such as:

```text
Plan: 0 to add, 1 to change, 0 to destroy.
```

The actual attributes being changed must also be reviewed.

### 7. Apply the reviewed plan

Apply the exact saved plan that was inspected.

### 8. Verify the live result

Confirm the resulting VM state through the Proxmox API and, where appropriate, inside the guest.

### 9. Check for drift

A subsequent plan should ideally report no unexpected changes.

## State management

OpenTofu state is critical because it records the relationship between the configuration and the infrastructure OpenTofu manages.

The current disposable proof uses local state on the control node. State files are explicitly excluded from Git.

This is acceptable only for the lab proof.

Before production infrastructure is managed, the project must establish a durable state design covering:

- protected storage;
- backup;
- recovery;
- access control;
- encryption where appropriate;
- locking/concurrent-access protection;
- recovery or import if the original control node is lost;
- Jenkins and manual control using the same authoritative state.

Two separate OpenTofu state files must not independently manage the same VM.

## Secrets and API permissions

OpenTofu connects to Proxmox with a dedicated API identity rather than the root account.

The current identity is:

```text
iac@pve
```

It has narrowly scoped permissions required for VM, storage, node and bridge operations. Missing permissions are added only when proven necessary; provider errors are not solved by granting unrestricted Administrator access.

API token values are stored outside Git and must never be printed into logs or committed.

OpenTofu state must also be treated as sensitive because provider state can contain infrastructure metadata and may contain sensitive values depending on the resources being managed.

## Jenkins integration

Jenkins is planned as an orchestration layer after the reusable VM and durable-state model has been completed.

A future VM-provisioning pipeline is expected to follow this pattern:

```text
Checkout Git
   |
   v
fmt / validate
   |
   v
OpenTofu plan
   |
   v
Review / approval gate
   |
   v
Apply saved plan
   |
   v
Wait for guest bootstrap
   |
   v
Run Ansible baseline
   |
   v
Validate services and monitoring
   |
   v
Final drift/idempotence checks
```

The initial Jenkins implementation should not expose an unrestricted destroy operation.

Jenkins automation must use the same authoritative infrastructure definitions and state as the manual recovery workflow.

## What OpenTofu does not replace

OpenTofu is one part of the recovery model. It does not replace:

- Git backups;
- Proxmox VM backups;
- application/database backups;
- secret recovery;
- Ansible configuration;
- monitoring and alerting;
- disaster-recovery documentation;
- testing that restored systems actually work.

For example, OpenTofu may rebuild a PostgreSQL VM, but the database contents still require a separate backup and restore process.

## Current project gates

Before OpenTofu is used for production workload migration, the project is proving:

- disposable VM creation from Git;
- controlled VM lifecycle changes;
- QEMU guest-agent operation;
- Ansible baseline configuration;
- Ansible idempotence;
- OpenTofu zero-drift planning;
- reusable VM definitions;
- durable state and recovery;
- off-host backup and restore;
- destroy and full rebuild from Git.

Only after those gates are complete should the same model be used for production services.

## Operational rules

1. Git is authoritative for OpenTofu-managed infrastructure.
2. Validate before planning.
3. Review plans before applying them.
4. Prefer applying the exact saved plan that was reviewed.
5. Keep secrets and state out of Git.
6. Do not manually edit managed infrastructure without understanding the resulting drift.
7. Grant API permissions narrowly.
8. Keep a manual recovery path even after Jenkins automation is introduced.
9. Prove backups and recovery before moving production workloads.
10. Use disposable infrastructure to prove destructive/rebuild workflows before relying on them in production.

## Related documentation

- [Proxmox project repository](https://github.com/jrwroberts1976/proxmox)
- [Proxmox Infrastructure as Code runbook](https://github.com/jrwroberts1976/proxmox/blob/iac/bootstrap-opentofu/docs/iac.md)
- [Proxmox project plan](https://github.com/jrwroberts1976/proxmox/blob/iac/bootstrap-opentofu/docs/project-plan.md)
- [Service Overviews index](README.md)

The Proxmox repository contains the implementation-specific OpenTofu configuration and evidence. This Service Overview explains the role OpenTofu plays across the homelab and why it is being adopted.
