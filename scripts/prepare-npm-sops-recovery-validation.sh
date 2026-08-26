#!/usr/bin/env bash
set -Eeuo pipefail

# Package the staged encrypted NPM recovery source with a one-way checksum of
# the protected live values and transfer it to DietPi for independent recovery
# identity validation.

WORKTREE="${WORKTREE:-/var/tmp/docker-env-npm-sops}"
ENCRYPTED_REL="secrets/testserver/nginx-proxy-manager.sops.env"
LIVE_ENV="${LIVE_ENV:-/home/james/docker/secrets/npm.env}"
REMOTE="${REMOTE:-dietpi@192.168.2.48}"
REMOTE_ARCHIVE="${REMOTE_ARCHIVE:-/tmp/npm-sops-recovery-validation.tar}"
EXPECTED_HOST="${EXPECTED_HOST:-TestServer}"

TEMP_ROOT=""
ARCHIVE=""

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]] && rm -rf -- "$TEMP_ROOT"
  [[ -n "$ARCHIVE" && -e "$ARCHIVE" ]] && rm -f -- "$ARCHIVE"
}
trap cleanup EXIT HUP INT TERM

printf '%s\n' '===== PREPARE NPM SOPS RECOVERY VALIDATION ====='

[[ "$(hostname -s)" == "$EXPECTED_HOST" ]] || fail "run this on $EXPECTED_HOST"
[[ -d "$WORKTREE/.git" || -f "$WORKTREE/.git" ]] || fail "isolated worktree is unavailable"
[[ -r "$LIVE_ENV" && -s "$LIVE_ENV" ]] || fail "protected live NPM source is unavailable"

ENCRYPTED="$WORKTREE/$ENCRYPTED_REL"
[[ -s "$ENCRYPTED" ]] || fail "staged encrypted source is unavailable"
[[ "$(git -C "$WORKTREE" diff --cached --name-only)" == "$ENCRYPTED_REL" ]] || \
  fail "staged allowlist does not contain exactly the encrypted source"
[[ -z "$(git -C "$WORKTREE" diff --name-only)" ]] || fail "unstaged changes remain"
git -C "$WORKTREE" diff --cached --check

EXPECTED_KEYS=$'NPM_PROXY_ID\nNPM_TOKEN\nNPM_URL'
LIVE_KEYS="$(sed -nE 's/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=.*/\1/p' "$LIVE_ENV" | sort)"
[[ "$LIVE_KEYS" == "$EXPECTED_KEYS" ]] || fail "protected live variable structure is invalid"

TEMP_ROOT="$(mktemp -d /dev/shm/npm-recovery-transfer.XXXXXX)"
ARCHIVE="$(mktemp /tmp/npm-sops-recovery-validation.XXXXXX.tar)"
chmod 0700 "$TEMP_ROOT"
chmod 0600 "$ARCHIVE"
umask 077

install -m 0600 "$ENCRYPTED" "$TEMP_ROOT/nginx-proxy-manager.sops.env"

sed -nE '/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=/p' "$LIVE_ENV" |
  sort |
  sha256sum |
  awk '{print $1}' >"$TEMP_ROOT/expected.sha256"

tar --directory "$TEMP_ROOT" --create --file "$ARCHIVE" \
  nginx-proxy-manager.sops.env expected.sha256

tar --list --file "$ARCHIVE" | sort >"$TEMP_ROOT/archive.list"
EXPECTED_LIST=$'expected.sha256\nnginx-proxy-manager.sops.env'
[[ "$(cat "$TEMP_ROOT/archive.list")" == "$EXPECTED_LIST" ]] || fail "archive allowlist is invalid"

printf '%s\n' 'Encrypted validation package: PASS'
scp "$ARCHIVE" "$REMOTE:$REMOTE_ARCHIVE"
printf '%s\n' 'DietPi transfer: PASS'

rm -f -- "$ARCHIVE"
ARCHIVE=""
printf '%s\n' 'Local validation archive removed: PASS'

printf '\n%s\n' '===== RESULT ====='
printf '%s\n' 'NPM recovery-validation transfer: PASS'
printf '%s\n' 'No credential or private identity was displayed.'
printf '%s\n' 'Nothing was committed, pushed, deployed, restarted or recreated.'
printf '%s\n' 'NEXT: run scripts/dietpi/validate-npm-sops-recovery-identity.sh on DietPi.'
