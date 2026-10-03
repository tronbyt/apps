"""
Applet: Docker Container Monitor
Summary: Monitor Docker containers
Description: Monitor single or multiple Docker containers, track health status, view dot matrix or fleet summary, and receive alerts for stopped or unhealthy containers.
Author: brombomb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/docker_icon.png", DOCKER_ICON_ASSET = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

DOCKER_CYAN = "#0db7ed"
GREEN = "#00ff66"
RED = "#ff3333"
ORANGE = "#ff9900"
YELLOW = "#ffcc00"
MUTED = "#778899"
WHITE = "#ffffff"
BG_COLOR = "#000000"

SAMPLE_CONTAINERS = [
    {"Names": ["/pin-card-api"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "pin-card-api:latest"},
    {"Names": ["/uptime-kuma"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "louislam/uptime-kuma:2"},
    {"Names": ["/birdnet-go"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "birdnet-go:nightly"},
    {"Names": ["/homeassistant"], "State": "running", "Status": "Up 4 hours", "Image": "home-assistant:stable"},
    {"Names": ["/plex"], "State": "running", "Status": "Up 37 hours", "Image": "linuxserver/plex:latest"},
    {"Names": ["/postgres-db"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "postgres:15-alpine"},
    {"Names": ["/tronbyt-server"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "tronbyt/server:2"},
    {"Names": ["/readmeabook"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "readmeabook:latest"},
    {"Names": ["/seerr"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "seerr:latest"},
    {"Names": ["/teslamate"], "State": "running", "Status": "Up 37 hours", "Image": "teslamate:latest"},
    {"Names": ["/authelia"], "State": "running", "Status": "Up 37 hours (healthy)", "Image": "authelia:latest"},
    {"Names": ["/netdata"], "State": "running", "Status": "Up 4 hours (healthy)", "Image": "netdata:edge"},
]

def clean_container_name(raw_name):
    if raw_name.startswith("/"):
        return raw_name[1:]
    return raw_name

def filter_containers_by_targets(parsed, target_name):
    if not target_name or target_name.strip() == "":
        return parsed

    raw_targets = [t.strip() for t in target_name.split(",") if t.strip() != ""]
    if not raw_targets:
        return parsed

    selected = []
    seen_ids = {}

    for rt in raw_targets:
        is_exact = False
        if rt.startswith("="):
            t = rt[1:].strip().lower()
            is_exact = True
        elif rt.startswith('"') and rt.endswith('"') and len(rt) >= 2:
            t = rt[1:-1].strip().lower()
            is_exact = True
        else:
            t = clean_container_name(rt.lower())

        # Pass 1: Exact matches for this target
        exact_matches = []
        for c in parsed:
            c_name = c["name"].lower()
            if c_name == t or clean_container_name(c_name) == t:
                exact_matches.append(c)

        if exact_matches:
            for c in exact_matches:
                cid = c["name"].lower()
                if cid not in seen_ids:
                    seen_ids[cid] = True
                    selected.append(c)
            continue

        # If no exact match and not forced exact, Pass 2: Prefix match (e.g. "foo-" or "foo_")
        if not is_exact:
            prefix_matches = []
            for c in parsed:
                c_name = c["name"].lower()
                if c_name.startswith(t + "-") or c_name.startswith(t + "_"):
                    prefix_matches.append(c)
            if prefix_matches:
                for c in prefix_matches:
                    cid = c["name"].lower()
                    if cid not in seen_ids:
                        seen_ids[cid] = True
                        selected.append(c)
                continue

        # If still no match and not forced exact, Pass 3: Substring match
        if not is_exact:
            sub_matches = []
            for c in parsed:
                c_name = c["name"].lower()
                if t in c_name:
                    sub_matches.append(c)
            for c in sub_matches:
                cid = c["name"].lower()
                if cid not in seen_ids:
                    seen_ids[cid] = True
                    selected.append(c)

    return selected

def parse_container_info(raw_container):
    names = raw_container.get("Names", [])
    name = clean_container_name(names[0]) if names else raw_container.get("Id", "container")[:12]
    state = raw_container.get("State", "").lower()
    status = raw_container.get("Status", "")
    image = raw_container.get("Image", "")

    status_lower = status.lower()

    is_unhealthy = "(unhealthy)" in status_lower
    is_healthy = "(healthy)" in status_lower
    is_running = state == "running"
    is_restarting = state == "restarting"
    is_paused = state == "paused"
    is_exited = state in ["exited", "dead"]

    if is_unhealthy:
        status_label = "UNHEALTHY"
        status_color = ORANGE
        badge_bg = "#331a00"
        badge_border = "#aa5500"
        dot_color = ORANGE
    elif is_restarting:
        status_label = "RESTART"
        status_color = YELLOW
        badge_bg = "#332b00"
        badge_border = "#aa8800"
        dot_color = YELLOW
    elif is_paused:
        status_label = "PAUSED"
        status_color = YELLOW
        badge_bg = "#332b00"
        badge_border = "#aa8800"
        dot_color = YELLOW
    elif is_exited:
        status_label = "DOWN"
        status_color = RED
        badge_bg = "#330000"
        badge_border = "#aa0000"
        dot_color = RED
    elif is_running:
        status_label = "RUNNING"
        status_color = GREEN
        badge_bg = "#002b11"
        badge_border = "#008833"
        dot_color = GREEN
    else:
        status_label = state.upper() if state else "UNKNOWN"
        status_color = MUTED
        badge_bg = "#111822"
        badge_border = "#334455"
        dot_color = MUTED

    return {
        "name": name,
        "state": state,
        "status": status,
        "image": image,
        "is_running": is_running,
        "is_unhealthy": is_unhealthy,
        "is_healthy": is_healthy,
        "is_down": is_exited or is_unhealthy,
        "label": status_label,
        "color": status_color,
        "badge_bg": badge_bg,
        "badge_border": badge_border,
        "dot_color": dot_color,
    }

def fetch_docker_containers(url, auth_token):
    if not url or url.strip() == "":
        return SAMPLE_CONTAINERS

    clean_url = url.strip()
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    if not clean_url.endswith("/containers/json"):
        endpoint = clean_url + "/containers/json?all=1"
    else:
        endpoint = clean_url + "?all=1"

    cache_key = "docker_mon_" + endpoint
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    headers = {
        "User-Agent": "Tronbyt-Docker-Monitor",
        "Accept": "application/json",
    }
    if auth_token and auth_token.strip() != "":
        tok = auth_token.strip()
        headers["Authorization"] = "Bearer " + tok
        headers["X-API-Key"] = tok

    res = http.get(endpoint, headers = headers, ttl_seconds = 30)
    if res.status_code != 200:
        print("Failed to query Docker API:", res.status_code, endpoint)
        return None

    data = res.json()
    if type(data) == "list":
        cache.set(cache_key, json.encode(data), ttl_seconds = 30)
        return data
    elif type(data) == "dict" and "data" in data and type(data["data"]) == "list":
        cache.set(cache_key, json.encode(data["data"]), ttl_seconds = 30)
        return data["data"]

    return None

def render_count_badge(num, color, bg_color, scale, badge_height, font_tiny):
    s = str(num)
    w = (len(s) * 4 + 3) * scale
    return render.Box(
        color = bg_color,
        width = w,
        height = badge_height,
        child = render.Text(s, font = font_tiny, color = color),
    )

def render_header(scale, width, docker_icon, title_text, up_count, down_count, font_title, font_tiny):
    icon_width = 13 * scale
    icon_height = 10 * scale
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
        render.Image(src = docker_icon, width = icon_width, height = icon_height),
    )

    right_side = render.Row(
        cross_align = "center",
        children = right_elements,
    )

    max_title_w = width - (35 * scale if down_count > 0 else 26 * scale)

    return render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Marquee(
                width = max_title_w,
                child = render.Text(title_text, font = font_title, color = DOCKER_CYAN),
            ),
            right_side,
        ],
    )

def render_summary_view(scale, width, height, parsed_containers, up_count, down_count, docker_icon, font_title, font_main, font_tiny):
    header = render_header(scale, width, docker_icon, "DOCKER", up_count, down_count, font_title, font_tiny)

    body_height = height - (12 * scale)

    # If any container is down or unhealthy, show incident banner
    down_items = [c for c in parsed_containers if c["is_down"]]

    if down_items:
        first_down = down_items[0]
        alert_content = [
            render.Marquee(
                width = width - (8 * scale),
                child = render.Text("! " + first_down["name"], font = font_main, color = RED),
            ),
            render.Text(
                first_down["status"][:20] if first_down["status"] else first_down["label"],
                font = font_tiny,
                color = ORANGE,
            ),
        ]

        if len(down_items) > 1:
            alert_content.append(
                render.Text("+%d more issue(s)" % (len(down_items) - 1), font = font_tiny, color = MUTED),
            )

        body = render.Box(
            width = width,
            height = body_height,
            color = "#1a0000",
            child = render.Padding(
                pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale),
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "start",
                    children = alert_content,
                ),
            ),
        )
    else:
        # All healthy / running view
        total = len(parsed_containers)
        status_text = "%d / %d Healthy" % (up_count, total) if total > 0 else "No Containers"
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
                        render.Text(status_text, font = font_tiny, color = "#88ddaa"),
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

def render_single_view(scale, width, height, target, docker_icon, font_title, font_main, font_tiny, card_idx = 0, total_cards = 1):
    icon_width = 13 * scale
    icon_height = 10 * scale

    if not target:
        return render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("Container Not Found", font = font_main, color = RED),
                    render.Text("Check Config", font = font_tiny, color = MUTED),
                ],
            ),
        )

    if total_cards > 1:
        disp_idx = target.get("orig_idx", card_idx)
        disp_total = target.get("orig_total", total_cards)
        counter_str = "%d/%d" % (disp_idx + 1, disp_total)
        counter_w = (len(counter_str) * 4 + 4) * scale
        name_w = width - icon_width - (3 * scale) - counter_w - (3 * scale)
        top_row = render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_between",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = docker_icon, width = icon_width, height = icon_height),
                        render.Box(width = 3 * scale, height = 1),
                        render.Marquee(
                            width = name_w,
                            child = render.Text(target["name"], font = font_title, color = WHITE),
                        ),
                    ],
                ),
                render.Text(counter_str, font = font_tiny, color = "#778899"),
            ],
        )
    else:
        top_row = render.Row(
            cross_align = "center",
            children = [
                render.Image(src = docker_icon, width = icon_width, height = icon_height),
                render.Box(width = 3 * scale, height = 1),
                render.Marquee(
                    width = width - (20 * scale),
                    child = render.Text(target["name"], font = font_title, color = WHITE),
                ),
            ],
        )

    return render.Box(
        width = width,
        height = height,
        color = BG_COLOR,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                top_row,
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Box(
                            color = target["badge_bg"],
                            child = render.Padding(
                                pad = (4 * scale, 1 * scale, 4 * scale, 1 * scale),
                                child = render.Text(target["label"], font = font_main, color = target["color"]),
                            ),
                        ),
                    ],
                ),
                render.Marquee(
                    width = width,
                    child = render.Text(target["status"] if target["status"] else target["image"], font = font_tiny, color = MUTED),
                ),
            ],
        ),
    )

def render_single_carousel_view(scale, width, height, items, docker_icon, font_title, font_main, font_tiny, hold_frames = 70):
    total = len(items)
    cards = [
        render_single_view(
            scale,
            width,
            height,
            items[i],
            docker_icon,
            font_title,
            font_main,
            font_tiny,
            i,
            total,
        )
        for i in range(total)
    ]

    card_frames = []
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

        for _ in range(hold_frames):
            card_frames.append(cur_card)

        for offset in swipe_offsets:
            card_frames.append(
                render.Box(
                    width = width,
                    height = height,
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

    return render.Animation(children = card_frames)

def calc_matrix_layout(n_items, avail_w, avail_h, scale):
    if n_items <= 0:
        return 12 * scale, 1, 1, 2 * scale

    best_size = 0
    best_rows = 1
    best_cols = n_items
    best_spacing = 1 * scale

    max_try_rows = 4 * scale
    if n_items < max_try_rows:
        max_try_rows = n_items

    for r in range(1, max_try_rows + 1):
        cols = (n_items + r - 1) // r
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

def render_grid_view(scale, width, height, parsed_containers, up_count, down_count, docker_icon, font_title, font_tiny):
    header = render_header(scale, width, docker_icon, "DOCKER FLEET", up_count, down_count, font_title, font_tiny)

    matrix_body_height = height - (14 * scale)
    avail_w = width - (4 * scale)
    avail_h = matrix_body_height - (2 * scale)

    dot_size, _, best_cols, spacing = calc_matrix_layout(len(parsed_containers), avail_w, avail_h, scale)

    rows = []
    current_row = []

    for c in parsed_containers:
        if len(current_row) > 0:
            current_row.append(render.Box(width = spacing, height = dot_size))

        current_row.append(
            render.Box(
                width = dot_size,
                height = dot_size,
                color = c["dot_color"],
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

def render_container_card(scale, width, card_height, c, card_idx, total_cards, font_main, font_tiny):
    disp_idx = c.get("orig_idx", card_idx)
    disp_total = c.get("orig_total", total_cards)
    counter_str = "%d/%d" % (disp_idx + 1, disp_total)
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
                    render.Box(width = 2 * scale, height = 6 * scale, color = c["dot_color"]),
                    render.Box(width = 2 * scale, height = 1),
                    render.Marquee(
                        width = name_w,
                        child = render.Text(c["name"], font = font_main, color = WHITE),
                    ),
                ],
            ),
            render.Text(counter_str, font = font_tiny, color = "#778899"),
        ],
    )

    detail_str = c["status"] if c["status"] else (c["image"] if c["image"] else "Active")

    row2 = render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Marquee(
                width = width - (4 * scale),
                child = render.Text(detail_str, font = font_tiny, color = "#88aacc"),
            ),
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

def render_carousel_view(scale, width, height, parsed_containers, up_count, down_count, docker_icon, font_title, font_main, font_tiny, hold_frames = 70):
    header = render_header(scale, width, docker_icon, "DOCKER FLEET", up_count, down_count, font_title, font_tiny)
    header_height = 13 * scale
    card_height = height - header_height - (1 * scale)

    if not parsed_containers:
        return render.Column(
            expanded = True,
            children = [
                render.Padding(pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale), child = header),
                render.Box(width = width, height = 1 * scale, color = "#112233"),
                render.Box(width = width, height = card_height, child = render.Text("No Containers", font = font_tiny, color = MUTED)),
            ],
        )

    total = len(parsed_containers)
    cards = [render_container_card(scale, width, card_height, parsed_containers[i], i, total, font_main, font_tiny) for i in range(total)]

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

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    font_title = "tb-8" if scale == 1 else "terminus-14"
    font_main = "tb-8" if scale == 1 else "terminus-14"
    font_tiny = "tom-thumb" if scale == 1 else "tb-8"

    docker_url = config.str("docker_url", "")
    auth_token = config.str("auth_token", "")
    mode = config.str("display_mode", "summary")
    target_name = config.str("container_name", "")
    hide_stopped = config.bool("hide_stopped", False)
    alert_only = config.bool("alert_only", False)
    random_start = config.bool("random_start", False)
    down_first = config.bool("down_first", True)

    raw_containers = fetch_docker_containers(docker_url, auth_token)

    if raw_containers == None:
        return render.Root(
            child = render.Box(
                width = width,
                height = height,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("Docker Offline", font = font_main, color = RED),
                        render.Text("Check Host URL", font = font_tiny, color = MUTED),
                    ],
                ),
            ),
        )

    parsed = []
    for rc in raw_containers:
        p = parse_container_info(rc)

        # Skip clean exits if requested
        if hide_stopped and p["state"] == "exited" and "exited (0)" in p["status"].lower():
            continue

        parsed.append(p)

    # Filter by container name / multi target list (exact match prioritized, supports =name, "name", and comma-separated)
    if target_name and target_name.strip() != "":
        parsed = filter_containers_by_targets(parsed, target_name)

    # Record fleet index and total count for accurate X/Y display on cards
    total_count = len(parsed)
    for i in range(total_count):
        parsed[i]["orig_idx"] = i
        parsed[i]["orig_total"] = total_count

    # Always show down/stopped/unhealthy containers first if requested
    if down_first and len(parsed) > 1:
        down_containers = [c for c in parsed if c["is_down"] or not c["is_running"]]
        up_containers = [c for c in parsed if not (c["is_down"] or not c["is_running"])]
        parsed = down_containers + up_containers

    up_count = len([c for c in parsed if c["is_running"]])
    down_count = len([c for c in parsed if c["is_down"]])

    # Alert only mode: skip rendering if everything is healthy
    if alert_only and down_count == 0:
        return []

    docker_icon = DOCKER_ICON_ASSET.readall()
    is_multi_single = mode == "single" and len(parsed) > 1 and target_name and target_name.strip() != ""

    if mode == "single":
        if not parsed:
            root_child = render_single_view(
                scale,
                width,
                height,
                None,
                docker_icon,
                font_title,
                font_main,
                font_tiny,
                0,
                0,
            )
        elif not is_multi_single:
            root_child = render_single_view(
                scale,
                width,
                height,
                parsed[0],
                docker_icon,
                font_title,
                font_main,
                font_tiny,
                0,
                1,
            )
        else:
            speed_option = config.str("carousel_speed", "normal")
            base_hold = 70
            if speed_option == "slow":
                base_hold = 100
            elif speed_option == "relaxed":
                base_hold = 80
            elif speed_option == "fast":
                base_hold = 50
            hold_frames = base_hold * scale

            items = parsed
            total_items = len(items)

            if random_start and total_items > 1:
                down_items = [c for c in items if c["is_down"] or not c["is_running"]]
                up_items = [c for c in items if not (c["is_down"] or not c["is_running"])]

                if down_items:
                    if len(up_items) > 1:
                        r_idx = random.number(0, len(up_items) - 1)
                        up_items = up_items[r_idx:] + up_items[:r_idx]
                    items = down_items + up_items
                else:
                    r_idx = random.number(0, total_items - 1)
                    items = items[r_idx:] + items[:r_idx]

                if len(items) > 5:
                    items = items[:5]

            root_child = render_single_carousel_view(
                scale,
                width,
                height,
                items,
                docker_icon,
                font_title,
                font_main,
                font_tiny,
                hold_frames = hold_frames,
            )
    elif mode == "grid":
        root_child = render_grid_view(
            scale,
            width,
            height,
            parsed,
            up_count,
            down_count,
            docker_icon,
            font_title,
            font_tiny,
        )
    elif mode == "carousel":
        speed_option = config.str("carousel_speed", "normal")
        base_hold = 70
        if speed_option == "slow":
            base_hold = 100
        elif speed_option == "relaxed":
            base_hold = 80
        elif speed_option == "fast":
            base_hold = 50
        hold_frames = base_hold * scale

        carousel_items = parsed
        total_items = len(carousel_items)

        if random_start and total_items > 1:
            down_items = [c for c in carousel_items if c["is_down"] or not c["is_running"]]
            up_items = [c for c in carousel_items if not (c["is_down"] or not c["is_running"])]

            if down_items:
                # Keep down containers at the front, randomize running containers
                if len(up_items) > 1:
                    r_idx = random.number(0, len(up_items) - 1)
                    up_items = up_items[r_idx:] + up_items[:r_idx]
                carousel_items = down_items + up_items
            else:
                # Randomize starting point across all containers
                r_idx = random.number(0, total_items - 1)
                carousel_items = carousel_items[r_idx:] + carousel_items[:r_idx]

            # In random start mode, cap to a 5-card window (~22s) so long lists render within display window
            if len(carousel_items) > 5:
                carousel_items = carousel_items[:5]

        root_child = render_carousel_view(
            scale,
            width,
            height,
            carousel_items,
            up_count,
            down_count,
            docker_icon,
            font_title,
            font_main,
            font_tiny,
            hold_frames = hold_frames,
        )
    else:
        root_child = render_summary_view(
            scale,
            width,
            height,
            parsed,
            up_count,
            down_count,
            docker_icon,
            font_title,
            font_main,
            font_tiny,
        )

    delay = 50 // scale
    return render.Root(
        delay = delay,
        show_full_animation = True if (mode == "carousel" or is_multi_single) else False,
        child = render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = root_child,
        ),
    )

def get_schema():
    modes = [
        schema.Option(display = "Fleet Summary & Alert", value = "summary"),
        schema.Option(display = "Single Container Focus", value = "single"),
        schema.Option(display = "Container Dot Matrix", value = "grid"),
        schema.Option(display = "Container Carousel", value = "carousel"),
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
                id = "docker_url",
                name = "Docker Host URL",
                desc = "Docker Engine HTTP API, Socket Proxy, or Portainer endpoint",
                icon = "docker",
                default = "http://localhost:2375",
            ),
            schema.Text(
                id = "auth_token",
                name = "Auth Token (Optional)",
                desc = "Bearer token, Portainer API key, or custom auth token",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Display Mode",
                desc = "How container statuses are presented",
                icon = "cubesStacked",
                default = "summary",
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
                id = "random_start",
                name = "Random Carousel Start",
                desc = "Start carousel at a random container each cycle (renders a quick window for rotation)",
                icon = "shuffle",
                default = False,
            ),
            schema.Toggle(
                id = "down_first",
                name = "Show Down / Stopped First",
                desc = "Always prioritize down, unhealthy, or stopped containers at the top of the list",
                icon = "triangleExclamation",
                default = True,
            ),
            schema.Text(
                id = "container_name",
                name = "Container Name / Filter",
                desc = "Target container (exact matches prioritized; prefix '=' to force exact), or comma-separated list",
                icon = "cube",
            ),
            schema.Toggle(
                id = "hide_stopped",
                name = "Hide Normal Exits",
                desc = "Hide containers that cleanly exited with status 0",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Toggle(
                id = "alert_only",
                name = "Alert Only Mode",
                desc = "Only display when containers are down or unhealthy; otherwise skip rendering",
                icon = "bell",
                default = False,
            ),
        ],
    )
