# Vibe Weather (Python)

A weather web app built with **Python FastAPI**, **Nginx reverse proxy**, and **Docker** — designed to demonstrate networking and container internals.

## Stack

| Layer | Technology |
|-------|------------|
| Backend | Python 3.12, FastAPI, uvicorn, httpx |
| Reverse Proxy / LB | Nginx (least_conn upstream) |
| API | [OpenWeatherMap](https://openweathermap.org/api) |
| Containers | Multi-stage Dockerfile, BuildKit, OCI runtime |
| Registry | GitHub Container Registry (`ghcr.io`) |
| CI/CD | GitHub Actions → build → push → SSH deploy |

## Architecture

```
Internet → DNS → Firewall (ufw) → Nginx :80/:443 → App replicas :8000 → OpenWeatherMap
                     ↑ public IP          ↑ edge_net    ↑ backend_net (private)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full coverage of:

- VPC / subnet analogy, NAT, public vs private IP
- TCP vs UDP, HTTP vs HTTPS, DNS, Ethernet
- Ping, traceroute, routing, ports & firewall
- Load balancing, multi-stage builds, BuildKit, layer caching
- Docker networking, storage, image internals, OCI runtime
- Compose advanced features, logging drivers, Docker registry

## Quick Start

```bash
cp .env.example .env          # add OPENWEATHER_API_KEY
DOCKER_BUILDKIT=1 docker compose up --build --scale app=2
# → http://localhost  (Nginx on port 80, 2 app replicas load-balanced)
```

## Network Lab UI

Open the **Network Lab** tab in the browser to run live diagnostics:

- Container IPs and routing table
- DNS lookup, TCP/UDP probes
- Ping (ICMP) and traceroute
- Docker/networking concept reference

API: `GET /api/network/diagnostics`

## Local Python Dev (without Docker)

```bash
pip install -r app/requirements.txt
cd app && OPENWEATHER_API_KEY=your_key uvicorn main:app --reload --port 8000
```

## Server Requirements

| Resource | Minimum |
|----------|---------|
| CPU | 1 vCPU |
| RAM | 512 MB |
| OS | Ubuntu 22.04+ |
| Ports | 22, 80, 443 |

## Deploy

1. Run `deploy/setup-server.sh` on your VPS
2. Add GitHub secrets: `OPENWEATHER_API_KEY`, `SERVER_HOST`, `SERVER_USER`, `SSH_PRIVATE_KEY`
3. Push to `main` — CI/CD deploys Nginx + 2 app replicas automatically

## HTTPS

Mount TLS certs to the `cert_data` volume and uncomment the SSL server block in `nginx/conf.d/default.conf`. See architecture docs for certbot steps.

## Project Structure

```
vibe-weather/
├── app/                    # Python FastAPI application
│   ├── main.py
│   ├── weather.py
│   ├── network_info.py     # Ping, traceroute, TCP/UDP diagnostics
│   └── static/             # Frontend UI
├── nginx/                  # Reverse proxy + load balancer
├── docker/Dockerfile       # Multi-stage BuildKit image
├── docker-compose.yml      # Advanced compose (networks, volumes, logging)
├── docs/ARCHITECTURE.md    # Networking & Docker deep dive
└── .github/workflows/      # CI/CD pipeline
```

## License

MIT
