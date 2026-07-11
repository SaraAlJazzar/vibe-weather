#!/usr/bin/env bash
# Install GitHub Actions self-hosted runner for local CI/CD deploy
set -euo pipefail

export PATH="$HOME/bin:$PATH"
REPO="SaraAlJazzar/vibe-weather"
RUNNER_DIR="$HOME/actions-runner-vibe-weather"
RUNNER_VERSION="2.321.0"

if ! gh auth status &>/dev/null; then
  echo "Run: gh auth login"
  exit 1
fi

mkdir -p "$RUNNER_DIR" && cd "$RUNNER_DIR"

if [ ! -f ./config.sh ]; then
  curl -sL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    | tar xz
fi

TOKEN=$(gh api "repos/${REPO}/actions/runners/registration-token" --jq .token)

./config.sh \
  --url "https://github.com/${REPO}" \
  --token "$TOKEN" \
  --name "$(hostname)-vibe-weather" \
  --labels "self-hosted,vibe-weather" \
  --unattended \
  --replace

sudo ./svc.sh install "$USER" 2>/dev/null || true
./run.sh &

echo "Self-hosted runner started in background."
echo "Check: gh api repos/${REPO}/actions/runners --jq '.runners[].status'"
