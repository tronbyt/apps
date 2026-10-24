# Weather Clock With Date OG

A faithful recreation of the original Tidbyt "OG" weather clock, rebuilt from a reference photo of the original device and later cross-checked against the original app's source for exact font and layout details.

Shows the time (with a blinking colon separator), a weather icon, temperature, and humidity, with an optional day-of-week and date column. Includes a dimmed, clock-only night mode for a configurable overnight window.

## Data

Weather comes from either:

- **National Weather Service** (default) — US locations only, no API key required.
- **OpenWeather** — works globally, requires a free API key.

## Configuration

- Location, 12/24-hour clock, temperature units (imperial/metric)
- Time, temperature, and humidity colors
- Show/hide temperature unit suffix and day/date column
- Blinking colon toggle
- Night mode with configurable start/end time (HHmm)

## Notes

- Built-in `5x8`/`6x13` font digits for `0` and `9` render narrower than other digits at this size, so those two glyphs are hand-drawn replacements spliced in per-character; everything else uses the stock font.
- When OpenWeather is selected without an API key, the app shows a placeholder instead of blank/incorrect data, and the day/date column is hidden to avoid a cramped layout.
