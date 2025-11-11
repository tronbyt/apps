"""
Applet: HA Now Playing
Summary: Home Assistant Now Playing
Description: Display track details and artwork from any Home Assistant media_player entity.
Author: drudge, gabe565
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render", "canvas")
load("schema.star", "schema")

DEFAULT_IMAGE = """
iVBORw0KGgoAAAANSUhEUgAAABEAAAARCAMAAAAMs7fIAAAAGFBMVEVHcEz///////////////////////////8dS1W+AAAAB3RSTlMAAQMCBvYFRZBFoAAAAElJREFUGJWNj0sSwCAIQxNtm/vf2LGOQ0QXZgPz+ASAS2kKKANEKYL0GRKIf8LI2PRsRAxSMK1ST80ENlVPXi97SjtxzWh/3akBR3MCH53fHWkAAAAASUVORK5CYII=
"""

DEFAULT_IMAGE_2X = """
iVBORw0KGgoAAAANSUhEUgAAACQAAAAkAgMAAACcbnALAAAACVBMVEUAAAD///8mRckgsHh3AAAAA3RSTlP//wDXyg1BAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAZUlEQVQYlY3QsQ3AMAgEQC8JBSOwD9nARZgybyfhG6TEhXWSwXoY+Z7xXyEiunTKOg5NwxOukbGrFDq2D0gzHG2QZaBy3tKSUF6ykpaE8kZNhzU/NwmeVEzK9JyIU3LyvQ372toF2su87R8cvrAAAAAASUVORK5CYII=
"""

def get_entity_status(ha_server, entity_id, token):
    if not ha_server:
        fail("Home Assistant server not configured")
    if not entity_id:
        fail("Entity ID not configured")
    if not token:
        fail("Bearer token not configured")

    rep = http.get("%s/api/states/%s" % (ha_server, entity_id), headers = {
        "Authorization": "Bearer %s" % token,
    }, ttl_seconds = 10)
    if rep.status_code != 200:
        print("HTTP request failed with status", rep.status_code)
        return None

    return rep.json()

def render_media_title(title, app_name, font = "tb-8", scale = 1):
    return render.Padding(
        pad = (2 * scale, 0, 0, 0),
        child = render.Marquee(
            width = 60 * scale,
            child = render.Padding(
                pad = (0, 2, 0, 0),
                child = render.Text(
                    content = title,
                    color = get_title_color(app_name),
                    font = font,
                ),
            ),
        ),
    )

def render_detail_text(name, color = "#ffffff", font = "tb-8", scale = 1):
    return render.Marquee(
        width = 41 * scale,
        child = render.Text(
            content = name or "",
            color = color,
            font = font,
        ),
    )

def get_title_color(app_name):
    APP_COLORS = {
        "HBO": "#b535f6",
        "Movies": "#5ea8b8",
        "Music": "#e74e5a",
        "Netflix": "#e50914",
        "Overcast": "#fc7e0f",
        "Plex": "#e5a00d",
        "Podcasts": "#bf94ff",
        "Spotify": "#1db954",
        "TVMusic": "#e74e5a",
        "Twitch": "#bf94ff",
        "YouTube": "#f00000",
    }
    return APP_COLORS.get(app_name, "#009cc4")

def get_app_name(app_name, app_id, friendly_name):
    if app_name:
        return app_name
    if not app_id:
        return friendly_name

    APP_ID_FULL_MAP = {
        "com.apple.TVAirPlay": "AirPlay",
        "com.google.ios.youtube": "YouTube",
        "com.hbo.hbonow": "HBO",
        "com.plexapp.plex": "Plex",
        "com.timewarnercable.simulcast": "Spectrum TV",
    }
    if app_id in APP_ID_FULL_MAP:
        return APP_ID_FULL_MAP[app_id]

    name = app_id.split(".")[-1]

    APP_ID_SUFFIX_MAP = {
        "AIVApp": "Prime Video",
        "TVMovies": "Movies",
        "TVWatchList": "Apple TV",
    }
    return APP_ID_SUFFIX_MAP.get(name, name)

def main(config):
    ha_server = config.get("homeassistant_server")
    entity_id = config.get("entity_id")
    token = config.get("auth")
    entity_status = get_entity_status(ha_server, entity_id, token)

    if not entity_status:
        return []

    status = entity_status.get("state")
    attributes = entity_status.get("attributes", dict())

    if status != "playing":
        return []

    scale = 2 if canvas.is2x() else 1
    font = "terminus-18" if scale == 2 else "tb-8"

    media_title = attributes.get("media_title")
    media_image = None

    if "entity_picture" in attributes:
        res = http.get("%s%s" % (ha_server, attributes.get("entity_picture")), ttl_seconds = 600)
        if res.status_code == 200:
            media_image = res.body()

    if not media_image:
        media_image = base64.decode(DEFAULT_IMAGE_2X if scale >= 2 else DEFAULT_IMAGE)

    media_content_type = attributes.get("media_content_type")
    media_artist = attributes.get("media_artist")
    app_name = attributes.get("app_name") or attributes.get("source")
    app_id = attributes.get("app_id")
    friendly_name = attributes.get("friendly_name", "")
    app_name = get_app_name(app_name, app_id, friendly_name)
    media_artist = media_artist or friendly_name
    media_title = media_title or app_name
    media_album_name = attributes.get("media_album_name", app_name)

    line2 = media_album_name
    line1 = media_artist if line2 != media_artist else ""

    if media_content_type == "video" or app_name == "Overcast" or app_name == "Podcasts":
        line1 = line2
        line2 = media_artist

    if line2 == friendly_name:
        line2 = "→ %s" % line2

    media_title, line1, line2 = [s.replace("&amp;", "&") for s in (media_title, line1, line2)]

    if config.bool("upper"):
        media_title, line1, line2 = media_title.upper(), line1.upper(), line2.upper()

    image_size = 36 if scale == 2 else 17 * scale

    return render.Root(
        delay = 50 if scale == 1 else 25,
        child = render.Column(
            children = [
                render_media_title(media_title, app_name, font = font, scale = scale),
                render.Padding(
                    pad = (2 * scale, 2, 0, 0),
                    child = render.Row(
                        children = [
                            render.Image(
                                src = media_image,
                                height = image_size,
                                width = image_size,
                            ),
                            render.Padding(
                                pad = (2 * scale, 0, 0, 0),
                                child = render.Column(children = [
                                    render_detail_text(line1, font = font, scale = scale),
                                    render_detail_text(line2, color = "#cccccc", font = font, scale = scale),
                                ]),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "homeassistant_server",
                name = "Home Assistant Server",
                desc = "Home Assistant base URL (e.g. http://homeassistant:8123). Supports https.",
                icon = "server",
            ),
            schema.Text(
                id = "entity_id",
                name = "Entity ID",
                icon = "play",
                desc = "Entity ID of the media player entity in Home Assistant",
            ),
            schema.Text(
                id = "auth",
                name = "Bearer Token",
                icon = "key",
                desc = "Long-lived access token for Home Assistant",
            ),
            schema.Toggle(
                id = "upper",
                name = "Capitalize Text",
                desc = "Outputs text in upper case.",
                icon = "font",
                default = False,
            ),
        ],
    )
