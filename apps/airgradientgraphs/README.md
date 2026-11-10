# Air Gradient Graphs for Tronbyt / Tidbyt

Bar charts of recent readings from an [AirGradient](https://www.airgradient.com/) air quality monitor (AirGradient ONE or Open Air), so you can see how the air has changed over the last few hours or days, not just what it is right now.

A companion to the [AirGradient](../airgradient/) app by Brombomb, which shows the current readings.

## Setup

The history comes from the [AirGradient cloud API](https://api.airgradient.com/public/docs/api/v1/), so the monitor must be connected to the AirGradient dashboard. You need:

- **Location ID**: the numeric ID shown at [Settings → Locations](https://app.airgradient.com/settings/location). This is **not** the Place ID shown under Place settings.
- **API Key**: your place's API key from [Settings → Place → API](https://app.airgradient.com/settings/place?tab=4).

Until both are set, the app shows sample data.

## Options

- **Layout**
  - **All on one screen**: the layout follows how many charts you pick: 1 is full screen, 2 side by side, 3 is one tall chart on the left with two stacked on the right, 4 is a 2x2 grid, and 5 or 6 is a 3x2 grid.
  - **One per slide**: each chart gets the full screen, one after another. Pick the seconds per slide. The app asks Tronbyt to play the whole slideshow even when it's longer than the app's display time (for example 4 charts × 5 s = 20 s). If you've turned off **Show Full Animation** in this app's settings on the Tronbyt server, slides past the display time are cut.
- **Chart 1 to 6**: CO2, PM2.5, PM1.0, PM10, temperature, humidity, VOC index or NOx index. Metrics your monitor doesn't measure (such as CO2 on an Open Air) are skipped.
- **Time Range**: 1, 3, 6, 12 or 24 hours, 2 days or 7 days. Readings are averaged into as many bars as fit, with the newest bar on the right.
- **Y-Axis Scale**
  - **Auto (zoom to data)**: fits the range of the data, with a minimum span per metric so small sensor noise doesn't look dramatic.
  - **From zero**: bars start at zero, so heights are in true proportion.
  - **Fixed health range**: the same range every time (for example CO2 400–2000 ppm, PM2.5 0–55 µg/m³), widened if a reading goes beyond it.
- **Bar Colors**
  - **Air quality level**: each bar is green, yellow, orange, red or purple by its own value, using AirGradient's thresholds. Temperature and humidity use a fixed color.
  - **Highlight above average**: a grey line shows the average of the last 1–24 hours or 7 days (**Average Window**), and bars above it turn red.
  - **One color per metric**: plain bars.
- **Bar Style**: separate bars, or solid columns with no gaps.
- **Show Labels**: the metric name and latest value above each chart. In small cells the name is shortened (for example `C` for CO2) to make room. If the monitor stops reporting, its last value turns grey.
- **Temperature Unit**: °F or °C.

Supports 64x32 and 128x64 (2x) displays.
