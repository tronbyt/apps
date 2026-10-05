# Airplanes Live Overhead

Shows the **single closest aircraft** to a location, using an
[airplanes.live](https://airplanes.live) ADS-B feed — no API key required.
One readable plane beats a cramped list. Renders at **64×32** and **128×64** (2x).

The frame, top to bottom:

- **Callsign** (falls back to registration, then ICAO hex). Scrolls if it overflows.
- **Type · altitude** — e.g. `B738 · 37000ft`, or `GND` when on the ground.
- **Distance · bearing · speed** — e.g. `4.2nm NW · 410kt`.
- A small **plane glyph rotated to the aircraft's heading**.

If any aircraft is squawking an emergency code, it is surfaced ahead of the closest
plane and flagged (`7700 EMERG`, `7600 RADIO`, `7500 HIJACK`) with the frame in red.

## Configuration

| Field | Default | Notes |
|-------|---------|-------|
| **Location** | — | Center point to search around. |
| **Radius (nm)** | `10` | Search radius in nautical miles (clamped 1–250). |
| **Altitude units** | Feet | Feet or meters. |
| **Speed units** | Knots | Knots or MPH. Distance follows it — knots → `nm`, MPH → `mi`. |
| **Airborne only** | off | Skip aircraft on the ground. |
| **Highlight emergencies** | on | Surface any 7500/7600/7700 squawk first. |
| **Hide when no aircraft** | off | Skip the app in rotation when nothing is in range. |

## Data source & terms

Aircraft data is provided by [airplanes.live](https://airplanes.live) via its public
[REST API](https://airplanes.live/api-guide/). This app is an independent project and is
not affiliated with or endorsed by airplanes.live.

- **Personal, non-commercial, educational use only.** For commercial use, see their
  [commercial data options](https://airplanes.live/commercial-use/).
- **Max 1 request/second.** The app fetches with a 45-second cache TTL, so each device
  stays well under the limit.
- The API is provided with **no SLA and no uptime guarantee**.

airplanes.live is a community-funded network of volunteer feeders. If you rely on this
data, please [support them](https://airplanes.live/donate/).
