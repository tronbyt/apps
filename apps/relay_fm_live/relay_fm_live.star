"""
Applet: Relay Live
Summary: Relay Live
Description: Shows live stream information for the Relay podcast network. Requires a Google Calendar API key.
Author: radiocolin
"""

load("http.star", "http")
load("images/relay_logo.png", RELAY_LOGO_ASSET = "file")
load("qrcode.star", "qrcode")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

RELAY_LOGO = RELAY_LOGO_ASSET.readall()

live_status_url = "https://www.relay.fm/live.json"
live_page_url = "https://www.relay.fm/live"
live_broadcasts_url = "https://www.relay.fm/addtobroadcasts"
live_discord_url = "https://discord.com/channels/620638957960691723/707667851745427666"
live_m3u_url = "http://stream.relay.fm:8000/stream.m3u"

def generate_qrcode(url):
    code = qrcode.generate(
        url = url,
        size = "large",
        color = "#fff",
        background = "#000",
    )
    return render.Image(src = code)

def check_live():
    r = http.get(live_status_url, ttl_seconds = 60)
    if r.json().get("live") == True:
        return True
    return False

def get_next_recording(live, timezone):
    if live:
        r = http.get(live_status_url, ttl_seconds = 60)
        header = render.Text("Live:")
        title = render.Text(r.json()["broadcast"]["title"])
        start_text = render.Text("Relay", font = "tom-thumb")
    else:
        header = render.Text("Up next:")
        calendar_minimum_time = time.now().in_location("UTC").format("2006-01-02T15:04:05.000Z")
        calendar_url = "https://www.googleapis.com/calendar/v3/calendars/relay.fm_t9pnsv6j91a3ra7o8l13cb9q3o%40group.calendar.google.com/events?key=AIzaSyAVhU0GdCZQidylxz7whIln82rWtZ4cIDQ&orderBy=startTime&singleEvents=true&timeMin=" + calendar_minimum_time
        r = http.get(calendar_url, ttl_seconds = 60)
        if "items" in r.json():
            next = r.json()["items"][0]
            title = render.Text(next["summary"])
            start = time.parse_time(next.get("start").get("dateTime"), "2006-01-02T15:04:05-07:00", next.get("start").get("timeZone"))
            start_text = render.Text(start.in_location(timezone).format("Jan 2 3:04pm"), font = "tom-thumb")
        else:
            header = render.Text("")
            title = render.Text("Check back soon for live streams")
            start_text = render.Text("Relay", font = "tom-thumb")

    return render.Box(
        child = render.Padding(
            child = render.Column(
                children = [
                    header,
                    render.Marquee(
                        width = 35,
                        child = title,
                        offset_start = 35,
                        offset_end = 35,
                    ),
                    render.Marquee(
                        width = 35,
                        child = start_text,
                        offset_start = 35,
                        offset_end = 35,
                    ),
                ],
            ),
            pad = (1, 0, 0, 0),
        ),
        height = 29,
        color = "#333F48",
    )

def main(config):
    timezone = config.get("timezone") or "America/New_York"
    img = render.Image(src = RELAY_LOGO)
    live = check_live()
    if not live and config.bool("live_only"):
        return []
    art = config.get("show_art") or live_page_url
    if live and art == "show_art":
        r = http.get(live_status_url, ttl_seconds = 60)
        img_url = r.json()["broadcast"]["show_art"]
        img_data = http.get(img_url, ttl_seconds = 60).body()
        img = render.Image(src = img_data, width = 29, height = 29)
    elif live and art == "RELAY_LOGO":
        img = render.Image(src = RELAY_LOGO)
    elif live:
        img = generate_qrcode(art)
    show = get_next_recording(live, timezone)
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
                render.Box(height = 2, color = "#34657F"),
                main_content,
                render.Box(height = 1, color = "#34657F"),
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
