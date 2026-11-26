"""
Applet: Strava
Summary: Displays athlete stats
Description: Displays your YTD or all-time athlete stats recorded on Strava.
Author: Rob Kimball
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/achievement_icon.png", ACHIEVEMENT_ICON_ASSET = "file")
load("images/clock_icon.png", CLOCK_ICON_ASSET = "file")
load("images/distance_icon.gif", DISTANCE_ICON_ASSET = "file")
load("images/distance_icon_fixed.png", DISTANCE_ICON_FIXED_ASSET = "file")
load("images/elev_icon.png", ELEV_ICON_ASSET = "file")
load("images/heart_icon.png", HEART_ICON_ASSET = "file")
load("images/kcal_icon.png", KCAL_ICON_ASSET = "file")
load("images/kudos_icon.png", KUDOS_ICON_ASSET = "file")
load("images/pr_icon.png", PR_ICON_ASSET = "file")
load("images/ride_icon.png", RIDE_ICON_ASSET = "file")
load("images/run_icon.png", RUN_ICON_ASSET = "file")
load("images/suffer_icon.png", SUFFER_ICON_ASSET = "file")
load("images/swim_icon.png", SWIM_ICON_ASSET = "file")
load("images/watts_icon.png", WATTS_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ACHIEVEMENT_ICON = ACHIEVEMENT_ICON_ASSET.readall()
CLOCK_ICON = CLOCK_ICON_ASSET.readall()
DISTANCE_ICON = DISTANCE_ICON_ASSET.readall()
DISTANCE_ICON_FIXED = DISTANCE_ICON_FIXED_ASSET.readall()
ELEV_ICON = ELEV_ICON_ASSET.readall()
HEART_ICON = HEART_ICON_ASSET.readall()
KCAL_ICON = KCAL_ICON_ASSET.readall()
KUDOS_ICON = KUDOS_ICON_ASSET.readall()
PR_ICON = PR_ICON_ASSET.readall()
RIDE_ICON = RIDE_ICON_ASSET.readall()
RUN_ICON = RUN_ICON_ASSET.readall()
SUFFER_ICON = SUFFER_ICON_ASSET.readall()
SWIM_ICON = SWIM_ICON_ASSET.readall()
WATTS_ICON = WATTS_ICON_ASSET.readall()

STRAVA_BASE = "https://www.strava.com/api/v3"
CLIENT_ID = "79662"
DEFAULT_UNITS = "imperial"
DEFAULT_SPORT = "ride"
DEFAULT_SCREEN = "all"

# Strava Info
STRAVA_CLIENT_ID = "strava_client_id"
STRAVA_CLIENT_SECRET = "strava_client_secret"
STRAVA_REFRESH_TOKEN = "strava_refresh_token"
STRAVA_ACCESS_TOKEN = "strava_access_token"
STRAVA_EXPIRES_AT = "strava_expires_at"

RATE_LIMIT_DEFAULT_BACKOFF_SECONDS = 15 * 60
RATE_LIMIT_CACHE_KEY = "rate-limit-backoff"

CACHE_VERSION = "v2"  # bump if Strava semantics ever change

STAT_KEYS = ["count", "distance", "moving_time", "elapsed_time", "elevation_gain"]

PREVIEW_DATA = {
    "count": 1408,
    "distance": 56159815,
    "moving_time": 2318919,
    "elapsed_time": 2615958,
    "elevation_gain": 125800,
}

CACHE_TTL = 60 * 60 * 18  # updates once every 36 hours

def main(config):
    client_id = config.get(STRAVA_CLIENT_ID)
    client_secret = config.get(STRAVA_CLIENT_SECRET)
    refresh_token = config.get(STRAVA_REFRESH_TOKEN)
    access_token = cache.get(STRAVA_ACCESS_TOKEN)
    expires_at = cache.get(STRAVA_EXPIRES_AT)

    sport = config.get("sport", DEFAULT_SPORT)
    units = config.get("units", DEFAULT_UNITS)
    display_type = config.get("display_type", DEFAULT_SCREEN)

    now = time.now().unix
    if not access_token or not expires_at or now >= int(float(expires_at)):
        if not client_id or not client_secret or not refresh_token:
            return display_failure("Strava tokens not configured.")

        print("Access token missing or expired, refreshing...")
        tokens = refresh_strava_token(client_id, client_secret, refresh_token)
        access_token = tokens.get("access_token")
        refresh_token = tokens.get("refresh_token")
        expires_at = tokens.get("expires_at")

        cache.set(STRAVA_ACCESS_TOKEN, access_token, ttl_seconds = CACHE_TTL)
        cache.set(STRAVA_REFRESH_TOKEN, refresh_token, ttl_seconds = CACHE_TTL)
        cache.set(STRAVA_EXPIRES_AT, str(expires_at), ttl_seconds = CACHE_TTL)

    if display_type in ("ytd", "all"):
        return athlete_stats(config, refresh_token, display_type, sport, units)
    elif display_type == "progress_chart":
        return progress_chart(config, refresh_token, sport, units)
    elif display_type == "last_activity":
        return last_activity(config, refresh_token, sport, units)
    else:
        print("Display type %s was invalid, showing the %s screen instead." % (display_type, DEFAULT_SCREEN))
        return athlete_stats(config, refresh_token, DEFAULT_SCREEN, sport, units)

def refresh_strava_token(client_id, client_secret, refresh_token):
    """
    Refresh Strava access token using refresh_token + client_id + client_secret
    Returns dict with access_token, refresh_token, expires_at
    """
    payload = {
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
    }

    rep = http.post(
        "https://www.strava.com/api/v3/oauth/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = payload,  # Pass dict directly
    )

    if rep.status_code != 200:
        fail("Token refresh failed: %d - %s" % (rep.status_code, rep.body()))

    tokens = rep.json()

    return tokens

def progress_chart(config, refresh_token, sport, units):
    show_logo = config.bool("show_logo", True)
    no_anim = config.bool("no_anim", False) or config.bool("$widget")

    distance_conv = meters_to_mi
    if units == "metric":
        distance_conv = meters_to_km

    activities = get_activities(config, refresh_token)

    # This is duped from the get_activities function but we still need this info for this display
    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    beg_curr_month = time.time(year = now.year, month = now.month, day = 1)
    _next_month = time.time(year = now.year, month = now.month, day = 32)
    end_curr_month = time.time(year = _next_month.year, month = _next_month.month, day = 1) - time.parse_duration("1ns")
    end_prev_month = beg_curr_month - time.parse_duration("1ns")
    beg_prev_month = time.time(year = end_prev_month.year, month = end_prev_month.month, day = 1)

    stat_keys = ("distance", "moving_time", "total_elevation_gain")
    graph_stat = stat_keys[0]

    # Iterate through each activity from the current and previous month and extract the relevant data, adding it
    # to our cumulative totals as we go, which are later used in our plot.
    included_current_activities = []
    cumulative_current = {k: 0 for k in stat_keys}
    for item in activities["current"]:
        if item["type"].lower() == sport:
            activity_time = time.parse_time(item["start_date"])
            activity_epoch = activity_time.unix
            activity_stats = {k: item.get(k, 0) for k in stat_keys}
            activity_stats["time"] = activity_time
            activity_stats["date_pct"] = (activity_epoch - beg_curr_month.unix) / (end_curr_month.unix - beg_curr_month.unix)
            cumulative_current = {k: cumulative_current.get(k, 0) + activity_stats.get(k, 0) for k in stat_keys}
            activity_stats.update({
                "cum_%s" % k: round(cumulative_current.get(k, 0), 2)
                for k in stat_keys
            })
            included_current_activities.append(activity_stats)
        else:
            print("Found non-%s activity (%s), skipping" % (sport, item["type"]))

    included_previous_activities = []
    cumulative_previous = {k: 0 for k in stat_keys}
    for item in activities["previous"]:
        if item["type"].lower() == sport:
            activity_time = time.parse_time(item["start_date"])
            activity_epoch = activity_time.unix
            activity_stats = {k: item.get(k, 0) for k in stat_keys}
            activity_stats["time"] = activity_time
            activity_stats["date_pct"] = (activity_epoch - beg_prev_month.unix) / (end_prev_month.unix - beg_prev_month.unix)
            cumulative_previous = {k: cumulative_previous.get(k, 0) + activity_stats.get(k, 0) for k in stat_keys}
            activity_stats.update({
                "cum_%s" % k: round(cumulative_previous.get(k, 0), 2)
                for k in stat_keys
            })
            included_previous_activities.append(activity_stats)
        else:
            print("Found non-%s activity (%s), skipping" % (sport, item["type"]))

    # Start both plots off at the origin and then add converted distance at each time stamp.
    # We use the percentage of the month here to align the axis of months that consist of a different number of days
    # Immediately before each activity we add the previous distance to create the "step" effect in the graph
    curr_plot = [(0.0, 0.0)]
    for item in included_current_activities:
        curr_plot.append((item["date_pct"] - 0.025, curr_plot[-1][1]))
        curr_plot.append((item["date_pct"], distance_conv(item["cum_%s" % graph_stat])))

    prev_plot = [(0.0, 0.0)]
    for item in included_previous_activities:
        prev_plot.append((item["date_pct"] - 0.025, prev_plot[-1][1]))
        prev_plot.append((item["date_pct"], distance_conv(item["cum_%s" % graph_stat])))

    # At the end of the current plot we want today's date as a percentage of the month,
    now_date_pct = (now.unix - beg_curr_month.unix) / (end_curr_month.unix - beg_curr_month.unix)
    curr_plot.append((now_date_pct, curr_plot[-1][1]))

    # ...and at the end of the previous plot we want 100% of the month to be our final cumulative number
    prev_plot.append((1.0, prev_plot[-1][1]))

    plot_height = max([prev_plot[-1][1], curr_plot[-1][1]])

    title_font = "CG-pixel-3x5-mono"

    total_time = time.parse_duration("%ss" % cumulative_current.get("moving_time", 0))
    if len(included_current_activities):
        total_time = format_duration(total_time, resolution = "hours")
    else:
        total_time = "0:00"

    logo = []
    if show_logo:
        sport_icon = {
            "run": RUN_ICON,
            "ride": RIDE_ICON,
            "swim": SWIM_ICON,
        }[sport]
        logo.append(
            render.Column(
                expanded = True,
                main_align = "end",
                cross_align = "end",
                children = [render.Image(src = sport_icon)],
            ),
        )
        graph_width = 54
    else:
        graph_width = 64

    if sport == "ride":
        value = cumulative_current["total_elevation_gain"]
        if units == "imperial":
            value = meters_to_ft(value)

        if value == 0 and len(curr_plot) > 0:
            # We can assume the athlete is using a trainer here and would rather not see elevation
            third_stat = {
                "title": sport + "s",
                "value": len(included_current_activities),
            }
        else:
            third_stat = {
                "title": "Elev",
                "value": int(value),
            }
    else:
        third_stat = {
            "title": sport + "s",
            "value": len(included_current_activities),
        }

    frames = []
    num_frames = len(prev_plot) + len(curr_plot)
    for i in range(num_frames + 1):
        frames.append(
            render.Stack(
                children = [
                    # Using a column here so I can place the logo in the bottom corner
                    render.Row(
                        expanded = True,
                        main_align = "start",
                        cross_align = "start",
                        children = logo,
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "end",
                        cross_align = "end",
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "end",
                                children = [
                                    render.Plot(
                                        data = prev_plot[0:i],
                                        width = graph_width,
                                        height = 22,
                                        color = "#787878",
                                        y_lim = (0.0, plot_height),
                                        x_lim = (0.0, 1.0),
                                        fill = False,
                                    ),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "end",
                        cross_align = "end",
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "end",
                                children = [
                                    render.Plot(
                                        data = curr_plot[0:i - len(prev_plot)],
                                        width = graph_width,
                                        height = 22,
                                        color = "#fc4c02",
                                        y_lim = (0.0, plot_height),
                                        x_lim = (0.0, 1.0),
                                        fill = False,
                                    ),
                                ] if i > len(prev_plot) else [],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text("Time", color = "#fc4c02", font = title_font),
                                    render.Text(total_time, color = "#FFF"),
                                ],
                            ),
                            render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text("Dist", color = "#fc4c02", font = title_font),
                                    render.Text(
                                        humanize.comma(math.round(distance_conv(cumulative_current["distance"]))),
                                        color = "#FFF",
                                    ),
                                ],
                            ),
                            render.Column(
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.Text(third_stat["title"], color = "#fc4c02", font = title_font),
                                    render.Text(
                                        humanize.comma(third_stat["value"]),
                                        color = "#FFF",
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

    if no_anim:
        frames = [frames[-1]]
    else:
        # Repeat last frame for a long time
        frames.extend([frames[-1]] * 400)

    return render.Root(
        delay = 50,
        child = render.Animation(
            children = frames,
        ),
    )

def athlete_stats(config, refresh_token, period, sport, units):
    no_anim = config.bool("no_anim", False) or config.bool("$widget")
    timezone = config.get("timezone") or "America/New_York"
    year = time.now().in_location(timezone).year

    if not refresh_token:
        stats = {k: PREVIEW_DATA[k] for k in STAT_KEYS}
    else:
        cached_token = cache.get(refresh_token)
        access_token = json.decode(cached_token) if cached_token else None

        if not access_token:
            access_token = get_access_token(
                refresh_token,
                config.get(STRAVA_CLIENT_ID),
                config.get(STRAVA_CLIENT_SECRET),
            )

        headers = {
            "Authorization": "Bearer %s" % access_token,
        }

        cached_athlete = cache.get("%s/athlete_id" % refresh_token)
        athlete = int(float(json.decode(cached_athlete))) if cached_athlete else None

        if not athlete:
            url = "%s/athlete" % STRAVA_BASE
            response = http_get(url, headers = headers)
            if response.status_code != 200:
                return display_failure("Strava API failed")

            athlete = int(float(response.json()["id"]))
            cache.set(
                "%s/athlete_id" % refresh_token,
                json.encode(str(athlete)),
                ttl_seconds = CACHE_TTL,
            )

        stats = fetch_athlete_stats(
            refresh_token,
            headers,
            athlete,
            sport,
            period,
        )

        if not stats:
            return display_failure("Failed to load athlete stats")

    if not stats:
        return display_failure("Failed to load athlete stats")

    # Configure the display to the user's preferences
    elevu = "m"
    if units.lower() == "imperial":
        if sport == "swim":
            stats["distance"] = round(meters_to_ft(float(stats["distance"])), 0)
            distu = "ft"
        else:
            stats["distance"] = round(meters_to_mi(float(stats["distance"])), 1)
            distu = "mi"
            elevu = "ft"
        stats["elevation_gain"] = round(meters_to_ft(float(stats["elevation_gain"])), 0)
    else:  # metric
        if sport != "swim":
            stats["distance"] = round(meters_to_km(float(stats["distance"])), 1)  # keep 1 decimal for km
        else:
            stats["distance"] = round(float(stats["distance"]), 0)
        distu = "km" if sport != "swim" else "m"
        stats["elevation_gain"] = round(float(stats.get("elevation_gain", 0)), 0)  # round meters

    if sport == "all":
        if int(float(stats["count"])) != 1:
            actu = "activities"
        else:
            actu = "activity"
    else:
        actu = sport
        if int(float(stats["count"])) != 1:
            actu += "s"

    display_header = []

    sport_verb = {
        "run": "running",
        "ride": "cycling",
        "swim": "swim",
    }[sport]

    if period == "ytd":
        display_header.append(
            render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [render.Text(" %d %s" % (year, sport_verb.capitalize()), font = "tb-8")],
            ),
        )

    sport_icon = {
        "run": RUN_ICON,
        "ride": RIDE_ICON,
        "swim": SWIM_ICON,
    }[sport]

    # The number of activities and distance traveled is universal, but for cycling the elevation gain is a
    # more interesting statistic than speed so we"ll vary the third item:
    if sport == "ride" and float(stats.get("elevation_gain", 0)) > 0:
        third_stat = {
            "icon": ELEV_ICON,
            "text": "%s %s" % (humanize.comma(float(stats.get("elevation_gain", 0))), elevu),
        }
    else:
        if float(stats.get("distance", 0)) > 0:
            split = float(stats.get("moving_time", 0)) // float(stats.get("distance", 0))
            split = time.parse_duration(str(split) + "s")
            split = format_duration(split)
        else:
            split = "N/A"

        third_stat = {
            "icon": CLOCK_ICON,
            "text": "%s%s" % (split, "/" + distu),
        }

    return render.Root(
        delay = 0,
        child = render.Column(
            expanded = True,
            cross_align = "start",
            main_align = "space_evenly",
            children = [
                render.Row(
                    cross_align = "center",
                    children = display_header,
                ),
                render.Animation(
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = sport_icon),
                                render.Box(height = 8, width = max(64 - i, 1)),
                                render.Text("%s " % humanize.comma(float(stats.get("count", 0)))),
                                render.Text(actu, font = "tb-8"),
                            ],
                        )
                        for i in range(799 if no_anim else 0, 800)
                    ],
                ),
                render.Animation(
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = DISTANCE_ICON_FIXED if no_anim else DISTANCE_ICON),
                                render.Box(height = 8, width = max(74 - i, 1)),
                                render.Text("%s " % humanize.comma(float(stats.get("distance", 0)))),
                                render.Text(distu, font = "tb-8"),
                            ],
                        )
                        for i in range(799 if no_anim else 0, 800)
                    ],
                ),
                render.Animation(
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Image(src = third_stat["icon"]),
                                render.Box(height = 8, width = max(84 - i, 1)),
                                render.Text(third_stat["text"]),
                            ],
                        )
                        for i in range(799 if no_anim else 0, 800)
                    ],
                ),
            ],
        ),
    )

def last_activity(config, refresh_token, sport, units):
    show_logo = config.bool("show_logo", True)
    no_anim = config.bool("no_anim", True) or config.bool("$widget")
    title_font = "CG-pixel-3x5-mono"

    if units == "metric":
        distance_conv = meters_to_km
    else:
        distance_conv = meters_to_mi

    activities = get_activities(config, refresh_token)

    filtered = [a for a in activities["current"] if a["type"].lower() == sport.lower()]
    if not len(filtered):
        filtered = [a for a in activities["previous"] if a["type"].lower() == sport.lower()]
    if not len(filtered):
        # Skip display if the athlete has no activities in the past 2 months
        print("No recent %ss found" % sport)
        return []
    display_activity = filtered[-1]

    map_info = display_activity.get("map", {})
    polyline = map_info.get("summary_polyline", map_info.get("polyline", None))
    title = []
    if show_logo:
        sport_icon = {
            "run": RUN_ICON,
            "ride": RIDE_ICON,
            "swim": SWIM_ICON,
        }[sport]
        title.append(
            render.Image(src = sport_icon),
        )

    total_time = format_duration(
        time.parse_duration("%ss" % display_activity.get("moving_time", 0)),
        resolution = "hours",
    )

    if display_activity.get("heartrate_opt_out", False) or (
        not display_activity.get("has_heartrate") or display_activity.get("average_heartrate", 0) == 0
    ):
        if sport == "ride" and display_activity.get("average_watts", 0) > 0:
            work_stat = {
                "icon": WATTS_ICON,
                "value": display_activity.get("average_watts"),
            }
        elif display_activity.get("kilojoules", 0) > 0:
            work_stat = {
                "icon": KCAL_ICON,
                "value": kj_to_calories(display_activity.get("kilojoules", 0)),
            }
        else:
            work_stat = {
                "icon": SUFFER_ICON,
                "value": math.round(display_activity.get("suffer_score", 0)),
            }
    else:
        work_stat = {
            "icon": HEART_ICON,
            "value": int(display_activity.get("average_heartrate", 0)),
        }

    elev = display_activity.get("total_elevation_gain", 0)
    if sport == "ride":
        if units == "imperial":
            elev = meters_to_ft(elev)

    if float(display_activity.get("distance", 0)) > 0:
        distance = distance_conv(float(display_activity.get("distance", 1)))
        split = float(display_activity.get("moving_time", 0)) / distance
        split = time.parse_duration(str(split) + "s")
        split = format_duration(split)
    else:
        split = "N/A"

    pace_stat = render.Column(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text("Pace", color = "#fc4c02", font = title_font),
            render.Text(split, color = "#FFF"),
        ],
    )

    time_stat = render.Column(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text("Time", color = "#fc4c02", font = title_font),
            render.Text(total_time, color = "#FFF"),
        ],
    )

    top_row = [
        time_stat if sport == "ride" else pace_stat,
        render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing + row height to 10px
        render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("Dist", color = "#fc4c02", font = title_font),
                render.Text(
                    humanize.comma(math.round(distance_conv(display_activity.get("distance", 0)))),
                    color = "#FFF",
                ),
            ],
        ),
    ]

    render_layers = []

    # This gives better spacing if there is no map
    stat_spacing = "space_around"

    if polyline:
        coordinates = decode_polyline(polyline)

        # Slight rotation helps certain routes fit better on the screen
        degrees_rotation = 15
        theta = math.radians(degrees_rotation)
        coordinates = [
            (
                math.cos(theta) * y + math.sin(theta) * x,
                math.cos(theta) * x - math.sin(theta) * y,
            )
            for x, y in coordinates
        ]

        n_frames = min(len(coordinates), 100)  # no more than 10 seconds for full animation
        speed = max(len(coordinates) / n_frames, 1)
        speed = int(speed) + 1 if speed > len(coordinates) // n_frames else int(speed)

        if no_anim:
            plot = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Plot(
                            data = coordinates,
                            width = 32,
                            height = 32,
                            color = "#fc4c02",
                        ),
                    ],
                ),
            ]
        else:
            plot = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Plot(
                            data = coordinates,
                            width = 32,
                            height = 32,
                            color = "#6d6d7833",
                        ),
                    ],
                ),
                # Bright moving tip
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Animation(
                            children = list([
                                render.Plot(
                                    data = coordinates[int(i * speed):int(i * speed) + speed],
                                    width = 32,
                                    height = 32,
                                    color = "#ffa078",
                                    x_lim = (min([x for x, _ in coordinates]), max([x for x, _ in coordinates])),
                                    y_lim = (min([y for _, y in coordinates]), max([y for _, y in coordinates])),
                                )
                                for i in range(n_frames + 1)
                            ]),
                        ),
                    ],
                ),
                # Darker moving line
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Animation(
                            children = list([
                                render.Plot(
                                    data = coordinates[int(i * speed) - speed:int(i * speed) + 1],
                                    width = 32,
                                    height = 32,
                                    color = "#fc4c02",
                                    x_lim = (min([x for x, _ in coordinates]), max([x for x, _ in coordinates])),
                                    y_lim = (min([y for _, y in coordinates]), max([y for _, y in coordinates])),
                                )
                                for i in range(n_frames + 1)
                            ]),
                        ),
                    ],
                ),
                # Background line:
                render.Row(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Animation(
                            children = list([
                                render.Plot(
                                    data = coordinates[0:int(i * speed) + speed],
                                    width = 32,
                                    height = 32,
                                    color = "#fc4c0277",
                                    x_lim = (min([x for x, _ in coordinates]), max([x for x, _ in coordinates])),
                                    y_lim = (min([y for _, y in coordinates]), max([y for _, y in coordinates])),
                                )
                                for i in range(n_frames + 1)
                            ]),
                        ),
                    ],
                ),
            ]

        render_layers.append(
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Stack(
                        children = plot,
                    ),
                ],
            ),
        )

        stat_spacing = "space_between"
    else:
        top_row.extend(
            [
                render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing + row height to 10px
                pace_stat if sport == "ride" else time_stat,
            ],
        )

    render_layers.append(
        render.Column(
            expanded = True,
            main_align = "start",
            children = [
                # Top Row (Time/Distance)
                render.Row(
                    expanded = True,
                    main_align = stat_spacing,
                    cross_align = "center",
                    children = top_row,
                ),
                # Middle Row
                render.Row(
                    expanded = True,
                    main_align = stat_spacing,
                    cross_align = "center",
                    children = [
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            children = [
                                render.Image(PR_ICON),
                                render.Text(" " + humanize.comma(display_activity.get("pr_count", 0))),
                            ] if display_activity.get("pr_count", 0) > 0 else [
                                render.Box(width = 1, height = 10, color = "#0000"),
                            ],
                        ),
                        render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing & height to 10px
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            children = [
                                render.Text(" " + humanize.comma(display_activity.get("kudos_count"))),
                                render.Image(KUDOS_ICON),
                            ] if display_activity.get("kudos_count", 0) > 0 else [
                                render.Box(width = 1, height = 10, color = "#0000"),
                            ],
                        ),
                    ],
                ),
                # Bottom Row
                render.Row(
                    expanded = True,
                    main_align = stat_spacing,
                    cross_align = "center",
                    children = [
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            children = [
                                render.Image(ACHIEVEMENT_ICON),
                                render.Text(" " + humanize.comma(display_activity.get("achievement_count"))),
                            ] if display_activity.get("achievement_count", 0) > 0 else [
                                render.Image(ELEV_ICON),
                                render.Text(" " + humanize.comma(int(elev))),
                            ] if elev > 0 else [
                                render.Box(width = 1, height = 10, color = "#0000"),
                            ],
                        ),
                        render.Box(width = 1, height = 10, color = "#0000"),  # Force spacing & row height to 10px
                        render.Row(
                            cross_align = "center",
                            main_align = stat_spacing,
                            # This is either the avg HR or calories burned
                            children = [
                                render.Text(humanize.comma(int(work_stat["value"]))),
                                render.Image(work_stat["icon"]),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

    return render.Root(
        delay = 0,
        child = render.Stack(
            children = render_layers,
        ),
    )

def get_activities(config, refresh_token):
    max_activities = 200

    timezone = config.get("timezone") or "America/New_York"
    now = time.now().in_location(timezone)
    beg_curr_month = time.time(year = now.year, month = now.month, day = 1)

    end_prev_month = beg_curr_month - time.parse_duration("1ns")
    beg_prev_month = time.time(year = end_prev_month.year, month = end_prev_month.month, day = 1)

    if not refresh_token:
        activities = {
            "current": [],
            "previous": [],
        }
    else:
        access_token = cache.get(refresh_token)
        access_token = json.decode(access_token) if access_token else None

        if not access_token:
            print("Generating new access token")
            access_token = get_access_token(refresh_token, config.get(STRAVA_CLIENT_ID), config.get(STRAVA_CLIENT_SECRET))

        headers = {
            "Authorization": "Bearer %s" % access_token,
        }

        # To help reduce the number of API calls we need, I'm querying both months together (current/prev commented)
        # The consequence here is if the athlete completed more than 200 activities in the last 2 months we'll miss some
        urls = {
            "last-2": "%s/athlete/activities?after=%s&per_page=%s" % (STRAVA_BASE, beg_prev_month.unix, max_activities),
            # "current": "%s/athlete/activities?after=%s&per_page=%s" % (STRAVA_BASE, beg_curr_month.unix, max_activities),
            # "previous": "%s/athlete/activities?after=%s&before=%s&per_page=%s" % (STRAVA_BASE, beg_prev_month.unix, end_prev_month.unix, max_activities),
        }

        activities = {}

        for query, url in urls.items():
            print("Getting %s month activities. %s" % (query, url))
            response = http_get(url, headers = headers, ttl_seconds = CACHE_TTL)
            if response.status_code != 200:
                text = "code %d, %s" % (response.status_code, json.decode(response.body()).get("message", ""))
                return display_failure("Strava API failed, %s" % text)
            data = response.json()

            activities[query] = data

    # Sort each list chronologically
    for query in activities.keys():
        activities[query] = sorted(activities[query], key = lambda x: x["start_date"])

    # Per above, split list into current and previous month
    activities["current"] = [a for a in activities["last-2"] if time.parse_time(a["start_date"]) >= beg_curr_month]
    activities["previous"] = [a for a in activities["last-2"] if time.parse_time(a["start_date"]) < beg_curr_month]
    activities.pop("last-2", None)

    return activities

def decode_polyline(polyline_str):
    """
    Converts a compressed series of GPS coordinates (i.e. Polyline) back into coordinates that we can plot.

    Implementation borrowed from https://github.com/geodav-tech/decode-google-maps-polyline

    :param polyline_str: Compressed coordinates as a string
    :return: list of tuples: latitude, longitude
    """
    index, lat, lng = 0, 0, 0
    coordinates = []
    changes = {"latitude": 0, "longitude": 0}

    # Coordinates have variable length when encoded, so just keep
    # track of whether we've hit the end of the string. In each
    # pseudo-while loop iteration, a single coordinate is decoded.
    for _ in range(int(1e10)):
        if index >= len(polyline_str):
            break

        # Gather lat/lon changes, store them in a dictionary to apply them later
        for unit in ["latitude", "longitude"]:
            shift, result = 0, 0

            for _ in range(len(polyline_str)):
                if index >= len(polyline_str):
                    break
                byte = ord(polyline_str[index]) - 63
                index += 1
                result |= (byte & 0x1f) << shift
                shift += 5
                if not byte >= 0x20:
                    break

            if result & 1:
                changes[unit] = ~(result >> 1)
            else:
                changes[unit] = (result >> 1)

        lat += changes["latitude"]
        lng += changes["longitude"]

        coordinates.append((lat / 100000.0, lng / 100000.0))

    return coordinates

def kj_to_calories(kj):
    return float(kj) / 4.184

def meters_to_mi(m, precision = 2):
    return round(m * 0.00062137, precision)

def meters_to_ft(m, precision = 0):
    return round(m * 3.280839895, precision)

def meters_to_km(m, precision = 2):
    return round(m / 1000.0, precision)

def round(num, precision):
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def format_duration(d, resolution = "minutes"):
    if resolution == "minutes":
        m = int(d.minutes)
        s = str(int((d.minutes - m) * 60))
        m = str(m)
        if len(s) == 1:
            s = "0" + s
        return "%s:%s" % (m, s)

    elif resolution == "hours":
        h = int(d.hours)
        m = str(int((d.hours - h) * 60))
        m = str(m)
        if len(m) == 1:
            m = "0" + m
        return "%s:%s" % (h, m)

    else:
        # Should never get here.
        return ""

def display_failure(msg):
    return render.Root(
        child = render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    child = render.Text(msg),
                ),
            ],
        ),
    )

def is_rate_limited():
    return cache.get(RATE_LIMIT_CACHE_KEY)

def http_get(url, headers = None, ttl_seconds = 0):
    res = http.get(url, headers = headers, ttl_seconds = ttl_seconds)

    if res.status_code == 429:
        # rate-limit exceeded. as of this writing, Strava doesn't return a
        # Retry-After header. but if they start doing so, we'll respect it.
        # in the absence of that header, we backoff for some reasonable
        # default number of seconds.
        backoff = res.headers.get("Retry-After", RATE_LIMIT_DEFAULT_BACKOFF_SECONDS)

        cache.set(
            RATE_LIMIT_CACHE_KEY,
            "back off, buddy",
            ttl_seconds = int(backoff),
        )

    return res

def fetch_athlete_stats(refresh_token, headers, athlete, sport, period):
    cache_prefix = "{}/{}/{}/{}/".format(
        CACHE_VERSION,
        refresh_token,
        sport,
        period,
    )

    stats = {}
    missing = False

    for k in STAT_KEYS:
        v = cache.get(cache_prefix + k)
        if v == None:
            missing = True
            break
        stats[k] = json.decode(v)

    if not missing:
        return stats

    resp = http_get(
        "%s/athletes/%s/stats" % (STRAVA_BASE, athlete),
        headers = headers,
        ttl_seconds = CACHE_TTL,
    )

    if resp.status_code != 200:
        return None

    data = resp.json()
    totals_key = "%s_%s_totals" % (
        "ytd" if period == "ytd" else "all",
        sport,
    )

    for k in STAT_KEYS:
        value = data[totals_key][k]
        stats[k] = value
        cache.set(
            cache_prefix + k,
            json.encode(value),
            ttl_seconds = CACHE_TTL,
        )

    return stats

def get_access_token(refresh_token, client_id, client_secret):
    params = {
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
    }

    res = http.post(
        url = "https://www.strava.com/api/v3/oauth/token",
        headers = {"Accept": "application/json"},
        form_body = params,  # dict, not string
    )

    if res.status_code != 200:
        fail("Token refresh failed: %d - %s" % (res.status_code, res.body()))

    token_data = res.json()
    new_access_token = token_data["access_token"]

    cache.set(
        refresh_token,
        json.encode(new_access_token),
        ttl_seconds = int(token_data["expires_in"] - 30),
    )

    return new_access_token

def get_schema():
    units_options = [
        schema.Option(value = "imperial", display = "Imperial (US)"),
        schema.Option(value = "metric", display = "Metric"),
    ]

    screen_options = [
        schema.Option(value = "all", display = "All-time stats"),
        schema.Option(value = "ytd", display = "YTD stats"),
        schema.Option(value = "progress_chart", display = "Monthly progress"),
        schema.Option(value = "last_activity", display = "Last activity"),
    ]

    sport_options = [
        schema.Option(value = "ride", display = "Cycling"),
        schema.Option(value = "run", display = "Running"),
        schema.Option(value = "swim", display = "Swimming"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "strava_refresh_token",
                name = "Strava Refresh Token",
                desc = "Connect to your Strava account",
                icon = "user",
                secret = True,
                default = "",
            ),
            schema.Text(
                id = "strava_client_id",
                name = "Strava Client ID",
                desc = "Connect to your Strava account",
                icon = "user",
                secret = True,
                default = "",
            ),
            schema.Text(
                id = "strava_client_secret",
                name = "Strava Client Secret",
                desc = "Connect to your Strava account",
                icon = "user",
                secret = True,
                default = "",
            ),
            schema.Dropdown(
                id = "sport",
                name = "Activity type",
                desc = "Runs, rides or swims are all supported!",
                icon = "personRunning",
                options = sport_options,
                default = "ride",
            ),
            schema.Dropdown(
                id = "units",
                name = "Distance units",
                desc = "Imperial displays miles and feet, metric displays kilometers and meters.",
                icon = "penRuler",
                options = units_options,
                default = DEFAULT_UNITS,
            ),
            schema.Dropdown(
                id = "display_type",
                name = "Screen type",
                desc = "Show your cumulative stats or a progress chart.",
                icon = "userClock",
                options = screen_options,
                default = DEFAULT_SCREEN,
            ),
            schema.Toggle(
                id = "show_logo",
                name = "Icon",
                desc = "Whether to display the sport icon on progress charts.",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "no_anim",
                name = "No animations",
                desc = "Toggle on to remove all animations for this view.",
                icon = "gear",
                default = False,
            ),
        ],
    )
