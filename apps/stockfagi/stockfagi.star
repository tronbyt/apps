"""
Applet: StockFagi
Summary: Stock Fear And Greed Index
Description: Shows the Fear And Greed Index from from https://www.cnn.com/markets/fear-and-greed.
Author: jondkelley, with base code borrowed from btcfagi & PMK (@pmk)
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/background.gif", BACKGROUND_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BACKGROUND = BACKGROUND_ASSET.readall()

CACHE_SECONDS = 1800

def get_text_color(index_value):
    text_color = "#fff"
    if index_value < 25:
        text_color = "#bb2313"
    if index_value >= 25 and index_value < 50:
        text_color = "#c0b713"
    if index_value >= 50 and index_value < 75:
        text_color = "#9ab91f"
    if index_value >= 75:
        text_color = "#519736"
    return text_color

def main(config):
    rapidapi_key = config.get("rapidapi_key")
    if not rapidapi_key:
        return render.Root(
            child = render.Marquee(
                child = render.Text("This app requires the RapidAPI Key to run."),
                width = 64,
            ),
        )

    # cache stock moods to reduce API call count
    data = cache.get("stockfagi")
    if data:
        data = json.decode(data)
    else:
        # If not, pull the fagi from the remote source
        response = http.get(
            "https://fear-and-greed-index.p.rapidapi.com/v1/fgi",
            headers = {
                "X-RapidAPI-Key": rapidapi_key,
                "X-RapidAPI-Host": "fear-and-greed-index.p.rapidapi.com",
            },
        )

        # If something went wrong, show an error
        if response.status_code != 200:
            return render.Root(
                child = render.WrappedText(
                    content = "stockfagi: %d. this app is dead jim!" % (response.status_code),
                    align = "left",
                ),
            )

        # Otherwise, cache the result
        data = json.decode(response.body())
        cache.set("stockfagi", json.encode(data), ttl_seconds = CACHE_SECONDS)

    value = int(data["fgi"]["now"]["value"])
    classification = data["fgi"]["now"]["valueText"]
    has_extreme_in_classification = "Extreme" in classification
    text_color = get_text_color(value)

    return render.Root(
        delay = 15,
        max_age = 60 * 60 * 6,
        child = render.Stack(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Text(
                                content = "Stocks F&G",
                                font = "5x8",
                            ),
                        ),
                    ],
                ),
                render.Padding(
                    pad = (2, 12, 2, 2),
                    child = render.Image(
                        src = BACKGROUND,
                        width = 60,
                        height = 5,
                    ),
                ),
                render.Padding(
                    pad = (2, 11, 2, 2),
                    child = animation.Transformation(
                        child = render.Box(
                            width = 1,
                            height = 7,
                            color = "#fff",
                        ),
                        duration = 1500,
                        delay = 0,
                        origin = animation.Origin(0, 0),
                        keyframes = [
                            animation.Keyframe(
                                percentage = 0.0,
                                transforms = [animation.Translate(int(value * 0.6), 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.001,
                                transforms = [animation.Translate(0, 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 0.1,
                                transforms = [animation.Translate(int(value * 0.6), 0)],
                                curve = "ease_in_out",
                            ),
                            animation.Keyframe(
                                percentage = 1.0,
                                transforms = [animation.Translate(int(value * 0.6), 0)],
                                curve = "ease_in_out",
                            ),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, (22 if has_extreme_in_classification else 18), 0, 0),
                            child = render.Text(
                                content = classification,
                                color = text_color,
                                font = "tom-thumb" if has_extreme_in_classification else "6x13",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "rapidapi_key",
                name = "RapidAPI Key",
                desc = "Your RapidAPI key for the Fear and Greed Index API.",
                icon = "key",
                secret = True,
            ),
        ],
    )
