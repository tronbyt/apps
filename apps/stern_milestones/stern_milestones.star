load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

CACHE_TTL = 43200  # 12 hours

def login(username, password):
    login_url = "https://insider.sternpinball.com/login"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Accept": "text/x-component",
        "Next-Action": "9d2cf818afff9e2c69368771b521d93585a10433",
        "Content-Type": "text/plain;charset=UTF-8",
        "Origin": "https://insider.sternpinball.com",
    }
    body = json.encode([username, password])
    rep = http.post(login_url, headers = headers, body = body)

    if rep.status_code != 200:
        return None

    cookies = rep.headers.get("Set-Cookie", "")
    return cookies

def extract_stats(body):
    stats = {}

    # Use both escaped and unescaped keys for compatibility
    keys = {
        '"games_played"': "games",
        '"consecutive_days_played"': "streak",
        '"days_played"': "days",
        '\\"games_played\\"': "games",
        '\\"consecutive_days_played\\"': "streak",
        '\\"days_played\\"': "days",
    }

    for key, stat_name in keys.items():
        idx = body.find(key)
        if idx != -1:
            colon_idx = body.find(":", idx)
            if colon_idx != -1:
                start = colon_idx + 1

                # Find start of digits
                for i in range(20):
                    if start + i < len(body):
                        if body[start + i].isdigit():
                            start = start + i
                            break

                # Find end of digits
                end = start
                for i in range(20):
                    if start + i < len(body):
                        if not body[start + i].isdigit():
                            end = start + i
                            break
                        else:
                            end = start + i + 1

                val = body[start:end]
                if val:
                    stats[stat_name] = val
    return stats

def extract_icon(body, pattern):
    idx = body.find(pattern)
    if idx == -1:
        return None

    # Find the URL start (search backwards for https:)
    url_start = body.rfind("https:", 0, idx)
    if url_start == -1:
        return None

    # Find the URL end (search forwards for ")
    url_end = body.find('"', idx)
    if url_end == -1:
        return None
    url = body[url_start:url_end]

    # Strip potential trailing backslash if it was escaped \"
    if url.endswith("\\"):
        url = url[:-1]
    return url.replace("\\u0026", "&").replace("\\/", "/")

def main(config):
    username = config.get("username")
    password = config.get("password")

    if not username or not password:
        return render.Root(
            child = render.WrappedText("Configure Stern username & password"),
        )

    # Check cache for stats and icon URLs first
    cache_key = "stern_milestones_data_" + username
    cached_data = cache.get(cache_key)
    extracted_data = None
    if cached_data:
        extracted_data = json.decode(cached_data)

    if not extracted_data:
        cookies = login(username, password)
        if not cookies:
            return render.Root(
                child = render.WrappedText("Login failed. Check credentials."),
            )

        # Fetch dashboard (contains both stats and icon URLs)
        url = "https://insider.sternpinball.com/insider?_rsc=1"
        headers = {
            "User-Agent": "Mozilla/5.0",
            "Cookie": cookies,
            "RSC": "1",
        }

        # Fetch without ttl_seconds to avoid large body serialization issues
        rep = http.get(url, headers = headers)
        if rep.status_code != 200:
            return render.Root(child = render.WrappedText("Failed to fetch dashboard."))

        body = rep.body()
        stats = extract_stats(body)

        badge_cats = [
            ("Games-Played-Badge", "Games", "games"),
            ("Days-Played-Badge", "Days", "days"),
            ("Game-Streak-Badge", "Streak", "streak"),
        ]

        extracted_data = {
            "stats": stats,
            "icons": {},
        }

        for pattern, _, stat_key in badge_cats:
            icon_url = extract_icon(body, pattern)
            if icon_url:
                extracted_data["icons"][stat_key] = icon_url

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

    for _, cat_short, stat_key in badge_cats:
        icon_url = icon_urls.get(stat_key)
        display_val = stats.get(stat_key, "N/A")

        icon_widget = render.Box(width = 20 * SCALE, height = 20 * SCALE, color = "#333")
        if icon_url:
            img_rep = http.get(icon_url, ttl_seconds = CACHE_TTL)
            if img_rep.status_code == 200:
                icon_widget = render.Image(src = img_rep.body(), width = 20 * SCALE, height = 20 * SCALE)

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
                                height = 12 * SCALE,
                                child = render.Column(
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        render.Padding(
                                            pad = (1 * SCALE, 1 * SCALE, 0, 0),  # Micro-adjust for hex center
                                            child = render.Text(
                                                content = str(display_val),
                                                font = "tom-thumb" if not canvas.is2x() else "terminus-12",
                                                color = "#fff",
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                    render.Text(content = cat_short, font = "tom-thumb", color = "#aaa"),
                ],
            ),
        )

    return render.Root(
        child = render.Padding(
            pad = (2, 2 * SCALE, 0, 0),
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
