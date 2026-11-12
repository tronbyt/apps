# Overhead Live

Shows the **single closest aircraft** to a location, using an
[adsb.lol](https://adsb.lol) ADS-B feed — no API key required.
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

Aircraft data is provided by [adsb.lol](https://adsb.lol) via its public
[REST API](https://api.adsb.lol/docs). This app is an independent project and is not
affiliated with or endorsed by adsb.lol.

- **License:** adsb.lol publishes its API and data under the
  [ODbL](https://opendatacommons.org/licenses/odbl/summary/).
- **Free to use, no key today.** adsb.lol says an API key, available by feeding, will be
  required in the future.
- The app fetches with a 45-second cache TTL to keep requests to the API low.

adsb.lol is a community network of volunteer feeders. If you rely on this data, consider
[feeding it](https://adsb.lol/).
