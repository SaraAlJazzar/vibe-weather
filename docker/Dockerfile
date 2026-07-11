# syntax=docker/dockerfile:1.4
# BuildKit enables: parallel stages, cache mounts, OCI-compliant output
# https://docs.docker.com/build/buildkit/

# ── Stage 1: builder ──────────────────────────────────────────────
# Dependencies installed in isolated stage → smaller final image (multi-stage)
FROM python:3.12-slim AS builder

WORKDIR /build

# Layer caching: copy requirements FIRST so code changes don't bust pip cache
COPY app/requirements.txt .

# BuildKit cache mount — persists pip downloads across builds
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --prefix=/install --no-warn-script-location -r requirements.txt

# ── Stage 2: runtime (OCI image) ──────────────────────────────────
# Only runtime artifacts copied — no build tools in final image
FROM python:3.12-slim AS runtime

# OCI image labels (image internals metadata)
LABEL org.opencontainers.image.title="vibe-weather" \
      org.opencontainers.image.description="Python weather app with Nginx reverse proxy" \
      org.opencontainers.image.source="https://github.com/your-username/vibe-weather" \
      org.opencontainers.image.licenses="MIT"

# Install iproute2 (ip route) + ping + traceroute for network diagnostics
RUN apt-get update && apt-get install -y --no-install-recommends \
        iproute2 iputils-ping traceroute \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy installed packages from builder stage (layer reuse)
COPY --from=builder /install /usr/local

# Application code — changes here only invalidate this layer
COPY app/ .

# Non-root user for OCI runtime security
RUN useradd --create-home --uid 1001 appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Health check — TCP HTTP probe
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/api/health')" || exit 1

# OCI runtime entrypoint — executed by containerd → runc
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
