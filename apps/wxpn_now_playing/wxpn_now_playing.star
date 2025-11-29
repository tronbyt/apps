"""
Applet: WXPN Now Playing
Summary: Show now playing on WXPN with album art
Description: Now playing with album art from WXPN, XPN2, and XPN Kids Corner.
Author: radiocolin
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/wxpn_logo_base64.png", WXPN_LOGO_BASE64_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

WXPN_LOGO_BASE64 = WXPN_LOGO_BASE64_ASSET.readall()

# Station URLs
XPN_URL = "https://jetapi.streamguys.com/ca5a773facc7e544fe426038da93667b3898b0a6/scraper/d8539cb7-52fb-4687-8f52-46c14fbf3c8e/metadata"
XPN2_URL = "https://jetapi.streamguys.com/ca5a773facc7e544fe426038da93667b3898b0a6/scraper/1c642a35-8a73-4e00-812e-736ffcdf73cd/metadata"
KIDS_CORNER_URL = "https://jetapi.streamguys.com/ca5a773facc7e544fe426038da93667b3898b0a6/scraper/ac86d03e-3ce7-4078-918e-7855675b3299/metadata"

# iTunes search URL template
ITUNES_URL_TEMPLATE = "https://itunes.apple.com/search?term={}+{}&media=music&limit=1"

# WXPN logo base64 (placeholder - you'll need to provide the actual base64 string)

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
        logo_data = WXPN_LOGO_BASE64
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
