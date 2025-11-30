"""
Applet: Flight Radar Feed
Summary: View FR24 Radar Feed
Description: View the flights tracked by a radar on Flightradar24.
Author: kinson
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_fe26b9dc.png", IMG_fe26b9dc_ASSET = "file")

PLANE_ICON = IMG_fe26b9dc_ASSET.readall()]

    if show_radar:
        callsign_row.append(
            render.Padding(
                child = render.Text(
                    content = radar,
                    font = "CG-pixel-3x5-mono",
                    color = "#811",
                ),
                pad = (0, 0, 0, 0),
            ),
        )

    return render.Padding(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            children = [
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = callsign_row,
                ),
                render.Row(
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 0, 4, 0),
                            child = render.Image(src = PLANE_ICON),
                        ),
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(
                                content = origin + " -> " + destination,
                                color = "#1111ee",
                            ),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(content = model, font = "tom-thumb"),
                        ),
                        render.Padding(
                            pad = (0, 1, 0, 1),
                            child = render.Text(content = registration, font = "tom-thumb"),
                        ),
                    ],
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Row(
                            children = [
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = speed, font = "tom-thumb"),
                                ),
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = "kts", font = "tom-thumb"),
                                ),
                            ],
                        ),
                        render.Row(
                            children = [
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = alt, font = "tom-thumb"),
                                ),
                                render.Padding(
                                    pad = 0,
                                    child = render.Text(content = "ft", font = "tom-thumb"),
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        ),
        pad = (1, 1, 0, 1),
    )

def render_list_of_flights(flights, radar, show_radar):
    if len(flights) > 0:
        return [render_flight_info_screen(f, radar, show_radar) for f in flights]
    else:
        return []

def main(config):
    radars = config.str("radars")

    if not radars:
        return []

    radar_array = radars.split(",")
    rendered_flights = []

    for radar in radar_array:
        flight_data = get_data(API_URL, radar)
        rendered_screens = render_list_of_flights(
            flight_data,
            radar,
            len(radar_array) > 1,
        )
        rendered_flights.extend(rendered_screens)

    if len(rendered_flights) == 0:
        return []

    return render.Root(
        delay = 3500,
        show_full_animation = True,
        child = render.Animation(children = rendered_flights),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "radars",
                name = "Radar IDs (e.g. T-KSFO10)",
                desc = "Separate multiple with a comma",
                icon = "satelliteDish",
            ),
        ],
    )
