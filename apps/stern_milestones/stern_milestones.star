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

CACHE_TTL = 43200  # 12 hours

def login(username, password):
    token_cache_key = "stern_descope_token_v1_" + hash.sha256(username + ":" + password)[:16]
    cached_token = cache.get(token_cache_key)
    if cached_token:
        return cached_token

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
        return access_token

    return None

def main(config):
    username = config.get("username")
    password = config.get("password")

    if not username or not password:
        return render.Root(
            child = render.WrappedText("Configure Stern email & password"),
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
            if "@" not in username:
                return render.Root(
                    child = render.WrappedText("Stern login requires account email"),
                )
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
        ],
    )
