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
RED = "#ff3333"
WHITE = "#ffffff"
MUTED = "#94a3b8"
BG_COLOR = "#000000"

SAMPLE_DATA = {
    "title": "The Way of Kings",
    "author": "Brandon Sanderson",
    "progress": 0.38,
    "current_time": 5400,
    "duration": 14200,
    "is_playing": True,
    "cover_path": "",
    "item_id": "",
}

def format_time(seconds):
    if seconds <= 0:
        return "0m"
    hours = int(seconds) // 3600
    minutes = (int(seconds) % 3600) // 60
    if hours > 0:
        return "%dh %dm" % (hours, minutes)
    return "%dm" % minutes

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
    duration = int(sess.get("duration", 0))
    current_time = int(sess.get("currentTime", 0))
    progress_val = float(current_time) / duration if duration > 0 else 0.0
    cover_path = sess.get("coverPath") or media_meta.get("coverPath") or ""

    result = {
        "title": title,
        "author": author,
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

def render_cover_fallback(scale, width, height, title):
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
                render.Box(width = spine_width, height = height, color = ABS_GOLD),
                render.Box(
                    width = width - spine_width,
                    height = height,
                    child = render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(initial, font = "tb-8" if scale == 1 else "terminus-14", color = ABS_GOLD),
                            render.Box(width = 8 * scale, height = 1 * scale, color = "#475569"),
                        ],
                    ),
                ),
            ],
        ),
    )

def render_abs_view(scale, width, data, cover_bytes, font_title, font_tiny):
    cover_width = 24 * scale
    cover_height = 30 * scale

    if cover_bytes:
        cover_widget = render.Image(
            src = cover_bytes,
            width = cover_width,
            height = cover_height,
        )
    else:
        cover_widget = render_cover_fallback(scale, cover_width, cover_height, data.get("title", ""))

    text_width = width - cover_width - (4 * scale)
    progress_pct = int(data["progress"] * 100)
    time_left = data["duration"] - data["current_time"]
    time_display = format_time(time_left) + " left" if time_left > 0 else format_time(data["current_time"])

    bar_outer_width = text_width
    bar_height = 3 * scale
    fill_width = int(bar_outer_width * data["progress"])
    if fill_width < 1 and data["progress"] > 0:
        fill_width = 1
    if fill_width > bar_outer_width:
        fill_width = bar_outer_width

    progress_bar = render.Box(
        width = bar_outer_width,
        height = bar_height,
        color = "#1e293b",
        child = render.Row(
            children = [
                render.Box(
                    width = fill_width,
                    height = bar_height,
                    color = ABS_GOLD,
                ),
            ],
        ),
    )

    text_column = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "start",
        children = [
            render.Marquee(
                width = text_width,
                child = render.Text(data["title"], font = font_title, color = WHITE),
            ),
            render.Marquee(
                width = text_width,
                child = render.Text(data["author"] if data["author"] else "Audiobookshelf", font = font_tiny, color = MUTED),
            ),
            progress_bar,
            render.Row(
                expanded = True,
                cross_align = "center",
                main_align = "space_between",
                children = [
                    render.Text("%d%%" % progress_pct, font = font_tiny, color = ABS_GOLD),
                    render.Text(time_display, font = font_tiny, color = MUTED),
                ],
            ),
        ],
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
            target_width = 24 * scale,
        )

    root_child = render_abs_view(
        scale,
        width,
        data,
        cover_bytes,
        font_title,
        font_tiny,
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
        ],
    )
