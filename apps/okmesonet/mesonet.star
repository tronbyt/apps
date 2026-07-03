"""Pure parse/format/color logic for the OK Mesonet app.

No rendering and no main() here: this module is loaded both by
ok_mesonet.star (the applet) and by test_parse.star (the test runner),
and pixlet refuses to load modules that define main().

Data courtesy of the Oklahoma Mesonet (Oklahoma State University /
University of Oklahoma). Personal, non-commercial use.
"""

load("math.star", "math")
load("re.star", "re")
load("time.star", "time")

FEED_TZ = "Etc/GMT+6"  # feed is fixed CST (UTC-6), no DST

DEFAULT_STATION = "NRMN"

WHITE = "#FFFFFF"
DIM = "#9CA3AF"
WIND_GRAY = "#D1D5DB"
BLUE = "#60A5FA"
GREEN = "#22C55E"
AMBER = "#F59E0B"
RED = "#EF4444"

GUST_DELTA = 5  # mph over sustained before the gust is worth showing
RED_FLAG_RELH = 25  # <= this RH (%) ...
RED_FLAG_WSPD = 20  # ... with >= this sustained wind (mph) = red-flag accent
HEAT_ACCENT_F = 105  # heat index at/above this forces the temp red

def to_int(s):
    if s == None or len(s) == 0:
        return None
    if not re.match(r"^[0-9]+$", s):
        return None
    return int(s)

def to_float(s):
    if s == None or len(s) == 0:
        return None
    if not re.match(r"^-?[0-9]+(\.[0-9]+)?$", s):
        return None
    return float(s)

def field(row, key):
    v = row.get(key, "")
    if v == None:
        return None
    v = v.strip()
    if len(v) == 0:
        return None
    return v

def parse_current_csv(body, stid):
    lines = body.strip().split("\n")
    if len(lines) < 2:
        return None
    header = [h.strip() for h in lines[0].split(",")]
    if "STID" not in header:
        return None
    idx = {h: i for i, h in enumerate(header)}
    for line in lines[1:]:
        cells = line.split(",")
        if len(cells) < len(header):
            continue
        if cells[idx["STID"]].strip() == stid:
            return {h: cells[idx[h]] for h in header}
    return None

def parse_obs_time(row):
    parts = [to_int(field(row, k)) for k in ["YR", "MO", "DA", "HR", "MI"]]
    if None in parts:
        return None
    return time.time(
        year = parts[0],
        month = parts[1],
        day = parts[2],
        hour = parts[3],
        minute = parts[4],
        location = FEED_TZ,
    )

def round_int(v):
    return int(math.round(v))

def fmt_temp(v):
    t = to_float(v)
    if t == None:
        return "--"
    return "%d°" % round_int(t)

def temp_color(temp_f, colorize):
    if not colorize or temp_f == None:
        return WHITE
    if temp_f <= 32:
        return "#3B82F6"
    if temp_f < 50:
        return "#22D3EE"
    if temp_f < 70:
        return "#4ADE80"
    if temp_f < 85:
        return "#FDE047"
    if temp_f < 100:
        return "#FB923C"
    return RED

def fmt_wind(row):
    spd = to_float(field(row, "WSPD"))
    if spd == None:
        return "--"
    s = round_int(spd)
    if s == 0:
        return "CALM"
    text = "%d" % s
    wdir = field(row, "WDIR")
    if wdir != None:
        text = "%d %s" % (s, wdir)
    gust = to_float(field(row, "WMAX"))
    if gust != None and gust - spd >= GUST_DELTA:
        text += " G%d" % round_int(gust)
    return text

def wind_fit(text):
    if len(text) > 9:
        return text.replace(" ", "", 1)
    return text

