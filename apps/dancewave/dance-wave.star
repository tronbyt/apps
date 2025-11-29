"""
Dance Wave - A Tidbyt app showing the currently playing song from Dance Wave Online Radio
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/dw_logo.gif", DW_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DW_LOGO = DW_LOGO_ASSET.readall()

# Dance Wave Logo

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
