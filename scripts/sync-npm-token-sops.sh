#!/usr/bin/env bash
set -Eeuo pipefail

# Synchronise TestServer's protected NPM environment file into its SOPS recovery
# source. This script deliberately stops after staging the encrypted file.

REPOSITORY="${REPOSITORY:-/home/james/docker}"
WORKTREE="${WORKTREE:-/var/tmp/docker-env-npm-sops}"
BRANCH="${BRANCH:-security/sync-npm-token-sops}"
LIVE_ENV="${LIVE_ENV:-/home/james/docker/secrets/npm.env}"
ENCRYPTED_REL="secrets/testserver/nginx-proxy-manager.sops.env"
IDENTITY="${SOPS_AGE_KEY_FILE:-/home/james/.config/sops/age/keys.txt}"
EXPECTED_HOST="${EXPECTED_HOST:-TestServer}"

TEMP_ROOT=""

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  unset LIVE_TOKEN RECOVERY_TOKEN
  if [[ -n "$TEMP_ROOT" && -d "$TEMP_ROOT" ]]; then
    rm -rf -- "$TEMP_ROOT"
  fi
}
trap cleanup EXIT HUP INT TERM

printf '%s\n' '===== SYNC NPM TOKEN TO SOPS RECOVERY SOURCE ====='

[[ "$(hostname -s)" == "$EXPECTED_HOST" ]] || fail "run this on $EXPECTED_HOST"
[[ -d "$REPOSITORY/.git" ]] || fail "repository not found: $REPOSITORY"
[[ -r "$LIVE_ENV" && -s "$LIVE_ENV" ]] || fail "live environment file is unavailable"
[[ -r "$IDENTITY" && -s "$IDENTITY" ]] || fail "operational age identity is unavailable"
command -v git >/dev/null || fail "git is unavailable"
command -v sops >/dev/null || fail "sops is unavailable"

LIVE_KEYS="$(sed -nE 's/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=.*/\1/p' "$LIVE_ENV" | sort)"
EXPECTED_KEYS=$'NPM_PROXY_ID\nNPM_TOKEN\nNPM_URL'
[[ "$LIVE_KEYS" == "$EXPECTED_KEYS" ]] || fail "live NPM variable structure is not the expected exact set"

git -C "$REPOSITORY" fetch origin --prune
[[ "$(git -C "$REPOSITORY" rev-parse HEAD)" == "$(git -C "$REPOSITORY" rev-parse origin/main)" ]] || \
  fail "original checkout is not at origin/main; synchronise it first"

if [[ -e "$WORKTREE" ]]; then
  fail "worktree path already exists: $WORKTREE"
fi

if git -C "$REPOSITORY" show-ref --verify --quiet "refs/heads/$BRANCH"; then
  fail "local branch already exists: $BRANCH"
fi

if git -C "$REPOSITORY" ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  fail "remote branch already exists: $BRANCH"
fi

git -C "$REPOSITORY" worktree add -b "$BRANCH" "$WORKTREE" origin/main

TARGET="$WORKTREE/$ENCRYPTED_REL"
[[ -s "$TARGET" ]] || fail "encrypted recovery source is unavailable in the worktree"

TEMP_ROOT="$(mktemp -d /dev/shm/npm-sops-sync.XXXXXX)"
chmod 0700 "$TEMP_ROOT"
umask 077

DECRYPTED="$TEMP_ROOT/current.env"
UPDATED="$TEMP_ROOT/updated.env"
VERIFY="$TEMP_ROOT/verify.env"
ENCRYPTED_NEW="$TEMP_ROOT/nginx-proxy-manager.sops.env"

SOPS_AGE_KEY_FILE="$IDENTITY" sops --decrypt "$TARGET" >"$DECRYPTED"

SOURCE_KEYS="$(sed -nE 's/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=.*/\1/p' "$DECRYPTED" | sort)"
[[ "$SOURCE_KEYS" == "$EXPECTED_KEYS" ]] || fail "encrypted source variable structure is not the expected exact set"

# Replace values by key without placing credentials in argv or output.
awk -F= '
  NR == FNR {
    if ($1 == "NPM_URL" || $1 == "NPM_TOKEN" || $1 == "NPM_PROXY_ID") {
      values[$1] = substr($0, index($0, "=") + 1)
    }
    next
  }
  {
    key = $1
    if (key in values) {
      print key "=" values[key]
    } else {
      print
    }
  }
' "$LIVE_ENV" "$DECRYPTED" >"$UPDATED"

SOPS_AGE_KEY_FILE="$IDENTITY" sops \
  --encrypt \
  --input-type dotenv \
  --output-type dotenv \
  --filename-override "$ENCRYPTED_REL" \
  "$UPDATED" >"$ENCRYPTED_NEW"

chmod 0600 "$ENCRYPTED_NEW"
install -m 0644 "$ENCRYPTED_NEW" "$TARGET"

SOPS_AGE_KEY_FILE="$IDENTITY" sops --decrypt "$TARGET" >"$VERIFY"

normalise_npm() {
  sed -nE '/^(NPM_URL|NPM_TOKEN|NPM_PROXY_ID)=/p' "$1" | sort
}

cmp -s <(normalise_npm "$LIVE_ENV") <(normalise_npm "$VERIFY") || \
  fail "updated recovery source does not exactly match the live NPM variables"

PRIVATE_FINDINGS="$(
  grep -RIlE 'AGE-SECRET-KEY-|BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY' \
    "$WORKTREE" --exclude-dir=.git 2>/dev/null | wc -l
)"
[[ "$PRIVATE_FINDINGS" -eq 0 ]] || fail "private identity material was found in the worktree"

git -C "$WORKTREE" diff --check
git -C "$WORKTREE" add -- "$ENCRYPTED_REL"

STAGED="$(git -C "$WORKTREE" diff --cached --name-only)"
[[ "$STAGED" == "$ENCRYPTED_REL" ]] || fail "staged allowlist does not contain exactly the encrypted source"

printf '\n%s\n' '===== STAGED REVIEW ====='
git -C "$WORKTREE" status --short
git -C "$WORKTREE" diff --cached --stat

printf '\n%s\n' '===== RESULT ====='
printf '%s\n' 'NPM SOPS recovery-source synchronisation: PASS'
printf 'Worktree: %s\n' "$WORKTREE"
printf 'Branch:   %s\n' "$BRANCH"
printf '%s\n' 'The operational identity successfully decrypted the updated source.'
printf '%s\n' 'No credential or private identity was displayed.'
printf '%s\n' 'Nothing was committed, pushed, deployed, restarted or recreated.'
printf '%s\n' 'NEXT: validate the staged encrypted source with the recovery identity before committing.'
