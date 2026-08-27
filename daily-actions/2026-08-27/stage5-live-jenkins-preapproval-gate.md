# Stage 5 live Jenkins pilot — pre-approval gate proof

Date: 2026-08-27

## Result

The live Jenkins job `stage5-maintenance-page-pilot` build #1 reached the human approval input and paused there with the Stage 5 pilot still unarmed.

## Proven source identity

- Jenkins job source branch: `main`
- Running workspace commit: `ce224bfece535275d1482b7214a63ef74bde273b`
- Pipeline SHA256: `f33ae0e836866ba78426e85e960981947e06e788415e92f63b37e208b29b1064`

## Pre-approval Jenkins evidence

- Build #1 was active and waiting at the `Human approval` stage.
- Jenkins input message identified:
  - pilot: `stage5-maintenance-page-nginx-1.31.4-20260827`
  - rollback/current: `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`
  - candidate: `nginx@sha256:db35bfc6b2951e7f8a72db5db120288c127ffaeeb4a6d4b95a26fead017d5913`
- Pre-approval inspection succeeded.
- Inspection artifact reported:
  - `approval.required=true`
  - `approval.granted=false`
  - `inspection.allowed=true`
  - `inspection.performed=true`
  - `deployment.allowed=false`
  - `deployment.performed=false`
  - `deployment.deploy_command_enabled=false`
  - `deployment.rollback_command_enabled=false`
  - result `ready-for-human-review`
- Executor credential had not been bound.
- No post-approval stage had started.

## Live TestServer boundary at pause

- enable file absent;
- active Stage 5 policy remained exact inspection-ready SHA256 `adcac66121b04d4b0b4f0a9962c5e75e5c9b3a801a5b28f222f04a6670973f6f`;
- maintenance-page remained exact rollback digest `nginx@sha256:4a73073bd557c65b759505da037898b61f1be6cbcc3c2c3aeac22d2a470c1752`;
- all container IDs/restart counts remained unchanged;
- pilot armed: false;
- no Stage 5 deployment performed.

## Meaning

This proves the key end-to-end security property before first deployment: Jenkins can perform the read-only inspection and reach the explicit human approval gate, but the executor credential is not bound and the execution state machine is not armed before approval.

The next action is the explicit human approval in Jenkins. After approval, the expected sequence is second inspection -> drift comparison -> executor credential binding -> arm -> exact candidate deploy -> terminal disarm, with reviewed rollback on eligible deploy failure.
