#!/usr/bin/env bash
# Test OpenWeatherMap API key from .env (does not print the key)
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Missing .env — copy from .env.example"
  exit 1
fi

# shellcheck disable=SC1091
source .env

if [ -z "${OPENWEATHER_API_KEY:-}" ]; then
  echo "OPENWEATHER_API_KEY is empty in .env"
  exit 1
fi

response=$(curl -s "https://api.openweathermap.org/data/2.5/weather?q=London&appid=${OPENWEATHER_API_KEY}&units=metric")
cod=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cod','?'))")

if [ "$cod" = "200" ]; then
  temp=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin)['main']['temp'])")
  echo "OK — API key works. London temp: ${temp}°C"
  exit 0
fi

message=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message','unknown'))")
echo "FAILED (HTTP cod=$cod): $message"
echo ""
echo "Checklist:"
echo "  1. Verify email at https://home.openweathermap.org/profile"
echo "  2. New keys take up to 2 hours to activate"
echo "  3. Use Current Weather Data (free) — not One Call 3.0"
echo "  4. After updating .env: docker compose up -d --force-recreate --scale app=2"
exit 1
