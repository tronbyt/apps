load("cache.star", "cache")
load("color.star", "color")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

def shuffle(items):
    res = []
    for item in items:
        res.append(item)

    n = len(res)
    if n < 2:
        return res

    for i in range(n - 1, 0, -1):
        j = random.number(0, i)
        tmp = res[i]
        res[i] = res[j]
        res[j] = tmp
    return res

def mid_color(c1, c2):
    col1 = color.hex(c1)
    col2 = color.hex(c2)

    r = (col1.r + col2.r) // 2
    g = (col1.g + col2.g) // 2
    b = (col1.b + col2.b) // 2

    return color.rgb(r, g, b).hex()

def clean_hex(h):
    if not h or not h.startswith("#"):
        return None
    valid = "0123456789abcdefABCDEF"
    res = "#"
    for i in range(1, len(h)):
        if h[i] in valid:
            res += h[i]
        else:
            break
    if len(res) == 4 or len(res) == 7 or len(res) == 9:
        return res
    return None

def extract_until_quote(games_body, start_idx):
    end1 = games_body.find('\\"', start_idx)
    end2 = games_body.find('"', start_idx)

    valid_ends = []
    if end1 != -1:
        valid_ends.append(end1)
    if end2 != -1:
        valid_ends.append(end2)

    if valid_ends:
        return games_body[start_idx:min(valid_ends)]
    return ""

def format_score(n):
    s = str(n)
    res = ""
    count = 0
    for i in range(len(s) - 1, -1, -1):
        if count == 3:
            res = "," + res
            count = 0
        res = s[i] + res
        count += 1
    return res

def login(username, password):
    login_url = "https://api.prd.sternpinball.io/api/v2/token/"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Content-Type": "application/json",
    }

    usernames_to_try = [username]
    if "@" in username:
        usernames_to_try.append(username.split("@")[0])

    for u in usernames_to_try:
        body = json.encode({"username": u, "password": password})
        rep = http.post(login_url, headers = headers, body = body)

        if rep.status_code == 200:
            data = rep.json()
            token = data.get("access") or data.get("access_token")
            if token:
                return {"token": token}

    return None

def get_user_id_from_token(token):
    parts = token.split(".")
    if len(parts) < 2:
        return None
    payload = parts[1].replace("-", "+").replace("_", "/")
    pad_len = (4 - (len(payload) % 4)) % 4
    payload += "=" * pad_len
    decoded = base64.decode(payload)
    if not decoded:
        return None
    data = json.decode(decoded)
    user_id = data.get("user_id")
    if user_id:
        return str(user_id)
    return None

def normalize_game_name(name):
    n = name.strip()
    if "Pokemon" in n or "Pokémon" in n:
        return "Pokémon"
    if "Stranger Things" in n:
        return "Stranger Things"
    if "Batman" in n and "66" in n:
        return "Batman '66"
    if "Elvira" in n:
        return "Elvira's House of Horrors"
    if "007" in n and "60th" in n:
        return "James Bond 007 60th Anniversary"
    if "007" in n:
        return "James Bond 007"
    if "Dungeons" in n and "Dragons" in n:
        return "Dungeons \\u0026 Dragons"
    return n.replace("&", "\\u0026")

