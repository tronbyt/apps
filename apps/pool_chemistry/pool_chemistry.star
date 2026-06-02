"""
Pool Chemistry Display for Tronbyt (64×32 LED)
Fetches Water Guru pool sensor data from Home Assistant.

Animated slideshow:
  1. Overview  — all 6 params at once, color-coded
  2. pH        — detail + GOOD/LOW/HIGH
  3. Chlorine  — detail
  4. Temperature — comfort indicator
  5. Alkalinity — detail
  6. CYA        — detail
  7. Calcium    — detail

Schema config: ha_url, ha_token
"""

load("render.star", "render")
load("http.star", "http")
load("schema.star", "schema")

# ── Palette ───────────────────────────────────────────────────────────────────
GREEN  = "#0d0"
ORANGE = "#f80"
RED    = "#e22"
GREY   = "#555"
BLUE   = "#4af"
WHITE  = "#fff"
CYAN   = "#8cf"
DIM    = "#888"
DARK   = "#001b33"

# ── Data helpers ──────────────────────────────────────────────────────────────

def fetch(ha_url, token, entity_id):
    url = ha_url.rstrip("/") + "/api/states/" + entity_id
    r = http.get(
        url,
        headers = {"Authorization": "Bearer " + token},
    )
    if r.status_code != 200:
        return -1.0
    s = r.json().get("state", "")
    if s in ("unavailable", "unknown", "none", ""):
        return -1.0
    return float(s)

def color_for(v, lo_red, lo_orange, hi_orange, hi_red):
    if v < 0:
        return GREY
    if v < lo_red or v > hi_red:
        return RED
    if v < lo_orange or v > hi_orange:
        return ORANGE
    return GREEN

def ph_color(v):   return color_for(v, 7.2, 7.3, 7.5, 7.6)
def fc_color(v):   return color_for(v, 1.0, 1.5, 5.0, 5.0)
def ta_color(v):   return color_for(v, 80, 90, 110, 120)
def cya_color(v):  return color_for(v, 30, 40, 70, 80)
def ca_color(v):   return color_for(v, 150, 175, 275, 300)

def status(v, lo, hi):
    if v < 0:   return "NO DATA"
    if v < lo:  return "LOW"
    if v > hi:  return "HIGH"
    return "GOOD"

def fmt(v, decimals):
    if v < 0:
        return "--"
    if decimals == 0:
        return str(int(v + 0.5))
    if decimals == 1:
        int_part = int(v)
        dec_part = int((v - int_part) * 10 + 0.5)
        if dec_part >= 10:
            int_part += 1
            dec_part = 0
        return str(int_part) + "." + str(dec_part)
    return str(v)

# ── Shared widgets ────────────────────────────────────────────────────────────

def header_bar(label, accent):
    return render.Box(
        width = 64, height = 9, color = DARK,
        child = render.Row(
            cross_align = "center",
            children = [
                render.Box(width = 4, height = 9, color = accent),
                render.Box(width = 3, height = 1),
                render.Text(label, font = "tb-8", color = WHITE),
            ],
        ),
    )

# ── Frame builders ────────────────────────────────────────────────────────────

def overview_frame(ph, fc, temp, ta, cya, ca):
    def cell(label, val_str, clr):
        return render.Column(
            cross_align = "start",
            children = [
                render.Text(label, font = "tom-thumb", color = CYAN),
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Box(width = 4, height = 4, color = clr),
                        render.Box(width = 1, height = 1),
                        render.Text(val_str, font = "tom-thumb", color = clr),
                    ],
                ),
            ],
        )

    temp_s = (fmt(temp, 0) + "°") if temp >= 0 else "--"  # °

    return render.Column(
        children = [
            render.Box(
                width = 64, height = 7, color = DARK,
                child = render.Row(
                    cross_align = "center",
                    children = [
                        render.Box(width = 2, height = 1),
                        render.Text("POOL CHEMISTRY", font = "tom-thumb", color = CYAN),
                    ],
                ),
            ),
            render.Row(
                children = [
                    render.Box(width = 2, height = 1),
                    cell("pH",  fmt(ph, 1),        ph_color(ph)),
                    render.Box(width = 5, height = 1),
                    cell("FC",  fmt(fc, 1) + "p",  fc_color(fc)),
                    render.Box(width = 5, height = 1),
                    cell("°F", temp_s,         BLUE),
                ],
            ),
            render.Box(height = 1),
            render.Row(
                children = [
                    render.Box(width = 2, height = 1),
                    cell("TA",  fmt(ta,  0),  ta_color(ta)),
                    render.Box(width = 3, height = 1),
                    cell("CYA", fmt(cya, 0),  cya_color(cya)),
                    render.Box(width = 3, height = 1),
                    cell("Ca",  fmt(ca,  0),  ca_color(ca)),
                ],
            ),
        ],
    )

