#!/usr/bin/env bash
set -Eeuo pipefail

# Create a long-lived Nginx Proxy Manager API token through the NPM container
# network, validate it, and atomically install it in the protected host file.

NPM_ENV="${NPM_ENV:-/home/james/docker/secrets/npm.env}"
NPM_CONTAINER="${NPM_CONTAINER:-npm}"
NPM_API="${NPM_API:-http://127.0.0.1:81/api}"
TOKEN_EXPIRY="${TOKEN_EXPIRY:-10y}"
EXPECTED_HOST="${EXPECTED_HOST:-TestServer}"

TEMP_ROOT=""
INSTALLED=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  unset NPM_IDENTITY NPM_SECRET BOOTSTRAP_TOKEN NEW_TOKEN
  if [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]]; then
    rm -rf -- "$TEMP_ROOT"
  fi
}
trap cleanup EXIT HUP INT TERM

printf '%s\n' '===== ROTATE NPM API TOKEN ====='

[[ "$(hostname -s)" == "$EXPECTED_HOST" ]] || fail "run this on $EXPECTED_HOST"
[[ -r "$NPM_ENV" && -s "$NPM_ENV" ]] || fail "protected NPM environment file is unavailable"
command -v docker >/dev/null || fail "docker is unavailable"
command -v jq >/dev/null || fail "jq is unavailable"
command -v curl >/dev/null || true
docker inspect "$NPM_CONTAINER" >/dev/null 2>&1 || fail "NPM container is unavailable"
[[ "$(docker inspect -f '{{.State.Running}}' "$NPM_CONTAINER")" == "true" ]] || fail "NPM container is not running"

LIVE_KEYS="$(sed -nE 's/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=.*/\1/p' "$NPM_ENV" | sort)"
EXPECTED_KEYS=$'NPM_PROXY_ID\nNPM_TOKEN\nNPM_URL'
[[ "$LIVE_KEYS" == "$EXPECTED_KEYS" ]] || fail "protected NPM variable structure is not the expected exact set"

NPM_PROXY_ID="$(sed -n 's/^NPM_PROXY_ID=//p' "$NPM_ENV" | tail -1)"
[[ "$NPM_PROXY_ID" =~ ^[0-9]+$ ]] || fail "NPM proxy ID is invalid"

TEMP_ROOT="$(mktemp -d /dev/shm/npm-token-rotation.XXXXXX)"
chmod 0700 "$TEMP_ROOT"
umask 077

LOGIN_JSON="$TEMP_ROOT/login.json"
LOGIN_RAW="$TEMP_ROOT/login.raw"
LOGIN_BODY="$TEMP_ROOT/login-body.json"
REFRESH_RAW="$TEMP_ROOT/refresh.raw"
REFRESH_BODY="$TEMP_ROOT/refresh-body.json"
TOKEN_FILE="$TEMP_ROOT/token"
CANDIDATE="$TEMP_ROOT/npm.env"
BACKUP="$TEMP_ROOT/npm.env.before"

printf 'NPM login email: '
IFS= read -r NPM_IDENTITY </dev/tty
printf 'NPM login password: '
IFS= read -rs NPM_SECRET </dev/tty
printf '\n'
[[ -n "$NPM_IDENTITY" && -n "$NPM_SECRET" ]] || fail "login credentials cannot be empty"

# Construct the request through stdin so credentials do not enter argv.
printf '%s\n%s' "$NPM_IDENTITY" "$NPM_SECRET" |
  jq -Rs 'split("\n") | {identity: .[0], secret: .[1]}' >"$LOGIN_JSON"
unset NPM_SECRET

docker run --rm --network "container:$NPM_CONTAINER" -i \
  curlimages/curl:latest \
  curl --silent --show-error \
    --request POST \
    --header 'Content-Type: application/json' \
    --data-binary @- \
    --write-out $'\n%{http_code}' \
    "$NPM_API/tokens" <"$LOGIN_JSON" >"$LOGIN_RAW"

LOGIN_STATUS="$(tail -1 "$LOGIN_RAW")"
sed '$d' "$LOGIN_RAW" >"$LOGIN_BODY"
printf 'Login HTTP status: %s\n' "$LOGIN_STATUS"
[[ "$LOGIN_STATUS" == "200" ]] || fail "temporary login-token creation failed"

jq -e '.token | type == "string" and length > 0' "$LOGIN_BODY" >/dev/null || \
  fail "login response did not contain a token"
BOOTSTRAP_TOKEN="$(jq -r '.token' "$LOGIN_BODY")"

# The token is injected as an environment variable and expanded only inside the
# short-lived curl container, keeping it out of the host-side argument list.
docker run --rm --network "container:$NPM_CONTAINER" \
  -e NPM_TOKEN="$BOOTSTRAP_TOKEN" \
  -e NPM_API="$NPM_API" \
  -e TOKEN_EXPIRY="$TOKEN_EXPIRY" \
  curlimages/curl:latest \
  sh -eu -c 'curl --silent --show-error \
    --header "Authorization: Bearer ${NPM_TOKEN}" \
    --write-out "\n%{http_code}" \
    "${NPM_API}/tokens?expiry=${TOKEN_EXPIRY}"' >"$REFRESH_RAW"
