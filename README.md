# 📦 Parcel Tracking Skill for OpenClaw

Automated package tracking with Telegram notifications. Uses the [Parcel](https://parcelapp.net) API to monitor deliveries across 300+ carriers.

## Features

- **Active tracking** — Monitor all parcels via heartbeat polling
- **Status change detection** — Only notifies when something changes
- **Telegram alerts** — `📦 [CARRIER] Package: Status` format
- **300+ carriers** — UPS, FedEx, DHL, Colissimo, Amazon, DPD, Mondial Relay...
- **Rate-limit safe** — Designed for 2-4 checks/day (limit is 20/hour)

## Requirements

- Parcel Premium ($4.99/year) — [parcelapp.net](https://parcelapp.net)
- `bash`, `curl`, `jq`

## Quick Start

```bash
cp config.env.example config.env
# Edit config.env with your API key from https://web.parcelapp.net

# List active parcels
./parcel-list.sh active

# Add a parcel
./parcel-add.sh "1Z999AA10123456784" ups "My Package"

# Check for changes (heartbeat)
./parcel-check.sh
```

## File Structure

```
skills/parcel/
├── parcel-check.sh      # Heartbeat: detect & report status changes
├── parcel-add.sh        # Add new parcel to track
├── parcel-list.sh       # List active/recent parcels
├── config.env.example   # Config template
├── config.env           # Your config (gitignored)
├── SKILL.md             # Internal docs
└── README.md            # This file
```

State tracked in: `memory/parcel-state.json`
