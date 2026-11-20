# Stream Gauge for Tronbyt / Tidbyt

Water level at one or two USGS stream gauges: the last few days of readings and, where the National Weather Service forecasts that river, the forecast on the same chart. When a river is forecast to reach flood stage, a flood screen takes over.

## Screens

- **One gauge**: the gauge name, the current water level (stage) in feet with a rising, falling or steady arrow, the flow in cubic feet per second, and a chart. Readings are blue; the forecast is amber, to the right of a dotted line that marks the latest reading.
- **Two gauges**: one row per gauge, each with its name, stage, trend arrow and a small chart.
- **Flood screen**: the gauge name on a band colored by flood level, the level (near flood, minor, moderate or major flood), when and how high the river is forecast to crest, and a chart with the flood stages drawn as dotted lines. With two gauges, the flood screen follows the two-gauge screen for each gauge that's flooding.

The stage turns yellow, orange, red or purple when the river is at a flood stage, and turns grey if the gauge hasn't reported for 3 hours. A grey reading doesn't trigger the flood screen on its own; only the forecast can while the gauge is silent.

With two gauges, if one can't be reached its row says so and the other keeps updating.

## Setup

Pick a **nearby gauge** from the location-based list (USGS stream and lake sites with recent stage data within about 25 km), or enter a **USGS site number** manually: 8 to 15 digits, such as `08108700`. The site number field overrides the picker.

To find a site number by hand:

1. Open the [USGS National Water Dashboard](https://dashboard.waterdata.usgs.gov/) and zoom to your river.
2. Click a gauge. The pop-up shows its name and site number.
3. Or, on the gauge's page on waterdata.usgs.gov, take the number from the address bar: `https://waterdata.usgs.gov/monitoring-location/USGS-08108700/` is site `08108700`.

You can paste the whole page link into the site number field; it picks out the number.

The gauge has to measure water level (gage height, parameter 00065). Most river gauges do; some measure only flow, or lake elevation, and those show "No water level readings".

### Which gauges have forecasts and flood stages?

Forecasts and flood stages come from the National Weather Service, which forecasts a few thousand of the gauges USGS runs. To check a gauge, find it on the [National Water Prediction Service map](https://water.noaa.gov/): gauges with a forecast show one on their hydrograph. Gauges without a forecast still work. The chart shows only readings, and there's no flood screen.

## Options

- **Nearby Gauge** / **Second Nearby Gauge**: choose a place, then a gauge from the list. Optional second gauge for the split screen.
- **USGS Site Number** and **Second Site Number**: optional overrides for either gauge.
- **Label** and **Second Label**: a short name to show instead of the gauge's name. By default the app shortens the name (for example "Brazos River near Bryan" becomes "BRAZOS NR BRYAN") and drops words that don't fit.
- **History**: 3, 7 or 14 days of readings. The forecast adds up to as many days again. The flood screen always checks, and charts, the whole forecast, so a short history never hides a coming crest.
- **Flood Screen**: switch to the flood screen when the river reaches, or is forecast to reach, the gauge's action stage ("near flood"), its flood stage (minor flooding), or never.

## Data

- Readings: [USGS Water Data API](https://api.waterdata.usgs.gov/), refreshed every 15 minutes.
- Forecasts, flood stages, gauge names and flow: [NOAA National Water Prediction Service](https://water.noaa.gov/about/api), refreshed every 15 to 30 minutes. NWS issues new forecasts a few times a day, more often during floods.

Supports 64x32 and 128x64 (2x) displays.

To preview the flood screen without a flood, render with `demo=flood`:

```sh
pixlet render apps/streamgauge/stream_gauge.star demo=flood
```
