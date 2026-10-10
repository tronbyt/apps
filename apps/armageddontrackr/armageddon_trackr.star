"""
Applet: Armageddon Trackr
Summary: Closest Near Earth Object
Description: Provides information from NASA about the nearest Near Earth Object on a given date.
Author: flynnt
"""

load("animation.star", "animation")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/dino.png", DINO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DINO = DINO_ASSET.readall()

BASE_URL = "https://api.nasa.gov/neo/rest/v1/feed"
DEFAULT_UNIT = "miles"
TERMINAL_TEXT_COLOR = "#33ff00"

def main(config):
    """
    App entrypoint.
    Retrieves the nearest earth objects from the NASA NeoWS.
    Returns rendered application root.
    """
    api_key = config.get("api_key")
    if not api_key:
        return render.Root(
            child = render_static_dino(),
        )
    else:
        unit = config.get("distance_key", DEFAULT_UNIT)
        now = time.now()
        pretty_now = now.format("January 2, 2006")
        query_now = now.format("2006-01-02")

        neos = get_neos(query_now, api_key)
        if not neos:
            return render.Root(
                child = render.Box(
                    render.WrappedText("No asteroids today!", color = TERMINAL_TEXT_COLOR),
                ),
            )

        nearest_distance = get_shortest_distance(neos, unit)
        nearest_neo = get_nearest_neo(neos, nearest_distance, unit)
        pretty_distance = humanize.comma(int(nearest_distance))

        date_string = "On {}".format(pretty_now)
        asteroid_string = "Asteroid: \n {}".format(nearest_neo["name"])
        pre_proximity_string = "Will miss the Earth by..."
        distance_string = config.get("distance_key", DEFAULT_UNIT)
        proximity_string = "{} \n {}".format(pretty_distance, distance_string)

        static_dino = [
            render_static_dino()
            for frame in range(30)
        ]

        return render.Root(
            delay = 90,
            show_full_animation = bool(1),
            child = render.Row(
                children = [
                    render.Box(
                        width = 64,
                        child = render.Sequence(
                            children = [
                                render.Animation(generate_string_segments(date_string)),
                                render.Animation(generate_static_string_frames(date_string, 10)),
                                render.Animation(generate_string_segments(asteroid_string)),
                                render.Animation(generate_static_string_frames(asteroid_string, 10)),
                                render.Animation(generate_string_segments(pre_proximity_string)),
                                render.Animation(generate_static_string_frames(pre_proximity_string, 10)),
                                render.Animation(generate_string_segments(proximity_string)),
                                render.Animation(generate_static_string_frames(proximity_string, 10)),
                                animation.Transformation(
                                    child = render.Row(
                                        expanded = bool(1),
                                        cross_align = "end",
                                        main_align = "end",
                                        children = [
                                            render.Box(
                                                height = 32,
                                                width = 34,
                                                child = render.WrappedText("", font = "tom-thumb"),
                                            ),
                                            render.Box(
                                                height = 26,
                                                width = 28,
                                                child = render.Image(DINO),
                                            ),
                                        ],
                                    ),
                                    duration = 8,
                                    keyframes = [
                                        animation.Keyframe(
                                            percentage = 0.0,
                                            transforms = [animation.Translate(0, 32)],
                                            curve = "ease_out",
                                        ),
                                        animation.Keyframe(
                                            percentage = 1.0,
                                            transforms = [animation.Translate(0, 0)],
                                            curve = "ease_out",
                                        ),
                                    ],
                                ),
                                render.Animation(static_dino),
                            ],
                        ),
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "NASA API Key",
                desc = "Your NASA API key. See https://api.nasa.gov/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "distance_key",
                name = "Distance Unit",
                desc = "Unit to use when displaying distances.",
                icon = "gear",
                default = DEFAULT_UNIT,
                options = [
                    schema.Option(
                        display = "Miles",
                        value = "miles",
                    ),
                    schema.Option(
                        display = "Kilometers",
                        value = "kilometers",
                    ),
                ],
            ),
        ],
    )

def get_neos(query_now, api_key):
    params = {
        "api_key": api_key,
        "start_date": query_now,
        "end_date": query_now,
    }
    req = http.get(BASE_URL, ttl_seconds = 3600, params = params)
    if req.status_code != 200:
        fail("API request failed with status:", req.status_code)

    data = req.json()
    if not data["element_count"]:
        return None

    neos = data["near_earth_objects"][query_now]

    return neos

def get_nearest_neo(neos, nearest_distance, unit):
    for neo in neos:
        if float(neo["close_approach_data"][0]["miss_distance"][unit]) == nearest_distance:
            return neo
    return None

def get_shortest_distance(neos, unit):
    distances = []
    for neo in neos:
        distances.append(float(neo["close_approach_data"][0]["miss_distance"][unit]))

    return min(*distances)

def generate_static_string_frames(string, duration):
    frames = []
    for _ in range(duration):
        frames.append(render_character(string, color = TERMINAL_TEXT_COLOR))

    return frames

def generate_string_segments(string):
    segments = []
    for i, _ in enumerate(string.elems()):
        segments.append(render_character(string[:i + 1], color = TERMINAL_TEXT_COLOR))

    return segments

def render_character(string, color):
    return render.WrappedText(string, color = color)

def render_static_dino():
    return render.Row(
        cross_align = "end",
        main_align = "space_between",
        expanded = bool(1),
        children = [
            render.Box(
                height = 32,
                width = 34,
                child = render.WrappedText("This is fine.", font = "tom-thumb"),
            ),
            render.Box(
                height = 26,
                width = 28,
                child = render.Image(DINO),
            ),
        ],
    )