def get_personal_scores(auth):
    # Use a chunk of token as cache key suffix
    cache_key = "stern_personal_scores_v10_" + auth["token"][:15]
    cached_data = cache.get(cache_key)
    if cached_data:
        return json.decode(cached_data)

    token = auth["token"]
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Authorization": "Bearer " + token,
    }

    user_id = get_user_id_from_token(token)

    # Fallback to user_registered_machines endpoint if user_id was not in token
    if not user_id:
        m_rep = http.get("https://api.prd.sternpinball.io/api/v1/portal/user_registered_machines/?group_type=home", headers = headers)
        if m_rep.status_code == 200:
            m_data = m_rep.json()
            user_id = str(m_data.get("user", {}).get("id", ""))

    if not user_id:
        return []

    # Map titles to model type from user registered home machines if available
    user_models_by_title = {}
    m_rep = http.get("https://api.prd.sternpinball.io/api/v1/portal/user_registered_machines/?group_type=home", headers = headers, ttl_seconds = 3600)
    if m_rep.status_code == 200:
        m_data = m_rep.json()
        machines = m_data.get("user", {}).get("machines", [])
        for m in machines:
            model_info = m.get("model") or {}
            m_type = model_info.get("type", "pro")
            title_info = model_info.get("title") or {}
            title_name = title_info.get("name", "")
            if title_name:
                user_models_by_title[title_name] = m_type.lower()

    # Fetch game titles list
    titles_url = "https://api.prd.sternpinball.io/api/v1/portal/game_titles/"
    titles_rep = http.get(titles_url, headers = headers, ttl_seconds = 86400)
    if titles_rep.status_code != 200:
        return []
    titles = titles_rep.json()

    # Fetch global games list to extract logo URLs
    games_url = "https://insider.sternpinball.com/games?_rsc=1"
    games_cache_key = "stern_games_metadata_html"
    games_body = cache.get(games_cache_key)
    if not games_body:
        g_rep = http.get(games_url, ttl_seconds = 86400)
        if g_rep.status_code == 200:
            games_body = g_rep.body()
            cache.set(games_cache_key, games_body, ttl_seconds = 86400)

    results = []
    for t in titles:
        game_name = t.get("name", "")
        pk = t.get("pk")
        if not pk:
            continue

        stat_url = "https://api.prd.sternpinball.io/api/v1/portal/user_title_stats/?user_id=" + user_id + "&title_id=" + str(pk)
        stat_rep = http.get(stat_url, headers = headers, ttl_seconds = 300)
        if stat_rep.status_code != 200:
            continue

        stat_data = stat_rep.json()
        max_score = stat_data.get("max_score", 0)
        if not max_score or max_score <= 0:
            continue

        percentile = stat_data.get("score_percentile")
        percent_str = ""
        if percentile != None and percentile > 0:
            top_pct = 100 - int(percentile)
            if top_pct <= 0:
                top_pct = 1
            percent_str = " (Top " + str(top_pct) + "%)"

        m_type = user_models_by_title.get(game_name, "best")

        search_name = normalize_game_name(game_name)

        logo_url = ""
        c1 = "#0aa"
        c2 = "#a0a"
        if games_body:
            idx = games_body.find('\\"name\\":\\"' + search_name + '\\"')
            if idx == -1:
                idx = games_body.find('"name":"' + search_name + '"')

            if idx > -1:
                g1_idx = games_body.find("gradient_start", idx, idx + 10000)
                if g1_idx > -1:
                    hex_start = games_body.find("#", g1_idx, g1_idx + 50)
                    if hex_start > -1:
                        c1_cand = extract_until_quote(games_body, hex_start)
                        c1_clean = clean_hex(c1_cand)
                        if c1_clean:
                            c1 = c1_clean

                g2_idx = games_body.find("gradient_stop", idx, idx + 10000)
                if g2_idx > -1:
                    hex_start = games_body.find("#", g2_idx, g2_idx + 50)
                    if hex_start > -1:
                        c2_cand = extract_until_quote(games_body, hex_start)
                        c2_clean = clean_hex(c2_cand)
                        if c2_clean:
                            c2 = c2_clean

                s_idx = games_body.find("variable_width_logo", idx, idx + 10000)
                if s_idx > -1:
                    http_start = games_body.find("http", s_idx, s_idx + 100)
                    if http_start > -1:
                        logo_url = extract_until_quote(games_body, http_start)

        game_scores = [{
            "model": m_type,
            "score": int(max_score),
            "percent": percent_str,
        }]

        results.append({
            "name": game_name,
            "logo": logo_url,
            "scores": game_scores,
            "c1": c1,
            "c2": c2,
            "mid_c": mid_color(c1, c2),
        })

    cache.set(cache_key, json.encode(results), ttl_seconds = 300)
    return results

