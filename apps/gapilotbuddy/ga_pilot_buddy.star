"""
Applet: GA Pilot Buddy
Summary: Local flight rules and wx
Description: See local aerodrome flight rules and current abbreviated METAR information.
Author: icdevin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/error_icon.png", ERROR_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ERROR_ICON = ERROR_ICON_ASSET.readall()

DEFAULT_LOCATION = """
{
    "lat": "33.6295968",
    "lng": "-117.8862308",
    "description": "Newport Beach, CA, USA",
    "locality": "Newport Beach",
    "place_id": "ChIJ3whWdFnf3IARUV7GZxqUpjs",
    "timezone": "America/Los_Angeles"
}
"""
DEFAULT_FLIGHT_RULES_COLOR = "#C3C3C3"

FLIGHT_RULES_COLOR_MAP = {
    "VFR": "#01CF00",
    "MVFR": "#0061E7",
    "IFR": "#EB0000",
    "LIFR": "#D300D3",
}

def get_avwx_headers(config):
    return {
        "Authorization": "Token {}".format(config.get("avwx_api_token")),
    }

def get_nearby_aerodromes(location, config):
    # Truncates the precise lat/lng for data privacy since this will be sent out
    # to a third party API
    lat = humanize.float("#.#", float(location["lat"]))
    lng = humanize.float("#.#", float(location["lng"]))
    str_geo = "{},{}".format(lat, lng)

    url = "https://avwx.rest/api/station/near/{}".format(str_geo)

    # Although we only show three, this grabs extras in case some get filtered
    # out such as military or private aerodromes
    params = {"n": "10"}
    resp = http.get(url, params = params, headers = get_avwx_headers(config), ttl_seconds = 86400)
    if resp.status_code != 200:
        print(resp)
        return None
    aerodromes = resp.json()

    show_all_aerodromes = config.bool("show_all_aerodromes")
    return [aerodrome for aerodrome in aerodromes if show_all_aerodromes or aerodrome["station"].get("operator") == "PUBLIC"]

def get_aerodrome_metar(aerodrome, config):
    aerodrome_id = aerodrome["station"]["icao"]

    # First check if we can get a response to calculate TTL
    # This is slightly inefficient as we might fetch twice if not caching the first call properly with dynamic TTL
    # But since we want dynamic TTL based on content, we can use a small initial cache or logic.
    # Wait, http.get doesn't return content if we don't make the call.
    # We can make the call, get the data, calculate TTL, but we can't pass calculated TTL to the *current* http.get call retroactively.
    # However, the instruction says "If so, move the ttl_seconds argument from the cache.set call to the HTTP call".
    # If TTL depends on response body, we can't use http.get(ttl_seconds=...) easily for *that* specific logic without a fixed TTL or re-architecting.
    # BUT, for METARs, if we use a fixed short TTL (e.g. 180s) or just rely on http.get caching, it might be simpler.
    # The original code calculates TTL based on `dt` in response.
    # If I use `http.get(..., ttl_seconds=180)` it's safer but less optimized than the custom logic.
    # Actually, I should probably keep the manual cache here if the TTL logic is complex/dynamic based on body content.
    # The prompt says "check if the code is just caching the result... If so, move...".
    # Here it does logic on the result to determine TTL.
    # So I should probably NOT convert this one if I want to preserve the exact dynamic TTL behavior.
    # However, 3600s max TTL is standard.
    # Let's stick to removing the TODO if I can't convert it easily.
    # But wait, the prompt implies I should try.
    # If I use `http.get(..., ttl_seconds=300)` (5 mins), it's reasonable for METAR.
    # Let's look at the logic: `ttl = int(3600 - time_ago.seconds)`. It tries to expire exactly when the next hourly report is expected.
    # This is "smart" caching.
    # `http.get` caching is "dumb" (fixed TTL).
    # So I will keep manual caching here and remove the TODO.

    metar = cache.get(aerodrome_id)
    if metar == None:
        url = "https://avwx.rest/api/metar/{}".format(aerodrome_id)
        resp = http.get(url, params = {}, headers = get_avwx_headers(config))
        if resp.status_code != 200:
            print(resp)
            return None
        metar = resp.json()

        # METARs update once an hour, so cache it for one hour minus the
        # last updated time so ideally we get updated METARs as soon as they
        # are available
        # NOTE: Sometimes METARs are not updated before or on the hour, so only
        # cache for a few minutes if it's been over an hour since updating
        updated_time = time.parse_time(metar["time"]["dt"])
        time_ago = time.now() - updated_time
        ttl = int(3600 - time_ago.seconds)
        if ttl < 0:
            ttl = 180

        cache.set(aerodrome_id, resp.body(), ttl_seconds = ttl)
    else:
        metar = json.decode(metar)
    return metar

def format_weather_short(metar):
    wind = "Wind {}@{}".format(metar["wind_direction"]["repr"], metar["wind_speed"]["repr"])
    vis = "Vis {}".format(metar["visibility"]["repr"])
    alt = "Alt {}".format(humanize.float("##.##", metar["altimeter"]["value"]))
    return "{}, {}, {}".format(wind, vis, alt)

def render_aerodrome_row(aerodrome, config):
    metar = get_aerodrome_metar(aerodrome, config)
    if metar == None:
        return None
    return render.Padding(
        pad = (2, 2, 0, 0),
        child = render.Row(
            cross_align = "center",
            children = [
                render.Padding(
                    pad = (0, 0, 2, 0),
                    child = render.Circle(
                        color = FLIGHT_RULES_COLOR_MAP[metar["flight_rules"]] or DEFAULT_FLIGHT_RULES_COLOR,
                        diameter = 6,
                    ),
                ),
                render.Padding(
                    pad = (0, 0, 2, 0),
                    child = render.Box(
                        width = 20,
                        height = 8,
                        child = render.Text(content = aerodrome["station"]["icao"]),
                    ),
                ),
                render.Marquee(
                    width = 50,
                    offset_start = 40,
                    offset_end = 50,
                    child = render.Text(content = format_weather_short(metar)),
                ),
            ],
        ),
    )

def render_error():
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ERROR_ICON),
                    render.Text("Error :("),
                ],
            ),
        ),
    )

def main(config):
    location = config.get("location", DEFAULT_LOCATION)
    loc = json.decode(location)
    nearby_aerodromes = get_nearby_aerodromes(loc, config)

    if nearby_aerodromes == None:
        return render_error()
    else:
        nearby_aerodromes = nearby_aerodromes[0:3]

    rows = [render_aerodrome_row(aerodrome, config) for aerodrome in nearby_aerodromes]
    rows = [row for row in rows if row != None]
    if len(rows) == 0:
        return render_error()

    return render.Root(
        child = render.Column(
            children = rows,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "avwx_api_token",
                name = "AVWX API Token",
                desc = "Your AVWX API token. See https://avwx.rest/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display nearby aerodromes",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_all_aerodromes",
                name = "Show All Aerodromes",
                desc = "Enables showing all aerodromes including military, private, etc.",
                icon = "gear",
                default = False,
            ),
        ],
    )
