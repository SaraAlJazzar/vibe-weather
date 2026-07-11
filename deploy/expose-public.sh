#!/usr/bin/env bash
# Expose Vibe Weather publicly via ngrok (requires free ngrok account)
# Get authtoken: https://dashboard.ngrok.com/get-started/your-authtoken
set -euo pipefail

if [ -z "${NGROK_AUTHTOKEN:-}" ]; then
  echo "Usage: NGROK_AUTHTOKEN=your_token $0"
  exit 1
fi

ngrok config add-authtoken "$NGROK_AUTHTOKEN"
pkill ngrok 2>/dev/null || true
nohup ngrok http 80 --log=stdout > /tmp/ngrok-vibe.log 2>&1 &
sleep 4
URL=$(curl -s http://127.0.0.1:4040/api/tunnels | python3 -c "import sys,json; t=json.load(sys.stdin).get('tunnels',[]); print(t[0]['public_url'] if t else '')")
echo "Public URL: $URL"
echo "Share this link — anyone can visit the UI"