def main(config):
    username = config.get("username")
    password = config.get("password")
    game_filter = config.get("game_filter", "all")
    highest_only = config.bool("highest_only")
    max_games = int(config.get("max_games", "3"))

    if not username or not password:
        return render.Root(
            child = render.WrappedText("Configure Stern username & password"),
        )

    auth = login(username, password)
    if not auth:
        return render.Root(
            child = render.WrappedText("Login failed. Check credentials."),
        )

    width = canvas.width()
    all_content = []

    personal_games = get_personal_scores(auth)
    if not personal_games:
        return render.Root(child = render.WrappedText("No personal scores found."))

    # Filter personal games
    if game_filter and game_filter != "all":
        filtered = []
        for g in personal_games:
            if game_filter.lower() in g["name"].lower():
                filtered.append(g)
        personal_games = filtered
    else:
        personal_games = shuffle(personal_games)

    personal_games = personal_games[:max_games]

    for g in personal_games:
        logo_url = g["logo"]
        machine_name = g["name"]
        scores = g["scores"]

        if highest_only and scores:
            highest = scores[0]
            for s in scores:
                if s["score"] > highest["score"]:
                    highest = s
            scores = [highest]

        banner_child = None
        if logo_url:
            logo_rep = http.get(logo_url, ttl_seconds = 3600)
            if logo_rep.status_code == 200:
                banner_child = render.Image(src = logo_rep.body(), width = canvas.width())

        if not banner_child:
            banner_child = render.Box(
                width = width,
                height = 26,
                child = render.WrappedText(
                    content = machine_name,
                    font = "tb-8",
                    align = "center",
                ),
            )

        all_content.append(banner_child)

        # Build personal score table
        score_rows = []
        for s in scores:
            model_color = "#666"
            if s["model"] == "pro":
                model_color = g["c1"]
            elif s["model"] == "premium":
                model_color = g.get("mid_c", "#666")
            elif s["model"] == "limited":
                model_color = g["c2"]

            score_children = [
                render.Text(content = s["model"].upper() + ": ", font = "tb-8", color = model_color),
                render.Text(content = format_score(s["score"]), font = "tb-8", color = "#fff"),
            ]
            if s["percent"]:
                score_children.append(render.Text(content = s["percent"], font = "tb-8", color = "#ff0"))
            score_children.append(render.Box(height = 2))

            score_rows.append(
                render.Column(
                    children = score_children,
                ),
            )
        all_content.append(render.Padding(pad = (4, 0, 4, 0), child = render.Column(children = score_rows)))
        all_content.append(render.Box(height = 8))

    # If no content, just skip
    if not all_content:
        return None
    print("Rendering total elements:", len(all_content))
    return render.Root(
        delay = 80,
        child = render.Marquee(
            height = canvas.height(),
            scroll_direction = "vertical",
            child = render.Column(children = all_content),
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
            schema.Toggle(
                id = "highest_only",
                name = "Highest Score Only",
                desc = "Only show your single highest score for each game",
                icon = "trophy",
                default = False,
            ),
            schema.Dropdown(
                id = "game_filter",
                name = "Game Filter",
                desc = "Select a specific game to display",
                icon = "gamepad",
                default = "all",
                options = [
                    schema.Option(display = "All", value = "all"),
                    schema.Option(display = "Aerosmith", value = "Aerosmith"),
                    schema.Option(display = "Avengers: Infinity Quest", value = "Avengers: Infinity Quest"),
                    schema.Option(display = "Batman '66", value = "Batman '66"),
                    schema.Option(display = "Black Knight: Sword of Rage", value = "Black Knight: Sword of Rage"),
                    schema.Option(display = "Deadpool", value = "Deadpool"),
                    schema.Option(display = "Dungeons & Dragons", value = "Dungeons & Dragons"),
                    schema.Option(display = "Elvira's House of Horrors", value = "Elvira's House of Horrors"),
                    schema.Option(display = "Foo Fighters", value = "Foo Fighters"),
                    schema.Option(display = "Godzilla", value = "Godzilla"),
                    schema.Option(display = "Guardians of the Galaxy", value = "Guardians of the Galaxy"),
                    schema.Option(display = "Iron Maiden", value = "Iron Maiden"),
                    schema.Option(display = "James Bond 007", value = "James Bond 007"),
                    schema.Option(display = "James Bond 007 60th Anniversary", value = "James Bond 007 60th Anniversary"),
                    schema.Option(display = "Jaws", value = "Jaws"),
                    schema.Option(display = "John Wick", value = "John Wick"),
                    schema.Option(display = "Jurassic Park", value = "Jurassic Park"),
                    schema.Option(display = "Jurassic Park Home Edition", value = "Jurassic Park Home Edition"),
                    schema.Option(display = "King Kong", value = "King Kong"),
                    schema.Option(display = "Led Zeppelin", value = "Led Zeppelin"),
                    schema.Option(display = "Metallica", value = "Metallica"),
                    schema.Option(display = "Pokémon", value = "Pokémon"),
                    schema.Option(display = "Rush", value = "Rush"),
                    schema.Option(display = "Star Wars", value = "Star Wars"),
                    schema.Option(display = "Star Wars Home Edition", value = "Star Wars Home Edition"),
                    schema.Option(display = "Star Wars: Fall of the Empire", value = "Star Wars: Fall of the Empire"),
                    schema.Option(display = "Stranger Things", value = "Stranger Things"),
                    schema.Option(display = "Teenage Mutant Ninja Turtles", value = "Teenage Mutant Ninja Turtles"),
                    schema.Option(display = "The Beatles", value = "The Beatles"),
                    schema.Option(display = "The Mandalorian", value = "The Mandalorian"),
                    schema.Option(display = "The Munsters", value = "The Munsters"),
                    schema.Option(display = "The Uncanny X-Men", value = "The Uncanny X-Men"),
                    schema.Option(display = "The Walking Dead: Remastered", value = "The Walking Dead: Remastered"),
                    schema.Option(display = "Venom", value = "Venom"),
                ],
            ),
            schema.Dropdown(
                id = "max_games",
                name = "Max Games",
                desc = "Maximum number of games to display",
                icon = "list",
                default = "3",
                options = [
                    schema.Option(display = "1", value = "1"),
                    schema.Option(display = "2", value = "2"),
                    schema.Option(display = "3", value = "3"),
                    schema.Option(display = "5", value = "5"),
                ],
            ),
        ],
    )
