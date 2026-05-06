load("api.star", "fetch_icon", "fetch_server_data")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("games.star", "GAME_ICONS", "GAME_MIDDLE_RENDERERS")
load("render.star", "render")
load("schema.star", "schema")
load("utils.star", "truncate")

def render_missing_server_id():
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text("BattleMetrics", font = "tb-8", color = "#ffffff"),
                render.Box(height = 4),
                render.Text("MISSING", font = "tb-8", color = "#ff3333"),
                render.Text("SERVER ID", font = "tb-8", color = "#ff3333"),
            ],
        ),
    )

def render_middle_default(_server):
    return render.Row(children = [])

def render_middle(server):
    renderer = GAME_MIDDLE_RENDERERS.get(server["game_id"], render_middle_default)
    return renderer(server)

def render_title(name, use_marquee):
    if not use_marquee:
        return render.Box(
            width = 64,
            height = 8,
            child = render.Text(truncate(name), font = "tb-8", color = "#ffffff"),
        )

    text = render.Text(name, font = "tb-8", color = "#ffffff")
    cw, _ch = text.size()

    if cw <= 64:
        return render.Box(width = 64, height = 8, child = text)

    # Scroll until text end aligns with the right edge of the viewport, then hold.
    # offset_end=128 makes FrameCount = cw+17 (with delay=80), so the last scroll
    # frame lands at offset -(cw-64) — text end exactly at pixel 64.
    DELAY_FRAMES = 50
    HOLD_FRAMES = 30

    scroll_part = render.Marquee(
        width = 64,
        offset_end = 128,
        delay = DELAY_FRAMES,
        child = text,
    )

    # Negative left pad shifts text left so its right end aligns with x=64.
    hold_frame = render.Box(
        width = 64,
        height = 8,
        child = render.Padding(
            child = text,
            pad = (64 - cw, 0, 0, 0),
        ),
    )

    return render.Box(
        width = 64,
        height = 8,
        child = render.Sequence(
            children = [
                scroll_part,
                render.Animation(children = [hold_frame] * HOLD_FRAMES),
            ],
        ),
    )

def render_bottom(status, players, max_players, icon_bytes):
    icon = render.Image(src = icon_bytes, width = 8, height = 8) if icon_bytes != None else render.Box(width = 8, height = 8)
    dot_color = "#00ff55" if status == "online" else "#ff3333"
    players_str = str(players) if players < 10000 else str(int(players / 1000)) + "k"
    max_players_str = str(max_players) if max_players < 10000 else str(int(max_players / 1000)) + "k"
    return render.Row(
        cross_align = "end",
        children = [
            icon,
            render.Row(
                expanded = True,
                main_align = "end",
                cross_align = "center",
                children = [
                    render.Circle(color = dot_color, diameter = 5),
                    render.Box(width = 3, height = 1),
                    render.Text(players_str + "/" + max_players_str, font = "tom-thumb", height = 6, color = "#ffffff"),
                ],
            ),
        ],
    )

def render_error_state(name, icon_bytes):
    icon = render.Image(src = icon_bytes, width = 8, height = 8) if icon_bytes != None else render.Box(width = 8, height = 8)
    return render.Root(
        max_age = 60,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Box(
                    width = 64,
                    height = 8,
                    child = render.Text(truncate(name), font = "tb-8", color = "#ffffff"),
                ),
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [
                        render.Text("== API ERROR ==", font = "tom-thumb", color = "#ff3333"),
                    ],
                ),
                render.Row(
                    expanded = True,
                    cross_align = "end",
                    main_align = "space_between",
                    children = [icon, render.Box(width = 1, height = 8)],
                ),
            ],
        ),
    )

def main(config):
    server_id = config.get("server_id")
    if not server_id:
        return render_missing_server_id()

    use_marquee = config.bool("title_marquee")

    custom_title = config.get("custom_title") or ""

    server = fetch_server_data(server_id)
    if server == None:
        fallback_json = cache.get("bm_fallback_" + server_id)
        if fallback_json != None:
            fallback = json.decode(fallback_json)
            name = fallback["name"]
            game_id = fallback["game_id"]
        else:
            name = "Unknown"
            game_id = None
        icon_bytes = fetch_icon(GAME_ICONS.get(game_id)) if game_id != None else None
        return render_error_state(custom_title if custom_title != "" else name, icon_bytes)

    icon_bytes = fetch_icon(GAME_ICONS.get(server["game_id"]))
    display_name = custom_title if custom_title != "" else server["name"]

    return render.Root(
        max_age = 600,
        child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render_title(display_name, use_marquee),
                render_middle(server),
                render_bottom(server["status"], server["players"], server["max_players"], icon_bytes),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "server_id",
                name = "Server ID",
                desc = "BattleMetrics server ID",
                icon = "server",
            ),
            schema.Text(
                id = "custom_title",
                name = "Custom title",
                desc = "Override the server name shown on the display",
                icon = "tag",
            ),
            schema.Toggle(
                id = "title_marquee",
                name = "Scroll title",
                desc = "Scroll the server name instead of truncating it",
                icon = "arrowsLeftRight",
                default = True,
            ),
        ],
    )
