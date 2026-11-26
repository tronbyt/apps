Displays active weather warnings from the Hong Kong Observatory, cycling through each in-force signal as an animation frame.

Each frame shows the official HKO signal icon filling the left half of the screen, with the issued time and a short two-word label on the right. Notable design decisions:

When no warnings are active, a "No Warnings In Force" screen is shown

Descriptions of the warnings can be found here: <https://www.hko.gov.hk/en/wxinfo/dailywx/warnlegend.htm>

The HKO publishes this through its official Open Data API - no key required, JSON, updated as-and-when warnings change. Two endpoints are relevant:
Warning summary (warnsum) - compact, machine-friendly. This applet uses this one
<https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warnsum&lang=en>

Warning information (warningInfo) - the verbose version, with full bulletin text, actionCode (ISSUE/CANCEL/EXTEND/UPDATE) and updateTime:
<https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warningInfo&lang=en>

The API spec can be found here:
<https://data.weather.gov.hk/weatherAPI/doc/HKO_Open_Data_API_Documentation.pdf>
