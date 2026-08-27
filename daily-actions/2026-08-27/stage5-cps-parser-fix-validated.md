# Stage 5 Jenkins CPS parser fix validated

Date: 2026-08-27

## Context

Stage 5 Jenkins build #1 was intentionally fail-closed before `Arm exact pilot` because Jenkins CPS serialization failed in the post-approval drift-check stage with `java.io.NotSerializableException: groovy.json.JsonSlurperClassic`.

The root cause was the Jenkinsfile pattern:

```groovy
new groovy.json.JsonSlurperClassic().parseText(readFile(...))
```

Because `readFile` is a Jenkins Pipeline step that may suspend, the surrounding `JsonSlurperClassic` instance could become part of the CPS continuation and require serialization.

## Fix branch

Repository: `jrwroberts1976/homelab-container-version-control`

Branch: `stage5/jenkins-cps-parser-fix`

Base/main: `ce224bfece535275d1482b7214a63ef74bde273b`

Validated head: `8af7e6f53acd084794c300b83b46552e4142c6eb`

The branch is exactly two commits ahead and zero behind.

Changed files only:

- `Jenkinsfile.stage5-maintenance-page-pilot`
- `scripts/validate-stage5-jenkins-human-approval-pipeline.sh`

No Stage 4 source, host helper, policy, SSH wrapper, or sudo boundary source changed.

## CPS parser correction

All five unsafe post-approval parse sites were changed so the pipeline step completes first, for example:

```groovy
def raw = readFile('artifacts/stage5-arm.json')
def a = new groovy.json.JsonSlurperClassic().parseText(raw)
```

The fixed pipeline contains:

- 7 `JsonSlurperClassic().parseText(...)` calls;
- 7 separate `readFile(...)` calls;
- zero nested `parseText(readFile(...))` patterns.

The validator now explicitly fails if `JsonSlurperClassic().parseText(...)` directly nests a `readFile(...)` pipeline step.

## Validation results

Static Stage 5 validator: PASS.

Security ordering retained:

- inspector credential before approval;
- approval restricted to `james` and recorded;
- second inspection after approval;
- drift gate before executor credential binding;
- literal `inspect`, `arm`, `deploy`, `rollback`, `disarm` actions only;
- reviewed rollback path and fail-closed recovery contract unchanged.

Live Jenkins Declarative Pipeline linter:

```text
Jenkinsfile successfully validated.
declarative_linter_rc=0
```

Fixed pipeline SHA256:

`442e38ce1618509681b89208e9fe3dbfa87607fd9bf09985324b0a0739e5bfee`

## Live state during validation

Build #1 remained recorded as `FAILURE` and fail-closed.

Build #2 did not exist; Jenkins `nextBuildNumber` remained 2.

TestServer state remained:

- enable file absent;
- active policy SHA256 `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`;
- active policy inspection-only;
- consumed marker absent;
- maintenance-page on rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`;
- candidate not deployed.

## Conclusion

`STAGE 5 CPS PARSER FIX: READY FOR PR REVIEW`

No Stage 5 deployment was performed during this validation.
