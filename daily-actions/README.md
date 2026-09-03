# Daily Homelab Actions

Daily operational follow-up notes from the automated homelab security, recovery, monitoring and controlled container-update reviews.

## Maintenance rule

The daily-actions record is the standing operational change log for the homelab.

Whenever a material change is made, update the current date's `daily-actions.md` during the same working session. This includes:

- Incident investigation, remediation and closure.
- Service, container, host, network or security configuration changes.
- Monitoring, alerting, dashboard, metric or email-report changes.
- Backup, recovery, restore-test or resilience changes.
- Secrets-management and access-control changes.
- Operational documentation, runbook or recovery-plan changes.
- Controlled container-version/update work, including candidate identity, approval, deployment, rollback and closure evidence.
- Validation results, remaining risks, follow-up actions and rollback evidence.

If the current date folder or document does not exist, create it using:

```text
daily-actions/YYYY-MM-DD/daily-actions.md
```

A date folder may also contain `todo.md` and focused evidence/runbook notes for substantial workstreams. Record only evidence-backed work. Distinguish completed, fixed, resolved, open and carried-forward items, and do not carry completed work forward as outstanding.

## Daily report triage rule

The automated/nightly homelab report normally arrives at about **08:00 local time**.

- If the report has already arrived when the homelab working session starts, review it before starting planned project work.
- If work starts before the current day's report arrives, continue the planned safe work and review the report as soon as it lands; do not use the previous day's report as a substitute for today's triage.
- Identify any new failures, warnings, security findings, backup/patch issues, monitoring gaps or other actionable follow-ups.
- Deduplicate those findings against the existing TODO/backlog so the same task is not added twice.
- Add genuine new actions to the current date's `todo.md`, with enough evidence/context to make the next safe action clear.
- Record in `daily-actions.md` whether the report produced new tasks, confirmed an existing task, or required no action.
- Do not silently carry an unresolved nightly finding forward: either complete it, explicitly defer it with a reason, or keep it visible in the carried-forward summary.

This nightly-report triage is a recurring daily step, but it is **arrival-driven rather than a reason to block safe work before 08:00**.

## Daily summary rule

Every `daily-actions.md` should finish with a concise end-of-day summary using this structure:

```text
## Daily summary

### Completed today
- evidence-backed work actually completed during that date;
- include merged documentation/source changes, validated fixes and completed operational actions;
- do not repeat work that was merely carried in from a previous day unless it was completed today.

### Carried forward
- only unfinished work that genuinely remains outstanding;
- include the exact next safe action where useful;
- do not carry completed work forward.
```

The summary should be updated during the day as work moves from carried-forward/open to completed. If an item is explicitly deferred, record why and what condition should cause it to be revisited.

## Current day

- **ACTIVE:** [2026-09-03 daily actions](2026-09-03/daily-actions.md)
- **ACTIVE TODO:** [2026-09-03 task list](2026-09-03/todo.md)

## Reports

- [2026-09-03](2026-09-03/daily-actions.md)
- [2026-09-02](2026-09-02/daily-actions.md) — closed; see also [closeout](2026-09-02/closeout.md)
- [2026-09-01](2026-09-01/daily-actions.md)
- [2026-08-31](2026-08-31/daily-actions.md)
- [2026-08-30](2026-08-30/daily-actions.md)
- [2026-08-29](2026-08-29/daily-actions.md)
- [2026-08-28](2026-08-28/daily-actions.md)
- [2026-08-27](2026-08-27/todo.md)
- [2026-08-26](2026-08-26/daily-actions.md)
- [2026-08-25](2026-08-25/daily-actions.md)
- [2026-08-24](2026-08-24/daily-actions.md)
- [2026-08-23](2026-08-23/daily-actions.md)
- [2026-08-22](2026-08-22/daily-actions.md)
- [2026-08-21](2026-08-21/daily-actions.md)

## Structure

Each day is stored in its own date folder using `YYYY-MM-DD`.

Current tail of the structure:

```text
daily-actions/
├── README.md
├── 2026-08-31/
│   ├── daily-actions.md
│   ├── stage6-container-update-closeout.md
│   └── todo.md
├── 2026-09-01/
│   ├── daily-actions.md
│   └── reporting-reconciliation.md
├── 2026-09-02/
│   ├── daily-actions.md
│   └── closeout.md
└── 2026-09-03/
    ├── daily-actions.md
    └── todo.md
```
