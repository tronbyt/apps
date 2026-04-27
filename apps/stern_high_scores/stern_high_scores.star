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

def get_personal_scores(auth):
    url = "https://insider.sternpinball.com/trophy-room/scores"
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Cookie": auth["cookies"],
        "RSC": "1",
    }
    rep = http.get(url, headers = headers, ttl_seconds = 300)
    if rep.status_code != 200:
        return []

    body = rep.body()
    results = []
    curr_pos = 0

    # Max 50 games to avoid timeout
    for _ in range(50):
        idx = body.find('"alt":"', curr_pos)
        if idx == -1:
            break

        # Extract game name
        start = idx + len('"alt":"')
        end = body.find('"', start)
        game_name = body[start:end]

        # Extract logo src (search backwards from idx for variable_width_logo or src)
        # We limit search to avoid picking up previous games
        search_start = idx - 500
        if search_start < 0:
            search_start = 0
        src_idx = body.rfind('"variable_width_logo":"', search_start, idx)
        if src_idx == -1:
            src_idx = body.rfind('"src":"', search_start, idx)

        logo_url = ""
        if src_idx != -1:
            # Determine which key we found
            key = '"variable_width_logo":"'
            if body[src_idx:src_idx + len('"src":"')] == '"src":"':
                key = '"src":"'

            s_start = src_idx + len(key)
            s_end = body.find('"', s_start)
            logo_url = body[s_start:s_end]

        # Extract scores in this block (until next alt)
        next_alt = body.find('"alt":"', end)
        if next_alt == -1:
            next_alt = len(body)

        game_scores = []
        score_pos = end
        for _ in range(5):  # Max 5 models per game
            s_idx = body.find('"stats":', score_pos, next_alt)
            if s_idx == -1:
                break

            # Find title
            t_idx = body.rfind('"title":"', score_pos, s_idx)
            title = "Score"
            if t_idx != -1:
                t_start = t_idx + len('"title":"')
                t_end = body.find('"', t_start)
                title = body[t_start:t_end]

            # Find stats value
            st_start = s_idx + len('"stats":')
            st_end = body.find(",", st_start)
            if st_end == -1 or st_end > body.find("}", st_start):
                st_end = body.find("}", st_start)
            stats_val = body[st_start:st_end]

            # Find percentageStats
            p_idx = body.find('"percentageStats":"', st_end, next_alt)
            percent = ""
            if p_idx != -1:
                # Ensure percentageStats belongs to THIS score by checking it's before next stats
                next_stats = body.find('"stats":', st_end, next_alt)
                if next_stats == -1 or p_idx < next_stats:
                    p_start = p_idx + len('"percentageStats":"')
                    p_end = body.find('"', p_start)
                    percent = body[p_start:p_end]

            if stats_val.isdigit():
                game_scores.append({
                    "model": title,
                    "score": int(stats_val),
                    "percent": percent,
                })
            score_pos = st_end

        if game_scores:
            # Sort scores: Pro, Premium, Limited
            ordered_scores = []
            for m_type in ["pro", "premium", "limited"]:
                for s in game_scores:
                    if s["model"].lower() == m_type:
                        ordered_scores.append(s)

            # Add any that didn't match (e.g. "LE", "Home Edition", etc.)
            for s in game_scores:
                match = False
                for m_type in ["pro", "premium", "limited"]:
                    if s["model"].lower() == m_type:
                        match = True
                        break
                if not match:
                    ordered_scores.append(s)

            results.append({
                "name": game_name,
                "logo": logo_url,
                "scores": ordered_scores,
            })

        curr_pos = next_alt

    return results

def main(config):
    username = config.get("username")
    password = config.get("password")
    game_filter = config.get("game_filter", "all")
    highest_only = config.bool("highest_only")

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
            score_children = [
                render.Text(content = s["model"].upper(), font = "tb-8", color = "#666"),
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
            schema.Dropdown(
                id = "display_mode",
                name = "Display Mode",
                desc = "Show your machine's leaderboards or your personal top scores",
                icon = "list",
                default = "machine",
                options = [
                    schema.Option(display = "Machine Leaderboards", value = "machine"),
                    schema.Option(display = "My Top Scores", value = "personal"),
                ],
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
        ],
    )
