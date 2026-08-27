# Stage 5 Build #2 — CPS-fixed pre-approval boundary proven

Date: 2026-08-27

## Result

Jenkins job `stage5-maintenance-page-pilot` build #2 reached the human approval input while running the merged CPS-fixed Stage 5 pipeline.

## Exact source

- GitHub main / Jenkins workspace commit: `a633d676d85e550f216b75c46674dae474e0db18`
- Jenkinsfile SHA256: `442e38ce1618509681b89208e9fe3dbfa87607fd9bf09985324b0a0739e5bfee`
- Historical build #1 remains terminal `FAILURE` before arm.

## Pre-approval evidence

The build #2 inspection artifact proved:

- pilot `stage5-maintenance-page-nginx-1.31.4-20260827`
- service `maintenance-page`
- current / rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`
- candidate digest `nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913`
- approval required and not yet granted
- `deployment.allowed=false`
- `deployment.performed=false`
- deploy command disabled
- rollback command disabled
- result `ready-for-human-review`

Jenkins then paused at:

`Approve Stage 5 maintenance-page deployment?`

## Security boundary at pause

- executor credential not bound;
- no post-approval stage started;
- enable file absent;
- consumed marker absent;
- active policy remained exact inspection-only policy SHA `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`;
- maintenance-page remained the rollback digest;
- container IDs and restart counts were unchanged;
- pilot armed: false;
- deployment performed: false.

## Status

`STAGE 5 BUILD #2: WAITING FOR HUMAN APPROVAL`

No Stage 5 deployment had been performed at this checkpoint.
