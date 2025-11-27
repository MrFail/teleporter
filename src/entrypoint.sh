#!/bin/bash
set -e

# Write the private key to a temp file
KEY_FILE=$(mktemp)
echo -e "$SSH_PRIVATE_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

# Remove remote directory
ssh -i "$KEY_FILE" -p "$SSH_PORT" -o StrictHostKeyChecking=no \
  "$SSH_USER@$SSH_HOST" \
  "rm -rf '$REMOTE_PATH'"

# Copy files using scp
if scp -i "$KEY_FILE" -P "$SSH_PORT" -o StrictHostKeyChecking=no \
    -r "$LOCAL_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"; then
  echo "✅ Deployment finished successfully."
else
  status=$?
  echo "::error ::SCP failed with exit code $status"
  exit $status
fi

# Cleanup private key (security)
rm -f "$KEY_FILE"
