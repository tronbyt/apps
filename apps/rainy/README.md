# Rainy?

Tronbyt Pixlet applet (64x32). Two 24-hour rain-intensity bars, today and tomorrow, midnight to midnight.

Work in `D:\MortonWebWorks\rainy` (own folder). AntiGravity is the IDE. Author: SamuLab. Tronbyt only.

- Open-Meteo hourly precipitation and precipitation probability
- Dry hours (< 0.05 mm) get a faint teal tint by chance of rain: 15-24%, 25-39%, 40-59%, 60%+ (blank below 15%). Real rainfall uses the brighter intensity colours.
- Default: Houston, TX
- Catalog slug: `rainy`
- Bars: 2px/hour, 48px, x=8–55. TODAY / TOM labels (tom-thumb). Now-tick on TODAY only.
- Colors: gray → cyan → blue → purple → red. No words inside the bar.

```bat
cd D:\MortonWebWorks\rainy
pixlet check rainy.star
pixlet render rainy.star
pixlet serve rainy.star
```
