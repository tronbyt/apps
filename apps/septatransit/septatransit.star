"""
Applet: SEPTA Transit
Summary: SEPTA Transit Departures
Description: Displays departure times for SEPTA buses, trolleys, and MFL/BSL in and around Philadelphia.
Author: radiocolin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

API_V2 = "https://www3.septa.org/api/v2"
API_FLAT = "https://flat-api.septa.org"

API_ROUTES = API_V2 + "/routes/"
DEFAULT_ROUTE = "17"
DEFAULT_STOP = "10264"
DEFAULT_BANNER = ""

def call_routes_api():
    cached = cache.get("routes_v2")
    if cached != None:
        return sort_routes(json.decode(cached))

    r = http.get(API_ROUTES)
    routes = r.json() if r.status_code == 200 else []

    if len(routes) > 0:
        cache.set("routes_v2", json.encode(routes), ttl_seconds = 604800)
    return sort_routes(routes)

def sort_routes(routes):
    numerical_routes = []
    non_numerical_routes = []

    for route in routes:
        name = route["route_short_name"]
        if name.isdigit():
            numerical_routes.append(route)
        else:
            non_numerical_routes.append(route)

    numerical_routes = sorted(numerical_routes, key = lambda x: int(x["route_short_name"]))
    return numerical_routes + non_numerical_routes

def get_routes():
    routes = call_routes_api()
    list_of_routes = []

    for i in routes:
        # 0: Tram/Trolley, 1: Subway, 3: Bus (GTFS types)
        # 2 is Rail, which we often exclude or handle differently
        if i["route_type"] != 2:
            list_of_routes.append(
                schema.Option(
                    display = i["route_short_name"] + ": " + i["route_long_name"],
                    value = i["route_id"],
                ),
            )

    if not list_of_routes:
        return [schema.Option(display = "17: South Philly to Center City", value = "17")]

    return list_of_routes

def get_route_info(route_id):
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route_id:
            return i
    return None

def fetch_stops(route_id):
    cache_key = "stops_v2_" + route_id
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    url = "%s/stops/%s/stops.json" % (API_FLAT, route_id)
    r = http.get(url)
    stops = r.json() if r.status_code == 200 else []

    if len(stops) > 0:
        cache.set(cache_key, json.encode(stops), ttl_seconds = 604800)
    return stops

def sort_stops_geographically(stops):
    if len(stops) <= 1:
        return stops
    lats = [float(s["stop_lat"]) for s in stops]
    lngs = [float(s["stop_lon"]) for s in stops]
    if max(lngs) - min(lngs) > max(lats) - min(lats):
        return sorted(stops, key = lambda s: float(s["stop_lon"]))
    else:
        return sorted(stops, key = lambda s: float(s["stop_lat"]))

def stop_direction(dlat, dlng):
    if abs(dlng) >= abs(dlat):
        return "NB" if dlng > 0 else "SB"
    else:
        return "WB" if dlat > 0 else "EB"

def direction_labels(stops):
    name_groups = {}
    for s in stops:
        name = s["stop_name"]
        if name not in name_groups:
            name_groups[name] = []
        name_groups[name].append(s)
    labels = {}
    for name in name_groups:
        group = name_groups[name]
        if len(group) < 2:
            continue
        total_lat = 0.0
        total_lng = 0.0
        for s in group:
            total_lat += float(s["stop_lat"])
            total_lng += float(s["stop_lon"])
        center_lat = total_lat / len(group)
        center_lng = total_lng / len(group)
        for s in group:
            dlat = float(s["stop_lat"]) - center_lat
            dlng = float(s["stop_lon"]) - center_lng

            # Key by both ID and direction to be safe
            key = "%s_%s" % (int(s["stop_id"]), int(s["direction_id"]))
            labels[key] = stop_direction(dlat, dlng)
    return labels

def get_stops(route_id):
    stops = sort_stops_geographically(fetch_stops(route_id))
    labels = direction_labels(stops)
    seen = {}
    options = []
    for i in stops:
        stop_id_int = int(i["stop_id"])
        key = "%s_%s" % (stop_id_int, int(i["direction_id"]))
        label = labels.get(key, "")
        display_name = i["stop_name"].replace("&amp;", "&")
        if label:
            display_name += " (" + label + ")"
        display_name += " [" + str(stop_id_int) + "]"

        # Sometimes a stop is listed multiple times for different patterns
        if seen.get(key):
            continue
        seen[key] = True

        options.append(
            schema.Option(
                display = display_name,
                value = str(stop_id_int),
            ),
        )
    return options

def parse_time_to_seconds(t_str):
    parts = t_str.split(":")
    h = int(parts[0])
    m = int(parts[1])
    s = int(parts[2])
    return h * 3600 + m * 60 + s

def call_schedule_api(route, stopid):
    cache_key = "sched_v2_%s_%s" % (route, stopid)

    # Cache schedule for 1 hour to allow for service changes
    # Real-time trips will be fetched fresh every time
    cached_sched = cache.get(cache_key)
    if cached_sched != None:
        full_schedule = json.decode(cached_sched)
    else:
        sched_url = "%s/schedules/stops/%s/%s/schedule.json" % (API_FLAT, route, stopid)
        r_sched = http.get(sched_url)
        full_schedule = r_sched.json() if r_sched.status_code == 200 else []
        if len(full_schedule) > 0:
            cache.set(cache_key, json.encode(full_schedule), ttl_seconds = 3600)

    if not full_schedule:
        return []

    # Fetch live trips for real-time delays
    trips_url = "%s/trips/?route_id=%s" % (API_V2, route)
    r_trips = http.get(trips_url)
    live_trips = r_trips.json() if r_trips.status_code == 200 else []

    live_data = {}
    service_id_counts = {}
    for t in live_trips:
        # Match by trip_id
        live_data[t["trip_id"]] = t

    # Infer today's service_id from live trips
    for s in full_schedule:
        if s["trip_id"] in live_data:
            svc_id = s["service_id"]
            service_id_counts[svc_id] = service_id_counts.get(svc_id, 0) + 1

    today_service_id = None
    max_count = 0
    for svc_id, count in service_id_counts.items():
        if count > max_count:
            max_count = count
            today_service_id = svc_id

    # Fallback guess for service_id based on day of week
    if not today_service_id:
        # If we can't infer it from live data, we'll look for the most frequent
        # service_id in the schedule. This is safer than hardcoding 10/12/13.
        counts = {}
        for s in full_schedule:
            sid = s["service_id"]
            counts[sid] = counts.get(sid, 0) + 1

        best_sid = None
        max_sid_count = 0
        for sid, count in counts.items():
            if count > max_sid_count:
                max_sid_count = count
                best_sid = sid
        today_service_id = best_sid

    now = time.now().in_location("America/New_York")
    now_secs = parse_time_to_seconds(now.format("15:04:05"))

    # Deduplicate by trip_id (sometimes the API returns multiple releases of the same trip)
    unique_trips = {}
    for s in full_schedule:
        if s["service_id"] != today_service_id:
            continue

        tid = s["trip_id"]

        # If we have multiple releases, the one with the higher release_name is likely newer
        if tid not in unique_trips or s.get("release_name", "") > unique_trips[tid].get("release_name", ""):
            unique_trips[tid] = s

    results = []
    for trip_id, s in unique_trips.items():
        sched_secs = parse_time_to_seconds(s["arrival_time"])
        delay = 0
        is_live = False
        live = None

        if trip_id in live_data:
            live = live_data[trip_id]

            # Use live data only if it has GPS and sane delay
            # SEPTA sometimes sends "998" or other bogus delay for "NO GPS"
            if live.get("status") != "NO GPS" and live.get("delay") != None and abs(float(live["delay"])) < 120:
                # Skip if it already passed our stop according to sequence
                if live.get("next_stop_sequence") != None:
                    if int(live["next_stop_sequence"]) > int(s["stop_sequence"]):
                        continue
                delay = int(float(live["delay"]) * 60)
                is_live = True

        eta_secs = sched_secs + delay - now_secs

        # Filter out trips in the past (allow 2 min buffer for late arrivals)
        # However, for the canonical schedule, we MUST show future scheduled trips
        # regardless of live data filtering.
        if eta_secs < -120:
            continue

        stops_away = None
        if is_live and live.get("next_stop_sequence") != None:
            stops_away = int(s["stop_sequence"]) - int(live["next_stop_sequence"])

        results.append({
            "eta_secs": eta_secs,
            "scheduled": s["arrival_time"],
            "headsign": s["trip_headsign"],
            "is_live": is_live,
            "delay_mins": int(delay / 60),
            "stops_away": stops_away,
        })

    # Sort by ETA
    return sorted(results, key = lambda x: x["eta_secs"])[:10]

def get_schedule(route, stopid, show_relative_times):
    departures = call_schedule_api(route, stopid)

    # 1. Pre-process to find max width needed for the time column
    processed_deps = []
    max_chars = 0
    for dep in departures:
        if show_relative_times:
            mins = int(dep["eta_secs"] / 60)
            t_str = "Now" if mins <= 0 else str(mins) + "m"
        else:
            parts = dep["scheduled"].split(":")
            h = int(parts[0])
            m = parts[1]
            suffix = "a"
            if h >= 24:
                h -= 24
            if h >= 12:
                suffix = "p"
                if h > 12:
                    h -= 12
            if h == 0:
                h = 12
            t_str = str(h) + ":" + m + suffix

        if len(t_str) > max_chars:
            max_chars = len(t_str)
        processed_deps.append((dep, t_str))

    # tom-thumb font is roughly 4px wide per character (3px glyph + 1px spacing)
    time_col_width = max_chars * 4 + 1
    if time_col_width < 12:
        time_col_width = 12

    list_of_departures = []
    for i, (dep, t_str) in enumerate(processed_deps):
        background = "#222" if i % 2 == 1 else "#000"
        text = "#fff" if i % 2 == 1 else "#ffc72c"

        # Live indicator color coding: Red if > 5m late, Green otherwise
        if dep["is_live"]:
            time_color = "#f00" if dep["delay_mins"] > 5 else "#0f0"
        else:
            time_color = text

        headsign = dep["headsign"]
        if dep.get("stops_away") != None:
            if dep["stops_away"] <= 0:
                headsign += " - Approaching"
            elif dep["stops_away"] == 1:
                headsign += " - 1 stop away"
            else:
                headsign += " - %d stops away" % dep["stops_away"]

        item = render.Box(
            height = 6,
            width = 64,
            color = background,
            child = render.Row(
                children = [
                    render.Box(
                        width = time_col_width,
                        child = render.Padding(
                            pad = (0, 0, 1, 0),  # Small gap before marquee
                            child = render.Text(
                                content = t_str,
                                font = "tom-thumb",
                                color = time_color,
                            ),
                        ),
                    ),
                    render.Marquee(
                        child = render.Text(
                            headsign,
                            font = "tom-thumb",
                            color = text,
                        ),
                        width = 64 - time_col_width,
                        offset_start = 40,
                        offset_end = 40,
                    ),
                ],
            ),
        )
        list_of_departures.append(item)

    if len(list_of_departures) < 1:
        msg = "No departures" if stopid else "Select a stop"
        return [render.Box(
            height = 6,
            width = 64,
            color = "#000",
            child = render.Text(msg, font = "tom-thumb"),
        )]
    else:
        return list_of_departures

def select_stop(route):
    options = get_stops(route)
    if not options:
        return [schema.Text(id = "stop", name = "Stop", desc = "No stops found", default = "")]
    return [
        schema.Dropdown(
            id = "stop",
            name = "Stop",
            desc = "Select a stop.",
            icon = "bus",
            default = options[0].value,
            options = options,
        ),
    ]

def main(config):
    route = config.str("route", DEFAULT_ROUTE)
    stop = config.str("stop", DEFAULT_STOP)
    show_relative_times = config.bool("show_relative_times", False)
    user_text = config.str("banner", "")
    schedule = get_schedule(route, stop, show_relative_times)
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    left_pad = 4

    route_info = get_route_info(route)
    if route_info:
        route_bg_color = "#" + route_info["route_color"]
        route_text_color = "#" + route_info["route_text_color"]
    else:
        route_bg_color = "#000"
        route_text_color = "#fff"

    if config.bool("use_custom_banner_color"):
        route_bg_color = config.str("custom_banner_color")
    if config.bool("use_custom_text_color"):
        route_text_color = config.str("custom_text_color")

    if user_text == "":
        banner_text = route
    else:
        banner_text = user_text

    if config.bool("show_time"):
        if int(now.format("15")) < 12:
            meridian = "a"
        else:
            meridian = "p"
        banner_text = now.format("3:04") + meridian + " " + banner_text
        if now.format("3") in ["10", "11", "12"]:
            left_pad = 0

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Column(
                    children = [
                        render.Stack(children = [
                            render.Box(height = 6, width = 64, color = route_bg_color),
                            render.Padding(pad = (left_pad, 0, 0, 0), child = render.Text(banner_text, font = "tom-thumb", color = route_text_color)),
                        ]),
                    ],
                ),
                render.Padding(pad = (0, 0, 0, 2), color = route_bg_color, child = render.Column(children = schedule)),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "banner",
                name = "Custom banner text",
                desc = "Custom text for the top bar. Leave blank to show the selected route.",
                icon = "penNib",
                default = "",
            ),
            schema.Toggle(
                id = "use_custom_banner_color",
                name = "Use custom banner color",
                desc = "Use a custom background color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_banner_color",
                name = "Custom banner color",
                desc = "A custom background color for the top banner.",
                icon = "brush",
                default = "#7AB0FF",
            ),
            schema.Toggle(
                id = "use_custom_text_color",
                name = "Use custom text color",
                desc = "Use a custom text color for the top banner.",
                icon = "palette",
                default = False,
            ),
            schema.Color(
                id = "custom_text_color",
                name = "Custom text color",
                desc = "A custom text color for the top banner.",
                icon = "brush",
                default = "#FFFFFF",
            ),
            schema.Toggle(
                id = "show_time",
                name = "Show time",
                desc = "Show the current time in the top banner.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "show_relative_times",
                name = "Show relative departure times",
                desc = "Show relative departure times.",
                icon = "clock",
                default = False,
            ),
            schema.Dropdown(
                id = "route",
                name = "Route",
                desc = "Select a route",
                icon = "signsPost",
                default = DEFAULT_ROUTE,
                options = get_routes(),
            ),
            schema.Generated(
                id = "stop",
                source = "route",
                handler = select_stop,
            ),
        ],
    )
