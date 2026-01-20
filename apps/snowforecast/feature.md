This is a tidbyt applet for snow forecast updates.

The user should select what resort they want to see the forecast for (see *.json file for list of resorts)

this app is inspired by
https://snow.fyi/?resorts=keystone
https://catalium.net/launching-snow-fyi/#more-1957

Main Features to include:
- Resort Name
- Last 14 Days of Snowfall
- Next 7 Days of Snowfall
- Next 14 Days of Snowfall

We should have a 2nd screen that shows a graph
The graph should show the next 7 days of snowfall

The API endpoint is
https://api.open-meteo.com/v1/forecast?latitude=39.620608&longitude=-106.356233&hourly=freezing_level_height&daily=snowfall_sum,temperature_2m_max,temperature_2m_min,wind_speed_10m_max,cloud_cover_mean,rain_sum,showers_sum&timezone=auto&forecast_days=14&past_days=14&precipitation_unit=inch&temperature_unit=fahrenheit&wind_speed_unit=mph

The main screen this should be developed for is a 64 wide x 32 high pixel display.  We should give consideration to a 2x scale for the bigger device which is 128 wide x 64 high.

