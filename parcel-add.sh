#!/bin/bash
# parcel-add.sh - Add a new parcel to track
# Usage: parcel-add.sh <tracking_number> <carrier_code> [description]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || readlink "$0" || echo "$0")")" && pwd)"
source "${SKILL_DIR}/config.env" 2>/dev/null || { echo "❌ Missing config.env"; exit 1; }

BASE_URL="https://api.parcel.app/external"

TRACKING="${1:-}"
CARRIER="${2:-}"
DESC="${3:-}"

if [ -z "$TRACKING" ] || [ -z "$CARRIER" ]; then
  echo "Usage: parcel-add.sh <tracking_number> <carrier_code> [description]"
  echo ""
  echo "Common carriers: ups, fedex, dhl, lp (Colissimo), chronopost, amazon_fr, dpd, mondial_relay"
  echo "Full list: https://api.parcel.app/external/supported_carriers.json"
  exit 1
fi

BODY=$(jq -n \
  --arg tn "$TRACKING" \
  --arg cc "$CARRIER" \
  --arg desc "$DESC" \
  '{tracking_number: $tn, carrier_code: $cc, description: $desc, language: "fr", send_push_confirmation: false}')

RESPONSE=$(curl -sf "${BASE_URL}/add-delivery/" \
  -H "api-key: ${PARCEL_API_KEY}" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "$BODY" 2>&1) || { echo "❌ API error: ${RESPONSE}"; exit 1; }

# Check for error in response
ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
  echo "❌ ${ERROR}"
  exit 1
fi

echo "✅ Parcel added!"
echo "   🔢 ${TRACKING} (${CARRIER})"
[ -n "$DESC" ] && echo "   📝 ${DESC}"
echo "$RESPONSE" | jq -r 'if .uuid then "   🆔 UUID: \(.uuid)" else empty end'
