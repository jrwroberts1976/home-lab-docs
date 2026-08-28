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

## Reports

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

Example:

```text
daily-actions/
├── README.md
├── 2026-08-21/
│   └── daily-actions.md
├── 2026-08-22/
│   └── daily-actions.md
├── 2026-08-23/
│   └── daily-actions.md
├── 2026-08-24/
│   └── daily-actions.md
├── 2026-08-25/
│   └── daily-actions.md
├── 2026-08-26/
│   └── daily-actions.md
├── 2026-08-27/
│   ├── todo.md
│   └── stage*.md
└── 2026-08-28/
    ├── daily-actions.md
    ├── todo.md
    └── stage6-prometheus-starting-point.md
```
