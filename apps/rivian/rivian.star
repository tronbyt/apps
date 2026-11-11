"""
Applet: Rivian
Summary: Rivian charge, range & lock
Description: Shows your Rivian's state of charge, range, charge limit, charging status and lock state, read from the Rivian (Unofficial) Home Assistant integration through the Home Assistant REST API.
Author: John Abella
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

CACHE_TTL = 60

# Entity ID suffixes created by the Rivian (Unofficial) integration
# (github.com/bretterer/home-assistant-rivian). Full ID = <domain>.<vehicle>_<suffix>.
SUFFIX = {
    "soc": "sensor.%s_battery_state_of_charge",
    "range": "sensor.%s_estimated_vehicle_range",
    "charger": "sensor.%s_charger_state",
    "limit": "sensor.%s_battery_state_of_charge_limit",
    "plug": "binary_sensor.%s_charger_connection",
    "power": "sensor.%s_charging_speed",
    "lock": "lock.%s_closures",
}

# charger_state values the integration treats as actively charging
ACTIVE_STATES = ["charging_active", "charging_connecting", "smart_charging_active"]

# ---- colors ----
C_TITLE = "#FFB000"
C_DIM = "#666666"
C_TEXT = "#FFFFFF"
C_BAR_BG = "#222222"
C_BAR_NUB = "#444444"
C_GREEN = "#2ECC40"
C_YELLOW = "#FFDC00"
C_RED = "#FF4136"
C_CHARGE = "#39CCCC"
C_LIMIT = "#DDDDDD"

BAR_W = 61  # body; the nub adds 1px
BAR_H = 4

# vertical layout (absolute rows)
HEADER_Y = 1
HERO_Y = 9
BAR_Y = 25

# ---------------------------------------------------------------- helpers

def is_number(s):
    if s == None:
        return False
    t = s.strip().replace("-", "", 1).replace(".", "", 1)
    return len(t) > 0 and t.isdigit()

def to_num(s):
    return float(s) if is_number(s) else None

def fmt1(x):
    """One decimal place (Starlark's % has no precision flag)."""
    tenths = int(x * 10 + 0.5)
    return "%d.%d" % (tenths // 10, tenths % 10)

def slugify(s):
    """Turn a vehicle name like 'Dee Two' into an entity-ID prefix like 'dee_two'."""
    out = ""
    for c in s.strip().lower().elems():
        out += c if (c.isalnum() or c == "_") else "_"
    for _ in range(4):
        out = out.replace("__", "_")
    return out.strip("_")

def entity_for(config, vehicle, role):
    """User override if set, otherwise derived from the vehicle name."""
    override = config.str(role + "_entity", "").strip()
    if override:
        return override
    if vehicle:
        return SUFFIX[role] % vehicle
    return ""

def get_state(base, token, entity):
    """Returns (state, attributes) for an HA entity, or (None, {})."""
    if not entity:
        return None, {}
    resp = http.get(
        "%s/api/states/%s" % (base.rstrip("/"), entity),
        headers = {
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json",
        },
        ttl_seconds = CACHE_TTL,
    )
    if resp.status_code != 200:
        return None, {}
    data = resp.json()
    state = data.get("state")
    attrs = data.get("attributes") or {}
    if state in (None, "unknown", "unavailable", ""):
        return None, attrs
    return state, attrs

def is_unlocked(raw, attrs):
    """True / False / None. lock.* reports locked/unlocked; a binary_sensor with
    device_class lock is on = unlocked, otherwise (e.g. 'locked state') on = locked."""
    if raw == None:
        return None
    s = raw.lower()
    if s in ("on", "off"):
        on_means_unlocked = attrs.get("device_class") == "lock"
        return (s == "on") == on_means_unlocked
    if s in ("unlocked", "unlocking", "open", "opening", "jammed"):
        return True
    if s in ("locked", "locking", "closed"):
        return False
    return None

def lock_status(base, token, entities):
    """One entity or a comma-separated list: UNLOCKED if any is unlocked."""
    seen = False
    for ent in entities.split(","):
        raw, attrs = get_state(base, token, ent.strip())
        u = is_unlocked(raw, attrs)
        if u == True:
            return "UNLOCKED"
        if u == False:
            seen = True
    return "LOCKED" if seen else None

def charger_status(state_raw, plug_raw):
    """Returns 'charging', 'plugged', 'unplugged' or None."""
    s = state_raw.lower() if state_raw != None else None
    if s != None and s in ACTIVE_STATES:
        return "charging"
    if plug_raw != None:
        return "plugged" if plug_raw.lower() == "on" else "unplugged"

    # No connection sensor: infer from charger_state. charging_ready is reported
    # whenever the car is idle, plugged or not, so it can't mean "plugged".
    if s == None:
        return None
    if s == "charging_ready" or "disconnect" in s:
        return "unplugged"
    return "plugged"

def soc_color(soc):
    if soc == None:
        return C_DIM
    if soc >= 50:
        return C_GREEN
    if soc >= 20:
        return C_YELLOW
    return C_RED

def units_label(attrs):
    u = (attrs.get("unit_of_measurement") or "mi").lower()
    return "km" if u.startswith("km") else "mi"

# ---------------------------------------------------------------- widgets

def at(x, y, child):
    """Place a widget at an absolute (x, y) inside a full-screen Stack."""
    return render.Padding(pad = (x, y, 0, 0), child = child)

def message(title, body):
    return render.Root(
        child = render.Padding(
            pad = 1,
            child = render.Column(
                children = [
                    render.Text(title, font = "tom-thumb", color = C_TITLE),
                    render.WrappedText(body, font = "tom-thumb", color = C_TEXT, width = 62),
                ],
            ),
        ),
    )

def header(label, status_text, status_color):
    return render.Row(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Text(label, font = "tom-thumb", color = C_TITLE),
            render.Text(status_text, font = "tom-thumb", color = status_color),
        ],
    )

def hero(soc, rng, unit):
    """Big SOC on the left, range on the right, sharing one baseline."""
    soc_txt = "--" if soc == None else "%d" % int(soc + 0.5)
    rng_txt = "--" if rng == None else "%d" % int(rng + 0.5)
    color = soc_color(soc)
    return render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "end",
        children = [
            render.Row(
                cross_align = "end",
                children = [
                    render.Text(soc_txt, font = "terminus-16", color = color),
                    # lift the % so its bottom sits on the digits' baseline
                    render.Padding(pad = (1, 0, 0, 2), child = render.Text("%", font = "tb-8", color = color)),
                ],
            ),
            render.Padding(
                pad = (0, 0, 0, 3),
                child = render.Row(
                    cross_align = "end",
                    children = [
                        render.Text(rng_txt, font = "tb-8", color = C_TEXT),
                        render.Padding(pad = (1, 0, 0, 0), child = render.Text(unit, font = "tom-thumb", color = C_DIM)),
                    ],
                ),
            ),
        ],
    )

