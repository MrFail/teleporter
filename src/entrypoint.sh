#!/bin/bash
set -e

sudo apt-get update && sudo apt-get install -y sshpass

# Run rsync and capture exit code
if sshpass -p "$SSH_PASSWORD" scp -r -P "$SSH_PORT" -o StrictHostKeyChecking=no "$SOURCE_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"; then
  echo "✅ Deployment finished successfully."
else
  status=$?
  echo "::error ::Rsync failed with exit code $status"
  exit $status
fi
