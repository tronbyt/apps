"""
Applet: TeslaFi
Summary: Shows charge/name/range
Description: Shows your Teslas current Name, Charge in Mi/KM and battery %. Also shows if its charging or not.
To grab the API key to go TeslaFi -> Settings -> Account -> Advanced -> TeslaFi API access
Author: mrrobot245
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/bolt_animated.gif", BOLT_ANIMATED = "file")
load("images/bolt_green.png", BOLT_GREEN = "file")
load("images/bolt_grey.png", BOLT_GREY = "file")
load("images/tesla.png", TESLA = "file")
load("math.star", "math")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

FRAME_WIDTH = 64

def lightness(color, amount):
    hsl_color = rgb_to_hsl(*hex_to_rgb(color))
    hsl_color_list = list(hsl_color)
    hsl_color_list[2] = hsl_color_list[2] * amount
    hsl_color = tuple(hsl_color_list)
    return rgb_to_hex(*hsl_to_rgb(*hsl_color))

def rgb_to_hsl(r, g, b):
    r = float(r / 255)
    g = float(g / 255)
    b = float(b / 255)
    high = max(r, g, b)
    low = min(r, g, b)
    h, s, l = ((high + low) / 2,) * 3

    if high == low:
        h = 0.0
        s = 0.0
    else:
        d = high - low
        s = d / (2 - high - low) if l > 0.5 else d / (high + low)
        if high == r:
            h = (g - b) / d + (6 if g < b else 0)
        elif high == g:
            h = (b - r) / d + 2
        elif high == b:
            h = (r - g) / d + 4
        h /= 6

    return int(math.round(h * 360)), s, l

def hue_to_rgb(p, q, t):
    if t < 0:
        t += 1
    if t > 1:
        t -= 1
    if t < 1 / 6:
        return p + (q - p) * 6 * t
    if t < 1 / 2:
        return q
    if t < 2 / 3:
        return p + (q - p) * (2 / 3 - t) * 6
    return p

def hsl_to_rgb(h, s, l):
    h = h / 360
    if s == 0:
        r, g, b = (l,) * 3  # achromatic
    else:
        q = l * (1 + s) if l < 0.5 else l + s - l * s
        p = 2 * l - q
        r = hue_to_rgb(p, q, h + 1 / 3)
        g = hue_to_rgb(p, q, h)
        b = hue_to_rgb(p, q, h - 1 / 3)

    return int(math.round(r * 255)), int(math.round(g * 255)), int(math.round(b * 255))

def hex_to_rgb(color):
    # Expand 4 digit hex to 7 digit hex
    if len(color) == 4:
        x = "([A-Fa-f0-9])"
        matches = re.match("#%s%s%s" % (x, x, x), color)
        rgb_hex_list = list(matches[0])
        rgb_hex_list.pop(0)
        for i in range(len(rgb_hex_list)):
            rgb_hex_list[i] = rgb_hex_list[i] + rgb_hex_list[i]
        color = "#" + "".join(rgb_hex_list)

    # Split hex into RGB
    x = "([A-Fa-f0-9]{2})"
    matches = re.match("#%s%s%s" % (x, x, x), color)
    rgb_hex_list = list(matches[0])
    rgb_hex_list.pop(0)
    for i in range(len(rgb_hex_list)):
        rgb_hex_list[i] = int(rgb_hex_list[i], 16)
    rgb = tuple(rgb_hex_list)

    return rgb

# Convert RGB tuple to hex
def rgb_to_hex(r, g, b):
    return "#" + str("%x" % ((1 << 24) + (r << 16) + (g << 8) + b))[1:]

def main(config):
    if config.str("api") == None:
        return render.Root(
            child = render.WrappedText("Please enter the API info!"),
        )
    else:
        api = config.str("api")
        rep_cache = cache.get("teslafi-" + api)
        if rep_cache != None:
            print("Hit! Displaying cached data.")
            rep = json.decode(rep_cache)
        else:
            print("Miss! Calling TeslaFI API.")
            rep = http.get("https://www.teslafi.com/feed.php?token=" + api)
            if rep.status_code != 200:
                fail("TeslaFi request failed with status:", rep.status_code)
            rep = rep.json()

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("teslafi-" + api, json.encode(rep), ttl_seconds = 60)

        name = rep["display_name"]
        rangemi = rep["est_battery_range"]
        if (config.bool("mi2km") == True):
            rangemi = math.round((float(rangemi) * 1.60934) * 100) / 100
        batterylevel = rep["usable_battery_level"]
        chargingstate = rep["charging_state"]

        if chargingstate == "Charging":
            image = BOLT_ANIMATED
        elif chargingstate == "Complete":
            image = BOLT_GREEN
        else:
            image = BOLT_GREY

    state = {
        "batterylevel": batterylevel,
        "color": "#0f0",
        "name": name,
        "rangemi": rangemi,
        "image": image.readall(),
    }

    return render.Root(
        delay = 32,  # 30 fps
        child = render.Box(
            child = render.Animation(
                children = [
                    get_frame(state, fr, config, capanim((fr) * 3))
                    for fr in range(300)
                ],
            ),
        ),
    )

def easeOut(t):
    sqt = t * t
    return sqt / (2.0 * (sqt - t) + 1.0)

def render_progress_bar(state, label, percent, col1, col2, col3, animprogress):
    animpercent = easeOut(animprogress / 100) * percent

    label1color = lightness("#fff", animprogress / 100)
    label2align = "start"
    label2color = lightness(col3, animprogress / 100)

    labelcomponent = None
    widthmax = FRAME_WIDTH - 1
    labelcomponent = render.Stack(
        children = [
            render.Text(
                content = label,
                color = label1color,
                font = "tom-thumb",
            ),
            render.Box(width = 2, height = 6),
        ],
    )
    widthmax -= 4

    progresswidth = max(1, int(widthmax * animpercent / 100))

    progressfill = None
    if animpercent > 0:
        progressfill = render.Row(
            main_align = "start",
            cross_align = "center",
            expanded = True,
            children = [
                render.Box(width = progresswidth, height = 7, color = col2),
                render.Box(width = 1, height = 7, color = col3),
            ],
        )

    label2component = None
    label2component = render.Stack(
        children = [
            render.Text(
                content = "{}%".format(int(percent * animprogress / 100)),
                color = label2color,
                font = "tom-thumb",
            ),
        ],
    )

    return render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            labelcomponent,
            render.Stack(
                children = [
                    render.Row(
                        main_align = "start",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Box(width = widthmax, height = 7, color = col1),
                        ],
                    ),
                    progressfill,
                    render.Row(
                        main_align = label2align,
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Box(width = 1, height = 8),
                            label2component,
                        ],
                    ),
                    render.Row(
                        main_align = "end",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Image(src = state["image"].readall()),
                            render.Box(width = 2, height = 8),
                        ],
                    ),
                ],
            ),
            render.Box(width = 1, height = 8),
        ],
    )

def capanim(input):
    return max(0, min(100, input))

def get_frame(state, fr, config, animprogress):
    children = []

    delay = 0
    color = state["color"]
    if config.bool("carimg") == True:
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Image(src = TESLA.readall()),
                    render.Marquee(
                        width = 40,
                        child = render.Text("%s" % state["name"], font = ""),
                    ),
                ],
            ),
        )
    else:
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Marquee(
                        width = 40,
                        child = render.Text("%s" % state["name"], font = ""),
                    ),
                ],
            ),
        )
    children.append(
        render_progress_bar(state, "", int(state["batterylevel"]), lightness(color, 0.06), lightness(color, 0.18), color, capanim((fr - delay) * 3)),
    )
    children.append(
        render.Row(
            expanded = True,
            main_align = "center",
            children = [
                render.Text("Range: "),
                render.Box(width = 1, height = 1),
                render.Text("%s" % state["rangemi"], font = "", color = lightness("#e5a00d", animprogress / 100)),
            ],
        ),
    )

    return render.Column(
        main_align = "space_between",
        cross_align = "center",
        children = children,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api",
                name = "API Key",
                desc = "API Key for TeslaFi",
                icon = "arrowUpFromBracket",
                secret = True,
            ),
            schema.Toggle(
                id = "mi2km",
                name = "Mi/KM",
                desc = "Convert to KM",
                icon = "codeFork",
                default = True,
            ),
            schema.Toggle(
                id = "carimg",
                name = "Car Image",
                desc = "Show car image",
                icon = "car",
                default = True,
            ),
        ],
    )
