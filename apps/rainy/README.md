# Rainy?

Tronbyt Pixlet applet (64x32). Two 24-hour rain-intensity bars, today and tomorrow, midnight to midnight.

Work in `D:\MortonWebWorks\rainy` (own folder). AntiGravity is the IDE. Author: SamuLab. Tronbyt only.

- Open-Meteo hourly precipitation
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
