"""
Applet: SailGP
Summary: Sail GP Race and Leaders
Description: Sail GP Next Race Info and Current Leaderboard.
Author: jvivona
"""

# ############################
# Mods - jvivona - 2023-07-13
# - added in standings display with country flags (** I learned a bunch about flag sizes in this exercise)
# - convert next race info color to generated schema field
# 20230911 - jvivona - update code and API to better handle end of season with not upcoming race
#                    - moved data to github repo
# 20231107 - jvivona - cleanup code in for loop
# 20250326 - jvivona - 12 teams now - updated
# 20260602 - jvivona - repoint to revived data feed (new wrapped schema):
#                    - standings.json now wrapped: decode(...)["standings"], field teamAbbreviation -> team_code
#                    - nri.json fields: startDateTime/endDateTime -> start/end, locationName -> location
#                    - parse timestamps with seconds+millis (...:05.000-07:00)
#                    - standings slides built dynamically (handles 13+ teams / odd counts)
#                    - flags fetched once instead of per slide

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

VERSION = 26153

# 2x (128x64): Next Race becomes a static schedule screen with the standings
# paging along the bottom. 1x (64x32) is unchanged.
IS2X = canvas.is2x()
ACCENT_COLOR = "#7fd4d9"
DRIVER_INITIAL = False  # False: "Slingsby" | True: "T. Slingsby"

DEFAULTS = {
    "display": "nri",
    "timezone": "America/New_York",
    "date_us": True,
    "api": "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/sailgp/{}.json",
    "ttl": 1800,
    "text_color": "#FFFFFF",
    "standings_text_color": "#FFFFFF",
    "regular_font": "tom-thumb",
    "data_box_width": 64,
    "data_box_height": 16,
    "data_box_bkg": "#000",
    "ease_in_out": "ease_in_out",
    "animation_frames": 30,
    "animation_hold_frames": 75,
    "title_bkg_color": "#0a2627",
    "slide_duration": 100,
    "nri_page_duration": 70,
}

def main(config):
    displaytype = config.get("datadisplay", DEFAULTS["display"])

    # we always need standings - so just go get it.
    # standings.json is the new wrapped schema: { ..., "standings": [ ... ] }
    standings = json.decode(get_cachable_data(DEFAULTS["api"].format("standings")))["standings"]

    displayrow = []

    # if we're showing NRI go and get that data
    if displaytype == "nri":
        data = json.decode(get_cachable_data(DEFAULTS["api"].format(displaytype)))
        if data.get("start", "") == "":
            return []
        elif IS2X:
            displayrow = nri_2x(data, standings, config)
        else:
            displayrow = nri(data, standings, config)
    elif IS2X:
        displayrow = current_standings_2x(standings, config)
    else:
        displayrow = current_standings(standings, config)

    return render.Root(
        show_full_animation = True,
        child = render.Column(
            main_align = "space_between" if IS2X else "start",
            cross_align = "center" if IS2X else "start",
            expanded = IS2X,
            children = [title_bar(displaytype)] + displayrow,
        ),
    )

def title_bar(displaytype):
    if not IS2X:
        return render.Box(width = 64, height = 6, child = render.Text("Sail GP", font = "tom-thumb"), color = DEFAULTS["title_bkg_color"])

    # 2x: brand on the left, current mode on the right.
    label = "Next Race" if displaytype == "nri" else "Season Standings"
    return render.Box(
        width = 128,
        height = 10,
        color = DEFAULTS["title_bkg_color"],
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Padding(pad = (2, 0, 0, 0), child = render.Text("SailGP", font = "tb-8")),
                render.Padding(pad = (0, 0, 3, 0), child = render.Text(label, font = "tom-thumb", color = ACCENT_COLOR)),
            ],
        ),
    )

