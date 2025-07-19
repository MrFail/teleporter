#!/bin/bash
set -e

REMOTE_HOST="$1"
REMOTE_USER="$2"
REMOTE_PATH="$3"
LOCAL_PATH="$4"
PRIVATE_KEY="$5"

echo "🔐 Setting up SSH key..."
mkdir -p ~/.ssh
KEY_FILE=~/.ssh/temp_rsync_key
echo "$PRIVATE_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo "📤 Running rsync..."
rsync -av -e "ssh -i $KEY_FILE -o StrictHostKeyChecking=no" "$LOCAL_PATH"/ "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

echo "🧹 Cleaning up..."
rm "$KEY_FILE"
