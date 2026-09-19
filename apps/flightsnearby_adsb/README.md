# Flights Nearby

Displays information for a random flight that's passing over a specified location.
This app was forked from [flightsnearby](flightsnearby) and uses [adsb.lol](https://adsb.lol) for flight data instead of Flight Radar, since adsb.lol is free.

## Flight info displayed

*   Airline tail graphic
*   Flight origin
*   Flight destination
*   Flight number
*   Aircraft type or aircraft altitude, heading, and speed.

## Configuration

*   Location - location to display nearby flights from.
*   Distance - radius from location to look for flights.
*   Hide - whether to hide (not display) this app if no flights are nearby.
*   Extend - whether to show detailed info about the flight.
*   Logostream API Key (optional) - fetches a tail logo for airlines outside the ~30 built into this app. Get one at https://airline.logostream.dev/pricing. Airline logos provided by [Logostream](https://airline.logostream.dev/). Without a key, the app falls back to its built-in tail images.

## Screenshot
![](flightsnearby_adsb.gif)
