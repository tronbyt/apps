"""
Applet: F1 Clock
Summary: Formula 1 racing clock
Description: Large digital clock with animated 8px Formula 1 cars racing across the track with real, condensed, or historic gaps.
Author: brombomb
"""

load("http.star", "http")
load("images/alp_doo.png", IMG_ALP_DOO = "file")
load("images/alp_gas.png", IMG_ALP_GAS = "file")
load("images/ast_alo.png", IMG_AST_ALO = "file")
load("images/ast_str.png", IMG_AST_STR = "file")
load("images/fer_ham.png", IMG_FER_HAM = "file")
load("images/fer_lec.png", IMG_FER_LEC = "file")
load("images/haa_bea.png", IMG_HAA_BEA = "file")
load("images/haa_oco.png", IMG_HAA_OCO = "file")
load("images/his_hun.png", IMG_HIS_HUN = "file")
load("images/his_lau.png", IMG_HIS_LAU = "file")
load("images/his_msc.png", IMG_HIS_MSC = "file")
load("images/his_pro.png", IMG_HIS_PRO = "file")
load("images/his_sen.png", IMG_HIS_SEN = "file")
load("images/his_vet.png", IMG_HIS_VET = "file")
load("images/mcl_nor.png", IMG_MCL_NOR = "file")
load("images/mcl_pia.png", IMG_MCL_PIA = "file")
load("images/mer_ant.png", IMG_MER_ANT = "file")
load("images/mer_rus.png", IMG_MER_RUS = "file")
load("images/rbr_law.png", IMG_RBR_LAW = "file")
load("images/rbr_ver.png", IMG_RBR_VER = "file")
load("images/sau_bor.png", IMG_SAU_BOR = "file")
load("images/sau_hul.png", IMG_SAU_HUL = "file")
load("images/vca_had.png", IMG_VCA_HAD = "file")
load("images/vca_tsu.png", IMG_VCA_TSU = "file")
load("images/wil_alb.png", IMG_WIL_ALB = "file")
load("images/wil_sai.png", IMG_WIL_SAI = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

CAR_SPRITES = {
    "HAM": IMG_FER_HAM,
    "LEC": IMG_FER_LEC,
    "NOR": IMG_MCL_NOR,
    "PIA": IMG_MCL_PIA,
    "VER": IMG_RBR_VER,
    "LAW": IMG_RBR_LAW,
    "RUS": IMG_MER_RUS,
    "ANT": IMG_MER_ANT,
    "ALO": IMG_AST_ALO,
    "STR": IMG_AST_STR,
    "SAI": IMG_WIL_SAI,
    "ALB": IMG_WIL_ALB,
    "GAS": IMG_ALP_GAS,
    "DOO": IMG_ALP_DOO,
    "BEA": IMG_HAA_BEA,
    "OCO": IMG_HAA_OCO,
    "HUL": IMG_SAU_HUL,
    "BOR": IMG_SAU_BOR,
    "TSU": IMG_VCA_TSU,
    "HAD": IMG_VCA_HAD,
    "SEN": IMG_HIS_SEN,
    "PRO": IMG_HIS_PRO,
    "HUN": IMG_HIS_HUN,
    "LAU": IMG_HIS_LAU,
    "MSC": IMG_HIS_MSC,
    "VET": IMG_HIS_VET,
}

# Driver code lookup by driver ID / name
DRIVER_MAP = {
    "hamilton": "HAM",
    "leclerc": "LEC",
    "norris": "NOR",
    "piastri": "PIA",
    "max_verstappen": "VER",
    "lawson": "LAW",
    "russell": "RUS",
    "antonelli": "ANT",
    "alonso": "ALO",
    "stroll": "STR",
    "sainz": "SAI",
    "albon": "ALB",
    "gasly": "GAS",
    "doohan": "DOO",
    "bearman": "BEA",
    "ocon": "OCO",
    "hulkenberg": "HUL",
    "bortoleto": "BOR",
    "tsunoda": "TSU",
    "hadjar": "HAD",
    "senna": "SEN",
    "prost": "PRO",
    "hunt": "HUN",
    "lauda": "LAU",
    "schumacher": "MSC",
    "schumaker": "MSC",
}

# Driver numbers for results display
DRIVER_NUMBERS = {
    "HAM": "44",
    "LEC": "16",
    "NOR": "4",
    "PIA": "81",
    "VER": "1",
    "LAW": "30",
    "RUS": "63",
    "ANT": "12",
    "ALO": "14",
    "STR": "18",
    "SAI": "55",
    "ALB": "23",
    "GAS": "10",
    "DOO": "7",
    "BEA": "87",
    "OCO": "31",
    "HUL": "27",
    "BOR": "5",
    "TSU": "22",
    "HAD": "6",
    "SEN": "12",
    "PRO": "2",
    "HUN": "11",
    "LAU": "12",
    "MSC": "1",
    "VET": "5",
}

# Historical race finishes: (name, [(driver_code, gap_seconds)])
HISTORICAL_RACES = [
    # Monza 2020: Gasly miracle win holding off Sainz
    [("GAS", 0.0), ("SAI", 0.415), ("STR", 3.358), ("NOR", 6.000)],
    # Abu Dhabi 2021: Final lap shootout
    [("VER", 0.0), ("HAM", 2.256), ("SAI", 5.173), ("TSU", 5.692)],
    # Silverstone 2020: Hamilton 3-wheel finish
    [("HAM", 0.0), ("VER", 5.856), ("LEC", 18.474), ("NOR", 22.926)],
    # 2024 Classic Battle
    [("NOR", 0.0), ("VER", 1.842), ("LEC", 3.210), ("HAM", 5.412), ("PIA", 7.150)],
    # 1988 Suzuka: Senna vs Prost duel
    [("SEN", 0.0), ("PRO", 0.320), ("LAU", 3.800), ("MSC", 6.500)],
    # 1976 Fuji: Hunt vs Lauda title battle
    [("HUN", 0.0), ("LAU", 0.850), ("PRO", 2.900), ("SEN", 5.400)],
    # Legends showdown
    [("SEN", 0.0), ("MSC", 0.720), ("PRO", 1.850), ("LAU", 3.400), ("HUN", 5.100)],
]

DEFAULT_GRID = [
    ("HAM", 0.0),
    ("LEC", 1.25),
    ("NOR", 2.80),
    ("VER", 4.60),
    ("PIA", 6.70),
]

F1_API_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/races.json"
F1_BASE_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/refs/heads/main/formula1/"

def fetch_last_race_results():
    """Fetch previous race results from F1 data mirror."""
    res = http.get(F1_API_URL, ttl_seconds = 86400)
    if res.status_code != 200:
        return None

    data = res.json()
    races = data.get("MRData", {}).get("RaceTable", {}).get("Races", [])
    if not races:
        return None

    now = time.now()
    last_round = None
    last_year = now.format("2006")

    for r in races:
        d_str = r.get("date", "") + " " + r.get("time", "00:00:00Z")
        parsed = time.parse_time(d_str, format = "2006-01-02 15:04:00Z")
        diff_hours = (parsed - now).hours
        if diff_hours < -3:
            last_round = r.get("round")

    if not last_round:
        last_round = races[0].get("round")

    res_url = "%s%s/%s/results.json" % (F1_BASE_URL, last_year, last_round)
    r_res = http.get(res_url, ttl_seconds = 3600)
    if r_res.status_code != 200:
        return None

    results_data = r_res.json()
    races_res = results_data.get("MRData", {}).get("RaceTable", {}).get("Races", [])
    if not races_res:
        return None

    results_list = races_res[0].get("Results", [])
    if not results_list:
        return None

    parsed_pack = []
    for entry in results_list[:6]:
        driver_id = entry.get("Driver", {}).get("driverId", "")
        code = DRIVER_MAP.get(driver_id, entry.get("Driver", {}).get("code", "HAM"))
        if code not in CAR_SPRITES:
            code = "HAM"

        time_obj = entry.get("Time", {})
        time_str = time_obj.get("time", "")
        gap_sec = 0.0
        if time_str.startswith("+"):
            val_str = time_str.replace("+", "").replace("s", "").strip()
            parts = val_str.split(":")
            if len(parts) == 2:
                gap_sec = float(parts[0]) * 60.0 + float(parts[1])
            elif len(parts) == 1:
                gap_sec = float(parts[0])

        parsed_pack.append((code, gap_sec))

    return parsed_pack

def get_pack(mode):
    """Return ordered list of (driver_code, gap_seconds) according to selected mode."""
    if mode == "random_race":
        modes = ["previous_condensed", "previous_results", "random", "historical"]
        idx = random.number(0, len(modes) - 1)
        mode = modes[idx]

    if mode == "historical":
        idx = random.number(0, len(HISTORICAL_RACES) - 1)
        return HISTORICAL_RACES[idx]

    if mode == "random":
        driver_keys = CAR_SPRITES.keys()

        # Pick 5 random drivers with realistic trailing gaps
        pack = []
        cur_gap = 0.0
        for _ in range(5):
            d_idx = random.number(0, len(driver_keys) - 1)
            pack.append((driver_keys[d_idx], cur_gap))
            cur_gap += 1.2 + (random.number(0, 15) / 10.0)
        return pack

    # Previous results (real or condensed)
    results = fetch_last_race_results()
    if not results:
        results = DEFAULT_GRID

    if mode == "previous_condensed":
        condensed = []
        cur_time = 0.0
        for i, (code, gap) in enumerate(results):
            if i == 0:
                condensed.append((code, 0.0))
            else:
                prev_gap = results[i - 1][1]
                delta = gap - prev_gap
                if delta < 0:
                    delta = 0.5
                step = 1.2 + (delta / 12.0)
                cur_time += step
                condensed.append((code, cur_time))
        return condensed

    return results

def render_track(width, height, scale):
    """Render background asphalt and curb."""
    curb_y = 15 * scale
    track_y = 16 * scale
    track_h = height - track_y

    # Red & white curb blocks (4px wide * scale)
    curb_blocks = []
    block_w = 4 * scale
    num_blocks = (width // block_w) + 1
    for b in range(num_blocks):
        c = "#e10600" if b % 2 == 0 else "#f0f0f0"
        curb_blocks.append(render.Box(width = block_w, height = 1 * scale, color = c))

    return [
        # Track background (daylight circuit asphalt for high contrast against black wheels and dark bodies)
        render.Padding(
            pad = (0, track_y, 0, 0),
            child = render.Box(width = width, height = track_h, color = "#444a59"),
        ),
        # Curb rumble strip
        render.Padding(
            pad = (0, curb_y, 0, 0),
            child = render.Row(children = curb_blocks),
        ),
        # Bottom boundary chalk line
        render.Padding(
            pad = (0, height - (1 * scale), 0, 0),
            child = render.Box(width = width, height = 1 * scale, color = "#abb2bf"),
        ),
    ]

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1
    is_2x = canvas.is2x()

    mode = config.get("mode", "previous_condensed")
    military = config.bool("military_time", False)
    hide_spoilers = config.bool("hide_spoilers", False)
    timezone = config.get("timezone") or config.get("$tz") or time.tz()

    # Time display (clean & large at the top)
    now = time.now().in_location(timezone)
    time_format = "15:04" if military else "3:04"
    time_str = now.format(time_format)

    clock_font = "terminus-24" if is_2x else "6x13"

    # Pre-decoded car images
    car_images = {}
    for code, sprite in CAR_SPRITES.items():
        car_images[code] = sprite.readall()

    # Get driver pack and gaps
    pack = get_pack(mode)

    # 8px tall cars (16px at 2x), 32px long (64px at 2x)
    car_w = 32 * scale
    car_h = 8 * scale

    # Vertical lanes for staggered racing:
    # Lane 0: Upper / Outside line (y = 16 * scale)
    # Lane 1: Middle / Racing line (y = 19 * scale)
    # Lane 2: Lower / Inside line (y = 22 * scale)
    lane_y = [16 * scale, 19 * scale, 22 * scale]

    # Assign each car a lane based on position and trailing gaps
    car_lanes = []
    for i in range(len(pack)):
        # Stagger pattern: Middle -> Inside -> Outside -> Middle
        l_idx = [1, 2, 0, 1, 2, 0][i % 6]
        car_lanes.append(lane_y[l_idx])

    # Simulation parameters:
    # Frame delay = 60ms (~16.7 fps).
    # Speed = 2px per frame (4px at 2x).
    # Total distance to cross 64px screen = 64 + 38 = 102px.
    # 180 frames @ 60ms = 10.8s rich race loop!
    speed = 2 * scale
    frame_delay_ms = 60
    num_frames = 180
    finish_x = width - (6 * scale)

    rendered_frames = []

    # Static background layers (clock + track)
    track_layers = render_track(width, height, scale)

    clock_widget = render.Box(
        width = width,
        height = 15 * scale,
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = time_str,
                    font = clock_font,
                    color = "#ffffff",
                ),
            ],
        ),
    )

    for f in range(num_frames):
        # Base frame
        frame_children = [
            render.Box(width = width, height = height, color = "#0a0c10"),
            clock_widget,
        ]

        # Top right driver numbers for top 3 as they cross finish line
        if not hide_spoilers:
            crossed_numbers = []
            for i in range(min(3, len(pack))):
                code, gap_sec = pack[i]
                entry_frame = int(gap_sec * 1000 // frame_delay_ms)
                car_x = -car_w + (f - entry_frame) * speed
                if car_x + car_w >= finish_x:
                    num_str = DRIVER_NUMBERS.get(code, "")
                    if num_str:
                        crossed_numbers.append(num_str)

            if crossed_numbers:
                num_font = "tb-8" if is_2x else "CG-pixel-3x5-mono"
                podium_colors = ["#ffd700", "#c0c0c0", "#cd7f32"]
                num_items = []
                for idx, num_str in enumerate(crossed_numbers):
                    color = podium_colors[idx if idx < 3 else 2]
                    num_items.append(
                        render.Text(
                            content = num_str,
                            font = num_font,
                            color = color,
                        ),
                    )

                numbers_widget = render.Padding(
                    pad = (width - (12 * scale), 0, 0, 0),
                    child = render.Box(
                        width = 11 * scale,
                        height = 15 * scale,
                        child = render.Column(
                            expanded = True,
                            main_align = "start",
                            cross_align = "end",
                            children = num_items,
                        ),
                    ),
                )
                frame_children.append(numbers_widget)

        frame_children.extend(track_layers)

        # Draw cars from upper lane to lower lane (proper depth sorting)
        cars_in_frame = []
        for i, (code, gap_sec) in enumerate(pack):
            # Frame offset when car enters the screen
            entry_frame = int(gap_sec * 1000 // frame_delay_ms)
            car_x = -car_w + (f - entry_frame) * speed
            car_y = car_lanes[i]

            # Only render if visible on canvas
            if car_x > -car_w and car_x < width:
                img_data = car_images.get(code, car_images["HAM"])
                cars_in_frame.append((car_y, car_x, img_data))

        # Sort by Y so lower lane (closer to camera) draws in front of upper lane
        cars_in_frame = sorted(cars_in_frame, key = lambda c: c[0])

        for cy, cx, img_data in cars_in_frame:
            frame_children.append(
                render.Padding(
                    pad = (cx, cy, 0, 0),
                    child = render.Image(
                        src = img_data,
                        width = car_w,
                        height = car_h,
                    ),
                ),
            )

        rendered_frames.append(
            render.Box(
                width = width,
                height = height,
                child = render.Stack(children = frame_children),
            ),
        )

    return render.Root(
        delay = frame_delay_ms,
        child = render.Animation(children = rendered_frames),
    )

def get_schema():
    mode_options = [
        schema.Option(display = "Previous Race (Condensed 10x)", value = "previous_condensed"),
        schema.Option(display = "Previous Race (Real Gaps)", value = "previous_results"),
        schema.Option(display = "Random Pack Battle", value = "random"),
        schema.Option(display = "Historic Classic Finishes", value = "historical"),
        schema.Option(display = "Random Race Mode", value = "random_race"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "mode",
                name = "Race Mode",
                desc = "Grid lineup and gap spacing",
                icon = "flagCheckered",
                default = mode_options[0].value,
                options = mode_options,
            ),
            schema.Toggle(
                id = "military_time",
                name = "24-Hour Clock",
                desc = "Display time in 24-hour format instead of 12-hour",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = "hide_spoilers",
                name = "Hide Spoilers",
                desc = "Hide finishing numbers in top right corner",
                icon = "eyeSlash",
                default = False,
            ),
        ],
    )
