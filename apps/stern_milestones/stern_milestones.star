load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

CACHE_TTL = 43200  # 12 hours

def login(username, password):
    login_url = "https://api.prd.sternpinball.io/api/v2/token/"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Content-Type": "application/json",
    }
    body = json.encode({"username": username, "password": password})
    rep = http.post(login_url, headers = headers, body = body)

    if rep.status_code != 200:
        print("Login failed! Status Code: " + str(rep.status_code))
        print("Response Body: " + rep.body())
        return None

    data = rep.json()
    return data.get("access") or data.get("access_token")

def main(config):
    username = config.get("username")
    password = config.get("password")

    if not username or not password:
        return render.Root(
            child = render.WrappedText("Configure Stern username & password"),
        )

    # Check cache for stats and icon URLs first
    cache_key = "stern_milestones_data_v3_" + username
    cached_data = cache.get(cache_key)
    extracted_data = None
    if cached_data:
        extracted_data = json.decode(cached_data)

    if not extracted_data:
        token = login(username, password)
        if not token:
            return render.Root(
                child = render.WrappedText("Login failed. Check credentials."),
            )

        url = "https://api.prd.sternpinball.io/api/v1/portal/user_stats/"
        headers = {
            "User-Agent": "Mozilla/5.0",
            "Authorization": "Bearer " + token,
        }

        rep = http.get(url, headers = headers)
        if rep.status_code != 200:
            return render.Root(child = render.WrappedText("Failed to fetch dashboard."))

        stats_data = rep.json().get("stats", {})
        stats = {
            "games": int(stats_data.get("total_plays", 0)),
            "streak": int(stats_data.get("consecutive_days_played", 0)),
            "max_streak": int(stats_data.get("max_consecutive_days_played", 0)),
            "days": int(stats_data.get("days_played", 0)),
        }

        extracted_data = {
            "stats": stats,
            "icons": {
                "games": "https://stern-static-prod.s3.amazonaws.com/stern-assets/badges/Games-Played-Badge-Active.png",
                "days": "https://stern-static-prod.s3.amazonaws.com/stern-assets/badges/Days-Played-Badge.png",
                "streak": "https://stern-static-prod.s3.amazonaws.com/stern-assets/badges/Game-Streak-Badge.png",
            },
        }

        # Cache only the small extracted data
        cache.set(cache_key, json.encode(extracted_data), ttl_seconds = CACHE_TTL)

    stats = extracted_data["stats"]
    icon_urls = extracted_data["icons"]

    SCALE = 2 if canvas.is2x() else 1

    badge_cats = [
        ("Games-Played-Badge", "Games", "games"),
        ("Days-Played-Badge", "Days", "days"),
        ("Game-Streak-Badge", "Streak", "streak"),
    ]

    badge_widgets = []
    box_height = 20 * SCALE
    top_stat_pad = 4 * SCALE

    for _, cat_short, stat_key in badge_cats:
        icon_url = icon_urls.get(stat_key)
        display_val = stats.get(stat_key, "N/A")

        icon_widget = render.Box(width = 20 * SCALE, height = 20 * SCALE, color = "#333")
        if icon_url:
            img_rep = http.get(icon_url, ttl_seconds = CACHE_TTL)
            if img_rep.status_code == 200:
                icon_widget = render.Image(src = img_rep.body(), width = 20 * SCALE, height = 20 * SCALE)

        # For streak, stack current and max if available
        is_streak = stat_key == "streak" and stats.get("max_streak")
        stat_contents = []

        stat_contents = [
            render.Padding(
                pad = (1 * SCALE, top_stat_pad, 0, 0),
                child = render.Text(
                    content = str(display_val),
                    color = "#fff",
                    font = "tom-thumb" if not canvas.is2x() else "terminus-12",
                ),
            ),
        ]
        if is_streak:
            stat_contents.append(
                render.Padding(
                    pad = (1 * SCALE, 0, 0, 0),
                    child = render.Text(
                        content = str(stats.get("max_streak")),
                        color = "#f0f0f0",
                        font = "tom-thumb" if not canvas.is2x() else "terminus-12",
                    ),
                ),
            )

        badge_widgets.append(
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Stack(
                        children = [
                            icon_widget,
                            render.Box(
                                width = 20 * SCALE,
                                height = box_height,
                                child = render.Column(
                                    expanded = True,
                                    main_align = "start",
                                    cross_align = "center",
                                    children = stat_contents,
                                ),
                            ),
                        ],
                    ),
                    render.Text(
                        content = cat_short,
                        font = "tom-thumb" if not canvas.is2x() else "terminus-12",
                        color = "#aaa",
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Padding(
            pad = (2, SCALE, 0, 0),
            child = render.Row(
                expanded = True,
                main_align = "space_around",
                children = badge_widgets,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Stern Username",
                desc = "Your Stern Insider Connected username",
                icon = "user",
            ),
            schema.Text(
                id = "password",
                name = "Stern Password",
                desc = "Your Stern Insider Connected password",
                icon = "lock",
                secret = True,
            ),
        ],
    )
