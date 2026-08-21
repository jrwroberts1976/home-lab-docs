# Homelab Hardware Health Dashboard

## Purpose

The **Homelab Hardware Health** Grafana dashboard provides a 24-hour operational view of hardware and kernel fault signals across the homelab.

It is intended to answer a simple BAU question: **are the monitored hosts showing evidence of an underlying hardware, storage, memory, PCIe, thermal or kernel stability problem?**

## Data path

The dashboard queries **Loki** for kernel/system log events collected from jobs matching `systemd-journal|syslog` with `transport="kernel"`.

The dashboard is therefore evidence-based rather than inferred only from utilisation metrics: a host can have normal CPU or memory utilisation while still logging storage, PCIe, thermal or kernel faults.

## Dashboard panels

### Hardware Health

Overall hardware-fault count for the selected host and time range. A value of `0` maps to **Healthy**; one or more matching events moves the panel into the fault threshold.

The aggregate signature set includes storage I/O errors, filesystem errors, SMART-related failures, NVMe resets/timeouts, MMC/SD errors, under-voltage, machine-check/memory/PCIe errors, thermal critical events, watchdog lockups and kernel panics.

### Disk / Filesystem Events

Looks specifically for storage and filesystem fault signatures, including:

- buffer I/O errors
- `blk_update_request`
- critical medium / uncorrectable / bad-sector messages
- SMART failure, pending-sector and reallocated-sector signals
- NVMe critical/reset/timeout/abort messages
- EXT4, XFS and BTRFS errors
- filesystem remount read-only events
- MMC / SDHCI errors and timeouts
- under-voltage events

### CPU / Memory / PCIe Events

Looks for CPU, memory and bus-level fault evidence including:

- machine checks / MCE
- hardware errors
- EDAC / memory failures
- PCIe bus errors
- AER error messages

### Thermal / Panic Events

Looks for serious system-stability events including:

- thermal critical / overheat messages
- watchdog lockups
- kernel panics

### Hardware Events Over Time

Plots matching hardware-event counts over time, grouped by host, to make recurrence and bursts visible.

### Hardware Fault Evidence

Shows the raw matching log lines for investigation. An empty panel is expected when the selected hosts are healthy.

## Host selection

The `host` variable is populated from Loki labels and supports multi-select plus **All**. This makes the same dashboard usable for a single-host investigation or the whole monitored estate.

## Default operating view

- Default time range: **last 24 hours**
- Auto-refresh: **1 minute**
- Timezone: browser
- Host variable: all hosts by default

## BAU use

For routine host-health BAU, this dashboard should be checked alongside the existing host availability, CPU, memory, filesystem capacity and service/container monitoring.

A clean dashboard does not replace patch, capacity or service-health checks, but it means there is no need to repeat an ad-hoc SSH log sweep solely to look for the same hardware/kernel fault signatures already being collected centrally.

## Escalation

Any non-zero result should be followed by the **Hardware Fault Evidence** panel and host-specific investigation. Persistent or recurring events should become a tracked incident rather than being treated as routine BAU.