def fmt_rain(row):
    v = field(row, "RAIN")
    if v == None:
        return '0.00"'  # feed leaves RAIN blank when zero
    r = to_float(v)
    if r == None:
        return "--"

    # Starlark %-formatting has no precision flags; format N.NN via cents.
    cents = round_int(r * 100)
    frac = cents % 100
    pad = "0" if frac < 10 else ""
    return '%d.%s%d"' % (cents // 100, pad, frac)

def fmt_pressure(row):
    p = to_float(field(row, "PRES"))
    if p == None:
        return "--"
    return "%dmb" % round_int(p)

def fmt_secondary(row, secondary):
    if secondary == "dewpoint":
        d = to_float(field(row, "TDEW"))
        if d == None:
            return "--"
        return "%d°" % round_int(d)
    h = to_float(field(row, "RELH"))
    if h == None:
        return "--"
    return "%d%%" % round_int(h)

def staleness_color(minutes):
    # The feed publishes observations 5-13 minutes behind wall clock even
    # when perfectly healthy, so "fresh" extends to 15 minutes.
    if minutes == None:
        return RED
    if minutes < 15:
        return GREEN
    if minutes <= 40:
        return AMBER
    return RED

def is_red_flag(row):
    relh = to_float(field(row, "RELH"))
    spd = to_float(field(row, "WSPD"))
    if relh == None or spd == None:
        return False
    return relh <= RED_FLAG_RELH and spd >= RED_FLAG_WSPD

def has_heat_accent(row):
    h = to_float(field(row, "HEAT"))
    return h != None and h >= HEAT_ACCENT_F

def station_name(stid):
    for sid, name in STATIONS:
        if sid == stid:
            return name
    return stid

def build_view(row, name, secondary, colorize, now):
    obs = parse_obs_time(row)
    minutes = (now - obs).minutes if obs != None else None
    t = to_float(field(row, "TAIR"))
    tcolor = temp_color(t, colorize)
    if has_heat_accent(row):
        tcolor = RED
    return {
        "name": name,
        "dot": staleness_color(minutes),
        "temp": fmt_temp(field(row, "TAIR")),
        "temp_color": tcolor,
        "wind": fmt_wind(row),
        "wind_color": RED if is_red_flag(row) else WIND_GRAY,
        "secondary": fmt_secondary(row, secondary),
        "rain": fmt_rain(row),
        "pressure": fmt_pressure(row),
    }

def offline_view(name):
    return {
        "name": name,
        "dot": RED,
        "temp": "--",
        "temp_color": WHITE,
        "wind": "OFFLINE",
        "wind_color": RED,
        "secondary": "--",
        "rain": "--",
        "pressure": "--",
    }

def no_report_view(name):
    v = offline_view(name)
    v["dot"] = AMBER
    v["wind"] = "NO RPT"
    v["wind_color"] = AMBER
    return v

# BEGIN GENERATED STATIONS (scripts/gen_stations.py - do not edit by hand)
STATIONS = [
    ("ACME", "Acme"),
    ("ADAX", "Ada"),
    ("ALTU", "Altus"),
    ("ALV2", "Alva"),
    ("ANT2", "Antlers"),
    ("APAC", "Apache"),
    ("ARD2", "Ardmore"),
    ("ARNE", "Arnett"),
    ("BEAV", "Beaver"),
    ("BESS", "Bessie"),
    ("BIXB", "Bixby"),
    ("BLAC", "Blackwell"),
    ("BOIS", "Boise City"),
    ("BREC", "Breckinridge"),
    ("BRIS", "Bristow"),
    ("BROK", "Broken Bow"),
    ("BUFF", "Buffalo"),
    ("BURB", "Burbank"),
    ("BURN", "Burneyville"),
    ("BUTL", "Butler"),
    ("BYAR", "Byars"),
    ("CAMA", "Camargo"),
    ("CENT", "Centrahoma"),
    ("CHAN", "Chandler"),
    ("CHER", "Cherokee"),
    ("CHEY", "Cheyenne"),
    ("CHIC", "Chickasha"),
    ("CLAY", "Clayton"),
    ("CLOU", "Cloudy"),
    ("COOK", "Cookson"),
    ("COPA", "Copan"),
    ("DURA", "Durant"),
    ("ELRE", "El Reno"),
    ("ELKC", "Elk City"),
    ("ERIC", "Erick"),
    ("EUFA", "Eufaula"),
    ("EVAX", "Eva"),
    ("FAI2", "Fairview"),
    ("FITT", "Fittstown"),
    ("FORA", "Foraker"),
    ("FTCB", "Fort Cobb"),
    ("FREE", "Freedom"),
    ("GOOD", "Goodwell"),
    ("GRA2", "Grandfield"),
    ("GUTH", "Guthrie"),
    ("HASK", "Haskell"),
    ("HECT", "Hectorville"),
    ("HINT", "Hinton"),
    ("HOBA", "Hobart"),
    ("HOLD", "Holdenville"),
    ("HOLL", "Hollis"),
    ("HOOK", "Hooker"),
    ("HUGO", "Hugo"),
    ("IDAB", "Idabel"),
    ("INOL", "Inola"),
    ("JAYX", "Jay"),
    ("KENT", "Kenton"),
    ("KETC", "Ketchum Ranch"),
    ("KIN2", "Kingfisher"),
    ("LAHO", "Lahoma"),
    ("CARL", "Lake Carl Blackwell"),
    ("LANE", "Lane"),
    ("MADI", "Madill"),
    ("MANG", "Mangum"),
    ("MARE", "Marena"),
    ("MRSH", "Marshall"),
    ("MAYR", "May Ranch"),
    ("MCAL", "McAlester"),
    ("MEDF", "Medford"),
    ("MEDI", "Medicine Park"),
    ("MIAM", "Miami"),
    ("MINC", "Minco"),
    ("NEWK", "Newkirk"),
    ("NEWP", "Newport"),
    ("NRMN", "Norman"),
    ("NOWA", "Nowata"),
    ("OILT", "Oilton"),
    ("OKEM", "Okemah"),
    ("OKCE", "Oklahoma City East"),
    ("OKMU", "Okmulgee"),
    ("PAUL", "Pauls Valley"),
    ("PAWN", "Pawnee"),
    ("PERK", "Perkins"),
    ("PORT", "Porter"),
    ("PRYO", "Pryor"),
    ("PUTN", "Putnam"),
    ("REDR", "Red Rock"),
    ("RING", "Ringling"),
    ("SALL", "Sallisaw"),
    ("SEIL", "Seiling"),
    ("SEMI", "Seminole"),
    ("SHAW", "Shawnee"),
    ("SKIA", "Skiatook"),
    ("SLAP", "Slapout"),
    ("SMIT", "Smithville"),
    ("SPEN", "Spencer"),
    ("STIG", "Stigler"),
    ("STIL", "Stillwater"),
    ("STUA", "Stuart"),
    ("SULP", "Sulphur"),
    ("TAHL", "Tahlequah"),
    ("TALA", "Talala"),
    ("TALI", "Talihina"),
    ("TIPT", "Tipton"),
    ("TISH", "Tishomingo"),
    ("TULN", "Tulsa"),
    ("VALL", "Valliant"),
    ("VINI", "Vinita"),
    ("WAL2", "Walters"),
    ("WASH", "Washington"),
    ("WATO", "Watonga"),
    ("WAUR", "Waurika"),
    ("WEAT", "Weatherford"),
    ("WEB3", "Webbers Falls"),
    ("WEST", "Westville"),
    ("WILB", "Wilburton"),
    ("WIST", "Wister"),
    ("WOOD", "Woodward"),
    ("WYNO", "Wynona"),
    ("YUKO", "Yukon"),
]
# END GENERATED STATIONS
