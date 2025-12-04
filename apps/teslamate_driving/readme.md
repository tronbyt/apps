Requires Home Assistant and Teslamate (or compatible API)

Add the following helpers in `configuration.yaml` to get trip progress

```yaml
# Store the total distance for each car
input_number:
  tesla_1_trip_total:
    name: "MyTesla"
    min: 0
    max: 5000
    unit_of_measurement: mi
    icon: mdi:map-marker-distance

template:
  - sensor:
      - name: "MyTesla Progress"
        unique_id: teslamate_1_trip_progress
        unit_of_measurement: "%"
        icon: mdi:progress-clock
        state: >
          {% set current = states('sensor.tesla_active_route_distance_to_arrival') | float(0) %}
          {% set total = states('input_number.tesla_1_trip_total') | float(0) %}
          {% if total > 0 and current <= total %}
            {{ ((1 - (current / total)) * 100) | round(0) }}
          {% else %}
            0
          {% endif %}
```

Add to `automations.yaml`

```yaml
- alias: "Tesla Trip: Set Total Distance"
  trigger:
    - platform: state
      entity_id: sensor.tesla_active_route_destination
  condition:
    # Trigger only when a destination is set (state is not empty/unknown)
    - condition: template
      value_template: "{{ trigger.to_state.state not in ['unknown', 'unavailable', none] and trigger.to_state.state | string | length > 0 }}"
    # Ensure there's a valid distance to set
    - condition: numeric_state
      entity_id: sensor.tesla_active_route_distance_to_arrival
      above: 0
  action:
    - service: input_number.set_value
      target:
        entity_id: input_number.tesla_1_trip_total
      data:
        value: "{{ states('sensor.tesla_active_route_distance_to_arrival') }}"
  mode: single
```
