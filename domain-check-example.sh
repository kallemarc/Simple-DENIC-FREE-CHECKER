#!/bin/bash
set -euo pipefail

# config
DOMAIN="example.tld"
GOTIFY_URL="https://gotify.example.com"
GOTIFY_TOKEN="YOUR_GOTIFY_TOKEN"
HEALTH_TOKEN="YOUR_HEALTH_TOKEN"
HEALTH_URL="https://health.example.com/health.php"

notify() {
  curl -s -X POST "$GOTIFY_URL/message" \
    -H "X-Gotify-Key: $GOTIFY_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$1\",\"message\":\"$2\",\"priority\":$3}" >/dev/null
}

health_post() {
  resp=$(curl -s -w "%{http_code}" --data-urlencode "payload=$1" "$HEALTH_URL?token=$HEALTH_TOKEN")
  code="${resp: -3}"
  body="${resp::-3}"
  [[ "$code" == "200" && "$body" == *"OK"* ]] || notify "Healthcheck failed" "HTTP $code, Body: $body" 5
}

whois_out=$(whois -h whois.denic.de "$DOMAIN" 2>/dev/null || true)

echo "$whois_out" | grep -q "Status: free" && notify "Domain available" "The domain $DOMAIN is free." 5

health_post "$whois_out"
