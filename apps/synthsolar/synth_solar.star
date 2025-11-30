"""
Applet: Synth SunDial
Summary: Synth Solar SunDial
Description: Connect to your Synth Solar system by putting in the serial number of your inverter, which is in your Synth Handover Pack. For more information, please go to synth.solar/introduction-to-the-new-synth-sundial/ Any questions please contact max@synth.solar
Author: Synth Solar
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/baboon_icon.png", BABOON_ICON_ASSET = "file")
load("images/bat_icon_10.png", BAT_ICON_10_ASSET = "file")
load("images/bat_icon_100.png", BAT_ICON_100_ASSET = "file")
load("images/bat_icon_25.png", BAT_ICON_25_ASSET = "file")
load("images/bat_icon_50.png", BAT_ICON_50_ASSET = "file")
load("images/bat_icon_75.png", BAT_ICON_75_ASSET = "file")
load("images/battery_0_10.png", BATTERY_0_10_ASSET = "file")
load("images/battery_10_25.png", BATTERY_10_25_ASSET = "file")
load("images/battery_25_40.png", BATTERY_25_40_ASSET = "file")
load("images/battery_40_50.png", BATTERY_40_50_ASSET = "file")
load("images/battery_50_65.png", BATTERY_50_65_ASSET = "file")
load("images/battery_65_80.png", BATTERY_65_80_ASSET = "file")
load("images/battery_80_95.png", BATTERY_80_95_ASSET = "file")
load("images/battery_95_100.png", BATTERY_95_100_ASSET = "file")
load("images/battery_icon.png", BATTERY_ICON_ASSET = "file")
load("images/coin_pile_icon.png", COIN_PILE_ICON_ASSET = "file")
load("images/copper_coin_icon.png", COPPER_COIN_ICON_ASSET = "file")
load("images/current_icon.png", CURRENT_ICON_ASSET = "file")
load("images/goat_icon.png", GOAT_ICON_ASSET = "file")
load("images/goblet_icon.png", GOBLET_ICON_ASSET = "file")
load("images/gold_coin_icon.png", GOLD_COIN_ICON_ASSET = "file")
load("images/img_bf4e974d.svg", IMG_bf4e974d_ASSET = "file")
load("images/koala_icon.png", KOALA_ICON_ASSET = "file")
load("images/lion_icon.png", LION_ICON_ASSET = "file")
load("images/moneybag_icon.png", MONEYBAG_ICON_ASSET = "file")
load("images/moon_icon.png", MOON_ICON_ASSET = "file")
load("images/panel_icon.png", PANEL_ICON_ASSET = "file")
load("images/penguin_icon.png", PENGUIN_ICON_ASSET = "file")
load("images/savings_icon.png", SAVINGS_ICON_ASSET = "file")
load("images/silver_coin_icon.png", SILVER_COIN_ICON_ASSET = "file")
load("images/sun_icon.gif", SUN_ICON_ASSET = "file")
load("images/synth_icon_gif.gif", SYNTH_ICON_GIF_ASSET = "file")
load("images/tortoise_icon.png", TORTOISE_ICON_ASSET = "file")
load("images/treasure_chest_icon.png", TREASURE_CHEST_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BABOON_ICON = BABOON_ICON_ASSET.readall()
BATTERY_0_10 = BATTERY_0_10_ASSET.readall()
BATTERY_10_25 = BATTERY_10_25_ASSET.readall()
BATTERY_25_40 = BATTERY_25_40_ASSET.readall()
BATTERY_40_50 = BATTERY_40_50_ASSET.readall()
BATTERY_50_65 = BATTERY_50_65_ASSET.readall()
BATTERY_65_80 = BATTERY_65_80_ASSET.readall()
BATTERY_80_95 = BATTERY_80_95_ASSET.readall()
BATTERY_95_100 = BATTERY_95_100_ASSET.readall()
BATTERY_ICON = BATTERY_ICON_ASSET.readall()
BAT_ICON_10 = BAT_ICON_10_ASSET.readall()
BAT_ICON_100 = BAT_ICON_100_ASSET.readall()
BAT_ICON_25 = BAT_ICON_25_ASSET.readall()
BAT_ICON_50 = BAT_ICON_50_ASSET.readall()
BAT_ICON_75 = BAT_ICON_75_ASSET.readall()
COIN_PILE_ICON = COIN_PILE_ICON_ASSET.readall()
COPPER_COIN_ICON = COPPER_COIN_ICON_ASSET.readall()
CURRENT_ICON = CURRENT_ICON_ASSET.readall()
GOAT_ICON = GOAT_ICON_ASSET.readall()
GOBLET_ICON = GOBLET_ICON_ASSET.readall()
GOLD_COIN_ICON = GOLD_COIN_ICON_ASSET.readall()
KOALA_ICON = KOALA_ICON_ASSET.readall()
LION_ICON = LION_ICON_ASSET.readall()
MONEYBAG_ICON = MONEYBAG_ICON_ASSET.readall()
MOON_ICON = MOON_ICON_ASSET.readall()
PANEL_ICON = PANEL_ICON_ASSET.readall()
PENGUIN_ICON = PENGUIN_ICON_ASSET.readall()
SAVINGS_ICON = SAVINGS_ICON_ASSET.readall()
SILVER_COIN_ICON = SILVER_COIN_ICON_ASSET.readall()
SUN_ICON = SUN_ICON_ASSET.readall()
SYNTH_ICON_GIF = SYNTH_ICON_GIF_ASSET.readall()
TORTOISE_ICON = TORTOISE_ICON_ASSET.readall()
TREASURE_CHEST_ICON = TREASURE_CHEST_ICON_ASSET.readall()

SYNTH_ICON = IMG_bf4e974d_ASSET.readall()

def get_data(url, params):
    """
    Get daily_gen_+_batt.star widget

    Args:
        url: Base url
        params: Query params

    Returns:
        Widget
    """

    # * Make the call
    response = http.get(url + "?d=" + params, ttl_seconds = 10)

    if response.status_code != 200:
        fail("Request failed with status %d", response.status_code)

    data = response.json()["data"]

    return data

def get_overall_realtime_performance(url, timezone, mode):
    """
    Realtime performance widget

    Args:
        url: Base URL
        timezone: User's timezone
        mode: Device mode, digital or 8bit

    Returns:
        Widget
    """

    # * Make the call
    response = http.get(url + "?d=orp", ttl_seconds = 10)

    if response.status_code != 200:
        fail("Request failed with status %d", response.status_code)

    data = response.json()["data"]

    rtp = data["realtime_performance"] * 100

    max_width = 64

    now = time.now().in_location(timezone)

    if mode == "digital":
        return render.Box(
            width = max_width,
            padding = 1,
            child =
                render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            # main_align = "space_around",
                            # cross_align = "start",
                            children = [
                                render.Padding(
                                    child = render.Text(content = padd_number(str(math.ceil(rtp))) + "%", color = "#FFFF", font = "6x10-rounded"),
                                    pad = (0, 0, 3, 0),
                                ),
                                render.Text(content = "OF MAX", color = "#FFFF", font = "6x10-rounded"),
                            ],
                        ),
                        render.Text(content = "GENERATION", color = "#FFFF", font = "6x10-rounded"),
                        render.Text(content = now.format("3:04 PM"), color = "#B0B0B0", font = "6x10-rounded"),
                    ],
                ),
        )

    else:
        icon = None

        rtp = math.ceil(rtp)

        if rtp == 0:
            icon = render.Image(src = TORTOISE_ICON)
        elif rtp >= 1 and rtp <= 20:
            icon = render.Image(src = KOALA_ICON)
        elif rtp >= 21 and rtp <= 40:
            icon = render.Image(src = PENGUIN_ICON)
        elif rtp >= 41 and rtp <= 60:
            icon = render.Image(src = GOAT_ICON)
        elif rtp >= 61 and rtp <= 80:
            icon = render.Image(src = BABOON_ICON)
        elif rtp >= 81:
            icon = render.Image(src = LION_ICON)

        return render.Box(
            width = max_width,
            padding = 1,
            child = render.Row(
                children = [
                    render.Box(
                        width = max_width // 2,
                        child = render.Column(
                            expanded = True,
                            main_align = "center",
                            cross_align = "start",
                            children = [
                                render.Text(content = "SOLAR", color = "#FFFF", font = "6x10-rounded"),
                                render.Padding(child = render.Text(content = "GEN.", color = "#FFFF", font = "6x10-rounded"), pad = (0, 0, 3, 0)),
                                render.Padding(
                                    child = render.Text(content = padd_number(str(math.ceil(rtp))) + "%", color = "#FF3F00", font = "6x10-rounded"),
                                    pad = (0, 0, 3, 0),
                                ),
                            ],
                        ),
                    ),
                    icon,
                ],
            ),
        )

def get_todays_generation(url, mode):
    """
    Get daily_gen_+_batt.star widget

    Args:
        url: Base URL
        mode: Device mode, digital or 8bit

    Returns:
        Widget
    """

    # * Make the call
    response = http.get(url + "?d=cb_tg", ttl_seconds = 10)

    if response.status_code != 200:
        fail("Request failed with status %d", response.status_code)

    data = response.json()["data"]

    max_width = 64

    total_energy = math.floor(data["total_energy"] * 10) / 10
    power_generation_history = data["power_generation_history"]
    power_generation_history_tuple = [tuple(lst) for lst in power_generation_history]

    return render.Box(
        width = max_width,
        padding = 1,
        child = render.Column(
            children = [
                render.Row(
                    expanded = True,
                    children = [
                        render.Padding(child = render.Text(content = "SYNTH", color = "#FFFF", font = "6x10-rounded"), pad = (0, 0, 3, 0)),
                        render.Text(content = "TODAY", color = "#FFFF", font = "6x10-rounded"),
                    ],
                ),
                render.Text(content = padd_number(str(total_energy), 2) + "kWh", color = "#FFFF" if mode == "digital" else "#FF3F00", font = "6x10-rounded"),
                render.Plot(
                    data = power_generation_history_tuple,
                    width = max_width - 1,
                    height = 12,
                    color = "#FFFF" if mode == "digital" else "#FF3F00",
                    fill = True,
                ),
            ],
        ),
    )

def get_current_load_widget(data, mode):
    """
    Get current inverter load

    Args:
        data: Data from the api
        mode: Device mode, digital or 8bit


    Returns:
        Widget
    """

    max_width = 64

    # * Calculate icon scale
    min_height = 12
    max_height = 32
    min_load = 0.5
    max_load = 5

    total_load = math.ceil(data["load_kw"])

    # * Calculate scale by using linear interpolation
    if total_load >= max_load:
        scale = max_height
    else:
        scale = min_height + (max_height - min_height) * (total_load - min_load) // (max_load - min_load)

        # * Convert float to int
        scale = math.ceil(scale)

    print("Icon scale", scale, "Total Load", total_load, "Total load raw", data["load_kw"], round_to_one_decimal_str(data["load_kw"]) + "kW", "Inverter power", data["inverter_power_kw"])

    if data["inverter_power_kw"] < 0:
        data["inverter_power_kw"] = 0.0

    return render.Box(
        width = max_width,
        padding = 1,
        child = render.Column(
            main_align = "space_around",
            cross_align = "start",
            children = [
                synth_primary_text(
                    "USAGE",
                    round_to_one_decimal_str(data["load_kw"]) + "kW",
                    "#FFFF" if mode == "digital" else "#FF3F00",
                ),
                render.Box(width = max_width, height = 1, color = "#FFFF"),
                render.Row(
                    expanded = True,
                    # main_align = "space_between",
                    cross_align = "start",
                    children = [
                        render.Text(content = "GRID", color = "#B0B0B0", font = "6x10-rounded"),
                        render.Padding(
                            child = render.Text(content = round_to_one_decimal_str(data["grid_power_kw"]) + "kW", color = "#B0B0B0", font = "6x10-rounded"),
                            pad = (9, 0, 0, 0),
                        ),
                    ],
                ),
                synth_primary_text("SYNTH", round_to_one_decimal_str(data["inverter_power_kw"]) + "kW", "#B0B0B0" if mode == "digital" else "#FFF599"),
            ],
        ),
    )

def get_current_battery_charge_widget(data, mode):
    """
    Get daily_gen_+_batt.star widget

    Args:
        data: Data from the api
        mode: Device mode, digital or 8bit


    Returns:
        Widget
    """
    max_width = 64
    battery_power = data["battery_power"] or 0
    battery_soc = data["battery_soc"] or 0

    print("Battery level ", battery_soc)

    if battery_soc == 100:
        battery_state = "CHARGED"
    elif battery_soc <= 10:
        battery_state = "DISCHARGED"
    elif battery_power > 0:
        battery_state = "CHARGING"
    else:
        battery_state = "POWERING"

    mapped_battery_value = 0 if battery_soc == 0 else int((math.ceil(battery_soc) / 100) * 60)

    if mode == "digital":
        return render.Box(
            width = max_width,
            padding = 1,
            child = render.Column(
                main_align = "space_around",
                cross_align = "start",
                children = [
                    synth_primary_text(padd_number(str(math.ceil(battery_soc))) + "%", ""),
                    render.Stack(
                        children = [
                            render.Box(
                                width = 62,
                                height = 9,
                                color = "#ffff",
                                child = render.Box(
                                    width = 60,
                                    height = 7,
                                    color = "#000",
                                ),
                            ),
                            render.Padding(
                                pad = (1, 1, 0, 0),
                                child = render.Box(
                                    width = mapped_battery_value,
                                    height = 7,
                                    color = "#B0B0B0",
                                ),
                            ),
                        ],
                    ),
                    synth_primary_text(battery_state, ""),
                ],
            ),
        )
    else:
        icon = None

        if battery_soc > 95:
            icon = render.Image(src = BATTERY_95_100)
        elif battery_soc >= 80 and battery_soc <= 95:
            icon = render.Image(src = BATTERY_80_95)
        elif battery_soc >= 65 and battery_soc < 80:
            icon = render.Image(src = BATTERY_65_80)
        elif battery_soc >= 50 and battery_soc < 65:
            icon = render.Image(src = BATTERY_50_65)
        elif battery_soc >= 40 and battery_soc < 50:
            icon = render.Image(src = BATTERY_40_50)
        elif battery_soc >= 25 and battery_soc < 40:
            icon = render.Image(src = BATTERY_25_40)
        elif battery_soc > 10 and battery_soc < 25:
            icon = render.Image(src = BATTERY_10_25)
        else:
            icon = render.Image(src = BATTERY_0_10)

        return render.Box(
            width = max_width,
            padding = 1,
            child =
                render.Padding(
                    pad = (1, 0, 0, 0),
                    child = render.Column(
                        main_align = "space_evenly",
                        children = [
                            synth_primary_text(padd_number(str(math.ceil(battery_soc))) + "%", ""),
                            icon,
                            synth_primary_text(battery_state, ""),
                        ],
                    ),
                ),
        )

def round_to_one_decimal_str(x):
    # Round to 0 if the value is less than 0.05 in magnitude
    if math.fabs(x) < 0.05:
        return "0.0"

    v = str(int(math.round(x * 10)))
    if len(v) == 1:
        v = "0" + v
    v = (v[0:-1] + "." + v[-1:])
    return v

def round_to_two_decimals_str(x):
    if math.fabs(x) < 0.005:
        return "0.00"

    rounded_value = math.round(x * 100) / 100.0

    whole, fraction = str(rounded_value).split(".")

    # Ensure the fraction has exactly two digits
    if len(fraction) == 1:
        fraction += "0"
    elif len(fraction) == 0:
        fraction = "00"

    v = whole + "." + fraction

    if math.fabs(x) < 1:
        # Add leading zero for values less than 1
        v = "0" + v.lstrip("0") if x >= 0 else "-0" + v[1:].lstrip("0")

    return v

def get_savings(url, timezone, mode):
    """
    Get savings

    Args:
        url: Base URL
        timezone: User's timezone, defaults for London
        mode: Device mode, digital or 8bit

    Returns:
        Widget
    """

    # * Make the call
    response = http.get(url + "?d=es", ttl_seconds = 60 * 5)

    if response.status_code != 200:
        fail("Request failed with status %d", response.status_code)

    data = response.json()["data"]

    total_savings_today = data["total_savings_today"]

    max_width = 64

    now = time.now().in_location(timezone)
    formatted_date = now.format("Mon Jan 2").upper()

    if mode == "digital":
        return render.Box(
            width = max_width,
            padding = 1,
            child = render.Column(
                children = [
                    render.Box(
                        width = max_width,
                        child = render.Column(
                            expanded = True,
                            main_align = "center",
                            cross_align = "start",
                            children = [
                                render.Text(content = formatted_date, color = "#B0B0B0", font = "6x10-rounded"),
                                render.Row(
                                    expanded = True,
                                    # main_align = "space_around",
                                    # cross_align = "start",
                                    children = [
                                        render.Padding(child = render.Text(content = "SYNTH", color = "#FFFF", font = "6x10-rounded"), pad = (0, 0, 3, 0)),
                                        render.Text(content = "SAVED", color = "#FFFF", font = "6x10-rounded"),
                                    ],
                                ),
                                render.Text(content = "£" + str(round_to_two_decimals_str(total_savings_today)), color = "#FFFF", font = "6x10-rounded"),
                            ],
                        ),
                    ),
                ],
            ),
        )
    else:
        icon = None
        text_widget = [
            render.Text(content = "SYNTH", color = "#FFFF", font = "6x10-rounded"),
            render.Padding(child = render.Text(content = "SAVED", color = "#FFFF", font = "6x10-rounded"), pad = (0, 0, 3, 0)),
            render.Text(content = "£" + str(round_to_two_decimals_str(total_savings_today)), color = "#FF3F00", font = "6x10-rounded"),
        ]

        if 0.00 <= total_savings_today and total_savings_today <= 0.20:
            icon = render.Image(src = COPPER_COIN_ICON)
            text_widget = [
                render.Text(content = "SAVED", color = "#FFFF", font = "6x10-rounded"),
                render.Text(content = "£" + str(round_to_two_decimals_str(total_savings_today)), color = "#FF3F00", font = "6x10-rounded"),
                render.Padding(child = render.Text(content = "TODAY", color = "#FFFF", font = "6x10-rounded"), pad = (0, 0, 3, 0)),
            ]
        elif 0.21 <= total_savings_today and total_savings_today <= 0.50:
            icon = render.Image(src = SILVER_COIN_ICON)
            text_widget = [
                render.Text(content = "SAVED", color = "#FFFF", font = "6x10-rounded"),
                render.Text(content = "£" + str(round_to_two_decimals_str(total_savings_today)), color = "#FF3F00", font = "6x10-rounded"),
                render.Padding(child = render.Text(content = "TODAY", color = "#FFFF", font = "6x10-rounded"), pad = (0, 0, 3, 0)),
            ]
        elif 0.51 <= total_savings_today and total_savings_today <= 1.00:
            icon = render.Image(src = GOLD_COIN_ICON)
        elif 1.01 <= total_savings_today and total_savings_today <= 2.00:
            icon = render.Image(src = COIN_PILE_ICON)
        elif 2.01 <= total_savings_today and total_savings_today <= 3.00:
            icon = render.Image(src = GOBLET_ICON)
        else:
            icon = render.Image(src = TREASURE_CHEST_ICON)

        return render.Box(
            width = max_width,
            child = render.Row(
                main_align = "start",
                children = [
                    icon,
                    render.Box(
                        width = max_width // 2,
                        child = render.Column(
                            expanded = True,
                            main_align = "center",
                            cross_align = "start",
                            children = text_widget,
                        ),
                    ),
                ],
            ),
        )

def build_keyframe(offset, pct):
    return animation.Keyframe(
        percentage = pct,
        transforms = [animation.Translate(offset, 0)],
        curve = "ease_in_out",
    )

def get_schema():
    mode_options = [
        schema.Option(
            display = "Classic",
            value = "digital",
        ),
        schema.Option(
            display = "8-bit",
            value = "8bit",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serial_number",
                name = "Serial Number",
                desc = "Serial number of your inverter.",
                icon = "solarPanel",
                default = "",
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "User's timezone",
                icon = "clock",
                default = "Europe/London",
            ),
            schema.Dropdown(
                id = "mode",
                name = "Mode",
                desc = "Classic or 8-bit mode",
                icon = "brush",
                default = mode_options[0].value,
                options = mode_options,
            ),
        ],
    )

def padd_number(number, padd_by = 3):
    # * Convert the number to a string if it's not already
    number_str = str(number)

    # * Check if the number has a decimal point
    if "." in number_str:
        # * Split into integer and decimal parts
        integer_part, decimal_part = number_str.split(".")

        # * Pad the integer part
        zeros_needed = padd_by - len(integer_part)
        padded_integer_part = "0" * zeros_needed + integer_part

        # * Recombine the integer and decimal parts
        padded_number = padded_integer_part + "." + decimal_part
    else:
        zeros_needed = padd_by - len(number_str)
        padded_number = "0" * zeros_needed + number_str

    return padded_number

def get_widgets_and_animations(url, timezone, mode):
    """
    Get widget and animations

    Args:
        url: Base URL
        timezone: User's timezone, defaults for London
        mode: Device mode, digital or 8bit

    Returns:
        Widgets & Animations
    """
    max_width = 64

    keyframes = []
    widgets = []
    max_animation_duration = 1000

    # * Get battery data
    battery_data = get_data(url, "cb_tg")

    # * Get load data
    load_data = get_data(url, "load")

    if not battery_data.get("battery_soc") and load_data.get("load_kw", 0) <= 0.001:
        print("No battery and load data found")
        widgets = [
            get_savings(url, timezone, mode),
            get_todays_generation(url, mode),
            get_overall_realtime_performance(url, timezone, mode),
        ]
        keyframes = [
            build_keyframe(0, 0.0),
            build_keyframe(0, 0.33),
            build_keyframe(-max_width, 0.33),
            build_keyframe(-max_width, 0.66),
            build_keyframe(-max_width * 2, 0.66),
            build_keyframe(-max_width * 2, 1.0),
        ]

        max_animation_duration //= 2

    elif not battery_data.get("battery_soc"):
        widgets = [
            get_savings(url, timezone, mode),
            get_todays_generation(url, mode),
            get_overall_realtime_performance(url, timezone, mode),
            get_current_load_widget(load_data, mode),
        ]
        keyframes = [
            build_keyframe(0, 0.0),
            build_keyframe(0, 0.25),
            build_keyframe(-max_width, 0.25),
            build_keyframe(-max_width, 0.5),
            build_keyframe(-max_width * 2, 0.5),
            build_keyframe(-max_width * 2, 0.75),
            build_keyframe(-max_width * 3, 0.75),
            build_keyframe(-max_width * 3, 1.0),
        ]

    elif load_data.get("load_kw", 0) <= 0.001:
        widgets = [
            get_savings(url, timezone, mode),
            get_todays_generation(url, mode),
            get_current_battery_charge_widget(battery_data, mode),
            get_overall_realtime_performance(url, timezone, mode),
        ]
        keyframes = [
            build_keyframe(0, 0.0),
            build_keyframe(0, 0.25),
            build_keyframe(-max_width, 0.25),
            build_keyframe(-max_width, 0.5),
            build_keyframe(-max_width * 2, 0.5),
            build_keyframe(-max_width * 2, 0.75),
            build_keyframe(-max_width * 3, 0.75),
            build_keyframe(-max_width * 3, 1.0),
        ]

    else:
        widgets = [
            get_savings(url, timezone, mode),
            get_todays_generation(url, mode),
            get_current_battery_charge_widget(battery_data, mode),
            get_overall_realtime_performance(url, timezone, mode),
            get_current_load_widget(load_data, mode),
        ]
        keyframes = [
            build_keyframe(0, 0.0),
            build_keyframe(0, 0.2),
            build_keyframe(-max_width, 0.2),
            build_keyframe(-max_width, 0.4),
            build_keyframe(-max_width * 2, 0.4),
            build_keyframe(-max_width * 2, 0.6),
            build_keyframe(-max_width * 3, 0.6),
            build_keyframe(-max_width * 3, 0.8),
            build_keyframe(-max_width * 4, 0.8),
            build_keyframe(-max_width * 4, 1.0),
        ]

    return keyframes, widgets, max_animation_duration

def synth_primary_text(str1, str2, color = "#FFFF"):
    return render.Row(
        expanded = True,
        children = [
            render.Padding(child = render.Text(content = str1, color = color, font = "6x10-rounded"), pad = (0, 0, 3, 0)),
            render.Text(content = str2, color = color, font = "6x10-rounded"),
        ],
    )

def main(config):
    """
    Main driver function

    Args:
        config: Tidbyt config

    Returns:
        Root Widget
    """
    serial_number = config.get("serial_number")
    timezone = config.get("timezone") or "Europe/London"
    mode = config.get("mode")

    max_width = 64

    print("selected mode ", mode)

    if not serial_number:
        return render.Root(
            delay = 80,
            show_full_animation = True,
            child = render.Row(
                children = [
                    animation.Transformation(
                        duration = 250,
                        width = max_width * 2,
                        keyframes = [
                            build_keyframe(0, 0.0),
                            build_keyframe(0, 0.5),
                            build_keyframe(-max_width, 0.75),
                            build_keyframe(-max_width, 1.0),
                        ],
                        child = render.Row(
                            children = [
                                render.Image(src = SYNTH_ICON_GIF, width = max_width, height = 32),
                                render.Box(
                                    width = 64,
                                    child = render.Column(
                                        main_align = "center",
                                        cross_align = "center",
                                        expanded = True,
                                        children = [
                                            render.Text(content = "ENTER", color = "#ffffff", font = "6x10-rounded"),
                                            render.Text(content = "SERIAL", color = "#ffffff", font = "6x10-rounded"),
                                            render.Text(content = "NUMBER", color = "#ffffff", font = "6x10-rounded"),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                        wait_for_child = True,
                    ),
                ],
            ),
        )

    BASE_URL = "https://api.synth.solar/api/v1/devices/" + serial_number + "/data"

    keyframes, widgets, max_animation_duration = get_widgets_and_animations(BASE_URL, timezone, mode)

    return render.Root(
        delay = 80,
        show_full_animation = True,
        child = render.Row(
            children = [
                animation.Transformation(
                    duration = max_animation_duration,
                    width = max_width * 6,
                    keyframes = keyframes,
                    child = render.Row(
                        children = widgets,
                    ),
                    wait_for_child = True,
                ),
            ],
        ),
    )