def nri(nri, standings, config):
    text_color = config.get("text_color", DEFAULTS["text_color"])
    standings_text_color = config.get("standings_text_color", DEFAULTS["standings_text_color"])
    timezone = time.tz()  # Utilize special timezone variable to get TZ - otherwise assume US Eastern w/DST

    date_and_time_first = nri["start"]
    date_and_time_second = nri["end"]
    date_and_time_first_dt = time.parse_time(date_and_time_first, "2006-01-02T15:04:05.000-07:00").in_location(timezone)
    date_and_time_second_dt = time.parse_time(date_and_time_second, "2006-01-02T15:04:05.000-07:00").in_location(timezone)
    date_time_format = date_and_time_first_dt.format("Jan 2-") + date_and_time_second_dt.format("2 2006") if config.bool("is_us_date_format", DEFAULTS["date_us"]) else date_and_time_first_dt.format("2-") + date_and_time_second_dt.format("2 Jan 2006")

    standing_text = ""
    for i in standings:
        standing_text = standing_text + "{}. {} ({})  ".format(str(i["position"]), i["team_code"], str(i["points"]))

    return [
        render.Box(width = 64, height = 1),
        fade_child(nri["name"].replace("Sail Grand Prix", "GP"), nri["location"], text_color),
        render.WrappedText(content = date_time_format, font = DEFAULTS["regular_font"], color = text_color, align = "center", width = DEFAULTS["data_box_width"], height = 5),
        render.Box(width = 64, height = 1),
        render.Marquee(offset_start = 48, child = render.Text(height = 6, content = standing_text, font = DEFAULTS["regular_font"], color = standings_text_color), scroll_direction = "horizontal", width = 64),
    ]

def nri_2x(nri, standings, config):
    text_color = config.get("text_color", DEFAULTS["text_color"])
    standings_text_color = config.get("standings_text_color", DEFAULTS["standings_text_color"])
    timezone = time.tz()

    start_dt = time.parse_time(nri["start"], "2006-01-02T15:04:05.000-07:00").in_location(timezone)
    end_dt = time.parse_time(nri["end"], "2006-01-02T15:04:05.000-07:00").in_location(timezone)
    date_str = start_dt.format("Jan 2-") + end_dt.format("2 2006") if config.bool("is_us_date_format", DEFAULTS["date_us"]) else start_dt.format("2-") + end_dt.format("2 Jan 2006")
    race_name = nri["name"].replace("Sail Grand Prix", "GP")

    schedule = render.Column(
        cross_align = "center",
        children = [
            render.Text("Round {}".format(nri["round"]), font = "tom-thumb", color = ACCENT_COLOR),
            render.Text(nri["location"], font = "tb-8", color = text_color),
            render.WrappedText(content = race_name, font = "tom-thumb", color = ACCENT_COLOR, align = "center", width = 124, height = 6),
            render.Box(width = 128, height = 3),
            render.Text(date_str, font = "tom-thumb", color = text_color),
        ],
    )

    # title pins top, standings pins bottom, schedule floats centered between
    return [schedule, paged_standings_2x(standings, standings_text_color)]

def paged_standings_2x(standings, color):
    # Page through the standings two rows of three at a time, sliding each page
    # in from the right (calmer than a continuous marquee).
    per_row = 3
    per_page = per_row * 3
    pages = []
    for i in range(0, len(standings), per_page):
        group = standings[i:i + per_page]
        rows = []
        for r in range(0, len(group), per_row):
            cells = [
                render.Text("{} {} {}".format(str(t["position"]), t["team_code"], str(t["points"])), font = "tom-thumb", color = color)
                for t in group[r:r + per_row]
            ]
            rows.append(render.Box(width = 128, height = 6, child = render.Row(expanded = True, main_align = "space_evenly", children = cells)))
        page = render.Box(width = 128, height = 22, child = render.Column(main_align = "space_evenly", children = rows))
        pages.append(slide_page(page, DEFAULTS["nri_page_duration"], 128))
    return render.Sequence(children = pages)

