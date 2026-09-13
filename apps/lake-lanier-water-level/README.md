# Lake Lanier Level

Live water-level display for **Lake Sidney Lanier (GA)** on a 64×32 LED matrix.

- **LANIER** label and water temperature along the top
- **Hero number**: feet from full pool (1,071 ft) — green when rising, red when falling
- **Animated wave** colored by alert zone (blue / green / yellow / amber / red)
- **Scrolling ticker** with level, temp, and last-update time
- **Zone color bar** along the bottom

In app settings you can turn **Animate waves** off for a still surface, and turn **Scrolling ticker** off to show only the last-update time (the rest of the ticker repeats the header and hero). Both default on.

Data comes from the [Lanier Level Watch](https://lanierlevel.com) public API (USGS gauge, refreshed hourly).
