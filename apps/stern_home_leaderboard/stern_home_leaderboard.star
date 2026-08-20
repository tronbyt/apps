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
    login_url = "https://insider.sternpinball.com/login"
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:142.0) Gecko/20100101 Firefox/142.0",
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
    token = ""

    # In Starlark, headers.get returns a single string.
    # For multiple Set-Cookie headers, they might be comma separated or we might only get the first one.
    # Pixlet's http library returns a single string for headers.get().
    # It usually joins them with commas. Let's handle both commas and semicolons.
    for part in cookies.replace(",", ";").split(";"):
        if "spb-insider-token=" in part:
            token = part.split("spb-insider-token=")[1]

    if not token:
        return None

    return {"token": token, "cookies": cookies}

def get_machines(auth):
    machines_url = "https://cms.prd.sternpinball.io/api/v1/portal/user_registered_machines/?group_type=home&_rsc=1"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Authorization": "Bearer " + auth["token"],
        "Cookie": auth["cookies"],
        "RSC": "1",
    }
    cache_key = "stern_machines_" + auth["token"]
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
    url = "https://cms.prd.sternpinball.io/api/v1/portal/game_machine_high_scores/?machine_id=" + clean_id + "&_rsc=1"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Authorization": "Bearer " + auth["token"],
        "Cookie": auth["cookies"],
        "RSC": "1",
    }
    cache_key = "stern_scores_" + clean_id
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

    # We will loop through the machines and append their high scores
    for m in machines:
        model_dict = m.get("model") or {}
        title_dict = model_dict.get("title") or {}
        logo_url = title_dict.get("variable_width_logo")
        machine_name = title_dict.get("name") or m.get("name") or "Unknown Game"

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
                        child = render.Text(format_score(score_val), font = FONT, color = "#0ff"),
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
