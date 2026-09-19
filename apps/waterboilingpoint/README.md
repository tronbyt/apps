# Water Boiling Point for Tronbyt
Displays the current boiling point for water at a given location.

![Water Boiling Point for Tronbyt](water_boiling_point.webp)  
*The boiling point of water in Denver, Colorado, USA on August 17, 2026.*

## Setup
This app requires an API key from OpenWeather. If you don't already have one, you can get one for free [here](https://home.openweathermap.org/users/sign_up).

Once you sign up and log in, click the `API keys` tab at the top (or click [here](https://home.openweathermap.org/api_keys)). Just copy and paste the generated key into the app's configuration page. The app recalculates the boiling point every hour, which is well within the limits of OpenWeather API's free plan.

## About the boiling point
Liquids [boil](https://en.wikipedia.org/wiki/Boiling_point) whenever their vapor pressure equals the surrounding pressure. For everyday human use, the surrounding pressure is generally the current air pressure, which changes with daily weather patterns.

The boiling point changes with elevation, too. The higher up you go, the less air there is pressing down on you. That causes the air pressure to be comparatively lower than what it would be at ground level. With less air pressure, water can boil at a lower temperature than 100°C (212°F)!

In the image above, you can see water's boiling point is ~95°C (~203°F) in Denver, Colorado. That's because Denver sits at an elevation of 1,610 m (5,280 ft) above sea level. Less air is pressing down on the water, which means it needs less thermal energy to start boiling.

The boiling point for water is calculated using the [Antoine equation](https://en.wikipedia.org/wiki/Antoine_equation). This equation takes the current surrounding pressure as input and outputs the temperature at which a liquid boils. To get the surrounding pressure, the ground level air pressure from OpenWeather for a set location is used. This takes into account both the location's elevation and the current barometric pressure.

The constants used in the equation were empirically derived and are valid for temperature ranges humans encounter every day...like boiling water for pasta!