def slide_page(child, duration, width):
    return animation.Transformation(
        child = child,
        duration = duration,
        delay = 0,
        origin = animation.Origin(0, 0),
        keyframes = [
            animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(width, 0)], curve = DEFAULTS["ease_in_out"]),
            animation.Keyframe(percentage = 0.12, transforms = [animation.Translate(0, 0)], curve = DEFAULTS["ease_in_out"]),
            animation.Keyframe(percentage = 0.88, transforms = [animation.Translate(0, 0)], curve = DEFAULTS["ease_in_out"]),
            animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(-width, 0)], curve = DEFAULTS["ease_in_out"]),
        ],
    )

def current_standings(standings, config):
    standings_text_color = config.get("standings_text_color", DEFAULTS["standings_text_color"])

    # Fetch the chosen images once (flags or logos, not once per slide), then page
    # through the standings two teams at a time. Built dynamically so any team
    # count works (13 in 2026; an odd count renders a final single-team slide).
    images = json.decode(get_cachable_data(DEFAULTS["api"].format(config.get("imagetype", "flags"))))

    slides = []
    for i in range(0, len(standings), 2):
        left = standings[i]
        right = standings[i + 1] if i + 1 < len(standings) else None
        slides.append(current_standings_slide(left, right, standings_text_color, images))
    return [render.Sequence(children = slides)]

def standings_team_column(standing, standings_text_color, images):
    return render.Column(
        cross_align = "center",
        children = [
            render.Box(width = 32, height = 14, child = render.Image(base64.decode(images[standing["team_code"]]), height = 14)),
            render.Text("{} {}".format(str(standing["position"]), standing["team_code"]), font = DEFAULTS["regular_font"], color = standings_text_color),
            render.Text("{} pts".format(str(standing["points"])), font = DEFAULTS["regular_font"], color = standings_text_color),
        ],
    )

def current_standings_slide(standingsLeft, standingsRight, standings_text_color, images):
    columns = [standings_team_column(standingsLeft, standings_text_color, images)]
    if standingsRight != None:
        columns.append(standings_team_column(standingsRight, standings_text_color, images))

    return animation.Transformation(
        child =
            render.Row(expanded = True, main_align = "space_evenly", children = columns),
        duration = DEFAULTS["slide_duration"],
        delay = 0,
        origin = animation.Origin(0, 0),
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(DEFAULTS["data_box_width"], 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
            animation.Keyframe(
                percentage = 0.1,
                transforms = [animation.Translate(-0, 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
            animation.Keyframe(
                percentage = 0.9,
                transforms = [animation.Translate(-0, 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(-DEFAULTS["data_box_width"], 0)],
                curve = DEFAULTS["ease_in_out"],
            ),
        ],
    )

def driver_name(name):
    # Last name only (e.g. "Tom Slingsby" -> "Slingsby"). Flip DRIVER_INITIAL to
    # show a leading first initial instead ("T. Slingsby").
    parts = name.split(" ")
    if len(parts) < 2:
        return name
    return "{}. {}".format(parts[0][0], parts[-1]) if DRIVER_INITIAL else parts[-1]

def current_standings_2x(standings, config):
    color = config.get("standings_text_color", DEFAULTS["standings_text_color"])
    images = json.decode(get_cachable_data(DEFAULTS["api"].format(config.get("imagetype", "flags"))))

    per_page = 4
    pages = []
    for i in range(0, len(standings), per_page):
        rows = [standings_row_2x(t, color, images) for t in standings[i:i + per_page]]
        page = render.Box(
            width = 128,
            height = 54,
            child = render.Column(main_align = "space_evenly", children = rows),
        )
        pages.append(slide_page(page, DEFAULTS["slide_duration"], 128))
    return [render.Sequence(children = pages)]

def standings_row_2x(standing, color, images):
    # Two text lines beside the flag/logo: team name on top, driver + points below.
    info = render.Column(
        cross_align = "start",
        children = [
            render.WrappedText(content = standing["team_name"], font = DEFAULTS["regular_font"], color = color, width = 90, height = 6),
            render.Box(
                width = 90,
                height = 6,
                child = render.Row(
                    expanded = True,
                    main_align = "space_between",
                    children = [
                        render.Text(driver_name(standing["driver"]), font = DEFAULTS["regular_font"], color = "#9fb9bb"),
                        render.Text(str(standing["points"]), font = DEFAULTS["regular_font"], color = color),
                    ],
                ),
            ),
        ],
    )
    return render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Box(width = 11, height = 13, child = render.Text(str(standing["position"]), font = DEFAULTS["regular_font"], color = color)),
            render.Box(width = 22, height = 13, child = render.Image(base64.decode(images[standing["team_code"]]), height = 12)),
            render.Box(width = 3, height = 1),
            info,
        ],
    )

def fade_child(race, location, text_color):
    return render.Animation(
        children =
            createfadelist(race, DEFAULTS["animation_hold_frames"], DEFAULTS["regular_font"], text_color) +
            createfadelist(location, DEFAULTS["animation_hold_frames"], DEFAULTS["regular_font"], text_color),
    )

def createfadelist(text, cycles, text_font, text_color):
    alpha_values = ["00", "33", "66", "99", "CC", "FF"]
    cycle_list = []

    # go from none to full color
    for x in alpha_values:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x))
    for x in range(cycles):
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color))

    # go from full color back to none
    for x in alpha_values[5:0]:
        cycle_list.append(fadelistchildcolumn(text, text_font, text_color + x))
    return cycle_list

