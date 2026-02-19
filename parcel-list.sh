#!/bin/bash
# parcel-list.sh - List active/recent parcels
# Usage: parcel-list.sh [active|recent]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SKILL_DIR}/config.env" 2>/dev/null || { echo "❌ Missing config.env (copy from config.env.example)"; exit 1; }

BASE_URL="https://api.parcel.app/external"
MODE="${1:-active}"

STATUS_LABELS='def status_label:
  if . == 0 then "✅ Delivered"
  elif . == 1 then "❄️ Frozen"
  elif . == 2 then "🚚 In Transit"
  elif . == 3 then "📍 Pickup Ready"
  elif . == 4 then "🛵 Out for Delivery"
  elif . == 5 then "❓ Not Found"
  elif . == 6 then "⚠️ Failed Attempt"
  elif . == 7 then "🚨 Exception"
  elif . == 8 then "📋 Info Received"
  else "❓ Unknown (\(.))"
  end;'

RESPONSE=$(curl -sf "${BASE_URL}/deliveries/?filter_mode=${MODE}" \
  -H "api-key: ${PARCEL_API_KEY}" 2>&1) || { echo "❌ API error: ${RESPONSE}"; exit 1; }

COUNT=$(echo "$RESPONSE" | jq '.deliveries | length')

if [ "$COUNT" -eq 0 ]; then
  echo "📦 No ${MODE} parcels."
  exit 0
fi

echo "📦 ${COUNT} ${MODE} parcel(s):"
echo ""

echo "$RESPONSE" | jq -r "${STATUS_LABELS}"'
  .deliveries[] |
  "📦 \(.description // "No description")  [\(.carrier_code | ascii_upcase)]" +
  "\n   🔢 \(.tracking_number)" +
  "\n   📊 \(.status_code | status_label)" +
  (if .date_expected then "\n   📅 Expected: \(.date_expected)" else "" end) +
  (if .events and (.events | length > 0) then "\n   🔔 \(.events[0].event // "N/A") — \(.events[0].location // "")" else "" end) +
  "\n"
'
