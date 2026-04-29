# Show the 3 most recent machines in your area

# https://pinballmap.com/api/v1/locations/closest_by_lat_lon.json?lat=40.6781784;lon=-73.9441579;max_distance=10;send_all_within_distance=1;no_details=1

load("encoding/json.star", "json")
load("http.star", "http")
load("images/pbm_logo.png", PBM_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

PBM_LOGO = PBM_LOGO_ASSET.readall()

CACHE_TIME_IN_SECONDS = 600
DEFAULT_MAX_DISTANCE = 10
DEFAULT_LOCATION = json.encode({
    "lat": "40.6781784",
    "lng": "-73.9441579",
    "description": "Brooklyn, NY, USA",
    "locality": "Brooklyn",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/New_York",
})

def main(config):
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    max_distance = config.str("max_distance", DEFAULT_MAX_DISTANCE)

    most_recent_machines_url = "http://pinballmap.com/api/v1/location_machine_xrefs/most_recent_by_lat_lon.json?lat=%s;lon=%s;max_distance=%s" % (location["lat"], location["lng"], max_distance)
    most_recent_machines_data = http.get(most_recent_machines_url, ttl_seconds = CACHE_TIME_IN_SECONDS)
    most_recent_machines = []

    if most_recent_machines_data.status_code != 200:
        print("PBM request failed with status %d" % most_recent_machines_data.status_code)
    else:
        print("Cache hit!" if (most_recent_machines_data.headers.get("Tidbyt-Cache-Status") == "HIT") else "Cache miss!")

    if (len(most_recent_machines_data.json()["most_recently_added_machines"]) > 0):
        for machine in most_recent_machines_data.json()["most_recently_added_machines"]:
            most_recent_machines.append(
                render.Row(
                    children = [
                        render.Marquee(
                            child = render.Text(machine, font = "tom-thumb"),
                            width = 64,
                            offset_start = 32,
                            offset_end = 32,
                            align = "start",
                        ),
                    ],
                ),
            )

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Image(src = PBM_LOGO, width = 6),
                        render.Text(" %s " % location["locality"], font = "tom-thumb"),
                        render.Image(src = PBM_LOGO, width = 6),
                    ],
                    main_align = "center",
                    expanded = True,
                ),
                render.Column(
                    children = most_recent_machines,
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "max_distance",
                name = "Max Distance",
                desc = "The maximum number of miles away you want to monitor",
                icon = "user",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Monitor new machines from this location",
                icon = "locationDot",
            ),
        ],
    )
