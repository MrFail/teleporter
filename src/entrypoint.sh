#!/usr/bin/env bash
# Sync LOCAL_PATH (its contents) into REMOTE_PATH on the server with rsync over SSH.
# Inputs come from action.yml as environment variables.
set -euo pipefail

fail() {
  echo "::error ::$*"
  exit 1
}

# Split a list separated by spaces / tabs / new lines into the array named $1,
# without glob expansion (a `*.log` pattern must reach rsync as is).
# shellcheck disable=SC2034  # nameref: assigning `out` fills the caller's array
split_list() {
  local -n out=$1
  out=()
  [ -n "${2:-}" ] || return 0
  read -r -d '' -a out < <(printf '%s\0' "${2//$'\r'/}") || true
}

SSH_HOST="${SSH_HOST:-}"
SSH_PORT="${SSH_PORT:-22}"
SSH_USER="${SSH_USER:-}"
SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY:-}"
SSH_KNOWN_HOSTS="${SSH_KNOWN_HOSTS:-}"
LOCAL_PATH="${LOCAL_PATH:-./dist}"
REMOTE_PATH="${REMOTE_PATH:-}"
RSYNC_DELETE="${RSYNC_DELETE:-false}"

# === Validate inputs ===
[ -n "$SSH_HOST" ] || fail "Input 'host' is required."
[ -n "$SSH_USER" ] || fail "Input 'username' is required."
[ -n "$SSH_PRIVATE_KEY" ] || fail "Input 'key' is required."
[ -n "$REMOTE_PATH" ] || fail "Input 'destination' is required."
[[ "$SSH_PORT" =~ ^[0-9]+$ ]] || fail "Input 'port' must be a number, got '$SSH_PORT'."
[ -d "$LOCAL_PATH" ] || fail "Source directory '$LOCAL_PATH' does not exist."
command -v rsync >/dev/null || fail "rsync is not installed on the runner."

# `~/foo` is not expanded inside quotes: make it relative, SSH starts in the home directory.
# shellcheck disable=SC2088  # the literal "~" is matched on purpose
case "$REMOTE_PATH" in
  "~") REMOTE_PATH="." ;;
  "~/"*) REMOTE_PATH="${REMOTE_PATH#\~/}" ;;
esac

# === Private key + known_hosts in a temporary directory, always removed ===
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT
chmod 700 "$WORK_DIR"

KEY_FILE="$WORK_DIR/key"
KNOWN_HOSTS_FILE="$WORK_DIR/known_hosts"

# %b turns a key pasted with literal "\n" into real lines; CRs from Windows editors are dropped.
printf '%b\n' "$SSH_PRIVATE_KEY" | tr -d '\r' > "$KEY_FILE"
chmod 600 "$KEY_FILE"

if [ -n "$SSH_KNOWN_HOSTS" ]; then
  printf '%s\n' "$SSH_KNOWN_HOSTS" | tr -d '\r' > "$KNOWN_HOSTS_FILE"
else
  echo "::warning ::No 'known_hosts' given: trusting the host key scanned now. Pass the output of 'ssh-keyscan -p $SSH_PORT $SSH_HOST' as 'known_hosts' to pin it."
  ssh-keyscan -p "$SSH_PORT" -H "$SSH_HOST" > "$KNOWN_HOSTS_FILE" 2>/dev/null || true
  [ -s "$KNOWN_HOSTS_FILE" ] || fail "Could not read the host key of $SSH_HOST:$SSH_PORT (ssh-keyscan)."
fi

SSH_OPTS=(
  -i "$KEY_FILE"
  -p "$SSH_PORT"
  -o IdentitiesOnly=yes
  -o BatchMode=yes
  -o StrictHostKeyChecking=yes
  -o UserKnownHostsFile="$KNOWN_HOSTS_FILE"
  -o ConnectTimeout=20
)

# === Create the destination (and its parents) ===
# The path is quoted here, on the runner, so the remote shell sees it as one word.
# shellcheck disable=SC2029
ssh "${SSH_OPTS[@]}" "$SSH_USER@$SSH_HOST" "mkdir -p -- $(printf '%q' "$REMOTE_PATH")" \
  || fail "Could not create '$REMOTE_PATH' on $SSH_HOST."

# === rsync arguments ===
split_list EXCLUDES "${RSYNC_EXCLUDE:-}"
split_list INCLUDES "${RSYNC_INCLUDE:-}"
split_list EXTRA_ARGS "${RSYNC_ARGS:-}"

RSYNC_OPTS=(-az --human-readable --stats)
[ "$RSYNC_DELETE" = "true" ] && RSYNC_OPTS+=(--delete)

# Includes go first: rsync applies the first matching rule.
for pattern in "${INCLUDES[@]}"; do
  RSYNC_OPTS+=(--include="$pattern")
done
for pattern in "${EXCLUDES[@]}"; do
  RSYNC_OPTS+=(--exclude="$pattern")
done
RSYNC_OPTS+=("${EXTRA_ARGS[@]}")

# The temporary paths have no spaces, so a plain string is safe for -e.
RSYNC_SSH="ssh ${SSH_OPTS[*]}"

# === Sync: trailing slashes = contents of LOCAL_PATH into REMOTE_PATH ===
echo "Syncing '${LOCAL_PATH%/}/' to $SSH_USER@$SSH_HOST:${REMOTE_PATH%/}/ (delete: $RSYNC_DELETE)"
rsync "${RSYNC_OPTS[@]}" -e "$RSYNC_SSH" \
  "${LOCAL_PATH%/}/" "$SSH_USER@$SSH_HOST:${REMOTE_PATH%/}/" \
  || fail "rsync failed with exit code $?."

echo "✅ Deployment finished successfully."
