"""
Applet: Uptime Kuma
Summary: Monitor services with Uptime Kuma
Description: Track service status, uptime percentage, and incident alerts from your Uptime Kuma status pages.
Author: brombomb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/kuma_icon.png", KUMA_ICON_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

KUMA_GREEN = "#5cd685"
GREEN = "#00ff66"
RED = "#ff3333"
YELLOW = "#ffcc00"
BLUE = "#3399ff"
MUTED = "#778899"
WHITE = "#ffffff"
BG_COLOR = "#000000"

SAMPLE_DATA = {
    "title": "Homelab",
    "monitors": [
        {"name": "Plex Media Server", "status": 1, "status_label": "UP", "ping": 14, "uptime": 100.0, "msg": "200 OK"},
        {"name": "Home Assistant", "status": 1, "status_label": "UP", "ping": 8, "uptime": 99.9, "msg": "200 OK"},
        {"name": "Pi-hole DNS", "status": 1, "status_label": "UP", "ping": 2, "uptime": 100.0, "msg": "200 OK"},
        {"name": "Nextcloud", "status": 1, "status_label": "UP", "ping": 22, "uptime": 99.8, "msg": "200 OK"},
        {"name": "TeslaMate", "status": 1, "status_label": "UP", "ping": 12, "uptime": 100.0, "msg": "200 OK"},
        {"name": "Backrest Backup", "status": 1, "status_label": "UP", "ping": 5, "uptime": 100.0, "msg": "200 OK"},
        {"name": "Audiobookshelf", "status": 1, "status_label": "UP", "ping": 16, "uptime": 100.0, "msg": "200 OK"},
        {"name": "BirdNET Station", "status": 1, "status_label": "UP", "ping": 10, "uptime": 100.0, "msg": "200 OK"},
    ],
}

def fetch_kuma_data(base_url, slug):
    if not base_url or base_url.strip() == "":
        return SAMPLE_DATA

    clean_url = base_url.strip()
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    clean_slug = slug.strip() if slug and slug.strip() != "" else "default"

    cache_key = "kuma_sp_" + clean_url + "_" + clean_slug
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    page_url = clean_url + "/api/status-page/" + clean_slug
    hb_url = clean_url + "/api/status-page/heartbeat/" + clean_slug

    headers = {"User-Agent": "Tronbyt-Uptime-Kuma"}

    page_res = http.get(page_url, headers = headers, ttl_seconds = 30)
    if page_res.status_code != 200:
        print("Failed to fetch Uptime Kuma status page:", page_res.status_code, page_url)
        return None

    page_data = page_res.json()
    title = (page_data.get("config") or {}).get("title") or clean_slug.capitalize()

    monitors_list = []
    groups = page_data.get("publicGroupList") or []
    for g in groups:
        for m in g.get("monitorList") or []:
            monitors_list.append(m)

    hb_res = http.get(hb_url, headers = headers, ttl_seconds = 30)
    hb_data = hb_res.json() if hb_res.status_code == 200 else {}
    heartbeats = hb_data.get("heartbeatList") or {}
    uptime_dict = hb_data.get("uptimeList") or {}

    parsed_monitors = []
    for m in monitors_list:
        m_id = str(m.get("id"))
        m_name = m.get("name", "Service")

        m_hbs = heartbeats.get(m_id) or []
        latest_hb = m_hbs[-1] if m_hbs else {}

        raw_status = latest_hb.get("status", 1)
        ping = latest_hb.get("ping", 0)
        msg = latest_hb.get("msg", "")

        uptime_val = uptime_dict.get(m_id + "_24", 1.0)
        uptime_pct = int(uptime_val * 1000) / 10.0 if type(uptime_val) in ["int", "float"] else 100.0

        if raw_status == 0:
            status_label = "DOWN"
        elif raw_status == 2:
            status_label = "PENDING"
        elif raw_status == 3:
            status_label = "MAINT"
        else:
            status_label = "UP"

        parsed_monitors.append({
            "name": m_name,
            "status": raw_status,
            "status_label": status_label,
            "ping": ping,
            "uptime": uptime_pct,
            "msg": msg,
        })

    result = {
        "title": title,
        "monitors": parsed_monitors if parsed_monitors else SAMPLE_DATA["monitors"],
    }
    cache.set(cache_key, json.encode(result), ttl_seconds = 30)
    return result

def get_status_color(status):
    if status == 0:
        return RED
    elif status == 2:
        return YELLOW
    elif status == 3:
        return BLUE
    return GREEN

def get_status_bg(status):
    if status == 0:
        return "#330000"
    elif status == 2:
        return "#332b00"
    elif status == 3:
        return "#001a33"
    return "#002b11"

def render_count_badge(num, color, bg_color, scale, badge_height, font_tiny):
    s = str(num)
    w = (len(s) * 4 + 3) * scale
    return render.Box(
        color = bg_color,
        width = w,
        height = badge_height,
        child = render.Text(s, font = font_tiny, color = color),
    )

def render_header(scale, width, kuma_icon, title_text, up_count, down_count, font_title, font_tiny):
    icon_width = 11 * scale
    icon_height = 11 * scale
    badge_height = 8 * scale

    right_elements = []

    # Green for Up
    if up_count > 0 or down_count == 0:
        right_elements.append(render_count_badge(up_count, GREEN, "#002b11", scale, badge_height, font_tiny))
        right_elements.append(render.Box(width = 2 * scale, height = 1))

    # Red for Down (if 0 down no red)
    if down_count > 0:
        right_elements.append(render_count_badge(down_count, RED, "#330000", scale, badge_height, font_tiny))
        right_elements.append(render.Box(width = 2 * scale, height = 1))

    # Logo in the upper right
    right_elements.append(
        render.Image(src = kuma_icon, width = icon_width, height = icon_height),
    )

    right_side = render.Row(
        cross_align = "center",
        children = right_elements,
    )

    max_title_w = width - (33 * scale if down_count > 0 else 24 * scale)

    return render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Marquee(
                width = max_title_w,
                child = render.Text(title_text, font = font_title, color = KUMA_GREEN),
            ),
            right_side,
        ],
    )

def render_dashboard(scale, width, height, title, monitors, up_count, down_count, kuma_icon, font_title, font_main, font_tiny):
    header = render_header(scale, width, kuma_icon, title, up_count, down_count, font_title, font_tiny)
    body_height = height - (12 * scale)

    down_monitors = [m for m in monitors if m["status"] == 0]

    if down_monitors:
        first = down_monitors[0]
        alert_children = [
            render.Marquee(
                width = width - (8 * scale),
                child = render.Text("! " + first["name"] + " DOWN", font = font_main, color = RED),
            ),
            render.Text(first["msg"][:22] if first["msg"] else "Connection Failed", font = font_tiny, color = YELLOW),
        ]
        if len(down_monitors) > 1:
            alert_children.append(
                render.Text("+%d more down" % (len(down_monitors) - 1), font = font_tiny, color = MUTED),
            )

        body = render.Box(
            width = width,
            height = body_height,
            color = "#1a0000",
            child = render.Padding(
                pad = (3 * scale, 1 * scale, 3 * scale, 1 * scale),
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "start",
                    children = alert_children,
                ),
            ),
        )
    else:
        # Calculate average uptime and ping
        total = len(monitors)
        total_ping = 0
        total_uptime = 0.0
        for m in monitors:
            total_ping += m["ping"]
            total_uptime += m.get("uptime", 100.0)
        avg_ping = total_ping // total if total > 0 else 0
        avg_uptime = int(total_uptime * 10 / total) / 10.0 if total > 0 else 100.0
        uptime_str = "100%" if avg_uptime >= 99.95 else str(avg_uptime) + "%"

        status_title = "OPERATIONAL" if scale == 1 else "ALL OPERATIONAL"

        body = render.Box(
            width = width,
            height = body_height,
            color = "#00150d",
            child = render.Padding(
                pad = (3 * scale, 2 * scale, 3 * scale, 2 * scale),
                child = render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "start",
                    children = [
                        render.Row(
                            cross_align = "center",
                            children = [
                                render.Box(width = 2 * scale, height = 6 * scale, color = GREEN),
                                render.Box(width = 2 * scale, height = 1),
                                render.Text(status_title, font = font_main, color = WHITE),
                            ],
                        ),
                        render.Text("%dms / %s" % (avg_ping, uptime_str), font = font_tiny, color = "#88ddaa"),
                        render.Box(
                            width = width - (6 * scale),
                            height = 2 * scale,
                            color = "#003b1e",
                            child = render.Box(
                                width = width - (6 * scale),
                                height = 2 * scale,
                                color = GREEN,
                            ),
                        ),
                    ],
                ),
            ),
        )

    return render.Column(
        expanded = True,
        children = [
            render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale), child = header),
            render.Box(width = width, height = 1 * scale, color = "#112233"),
            body,
        ],
    )

def render_service_card(scale, width, card_height, m, card_idx, total_cards, font_main, font_tiny):
    color = get_status_color(m["status"])
    counter_str = "%d/%d" % (card_idx + 1, total_cards)
    counter_w = (len(counter_str) * 4 + 4) * scale
    name_w = width - counter_w - (8 * scale)

    row1 = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Row(
                cross_align = "center",
                children = [
                    render.Box(width = 2 * scale, height = 6 * scale, color = color),
                    render.Box(width = 2 * scale, height = 1),
                    render.Marquee(
                        width = name_w,
                        child = render.Text(m["name"], font = font_main, color = WHITE),
                    ),
                ],
            ),
            render.Text(counter_str, font = font_tiny, color = "#778899"),
        ],
    )

    ping_str = "%dms" % m["ping"] if m["ping"] > 0 else "0ms"
    uptime_val = m.get("uptime", 100.0)
    uptime_str = "100%" if uptime_val >= 99.95 else str(uptime_val) + "%"
    stat_line = ping_str + " · " + uptime_str

    row2 = render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Text(stat_line, font = font_tiny, color = "#88aacc"),
        ],
    )

    return render.Box(
        width = width,
        height = card_height,
        color = BG_COLOR,
        child = render.Padding(
            pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "start",
                children = [row1, row2],
            ),
        ),
    )

def render_carousel(scale, width, height, title, monitors, up_count, down_count, kuma_icon, font_title, font_main, font_tiny, hold_frames = 70):
    header = render_header(scale, width, kuma_icon, title, up_count, down_count, font_title, font_tiny)
    header_height = 13 * scale
    card_height = height - header_height - (1 * scale)

    if not monitors:
        return render.Column(
            expanded = True,
            children = [
                render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale), child = header),
                render.Box(width = width, height = 1 * scale, color = "#112233"),
                render.Box(width = width, height = card_height, child = render.Text("No Monitors", font = font_tiny, color = MUTED)),
            ],
        )

    total = len(monitors)
    cards = [render_service_card(scale, width, card_height, monitors[i], i, total, font_main, font_tiny) for i in range(total)]

    if total == 1:
        body = cards[0]
    else:
        card_frames = []

        # Smooth ease-in-out horizontal card swipe (~1.0s transition)
        swipe_offsets = [
            64,
            63,
            62,
            60,
            57,
            54,
            51,
            47,
            43,
            38,
            32,
            26,
            21,
            17,
            13,
            10,
            7,
            4,
            2,
            1,
        ] if scale == 1 else [
            128,
            127,
            126,
            125,
            123,
            122,
            120,
            117,
            115,
            112,
            109,
            106,
            102,
            98,
            94,
            90,
            85,
            80,
            75,
            70,
            64,
            58,
            53,
            48,
            43,
            38,
            34,
            30,
            26,
            22,
            19,
            16,
            13,
            11,
            8,
            6,
            5,
            3,
            2,
            1,
        ]

        for i in range(total):
            cur_card = cards[i]
            next_card = cards[(i + 1) % total]

            # Hold card static so it can be easily read
            for _ in range(hold_frames):
                card_frames.append(cur_card)

            # Smooth horizontal card swipe
            for offset in swipe_offsets:
                card_frames.append(
                    render.Box(
                        width = width,
                        height = card_height,
                        color = BG_COLOR,
                        child = render.Stack(
                            children = [
                                cur_card,
                                render.Padding(
                                    pad = (offset, 0, 0, 0),
                                    child = next_card,
                                ),
                            ],
                        ),
                    ),
                )

        body = render.Animation(children = card_frames)

    return render.Column(
        expanded = True,
        children = [
            render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale), child = header),
            render.Box(width = width, height = 1 * scale, color = "#112233"),
            body,
        ],
    )

def calc_matrix_layout(n_monitors, avail_w, avail_h, scale):
    if n_monitors <= 0:
        return 12 * scale, 1, 1, 2 * scale

    best_size = 0
    best_rows = 1
    best_cols = n_monitors
    best_spacing = 1 * scale

    max_try_rows = 4 * scale
    if n_monitors < max_try_rows:
        max_try_rows = n_monitors

    for r in range(1, max_try_rows + 1):
        cols = (n_monitors + r - 1) // r
        spacing = 2 * scale if cols <= 4 else 1 * scale
        max_w = (avail_w - ((cols - 1) * spacing)) // cols
        max_h = (avail_h - ((r - 1) * spacing)) // r

        dot_sz = max_w if max_w < max_h else max_h
        if dot_sz > 15 * scale:
            dot_sz = 15 * scale

        if dot_sz > best_size:
            best_size = dot_sz
            best_rows = r
            best_cols = cols
            best_spacing = spacing

    if best_size < 2 * scale:
        best_size = 2 * scale

    return best_size, best_rows, best_cols, best_spacing

def render_matrix(scale, width, height, title, monitors, up_count, down_count, kuma_icon, font_title, font_tiny):
    header = render_header(scale, width, kuma_icon, title, up_count, down_count, font_title, font_tiny)

    matrix_body_height = height - (14 * scale)
    avail_w = width - (4 * scale)
    avail_h = matrix_body_height - (2 * scale)

    dot_size, _, best_cols, spacing = calc_matrix_layout(len(monitors), avail_w, avail_h, scale)

    rows = []
    current_row = []

    for m in monitors:
        if len(current_row) > 0:
            current_row.append(render.Box(width = spacing, height = dot_size))

        current_row.append(
            render.Box(
                width = dot_size,
                height = dot_size,
                color = get_status_color(m["status"]),
            ),
        )

        num_dots_in_row = (len(current_row) + 1) // 2
        if num_dots_in_row >= best_cols:
            if len(rows) > 0:
                rows.append(render.Box(width = 1, height = spacing))
            rows.append(render.Row(main_align = "center", cross_align = "center", children = current_row))
            current_row = []

    if current_row:
        if len(rows) > 0:
            rows.append(render.Box(width = 1, height = spacing))
        rows.append(render.Row(main_align = "center", cross_align = "center", children = current_row))

    return render.Column(
        expanded = True,
        children = [
            render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale), child = header),
            render.Box(width = width, height = 1 * scale, color = "#112233"),
            render.Box(
                width = width,
                height = matrix_body_height,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = rows,
                ),
            ),
        ],
    )

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    font_title = "tb-8" if scale == 1 else "terminus-14"
    font_main = "tb-8" if scale == 1 else "terminus-14"
    font_tiny = "tom-thumb" if scale == 1 else "tb-8"

    kuma_url = config.str("kuma_url", "")
    slug = config.str("slug", "default")
    mode = config.str("display_mode", "dashboard")
    alert_only = config.bool("alert_only", False)
    hide_maintenance = config.bool("hide_maintenance", True)

    data = fetch_kuma_data(kuma_url, slug)
    if not data:
        return render.Root(
            child = render.Box(
                width = width,
                height = height,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("Kuma Offline", font = font_main, color = RED),
                        render.Text("Check URL / Slug", font = font_tiny, color = MUTED),
                    ],
                ),
            ),
        )

    title = data.get("title", "Kuma")
    raw_monitors = data.get("monitors", [])

    monitors = []
    for m in raw_monitors:
        if hide_maintenance and m["status"] == 3:
            continue
        monitors.append(m)

    up_count = len([m for m in monitors if m["status"] == 1])
    down_count = len([m for m in monitors if m["status"] == 0])

    if alert_only and down_count == 0:
        return []

    kuma_icon = KUMA_ICON_ASSET.readall()

    if mode == "carousel":
        speed_option = config.str("carousel_speed", "normal")
        base_hold = 70
        if speed_option == "slow":
            base_hold = 100
        elif speed_option == "relaxed":
            base_hold = 80
        elif speed_option == "fast":
            base_hold = 50
        hold_frames = base_hold * scale

        root_child = render_carousel(
            scale,
            width,
            height,
            title,
            monitors,
            up_count,
            down_count,
            kuma_icon,
            font_title,
            font_main,
            font_tiny,
            hold_frames = hold_frames,
        )
    elif mode == "matrix":
        root_child = render_matrix(
            scale,
            width,
            height,
            title,
            monitors,
            up_count,
            down_count,
            kuma_icon,
            font_title,
            font_tiny,
        )
    else:
        root_child = render_dashboard(
            scale,
            width,
            height,
            title,
            monitors,
            up_count,
            down_count,
            kuma_icon,
            font_title,
            font_main,
            font_tiny,
        )

    delay = 50 // scale
    return render.Root(
        delay = delay,
        show_full_animation = True if mode == "carousel" else False,
        child = render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = root_child,
        ),
    )

def get_schema():
    modes = [
        schema.Option(display = "Service Dashboard & Alert", value = "dashboard"),
        schema.Option(display = "Monitors Carousel", value = "carousel"),
        schema.Option(display = "Status Dot Matrix", value = "matrix"),
    ]

    carousel_speed_options = [
        schema.Option(display = "Normal (3.5s hold)", value = "normal"),
        schema.Option(display = "Relaxed (4s hold)", value = "relaxed"),
        schema.Option(display = "Slow (5s hold)", value = "slow"),
        schema.Option(display = "Brisk (2.5s hold)", value = "fast"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "kuma_url",
                name = "Uptime Kuma URL",
                desc = "Host URL of your Uptime Kuma instance",
                icon = "server",
                default = "http://localhost:3001",
            ),
            schema.Text(
                id = "slug",
                name = "Status Page Slug",
                desc = "Slug of your status page (default is 'default')",
                icon = "globe",
                default = "default",
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Display Mode",
                desc = "Choose how monitors are displayed",
                icon = "cubesStacked",
                default = "dashboard",
                options = modes,
            ),
            schema.Dropdown(
                id = "carousel_speed",
                name = "Carousel Speed",
                desc = "Hold duration per card before transitioning in carousel mode",
                icon = "gaugeHigh",
                default = "normal",
                options = carousel_speed_options,
            ),
            schema.Toggle(
                id = "alert_only",
                name = "Alert Only Mode",
                desc = "Only display on screen when services are DOWN; otherwise skip rendering",
                icon = "bell",
                default = False,
            ),
            schema.Toggle(
                id = "hide_maintenance",
                name = "Hide Maintenance",
                desc = "Hide monitors that are under scheduled maintenance",
                icon = "wrench",
                default = True,
            ),
        ],
    )