def fill_width(soc):
    return 0 if soc == None else max(1, min(BAR_W, int(BAR_W * soc / 100.0 + 0.5)))

def bar_frame(soc, limit, charging, sweep_x):
    """Battery-shaped bar: body + nub, with a tall tick at the charge limit. 6px tall overall."""
    fill_w = fill_width(soc)
    fill_color = C_CHARGE if charging else soc_color(soc)
    layers = [
        at(0, 1, render.Box(width = BAR_W, height = BAR_H, color = C_BAR_BG)),
        at(BAR_W, 2, render.Box(width = 1, height = BAR_H - 2, color = C_BAR_NUB)),
    ]

    # Box(width=0) would expand to fill the parent, so only add the fill when there is one
    if fill_w > 0:
        layers.append(at(0, 1, render.Box(width = fill_w, height = BAR_H, color = fill_color)))

    # moving highlight while charging
    if charging and sweep_x != None and sweep_x < fill_w:
        layers.append(at(sweep_x, 1, render.Box(width = 2, height = BAR_H, color = "#FFFFFF")))

    # charge limit tick, poking out above and below the bar
    if limit != None and limit < 100:
        lx = min(BAR_W - 1, int(BAR_W * limit / 100.0))
        layers.append(at(lx, 0, render.Box(width = 1, height = BAR_H + 2, color = C_LIMIT)))
    return render.Stack(children = layers)

def battery_bar(soc, limit, charging):
    if not charging or soc == None:
        return bar_frame(soc, limit, False, None)
    frames = [bar_frame(soc, limit, True, x) for x in range(0, fill_width(soc), 2)]

    # brief pause at the end so the sweep "breathes"
    frames.extend([bar_frame(soc, limit, True, None)] * 5)
    return render.Animation(children = frames)

# ---------------------------------------------------------------- main

