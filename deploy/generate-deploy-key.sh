#!/usr/bin/env bash
# Generate a deploy SSH key pair for GitHub Actions
# Run locally, then add the public key to your server's authorized_keys

set -euo pipefail

KEY_FILE="${1:-./deploy_key}"

ssh-keygen -t ed25519 -C "github-actions-vibe-weather" -f "$KEY_FILE" -N ""

echo ""
echo "=== Public key (add to server ~/.ssh/authorized_keys) ==="
cat "${KEY_FILE}.pub"
echo ""
echo "=== Private key (add as GitHub secret SSH_PRIVATE_KEY) ==="
cat "$KEY_FILE"
echo ""
echo "Done. Keep the private key secret!"
