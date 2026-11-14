# River Map

A map of a major US river, coloured along its length by the water level at the USGS stream
gauges on it. Colours are worked out at each gauge and blended between gauges.

## Colour By

| Setting | What the colour shows |
| --- | --- |
| Level vs normal | Where today's level sits in the gauge's normal range (its percentile of past levels, or of past flow where USGS has no level history): tan very low, olive low, green normal, cyan high, blue very high. Above a National Weather Service flood stage the NWS colours take over: yellow action, orange minor, red moderate, purple major flooding. |
| Flood stage | How far the river is from low water (10th percentile) to action stage, dark to light blue, then the NWS flood colours. Gauges without NWS flood stages are skipped. |
| Rising or falling | Change over the last 24 hours compared with the gauge's normal range: blue falling, grey steady, orange then red rising. |

## Outlines

None, states, or states and counties. On long rivers county lines would fill the screen, so
they are left out at sizes where they cover too much of it.

## Data

- Live readings: [USGS Water Data API](https://api.waterdata.usgs.gov/), gage height
  (parameter 00065), one request per refresh for all the river's gauges.
- River shapes: NHDPlus V2 mainstems from [geoconnex.us](https://reference.geoconnex.us/collections/mainstems).
- Gauges on each river: [NLDI](https://api.water.usgs.gov/nldi/), thinned so they are at
  least a few pixels apart on the display (at most 30 per river).
- Normal range: percentiles of each gauge's gage height over its period of record (USGS statistics), or of five years of daily means; where a gauge has no gage-height history, of its flow (discharge) instead.
- Flood stages: [NOAA National Water Prediction Service](https://api.water.noaa.gov/nwps/v1/docs/).
- Boundaries: [Census TIGERweb](https://tigerweb.geo.census.gov/).

Everything except the live readings is precomputed and stored in the app by a generator
script, so the app makes a single small request per refresh.

## Regenerating the river data

`gen_rivers.py` in this folder rebuilds the `RIVERS` block at the end of `river_map.star`
(Python 3 and `requests`):

```sh
python gen_rivers.py                  # all rivers
python gen_rivers.py brazos trinity   # just these; the others are kept from the last run
python gen_rivers.py --emit           # rewrite the app from the last run, no network
```

To add a river, add a line to `RIVERS` in the script: its key, label, short label, and the
mainstem's name at the outlet (or `id:<mainstem id>` from geoconnex.us when the name is
ambiguous). Without an API key USGS allows about 1000 requests an hour, so a full run takes
a while; every response is cached (`~/.cache/rivermap`) and a re-run picks up where it
stopped.
