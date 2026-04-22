"""
Applet: Relay Live
Summary: Relay Live
Description: Shows live stream information for the Relay podcast network. Requires a Google Calendar API key.
Author: radiocolin
"""

load("http.star", "http")
load("images/relay_logo.png", RELAY_LOGO_ASSET = "file")
load("images/relay_logo@2x.png", RELAY_LOGO_2X_ASSET = "file")
load("qrcode.star", "qrcode")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

RELAY_LOGO = RELAY_LOGO_ASSET.readall()
RELAY_LOGO_2X = RELAY_LOGO_2X_ASSET.readall()

live_status_url = "https://www.relay.fm/live.json"
live_page_url = "https://www.relay.fm/live"
live_broadcasts_url = "https://www.relay.fm/addtobroadcasts"
live_discord_url = "https://discord.com/channels/620638957960691723/707667851745427666"
live_m3u_url = "http://stream.relay.fm:8000/stream.m3u"

def generate_qrcode(url, scale):
    code = qrcode.generate(
        url = url,
        size = "large" if scale == 1 else "xlarge",
        color = "#fff",
        background = "#000",
    )
    return render.Image(src = code, width = 29 * scale, height = 29 * scale)

def check_live():
    r = http.get(live_status_url, ttl_seconds = 60)
    if r.status_code != 200:
        return False
    status = r.json()
    if status and status.get("live") == True:
        return True
    return False

def get_next_recording(live, timezone, scale, api_key):
    header_font = "tb-8" if scale == 1 else "terminus-14"
    title_font = "tb-8" if scale == 1 else "terminus-14"
    start_font = "tom-thumb" if scale == 1 else "terminus-12"

    if live:
        r = http.get(live_status_url, ttl_seconds = 60)
        header = render.Text("Live:", font = header_font)
        title = render.Text(r.json()["broadcast"]["title"], font = title_font)
        start_text = render.Text("Relay", font = start_font)
    elif api_key:
        header = render.Text("Up next:", font = header_font)

        # We use a 1h grace period in the past for current events
        calendar_minimum_time = (time.now() - time.parse_duration("1h")).in_location("UTC").format("2006-01-02T15:04:05.000Z")
        calendar_url = "https://www.googleapis.com/calendar/v3/calendars/relay.fm_t9pnsv6j91a3ra7o8l13cb9q3o%40group.calendar.google.com/events?key=" + api_key + "&orderBy=startTime&singleEvents=true&timeMin=" + calendar_minimum_time
        r = http.get(calendar_url, ttl_seconds = 60)
        if r.status_code == 200 and "items" in r.json() and len(r.json()["items"]) > 0:
            next = r.json()["items"][0]
            title = render.Text(next["summary"], font = title_font)

            # Handle dateTime or date for all-day events
            start_data = next.get("start", {})
            start_str = start_data.get("dateTime") or start_data.get("date")

            if not start_str:
                start_text = render.Text("Relay", font = start_font)
            else:
                # Robustly parse dateTime formats (with offset or Z)
                # Google Calendar dateTime is typically RFC3339
                # If it's just 'date', it's YYYY-MM-DD
                if len(start_str) == 10:  # YYYY-MM-DD
                    start = time.parse_time(start_str, "2006-01-02", timezone)
                elif "Z" in start_str:
                    start = time.parse_time(start_str, "2006-01-02T15:04:05Z")
                else:
                    # Try with offset, though Go's parse_time is very strict on format
                    # Most common from GCal is YYYY-MM-DDTHH:MM:SS-07:00
                    start = time.parse_time(start_str, "2006-01-02T15:04:05-07:00")

                start_text = render.Text(start.in_location(timezone).format("Jan 2 3:04pm"), font = start_font)
        else:
            header = render.Text("", font = header_font)
            title = render.Text("Check back soon for live streams", font = title_font)
            start_text = render.Text("Relay", font = start_font)
    else:
        header = render.Text("", font = header_font)
        title = render.Text("Check back soon for live streams", font = title_font)
        start_text = render.Text("Relay", font = start_font)

    return render.Box(
        child = render.Padding(
            child = render.Column(
                children = [
                    header,
                    render.Marquee(
                        width = 35 * scale,
                        child = title,
                        offset_start = 35 * scale,
                        offset_end = 35 * scale,
                    ),
                    render.Marquee(
                        width = 35 * scale,
                        child = start_text,
                        offset_start = 35 * scale,
                        offset_end = 35 * scale,
                    ),
                ],
            ),
            pad = (1 * scale, 0, 0, 0),
        ),
        height = 29 * scale,
        color = "#333F48",
    )

def main(config):
    scale = 2 if canvas.is2x() else 1
    timezone = config.get("timezone") or "America/New_York"
    api_key = config.get("api_key")
    if api_key:
        api_key = api_key.strip()

    logo = RELAY_LOGO if scale == 1 else RELAY_LOGO_2X
    img = render.Image(src = logo, width = 29 * scale, height = 29 * scale)
    live = check_live()
    if not live and config.bool("live_only"):
        return []
    art = config.get("show_art") or live_page_url
    if live and art == "show_art":
        r = http.get(live_status_url, ttl_seconds = 60)
        if r.status_code == 200:
            status = r.json()
            if status and "broadcast" in status and "show_art" in status["broadcast"]:
                img_url = status["broadcast"]["show_art"]
                img_res = http.get(img_url, ttl_seconds = 60)
                if img_res.status_code == 200:
                    img_data = img_res.body()
                    img = render.Image(src = img_data, width = 29 * scale, height = 29 * scale)
    elif live and art == "RELAY_LOGO":
        img = render.Image(src = logo, width = 29 * scale, height = 29 * scale)
    elif live:
        img = generate_qrcode(art, scale)
    show = get_next_recording(live, timezone, scale, api_key)
    main_content = render.Row(
        children = [
            img,
            show,
        ],
        expanded = True,
    )
    return render.Root(
        child = render.Column(
            children = [
                render.Box(height = 2 * scale, color = "#34657F"),
                main_content,
                render.Box(height = 1 * scale, color = "#34657F"),
            ],
        ),
    )

show_art_options = [
    schema.Option(
        display = "Display show art when live",
        value = "show_art",
    ),
    schema.Option(
        display = "Display QR when live: Relay website",
        value = live_page_url,
    ),
    schema.Option(
        display = "Display QR when live: Broadcasts app",
        value = live_broadcasts_url,
    ),
    schema.Option(
        display = "Display QR when live: m3u",
        value = live_m3u_url,
    ),
    schema.Option(
        display = "Always show Relay logo",
        value = "RELAY_LOGO",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "Google Calendar API Key",
                desc = "Required to show upcoming schedule.",
                icon = "key",
            ),
            schema.Dropdown(
                id = "show_art",
                name = "Artwork/QR code settings",
                desc = "Settings for how to display artwork.",
                icon = "qrcode",
                default = show_art_options[0].value,
                options = show_art_options,
            ),
            schema.Toggle(
                id = "live_only",
                name = "Only show app when live",
                desc = "Don't show this app when nothing is live.",
                icon = "towerBroadcast",
                default = False,
            ),
        ],
    )
