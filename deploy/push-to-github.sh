#!/usr/bin/env bash
# Push vibe-weather to GitHub (run after creating the remote repo)
#
# Usage:
#   ./deploy/push-to-github.sh YOUR_GITHUB_USERNAME
#
# Or set GITHUB_USERNAME env var.

set -euo pipefail

GITHUB_USER="${1:-${GITHUB_USERNAME:-}}"
REPO_NAME="vibe-weather"

if [ -z "$GITHUB_USER" ]; then
  echo "Usage: $0 YOUR_GITHUB_USERNAME"
  exit 1
fi

REMOTE="git@github.com:${GITHUB_USER}/${REPO_NAME}.git"

if ! git remote get-url origin &>/dev/null; then
  git remote add origin "$REMOTE"
else
  git remote set-url origin "$REMOTE"
fi

echo "Remote: $REMOTE"
echo ""
echo "Create the repo first if it doesn't exist:"
echo "  https://github.com/new?name=${REPO_NAME}"
echo ""
read -r -p "Press Enter to push to main (or Ctrl+C to cancel)..."

git push -u origin main

echo ""
echo "Done! Next steps:"
echo "  1. Settings → Actions → General → enable Actions"
echo "  2. Settings → Secrets → add OPENWEATHER_API_KEY, SERVER_HOST, SERVER_USER, SSH_PRIVATE_KEY"
echo "  3. After first build: Packages → vibe-weather → Package settings → Change visibility to Public"
echo "     (or add GHCR_TOKEN secret with read:packages scope)"