def main(config):
    base = config.str("ha_url", "").strip()
    token = config.str("ha_token", "").strip()
    vehicle = slugify(config.str("vehicle", ""))
    label = config.str("label", "").strip().upper()[:8] or (vehicle.upper()[:8] if vehicle else "RIVIAN")

    if not base or not token:
        return message(label, "Add Home Assistant URL & token in settings.")
    if not vehicle and not config.str("soc_entity", ""):
        return message(label, "Add your vehicle name in settings.")

    soc_raw, _ = get_state(base, token, entity_for(config, vehicle, "soc"))
    rng_raw, rng_attrs = get_state(base, token, entity_for(config, vehicle, "range"))
    chg_raw, _ = get_state(base, token, entity_for(config, vehicle, "charger"))
    lim_raw, _ = get_state(base, token, entity_for(config, vehicle, "limit"))
    plug_raw, _ = get_state(base, token, entity_for(config, vehicle, "plug"))
    pwr_raw, _ = get_state(base, token, entity_for(config, vehicle, "power"))
    lock = None
    if config.bool("show_lock", True):
        lock = lock_status(base, token, entity_for(config, vehicle, "lock"))

    soc = to_num(soc_raw)
    rng = to_num(rng_raw)
    limit = to_num(lim_raw)
    power = to_num(pwr_raw)

    if soc == None and rng == None:
        return message(label, "No data. Check URL, token & vehicle name.")

    charger = charger_status(chg_raw, plug_raw)
    charging = charger == "charging"

    # header status, most important first
    if charging:
        status = (fmt1(power) + "kW") if power != None and power > 0 else "CHARGING"
        status_color = C_CHARGE
    elif lock == "UNLOCKED":
        status, status_color = "UNLOCKED", C_RED
    elif charger == "plugged":
        status, status_color = "PLUGGED", C_GREEN
    elif lock == "LOCKED":
        status, status_color = "LOCKED", C_DIM
    elif limit != None:
        status, status_color = "LIMIT %d%%" % int(limit), C_DIM
    else:
        status, status_color = "", C_DIM

    return render.Root(
        delay = 80,
        max_age = 300,
        child = render.Stack(
            children = [
                at(1, HEADER_Y, render.Box(width = 62, height = 6, child = header(label, status, status_color))),
                at(1, HERO_Y, render.Box(width = 62, height = 16, child = hero(soc, rng, units_label(rng_attrs)))),
                at(1, BAR_Y, battery_bar(soc, limit, charging)),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_url",
                name = "Home Assistant URL",
                desc = "Reachable from your Tronbyt server, e.g. http://homeassistant.local:8123",
                icon = "house",
            ),
            schema.Text(
                id = "ha_token",
                name = "Access token",
                desc = "Long-lived access token (HA profile > Security)",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "vehicle",
                name = "Vehicle name",
                desc = "As it appears in entity IDs, e.g. 'r2' for sensor.r2_battery_state_of_charge",
                icon = "carSide",
            ),
            schema.Text(
                id = "label",
                name = "Display label",
                desc = "Text in the top-left corner, up to 8 characters (default: vehicle name)",
                icon = "font",
            ),
            schema.Toggle(
                id = "show_lock",
                name = "Show lock status",
                desc = "Show LOCKED / UNLOCKED in the header",
                icon = "lock",
                default = True,
            ),
            schema.Text(
                id = "soc_entity",
                name = "Battery % entity (optional)",
                desc = "Override. Default: sensor.<vehicle>_battery_state_of_charge",
                icon = "batteryHalf",
            ),
            schema.Text(
                id = "range_entity",
                name = "Range entity (optional)",
                desc = "Override. Default: sensor.<vehicle>_estimated_vehicle_range",
                icon = "road",
            ),
            schema.Text(
                id = "charger_entity",
                name = "Charger state entity (optional)",
                desc = "Override. Default: sensor.<vehicle>_charger_state",
                icon = "chargingStation",
            ),
            schema.Text(
                id = "plug_entity",
                name = "Charger connection entity (optional)",
                desc = "Override. Default: binary_sensor.<vehicle>_charger_connection",
                icon = "plug",
            ),
            schema.Text(
                id = "limit_entity",
                name = "Charge limit entity (optional)",
                desc = "Override. Default: sensor.<vehicle>_battery_state_of_charge_limit",
                icon = "gaugeHigh",
            ),
            schema.Text(
                id = "power_entity",
                name = "Charging power entity (optional)",
                desc = "Override, in kW. Default: sensor.<vehicle>_charging_speed",
                icon = "bolt",
            ),
            schema.Text(
                id = "lock_entity",
                name = "Lock entity (optional)",
                desc = "Override; comma-separate several. Default: lock.<vehicle>_closures",
                icon = "lock",
            ),
        ],
    )
