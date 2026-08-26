#!/usr/bin/env bash
set -Eeuo pipefail

# Validate the transferred encrypted NPM source using DietPi's protected
# recovery identity. Plaintext exists only in a protected RAM-backed directory.

ARCHIVE="${ARCHIVE:-/tmp/npm-sops-recovery-validation.tar}"
IDENTITY="${SOPS_RECOVERY_IDENTITY:-/mnt/backup/recovery/sops-age/recovery-identity.txt}"
EXPECTED_HOST="${EXPECTED_HOST:-DietPi}"

TEMP_ROOT=""

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]] && rm -rf -- "$TEMP_ROOT"
  [[ -e "$ARCHIVE" ]] && rm -f -- "$ARCHIVE"
}
trap cleanup EXIT HUP INT TERM

printf '%s\n' '===== VALIDATE NPM SOPS SOURCE WITH RECOVERY IDENTITY ====='

[[ "$(hostname -s)" == "$EXPECTED_HOST" ]] || fail "run this on $EXPECTED_HOST"
[[ -s "$ARCHIVE" ]] || fail "validation package is unavailable"
sudo test -s "$IDENTITY" || fail "protected recovery identity is unavailable"
command -v sops >/dev/null || fail "sops is unavailable"

TEMP_ROOT="$(mktemp -d /dev/shm/npm-sops-recovery.XXXXXX)"
chmod 0700 "$TEMP_ROOT"
umask 077

ARCHIVE_LIST="$(tar --list --file "$ARCHIVE" | sort)"
EXPECTED_LIST=$'expected.sha256\nnginx-proxy-manager.sops.env'
[[ "$ARCHIVE_LIST" == "$EXPECTED_LIST" ]] || fail "validation archive contains unexpected paths"

tar --directory "$TEMP_ROOT" --extract --file "$ARCHIVE"

ENCRYPTED="$TEMP_ROOT/nginx-proxy-manager.sops.env"
DECRYPTED="$TEMP_ROOT/recovered.env"
EXPECTED_FILE="$TEMP_ROOT/expected.sha256"
[[ -s "$ENCRYPTED" && -s "$EXPECTED_FILE" ]] || fail "validation package structure is incomplete"

sudo env SOPS_AGE_KEY_FILE="$IDENTITY" sops --decrypt "$ENCRYPTED" >"$DECRYPTED"
printf '%s\n' 'Recovery identity decryption: PASS'

EXPECTED_KEYS=$'NPM_PROXY_ID\nNPM_TOKEN\nNPM_URL'
RECOVERED_KEYS="$(sed -nE 's/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=.*/\1/p' "$DECRYPTED" | sort)"
[[ "$RECOVERED_KEYS" == "$EXPECTED_KEYS" ]] || fail "recovered variable structure is invalid"
printf '%s\n' 'Recovered variable structure: PASS'

EXPECTED_HASH="$(cat "$EXPECTED_FILE")"
[[ "$EXPECTED_HASH" =~ ^[[:xdigit:]]{64}$ ]] || fail "expected checksum is invalid"
RECOVERED_HASH="$(
  sed -nE '/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=/p' "$DECRYPTED" |
    sort |
    sha256sum |
    awk '{print $1}'
)"

[[ "$RECOVERED_HASH" == "$EXPECTED_HASH" ]] || fail "recovered source does not match the protected live source"
unset EXPECTED_HASH RECOVERED_HASH
printf '%s\n' 'Recovery source matches protected live source: PASS'

rm -rf -- "$TEMP_ROOT"
TEMP_ROOT=""
rm -f -- "$ARCHIVE"
printf '%s\n' 'Temporary recovery material removed: PASS'

printf '\n%s\n' '===== RESULT ====='
printf '%s\n' 'DietPi NPM recovery-identity validation: PASS'
printf '%s\n' 'No credential or private identity was displayed.'
printf '%s\n' 'No repository file, container, proxy host or service was changed.'
