"""
Applet: Audiobookshelf
Summary: Audiobookshelf now playing
Description: Track currently playing audiobooks and podcasts from your Audiobookshelf server.
Author: brombomb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

ABS_GOLD = "#f59e0b"
WHITE = "#ffffff"
MUTED = "#94a3b8"
BG_COLOR = "#000000"

COLOR_SCHEMES = {
    "gold": "#f59e0b",
    "teal": "#06b6d4",
    "green": "#10b981",
    "purple": "#a855f7",
    "red": "#ef4444",
    "blue": "#3b82f6",
    "white": "#ffffff",
}

SAMPLE_DATA = {
    "title": "The Way of Kings",
    "author": "Brandon Sanderson",
    "chapter": "Chapter 4: The Shattered Plains",
    "progress": 0.38,
    "current_time": 5400,
    "duration": 14200,
    "is_playing": True,
    "cover_path": "",
    "item_id": "",
}

def format_time(seconds, compact = True):
    if seconds <= 0:
        return "0m"
    hours = int(seconds) // 3600
    minutes = (int(seconds) % 3600) // 60
    if compact:
        if hours > 0:
            return "%dh%dm" % (hours, minutes)
        return "%dm" % minutes
    else:
        if hours > 0:
            return "%dh %dm" % (hours, minutes)
        return "%dm" % minutes

def parse_hex_color(val, default = ABS_GOLD):
    if not val:
        return default
    c = val.strip()
    if not c.startswith("#"):
        c = "#" + c
    if len(c) == 7:
        is_hex = True
        for ch in c[1:].elems():
            if ch.lower() not in "0123456789abcdef":
                is_hex = False
                break
        if is_hex:
            return c
    return default

def render_smart_text(text, font, color, max_width, scale, scroll_mode = "scroll"):
    """Renders text: static if scroll_mode is 'static' or text fits max_width, marquee if scrolling is enabled and overflows."""
    if scroll_mode == "static":
        return render.Text(text, font = font, color = color)

    char_width = 4
    if font == "tom-thumb":
        char_width = 3
    elif font == "tb-8":
        char_width = 4 if scale == 1 else 5
    elif font == "terminus-14":
        char_width = 8

    approx_pixel_width = len(text) * char_width
    text_widget = render.Text(text, font = font, color = color)

    if approx_pixel_width <= max_width:
        return text_widget
    else:
        return render.Marquee(
            width = max_width,
            child = text_widget,
        )

def is_image(data):
    """Safely validate image bytes for PNG, JPEG, GIF, or WebP."""
    if not data or len(data) < 8:
        return False
    if data[1:4] == "PNG":
        return True
    if data[:3] == "GIF":
        return True
    if data[:4] == "RIFF" and len(data) >= 12 and data[8:12] == "WEBP":
        return True
    if ord(data[0]) in [65533, 255] and ord(data[1]) in [65533, 216] and ord(data[2]) in [65533, 255]:
        return True
    return False

def get_image_aspect(data):
    """Returns 'square' or 'rectangular' (or None) based on raw image bytes."""
    if not data or len(data) < 24:
        return None

    w, h = 0, 0

    # PNG: bytes 16..19 width, 20..23 height
    if data[1:4] == "PNG":
        w = ord(data[16]) * 16777216 + ord(data[17]) * 65536 + ord(data[18]) * 256 + ord(data[19])
        h = ord(data[20]) * 16777216 + ord(data[21]) * 65536 + ord(data[22]) * 256 + ord(data[23])

        # GIF: bytes 6..7 width, 8..9 height (little endian)
    elif data[:3] == "GIF":
        w = ord(data[6]) + ord(data[7]) * 256
        h = ord(data[8]) + ord(data[9]) * 256

        # WEBP: RIFF...WEBP
    elif data[:4] == "RIFF" and len(data) >= 30 and data[8:12] == "WEBP":
        chunk_type = data[12:16]
        if chunk_type == "VP8X" and len(data) >= 30:
            w = 1 + ord(data[24]) + ord(data[25]) * 256 + ord(data[26]) * 65536
            h = 1 + ord(data[27]) + ord(data[28]) * 256 + ord(data[29]) * 65536
        elif chunk_type == "VP8L" and len(data) >= 26:
            b1 = ord(data[21])
            b2 = ord(data[22])
            b3 = ord(data[23])
            b4 = ord(data[24])
            w = 1 + (((b2 & 0x3f) << 8) | b1)
            h = 1 + (((ord(data[25]) & 0x0f) << 10) | (b4 << 2) | ((b3 & 0xc0) >> 6))
        elif chunk_type == "VP8 " and len(data) >= 30:
            w = (ord(data[26]) + ord(data[27]) * 256) & 0x3fff
            h = (ord(data[28]) + ord(data[29]) * 256) & 0x3fff

        # JPEG: SOF frame search
    elif ord(data[0]) in [65533, 255] and ord(data[1]) in [65533, 216]:
        idx = 2
        d_len = len(data)
        for _ in range(100):
            if idx + 8 >= d_len:
                break
            if ord(data[idx]) != 255:
                break
            marker = ord(data[idx + 1])
            if marker in [0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf]:
                h = ord(data[idx + 5]) * 256 + ord(data[idx + 6])
                w = ord(data[idx + 7]) * 256 + ord(data[idx + 8])
                break
            seg_len = ord(data[idx + 2]) * 256 + ord(data[idx + 3])
            idx += 2 + seg_len

    if w > 0 and h > 0:
        if float(w) / float(h) >= 0.88:
            return "square"
        else:
            return "rectangular"

    return None

def fetch_abs_progress(server_url, api_token):
    if not server_url or not api_token or server_url.strip() == "" or api_token.strip() == "":
        return SAMPLE_DATA

    clean_url = server_url.strip()
    if not clean_url.startswith("http://") and not clean_url.startswith("https://"):
        clean_url = "http://" + clean_url
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    endpoint = clean_url + "/api/me/listening-sessions"
    cache_key = "abs_sessions_" + endpoint
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    headers = {
        "Authorization": "Bearer " + api_token.strip(),
        "User-Agent": "Tronbyt-Audiobookshelf",
    }

    res = http.get(endpoint, headers = headers, ttl_seconds = 15)
    sessions = []
    if res.status_code == 200:
        data = res.json()
        sessions = data.get("sessions") or []

    # Fallback to in-progress items if no active listening sessions
    if not sessions:
        items_url = clean_url + "/api/me/items-in-progress"
        items_res = http.get(items_url, headers = headers, ttl_seconds = 30)
        if items_res.status_code == 200:
            items_data = items_res.json()
            in_progress = items_data.get("libraryItems") or items_data.get("inProgress") or []
            if in_progress:
                first = in_progress[0]
                item_id = first.get("id", "")
                media = first.get("media") or {}
                metadata = media.get("metadata") or {}
                progress_obj = first.get("userMediaProgress") or {}

                title = metadata.get("title") or "Audiobook"
                author = metadata.get("authorName") or metadata.get("author") or ""
                duration = int(media.get("duration", 0))
                current_time = int(progress_obj.get("currentTime", 0))
                prog = progress_obj.get("progress", 0.0)
                if prog == 0.0 and duration > 0 and current_time > 0:
                    prog = float(current_time) / duration
                cover_path = media.get("coverPath") or first.get("coverPath") or ""

                result = {
                    "title": title,
                    "author": author,
                    "chapter": "",
                    "progress": prog,
                    "current_time": current_time,
                    "duration": duration,
                    "is_playing": False,
                    "cover_path": cover_path,
                    "item_id": item_id,
                }
                cache.set(cache_key, json.encode(result), ttl_seconds = 30)
                return result
        return None

    # Use first active session
    sess = sessions[0]
    media_meta = sess.get("mediaMetadata") or {}
    item_id = sess.get("libraryItemId") or sess.get("mediaItemId") or ""
    title = sess.get("displayTitle") or media_meta.get("title") or "Audiobook"
    author = sess.get("displayAuthor") or media_meta.get("author") or media_meta.get("authorName") or ""
    chapter_name = sess.get("chapterName") or sess.get("chapterTitle") or media_meta.get("chapterName") or media_meta.get("chapterTitle") or ""
    duration = int(sess.get("duration", 0))
    current_time = int(sess.get("currentTime", 0))
    progress_val = float(current_time) / duration if duration > 0 else 0.0
    cover_path = sess.get("coverPath") or media_meta.get("coverPath") or ""

    result = {
        "title": title,
        "author": author,
        "chapter": chapter_name,
        "progress": progress_val,
        "current_time": current_time,
        "duration": duration,
        "is_playing": True,
        "cover_path": cover_path,
        "item_id": item_id,
    }
    cache.set(cache_key, json.encode(result), ttl_seconds = 15)
    return result

def fetch_cover_image(server_url, api_token, cover_path, item_id, target_width = 48):
    if not server_url or not api_token:
        return None

    clean_url = server_url.strip()
    if not clean_url.startswith("http://") and not clean_url.startswith("https://"):
        clean_url = "http://" + clean_url
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    # Resolve item_id if missing but embedded in cover_path (e.g. /metadata/items/<id>/...)
    resolved_id = item_id.strip() if item_id else ""
    if not resolved_id and cover_path and "/items/" in cover_path:
        parts = cover_path.split("/items/")
        if len(parts) > 1:
            resolved_id = parts[1].split("/")[0]

    urls_to_try = []

    # Audiobookshelf's official cover endpoint is /api/items/<id>/cover
    if resolved_id:
        urls_to_try.append("%s/api/items/%s/cover?width=%d" % (clean_url, resolved_id, target_width))
        urls_to_try.append("%s/api/items/%s/cover" % (clean_url, resolved_id))

    if cover_path:
        if cover_path.startswith("http://") or cover_path.startswith("https://"):
            urls_to_try.append(cover_path)
        elif not cover_path.startswith("/metadata/"):
            if cover_path.startswith("/"):
                urls_to_try.append(clean_url + cover_path)
            else:
                urls_to_try.append(clean_url + "/" + cover_path)

    headers = {
        "Authorization": "Bearer " + api_token.strip(),
        "User-Agent": "Tronbyt-Audiobookshelf",
    }

    for url in urls_to_try:
        cache_key = "abs_cov_" + url
        cached = cache.get(cache_key)
        if cached:
            return cached

        res = http.get(url, headers = headers, ttl_seconds = 3600)
        if res.status_code == 200:
            body = res.body()
            if is_image(body):
                cache.set(cache_key, body, ttl_seconds = 3600)
                return body

    return None

def render_cover_fallback(scale, width, height, title, accent_color = ABS_GOLD):
    # Stylized procedural book jacket
    spine_width = 2 * scale
    initial = title[:1].upper() if title else "A"
    return render.Box(
        width = width,
        height = height,
        color = "#1e2430",
        child = render.Row(
            expanded = True,
            children = [
                render.Box(width = spine_width, height = height, color = accent_color),
                render.Box(
                    width = width - spine_width,
                    height = height,
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(initial, font = "tb-8" if scale == 1 else "terminus-14", color = accent_color),
                            render.Box(width = 8 * scale, height = 1 * scale, color = "#475569"),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_abs_view(scale, width, data, cover_bytes, font_title, font_tiny, cover_aspect = "square", bar_style = "standard", accent_color = ABS_GOLD, time_mode = "remaining", scroll_mode = "scroll"):
    if cover_aspect == "rectangular":
        cover_width = 24 * scale
        cover_height = 30 * scale
    else:
        cover_width = 30 * scale
        cover_height = 30 * scale

    if cover_bytes:
        cover_widget = render.Image(
            src = cover_bytes,
            width = cover_width,
            height = cover_height,
        )
    else:
        cover_widget = render_cover_fallback(scale, cover_width, cover_height, data.get("title", ""), accent_color)

    text_width = width - cover_width - (4 * scale)
    progress_pct = int(data["progress"] * 100)

    # Format time display cleanly for compact width
    time_left = data["duration"] - data["current_time"]
    if time_mode == "elapsed":
        time_display = format_time(data["current_time"], compact = True)
    elif time_mode == "total":
        time_display = format_time(data["duration"], compact = True)
    else:
        time_display = "-" + format_time(time_left, compact = True) if time_left > 0 else format_time(data["current_time"], compact = True)

    bar_outer_width = text_width
    bar_height = 3 * scale
    fill_width = int(bar_outer_width * data["progress"])
    if fill_width < 1 and data["progress"] > 0:
        fill_width = 1
    if fill_width > bar_outer_width:
        fill_width = bar_outer_width

    if bar_style == "centered":
        progress_bar = render.Box(
            width = bar_outer_width,
            height = bar_height,
            color = "#1e293b",
            child = render.Row(
                children = [
                    render.Box(
                        width = fill_width,
                        height = bar_height,
                        color = accent_color,
                    ),
                ],
            ),
        )
    else:
        stack_children = [
            render.Box(
                width = bar_outer_width,
                height = bar_height,
                color = "#1e293b",
            ),
        ]
        if fill_width > 0:
            stack_children.append(
                render.Box(
                    width = fill_width,
                    height = bar_height,
                    color = accent_color,
                ),
            )

        progress_bar = render.Stack(
            children = stack_children,
        )

    title_widget = render_smart_text(data["title"], font_title, WHITE, text_width, scale, scroll_mode)
    author_text = data.get("author") or "Audiobookshelf"
    author_widget = render_smart_text(author_text, font_tiny, MUTED, text_width, scale, scroll_mode)

    column_children = [
        title_widget,
        author_widget,
    ]

    # Chapter info on 2x only
    if scale == 2 and data.get("chapter"):
        chapter_color = ABS_GOLD if accent_color == WHITE else accent_color
        chapter_widget = render_smart_text(data["chapter"], font_tiny, chapter_color, text_width, scale, scroll_mode)
        column_children.append(chapter_widget)

    column_children.append(progress_bar)

    bottom_row = render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "space_between",
        children = [
            render.Text("%d%%" % progress_pct, font = font_tiny, color = accent_color),
            render.Text(time_display, font = font_tiny, color = MUTED),
        ],
    )
    column_children.append(bottom_row)

    text_column = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "start",
        children = column_children,
    )

    return render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Padding(
                pad = (1 * scale, 1 * scale, 2 * scale, 1 * scale),
                child = cover_widget,
            ),
            render.Padding(
                pad = (0, 1 * scale, 1 * scale, 1 * scale),
                child = text_column,
            ),
        ],
    )

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    font_title = "tb-8" if scale == 1 else "terminus-14"
    font_tiny = "tom-thumb" if scale == 1 else "tb-8"

    server_url = config.str("server_url", "")
    api_token = config.str("api_token", "")
    only_playing = config.bool("only_playing", False)
    bar_style = config.str("bar_style", "standard")
    color_scheme = config.str("color_scheme", "gold")
    time_mode = config.str("time_mode", "remaining")
    scroll_mode = config.str("scroll_mode", "scroll")

    if color_scheme == "custom":
        accent_color = parse_hex_color(config.str("custom_color", "#f59e0b"), ABS_GOLD)
    else:
        accent_color = COLOR_SCHEMES.get(color_scheme, ABS_GOLD)

    data = fetch_abs_progress(server_url, api_token)

    if not data:
        return render.Root(
            child = render.Box(
                width = width,
                height = height,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("No Audiobooks", font = font_title, color = MUTED),
                        render.Text("Check Server / Token", font = font_tiny, color = MUTED),
                    ],
                ),
            ),
        )

    # If only_playing is True and not actively playing, skip rendering
    if only_playing and not data.get("is_playing", False):
        return []

    cover_bytes = None
    if server_url and api_token:
        cover_bytes = fetch_cover_image(
            server_url,
            api_token,
            data.get("cover_path", ""),
            data.get("item_id", ""),
            target_width = 30 * scale,
        )

    cover_aspect = "square"
    if cover_bytes:
        detected = get_image_aspect(cover_bytes)
        if detected:
            cover_aspect = detected

    root_child = render_abs_view(
        scale,
        width,
        data,
        cover_bytes,
        font_title,
        font_tiny,
        cover_aspect = cover_aspect,
        bar_style = bar_style,
        accent_color = accent_color,
        time_mode = time_mode,
        scroll_mode = scroll_mode,
    )

    delay = 40 // scale
    return render.Root(
        delay = delay,
        child = render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = root_child,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "server_url",
                name = "Audiobookshelf URL",
                desc = "Host URL of your Audiobookshelf server",
                icon = "server",
                default = "http://localhost:13378",
            ),
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "User API token or Bearer token",
                icon = "key",
                secret = True,
            ),
            schema.Toggle(
                id = "only_playing",
                name = "Only Render If Playing",
                desc = "Only display when an audiobook is actively playing",
                icon = "play",
                default = False,
            ),
            schema.Dropdown(
                id = "scroll_mode",
                name = "Title Animation",
                desc = "Animation style for long titles and authors",
                icon = "film",
                default = "scroll",
                options = [
                    schema.Option(display = "Scroll (Marquee)", value = "scroll"),
                    schema.Option(display = "Static (No Animation)", value = "static"),
                ],
            ),
            schema.Dropdown(
                id = "bar_style",
                name = "Progress Bar Style",
                desc = "Style of the playback progress bar",
                icon = "sliders",
                default = "standard",
                options = [
                    schema.Option(display = "Standard (Left to Right)", value = "standard"),
                    schema.Option(display = "Centered (Expand from Center)", value = "centered"),
                ],
            ),
            schema.Dropdown(
                id = "color_scheme",
                name = "Color Scheme",
                desc = "Accent color for progress bar and highlights",
                icon = "palette",
                default = "gold",
                options = [
                    schema.Option(display = "ABS Gold", value = "gold"),
                    schema.Option(display = "Teal / Cyan", value = "teal"),
                    schema.Option(display = "Emerald Green", value = "green"),
                    schema.Option(display = "Purple", value = "purple"),
                    schema.Option(display = "Coral Red", value = "red"),
                    schema.Option(display = "Sky Blue", value = "blue"),
                    schema.Option(display = "White", value = "white"),
                    schema.Option(display = "Custom Hex Color", value = "custom"),
                ],
            ),
            schema.Text(
                id = "custom_color",
                name = "Custom Color Hex",
                desc = "Custom hex color code (e.g. #ff007f) when Custom is selected",
                icon = "brush",
                default = "#f59e0b",
            ),
            schema.Dropdown(
                id = "time_mode",
                name = "Time Display Mode",
                desc = "Format of time displayed at the bottom right",
                icon = "clock",
                default = "remaining",
                options = [
                    schema.Option(display = "Remaining Time (-2h26m)", value = "remaining"),
                    schema.Option(display = "Elapsed Time (1h30m)", value = "elapsed"),
                    schema.Option(display = "Total Duration (3h56m)", value = "total"),
                ],
            ),
        ],
    )
