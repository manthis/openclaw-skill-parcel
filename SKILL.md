# 📦 Parcel Skill

Track package deliveries via [Parcel](https://parcelapp.net) API. Supports 300+ carriers worldwide.

## Setup

1. Get Parcel Premium ($4.99/yr) and generate API key at https://web.parcelapp.net
2. `cp config.env.example config.env` and fill in your key

## Commands

### List active parcels
```bash
skills/parcel/parcel-list.sh [active|recent]
```

### Add a parcel
```bash
skills/parcel/parcel-add.sh <tracking_number> <carrier_code> [description]
```
Common carriers: `ups`, `fedex`, `dhl`, `lp` (Colissimo), `chronopost`, `amazon_fr`, `dpd`, `mondial_relay`

### Check for changes (heartbeat)
```bash
skills/parcel/parcel-check.sh
```
Outputs notification text for any status changes since last check. Returns nothing if no changes.

State is stored in `memory/parcel-state.json`.

## Heartbeat Integration

Add to `HEARTBEAT.md`:
```
### 📦 Parcel Check (2-4x/day)
Run `skills/parcel/parcel-check.sh`. If output is non-empty, send it as Telegram notification.
```

## Rate Limits
- View: 20 req/hour (heartbeat 2-4x/day is safe)
- Add: 20 req/day

## Status Codes
| Code | Meaning |
|------|---------|
| 0 | ✅ Delivered |
| 2 | 🚚 In Transit |
| 3 | 📍 Pickup Ready |
| 4 | 🛵 Out for Delivery |
| 6 | ⚠️ Failed Attempt |
| 7 | 🚨 Exception |
| 8 | 📋 Info Received |
