"""
Applet: Sveriges Radio
Summary: What's currently playing
Description: See what's currently playing on any of the Sveriges Radio channels.
Author: Sebastian Ekström
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/p1_icon.png", P1_ICON_ASSET = "file")
load("images/p2_icon.png", P2_ICON_ASSET = "file")
load("images/p3_icon.png", P3_ICON_ASSET = "file")
load("images/p4_icon.png", P4_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

P1_ICON = P1_ICON_ASSET.readall()
P2_ICON = P2_ICON_ASSET.readall()
P3_ICON = P3_ICON_ASSET.readall()
P4_ICON = P4_ICON_ASSET.readall()

SCHEDULE_URL = "https://api.sr.se/api/v2/scheduledepisodes?format=json&pagination=false&channelid="
NOW_PLAYING_URL = "https://api.sr.se/api/v2/playlists/rightnow?format=json&channelid="
ICON_SIZE = 18
PADDING = 2
TIDBYT_PX_WIDTH = 64
TEXT_WIDTH = TIDBYT_PX_WIDTH - ICON_SIZE - (PADDING * 2)

def get_current_unix_time():
    return time.now().unix * 1000

def get_current_show_name(url):
    response = fetch_data(url)
    schedule_data = response["schedule"]
    current_time = get_current_unix_time()

    for episode in schedule_data:
        start_time = int(episode["starttimeutc"].replace("/Date(", "").replace(")/", ""))
        end_time = int(episode["endtimeutc"].replace("/Date(", "").replace(")/", ""))
        if start_time <= current_time and current_time <= end_time:
            return episode

    return None

def get_station_icon(station):
    if station == "132":
        return P1_ICON
    elif station == "163":
        return P2_ICON
    elif station == "164":
        return P3_ICON
    else:
        return P4_ICON

def fetch_data(url):
    cached_data = cache.get("sr-url=%s" % url)
    if cached_data != None:
        print("Hit! Using cached 'Sveriges Radio' data for", url)
        data = json.decode(cached_data)
    else:
        print("Miss! Fetching 'Sveriges Radio' data for", url)
        assets_resp = http.get(url)
        if (assets_resp.status_code != 200):
            fail("'Sveriges Radio' request failed with status", assets_resp.status_code)

        data = assets_resp.json()
        cache.set("sr-url=%s" % url, json.encode(data), ttl_seconds = 10)

    return data

def get_currently_playing(now_playing_data, station_selection):
    currently_playing = now_playing_data["playlist"]
    current_song = currently_playing.get("song")
    song_is_playing = current_song != None

    if song_is_playing:
        title = current_song["artist"]
        subtitle = current_song["title"]
    else:
        # If a song isn't playing, display the name of the show instead
        station_schedule_url = SCHEDULE_URL + station_selection
        current_episode = get_current_show_name(station_schedule_url)
        if current_episode == None:
            title = "Could not find"
            subtitle = "show information"
        title = current_episode.get("title") or "Now playing"
        subtitle = current_episode.get("subtitle") or current_episode.get("description")

    return title, subtitle

def main(config):
    station_selection = config.get("station", "132")
    station_now_playing = NOW_PLAYING_URL + station_selection
    station_image = get_station_icon(station_selection)

    response = fetch_data(station_now_playing)
    title, subtitle = get_currently_playing(response, station_selection)

    return render.Root(
        child = render.Box(
            padding = PADDING,
            child = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Box(
                                width = ICON_SIZE,
                                height = ICON_SIZE,
                                child = render.Image(
                                    src = station_image,
                                    width = ICON_SIZE,
                                    height = ICON_SIZE,
                                ),
                            ),
                            render.Box(
                                child = render.Column(
                                    children = [
                                        render.Marquee(
                                            child = render.Text(
                                                content = " %s" % title,
                                                font = "5x8",
                                            ),
                                            width = TEXT_WIDTH,
                                        ),
                                        render.Marquee(
                                            child = render.Text(
                                                content = " %s" % subtitle,
                                                font = "5x8",
                                            ),
                                            width = TEXT_WIDTH,
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Choose the station",
                desc = "Choose the station",
                icon = "radio",
                default = StationOptions[0].value,
                options = StationOptions,
            ),
        ],
    )

StationOptions = [
    schema.Option(
        display = "P1",
        value = "132",
    ),
    schema.Option(
        display = "P2",
        value = "163",
    ),
    schema.Option(
        display = "P3",
        value = "164",
    ),
    schema.Option(
        display = "P4",
        value = "701",
    ),
]
