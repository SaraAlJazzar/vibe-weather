"""OpenWeatherMap API client."""

import os

import httpx

API_KEY = os.environ.get("OPENWEATHER_API_KEY", "").strip()
BASE_URL = "https://api.openweathermap.org/data/2.5/weather"


def _format_api_error(status_code: int, message: str) -> str:
    if status_code == 401:
        return (
            "Invalid API key. Generate a new key at openweathermap.org/api, "
            "update .env, then run: docker compose up -d --force-recreate. "
            "New keys can take up to 2 hours to activate."
        )
    return message or "Failed to fetch weather data"


async def fetch_weather(city: str, units: str = "metric") -> dict:
    if not API_KEY:
        raise ValueError("Weather service is not configured")

    params = {"q": city, "appid": API_KEY, "units": units}
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(BASE_URL, params=params)
        data = response.json()

    if response.status_code != 200:
        raise ValueError(_format_api_error(response.status_code, data.get("message", "")))

    return {
        "city": data["name"],
        "country": data.get("sys", {}).get("country"),
        "temp": round(data["main"]["temp"]),
        "feelsLike": round(data["main"]["feels_like"]),
        "humidity": data["main"]["humidity"],
        "wind": round(data["wind"]["speed"]),
        "description": data["weather"][0]["description"],
        "icon": data["weather"][0]["icon"],
        "units": units,
        "replica": os.environ.get("HOSTNAME", "unknown"),
    }
