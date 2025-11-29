"""
Applet: XBOX Gamerscore
Summary: Show your Gamerscore
Description: Show your Gamerscore from XBOX Live.
Author: Nick Penree
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/bg.png", BG_ASSET = "file")
load("images/intro.gif", INTRO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")
load("time.star", "time")

BG = BG_ASSET.readall()
INTRO = INTRO_ASSET.readall()

## Constants

DEFAULT_SHOW_AVATAR = False
DEFAULT_SHOW_GAMERTAG = False
DEFAULT_TEXT_SIZE = "normal"
SMALL_TEXT_SIZE = "small"
DEFAULT_USE_ANIMATED_VERSION = False

XBOX_LIVE_CLIENT_ID = "12f593c5-93bb-4801-80c3-1968300d2cae"
XBOX_LIVE_CLIENT_SCOPES = ["XboxLive.signin", "XboxLive.offline_access"]
XBOX_LIVE_CLIENT_SECRET = secret.decrypt("""
AV6+xWcEaylC45kmQ1uz7XVrdPuZEQu7BdRk9Cv2MF5KpI00yb+VSlg+TMU48FM9vFkeDVml6kTSJ0Z
rzAvL7Oj8MBgjq7Dj0x9I7wqV9KNhzoqCMlKjqyTXo+r/ZU+ugm3ju8zW53V7HZV7moOxoK9WwlFncm
mbLEbzkZDUewu1vt47coBFQs2tEA=="
""")

PREVIEW_PROFILE = dict(
    gamer_tag = "TidbytUser",
    gamer_score = "80085",
    avatar_url = "https://assets.website-files.com/5e83e105296ec10c70a99eac/5f04b6fffef2f0b21590ac24_favicon.png",
)
## Widgets

def GamerTag(gamer_tag = None, text_size = DEFAULT_TEXT_SIZE):
    is_small = (text_size == SMALL_TEXT_SIZE)
    widget = render.Text(
        color = "#045904",
        content = gamer_tag,
        font = "tom-thumb" if is_small else "tb-8",
    )
    scroll_len = 15 if is_small else 12
    if len(gamer_tag) > scroll_len:
        widget = render.Marquee(
            width = 64,
            child = widget,
        )
    return widget if gamer_tag else None

def Avatar(avatar_url = None):
    return render.Image(
        src = http.get(avatar_url).body(),
        height = 14,
        width = 14,
    ) if avatar_url else None

def GamerScore(score = None, text_size = DEFAULT_TEXT_SIZE, avatar_url = None):
    return render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Padding(
                pad = (2, 2, 2, 2),
                child = render.Circle(
                    color = "#fff",
                    diameter = 11,
                    child = render.Text(
                        content = "G",
                        color = "#000",
                        font = "Dina_r400-6",
                    ),
                ) if not avatar_url else Avatar(avatar_url),
            ),
            render.Text(
                content = score,
                font = "tb-8" if text_size == SMALL_TEXT_SIZE else "6x13",
            ),
        ],
    ) if score else None

def AnimatedScore(score = None, text_size = DEFAULT_TEXT_SIZE):
    if not score:
        return None

    frames = []

    # intro animation
    for i in range(82):
        frames.append(
            render.Box(
                child = render.Stack(
                    children = [
                        render.Image(
                            src = INTRO,
                            width = 64,
                        ),
                    ],
                ),
            ),
        )

    for i in range(120):
        off = i % 2 == 0
        color = "#000"
        if off:
            color = "#111"

        frames.append(
            render.Box(
                child = render.Stack(
                    children = [
                        render.Box(
                            child = render.Image(
                                src = BG,
                                width = 64,
                            ),
                        ),
                        render.Padding(
                            pad = (13, 11, 0, 1),
                            child = render.Text(
                                content = "G",
                                color = color,
                                font = "Dina_r400-6",
                            ),
                        ),
                        render.Box(
                            child = render.Padding(
                                pad = (9, 0, 0, 0),
                                child = render.Text(
                                    content = score,
                                    font = "tb-8" if text_size == SMALL_TEXT_SIZE else "Dina_r400-6",
                                ),
                            ),
                        ),
                    ],
                ),
            ),
        )

    return render.Root(
        child = render.Animation(children = frames),
    )

## Helpers

def get_access_token(refresh_token):
    access_token = cache.get(refresh_token)
    if access_token:
        return access_token
    res = http.post(
        url = "https://login.live.com/oauth20_token.srf",
        form_body = {
            "client_id": XBOX_LIVE_CLIENT_ID,
            "refresh_token": refresh_token,
            # "client_secret": XBOX_LIVE_CLIENT_SECRET,
            "grant_type": "refresh_token",
            "redirect_uri": cache.get("redirect_uri") or "https://pixlet.penr.ee/oauth-callback",
        },
        form_encoding = "application/x-www-form-urlencoded",
    )

    if res.status_code != 200:
        fail("access token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]
    ttl = int(token_params["expires_in"]) - 30

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(refresh_token, access_token, ttl_seconds = ttl)
    return access_token

def get_profile(config):
    refresh_token = config.get("auth")

    if not refresh_token:
        return PREVIEW_PROFILE

    access_token = cache.get(refresh_token)

    if not access_token:
        access_token = get_access_token(refresh_token)

    if not access_token:
        return None

    cached_profile = cache.get("%s|profile" % access_token)

    if cached_profile:
        profile = json.decode(cached_profile)
        return profile

    user_token = exchange_access_token_for_user_token(access_token)

    if not user_token:
        return None

    xsts = exchange_user_token_for_xsts_token(user_token)

    if not xsts:
        return None

    profile = get_xbox_live_profile(xsts)

    if profile:
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("%s|profile" % access_token, json.encode(profile), ttl_seconds = 300)

    return profile

def exchange_access_token_for_user_token(access_token):
    if not access_token:
        return None
    res = http.post(
        url = "https://user.auth.xboxlive.com/user/authenticate",
        headers = {
            "x-xbl-contract-version": "1",
            "accept": "application/json",
        },
        json_body = {
            "Properties": {
                "AuthMethod": "RPS",
                "SiteName": "user.auth.xboxlive.com",
                "RpsTicket": "d=%s" % access_token,
            },
            "RelyingParty": "http://auth.xboxlive.com",
            "TokenType": "JWT",
        },
    )

    if res.status_code != 200:
        fail("user token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    return token_params["Token"]

def exchange_user_token_for_xsts_token(user_token, sandbox_id = "RETAIL"):
    if not user_token:
        return None
    res = http.post(
        url = "https://xsts.auth.xboxlive.com/xsts/authorize",
        headers = {
            "x-xbl-contract-version": "1",
            "accept": "application/json",
        },
        json_body = {
            "RelyingParty": "http://xboxlive.com",
            "TokenType": "JWT",
            "Properties": {
                "UserTokens": [user_token],
                "SandboxId": sandbox_id,
            },
        },
    )

    if res.status_code != 200:
        fail("user token (xsts) request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()

    if not "DisplayClaims" in token_params:
        return None
    elif not "xui" in token_params["DisplayClaims"]:
        return None
    elif len(token_params["DisplayClaims"]["xui"]) < 1:
        return None
    display_claim = token_params["DisplayClaims"]["xui"][0]
    return dict(
        xuid = display_claim["xid"],
        gamer_tag = display_claim["gtg"],
        user_hash = display_claim["uhs"],
        xsts_token = token_params["Token"],
        expires_on = time.parse_time(token_params["NotAfter"]),
    )

def get_profile_setting(profile, key):
    settings = profile["settings"] or []
    for setting in settings:
        if setting["id"] == key:
            return setting["value"]
    return None

def get_xbox_live_profile(xsts):
    xuid = xsts["xuid"]
    if not xuid:
        return None
    res = http.post(
        url = "https://profile.xboxlive.com/users/batch/profile/settings",
        headers = {
            "x-xbl-contract-version": "2",
            "accept": "application/json",
            "authorization": "XBL3.0 x=%s;%s" % (xsts["user_hash"], xsts["xsts_token"]),
        },
        json_body = {
            "userIds": [xuid],
            "settings": [
                "GameDisplayPicRaw",
                "Gamerscore",
                "Gamertag",
            ],
        },
    )

    if res.status_code != 200:
        fail("get profile request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    body = res.json()
    profile = body["profileUsers"][0] if len(body["profileUsers"]) > 0 else None
    return dict(
        gamer_tag = get_profile_setting(profile, "Gamertag"),
        avatar_url = get_profile_setting(profile, "GameDisplayPicRaw"),
        gamer_score = get_profile_setting(profile, "Gamerscore"),
    ) if profile else None

## Handlers

def oauth_handler(params):
    params = json.decode(params)
    params["scope"] = " ".join(XBOX_LIVE_CLIENT_SCOPES)
    res = http.post(
        url = "https://login.live.com/oauth20_token.srf",
        headers = {
            "accept": "application/json",
        },
        form_body = params,
        form_encoding = "application/x-www-form-urlencoded",
    )

    # Caching this here to use in the refresh token request
    if params["redirect_uri"]:
        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("redirect_uri", params["redirect_uri"])

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]
    refresh_token = token_params["refresh_token"]
    ttl = int(token_params["expires_in"]) - 30

    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(refresh_token, access_token, ttl)
    return refresh_token

## Applet

def main(config):
    show_avatar = config.bool("show_avatar", DEFAULT_SHOW_AVATAR)
    show_gamertag = config.bool("show_gamertag", DEFAULT_SHOW_GAMERTAG)
    text_size = config.get("text_size", DEFAULT_TEXT_SIZE)
    use_animated_version = config.bool("use_animated_version", DEFAULT_USE_ANIMATED_VERSION)

    profile = get_profile(config)

    if use_animated_version:
        return AnimatedScore(
            score = profile["gamer_score"],
            text_size = text_size,
        ) if profile else []

    return render.Root(
        child = render.Box(
            child = render.Column(
                main_align = "center",
                cross_align = "center",
                children = [
                    GamerScore(
                        score = profile["gamer_score"],
                        text_size = text_size,
                        avatar_url = profile["avatar_url"] if show_avatar else None,
                    ),
                    GamerTag(
                        gamer_tag = profile["gamer_tag"],
                        text_size = text_size,
                    ) if show_gamertag else None,
                ],
            ),
        ),
    ) if profile else []

## Schema

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "XBOX Live",
                desc = "Connect your XBOX Live account.",
                icon = "xbox",
                handler = oauth_handler,
                client_id = XBOX_LIVE_CLIENT_ID,
                authorization_endpoint = "https://login.live.com/oauth20_authorize.srf",
                scopes = XBOX_LIVE_CLIENT_SCOPES,
            ),
            schema.Toggle(
                id = "use_animated_version",
                name = "Show animation",
                desc = "Show an XBOX inspired animation instead of a number.",
                icon = "circleNotch",
                default = DEFAULT_USE_ANIMATED_VERSION,
            ),
            schema.Toggle(
                id = "show_avatar",
                name = "Show Avatar",
                desc = "Show your avatar",
                icon = "image",
                default = DEFAULT_SHOW_AVATAR,
            ),
            schema.Toggle(
                id = "show_gamertag",
                name = "Show Gamertag",
                desc = "Show your gamertag",
                icon = "idBadge",
                default = DEFAULT_SHOW_GAMERTAG,
            ),
            schema.Dropdown(
                id = "text_size",
                name = "Text Size",
                desc = "Set your preferred text size",
                icon = "textHeight",
                options = [
                    schema.Option(
                        display = "Smaller",
                        value = SMALL_TEXT_SIZE,
                    ),
                    schema.Option(
                        display = "Normal",
                        value = DEFAULT_TEXT_SIZE,
                    ),
                ],
                default = DEFAULT_TEXT_SIZE,
            ),
        ],
    )
