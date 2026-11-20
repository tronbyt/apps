load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

PROJECT_ID = "P3HEU9eRz5zrjI8c28n88adIDzyI"
AUTH_HOST = "https://auth.sternpinball.com"
REDIRECT_URI = "https://insider.sternpinball.com/auth/callback"
B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

def hex_to_b64url(hex_str):
    res = []
    for k in range(10):
        chunk = hex_str[k * 6:(k + 1) * 6]
        n = int(chunk, 16)
        res.append(B64_CHARS[(n >> 18) & 63])
        res.append(B64_CHARS[(n >> 12) & 63])
        res.append(B64_CHARS[(n >> 6) & 63])
        res.append(B64_CHARS[n & 63])
    last_chunk = hex_str[60:64]
    last_n = int(last_chunk, 16)
    res.append(B64_CHARS[(last_n >> 10) & 63])
    res.append(B64_CHARS[(last_n >> 4) & 63])
    res.append(B64_CHARS[(last_n << 2) & 63])
    return "".join(res)

def extract_query_param(url, param_name):
    target = param_name + "="
    s = url.find(target)
    if s == -1:
        return ""
    s += len(target)
    val = []
    for i in range(s, len(url)):
        ch = url[i]
        if ch == "&" or ch == "#":
            break
        val.append(ch)
    return "".join(val)

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
    token_cache_key = "stern_descope_token_v1_" + hash.sha256(username + ":" + password)[:16]
    cached_token = cache.get(token_cache_key)
    if cached_token:
        return {"token": cached_token}

    verifier = "pixlet_starlark_descope_login_verifier_12345678901234"
    h = hash.sha256(verifier)
    challenge = hex_to_b64url(h)
    state = "pixlet_state_123456"

    # 1. Authorize
    auth_url = "%s/oauth2/v1/%s/authorize?client_id=%s&redirect_uri=%s&response_type=code&scope=openid&state=%s&code_challenge=%s&code_challenge_method=S256&flow=prd-sign-in-or-up" % (
        AUTH_HOST,
        PROJECT_ID,
        PROJECT_ID,
        REDIRECT_URI,
        state,
        challenge,
    )
    rep = http.get(auth_url)
    if rep.status_code != 200:
        print("Authorize failed:", rep.status_code)
        return None

    state_id = extract_query_param(rep.url, "state_id")
    if not state_id:
        print("No state_id found in authorize redirect URL")
        return None

    cookies = rep.headers.get("Set-Cookie", "")

    # 2. Flow Start
    start_headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + PROJECT_ID,
        "x-descope-project-id": PROJECT_ID,
        "x-descope-auth-hosting": "1",
        "Referer": rep.url,
    }
    if cookies:
        start_headers["Cookie"] = cookies

    start_body = json.encode({
        "flowId": "prd-sign-in-or-up",
        "options": {
            "baseUrl": AUTH_HOST,
            "oidcIdpStateId": state_id,
            "ssoAppId": "descope-default-oidc",
            "oidcErrorRedirectUri": REDIRECT_URI,
        },
        "flowVersions": {
            "prd-sign-in-or-up": 3,
        },
        "componentsVersion": "3.27.2",
        "input": {"origin": AUTH_HOST},
    })

    rep_start = http.post("%s/v1/flow/start" % AUTH_HOST, headers = start_headers, body = start_body)
    if rep_start.status_code != 200:
        print("flow/start failed:", rep_start.status_code)
        return None

    start_data = rep_start.json()
    execution_id = start_data.get("executionId")
    nonce = rep_start.headers.get("X-Descope-Flow-Nonce") or rep_start.headers.get("x-descope-flow-nonce")

    # 3. Flow Next (Credentials)
    next_headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer " + PROJECT_ID,
        "x-descope-project-id": PROJECT_ID,
        "x-descope-auth-hosting": "1",
        "Referer": rep.url,
    }
    if nonce:
        next_headers["x-descope-flow-nonce"] = nonce
    if rep_start.headers.get("Set-Cookie"):
        next_headers["Cookie"] = rep_start.headers.get("Set-Cookie")
    elif cookies:
        next_headers["Cookie"] = cookies

    next_body = json.encode({
        "executionId": execution_id,
        "stepId": "1",
        "interactionId": "AMeyg_7npF",
        "version": 3,
        "componentsVersion": "3.27.2",
        "input": {
            "email": username,
            "password": password,
            "origin": AUTH_HOST,
        },
    })

    rep_next = http.post("%s/v1/flow/next" % AUTH_HOST, headers = next_headers, body = next_body)
    if rep_next.status_code != 200:
        print("flow/next failed:", rep_next.status_code)
        return None

    next_data = rep_next.json()
    redirect_url = next_data.get("redirect", {}).get("url", "")
    code = extract_query_param(redirect_url, "code")
    if not code:
        print("No authorization code in redirect:", redirect_url)
        return None

    # 4. Token Exchange
    token_url = "%s/oauth2/v1/%s/token" % (AUTH_HOST, PROJECT_ID)
    token_headers = {
        "Content-Type": "application/x-www-form-urlencoded",
    }
    token_body = "grant_type=authorization_code&client_id=%s&redirect_uri=%s&code=%s&code_verifier=%s" % (
        PROJECT_ID,
        REDIRECT_URI,
        code,
        verifier,
    )
    rep_token = http.post(token_url, headers = token_headers, body = token_body)
    if rep_token.status_code != 200:
        print("Token exchange failed:", rep_token.status_code)
        return None

    token_data = rep_token.json()
    access_token = token_data.get("access_token")
    if access_token:
        cache.set(token_cache_key, access_token, ttl_seconds = 900)
        return {"token": access_token}

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
            child = render.WrappedText("Configure Stern email & password", font = FONT),
        )

    auth = login(username, password)
    if not auth:
        if "@" not in username:
            return render.Root(
                child = render.WrappedText("Stern login requires account email", font = FONT),
            )
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
                name = "Stern Email",
                desc = "Your Stern Insider Connected account email address",
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
