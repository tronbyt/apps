# Flights Nearby using Home Assistant and the FlightRadar24 Integration

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/ebe45d5d-7d0d-4974-b46a-772dcaaa796a)

This app requires a functioning Home Assistant instance with the FlightRadar24 Integration configured and running. This app can be run locally on a server/container with pixlet, or it will require your Home Assistant to be reachable from the internet.

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/beae69ce-cebf-414a-985a-83eabf37b29f)

The information can be hardcoded if running locally.

This app will pull tail logos from Airhex using the three letter ICAO code. The filtering of what aircraft to display is done in Home Assistant through the FlightRadar24 integration. The direction of the tail logo can be changed by the user

![image](https://github.com/motoridersd/HomeAssistant-Tidbyt/assets/5197858/5e502229-1701-466f-a03f-ceecb78afb21)

# Configuring the Home Assistant FlightRadar24 integration

It is available on HACS, follow instructions here: https://github.com/AlexandrErohin/home-assistant-flightradar24

The integration asks for a radius in meters, coordinates, a scan interval in seconds, and an altitude range (minimum and maximum). Multiple entities can be added so one can track as many areas as desired and display the flight info from multiple areas by creating multiple copies of the flightsnearby app.

When running locally, I have a script running on an LXC container where pixlet resides that will run the applet with pixlet every time the flight entity changes. This can be run on a timed loop. When there are no flights detected, Home Assistant removes the app.

I created Helper Template Sensors to help trigger when the app should be updated.

sensor.flight_on_tidbyt
```
{% set ns = namespace(matched = 0) %}
{% set data = state_attr('sensor.flightradar24_current_in_area', 'flights') %} {% for flight in data | sort (attribute='altitude') %} {% if flight.altitude > 1000 and flight.airline_iata and ns.matched == 0 %}
{{ flight.flight_number }}
  {%set ns.matched = 1 %}
  {% endif %}
  {% endfor %}
```

sensor.commercial_planes_in_area
```
{% set count = namespace(value=0) %}
{% set data = state_attr('sensor.flightradar24_current_in_area', 'flights') %} {% for flight in data | sort (attribute='altitude') %} {% if flight.altitude > 1000 and flight.airline_iata and not flight.airport_origin_code_iata == 'MYF' and not flight.airport_destination_code_iata == 'MYF' %}
   {% set count.value = count.value +1 %}
{% endif %}
{% endfor %}
{{ count.value }}
```

sensor.flight_on_tidbyt will grab the first match of everything contained in sensor.flightradar24_current_in_area. I sort by altitude (lower first, since I can see them out of my window), and look for flights with an altitude over 1000 ft, that have a value in 'airline_iata' (this means it's a commercial aircraft vs smaller personal/private craft).

sensor.commercial_planes_in_area keeps track of commercial flights, filtering out aircraft I'm not interested in. I added some extra parameters for a smaller airport so any flights to/from MYF won't change the commercial_planes_in_area value.

An automation will run pixlet on my server to update the applet or remove it:

```
alias: Update Flights Nearby on Tidbyt with FlighRadar24 status
description: Uses the Commercial Planes in Area sensor
trigger:
  - platform: state
    entity_id:
      - sensor.commercial_planes_in_area
    enabled: false
  - platform: state
    entity_id:
      - sensor.flight_on_tidbyt
condition: []
action:
  - if:
      - condition: numeric_state
        entity_id: sensor.commercial_planes_in_area
        above: 0
    then:
      - service: switch.turn_on
        metadata: {}
        data: {}
        target:
          entity_id: switch.tidbyt_flights_update_trigger
  - if:
      - condition: numeric_state
        entity_id: sensor.commercial_planes_in_area
        below: 1
    then:
      - service: switch.turn_off
        metadata: {}
        data: {}
        target:
          entity_id: switch.tidbyt_flights_update_trigger
mode: single
```



