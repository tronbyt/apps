"""
Applet: HASS Solar
Summary: Home Assistant PV monitor
Description: Energy production and consumption monitor using Home Assistant.
Author: ingmarstein
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("i18n.star", "tr")
load("images/audi_logo.png", AUDI_LOGO_24x9 = "file")
load("images/audi_logo@2x.png", AUDI_LOGO_24x9_2X = "file")
load("images/autarky.png", AUTARKY_16x16 = "file")
load("images/autarky@2x.png", AUTARKY_16x16_2X = "file")
load("images/battery_0_25_main_screen.png", BATTERY_0_TO_25_MAIN_SCREEN = "file")
load("images/battery_0_25_main_screen@2x.png", BATTERY_0_TO_25_MAIN_SCREEN_2X = "file")
load("images/battery_25_50_main_screen.png", BATTERY_25_TO_50_MAIN_SCREEN = "file")
load("images/battery_25_50_main_screen@2x.png", BATTERY_25_TO_50_MAIN_SCREEN_2X = "file")
load("images/battery_50_75_main_screen.png", BATTERY_50_TO_75_MAIN_SCREEN = "file")
load("images/battery_50_75_main_screen@2x.png", BATTERY_50_TO_75_MAIN_SCREEN_2X = "file")
load("images/battery_75_100_main_screen.png", BATTERY_75_TO_100_MAIN_SCREEN = "file")
load("images/battery_75_100_main_screen@2x.png", BATTERY_75_TO_100_MAIN_SCREEN_2X = "file")
load("images/battery_charge_animation.gif", BATTERY_CHARGE_ANIMATION_10x10 = "file")
load("images/battery_charge_animation@2x.gif", BATTERY_CHARGE_ANIMATION_10x10_2X = "file")
load("images/battery_charge_status_0_25.gif", BATTERY_CHARGE_STATUS_0_25_10x10 = "file")
load("images/battery_charge_status_0_25@2x.gif", BATTERY_CHARGE_STATUS_0_25_10x10_2X = "file")
load("images/battery_charge_status_25_50.gif", BATTERY_CHARGE_STATUS_25_50_10x10 = "file")
load("images/battery_charge_status_25_50@2x.gif", BATTERY_CHARGE_STATUS_25_50_10x10_2X = "file")
load("images/battery_charge_status_50_75.gif", BATTERY_CHARGE_STATUS_50_75_10x10 = "file")
load("images/battery_charge_status_50_75@2x.gif", BATTERY_CHARGE_STATUS_50_75_10x10_2X = "file")
load("images/battery_charge_status_75_100.gif", BATTERY_CHARGE_STATUS_75_100_10x10 = "file")
load("images/battery_charge_status_75_100@2x.gif", BATTERY_CHARGE_STATUS_75_100_10x10_2X = "file")
load("images/battery_discharge_animation.gif", BATTERY_DISCHARGE_ANIMATION_10x10 = "file")
load("images/battery_discharge_animation@2x.gif", BATTERY_DISCHARGE_ANIMATION_10x10_2X = "file")
load("images/battery_noflow_animation.gif", BATTERY_NOFLOW_ANIMATION_10x10 = "file")
load("images/battery_noflow_animation@2x.gif", BATTERY_NOFLOW_ANIMATION_10x10_2X = "file")
load("images/bmw_logo.png", BMW_LOGO_18x18 = "file")
load("images/bmw_logo@2x.png", BMW_LOGO_18x18_2X = "file")
load("images/cupra_logo.png", CUPRA_LOGO_18x18 = "file")
load("images/cupra_logo@2x.png", CUPRA_LOGO_18x18_2X = "file")

# 7x16
load("images/empty.png", EMPTY = "file")
load("images/empty@2x.png", EMPTY_2X = "file")
load("images/ev_charging.png", EV_CHARGING_16x16 = "file")
load("images/ev_charging@2x.png", EV_CHARGING_16x16_2X = "file")
load("images/fiat_logo.png", FIAT_LOGO_18x18 = "file")
load("images/fiat_logo@2x.png", FIAT_LOGO_18x18_2X = "file")

# 7x16
load("images/green_anim.gif", GREEN_ANIM = "file")
load("images/green_anim@2x.gif", GREEN_ANIM_2X = "file")

# 12x16
load("images/grid.png", GRID = "file")
load("images/grid@2x.png", GRID_2X = "file")

# 16x16
load("images/house.png", HOUSE = "file")
load("images/house@2x.png", HOUSE_2X = "file")
load("images/hyundai_logo.png", HYUNDAI_LOGO_24x12 = "file")
load("images/hyundai_logo@2x.png", HYUNDAI_LOGO_24x12_2X = "file")
load("images/opel_logo.png", OPEL_LOGO_23x18 = "file")
load("images/opel_logo@2x.png", OPEL_LOGO_23x18_2X = "file")

# 16x16
load("images/plug.gif", PLUG = "file")
load("images/plug@2x.gif", PLUG_2X = "file")

# 10x10
load("images/plug_sum.gif", PLUG_SUM = "file")
load("images/plug_sum@2x.gif", PLUG_SUM_2X = "file")
load("images/red_anim.gif", RED_ANIM = "file")
load("images/red_anim@2x.gif", RED_ANIM_2X = "file")
load("images/renault_logo.png", RENAULT_LOGO_18x18 = "file")
load("images/renault_logo@2x.png", RENAULT_LOGO_18x18_2X = "file")
load("images/seat_logo.png", SEAT_LOGO_18x16 = "file")
load("images/seat_logo@2x.png", SEAT_LOGO_18x16_2X = "file")
load("images/skoda_logo.png", SKODA_LOGO_18x18 = "file")
load("images/skoda_logo@2x.png", SKODA_LOGO_18x18_2X = "file")

# 16x16
load("images/solar.png", SOLAR = "file")
load("images/solar@2x.png", SOLAR_2X = "file")

# 16x16
load("images/sun.gif", SUN = "file")
load("images/sun@2x.gif", SUN_2X = "file")

# 10x10
load("images/sun_sum.png", SUN_SUM = "file")
load("images/sun_sum@2x.png", SUN_SUM_2X = "file")
load("images/tesla_logo.png", TESLA_LOGO_18x18 = "file")
load("images/tesla_logo@2x.png", TESLA_LOGO_18x18_2X = "file")
load("images/vw_logo.png", VW_LOGO_18x18 = "file")
load("images/vw_logo@2x.png", VW_LOGO_18x18_2X = "file")
load("images/yellow_anim.gif", YELLOW_ANIM = "file")
load("images/yellow_anim@2x.gif", YELLOW_ANIM_2X = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

CACHE_TTL = 10

DEBUG = False
#DEBUG = True # set to True to skip api calls and use dummy data

HA_URL = "ha_url"
HA_TOKEN = "ha_token"

ENTITY_ENERGY_PRODUCTION = "entity_energy_production"
ENTITY_ENERGY_CONSUMPTION = "entity_energy_consumption"
ENTITY_ENERGY_EV_DAY = "entity_energy_ev_day"
ENTITY_ENERGY_EV_WEEK = "entity_energy_ev_week"
ENTITY_ENERGY_EV_MONTH = "entity_energy_ev_month"
ENTITY_POWER_SOLAR = "entity_power_solar"
ENTITY_POWER_GRID = "entity_power_grid"
ENTITY_POWER_LOAD = "entity_power_load"
ENTITY_POWER_BATTERY = "entity_power_battery"
ENTITY_SOC_BATTERY = "entity_soc_battery"
ENTITY_SOC_EV = "entity_soc_ev"
ENTITY_AUTARKY_DAY = "entity_autarky_day"
ENTITY_AUTARKY_WEEK = "entity_autarky_week"
ENTITY_AUTARKY_MONTH = "entity_autarky_month"
ENTITY_AUTARKY_YEAR = "entity_autarky_year"

ENTITY_UNITS = {
    ENTITY_ENERGY_CONSUMPTION: "kWh",
    ENTITY_ENERGY_PRODUCTION: "kWh",
    ENTITY_ENERGY_EV_DAY: "kWh",
    ENTITY_ENERGY_EV_WEEK: "kWh",
    ENTITY_ENERGY_EV_MONTH: "kWh",
    ENTITY_POWER_SOLAR: "W",
    ENTITY_POWER_GRID: "W",
    ENTITY_POWER_LOAD: "W",
    ENTITY_POWER_BATTERY: "W",
    ENTITY_SOC_BATTERY: "%",
    ENTITY_SOC_EV: "%",
    ENTITY_AUTARKY_DAY: "%",
    ENTITY_AUTARKY_WEEK: "%",
    ENTITY_AUTARKY_MONTH: "%",
    ENTITY_AUTARKY_YEAR: "%",
}

GRAY = "#777777"
RED = "#AA0000"  # very bright at FF, dim a little to AA
GREEN = "#00FF00"
ORANGE = "#FFA500"
YELLOW = "#FFFF00"
WHITE = "#FFFFFF"

# need 5 items because 100% is index 4
battery_level_icons = [BATTERY_CHARGE_STATUS_0_25_10x10, BATTERY_CHARGE_STATUS_25_50_10x10, BATTERY_CHARGE_STATUS_50_75_10x10, BATTERY_CHARGE_STATUS_75_100_10x10, BATTERY_CHARGE_STATUS_75_100_10x10]
battery_level_mains = [BATTERY_0_TO_25_MAIN_SCREEN, BATTERY_25_TO_50_MAIN_SCREEN, BATTERY_50_TO_75_MAIN_SCREEN, BATTERY_75_TO_100_MAIN_SCREEN, BATTERY_75_TO_100_MAIN_SCREEN]
soc_color = [RED, ORANGE, YELLOW, GREEN, GREEN]

battery_level_icons_2x = [BATTERY_CHARGE_STATUS_0_25_10x10_2X, BATTERY_CHARGE_STATUS_25_50_10x10_2X, BATTERY_CHARGE_STATUS_50_75_10x10_2X, BATTERY_CHARGE_STATUS_75_100_10x10_2X, BATTERY_CHARGE_STATUS_75_100_10x10_2X]
battery_level_mains_2x = [BATTERY_0_TO_25_MAIN_SCREEN_2X, BATTERY_25_TO_50_MAIN_SCREEN_2X, BATTERY_50_TO_75_MAIN_SCREEN_2X, BATTERY_75_TO_100_MAIN_SCREEN_2X, BATTERY_75_TO_100_MAIN_SCREEN_2X]

def render_fail(rep):
    content = json.decode(rep.body())
    return render.Root(render.Box(render.WrappedText(str(rep.status_code) + " : " + content["String"], color = RED)))

def dummy_entity(entity_id):
    if entity_id.startswith("entity_energy"):
        return {
            "entity_id": "{}".format(entity_id),
            "state": "130.12",
            "attributes": {
                "state_class": "total_increasing",
                "unit_of_measurement": "kWh",
                "device_class": "energy",
            },
        }
    elif entity_id.startswith("entity_soc"):
        return {
            "entity_id": "{}".format(entity_id),
            "state": "80",
            "attributes": {
                "raw_soc": 80,
                "state_class": "measurement",
                "unit_of_measurement": "%",
                "device_class": "energy",
            },
        }
    elif entity_id.startswith("entity_autarky"):
        return {
            "entity_id": "{}".format(entity_id),
            "state": "97",
            "attributes": {
                "state_class": "measurement",
                "unit_of_measurement": "%",
            },
        }
    else:
        return {
            "entity_id": "{}".format(entity_id),
            "state": "9886.0",
            "attributes": {
                "state_class": "measurement",
                "unit_of_measurement": "W",
                "device_class": "power",
            },
        }

def fetch_all_entities(config):
    entity_keys = ENTITY_UNITS.keys()
    raw_values = config.bool("raw_values", False)

    if DEBUG or (config.get(HA_URL) == None and not raw_values):
        results = {}
        for key in entity_keys:
            results[key] = dummy_entity(key)
        return results

    if raw_values:
        results = {}
        for key in entity_keys:
            entity_id = config.get(key)
            if entity_id:
                results[key] = {
                    "state": "{}".format(entity_id),
                    "attributes": {
                        "unit_of_measurement": ENTITY_UNITS.get(key),
                    },
                }
            else:
                results[key] = None
        return results

    template_parts = []
    active_keys = []

    for key in entity_keys:
        entity_id = config.get(key)
        if entity_id:
            active_keys.append(key)
            part = '"%s": {"state": {{ states("%s") | tojson }}, "attributes": {"unit_of_measurement": {{ state_attr("%s", "unit_of_measurement") | tojson }} }}' % (key, entity_id, entity_id)
            template_parts.append(part)

    if not active_keys:
        return {}

    template = "{%s}" % ",".join(template_parts)

    url = config.get(HA_URL)
    if url.endswith("/"):
        url = url[:-1]

    rep = http.post(
        url + "/api/template",
        headers = {
            "Authorization": "Bearer " + config.get(HA_TOKEN),
            "Content-Type": "application/json",
        },
        json_body = {"template": template},
        ttl_seconds = CACHE_TTL,
    )

    if rep.status_code != 200:
        fail("Template request failed with status %d: %s" % (rep.status_code, rep.body()))

    data = rep.json()

    results = {}
    for key in entity_keys:
        results[key] = data.get(key)

    return results

def unit_for_entity(entity):
    if "attributes" in entity and "unit_of_measurement" in entity["attributes"]:
        return entity["attributes"]["unit_of_measurement"]
    return None

def render_entity(entity, absolute_value = False, convert_to_kw = False, with_unit = True, dec = None):
    if not entity:
        return ""

    state = entity["state"]
    if not state or state == "unknown" or state == "unavailable":
        return ""

    value = float(state)

    unit = unit_for_entity(entity)
    if unit == "W" and convert_to_kw:
        unit = "kW"
        value = value / 1000.0

    if absolute_value or unit == "%" or unit == "kWh":
        value = abs(value)

    if dec == None:
        if value < 9.95:
            value_str = humanize.float("#,###.#", value)
        else:
            value_str = humanize.float("#,###.", value)
    elif dec == 2:
        value_str = humanize.float("#,###.##", value)
    elif dec == 1:
        value_str = humanize.float("#,###.#", value)
    elif dec == 0:
        value_str = humanize.float("#,###.", value)
    else:
        value_str = "0"

    if with_unit and unit:
        if unit == "%":
            return value_str + unit
        return value_str + " " + unit

    return value_str

def main(config):
    scale = 2 if canvas.is2x() else 1

    # Scaled fonts and images
    if scale == 2:
        font_default = "terminus-16"
        font_medium = "terminus-16"
        font_small = "terminus-12"
        autarky_img = AUTARKY_16x16_2X
        battery_charge_anim = BATTERY_CHARGE_ANIMATION_10x10_2X
        battery_discharge_anim = BATTERY_DISCHARGE_ANIMATION_10x10_2X
        battery_noflow_anim = BATTERY_NOFLOW_ANIMATION_10x10_2X
        empty_anim = EMPTY_2X
        ev_charging_img = EV_CHARGING_16x16_2X
        green_anim_img = GREEN_ANIM_2X
        grid_img = GRID_2X
        house_img = HOUSE_2X
        plug_img = PLUG_2X
        plug_sum_img = PLUG_SUM_2X
        red_anim_img = RED_ANIM_2X
        solar_img = SOLAR_2X
        sun_img = SUN_2X
        sun_sum_img = SUN_SUM_2X
        yellow_anim_img = YELLOW_ANIM_2X
        battery_icons_list = battery_level_icons_2x
        battery_mains_list = battery_level_mains_2x
    else:
        font_default = "tb-8"
        font_medium = "5x8"
        font_small = "tom-thumb"  # 4x6
        autarky_img = AUTARKY_16x16
        battery_charge_anim = BATTERY_CHARGE_ANIMATION_10x10
        battery_discharge_anim = BATTERY_DISCHARGE_ANIMATION_10x10
        battery_noflow_anim = BATTERY_NOFLOW_ANIMATION_10x10
        empty_anim = EMPTY
        ev_charging_img = EV_CHARGING_16x16
        green_anim_img = GREEN_ANIM
        grid_img = GRID
        house_img = HOUSE
        plug_img = PLUG
        plug_sum_img = PLUG_SUM
        red_anim_img = RED_ANIM
        solar_img = SOLAR
        sun_img = SUN
        sun_sum_img = SUN_SUM
        yellow_anim_img = YELLOW_ANIM
        battery_icons_list = battery_level_icons
        battery_mains_list = battery_level_mains

    # fetch data from HA
    entities = fetch_all_entities(config)

    energy_consumption = entities.get(ENTITY_ENERGY_CONSUMPTION)
    energy_production = entities.get(ENTITY_ENERGY_PRODUCTION)
    energy_ev_day = entities.get(ENTITY_ENERGY_EV_DAY)
    energy_ev_week = entities.get(ENTITY_ENERGY_EV_WEEK)
    energy_ev_month = entities.get(ENTITY_ENERGY_EV_MONTH)
    power_solar = entities.get(ENTITY_POWER_SOLAR)
    power_grid = entities.get(ENTITY_POWER_GRID)
    power_load = entities.get(ENTITY_POWER_LOAD)
    power_battery = entities.get(ENTITY_POWER_BATTERY)
    soc_battery = entities.get(ENTITY_SOC_BATTERY)
    soc_ev = entities.get(ENTITY_SOC_EV)
    autarky_day = entities.get(ENTITY_AUTARKY_DAY)
    autarky_week = entities.get(ENTITY_AUTARKY_WEEK)
    autarky_month = entities.get(ENTITY_AUTARKY_MONTH)
    autarky_year = entities.get(ENTITY_AUTARKY_YEAR)

    frames = []

    if power_solar and float(power_solar["state"]) > 0:
        solar_anim = green_anim_img
        solar_icon = solar_img
        solar_value = power_solar
        solar_color = GREEN

    elif soc_battery and soc_battery["state"] != "unknown" and soc_battery["state"] != "unavailable":
        # only do this if we have battery data
        solar_icon = battery_mains_list[int(float(soc_battery["state"]) / 25)]  # will be integer 0 - 3
        solar_value = power_battery
        if int(float(solar_value["state"])) == 0:
            solar_anim = empty_anim
            solar_color = GRAY
        elif float(solar_value["state"]) > 0:
            solar_anim = red_anim_img
            solar_color = WHITE
        else:
            solar_anim = yellow_anim_img
            solar_color = WHITE
    else:
        solar_anim = empty_anim
        solar_icon = solar_img
        solar_value = power_solar  # should be zero
        solar_color = GRAY

    if power_grid and float(power_grid["state"]) > 9:
        grid_anim = green_anim_img
        grid_color = GREEN
    elif power_grid and float(power_grid["state"]) < -9:
        grid_anim = red_anim_img
        grid_color = RED
    else:
        grid_anim = empty_anim
        grid_color = GRAY

    # MAIN FRAME
    #######################################
    main_frame = render.Row(
        children = [
            render.Box(
                height = canvas.height(),
                width = 16 * scale,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = solar_icon.readall(), width = 16 * scale, height = 16 * scale),
                        render.Padding(
                            pad = (1 * scale, 0, 0, 0),
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(render_entity(solar_value, absolute_value = True, convert_to_kw = True, with_unit = False), color = solar_color, font = font_default),
                                    render.Text("kW", color = GRAY, font = font_default),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            render.Box(
                height = canvas.height(),
                width = 9 * scale,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "start",
                    children = [
                        render.Image(src = solar_anim.readall(), width = 7 * scale, height = 16 * scale),
                    ],
                ),
            ),
            render.Box(
                height = canvas.height(),
                width = 16 * scale,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = house_img.readall(), width = 16 * scale, height = 16 * scale),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(render_entity(power_load, convert_to_kw = True, with_unit = False), font = font_default),
                                    render.Text("kW", color = GRAY, font = font_default),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
            render.Box(
                height = canvas.height(),
                width = 9 * scale,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "start",
                    children = [
                        render.Image(src = grid_anim.readall(), width = 7 * scale, height = 16 * scale),
                    ],
                ),
            ),
            render.Box(
                height = canvas.height(),
                width = 14 * scale,
                child = render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Image(src = grid_img.readall(), width = 12 * scale, height = 16 * scale),
                        render.Padding(
                            pad = (0, 0, 0, 0),
                            child = render.Column(
                                cross_align = "center",
                                children = [
                                    render.Text(render_entity(power_grid, absolute_value = True, convert_to_kw = True, with_unit = False), color = grid_color, font = font_default),
                                    render.Text("kW", color = GRAY, font = font_default),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        ],
    )

    if config.bool("$widget"):
        return render.Root(main_frame)

    if config.bool("show_main", True):
        frames.append(main_frame)

    # CHARGE FRAME shows charge/discharge rate and state of charge percent
    #########################################################
    if config.bool("show_char", False) and power_battery and soc_battery:
        battery_icon_index = 0
        if soc_battery["state"] != "unknown" and soc_battery["state"] != "unavailable":
            battery_icon_index = int(float(soc_battery["state"]) / 25)

        power_state = power_battery["state"]
        if power_state == "unknown" or power_state == "unavailable" or float(power_state) == 0:
            BATTERY_FLOW_ICON = battery_noflow_anim
            flow_color = GRAY
        elif float(power_state) < 0:
            BATTERY_FLOW_ICON = battery_discharge_anim
            flow_color = RED
        else:
            BATTERY_FLOW_ICON = battery_charge_anim
            flow_color = GREEN

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
                                render.Text(" ", height = 1, font = font_default),  # spacer to align with other frames
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
                                        render.Image(src = battery_icons_list[battery_icon_index].readall()),
                                        render.Image(src = BATTERY_FLOW_ICON.readall()),
                                    ],
                                ),
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "end",
                                    children = [
                                        render.Text(
                                            content = " " + render_entity(soc_battery, dec = 0),
                                            font = font_medium,
                                            #font = "6x13",
                                            color = soc_color[battery_icon_index],
                                        ),
                                        render.Text(
                                            content = " " + render_entity(power_battery, dec = 0),
                                            font = font_medium,
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
                    render.Image(src = sun_img.readall(), width = 16 * scale, height = 16 * scale),
                    render.Text(
                        content = render_entity(power_solar),
                        font = font_medium,
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
                    render.Image(src = plug_img.readall(), width = 16 * scale, height = 16 * scale),
                    render.Text(
                        content = render_entity(power_load),
                        #font = "6x13",
                        font = font_medium,
                        color = RED,
                    ),
                ],
            ),
        )
        frames.append(consumption_frame)

    if energy_production and energy_consumption:
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
                                render.Text(tr("Energy Today"), font = font_default),
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
                                        render.Image(src = sun_sum_img.readall(), width = 10 * scale, height = 10 * scale),
                                        render.Image(src = plug_sum_img.readall(), width = 10 * scale, height = 10 * scale),
                                    ],
                                ),
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "end",
                                    children = [
                                        render.Text(
                                            content = " " + render_entity(energy_production),
                                            font = font_medium,
                                            color = GREEN,
                                        ),
                                        render.Text(
                                            content = " " + render_entity(energy_consumption),
                                            font = font_medium,
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
    if autarky_day and autarky_week and autarky_month and autarky_year:
        autarky_frame = render.Stack(
            children = [
                render.Box(
                    height = canvas.height(),
                    width = canvas.width(),
                    child = render.Image(src = autarky_img.readall(), width = 16 * scale, height = 16 * scale),
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
                                render.Row([render.Text(tr("Today:"), font = font_small, color = GRAY)]),
                                render.Row([render.Text(tr("Month:"), font = font_small, color = GRAY)]),
                            ],
                        ),

                        # second row
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Row([render.Text(" " + render_entity(autarky_day, dec = 0), color = GREEN, font = font_default)]),
                                render.Row([render.Text(render_entity(autarky_month, dec = 0), color = GREEN, font = font_default)]),
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
                                render.Row([render.Text(tr("Week:"), font = font_small, color = GRAY)]),
                                render.Row([render.Text(tr("Year:"), font = font_small, color = GRAY)]),
                            ],
                        ),

                        # fourth row
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "end",
                            children = [
                                render.Row([render.Text(" " + render_entity(autarky_week, dec = 0), color = GREEN, font = font_default)]),
                                render.Row([render.Text(render_entity(autarky_year, dec = 0), color = GREEN, font = font_default)]),
                            ],
                        ),
                    ],
                ),
            ],
        )
        frames.append(autarky_frame)

    # EV CHARGING FRAME
    if energy_ev_day and energy_ev_week and energy_ev_month:
        ev_energy_frame = render.Stack(
            children = [
                render.Column(
                    main_align = "space_evenly",  # this controls position of children, start = top
                    expanded = True,
                    cross_align = "center",
                    children = [
                        render.Text(tr("EV Energy"), font = font_small),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Column(
                                    expanded = True,
                                    main_align = "center",
                                    #cross_align = "center",
                                    children = [
                                        render.Image(src = ev_charging_img.readall(), width = 16 * scale, height = 16 * scale),
                                    ],
                                ),
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "start",
                                    children = [
                                        render.Text(
                                            content = tr("D"),
                                            font = font_medium,
                                            color = GRAY,
                                        ),
                                        render.Text(
                                            content = tr("W"),
                                            font = font_medium,
                                            color = GRAY,
                                        ),
                                        render.Text(
                                            content = tr("M"),
                                            font = font_medium,
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
                                            content = render_entity(energy_ev_day, with_unit = False, dec = 0),
                                            font = font_medium,
                                            color = GREEN,
                                        ),
                                        render.Text(
                                            content = render_entity(energy_ev_week, with_unit = False, dec = 0),
                                            font = font_medium,
                                            color = GREEN,
                                        ),
                                        render.Text(
                                            content = render_entity(energy_ev_month, with_unit = False, dec = 0),
                                            font = font_medium,
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
                                            font = font_medium,
                                            color = GRAY,
                                        ),
                                        render.Text(
                                            content = " kWh",
                                            font = font_medium,
                                            color = GRAY,
                                        ),
                                        render.Text(
                                            content = " kWh",
                                            font = font_medium,
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
        frames.append(ev_energy_frame)

    # EV battery soc frame
    ###############################################
    if soc_ev:
        ev_brand = config.get("ev_icon", "TESLA")
        ev_logo = EV_LOGOS.get(ev_brand, EV_LOGOS["TESLA"])
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
                                render.Text(config.get("ev_name", "EV"), font = font_default),
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
                                        render.Image(src = (ev_logo["logo_2x"] if scale == 2 else ev_logo["logo"]).readall(), width = ev_logo["width"] * scale, height = ev_logo["height"] * scale),
                                        # render.Image(src = PLUG_SUM.readall()),
                                    ],
                                ),
                                render.Column(
                                    expanded = True,
                                    main_align = "space_around",
                                    cross_align = "end",
                                    children = [
                                        render.Text(
                                            content = render_entity(soc_ev),
                                            font = font_medium,
                                            color = GREEN,
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
            ],
        )
        frames.append(ev_frame)

    if len(frames) == 1:
        return render.Root(frames[0])
    elif len(frames) == 0:
        return render.Root(main_frame)
    else:
        return render.Root(
            show_full_animation = True,
            delay = int(config.get("frame_delay", "3")) * 1000,
            child = render.Animation(children = frames),
        )

EV_LOGOS = {
    "TESLA": {
        "logo": TESLA_LOGO_18x18,
        "logo_2x": TESLA_LOGO_18x18_2X,
        "width": 18,
        "height": 18,
    },
    "AUDI": {
        "logo": AUDI_LOGO_24x9,
        "logo_2x": AUDI_LOGO_24x9_2X,
        "width": 24,
        "height": 9,
    },
    "VW": {
        "logo": VW_LOGO_18x18,
        "logo_2x": VW_LOGO_18x18_2X,
        "width": 18,
        "height": 18,
    },
    "BMW": {
        "logo": BMW_LOGO_18x18,
        "logo_2x": BMW_LOGO_18x18_2X,
        "width": 18,
        "height": 18,
    },
    "SEAT": {
        "logo": SEAT_LOGO_18x16,
        "logo_2x": SEAT_LOGO_18x16_2X,
        "width": 18,
        "height": 16,
    },
    "SKODA": {
        "logo": SKODA_LOGO_18x18,
        "logo_2x": SKODA_LOGO_18x18_2X,
        "width": 18,
        "height": 18,
    },
    "OPEL": {
        "logo": OPEL_LOGO_23x18,
        "logo_2x": OPEL_LOGO_23x18_2X,
        "width": 23,
        "height": 18,
    },
    "RENAULT": {
        "logo": RENAULT_LOGO_18x18,
        "logo_2x": RENAULT_LOGO_18x18_2X,
        "width": 18,
        "height": 18,
    },
    "HYUNDAI": {
        "logo": HYUNDAI_LOGO_24x12,
        "logo_2x": HYUNDAI_LOGO_24x12_2X,
        "width": 24,
        "height": 12,
    },
    "CUPRA": {
        "logo": CUPRA_LOGO_18x18,
        "logo_2x": CUPRA_LOGO_18x18_2X,
        "width": 18,
        "height": 18,
    },
    "FIAT": {
        "logo": FIAT_LOGO_18x18,
        "logo_2x": FIAT_LOGO_18x18_2X,
        "width": 18,
        "height": 18,
    },
}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = HA_URL,
                name = "Home Assistant URL",
                desc = "The address of your HomeAssistant instance, as a full URL.",
                icon = "book",
            ),
            schema.Text(
                id = HA_TOKEN,
                name = "HomeAssistant Token",
                desc = "Find in User Settings > Long-lived access tokens.",
                icon = "book",
                secret = True,
            ),
            schema.Text(
                id = ENTITY_ENERGY_PRODUCTION,
                name = "Energy production today",
                desc = "Entity ID (e.g. sensor.energy_production)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_ENERGY_CONSUMPTION,
                name = "Energy consumption today",
                desc = "Entity ID (e.g. sensor.energy_consumption)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_POWER_SOLAR,
                name = "Current solar power",
                desc = "Entity ID (e.g. sensor.power_solar)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_POWER_GRID,
                name = "Current grid power (positive = export, negative = import)",
                desc = "Entity ID (e.g. sensor.solaredge_m1_ac_power)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_POWER_LOAD,
                name = "Current load power (consumption)",
                desc = "Entity ID (e.g. sensor.power_consumption)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_POWER_BATTERY,
                name = "Current battery power (positive = charging)",
                desc = "Entity ID (e.g. sensor.power_battery)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_SOC_BATTERY,
                name = "Current battery state of charge (charging level)",
                desc = "Entity ID (e.g. sensor.solaredge_b1_state_of_energy)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_SOC_EV,
                name = "Current EV state of charge",
                desc = "Entity ID (e.g. sensor.tesla_battery)",
                icon = "carBattery",
            ),
            schema.Text(
                id = ENTITY_ENERGY_EV_DAY,
                name = "Energy used for charging today",
                desc = "Entity ID (e.g. sensor.energy_ev_today)",
                icon = "carBattery",
            ),
            schema.Text(
                id = ENTITY_ENERGY_EV_WEEK,
                name = "Energy used for charging this week",
                desc = "Entity ID (e.g. sensor.energy_ev_week)",
                icon = "carBattery",
            ),
            schema.Text(
                id = ENTITY_ENERGY_EV_MONTH,
                name = "Energy used for charging this month",
                desc = "Entity ID (e.g. sensor.energy_ev_month)",
                icon = "carBattery",
            ),
            schema.Text(
                id = ENTITY_AUTARKY_DAY,
                name = "Autarky ratio today",
                desc = "Entity ID (e.g. sensor.steps)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_AUTARKY_WEEK,
                name = "Autarky ratio in the current week",
                desc = "Entity ID (e.g. sensor.steps)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_AUTARKY_MONTH,
                name = "Autarky ratio in the current month",
                desc = "Entity ID (e.g. sensor.steps)",
                icon = "1",
            ),
            schema.Text(
                id = ENTITY_AUTARKY_YEAR,
                name = "Autarky ratio in the current year",
                desc = "Entity ID (e.g. sensor.steps)",
                icon = "1",
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
                default = "TESLA",
                options = [
                    schema.Option(
                        display = "Audi",
                        value = "AUDI",
                    ),
                    schema.Option(
                        display = "BMW",
                        value = "BMW",
                    ),
                    schema.Option(
                        display = "Cupra",
                        value = "CUPRA",
                    ),
                    schema.Option(
                        display = "FIAT",
                        value = "FIAT",
                    ),
                    schema.Option(
                        display = "Hyundai",
                        value = "HYUNDAI",
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
                        display = "Seat",
                        value = "SEAT",
                    ),
                    schema.Option(
                        display = "Skoda",
                        value = "SKODA",
                    ),
                    schema.Option(
                        display = "VW",
                        value = "VW",
                    ),
                    schema.Option(
                        display = "Tesla",
                        value = "TESLA",
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
            schema.Toggle(
                id = "raw_values",
                name = "Entity IDs as raw values",
                desc = "Don't call the HA API and use entity IDs as raw values.",
                icon = "globe",
                default = False,
            ),
        ],
    )
