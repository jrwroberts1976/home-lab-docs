# Container Version Control — Stage 4 Secret Readiness Checkpoint

**Date:** 26 August 2026  
**Status:** READ-ONLY SECRET READINESS GATE VALIDATED  
**Implementation repository:** `jrwroberts1976/homelab-container-version-control`

This checkpoint supersedes earlier Stage 4 notes that listed secret readiness as a future control.

## Implementation

Stage 4 now includes a fifth stacked review unit:

```text
#19  stage4/service-ownership
#20  stage4/image-comparator
#21  stage4/candidate-planner
#22  stage4/trivy-gate
#23  stage4/secret-readiness
```

Secret-readiness commit:

```text
05af557  Add Stage 4 secret readiness gate
```

Files:

```text
config/secret-readiness.yml
scripts/validate-secret-readiness.py
```

The validator is read-only and emits metadata-only JSON. It does not print secret values, hashes, decrypted values, SOPS ciphertext or AGE payloads, and it contains no Docker/Compose deployment or Git mutation primitive.

## Registered readiness rules

### Secret-backed services

Three deployed file-backed Compose secrets are currently registered:

| Service | Compose secret | Encrypted recovery source | Recovery key | Runtime file |
|---|---|---|---|---|
| Autokuma | `autokuma_kuma_password` | `secrets/testserver/autokuma.sops.env` | `AUTOKUMA_KUMA_PASSWORD` | `/home/james/docker/secrets/autokuma-kuma-password` |
| Cloudflare DDNS | `cloudflare_api_token` | `secrets/testserver/cloudflare-ddns.sops.env` | `CLOUDFLARE_API_TOKEN` | `/home/james/docker/secrets/cloudflare-api-token` |
| DuckDNS | `duckdns_token` | `secrets/testserver/duckdns.sops.env` | `DUCKDNS_TOKEN` | `/home/james/docker/secrets/duckdns-token` |

Each current secret rule requires:

```text
encrypted recovery source present
SOPS structure valid
expected key encrypted
decryption succeeds
expected key present and non-empty
runtime file present and non-empty
recovered value exactly matches deployed value
runtime mode = 0400
```

Exact values are never emitted by the gate.

### Required non-secret runtime configuration

Autokuma also requires a username that is intentionally not treated as a secret.

Authoritative runtime source:

```text
/home/james/docker/stacks/availability/.env
AUTOKUMA_KUMA_USERNAME
```

Compose maps that variable to:

```text
AUTOKUMA__KUMA__USERNAME
```

The gate verifies source presence, non-empty state and exact source-to-running-container match without displaying the value.

## Security hardening completed during discovery

The readiness discovery found:

```text
/home/james/docker/secrets/autokuma-kuma-password mode=0444
/home/james/docker/secrets/cloudflare-api-token   mode=0400
/home/james/docker/secrets/duckdns-token          mode=0400
```

Before changing Autokuma, compatibility was checked:

```text
container Config.User: default/root
effective process uid: 0
secret readable inside container: yes
container running: yes
restart_count: 0
```

The Autokuma host secret file was then changed from `0444` to `0400`.

After the change:

```text
host secret mode:      0400
container view mode:   0400
process can still read: yes
container running:     yes
restart_count:         0
```

All three registered deployed secret files are now `0400`, so restricted permissions can be a mandatory gate rather than an exception.

## Real estate-wide validation

Authority checkout:

```text
repository: jrwroberts1976/docker-env
revision:   232a364bd929b2ed3ed6ffa37dccd045f8c05843
state:      clean detached checkout
```

Estate-wide result:

```text
rules checked: 4
rules blocked: 0
result:        pass
```

All three secret-backed rules passed:

- Compose service found;
- service secret declaration found;
- top-level Compose secret declaration found;
- registered runtime path matched the Compose file source;
- encrypted source present;
- SOPS structure valid;
- expected key encrypted;
- SOPS decryption successful;
- recovery key present and non-empty;
- deployed runtime file present and non-empty;
- recovered value exactly matched deployed value;
- deployed mode `0400`;
- permission policy satisfied.

The Autokuma username rule also passed exact `.env` to runtime matching.

Deployment state remained:

```json
{
  "allowed": false,
  "performed": false
}
```

## Service-aware behaviour

The validator supports both:

```text
--all
--service <service>
```

Autokuma service-aware validation checked its two registered rules and passed.

Dozzle, which has no registered secret-readiness requirements, correctly returned:

```text
rules checked: 0
rules blocked: 0
result: pass
```

This avoids blocking an unrelated service on another service's secret state.

## Fail-closed matrix

Temporary fixtures were used so no real secret or Compose source had to be modified.

Result:

```text
passed: 6
failed: 0
```

Validated blocks:

1. missing encrypted recovery source;
2. invalid/non-SOPS recovery source;
3. missing expected recovery key;
4. recovered/runtime value mismatch;
5. permission-policy mismatch; and
6. missing required non-secret runtime configuration source.

The real estate baseline remained 4/4 throughout the negative tests.

## Exact staged-blob validation

Before commit, the exact staged registry and validator blobs were materialised and executed.

Validation confirmed:

- exactly the two intended files were staged;
- staged blobs matched the validated worktree copies;
- the exact staged validator compiled;
- the exact staged registry parsed;
- no Docker/Compose deployment or Git mutation primitives were present;
- the staged registry contained metadata only;
- exact staged estate-wide readiness passed 4/4;
- all three secret rules remained exact recovery matches at mode `0400`;
- generated JSON contained no deployed secret values;
- generated JSON contained no SOPS or AGE encrypted payloads;
- Autokuma service-aware validation passed; and
- Dozzle no-rule validation passed.

## Current Stage 4 state

The independently validated read-only controls are now:

```text
ownership resolution
image version comparison
candidate image planning
Trivy candidate security validation
secret readiness validation
```

Remaining non-deploying Stage 4 work:

1. implement local-build provenance handling;
2. produce the non-secret deployment-plan artifact with exact rollback identity; and
3. integrate the independently proven gates into Jenkins while deployment remains disabled.

Automatic deployment remains explicitly outside the current Stage 4 scope.
