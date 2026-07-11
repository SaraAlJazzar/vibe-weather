#!/usr/bin/env bash
# Minimal server setup for Vibe Weather (Python + Nginx)
# Ubuntu 22.04/24.04 — 1 vCPU, 512 MB RAM minimum
#
# Covers: firewall (ufw), ports, Docker, NAT, public IP exposure

set -euo pipefail

APP_DIR="${APP_DIR:-/opt/vibe-weather}"

echo "==> System info (IP addresses, routing)"
echo "Public IP:  $(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo 'unknown')"
echo "Private IP: $(hostname -I | awk '{print $1}')"
ip route show default 2>/dev/null || true
echo ""

echo "==> Updating packages..."
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq

echo "==> Installing Docker (OCI runtime: containerd + runc)..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
fi
sudo apt-get install -y -qq docker-compose-plugin iputils-ping traceroute

echo "==> Enabling BuildKit..."
mkdir -p ~/.docker
if ! grep -q DOCKER_BUILDKIT ~/.docker/config.json 2>/dev/null; then
  echo '{"features":{"buildkit":true}}' | sudo tee /etc/docker/daemon.json >/dev/null 2>&1 || true
  sudo systemctl restart docker 2>/dev/null || true
fi

echo "==> Configuring firewall (ports + Linux firewall)..."
# ufw: allow SSH (22/tcp), HTTP (80/tcp), HTTPS (443/tcp)
# Block direct access to app port 8000 — only Nginx is public
if command -v ufw &>/dev/null; then
  sudo ufw allow OpenSSH comment 'SSH admin access'
  sudo ufw allow 80/tcp comment 'HTTP via Nginx reverse proxy'
  sudo ufw allow 443/tcp comment 'HTTPS via Nginx reverse proxy'
  sudo ufw --force enable
  sudo ufw status verbose
fi

echo "==> Creating app directory..."
sudo mkdir -p "$APP_DIR/nginx/conf.d"
sudo chown -R "$USER:$USER" "$APP_DIR"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Server ready — networking summary                          ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Public IP:   $(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo 'YOUR_IP')"
echo "║  Ports open:  22 (SSH), 80 (HTTP), 443 (HTTPS)              ║"
echo "║  App port:    8000/tcp — internal only (via Docker network)  ║"
echo "║  NAT:         Docker MASQUERADE for container internet egress║"
echo "║  DNS:         Point A record → public IP for custom domain   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "GitHub secrets needed:"
echo "  SERVER_HOST=$(curl -s --max-time 3 ifconfig.me 2>/dev/null || echo '<ip>')"
echo "  SERVER_USER=$USER"
echo "  OPENWEATHER_API_KEY, SSH_PRIVATE_KEY, GHCR_TOKEN (if private)"
