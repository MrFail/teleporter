#!/bin/bash
set -e

sshpass -p "$SSH_PASSWORD" ssh -p "$SSH_PORT" -o StrictHostKeyChecking=no user@remotehost "rm -r '$REMOTE_PATH'"

# Run rsync and capture exit code
if sshpass -p "$SSH_PASSWORD" scp -r -P "$SSH_PORT" -o StrictHostKeyChecking=no "$LOCAL_PATH" "$SSH_USER@$SSH_HOST:$REMOTE_PATH"; then
  echo "✅ Deployment finished successfully."
else
  status=$?
  echo "::error ::Rsync failed with exit code $status"
  exit $status
fi
