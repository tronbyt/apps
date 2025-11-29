"""
Icecast Now Playing - A Tidbyt app showing the currently playing song from an Icecast server
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Cache TTL for API responses
CACHE_TTL_SECONDS = 30  # Cache for 30 seconds (more frequent updates for live radio)
ICECAST_LOGO = """
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
"""

def main(config):
    """
    Main function that renders the Tidbyt display
    """

    # Get user-configured values
    status_url = config.get("status_url", "")
    custom_name = config.get("custom_name", "")
    text_color = config.get("text_color", "#0ff1b2")

    # Validate that a URL is provided
    if not status_url:
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = "Please configure Icecast status URL",
                            font = "tb-8",
                            color = "#ff0000",
                            align = "center",
                        ),
                    ],
                ),
            ),
        )

    # Fetch current playing track
    current_data = fetch_current_track(status_url)

    if current_data == None:
        # Fallback display if API is unavailable
        station_name = custom_name if custom_name else "Icecast Radio"
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(
                            src = base64.decode(ICECAST_LOGO),
                            width = 32,
                            height = 16,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = station_name + " • Loading...",
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
    server_name = current_data.get("server_name", "Icecast Radio")
    title = current_data.get("title", "Unknown Track")

    # Use custom name if provided, otherwise use server_name
    display_name = custom_name if custom_name else server_name

    # Parse title for artist and song
    artist = ""
    song = ""
    if " - " in title:
        parts = title.split(" - ", 1)
        artist = parts[0].strip()
        song = parts[1].strip()
        print("Parsed artist:", artist)
        print("Parsed song:", song)

    # Build the display
    children = []

    # Top row: Logo on left, station name in remaining space
    station_text = None
    if len(display_name) > 8:
        station_text = render.Marquee(
            width = 46,
            child = render.Text(
                content = display_name,
                font = "tb-8",
                color = "#888888",
            ),
            scroll_direction = "horizontal",
        )
    else:
        station_text = render.Text(
            content = display_name,
            font = "tb-8",
            color = "#888888",
        )

    top_row = render.Row(
        main_align = "start",
        cross_align = "center",
        children = [
            render.Image(
                src = base64.decode(ICECAST_LOGO),
                width = 16,
                height = 12,
            ),
            render.Box(width = 2, height = 1),  # Small spacer
            station_text,
        ],
    )
    children.append(top_row)

    # Add separator
    children.append(
        render.Box(
            width = 64,
            height = 1,
            color = "#333333",
        ),
    )

    # Add track info - if we have artist and song, show on two lines
    if len(artist) > 0 and len(song) > 0:
        # Artist line
        artist_widget = None
        if len(artist) > 10:
            artist_widget = render.Marquee(
                width = 64,
                child = render.Text(
                    content = artist,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            )
        else:
            artist_widget = render.Text(
                content = artist,
                font = "tb-8",
                color = text_color,
            )
        children.append(artist_widget)

        # Song line
        song_widget = None
        if len(song) > 10:
            song_widget = render.Marquee(
                width = 64,
                child = render.Text(
                    content = song,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            )
        else:
            song_widget = render.Text(
                content = song,
                font = "tb-8",
                color = text_color,
            )
        children.append(song_widget)
    else:
        # No dash, show full title
        title_widget = None
        if len(title) > 10:
            title_widget = render.Marquee(
                width = 64,
                child = render.Text(
                    content = title,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            )
        else:
            title_widget = render.Text(
                content = title,
                font = "tb-8",
                color = text_color,
            )
        children.append(title_widget)

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
            schema.Text(
                id = "status_url",
                name = "Icecast Status URL",
                desc = "URL to your Icecast server's status-json.xsl endpoint (e.g., http://icecast.example.com:8000/status-json.xsl)",
                icon = "radio",
            ),
            schema.Text(
                id = "custom_name",
                name = "Custom Stream Name (Optional)",
                desc = "Custom name for your stream (leave blank to use server_name from Icecast)",
                icon = "tag",
                default = "",
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color for track information text",
                icon = "palette",
                default = "#0ff1b2",
            ),
        ],
    )

def fetch_current_track(url):
    """
    Fetch current track from Icecast server status-json.xsl endpoint
    """

    # Create a cache key based on the URL
    cache_key = "icecast_track_" + url

    # Cache the response for 30 seconds
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    resp = http.get(url)

    if resp.status_code == 200:
        data = resp.json()

        # The Icecast status-json.xsl returns data in this structure:
        # {
        #   "icestats": {
        #     "source": [ ... ] or { ... }  (can be array or single object)
        #   }
        # }

        if "icestats" in data:
            icestats = data["icestats"]
            source = None

            # Handle both array and single source cases
            if "source" in icestats:
                source_data = icestats["source"]

                # If it's a list, get the first source
                if type(source_data) == "list":
                    if len(source_data) > 0:
                        source = source_data[0]
                else:
                    # It's a single source object
                    source = source_data

            if source != None:
                # Extract title and server_name
                title = source.get("title", "Unknown Track")
                server_name = source.get("server_name", "Icecast Radio")

                track_data = {
                    "title": title,
                    "server_name": server_name,
                }
                cache.set(cache_key, json.encode(track_data), ttl_seconds = CACHE_TTL_SECONDS)
                return track_data

        print("Could not parse Icecast status JSON")
        return None
    else:
        print("Failed to fetch from Icecast server:", resp.status_code)
        return None
