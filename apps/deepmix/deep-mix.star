"""
Deep Mix - A Tidbyt app showing the currently playing song from Deep Mix Online Radio
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/dm_logo.gif", DM_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DM_LOGO = DM_LOGO_ASSET.readall()

# Deep Mix Logo

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
                            src = DM_LOGO,
                            # width = 128,
                            # height = 64,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = "Deep Mix Radio • Loading...",
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
    # artist = current_track.get("artist", "Unknown Artist")
    title = current_track.get("title", "Unknown Track")

    # Build the display children
    children = [
        render.Image(
            src = DM_LOGO,
            width = 32,
            height = 16,
        ),
    ]

    # Use centered text for short titles, marquee for long ones
    if len(title) < 14:
        children.append(
            render.Text(
                content = title,
                font = "tb-8",
                color = text_color,
            ),
        )
    else:
        children.append(
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = title,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            ),
        )

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
    Fetch current track from Deep Mix Radio by scraping HTML
    """
    url = "http://217.160.63.220:7620/played.html?sid=1"

    # Cache the response for 30 seconds
    cached = cache.get("current_track")
    if cached != None:
        return json.decode(cached)

    resp = http.get(url)

    if resp.status_code == 200:
        html = resp.body()

        # Find the row with "Current Song" marker
        current_song_marker = "<b>Current Song</b>"
        if current_song_marker in html:
            # Find the start of the row containing the current song
            marker_pos = html.find(current_song_marker)
            row_start = html.rfind("<tr>", 0, marker_pos)

            if row_start != -1:
                # Extract the row
                row_end = html.find("</tr>", row_start)
                row = html[row_start:row_end]

                # Extract the song title (second <td>)
                # Find all <td> tags in the row
                first_td_end = row.find("</td>")
                if first_td_end != -1:
                    # Find the second <td>
                    second_td_start = row.find("<td>", first_td_end)
                    second_td_end = row.find("</td>", second_td_start)

                    if second_td_start != -1 and second_td_end != -1:
                        # Extract the content between the tags
                        song_text = row[second_td_start + 4:second_td_end]

                        # Parse artist and title (format: "Artist - Title")
                        if " - " in song_text:
                            parts = song_text.split(" - ", 1)
                            artist = parts[0].strip()
                            title = parts[1].strip()
                        else:
                            # If no separator, use the whole text as title
                            artist = "Unknown Artist"
                            title = song_text.strip()

                        track_data = {
                            "artist": artist,
                            "title": title,
                        }
                        cache.set("current_track", json.encode(track_data), ttl_seconds = CACHE_TTL_SECONDS)
                        return track_data

        print("Could not parse current song from HTML")
        return None
    else:
        print("Failed to fetch from server:", resp.status_code)
        return None
