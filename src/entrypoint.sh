#!/bin/bash
set -e

# Remove remote directory
ssh -i <(printf "%b" "$SSH_PRIVATE_KEY") -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" "rm -rf '$REMOTE_PATH'"

# Copy files using scp
if scp -i <(printf "%b" "$SSH_PRIVATE_KEY") -P "$SSH_PORT" -o StrictHostKeyChecking=no -r "$LOCAL_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"; then
  echo "✅ Deployment finished successfully."
else
  status=$?
  echo "::error ::SCP failed with exit code $status"
  exit $status
fi