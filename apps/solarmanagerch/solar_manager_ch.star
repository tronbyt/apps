"""
Applet: Solar Manager Ch
Summary: Show solarmanager.ch status
Description: Multiple screen selections will disable animations. For animated screens, run separate instances of the app and select 1 screen per instance.  For API Key : authorize with your Solarmanager username and password at: https://external-web.solar-manager.ch/swagger and copy the long string that follows after '-H authorization: Basic'.  For Site ID : check the back of your solarmanager device for the SMID code.  If you have an aux sensor the ID can be found be executing the GET/v1/info/senors/(smid) command on the solarmanager API. Add your car's sensor ID by copying the value found in the "Data" section in the Solarmanager API. For multiple cars use a separate app instance.
Author: tavdog, marcbaier
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/audi_logo_24x9.png", AUDI_LOGO_24X9_ASSET = "file")
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
load("images/battery_charge_test_10x10.gif", BATTERY_CHARGE_TEST_10X10_ASSET = "file")
load("images/battery_discharge_animation_10x10.gif", BATTERY_DISCHARGE_ANIMATION_10X10_ASSET = "file")
load("images/battery_noflow_animation_10x10.gif", BATTERY_NOFLOW_ANIMATION_10X10_ASSET = "file")
load("images/bmw_logo_18x18.png", BMW_LOGO_18X18_ASSET = "file")
load("images/cupra_logo_18x18.png", CUPRA_LOGO_18X18_ASSET = "file")
load("images/custom_sensor_16_16.png", CUSTOM_SENSOR_16_16_ASSET = "file")
load("images/empty.png", EMPTY_ASSET = "file")
load("images/ev_charging_16x16.png", EV_CHARGING_16X16_ASSET = "file")
load("images/fiat_logo_18x18.png", FIAT_LOGO_18X18_ASSET = "file")
load("images/green_anim.gif", GREEN_ANIM_ASSET = "file")
load("images/grid.png", GRID_ASSET = "file")
load("images/house.png", HOUSE_ASSET = "file")
load("images/hyundai_logo_24x12.png", HYUNDAI_LOGO_24X12_ASSET = "file")
load("images/opel_logo_23x18.png", OPEL_LOGO_23X18_ASSET = "file")
load("images/plug.gif", PLUG_ASSET = "file")
load("images/plug_sum.gif", PLUG_SUM_ASSET = "file")
load("images/red_anim.gif", RED_ANIM_ASSET = "file")
load("images/renault_logo_18x18.png", RENAULT_LOGO_18X18_ASSET = "file")
load("images/seat_logo_18x16.png", SEAT_LOGO_18X16_ASSET = "file")
load("images/skoda_logo_18x18.png", SKODA_LOGO_18X18_ASSET = "file")
load("images/solar.png", SOLAR_ASSET = "file")
load("images/solar_manager_logo.png", SOLAR_MANAGER_LOGO_ASSET = "file")
load("images/sun.gif", SUN_ASSET = "file")
load("images/sun_sum.png", SUN_SUM_ASSET = "file")
load("images/tesla_logo_18x18.png", TESLA_LOGO_18X18_ASSET = "file")
load("images/vw_logo_18x18.png", VW_LOGO_18X18_ASSET = "file")
load("images/yellow_anim.gif", YELLOW_ANIM_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

AUDI_LOGO_24X9 = AUDI_LOGO_24X9_ASSET.readall()
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
BATTERY_CHARGE_TEST_10X10 = BATTERY_CHARGE_TEST_10X10_ASSET.readall()
BATTERY_DISCHARGE_ANIMATION_10X10 = BATTERY_DISCHARGE_ANIMATION_10X10_ASSET.readall()
BATTERY_NOFLOW_ANIMATION_10X10 = BATTERY_NOFLOW_ANIMATION_10X10_ASSET.readall()
BMW_LOGO_18X18 = BMW_LOGO_18X18_ASSET.readall()
CUPRA_LOGO_18X18 = CUPRA_LOGO_18X18_ASSET.readall()
CUSTOM_SENSOR_16_16 = CUSTOM_SENSOR_16_16_ASSET.readall()
EMPTY = EMPTY_ASSET.readall()
EV_CHARGING_16X16 = EV_CHARGING_16X16_ASSET.readall()
FIAT_LOGO_18X18 = FIAT_LOGO_18X18_ASSET.readall()
GREEN_ANIM = GREEN_ANIM_ASSET.readall()
GRID = GRID_ASSET.readall()
HOUSE = HOUSE_ASSET.readall()
HYUNDAI_LOGO_24X12 = HYUNDAI_LOGO_24X12_ASSET.readall()
OPEL_LOGO_23X18 = OPEL_LOGO_23X18_ASSET.readall()
PLUG = PLUG_ASSET.readall()
PLUG_SUM = PLUG_SUM_ASSET.readall()
RED_ANIM = RED_ANIM_ASSET.readall()
RENAULT_LOGO_18X18 = RENAULT_LOGO_18X18_ASSET.readall()
SEAT_LOGO_18X16 = SEAT_LOGO_18X16_ASSET.readall()
SKODA_LOGO_18X18 = SKODA_LOGO_18X18_ASSET.readall()
SOLAR = SOLAR_ASSET.readall()
SOLAR_MANAGER_LOGO = SOLAR_MANAGER_LOGO_ASSET.readall()
SUN = SUN_ASSET.readall()
SUN_SUM = SUN_SUM_ASSET.readall()
TESLA_LOGO_18X18 = TESLA_LOGO_18X18_ASSET.readall()
VW_LOGO_18X18 = VW_LOGO_18X18_ASSET.readall()
YELLOW_ANIM = YELLOW_ANIM_ASSET.readall()

DEBUG = False
#DEBUG = True # set to True to skip api calls and use dummy data

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

URL_CUR = "https://cloud.solar-manager.ch/v1/stream/gateway/{}"
URL_SUM = "https://cloud.solar-manager.ch/v1/consumption/gateway/{}?period=day"
URL_AUT = "https://cloud.solar-manager.ch/v1/statistics/gateways/{}?accuracy=low&from={}&to={}"
URL_AUX = "https://cloud.solar-manager.ch/v1/consumption/sensor/{}?period={}"

# 5 minutes cache time
CACHE_TTL = 300

# combined summary and current dummy data
DUMMY_DATA = {
    "currentBatteryChargeDischarge": 50.0,
    "currentPowerConsumption": 1950.0,
    "currentPvGeneration": 0.0,
    "soc": 10,
    "consumption": 1000.96,
    "production": 3000.11,
    "has_battery": True,
    "autarky_day": 100,
    "autarky_24h": 75,
    "autarky_month": 50,
    "autarky_year": 25,
    "aux_sensor_day": 10000,
    "aux_sensor_week": 10000,
    "aux_sensor_month": 10000,
    "123456": 25,  # dummy item for EV battery soc
}

def w2kwstr(w, dec = None):  # rounds off decimal, removes completey if over 100kw
    if w == None:
        return "0"
    if w < 10000 and dec == None:
        if w < 0:  # CURRENTLY DISABLED
            return str(int(w / 1000 * 100) / 100.0)  # show two decimal places
        else:
            return str(int(w / 1000 * 10) / 10.0)  # show 1 decimal place
    elif dec == 2:
        return humanize.float("###.##", int(w / 1000 * 100) / 100.0)  # show two decimal places
    elif dec == 1:
        return str(int(w / 1000 * 10) / 10.0)  # show 1 decimal place
    else:
        return str(int(w / 1000))  # show 0 decimal places

def render_fail(rep):
    content = json.decode(rep.body())
    return render.Root(render.Box(render.WrappedText(content["error"] + " " + str(rep.status_code) + " : " + content["message"], color = RED)))

def get_aux_sensor_data(sensor_id, api_key, period):
    # 'https://cloud.solar-manager.ch/v1/consumption/sensor/62a7324c7ffb2aabdaf96b8d?period=day'
    # user 1 hour for http cache TTL
    print(URL_AUX.format(sensor_id, period))
    res = http.get(
        URL_AUX.format(sensor_id, period),
        headers = {
            "Accept": "application/json",
            "Authorization": "Basic " + api_key,
        },
        ttl_seconds = 60 * 60,  # 1 hour http cache ttl
    )
    if res.status_code != 200:
        print(res.body())
        return 0
    print(res.headers.get("Tidbyt-Cache-Status"))
    return res.json().get("totalConsumption")

def get_autarky_percent(site_id, api_key, tz, interval):
    now = time.now().in_location(tz)
    start_string = ""
    now_string = humanize.time_format("yyyy-MM-ddTHH:00", now)
    if interval == "day":  # from the start of today to now, just set time to 00:00
        start_string = humanize.time_format("yyyy-MM-ddT00:00", now)
        now_string = humanize.time_format("2006-01-02T15:04", now)
    elif interval == "24h":  # the last 24hr from now, use a now-duration
        duration = time.parse_duration("24h")
        start_time = now - duration
        start_string = humanize.time_format("yyyy-MM-ddTHH:00", start_time)
    elif interval == "month":  # from the start of the month to now, just set day to 01 and time to 00:00
        month = now.month
        if now.month < 10:  # pad a zero if less then 10
            month = "0" + str(month)
        start_string = "{}-{}-01T00:00".format(now.year, month)
    elif interval == "year":  # from the start of the year to now, set month/day to 01/01 and time to 00:00
        start_string = "{}-01-01T00:00".format(now.year)
    url = URL_AUT.format(site_id, start_string, now_string)
    print(url)
    rep = http.get(
        url,
        headers = {
            "Accept": "application/json",
            "Authorization": "Basic " + api_key,
        },
        ttl_seconds = 60 * 60,  # 1 hour cache
    )

    if rep.status_code != 200:
        print(rep.status_code)
        return 0
    print(rep.headers.get("Tidbyt-Cache-Status"))
    autarky = rep.json().get("autarchyDegree", 0)
    return int(autarky)

#######################################

def main(config):
    api_key = config.str("api_key")
    site_id = config.str("site_id")
    tz = time.tz()
    has_battery = False  #  assume no battery until we have data

    # verify api key doesn't have non key characters in there eg. "Basic"
    if api_key and "Basic" in api_key:
        b_index = api_key.find("Basic")
        api_key = api_key[b_index + 6:]
        print("corrected api_key : " + api_key)

    if not DEBUG and api_key and site_id:
        url = URL_CUR.format(site_id)
        print(url)
        data = dict()
        rep = http.get(
            url,
            headers = {
                "Accept": "application/json",
                "Authorization": "Basic " + api_key,
            },
            ttl_seconds = 300,  # 5 minutes
        )
        if rep.status_code != 200:
            print(rep.body())
            return render_fail(rep)

        cur_data = json.decode(rep.body())
        data["currentPowerConsumption"] = float(cur_data["currentPowerConsumption"])
        data["currentPvGeneration"] = float(cur_data["currentPvGeneration"])
        data["currentBatteryChargeDischarge"] = 0.0  # set to zero just to be safe
        data["soc"] = 0  # set to zero just to be safe

        if "currentBatteryChargeDischarge" in cur_data and "soc" in cur_data:
            data["currentBatteryChargeDischarge"] = float(cur_data["currentBatteryChargeDischarge"])
            data["soc"] = cur_data["soc"]
            data["has_battery"] = True
            has_battery = True

        url = URL_SUM.format(site_id)
        rep = http.get(
            url,
            headers = {
                "Accept": "application/json",
                "Authorization": "Basic " + api_key,
            },
            ttl_seconds = 60 * 60,
        )
        if rep.status_code != 200:
            return render_fail(rep)

        sum_data = json.decode(rep.body())
        data["consumption"] = sum_data["data"][0]["consumption"]
        data["production"] = sum_data["data"][0]["production"]

        if config.bool("show_autarky", False) == True:
            data["autarky_day"] = get_autarky_percent(site_id, api_key, tz, "day")
            data["autarky_24h"] = get_autarky_percent(site_id, api_key, tz, "24h")
            data["autarky_month"] = get_autarky_percent(site_id, api_key, tz, "month")
            data["autarky_year"] = get_autarky_percent(site_id, api_key, tz, "year")
        else:
            data["autarky_day"] = None  #get_autarky_percent(site_id, api_key, tz, "day")
            data["autarky_24h"] = None  #get_autarky_percent(site_id, api_key, tz, "24h")
            data["autarky_month"] = None  #= get_autarky_percent(site_id, api_key, tz, "month")
            data["autarky_year"] = None  #data["autarky_month"] #get_autarky_percent(site_id, api_key, tz, "year")

        data["aux_sensor_day"] = -1
        data["aux_sensor_week"] = -1
        data["aux_sensor_month"] = -1

        if config.get("aux_sensor_id", "") != "":
            data["aux_sensor_day"] = get_aux_sensor_data(config.get("aux_sensor_id"), api_key, "day")
            data["aux_sensor_week"] = get_aux_sensor_data(config.get("aux_sensor_id"), api_key, "week")
            data["aux_sensor_month"] = get_aux_sensor_data(config.get("aux_sensor_id"), api_key, "month")

        # look for any items in cur_data with an id and an soc value and store it for later use. eg. if we decide later to turn on ev battery frame
        for device in cur_data["devices"]:
            if "soc" in device:
                print(device)
                data[str(device["_id"])] = device["soc"]
                print(str(device["_id"]) + " " + str(device["soc"]))

    else:
        print("using dummy data")
        data = DUMMY_DATA
    print(data)
    frames = []

    if data["currentPvGeneration"] > 0:
        solar_anim = GREEN_ANIM
        solar_icon = SOLAR
        solar_value = data["currentPvGeneration"]
        solar_color = GREEN
    elif has_battery:  # only do this if we have battery data
        # change to battery data even though it's still called solar
        solar_icon = battery_level_mains[int(data["soc"] / 25)]  # will be integer 0 - 3
        solar_value = data["currentBatteryChargeDischarge"]
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
        solar_value = data["currentPvGeneration"]  # should be zero
        solar_color = GRAY

    # assuming negative chargerate means battery is discharging, and negative grid rate means pulling from grid.
    grid_rate = data["currentPvGeneration"] - (data["currentPowerConsumption"] + data["currentBatteryChargeDischarge"])
    if data["currentPvGeneration"] < 1 and grid_rate > 0:  # not possible to send energy to grid if no solar production
        grid_rate = 0.0
    if grid_rate > 9:
        grid_anim = GREEN_ANIM
        grid_color = GREEN
    elif grid_rate < -9:
        grid_anim = RED_ANIM
        grid_color = RED
    else:
        grid_anim = EMPTY
        grid_color = GRAY

    # LOGO FRAME
    #######################################
    logo_frame = render.Box(render.Image(src = SOLAR_MANAGER_LOGO))

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
                                    render.Text(w2kwstr(abs(solar_value)), color = solar_color),
                                    render.Text("kW", color = GRAY),
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
                            child =
                                render.Column(
                                    cross_align = "center",
                                    children = [
                                        render.Text(w2kwstr(data["currentPowerConsumption"])),
                                        render.Text("kW", color = GRAY),
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
                                    render.Text(w2kwstr(abs(grid_rate)), color = grid_color),
                                    render.Text("kW", color = GRAY),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

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
                                        content = " " + w2kwstr(data["production"], dec = 0) + " kWh",
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                    render.Text(
                                        content = " " + w2kwstr(data["consumption"], dec = 0) + " kWh",
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

    # CHARGE FRAME shows charge/discharge rate and state of charge percent
    #########################################################
    if data["currentBatteryChargeDischarge"] < 0:
        BATTERY_FLOW_ICON = BATTERY_DISCHARGE_ANIMATION_10X10
        flow_color = RED
    elif data["currentBatteryChargeDischarge"] > 0:
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
                                    render.Image(src = battery_level_icons[int(data["soc"] / 25)]),
                                    render.Image(src = BATTERY_FLOW_ICON),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = " " + str(data["soc"]) + " %",
                                        font = "5x8",
                                        #font = "6x13",
                                        color = soc_color[int(data["soc"] / 25)],
                                    ),
                                    render.Text(
                                        content = " " + humanize.float("#,###.", float(abs(data["currentBatteryChargeDischarge"]))) + " W",
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

    # CONSUMPTION FRAME
    verbrauch_frame = render.Box(
        render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_evenly",
            children = [
                render.Image(src = PLUG),
                render.Text(
                    #content = w2kwstr(data["currentPowerConsumption"], dec = 2) + " kW",
                    content = humanize.float("#,###.", float(data["currentPowerConsumption"])) + " W",
                    #font = "6x13",
                    font = "5x8",
                    color = RED,
                ),
            ],
        ),
    )

    # SOLAR PRODUCTION FRAME
    production_frame = render.Box(
        render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_evenly",
            children = [
                render.Image(src = SUN),
                render.Text(
                    #content = w2kwstr(data["currentPvGeneration"], dec = 2) + " kW",
                    content = humanize.float("#,###.", float(data["currentPvGeneration"])) + " W",
                    #font = "6x13",
                    font = "5x8",
                    color = GREEN,
                ),
            ],
        ),
    )

    # AUTARKY FRAME
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
                            render.Row([render.Text(" {}%".format(data["autarky_24h"]), color = GREEN)]),
                            render.Row([render.Text("{}%".format(data["autarky_month"]), color = GREEN)]),
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
                            render.Row([render.Text(" {}%".format(data["autarky_day"]), color = GREEN)]),
                            render.Row([render.Text("{}%".format(data["autarky_year"]), color = GREEN)]),
                        ],
                    ),
                ],
            ),
        ],
    )

    # AUX SENSOR FRAME
    aux_icon = CUSTOM_SENSOR_16_16
    if config.get("aux_icon") == "EV":
        aux_icon = EV_CHARGING_16X16
    sensor_frame = render.Stack(
        children = [
            render.Column(
                main_align = "space_evenly",  # this controls position of children, start = top
                expanded = True,
                cross_align = "center",
                children = [
                    render.Text(config.get("aux_sensor_label", "Aux Load"), font = "tom-thumb"),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Column(
                                expanded = True,
                                main_align = "center",
                                #cross_align = "center",
                                children = [
                                    render.Image(src = aux_icon),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(
                                        content = "D",
                                        font = "5x8",
                                        color = GRAY,
                                    ),
                                    render.Text(
                                        content = "W",
                                        font = "5x8",
                                        color = GRAY,
                                    ),
                                    render.Text(
                                        content = "M",
                                        font = "5x8",
                                        color = GRAY,
                                    ),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = w2kwstr(data["aux_sensor_day"], dec = 0),
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                    render.Text(
                                        content = w2kwstr(data["aux_sensor_week"], dec = 0),
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                    render.Text(
                                        content = w2kwstr(data["aux_sensor_month"], dec = 0),
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "start",
                                children = [
                                    render.Text(
                                        content = " kWh",
                                        font = "5x8",
                                        color = GRAY,
                                    ),
                                    render.Text(
                                        content = " kWh",
                                        font = "5x8",
                                        color = GRAY,
                                    ),
                                    render.Text(
                                        content = " kWh",
                                        font = "5x8",
                                        color = GRAY,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

    # EV battery soc frame
    ###############################################
    ev_id = config.get("ev_id", "")
    if ev_id != "" and ev_id in data:
        ev_soc = " " + str(data[ev_id]) + " %"
    else:
        ev_soc = " Not Found"
    ev_frame = render.Stack(
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
                            render.Text(config.get("ev_name", "EV")),
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
                                    render.Image(src = get_ev_logo(config.get("ev_icon"))),
                                    # render.Image(src = PLUG_SUM),
                                ],
                            ),
                            render.Column(
                                expanded = True,
                                main_align = "space_around",
                                cross_align = "end",
                                children = [
                                    render.Text(
                                        content = ev_soc,
                                        font = "5x8",
                                        color = GREEN,
                                    ),
                                    # render.Text(
                                    #     content = " " + w2kwstr(data["consumption"], dec = 0) + " kWh",
                                    #     font = "5x8",
                                    #     color = RED,
                                    # ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

    if config.bool("show_logo", False):
        frames.append(logo_frame)
    if config.bool("show_main", True):
        frames.append(main_frame)
    if config.bool("show_char", False) and has_battery:
        frames.append(charge_frame)
    if config.bool("show_prod", False):
        frames.append(production_frame)
    if config.bool("show_cons", False):
        frames.append(verbrauch_frame)
    if config.bool("show_summary", False):
        frames.append(summary_frame)
    if config.bool("show_autarky", False):
        frames.append(autarky_frame)
    if config.get("aux_sensor_id", "") != "":
        frames.append(sensor_frame)
    if config.get("ev_id", "") != "":
        frames.append(ev_frame)

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

def get_ev_logo(name):
    if name == "TESLA":
        return TESLA_LOGO_18X18
    elif name == "AUDI":
        return AUDI_LOGO_24X9
    elif name == "VW":
        return VW_LOGO_18X18
    elif name == "BMW":
        return BMW_LOGO_18X18
    elif name == "SEAT":
        return SEAT_LOGO_18X16
    elif name == "SKODA":
        return SKODA_LOGO_18X18
    elif name == "OPEL":
        return OPEL_LOGO_23X18
    elif name == "RENAULT":
        return RENAULT_LOGO_18X18
    elif name == "HYUNDAI":
        return HYUNDAI_LOGO_24X12
    elif name == "CUPRA":
        return CUPRA_LOGO_18X18
    elif name == "FIAT":
        return FIAT_LOGO_18X18
    else:
        return BMW_LOGO_18X18

def format_power(p):
    if p:
        return humanize.float("#,###.##", p)
    else:
        return "0"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "API key for the SolarManager monitoring API. Authorize with your solarmanager username and password on: https://external-web.solar-manager.ch/swagger and copy the long string that follows after '-H authorization: Basic'",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "site_id",
                name = "Site ID",
                desc = "Your site ID. Check the back of your solarmanager device for the SMID code.",
                icon = "hashtag",
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
                id = "show_logo",
                name = "Show Logo Frame",
                desc = "Solar Manager Logo",
                icon = "compress",
                default = False,
            ),
            schema.Toggle(
                id = "show_autarky",
                name = "Show Autarky Frame",
                desc = "Display the 4 Autarky values for day,week,month,year",
                icon = "compress",
                default = False,
            ),
            schema.Text(
                id = "aux_sensor_id",
                name = "Aux Sensor ID",
                desc = "Aux Senso ID",
                icon = "hashtag",
                default = "",
            ),
            schema.Text(
                id = "aux_sensor_label",
                name = "Aux Sensor Label",
                desc = "Aux Senso Label",
                icon = "hashtag",
                default = "",
            ),
            schema.Dropdown(
                id = "aux_icon",
                name = "Aux Icon",
                desc = "Icon Selection",
                icon = "hashtag",
                default = "EV",
                options = [
                    schema.Option(
                        display = "EV",
                        value = "EV",
                    ),
                    schema.Option(
                        display = "Generic",
                        value = "Generic",
                    ),
                ],
            ),
            schema.Text(
                id = "ev_id",
                name = "EV Battery ID",
                desc = "EV Battery ID",
                icon = "hashtag",
                default = "",
            ),
            schema.Text(
                id = "ev_name",
                name = "EV Name",
                desc = "EV Name",
                icon = "hashtag",
                default = "",
            ),
            schema.Dropdown(
                id = "ev_icon",
                name = "EV Brand",
                desc = "Logo Selection",
                icon = "hashtag",
                default = TESLA_LOGO_18X18,
                options = [
                    schema.Option(
                        display = "VW",
                        value = "VW",
                    ),
                    schema.Option(
                        display = "Tesla",
                        value = "TESLA",
                    ),
                    schema.Option(
                        display = "Audi",
                        value = "AUDI",
                    ),
                    schema.Option(
                        display = "BMW",
                        value = "BMW",
                    ),
                    schema.Option(
                        display = "Seat",
                        value = "SEAT",
                    ),
                    schema.Option(
                        display = "Skoda",
                        value = "SKODA",
                    ),
                    schema.Option(
                        display = "Opel",
                        value = "OPEL",
                    ),
                    schema.Option(
                        display = "Renault",
                        value = "RENAULT",
                    ),
                    schema.Option(
                        display = "Hyundai",
                        value = "HYUNDAI",
                    ),
                    schema.Option(
                        display = "Cupra",
                        value = "CUPRA",
                    ),
                    schema.Option(
                        display = "FIAT",
                        value = "FIAT",
                    ),
                ],
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
