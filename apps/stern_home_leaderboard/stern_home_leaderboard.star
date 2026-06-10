load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

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
    body = json.encode({"username": username, "password": password})
    rep = http.post(login_url, headers = headers, body = body)

    if rep.status_code != 200:
        print("Login failed! Status Code: " + str(rep.status_code))
        print("Response Body: " + rep.body())
        return None

    data = rep.json()
    token = data.get("access") or data.get("access_token")

    if not token:
        return None

    return {"token": token}

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

def get_machines(auth):
    machines_url = "https://api.prd.sternpinball.io/api/v1/portal/user_registered_machines/?group_type=home"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Authorization": "Bearer " + auth["token"],
    }
    cache_key = "stern_machines_v2_" + auth["token"][:15]
    cached_data = cache.get(cache_key)
    if cached_data:
        return json.decode(cached_data)

    rep = http.get(machines_url, headers = headers)
    if rep.status_code != 200:
        print("Error fetching machines. Status code:", rep.status_code)
        return []
    data = rep.json()
    if "user" in data and "machines" in data["user"]:
        machines = data["user"]["machines"]
        cache.set(cache_key, json.encode(machines), ttl_seconds = 300)
        return machines
    return []

def get_high_scores(auth, machine_id):
    clean_id = str(machine_id).split(".")[0]
    url = "https://api.prd.sternpinball.io/api/v1/portal/game_machine_high_scores/?machine_id=" + clean_id
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Authorization": "Bearer " + auth["token"],
    }
    cache_key = "stern_scores_v2_" + clean_id
    cached_data = cache.get(cache_key)
    if cached_data:
        return json.decode(cached_data)

    rep = http.get(url, headers = headers)
    if rep.status_code != 200:
        print("Error fetching high scores for machine", machine_id, ". Status code:", rep.status_code)
        return []
    data = rep.json()
    if "high_score" in data:
        scores = data["high_score"]
        cache.set(cache_key, json.encode(scores), ttl_seconds = 300)
        return scores
    return []

def main(config):
    username = config.get("username")
    password = config.get("password")
    game_filter = config.get("game_filter", "")

    SCALE = 2 if canvas.is2x() else 1
    FONT = "terminus-16" if canvas.is2x() else "tb-8"
    SMALL_FONT = "tb-8" if canvas.is2x() else "tom-thumb"

    if not username or not password:
        return render.Root(
            child = render.WrappedText("Configure Stern username & password", font = FONT),
        )

    auth = login(username, password)
    if not auth:
        return render.Root(
            child = render.WrappedText("Login failed. Check credentials.", font = FONT),
        )

    machines = get_machines(auth)
    if not machines:
        return render.Root(
            child = render.WrappedText("No machines found.", font = FONT),
        )

    # filter machines
    if game_filter:
        filtered = []
        for m in machines:
            model_dict = m.get("model") or {}
            title_dict = model_dict.get("title") or {}
            name = title_dict.get("name") or ""
            if game_filter.lower() in name.lower():
                filtered.append(m)
        if filtered:
            machines = filtered

    all_content = []

    # Fetch global games list to extract logo URLs
    games_url = "https://insider.sternpinball.com/games?_rsc=1"
    games_cache_key = "stern_games_metadata_html"
    games_body = cache.get(games_cache_key)
    if not games_body:
        g_rep = http.get(games_url, ttl_seconds = 86400)
        if g_rep.status_code == 200:
            games_body = g_rep.body()
            cache.set(games_cache_key, games_body, ttl_seconds = 86400)

    # We will loop through the machines and append their high scores
    for m in machines:
        model_dict = m.get("model") or {}
        title_dict = model_dict.get("title") or {}
        machine_name = title_dict.get("name") or m.get("name") or "Unknown Game"

        logo_url = ""
        if games_body:
            idx = games_body.find('\\"name\\":\\"' + machine_name + '\\"')
            if idx == -1:
                idx = games_body.find('"name":"' + machine_name + '"')

            if idx > -1:
                s_idx = games_body.find("variable_width_logo", idx, idx + 5000)
                if s_idx > -1:
                    http_start = games_body.find("http", s_idx, s_idx + 100)
                    if http_start > -1:
                        logo_url = extract_until_quote(games_body, http_start)

        scores = get_high_scores(auth, m["id"])

        banner_child = None
        if logo_url:
            logo_rep = http.get(logo_url, ttl_seconds = 3600)
            if logo_rep.status_code == 200:
                banner_child = render.Image(src = logo_rep.body(), width = canvas.width())

        if not banner_child:
            banner_child = render.Text(machine_name, font = FONT, color = "#ff0")

        print("Added machine banner for:", machine_name)

        # Machine title banner
        all_content.append(banner_child)

        if not scores:
            all_content.append(render.Text("No scores yet", font = SMALL_FONT))
        else:
            for i, s in enumerate(scores):
                user = s.get("user") or {}
                player = user.get("username") or user.get("name") or user.get("initials") or "UNK"
                score_val = s.get("score", 0)
                rank = "GC" if i == 0 else str(i)

                # Colors based on rank
                rank_color = "#fff"
                if i == 0:
                    rank_color = "#f0f"
                elif i == 1:
                    rank_color = "#f00"
                elif i == 2:
                    rank_color = "#f80"

                print("Appending score row for:", player, score_val)

                all_content.append(
                    render.Row(
                        children = [
                            render.Text("%s: " % rank, font = FONT, color = rank_color),
                            render.Text(player[:10], font = FONT, color = "#fff"),
                        ],
                    ),
                )
                all_content.append(
                    render.Padding(
                        pad = (4 * SCALE, 0, 0, 6 * SCALE),
                        child = render.Text(format_score(int(float(score_val))), font = FONT, color = "#0ff"),
                    ),
                )

        # Add spacing between machines
        all_content.append(render.Box(width = canvas.width(), height = 6 * SCALE, color = "#000"))

    # If no content, just skip
    if not all_content:
        print("all_content is empty!")
        return None

    print("Rendering total elements:", len(all_content))
    return render.Root(
        delay = 80 // SCALE,
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
            schema.Text(
                id = "game_filter",
                name = "Game Filter (Optional)",
                desc = "Filter to a specific game by name or model",
                icon = "magnifyingGlass",
            ),
        ],
    )
