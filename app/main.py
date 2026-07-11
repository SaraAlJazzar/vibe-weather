"""Vibe Weather — Python FastAPI backend."""

import os
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from network_info import full_diagnostics, network_concepts
from weather import fetch_weather

app = FastAPI(title="Vibe Weather", version="2.0.0")

STATIC_DIR = Path(__file__).parent / "static"
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/api/health")
async def health():
    return {
        "status": "ok",
        "replica": os.environ.get("HOSTNAME", "unknown"),
        "service": "vibe-weather-python",
    }


@app.get("/api/weather")
async def weather(
    city: str = Query(..., min_length=1),
    units: str = Query("metric", pattern="^(metric|imperial)$"),
):
    try:
        return await fetch_weather(city.strip(), units)
    except ValueError as exc:
        raise HTTPException(status_code=502 if "configured" in str(exc) else 400, detail=str(exc))


@app.get("/api/network/diagnostics")
async def network_diagnostics():
    """Ping, traceroute, TCP/UDP probes, routing table, DNS — networking lab."""
    return full_diagnostics()


@app.get("/api/network/concepts")
async def concepts():
    return network_concepts()


@app.get("/")
async def index():
    return FileResponse(STATIC_DIR / "index.html")
