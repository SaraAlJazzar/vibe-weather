#!/usr/bin/env bash
# Full deployment orchestrator for Vibe Weather
# Prerequisites: gh auth login, optional HCLOUD_TOKEN for Terraform
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/bin:$PATH"

GITHUB_USER="${GITHUB_USER:-SaraAlJazzar}"
REPO="${GITHUB_USER}/vibe-weather"
IMAGE="ghcr.io/$(echo "$GITHUB_USER" | tr '[:upper:]' '[:lower:]')/vibe-weather:latest"

echo "=== 1. GitHub repo + push ==="
if ! gh auth status &>/dev/null; then
  echo "Run: gh auth login --git-protocol ssh --hostname github.com"
  exit 1
fi

if ! gh repo view "$REPO" &>/dev/null; then
  gh repo create "$REPO" --public --source=. --remote=origin --push
else
  git remote add origin "git@github.com:${REPO}.git" 2>/dev/null || git remote set-url origin "git@github.com:${REPO}.git"
  git push -u origin main
fi

echo "=== 2. Build + push Docker image to GHCR ==="
export DOCKER_BUILDKIT=1
TOKEN=$(gh auth token)
echo "$TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin
docker build -f docker/Dockerfile -t "$IMAGE" .
docker push "$IMAGE"

echo "=== 3. Make GHCR package public ==="
echo "→ https://github.com/${GITHUB_USER}?tab=packages → vibe-weather → Package settings → Public"

echo "=== 4. GitHub Actions secrets ==="
source .env
DEPLOY_KEY="$ROOT/deploy/github_actions_key"

if [ ! -f "$DEPLOY_KEY" ]; then
  ./deploy/generate-deploy-key.sh deploy/github_actions_key
fi

if [ -z "${SERVER_HOST:-}" ]; then
  echo ""
  echo "No SERVER_HOST set. Options:"
  echo "  A) Provision Hetzner: cd terraform/hetzner && terraform apply"
  echo "  B) Use existing VPS IP: export SERVER_HOST=your.ip.here"
  read -r -p "Enter SERVER_HOST (or press Enter to skip): " SERVER_HOST
fi

if [ -n "${SERVER_HOST:-}" ]; then
  gh secret set OPENWEATHER_API_KEY --body "$OPENWEATHER_API_KEY"
  gh secret set SERVER_HOST --body "$SERVER_HOST"
  gh secret set SERVER_USER --body "${SERVER_USER:-root}"
  gh secret set SSH_PRIVATE_KEY < "$DEPLOY_KEY"
  gh secret set GHCR_TOKEN --body "$TOKEN"

  echo "=== 5. Add deploy public key to server ==="
  echo "Run on server ($SERVER_HOST):"
  echo "  mkdir -p ~/.ssh && echo '$(cat "${DEPLOY_KEY}.pub")' >> ~/.ssh/authorized_keys"
  echo ""
  echo "=== 6. Trigger deploy ==="
  git commit --allow-empty -m "chore: trigger CI/CD deploy" && git push
  echo ""
  echo "Live at: http://${SERVER_HOST}"
else
  echo "Skipped secrets/deploy — set SERVER_HOST and re-run."
fi
