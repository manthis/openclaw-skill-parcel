#!/bin/bash
# parcel-check.sh - Check for parcel status changes (heartbeat use)
# Usage: parcel-check.sh
# Returns: notifications for status changes, or nothing if no changes
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || readlink "$0" || echo "$0")")" && pwd)"
WORKSPACE="$(cd "${SKILL_DIR}/../.." && pwd)"
STATE_FILE="${WORKSPACE}/memory/parcel-state.json"

source "${SKILL_DIR}/config.env" 2>/dev/null || { echo "❌ Missing config.env"; exit 1; }

BASE_URL="https://api.parcel.app/external"

# Ensure memory dir and state file exist
mkdir -p "$(dirname "$STATE_FILE")"
[ -f "$STATE_FILE" ] || echo '{"last_check":0,"deliveries":{}}' > "$STATE_FILE"

# Fetch active deliveries
RESPONSE=$(curl -sf "${BASE_URL}/deliveries/?filter_mode=active" \
  -H "api-key: ${PARCEL_API_KEY}" 2>&1) || { echo "❌ API error"; exit 1; }

NOW=$(date +%s)
CHANGES=""

# Status labels
status_label() {
  case "$1" in
    0) echo "Delivered" ;;
    1) echo "Frozen" ;;
    2) echo "In Transit" ;;
    3) echo "Pickup Ready" ;;
    4) echo "Out for Delivery" ;;
    5) echo "Not Found" ;;
    6) echo "Failed Attempt" ;;
    7) echo "Exception" ;;
    8) echo "Info Received" ;;
    *) echo "Unknown" ;;
  esac
}

status_emoji() {
  case "$1" in
    0) echo "✅" ;;
    3) echo "📍" ;;
    4) echo "🛵" ;;
    6) echo "⚠️" ;;
    7) echo "🚨" ;;
    *) echo "📦" ;;
  esac
}

# Parse each delivery and compare with saved state
DELIVERIES=$(echo "$RESPONSE" | jq -c '.deliveries[]' 2>/dev/null || true)

if [ -z "$DELIVERIES" ]; then
  # No active deliveries — update state and exit
  jq --argjson now "$NOW" '.last_check = $now' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  exit 0
fi

NEW_STATE=$(jq --argjson now "$NOW" '.last_check = $now' "$STATE_FILE")

while IFS= read -r delivery; do
  TN=$(echo "$delivery" | jq -r '.tracking_number')
  STATUS=$(echo "$delivery" | jq -r '.status_code')
  CARRIER=$(echo "$delivery" | jq -r '.carrier_code // "unknown"')
  DESC=$(echo "$delivery" | jq -r '.description // "Package"')
  LAST_EVENT=$(echo "$delivery" | jq -r 'if .events and (.events | length > 0) then .events[0].event else "N/A" end')
  LAST_LOC=$(echo "$delivery" | jq -r 'if .events and (.events | length > 0) then (.events[0].location // "") else "" end')

  # Get previous status from state
  PREV_STATUS=$(echo "$NEW_STATE" | jq -r --arg tn "$TN" '.deliveries[$tn].status_code // -1')
  PREV_EVENT=$(echo "$NEW_STATE" | jq -r --arg tn "$TN" '.deliveries[$tn].last_event // ""')

  # Detect changes
  if [ "$STATUS" != "$PREV_STATUS" ] || [ "$LAST_EVENT" != "$PREV_EVENT" ]; then
    if [ "$PREV_STATUS" != "-1" ]; then
      # Status changed — generate notification
      EMOJI=$(status_emoji "$STATUS")
      LABEL=$(status_label "$STATUS")
      CARRIER_UP=$(echo "$CARRIER" | tr '[:lower:]' '[:upper:]')
      
      MSG="${EMOJI} [${CARRIER_UP}] ${DESC}: ${LABEL}"
      [ "$LAST_EVENT" != "N/A" ] && MSG="${MSG}\n📍 ${LAST_EVENT}"
      [ -n "$LAST_LOC" ] && MSG="${MSG} — ${LAST_LOC}"
      
      CHANGES="${CHANGES}${MSG}\n\n"
    fi
  fi

  # Update state for this delivery
  NEW_STATE=$(echo "$NEW_STATE" | jq --arg tn "$TN" --argjson sc "$STATUS" \
    --arg carrier "$CARRIER" --arg desc "$DESC" --arg ev "$LAST_EVENT" --argjson now "$NOW" \
    '.deliveries[$tn] = {tracking_number: $tn, carrier: $carrier, description: $desc, status_code: $sc, last_event: $ev, last_update: $now}')

done <<< "$DELIVERIES"

# Also clean up delivered parcels from state after 24h
NEW_STATE=$(echo "$NEW_STATE" | jq --argjson now "$NOW" '
  .deliveries |= with_entries(select(.value.status_code != 0 or (.value.last_update > ($now - 86400))))
')

# Save updated state
echo "$NEW_STATE" | jq '.' > "$STATE_FILE"

# Output changes (caller can use this for notifications)
if [ -n "$CHANGES" ]; then
  echo -e "$CHANGES"
fi
