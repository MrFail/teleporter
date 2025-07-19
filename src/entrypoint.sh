#!/bin/bash
set -e

# OS check: fail on Windows runners
OS_NAME=$(uname -s)
if [[ "$OS_NAME" == MINGW* || "$OS_NAME" == CYGWIN* || "$OS_NAME" == MSYS* ]]; then
  echo "::error ::Windows runners are not supported. Use ubuntu-latest or macos-latest."
  exit 1
fi

# Check rsync availability
if ! command -v rsync >/dev/null 2>&1; then
  echo "::error ::rsync is not installed on this runner."
  exit 1
fi

# Prepare SSH key
mkdir -p ~/.ssh
echo "$SSH_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

# Add host to known_hosts to prevent ssh prompt
ssh-keyscan -H "$REMOTE_HOST" >> ~/.ssh/known_hosts

# Trim and default SOURCE_PATH
SOURCE_PATH="${SOURCE_PATH:-./public/}"
SOURCE_PATH="$(echo -e "${SOURCE_PATH}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

# Prepare rsync filters
RSYNC_FILTERS=""

# Helper trim function
trim() {
  echo "$1" | xargs
}

# Process includes
if [[ -n "$INCLUDES" ]]; then
  IFS=',' read -ra INCLUDE_ITEMS <<< "$INCLUDES"
  for item in "${INCLUDE_ITEMS[@]}"; do
    trimmed=$(trim "$item")
    RSYNC_FILTERS+=" --include=\"$trimmed\""
  done
fi

# Process excludes
if [[ -n "$EXCLUDES" ]]; then
  IFS=',' read -ra EXCLUDE_ITEMS <<< "$EXCLUDES"
  for item in "${EXCLUDE_ITEMS[@]}"; do
    trimmed=$(trim "$item")
    RSYNC_FILTERS+=" --exclude=\"$trimmed\""
  done
fi

# Run rsync and capture exit code
if eval rsync -avz --delete $RSYNC_FILTERS "$SOURCE_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"; then
  echo "✅ Deployment finished successfully."
else
  status=$?
  echo "::error ::Rsync failed with exit code $status"
  exit $status
fi
