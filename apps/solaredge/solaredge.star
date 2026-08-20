"""
Applet: SolarEdge
Summary: SolarEdge system monitor
Description: Energy production and consumption monitor for your SolarEdge solar panels.
Author: ingmarstein
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/autarky_16x16.png", AUTARKY_16X16_ASSET = "file")
load("images/battery.gif", BATTERY_ASSET = "file")
load("images/battery_0_to_25_main_screen.png", BATTERY_0_TO_25_MAIN_SCREEN_ASSET = "file")
load("images/battery_25_to_50_main_screen.png", BATTERY_25_TO_50_MAIN_SCREEN_ASSET = "file")
load("images/battery_50_to_75_main_screen.png", BATTERY_50_TO_75_MAIN_SCREEN_ASSET = "file")
load("images/battery_75_to_100_main_screen.png", BATTERY_75_TO_100_MAIN_SCREEN_ASSET = "file")
load("images/battery_charge_animation_10x10.gif", BATTERY_CHARGE_ANIMATION_10X10_ASSET = "file")
load("images/battery_charge_status_0_25_10x10.gif", BATTERY_CHARGE_STATUS_0_25_10X10_ASSET = "file")
load("images/battery_charge_status_25_50_10x10.gif", BATTERY_CHARGE_STATUS_25_50_10X10_ASSET = "file")
load("images/battery_charge_status_50_75_10x10.gif", BATTERY_CHARGE_STATUS_50_75_10X10_ASSET = "file")
load("images/battery_charge_status_75_100_10x10.gif", BATTERY_CHARGE_STATUS_75_100_10X10_ASSET = "file")
load("images/battery_discharge_animation_10x10.gif", BATTERY_DISCHARGE_ANIMATION_10X10_ASSET = "file")
load("images/battery_noflow_animation_10x10.gif", BATTERY_NOFLOW_ANIMATION_10X10_ASSET = "file")
load("images/empty.png", EMPTY_ASSET = "file")
load("images/green_anim.gif", GREEN_ANIM_ASSET = "file")
load("images/grid.png", GRID_ASSET = "file")
load("images/house.png", HOUSE_ASSET = "file")
load("images/plug.gif", PLUG_ASSET = "file")
load("images/plug_sum.gif", PLUG_SUM_ASSET = "file")
load("images/red_anim.gif", RED_ANIM_ASSET = "file")
load("images/solar.png", SOLAR_ASSET = "file")
load("images/sun.gif", SUN_ASSET = "file")
load("images/sun_sum.png", SUN_SUM_ASSET = "file")
load("images/yellow_anim.gif", YELLOW_ANIM_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

AUTARKY_16X16 = AUTARKY_16X16_ASSET.readall()
BATTERY = BATTERY_ASSET.readall()
BATTERY_0_TO_25_MAIN_SCREEN = BATTERY_0_TO_25_MAIN_SCREEN_ASSET.readall()
BATTERY_25_TO_50_MAIN_SCREEN = BATTERY_25_TO_50_MAIN_SCREEN_ASSET.readall()
BATTERY_50_TO_75_MAIN_SCREEN = BATTERY_50_TO_75_MAIN_SCREEN_ASSET.readall()
BATTERY_75_TO_100_MAIN_SCREEN = BATTERY_75_TO_100_MAIN_SCREEN_ASSET.readall()
BATTERY_CHARGE_ANIMATION_10X10 = BATTERY_CHARGE_ANIMATION_10X10_ASSET.readall()
BATTERY_CHARGE_STATUS_0_25_10X10 = BATTERY_CHARGE_STATUS_0_25_10X10_ASSET.readall()
BATTERY_CHARGE_STATUS_25_50_10X10 = BATTERY_CHARGE_STATUS_25_50_10X10_ASSET.readall()
BATTERY_CHARGE_STATUS_50_75_10X10 = BATTERY_CHARGE_STATUS_50_75_10X10_ASSET.readall()
BATTERY_CHARGE_STATUS_75_100_10X10 = BATTERY_CHARGE_STATUS_75_100_10X10_ASSET.readall()
BATTERY_DISCHARGE_ANIMATION_10X10 = BATTERY_DISCHARGE_ANIMATION_10X10_ASSET.readall()
BATTERY_NOFLOW_ANIMATION_10X10 = BATTERY_NOFLOW_ANIMATION_10X10_ASSET.readall()
EMPTY = EMPTY_ASSET.readall()
GREEN_ANIM = GREEN_ANIM_ASSET.readall()
GRID = GRID_ASSET.readall()
HOUSE = HOUSE_ASSET.readall()
PLUG = PLUG_ASSET.readall()
PLUG_SUM = PLUG_SUM_ASSET.readall()
RED_ANIM = RED_ANIM_ASSET.readall()
SOLAR = SOLAR_ASSET.readall()
SUN = SUN_ASSET.readall()
SUN_SUM = SUN_SUM_ASSET.readall()
YELLOW_ANIM = YELLOW_ANIM_ASSET.readall()

URL = "https://monitoringapi.solaredge.com/site/{}/currentPowerFlow"
URL_AUT = "https://monitoringapi.solaredge.com/site/{}/energyDetails"

# SolarEdge API limit is 300 requests per day, which is about
# one per 5 minutes
CACHE_TTL = 300

DUMMY_DATA = {
    "siteCurrentPowerFlow": {
        "updateRefreshRate": 3,
        "unit": "kW",
        "connections": [
            {"from": "GRID", "to": "Load"},
            {"from": "PV", "to": "Load"},
            {"from": "STORAGE", "to": "Load"},
        ],
        "GRID": {"status": "Active", "currentPower": 1.57},
        "LOAD": {"status": "Active", "currentPower": 4.71},
        "PV": {"status": "Active", "currentPower": 3.14},
        "STORAGE": {
            "status": "Discharging",
            "currentPower": 1.42,
            "chargeLevel": 86,
            "critical": False,
        },
    },
}

DUMMY_DATA_AUTARKY_YEAR = {
    "energyDetails": {
        "timeUnit": "YEAR",
        "unit": "Wh",
        "meters": [
            {
                "type": "SelfConsumption",
                "values": [
                    {
                        "date": "2024-01-01 00:00:00",
                        "value": 5329901.0,
                    },
                ],
            },
            {
                "type": "Consumption",
                "values": [
                    {
                        "date": "2024-01-01 00:00:00",
                        "value": 6961366.0,
                    },
                ],
            },
        ],
    },
}

GRAY = "#777777"
RED = "#AA0000"  # very bright at FF, dim a little to AA
GREEN = "#00FF00"
ORANGE = "#FFA500"
YELLOW = "#FFFF00"
WHITE = "#FFFFFF"

# need 5 items because 100% is index 4
battery_level_icons = [BATTERY_CHARGE_STATUS_0_25_10X10, BATTERY_CHARGE_STATUS_25_50_10X10, BATTERY_CHARGE_STATUS_50_75_10X10, BATTERY_CHARGE_STATUS_75_100_10X10, BATTERY_CHARGE_STATUS_75_100_10X10]
battery_level_mains = [BATTERY_0_TO_25_MAIN_SCREEN, BATTERY_25_TO_50_MAIN_SCREEN, BATTERY_50_TO_75_MAIN_SCREEN, BATTERY_75_TO_100_MAIN_SCREEN, BATTERY_75_TO_100_MAIN_SCREEN]
soc_color = [RED, ORANGE, YELLOW, GREEN, GREEN]

def render_fail(rep):
    content = json.decode(rep.body())
    return render.Root(render.Box(render.WrappedText(str(rep.status_code) + " : " + content["String"], color = RED)))

def get_energy_details(site_id, api_key, tz, interval):
    now = time.now().in_location(tz)
    start_string = ""
    now_string = humanize.time_format("yyyy-MM-dd HH:mm:ss", now)
    if interval == "day":  # from the start of today to now, just set time to 00:00
        start_string = humanize.time_format("yyyy-MM-dd 00:00:00", now)
        time_unit = "DAY"
    elif interval == "24h":  # the last 24hr from now, use a now-duration
        duration = 24 * time.hour
        start_time = now - duration
        start_string = humanize.time_format("yyyy-MM-dd HH:mm:ss", start_time)
        time_unit = "DAY"
    elif interval == "month":  # from the start of the month to now, just set day to 01 and time to 00:00
        start_time = humanize.time_format("yyyy-MM-01 00:00:00", now)
        time_unit = "MONTH"
    elif interval == "year":  # from the start of the year to now, set month/day to 01/01 and time to 00:00
        start_string = humanize.time_format("yyyy-01-01 00:00:00", now)
        time_unit = "YEAR"
    else:
        return None
    url = URL_AUT.format(site_id, start_string, now_string)
    rep = http.get(
        url,
        params = {
            "api_key": api_key,
            "startTime": start_string,
            "endTime": now_string,
            "timeUnit": time_unit,
        },
        ttl_seconds = CACHE_TTL,
    )

    if rep.status_code != 200:
        print(rep.status_code)
        print(rep.body())
        return None

    return rep.json()["energyDetails"]

def get_autarky_percent(site_id, api_key, tz, interval):
    energy_details = get_energy_details(site_id, api_key, tz, interval)
    if not energy_details:
        return 0
    self_consumption = 0
    consumption = 0
    for m in energy_details["meters"]:
        if m["type"] == "SelfConsumption":
            for v in m["values"]:
                self_consumption += v["value"]
        elif m["type"] == "Consumption":
            for v in m["values"]:
                consumption += v["value"]
    if consumption == 0:
        return 100
    return int(self_consumption / consumption * 100)

def main(config):
    api_key = config.str("api_key")
    site_id = humanize.url_encode(config.str("site_id", ""))
    has_battery = False  #  assume no battery until we have data

    if api_key and site_id:
        tz = time.tz()
        url = URL.format(site_id)
        rep = http.get(url, params = {"api_key": api_key}, ttl_seconds = CACHE_TTL)
        if rep.status_code != 200:
            print(rep.body())
            return render_fail(rep)
        o = json.decode(rep.body())

        consumption = 0
        production = 0
        if config.bool("show_summary", False) == True:
            today_energy = get_energy_details(site_id, api_key, tz, "day")
            if today_energy:
                for m in today_energy["meters"]:
                    if m["type"] == "Consumption":
                        for v in m["values"]:
                            consumption += v["value"]
                    elif m["type"] == "Production":
                        for v in m["values"]:
                            production += v["value"]

        if config.bool("show_autarky", False) == True:
            autarky_day = get_autarky_percent(site_id, api_key, tz, "day")
            autarky_24h = get_autarky_percent(site_id, api_key, tz, "24h")
            autarky_month = get_autarky_percent(site_id, api_key, tz, "month")
            autarky_year = get_autarky_percent(site_id, api_key, tz, "year")
        else:
            autarky_day = None
            autarky_24h = None
            autarky_month = None
            autarky_year = None
    else:
        print("using dummy data")
        o = DUMMY_DATA
        consumption = 3141
        production = 6282
        autarky_day = 99
        autarky_24h = 97
        autarky_month = 95
        autarky_year = 76
    frames = []

    o = o["siteCurrentPowerFlow"]
    unit = o["unit"]
    connections = o["connections"]
    if "STORAGE" in o:
        has_battery = True

    if o["PV"]["status"] == "Active":
        solar_anim = GREEN_ANIM
        solar_icon = SOLAR
        solar_value = o["PV"]["currentPower"]
        solar_color = GREEN
    elif has_battery:  # only do this if we have battery data
        # change to battery data even though it's still called solar
        solar_icon = battery_level_mains[int(o["STORAGE"]["chargeLevel"] / 25)]  # will be integer 0 - 3
        solar_value = o["STORAGE"]["currentPower"]
        if solar_value == 0:
            solar_anim = EMPTY
            solar_color = GRAY
        elif solar_value > 0:
            solar_anim = RED_ANIM
            solar_color = WHITE
        else:
            solar_anim = YELLOW_ANIM
            solar_color = WHITE
    else:
        solar_anim = EMPTY
        solar_icon = SOLAR
        solar_value = o["PV"]["currentPower"]  # should be zero
        solar_color = GRAY

    grid_anim = EMPTY
    grid_color = GRAY
    grid_rate = o["GRID"]["currentPower"]
    if o["GRID"]["status"] == "Active":
        if {"from": "LOAD", "to": "Grid"} in connections:
            grid_anim = GREEN_ANIM
            grid_color = GREEN
        elif {"from": "GRID", "to": "Load"} in connections:
            grid_anim = RED_ANIM
            grid_color = RED

    # MAIN FRAME
    #######################################
    main_frame = render.Row(
        children = [
            render.Box(
                height = 32,
                width = 15,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = solar_icon, height = 15),
                        render.Padding(
                            pad = (1, 0, 0, 0),
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(format_power(abs(solar_value)), color = solar_color),
                                    render.Text(unit, color = GRAY),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            render.Box(
                height = 32,
                width = 10,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "start",
                    children = [
                        render.Image(src = solar_anim),
                    ],
                ),
            ),
            render.Box(
                height = 32,
                width = 15,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = HOUSE, height = 15),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(format_power(o["LOAD"]["currentPower"])),
                                    render.Text(unit, color = GRAY),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            render.Box(
                height = 32,
                width = 10,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "start",
                    children = [
                        render.Image(src = grid_anim),
                    ],
                ),
            ),
            render.Box(
                height = 32,
                width = 14,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = GRID),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(format_power(abs(grid_rate)), color = grid_color),
                                    render.Text(unit, color = GRAY),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

    if config.bool("show_main", True):
        frames.append(main_frame)

    # CHARGE FRAME shows charge/discharge rate and state of charge percent
    #########################################################
    if config.bool("show_char", False) and has_battery:
        charge_level = o["STORAGE"]["chargeLevel"]
        storage_power = o["STORAGE"]["currentPower"]
        if o["STORAGE"]["status"] == "Discharging":
            BATTERY_FLOW_ICON = BATTERY_DISCHARGE_ANIMATION_10X10
            flow_color = RED
        elif o["STORAGE"]["status"] == "Charging":
            BATTERY_FLOW_ICON = BATTERY_CHARGE_ANIMATION_10X10
            flow_color = GREEN
        else:
            BATTERY_FLOW_ICON = BATTERY_NOFLOW_ANIMATION_10X10
            flow_color = GRAY

        charge_frame = render.Stack(
            children = [
                render.Column(
                    main_align = "space_evenly",  # this controls position of children, start = top
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Text(" ", height = 1),
                            ],
                        ),
                        render.Row(
                            #expanded = True,
                            children = [
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "center",
                                    children = [
                                        render.Image(src = battery_level_icons[int(charge_level / 25)]),
                                        render.Image(src = BATTERY_FLOW_ICON),
                                    ],
                                ),
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "end",
                                    children = [
                                        render.Text(
                                            content = " " + str(charge_level) + " %",
                                            font = "5x8",
                                            #font = "6x13",
                                            color = soc_color[int(charge_level / 25)],
                                        ),
                                        render.Text(
                                            content = " " + humanize.float("#,###.##", float(abs(storage_power))) + " " + unit,
                                            font = "5x8",
                                            #font = "6x13",
                                            #min = a if a < b else b
                                            color = flow_color,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )
        frames.append(charge_frame)

    # SOLAR PRODUCTION FRAME
    if config.bool("show_prod", False):
        production_frame = render.Box(
            render.Row(
                expanded = True,
                cross_align = "center",
                main_align = "space_evenly",
                children = [
                    render.Image(src = SUN),
                    render.Text(
                        content = humanize.float("#,###.##", float(o["PV"]["currentPower"])) + " " + unit,
                        font = "5x8",
                        color = GREEN,
                    ),
                ],
            ),
        )
        frames.append(production_frame)

    # CONSUMPTION FRAME
    if config.bool("show_cons", False):
        consumption_frame = render.Box(
            render.Row(
                expanded = True,
                cross_align = "center",
                main_align = "space_evenly",
                children = [
                    render.Image(src = PLUG),
                    render.Text(
                        content = humanize.float("#,###.##", float(o["LOAD"]["currentPower"])) + " " + unit,
                        #font = "6x13",
                        font = "5x8",
                        color = RED,
                    ),
                ],
            ),
        )
        frames.append(consumption_frame)

    if config.bool("show_summary", False):
        # summary page for daily accumulated generation and consumption
        ###############################################
        summary_frame = render.Stack(
            children = [
                render.Column(
                    main_align = "space_evenly",  # this controls position of children, start = top
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            cross_align = "center",
                            children = [
                                render.Text("Energy Today"),
                            ],
                        ),
                        render.Row(
                            #expanded = True,
                            children = [
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "center",
                                    children = [
                                        render.Image(src = SUN_SUM),
                                        render.Image(src = PLUG_SUM),
                                    ],
                                ),
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "end",
                                    children = [
                                        render.Text(
                                            content = " " + humanize.float("#,###.##", production / 1000) + " kWh",
                                            font = "5x8",
                                            color = GREEN,
                                        ),
                                        render.Text(
                                            content = " " + humanize.float("#,###.##", consumption / 1000) + " kWh",
                                            font = "5x8",
                                            color = RED,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )
        frames.append(summary_frame)

    # AUTARKY FRAME
    if config.bool("show_autarky", False):
        autarky_frame = render.Stack(
            children = [
                render.Box(
                    height = 32,
                    width = 64,
                    child = render.Image(src = AUTARKY_16X16),
                ),
                render.Column(
                    # column for the top
                    main_align = "start",
                    expanded = True,
                    children = [
                        # top row
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Row([render.Text("24hr:", font = "tom-thumb", color = GRAY)]),
                                render.Row([render.Text("Month:", font = "tom-thumb", color = GRAY)]),
                            ],
                        ),

                        # second row
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Row([render.Text(" {}%".format(autarky_24h), color = GREEN)]),
                                render.Row([render.Text("{}%".format(autarky_month), color = GREEN)]),
                            ],
                        ),
                    ],
                ),
                render.Column(
                    main_align = "end",
                    expanded = True,
                    children = [
                        # third row
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Row([render.Text("Today:", font = "tom-thumb", color = GRAY)]),
                                render.Row([render.Text("Year:", font = "tom-thumb", color = GRAY)]),
                            ],
                        ),

                        # fourth row
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Row([render.Text(" {}%".format(autarky_day), color = GREEN)]),
                                render.Row([render.Text("{}%".format(autarky_year), color = GREEN)]),
                            ],
                        ),
                    ],
                ),
            ],
        )
        frames.append(autarky_frame)

    if len(frames) == 1:
        return render.Root(frames[0])
    elif len(frames) == 0:
        return render.Root(main_frame)
    else:
        return render.Root(
            #show_full_animation = True,
            delay = int(config.get("frame_delay", "3")) * 1000,
            child = render.Animation(children = frames),
        )

def format_power(p):
    if p and p < 10:
        return humanize.float("#,###.#", p)
    elif p:
        return humanize.float("#,###.", p)
    else:
        return "0"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "API key for the SolarEdge monitoring API.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "The site ID, available from the monitoring portal.",
                icon = "solarPanel",
            ),
            schema.Toggle(
                id = "show_main",
                name = "Show Main Stats",
                desc = "Realtime solar production, home consumption and grid usage. Note : Multiple screen selections will disable animations. If you prefer animated screens, run separate instances of the app and select a screen per instance.",
                icon = "solarPanel",
                default = True,
            ),
            schema.Toggle(
                id = "show_char",
                name = "Show Battery",
                desc = "State of charge of the battery and battery flow.",
                icon = "carBattery",
                default = False,
            ),
            schema.Toggle(
                id = "show_prod",
                name = "Show Current Production",
                desc = "Realtime solar energy production.",
                icon = "sun",
                default = False,
            ),
            schema.Toggle(
                id = "show_cons",
                name = "Show Current Consumption",
                desc = "Realtime energy consumption.",
                icon = "plugCircleBolt",
                default = False,
            ),
            schema.Toggle(
                id = "show_summary",
                name = "Show Daily Summary",
                desc = "Accumulated daily energy production and consumption.",
                icon = "chartLine",
                default = True,
            ),
            schema.Toggle(
                id = "show_autarky",
                name = "Show Autarky Frame",
                desc = "Display the autarky values for day, week, month, year.",
                icon = "compress",
                default = False,
            ),
            schema.Dropdown(
                id = "frame_delay",
                name = "Seconds per frame",
                desc = "This option is only used if multiple screens are selected.  (Multiple screens will disable animations.)",
                icon = "clock",
                default = "3",
                options = [
                    schema.Option(
                        display = "1 sec",
                        value = "1",
                    ),
                    schema.Option(
                        display = "2 sec",
                        value = "2",
                    ),
                    schema.Option(
                        display = "3 sec",
                        value = "3",
                    ),
                    schema.Option(
                        display = "4 sec",
                        value = "4",
                    ),
                    schema.Option(
                        display = "5 sec",
                        value = "5",
                    ),
                ],
            ),
        ],
    )