def detail_frame(label, val_str, unit, stat_str, clr):
    return render.Column(
        children = [
            header_bar(label, clr),
            render.Box(height = 1),
            render.Row(
                cross_align = "end",
                children = [
                    render.Box(width = 4, height = 1),
                    render.Text(val_str, font = "6x13", color = clr),
                    render.Box(width = 2, height = 1),
                    render.Text(unit, font = "tom-thumb", color = DIM),
                ],
            ),
            render.Box(height = 2),
            render.Row(
                children = [
                    render.Box(width = 4, height = 1),
                    render.Text(stat_str, font = "tom-thumb", color = clr),
                ],
            ),
        ],
    )

def temp_frame(temp):
    val   = (fmt(temp, 0) + "°F") if temp >= 0 else "--"
    if temp < 0:
        comfort = "NO DATA"
        comfort_clr = GREY
    elif temp < 75:
        comfort = "Too cold"
        comfort_clr = BLUE
    elif temp <= 86:
        comfort = "Great swim!"
        comfort_clr = GREEN
    else:
        comfort = "Very warm"
        comfort_clr = ORANGE
    return render.Column(
        children = [
            header_bar("Temperature", BLUE),
            render.Box(height = 1),
            render.Row(
                children = [
                    render.Box(width = 4, height = 1),
                    render.Text(val, font = "6x13", color = BLUE),
                ],
            ),
            render.Box(height = 2),
            render.Row(
                children = [
                    render.Box(width = 4, height = 1),
                    render.Text(comfort, font = "tom-thumb", color = comfort_clr),
                ],
            ),
        ],
    )

# ── Entry point ───────────────────────────────────────────────────────────────

def main(config):
    ha_url = config.get("ha_url", "")
    token  = config.get("ha_token", "")

    if not ha_url or not token:
        return render.Root(
            child = render.Box(
                width = 64, height = 32, color = "#001",
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Text("Pool Chemistry", font = "tb-8", color = ORANGE),
                        render.Box(height = 3),
                        render.Text("Set HA URL+Token", font = "tom-thumb", color = DIM),
                    ],
                ),
            ),
        )

    pool_id = config.get("pool_id", "my_pool")
    prefix  = "sensor.waterguru_" + pool_id

    ph   = fetch(ha_url, token, prefix + "_ph")
    fc   = fetch(ha_url, token, prefix + "_free_chlorine")
    ta   = fetch(ha_url, token, prefix + "_total_alkalinity")
    cya  = fetch(ha_url, token, prefix + "_cyanuric_acid_stabilizer")
    ca   = fetch(ha_url, token, prefix + "_calcium_hardness")
    temp = fetch(ha_url, token, prefix + "_water_temperature")

    frames = [
        overview_frame(ph, fc, temp, ta, cya, ca),
        detail_frame("pH",          fmt(ph,  1), "",    status(ph,  7.2, 7.6), ph_color(ph)),
        detail_frame("Free Cl", fmt(fc, 1), "ppm", status(fc,  1.5, 5.0), fc_color(fc)),
        temp_frame(temp),
        detail_frame("Alkalinity",  fmt(ta,  0), "ppm", status(ta,  80,  120),  ta_color(ta)),
        detail_frame("CYA",         fmt(cya, 0), "ppm", status(cya, 30,  80),   cya_color(cya)),
        detail_frame("Calcium",     fmt(ca,  0), "ppm", status(ca,  150, 300),  ca_color(ca)),
    ]

    return render.Root(
        delay = 3000,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id   = "ha_url",
                name = "Home Assistant URL",
                desc = "Your HA base URL, e.g. https://ha.example.com",
                icon = "house",
            ),
            schema.Text(
                id   = "ha_token",
                name = "Long-Lived Access Token",
                desc = "HA → Profile → Security → Long-Lived Access Tokens",
                icon = "key",
            ),
            schema.Text(
                id      = "pool_id",
                name    = "Pool entity ID slug",
                desc    = "HA slug for your Water Guru device, e.g. my_pool (check Settings → Devices for the entity prefix sensor.waterguru_XXXXX)",
                icon    = "water",
                default = "my_pool",
            ),
        ],
    )
