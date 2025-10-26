"""
Applet: WXPN Now Playing
Summary: Show now playing on WXPN with album art
Description: Now playing with album art from WXPN, XPN2, and XPN Kids Corner.
Author: radiocolin
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Station URLs
XPN_URL = "https://jetapi.streamguys.com/ca5a773facc7e544fe426038da93667b3898b0a6/scraper/d8539cb7-52fb-4687-8f52-46c14fbf3c8e/metadata"
XPN2_URL = "https://jetapi.streamguys.com/ca5a773facc7e544fe426038da93667b3898b0a6/scraper/1c642a35-8a73-4e00-812e-736ffcdf73cd/metadata"
KIDS_CORNER_URL = "https://jetapi.streamguys.com/ca5a773facc7e544fe426038da93667b3898b0a6/scraper/ac86d03e-3ce7-4078-918e-7855675b3299/metadata"

# iTunes search URL template
ITUNES_URL_TEMPLATE = "https://itunes.apple.com/search?term={}+{}&media=music&limit=1"

# WXPN logo base64 (placeholder - you'll need to provide the actual base64 string)
WXPN_LOGO_BASE64 = "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"

# Station configurations
STATIONS = {
    "xpn": {
        "name": "WXPN",
        "url": XPN_URL,
        "color": "#FF6600",  # XPN Orange
    },
    "xpn2": {
        "name": "XPN2",
        "url": XPN2_URL,
        "color": "#FF6600",
    },
    "kids": {
        "name": "Kids' Corner",
        "url": KIDS_CORNER_URL,
        "color": "#FF6600",
    },
}

def main(config):
    station_key = config.str("station", "xpn")
    station = STATIONS.get(station_key, STATIONS["xpn"])

    # Get now playing data
    now_playing = get_now_playing(station["url"])
    if not now_playing:
        return render.Root(
            child = render.Text("Unable to load WXPN data"),
        )

    # Parse track info
    track_info = parse_track_info(now_playing["StreamTitle"])
    artist = track_info["artist"]
    title = track_info["title"]

    # Get album art
    album_art = get_album_art(artist, title)

    # Create the display
    return render.Root(
        show_full_animation = True,
        child = create_display(station, artist, title, album_art, station_key),
    )

def get_now_playing(url):
    """Fetch now playing data from WXPN API"""
    resp = http.get(url)
    if resp.status_code != 200:
        return None
    return json.decode(resp.body())

def parse_track_info(stream_title):
    """Parse artist and title from stream title"""
    if not stream_title or " - " not in stream_title:
        return {"artist": "Unknown", "title": stream_title or "Unknown"}

    parts = stream_title.split(" - ", 1)
    return {
        "artist": parts[0].strip(),
        "title": parts[1].strip(),
    }

def get_album_art(artist, title):
    """Get album art from iTunes API"""

    # Clean up artist and title for search
    clean_artist = artist.replace(" ", "+")
    clean_title = title.replace(" ", "+")

    search_url = ITUNES_URL_TEMPLATE.format(clean_artist, clean_title)
    resp = http.get(search_url)

    if resp.status_code != 200:
        return None

    data = json.decode(resp.body())
    if data["resultCount"] > 0 and "artworkUrl30" in data["results"][0]:
        # Fetch the actual image data
        image_url = data["results"][0]["artworkUrl30"]
        image_resp = http.get(image_url)
        if image_resp.status_code == 200:
            return image_resp.body()

    return None

def create_display(station, artist, title, album_art_url, station_key):
    """Create the main display layout"""

    # Top orange bar
    top_bar = render.Box(
        width = 64,
        height = 1,
        color = "#C17430",
    )

    # Bottom orange bar
    bottom_bar = render.Box(
        width = 64,
        height = 1,
        color = "#C17430",
    )

    # Album art (30x30, left aligned)
    album_art = None
    if album_art_url:
        # Use the fetched image data directly
        album_art = render.Image(
            src = album_art_url,
            width = 30,
            height = 30,
        )

    # Fallback to WXPN logo if no album art
    if not album_art:
        logo_data = base64.decode(WXPN_LOGO_BASE64)
        album_art = render.Image(
            src = logo_data,
            width = 30,
            height = 30,
        )

    # Station indicator at top
    station_display_name = station["name"]
    if station_key == "kids":
        station_display_name = "XPN Kids"

    station_text = render.Text(
        station_display_name,
        font = "tom-thumb",
        color = "#FFFFFF",
    )

    # Spacer to give station name breathing room
    spacer = render.Box(
        width = 1,
        height = 2,
    )

    # Text content (right side) with single marquee
    title_text = render.Text(
        title,
        font = "6x10",
        color = "#FFFFFF",
    )

    artist_text = render.Text(
        artist,
        font = "5x8",
        color = "#808080",
    )

    # Combine title and artist in a column
    track_info = render.Column(
        children = [title_text, artist_text],
        main_align = "start",
        cross_align = "start",
    )

    # Single marquee for both title and artist
    track_marquee = render.Marquee(
        width = 34,
        child = track_info,
        scroll_direction = "horizontal",
        align = "start",
    )

    # Combine station, spacer, and marquee vertically
    text_content = render.Column(
        children = [station_text, spacer, track_marquee],
        main_align = "start",
        cross_align = "start",
    )

    # Main content row (album art + text)
    content_row = render.Row(
        children = [album_art, text_content],
        main_align = "start",
        cross_align = "start",
    )

    # Content area between bars (30 pixels high)
    content_area = render.Box(
        width = 64,
        height = 30,
        child = content_row,
    )

    # Combine all elements
    return render.Column(
        children = [top_bar, content_area, bottom_bar],
        main_align = "start",
        cross_align = "start",
    )

def get_schema():
    station_options = [
        schema.Option(
            display = "WXPN",
            value = "xpn",
        ),
        schema.Option(
            display = "XPN2",
            value = "xpn2",
        ),
        schema.Option(
            display = "Kids' Corner",
            value = "kids",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Choose which WXPN station to display",
                icon = "radio",
                default = station_options[0].value,
                options = station_options,
            ),
        ],
    )
