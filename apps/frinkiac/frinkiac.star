"""
Applet: Frinkiac
Summary: Random Simpsons frames
Description: Shows random stills or animations from the Frinkiac archive with season and movie filtering.
Author: radiocolin
"""

load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

IMAGE_URL_BASE = "https://frinkiac.com/img/%s/%d.jpg"
FRAMES_URL_BASE = "https://frinkiac.com/api/frames/%s/%d/%d/%d"
CAPTION_URL_BASE = "https://frinkiac.com/api/caption?e=%s&t=%d"

# Episode counts for Seasons 1-17
EPISODE_COUNTS = {
    1: 13,
    2: 22,
    3: 24,
    4: 22,
    5: 22,
    6: 25,
    7: 25,
    8: 25,
    9: 25,
    10: 23,
    11: 22,
    12: 21,
    13: 22,
    14: 22,
    15: 22,
    16: 21,
    17: 22,
}

# Cache for 24 hours (86400 seconds)
CACHE_TTL = 86400

def main(config):
    # 1. Configuration
    min_s = int(config.get("min_season", "1"))
    max_s = int(config.get("max_season", "17"))
    include_movie = config.bool("include_movie", True)
    animate = config.bool("animate", False)

    # Range validation
    if min_s > max_s:
        min_s, max_s = max_s, min_s

    frame = None

    # 2. THE METHOD: Discovery via /api/frames
    for _ in range(15):
        range_size = (max_s - min_s + 1)
        if include_movie and random.number(1, range_size + 1) == 1:
            ep_code = "Movie"
            anchor_ts = random.number(60000, 5000000)
        else:
            s_pick = random.number(min_s, max_s)
            e_max = EPISODE_COUNTS.get(s_pick, 22)
            e_pick = random.number(1, e_max)
            s_str = str(s_pick) if s_pick >= 10 else "0" + str(s_pick)
            e_str = str(e_pick) if e_pick >= 10 else "0" + str(e_pick)
            ep_code = "S%sE%s" % (s_str, e_str)
            anchor_ts = random.number(60000, 1200000)

        res = http.get(FRAMES_URL_BASE % (ep_code, anchor_ts, 30000, 30000), ttl_seconds = CACHE_TTL)
        if res.status_code == 200:
            frames_in_window = res.json()
            if len(frames_in_window) > 0:
                frame = frames_in_window[random.number(0, len(frames_in_window) - 1)]
                break

    if not frame:
        return []

    episode_code = frame.get("Episode")
    timestamp = int(frame.get("Timestamp"))
    is_movie = episode_code.lower() == "movie"

    # 3. Layout & Sizing
    width = canvas.width()
    height = canvas.height()

    if is_movie:
        img_w = width
        text_w = 0
    else:
        img_w = int((4.0 / 3.0) * height)
        text_w = width - img_w

    # 4. Animate Logic
    if animate:
        frames_res = http.get(FRAMES_URL_BASE % (episode_code, timestamp, 0, 15000), ttl_seconds = CACHE_TTL)
        if frames_res.status_code == 200:
            frames_data = frames_res.json()
            image_frames = []

            total_available = len(frames_data)
            limit = 45
            step = total_available // limit if total_available > limit else 1
            if step < 1:
                step = 1

            count = 0
            for i in range(0, total_available, step):
                if count >= limit:
                    break
                f_item = frames_data[i]
                f_img_res = http.get(IMAGE_URL_BASE % (f_item.get("Episode"), int(f_item.get("Timestamp"))), ttl_seconds = CACHE_TTL)
                if f_img_res.status_code == 200:
                    image_frames.append(render.Image(src = f_img_res.body(), width = img_w, height = height))
                    count += 1

            if len(image_frames) > 0:
                actual_delay = 15000 // len(image_frames)
                children = [render.Animation(children = image_frames)]
                if not is_movie:
                    children.append(render_sidebar(episode_code, canvas.is2x(), text_w, height))

                return render.Root(
                    delay = actual_delay,
                    child = render.Row(expanded = True, children = children),
                )

    # 5. Static Render
    img_res = http.get(IMAGE_URL_BASE % (episode_code, timestamp), ttl_seconds = CACHE_TTL)
    if img_res.status_code != 200:
        return []

    children = [render.Image(src = img_res.body(), width = img_w, height = height)]
    if not is_movie:
        children.append(render_sidebar(episode_code, canvas.is2x(), text_w, height))

    return render.Root(
        child = render.Row(expanded = True, children = children),
    )

def render_sidebar(ep_code, is_2x, width, height):
    s_val = ep_code[1:ep_code.find("E")].lstrip("0") or "0"
    e_val = ep_code[ep_code.find("E") + 1:].lstrip("0") or "0"

    meta_children = []
    if is_2x:
        meta_children.append(render.Text("Season", color = "#ffcc33", font = "tb-8"))
        meta_children.append(render.Text(s_val, color = "#ffffff", font = "tb-8"))
        meta_children.append(render.Box(height = 2, width = 1))
        meta_children.append(render.Text("Ep", color = "#ffcc33", font = "tb-8"))
        meta_children.append(render.Text(e_val, color = "#ffffff", font = "tb-8"))
    else:
        meta_children.append(render.Text("S" + s_val, color = "#ffcc33", font = "CG-pixel-3x5-mono"))
        meta_children.append(render.Text("E" + e_val, color = "#ffffff", font = "CG-pixel-3x5-mono"))

    return render.Box(
        width = width,
        height = height,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = meta_children,
        ),
    )

def get_schema():
    season_options = [
        schema.Option(display = str(s), value = str(s))
        for s in range(1, 18)
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "min_season",
                name = "Min Season",
                desc = "Minimum season to include.",
                icon = "arrowUp",
                default = season_options[0].value,
                options = season_options,
            ),
            schema.Dropdown(
                id = "max_season",
                name = "Max Season",
                desc = "Maximum season to include.",
                icon = "arrowDown",
                default = season_options[-1].value,
                options = season_options,
            ),
            schema.Toggle(id = "include_movie", name = "Include Movie", desc = "Include movie", icon = "film", default = True),
            schema.Toggle(id = "animate", name = "Animate", desc = "15s animation", icon = "video", default = False),
        ],
    )