def fadelistchildcolumn(text, font, color):
    return render.Column(main_align = "center", cross_align = "center", expanded = False, children = [render.WrappedText(content = text, font = font, color = color, align = "center", width = DEFAULTS["data_box_width"], height = 14)])

# ##############################################
#           Schema Funcitons
# ##############################################

dispopt = [
    schema.Option(
        display = "Next Race",
        value = "nri",
    ),
    schema.Option(
        display = "Standings Display",
        value = "standings",
    ),
]

# Values match the data feed filenames (flags.json / logos.json).
imgopt = [
    schema.Option(
        display = "Country Flag",
        value = "flags",
    ),
    schema.Option(
        display = "Team Logo",
        value = "logos",
    ),
]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "datadisplay",
                name = "Display Type",
                desc = "What data to display?",
                icon = "eye",
                default = "nri",
                options = dispopt,
            ),
            schema.Color(
                id = "standings_text_color",
                name = "Standings Color",
                desc = "The color for Standings.",
                icon = "palette",
                default = DEFAULTS["standings_text_color"],
            ),
            schema.Dropdown(
                id = "imagetype",
                name = "Team Image",
                desc = "Show country flags or team logos in the standings.",
                icon = "image",
                default = "flags",
                options = imgopt,
            ),
            schema.Generated(
                id = "nri_generated",
                source = "datadisplay",
                handler = show_nri_options,
            ),
        ],
    )

def show_nri_options(datadisplay):
    if datadisplay == "nri":
        return [
            schema.Color(
                id = "text_color",
                name = "Race Info Color",
                desc = "The color for Race Info and Date.",
                icon = "palette",
                default = DEFAULTS["text_color"],
            ),
            schema.Toggle(
                id = "is_us_date_format",
                name = "US Date format",
                desc = "Display the date in US format.",
                icon = "calendarDays",
                default = DEFAULTS["date_us"],
            ),
        ]
    else:
        return []

# ##############################################
#           General Funcitons
# ##############################################
def get_cachable_data(url):
    res = http.get(url = url, ttl_seconds = DEFAULTS["ttl"])
    if res.status_code != 200:
        fail("request to %s failed with status code: %d - %s" % (url, res.status_code, res.body()))

    return res.body()

def text_justify_trunc(length, text, direction):
    #  thanks to @inxi and @whyamihere / @rs7q5 for the codepoints() and codepoints_ords() help
    chars = list(text.codepoints())
    textlen = len(chars)

    # if string is shorter than desired - we can just use the count of chars (not bytes) and add on spaces - we're good
    if textlen < length:
        for _ in range(length - textlen):
            text = " " + text if direction == "right" else text + " "
    else:
        # text is longer - need to trunc it get the list of characters & trunc at length
        text = ""  # clear out text
        for i in range(length):
            text = text + chars[i]

    return text