unset BOOTSTRAP_TOKEN

REFRESH_STATUS="$(tail -1 "$REFRESH_RAW")"
sed '$d' "$REFRESH_RAW" >"$REFRESH_BODY"
printf 'Refresh HTTP status: %s\n' "$REFRESH_STATUS"
[[ "$REFRESH_STATUS" == "200" ]] || fail "long-lived token creation failed"

jq -e '.token | type == "string" and length > 0' "$REFRESH_BODY" >/dev/null || \
  fail "refresh response did not contain a token"
jq -r '.token' "$REFRESH_BODY" >"$TOKEN_FILE"
EXPIRY="$(jq -r '.expires // empty' "$REFRESH_BODY")"
[[ -n "$EXPIRY" ]] || fail "refresh response did not contain an expiry"

EXPIRY_EPOCH="$(date -d "$EXPIRY" +%s 2>/dev/null)" || fail "token expiry is not parseable"
MINIMUM_EPOCH="$(date -d '+9 years' +%s)"
(( EXPIRY_EPOCH >= MINIMUM_EPOCH )) || fail "token expiry is shorter than nine years"
printf 'Token expiry: %s\n' "$EXPIRY"

NEW_TOKEN="$(<"$TOKEN_FILE")"
VALIDATION_STATUS="$(
  docker run --rm --network "container:$NPM_CONTAINER" \
    -e NPM_TOKEN="$NEW_TOKEN" \
    -e NPM_API="$NPM_API" \
    -e NPM_PROXY_ID="$NPM_PROXY_ID" \
    curlimages/curl:latest \
    sh -eu -c 'curl --silent --show-error --output /dev/null \
      --write-out "%{http_code}" \
      --header "Authorization: Bearer ${NPM_TOKEN}" \
      "${NPM_API}/nginx/proxy-hosts/${NPM_PROXY_ID}"'
)"
printf 'New-token proxy-read HTTP status: %s\n' "$VALIDATION_STATUS"
[[ "$VALIDATION_STATUS" == "200" ]] || fail "new token failed proxy-host validation"

cp --preserve=mode,ownership,timestamps "$NPM_ENV" "$BACKUP"

awk -F= '
  NR == FNR { token = $0; next }
  $1 == "NPM_TOKEN" { print "NPM_TOKEN=" token; next }
  { print }
' "$TOKEN_FILE" "$NPM_ENV" >"$CANDIDATE"

CANDIDATE_KEYS="$(sed -nE 's/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=.*/\1/p' "$CANDIDATE" | sort)"
[[ "$CANDIDATE_KEYS" == "$EXPECTED_KEYS" ]] || fail "candidate variable structure is invalid"

INSTALL_TEMP="$(dirname "$NPM_ENV")/.npm.env.new.$$"
install -m 0600 "$CANDIDATE" "$INSTALL_TEMP"
mv -f -- "$INSTALL_TEMP" "$NPM_ENV"
INSTALLED=1

INSTALLED_TOKEN="$(sed -n 's/^NPM_TOKEN=//p' "$NPM_ENV" | tail -1)"
INSTALLED_STATUS="$(
  docker run --rm --network "container:$NPM_CONTAINER" \
    -e NPM_TOKEN="$INSTALLED_TOKEN" \
    -e NPM_API="$NPM_API" \
    -e NPM_PROXY_ID="$NPM_PROXY_ID" \
    curlimages/curl:latest \
    sh -eu -c 'curl --silent --show-error --output /dev/null \
      --write-out "%{http_code}" \
      --header "Authorization: Bearer ${NPM_TOKEN}" \
      "${NPM_API}/nginx/proxy-hosts/${NPM_PROXY_ID}"'
)"
unset INSTALLED_TOKEN NEW_TOKEN
printf 'Installed-token HTTP status: %s\n' "$INSTALLED_STATUS"

if [[ "$INSTALLED_STATUS" != "200" ]]; then
  RESTORE_TEMP="$(dirname "$NPM_ENV")/.npm.env.restore.$$"
  install -m 0600 "$BACKUP" "$RESTORE_TEMP"
  mv -f -- "$RESTORE_TEMP" "$NPM_ENV"
  fail "installed-token validation failed; previous protected file restored"
fi

printf '\n%s\n' '===== RESULT ====='
printf '%s\n' 'NPM long-lived API token rotation: PASS'
printf '%s\n' 'The protected NPM environment file was atomically updated with a validated token.'
printf '%s\n' 'No token or login credential was displayed.'
printf '%s\n' 'No proxy host, container or service was changed.'
printf '%s\n' 'NEXT: run scripts/sync-npm-token-sops.sh to update encrypted recovery.'
