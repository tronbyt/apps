"""
Applet: Twitch
Summary: Display info from Twitch
Description: Display info for a Twitch username.
Author: drudge
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/twitch_icon.png", TWITCH_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("secret.star", "secret")

TWITCH_ICON = TWITCH_ICON_ASSET.readall()

DEFAULT_CACHE_TTL = 120

TWITCH_CLIENT_ID = "h25bh1ddh0f5xcddgxgxhna399677y"
TWITCH_CLIENT_SECRET = secret.decrypt("""
AV6+xWcETS7CPwkqTIUG/LwYfqHrp8tLYkP1/SXo6T/eYjr9CVJ3dTArFuVaskadgybg6vIYZWy05sO
kxbTOK6nj7W2ca7Fwd3NDV881ld1uUlsNJPc9rEKMA5tt61x0ibneb4btRapT7W3dSspykK53ZspDxLv
YPZEg3QI4zXNn3maA
""")

def get_from_twitch_api(path, params, access_token, use_cache = True):
    if not access_token:
        return fail("No access token")

    # print("Fetching %s" % cache_key)
    res = http.get(
        url = "https://api.twitch.tv/helix%s" % path,
        params = params,
        headers = {
            "Authorization": "Bearer %s" % access_token,
            "Client-Id": TWITCH_CLIENT_ID,
        },
        ttl_seconds = DEFAULT_CACHE_TTL if use_cache else 0,
    )

    cached_res = res.body()

    if res.status_code != 200:
        # buildifier: disable=print
        print("get_from_twitch_api failed: %s - %s " % (res.status_code, cached_res))
        return None

    # else:
    #    print("Using cached %s" % cache_key)
    return json.decode(cached_res)

def get_twitch_followers(user_id, access_token):
    res = get_from_twitch_api(
        path = "/channels/followers",
        params = {
            "broadcaster_id": user_id,
        },
        access_token = access_token,
    )
    return res["total"] if res and res["total"] != None else 0

def get_twitch_subscribers(user_id, access_token):
    res = get_from_twitch_api(
        path = "/subscriptions",
        params = {
            "broadcaster_id": user_id,
            "first": "1",
        },
        access_token = access_token,
    )
    return res["total"] if res else None

def get_twitch_user(access_token, username = None):
    params = {
        "login": username,
    } if username else {}
    res = get_from_twitch_api(
        path = "/users",
        params = params,
        access_token = access_token,
    )
    if res and res["data"] and len(res["data"]) > 0:
        return res["data"][0]
    return None

def main(config):
    refresh_token = config.get("auth")
    username = config.get("username", "ninja")
    display_mode = config.get("display_mode", "subscribers")
    show_username = config.bool("show_username", "True")
    image_size = 16
    alt_text = None

    if refresh_token:
        access_token = get_token(refresh_token = refresh_token)
        user = get_twitch_user(
            username = username,
            access_token = access_token,
        )

        # print(user)
        if user == None:
            return []

        display_name = user["display_name"] if user["display_name"] else username

        if display_mode == "followers":
            followers = get_twitch_followers(
                access_token = access_token,
                user_id = user["id"],
            )
            if followers != None:
                msg = "%s %s" % (humanize.comma(followers), display_mode)
                if not show_username:
                    msg = humanize.comma(followers)
                    alt_text = display_mode
            else:
                msg = "Check username"
        elif display_mode == "subscribers":
            subscribers = get_twitch_subscribers(
                access_token = access_token,
                user_id = user["id"],
            )

            if subscribers != None:
                msg = "%s subs" % humanize.comma(subscribers)
                if not show_username:
                    msg = humanize.comma(subscribers)
                    alt_text = display_mode
            else:
                msg = "Check username"
                alt_text = "Are you %s? You can only view your own subscriber count." % display_name
                show_username = False
        elif display_mode == "nothing":
            msg = ""
        else:
            return []

        # print(msg)
    else:
        # msg = "Launch Tidbyt app"
        # alt_text = "Login to Twitch using the Tidbyt app on your phone"
        # show_username = False
        show_username = True
        msg = "42 followers"
        display_name = "Twytchbit"
        display_mode = "followers"

    if show_username:
        alt_text_child = None
        username_child = render.Text(
            color = "#3c3c3c",
            content = display_name,
        )

        if len(display_name) > 12:
            username_child = render.Marquee(
                width = 64,
                child = username_child,
            )
    else:
        if alt_text:
            alt_text_child = render.Text(content = alt_text)
            if len(alt_text) > 12:
                alt_text_child = render.Marquee(
                    width = 64,
                    child = alt_text_child,
                )
        else:
            alt_text_child = None
        username_child = None

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly" if len(msg) > 5 else "center",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(TWITCH_ICON, height = image_size, width = image_size),
                            ),
                            render.WrappedText(msg, font = "tb-8" if show_username or len(msg) > 7 else "6x13"),
                        ],
                    ),
                    username_child if show_username else None,
                    alt_text_child,
                ],
            ),
        ),
    )

def get_token(params = None, refresh_token = None):
    has_refresh_token = (refresh_token != None)

    # if params is a string, assume it is json and decode it
    if type(params) == "string":
        params = json.decode(params)
    elif params == None and has_refresh_token:
        params = dict(
            client_id = TWITCH_CLIENT_ID,
            grant_type = "refresh_token",
            refresh_token = refresh_token,
        )

    # get a new token
    res = http.post(
        url = "https://id.twitch.tv/oauth2/token",
        headers = {
            "Accept": "application/json",
        },
        form_body = dict(
            params,
            client_secret = TWITCH_CLIENT_SECRET,
        ),
        form_encoding = "application/x-www-form-urlencoded",
        ttl_seconds = 600,
    )

    if res.status_code != 200:
        fail("token request failed with status code: %d - %s" %
             (res.status_code, res.body()))

    token_params = res.json()
    access_token = token_params["access_token"]

    if not has_refresh_token:
        refresh_token = token_params["refresh_token"]

    return access_token if has_refresh_token else refresh_token

def build_user_fields(refresh_token):
    access_token = get_token(refresh_token = refresh_token)
    user = get_twitch_user(access_token = access_token)

    return [
        schema.Text(
            id = "username",
            icon = "user",
            name = "Username",
            desc = "The Twitch username to display stats for.",
            default = user["login"],
        ),
        schema.Toggle(
            id = "show_username",
            name = "Show username",
            desc = "Whether to show the username below the stat.",
            icon = "eye",
            default = True,
        ),
    ]

def get_schema():
    display_modes = [
        schema.Option(value = "nothing", display = "Logo only"),
        schema.Option(value = "followers", display = "Follower count"),
        schema.Option(value = "subscribers", display = "Subscriber count"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.OAuth2(
                id = "auth",
                name = "Twitch",
                desc = "Connect your Twitch account.",
                icon = "twitch",
                handler = get_token,
                client_id = TWITCH_CLIENT_ID,
                authorization_endpoint = "https://id.twitch.tv/oauth2/authorize",
                scopes = [
                    "user:read:follows",
                    "user:read:subscriptions",
                    "channel:read:subscriptions",
                ],
            ),
            schema.Generated(
                id = "username_generated",
                source = "auth",
                handler = build_user_fields,
            ),
            schema.Dropdown(
                id = "display_mode",
                name = "Display",
                desc = "Choose what info to display.",
                icon = "barsProgress",
                options = display_modes,
                default = display_modes[1].value,
            ),
        ],
    )
