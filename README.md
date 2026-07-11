# Vibe Weather

A modern weather web app powered by the [OpenWeatherMap API](https://openweathermap.org/api), containerized with Docker, and deployed automatically via GitHub Actions.

## Features

- Search weather by city name (metric / imperial)
- Responsive dark UI
- Dockerized Node.js backend
- CI/CD: push to `main` → build image → push to GHCR → deploy to server
- Public access on port 80

## Quick Start (Local)

```bash
cp .env.example .env
# Add your OpenWeatherMap API key to .env

npm install
npm start
# Open http://localhost:3000
```

Or with Docker:

```bash
docker compose up --build
```

## Server Requirements (Minimum)

| Resource | Minimum |
|----------|---------|
| CPU      | 1 vCPU  |
| RAM      | 512 MB  |
| Disk     | 10 GB   |
| OS       | Ubuntu 22.04+ |
| Ports    | 22 (SSH), 80 (HTTP) |

Recommended providers: [Hetzner CX11](https://www.hetzner.com/cloud) (~€4/mo), [DigitalOcean Basic](https://www.digitalocean.com/pricing/droplets) ($4/mo), [AWS t4g.micro](https://aws.amazon.com/ec2/instance-types/t4/) (free tier eligible).

## One-Time Server Setup

SSH into your new server and run:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/vibe-weather/main/deploy/setup-server.sh | bash
```

Or clone the repo and run `./deploy/setup-server.sh`.

Add the deploy public key to `~/.ssh/authorized_keys`:

```bash
# Run locally
./deploy/generate-deploy-key.sh
# Copy deploy_key.pub content to server's ~/.ssh/authorized_keys
```

## GitHub Secrets

Add these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `OPENWEATHER_API_KEY` | From [openweathermap.org/api](https://openweathermap.org/api) |
| `SERVER_HOST` | Server public IP or domain |
| `SERVER_USER` | SSH username (e.g. `ubuntu`, `root`) |
| `SSH_PRIVATE_KEY` | Private key from `deploy/generate-deploy-key.sh` |
| `GHCR_TOKEN` | GitHub PAT with `read:packages` (only if repo/package is private) |

`GITHUB_TOKEN` is provided automatically for pushing to GitHub Container Registry.

## CI/CD Pipeline

On every push to `main`:

1. **Test** — install deps, verify server health endpoint
2. **Build & Push** — build Docker image, push to `ghcr.io/<owner>/vibe-weather:latest`
3. **Deploy** — SSH to server, pull latest image, restart container on port 80

## Manual Docker Push

```bash
docker build -t ghcr.io/YOUR_USERNAME/vibe-weather:latest .
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
docker push ghcr.io/YOUR_USERNAME/vibe-weather:latest
```

## Project Structure

```
vibe-weather/
├── .github/workflows/deploy.yml   # CI/CD pipeline
├── deploy/
│   ├── setup-server.sh            # Server bootstrap script
│   └── generate-deploy-key.sh     # SSH key generator for Actions
├── src/
│   ├── server.js                  # Express API + static files
│   └── public/                    # Frontend UI
├── Dockerfile
├── docker-compose.yml             # Local dev
└── docker-compose.prod.yml        # Production (port 80)
```

## License

MIT
