# Phase of Moon - Tidbyt/Tronbyt App

Show the current moon phase for your location on a Tidbyt or Tronbyt display, with optional phase text and clock.

![Phase of Moon screenshot](phaseofmoon.webp)

## Features

- Displays the current moon phase image based on the lunar cycle
- Uses your configured location for timezone and hemisphere-aware rendering
- Optional phase label:
  - English text
  - Chinese (simplified) image labels
  - Hidden (no label)
- Optional clock:
  - 12-hour or 24-hour format
  - Optional blinking separator
  - Optional drop-shadow style
- Supports standard and 2x rendering (`supports2x: true`)
- Recommended refresh interval: 5 minutes (`manifest.yaml`)

## Configuration

The app schema exposes these settings:

| Field ID | Required | Description |
| --- | --- | --- |
| `location` | Yes | Location used for moon display and local time timezone |
| `display_text` | No | `English`, `Chinese (simplified)`, or `None` |
| `time_format` | No | `No clock`, `12 hour`, or `24 hour` |
| `clock_position` | No* | Position of clock when clock-only layout is shown (`Top`, `Center`, `Bottom`) |
| `blink_time` | No* | Blink the separator between hours and minutes |
| `has_shadow` | No* | Enable drop-shadow style for clock text |

\* These options appear when `time_format` is not `No clock`.

## Local Development (Pixlet)

From this app directory:

```bash
pixlet check phaseofmoon.star
pixlet render phaseofmoon.star
pixlet serve phaseofmoon.star
```

For 2x testing:

```bash
pixlet render -2 phaseofmoon.star
pixlet serve -2 phaseofmoon.star
```

## How It Works

- Uses a lunar cycle length of `29.53058770576` days and a fixed epoch timestamp (`FIRSTMOON`)
- Computes the current cycle day from current UTC time
- Maps cycle day to one of 8 moon phases using `PHASE_CHANGES`
- Flips the phase image order for southern hemisphere locations (latitude < 0)
- Renders the selected phase image, optional phase label, and optional local-time clock

## File Overview

- `phaseofmoon.star`: Main app logic and schema
- `manifest.yaml`: App metadata and packaging settings
- `images/`: Moon phase artwork and Chinese label assets
- `phaseofmoon.webp`: App preview image

## Credits

- Moon phase calculation approach and phase boundary data:
  - https://minkukel.com/en/various/calculating-moon-phase/
- Moon imagery source attribution in code comments:
  - https://spaceplace.nasa.gov/oreo-moon/en/
- Platform and tooling:
  - https://tidbyt.dev

## License

MIT License (see license header in `phaseofmoon.star`).
