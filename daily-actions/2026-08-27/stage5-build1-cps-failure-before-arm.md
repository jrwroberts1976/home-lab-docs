# Stage 5 build #1 — CPS serialization failure before arm

Date: 2026-08-27

## Outcome

Jenkins Stage 5 pilot build #1 reached the human approval gate, was explicitly approved by `james`, completed the post-approval re-inspection, and then failed in the `Assert no drift after approval` stage before the executor credential was bound for any mutating action.

The Jenkins failure was:

`java.io.NotSerializableException: groovy.json.JsonSlurperClassic`

The failing source pattern was a Jenkins CPS serialization hazard:

`new groovy.json.JsonSlurperClassic().parseText(readFile(...))`

Because `readFile` is a Pipeline step that may suspend, the non-serializable `JsonSlurperClassic` receiver can remain on the CPS continuation stack and Jenkins attempts to serialize it.

## Safety result

The failure occurred before `Arm exact pilot`.

Jenkins skipped:

- `Arm exact pilot`
- `Deploy exact candidate`
- `Rollback on deploy failure`
- `Disarm terminal state`
- final pilot result stage

No Stage 5 deployment was performed by build #1.

## Required source correction

Split Pipeline `readFile(...)` calls from JSON parsing, for example:

```groovy
def raw = readFile('artifact.json')
def parsed = new groovy.json.JsonSlurperClassic().parseText(raw)
```

The same unsafe pattern exists in the drift-check, arm, deploy, rollback and disarm artifact parsing paths and must be corrected together before another pilot attempt.
