#!/usr/bin/env bash
# Minimal server setup for Vibe Weather
# Tested on Ubuntu 22.04 / 24.04 LTS
# Minimum specs: 1 vCPU, 512 MB RAM, 10 GB disk

set -euo pipefail

APP_DIR="${APP_DIR:-/opt/vibe-weather}"

echo "==> Updating system packages..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

echo "==> Installing Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "Docker installed. Log out and back in for group changes, or run: newgrp docker"
fi

echo "==> Installing Docker Compose plugin..."
sudo apt-get install -y -qq docker-compose-plugin

echo "==> Configuring firewall (allow SSH + HTTP)..."
if command -v ufw &>/dev/null; then
  sudo ufw allow OpenSSH
  sudo ufw allow 80/tcp
  sudo ufw --force enable
fi

echo "==> Creating app directory..."
sudo mkdir -p "$APP_DIR"
sudo chown "$USER:$USER" "$APP_DIR"

echo "==> Server ready!"
echo ""
echo "Next steps:"
echo "  1. Add these GitHub repository secrets:"
echo "     - SERVER_HOST       = $(curl -s ifconfig.me 2>/dev/null || echo '<your-server-ip>')"
echo "     - SERVER_USER       = $USER"
echo "     - SSH_PRIVATE_KEY   = (private key matching your server's authorized_keys)"
echo "     - OPENWEATHER_API_KEY = (from https://openweathermap.org/api)"
echo "     - GHCR_TOKEN        = (GitHub PAT with read:packages scope, for private repos)"
echo ""
echo "  2. Push to main branch — CI/CD will deploy automatically."
echo "  3. Visit http://$(curl -s ifconfig.me 2>/dev/null || echo '<your-server-ip>')"
