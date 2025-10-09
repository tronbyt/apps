"""
Dance Wave - A Tidbyt app showing the currently playing song from Dance Wave Online Radio
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Dance Wave Logo
DW_LOGO = base64.decode("""
R0lGODlhQABAAPcAAAAAAAz7rg/6shD5tRb2vhr2vweD/wiF/wyL/xGS/xSY/xme/x2j/yOs/yey/ym1/y27/zG//x70xyPxzyfv1Cnv1S3t2zHs3ybw0inw0zPD/zjH/zbJ/zrM/z3S/zTr4zjq5jvn7jzn7z3n7zzn7jfp6Djp6Dnp6Djp6Tvp6Tno6jjp6jnp6jno6zzp6zro7Dvo7Dro7T3o7Dzo7T3n8D3n8T7n8T/m8j/m80DR/0DT/0DU/0HU/0DV/0HV/0DW/0HW/0HX/0PW/0LX/0PX/0HY/0LY/0PY/0LZ/0PZ/0Pb/0XY/0TZ/0Xa/0Tb/0Xb/0fa/0Td/0Xd/0bc/0fc/0bd/0fd/0be/0bf/0ff/0je/0jf/0nf/0Dn8UHn8UHm8kDm80Hm80Xn80Dl9EHl9EDl9UHl9UPl9UPm9ULl9kLl90Pl90Xl90bl90Xj+0bj+0Pk+EPk+UTk+ETk+UXk+Ubk+UXk+kXk+0bk+0fk+0bj/Ebj/Ufj/Ufg/0fh/0nj/Ujg/0ng/0jh/0nh/0ji/kni/kji/0ni/0ri/wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAABAAEAAAAj/AAEIHEiwoMGDBw0YQMiwocOHDhEcOACxosWLAxFoxMixo8EEIBN4HNlRgUkFJFNWZLCg5QKVMBsymDkzpk2DDXLmvMkTgE6dPW86GEo0aMwHRIsaVfmgqdMHS5k+bRqVJISrWK9WHZk161aPXbF+HaghgtmzEQ5GwKoBa1q1aOO+Naihrl27Z+/q1UDX7N0IfOmWlUsY7d7DiAOTvQuAseDEkCNDLshY72PJmDMrFljZMUHNeytuGH13A8ENdk2jrmuacurWPTdwmA0bgOzZAm9zMKi7ds8Oozt0ICh8dO7Rvm0jryq8+cDmwwVCNzg9KvToAKpnd06ce1QP4D3k/xgY3gP58AXLby0/HoD68+DTo6865H34IQTfC6wff+uQ//8BAGCAA/GHX4HgHVgVEgwiwQQASABY0IAEUbhVgw5CyOCDBGE4EBMNjgUiE0xggUWIBTXIIQAgZviViSZqASMWBckI40AzjjUjITBqUWOPAtlI41iE8GFkkUYahCQfhAiEZJNEEiLllFASRCWUVI4FgJFcHqkkl1ByqSUAdJRpJh0H0eHGmmiqueaYdMAhp5xoGhSnmWTiqaUZfPbJxkF9mvGnn2MGyidChgY6JgA2NNooGAiB4agYktoA6ZiONspQppVaumgIoIZAAkMklGpqqYsC8MKqL8jAEKuwuoW6KAu0stBQrbi6kCoLJZRgK0K89irsr4uCYGxDxiabbKoVKfsBCM8yC9EH1Fb7gbTTWksttg9dYMG3317ArUPggjsuueVacG5DFlTgbgXqrovQu+7Ky1AFFORbgb0IYeAvBhnwe9AEBE8g8EESJCzBwQYR4HABDBc0gAADRFyQAAEIEFRAADs=
""")

# Cache TTL for API responses
CACHE_TTL_SECONDS = 30  # Cache for 30 seconds (more frequent updates for live radio)

def main(config):
    """
    Main function that renders the Tidbyt display
    """

    # Get user-configured colors
    text_color = config.get("text_color", "#0ff1b2")

    # Fetch current playing track
    current_track = fetch_current_track()

    if current_track == None:
        # Fallback display if API is unavailable
        return render.Root(
            show_full_animation = True,
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(
                            src = DW_LOGO,
                            width = 32,
                            height = 32,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = "Dance Wave Radio • Loading...",
                                font = "tb-8",
                                color = text_color,
                            ),
                            scroll_direction = "horizontal",
                        ),
                    ],
                ),
            ),
        )

    # Display current track info
    artist = current_track.get("artist", "Unknown Artist")
    title = current_track.get("title", "Unknown Track")

    # Build the display children
    children = [
        render.Image(
            src = DW_LOGO,
            width = 32,
            height = 16,
        ),
        render.Marquee(
            width = 64,
            delay = 1000,
            child = render.Text(
                content = artist + " • " + title,
                font = "tb-8",
                color = text_color,
            ),
            scroll_direction = "horizontal",
        ),
    ]

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def get_schema():
    """
    Configuration schema for the app
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color for track information text",
                icon = "palette",
                default = "#0ff1b2",
            ),
        ],
    )

def fetch_current_track():
    """
    Fetch current track from Dance Wave Radio API
    """
    url = "https://dancewave.online/api/playlist.cgi?user=dw8080&streamid=1&mount=/dw.ogg&num=1&out=json"
    headers = {
        "Referer": "https://dancewave.online/tracklist/",
    }

    # Cache the API response for 30 seconds
    cached = cache.get("current_track")
    if cached != None:
        return json.decode(cached)

    resp = http.get(url, headers = headers)

    if resp.status_code == 200:
        data = resp.json()

        # Extract the current track (first item in playlist)
        playlist = data.get("mscp", {}).get("playlist")
        if playlist:
            current = playlist[0]
            track_data = {
                "artist": current.get("artist", "Unknown Artist"),
                "title": current.get("title", "Unknown Title"),
            }
            cache.set("current_track", json.encode(track_data), ttl_seconds = CACHE_TTL_SECONDS)
            return track_data
        else:
            print("No playlist data found")
            return None
    else:
        print("Failed to fetch from API:", resp.status_code)
        return None
