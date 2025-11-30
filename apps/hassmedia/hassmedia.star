load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_3b2d6389.png", IMG_3b2d6389_ASSET = "file")
load("images/img_fbe29b76.svg", IMG_fbe29b76_ASSET = "file")

PLACEHOLDER_DATA = {
    "entity_id": "media_player.spotify",
    "state": "playing",
    "attributes": {
        "media_title": "blown a wish",
        "media_artist": "my bloody valentine",
        "media_album_name": "loveless",
    },
}

ICONS = {
    "ha": IMG_fbe29b76_ASSET.readall(),
    "spotify": IMG_3b2d6389_ASSET.readall(),
}

def main(config):
    if not config.str("ha_instance") or not config.str("ha_entity") or not config.str("ha_token"):
        print("Using placeholder data, please configure the app")
        data = PLACEHOLDER_DATA
        error = None
    else:
        data, error = get_entity_data(config)

    if data == None:
        return render_error_message("Error: received status " + str(error))

    if data["state"] == "playing":
        return render_app(config, data)
    else:
        return []

def get_entity_data(config):
    url = config.str("ha_instance") + "/api/states/" + config.str("ha_entity")
    headers = {
        "Authorization": "Bearer " + config.str("ha_token"),
        "Content-Type": "application/json",
    }

    rep = http.get(url, ttl_seconds = 10, headers = headers)
    if rep.status_code != 200:
        return None, rep.status_code

    data = rep.json()
    return (data, None) if data else ({}, None)

def get_image(url, config):
    url = config.str("ha_instance") + url
    headers = {
        "Authorization": "Bearer " + config.str("ha_token"),
        "Content-Type": "application/json",
    }

    rep = http.get(url, ttl_seconds = 240, headers = headers)
    if rep.status_code != 200:
        return None, rep.status_code

    return base64.encode(rep.body()), None

def render_app(config, data):
    if "entity_picture" in data.get("attributes", {}):
        image_url = data["attributes"]["entity_picture"]
        image, _ = get_image(image_url, config)
        image_element = render.Image(src = base64.decode(image), width = 20, height = 20)
    else:
        image_element = render.Image(src = ICONS["spotify"], width = 17, height = 17)

    return render.Root(
        render.Row(
            children = [
                render.Column(
                    children = [
                        render.Padding(
                            child = image_element,
                            pad = (0, 0, 1, 0),
                        ),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
                render.Column(
                    children = [
                        render.Marquee(
                            align = "start",
                            child = render.Text(content = data["attributes"]["media_title"], font = "tb-8"),
                            width = 46,
                        ),
                        render.Marquee(
                            align = "start",
                            child = render.Text(color = "#1d9e03", content = data["attributes"]["media_artist"], font = "tb-8"),
                            width = 46,
                        ),
                        render.Marquee(
                            align = "start",
                            child = render.Text(color = "#8905da", content = data["attributes"]["media_album_name"], font = "tb-8"),
                            width = 46,
                        ),
                    ],
                    expanded = True,
                    main_align = "center",
                ),
            ],
        ),
    )

def render_error_message(message):
    return render.Root(
        child = render.Column(
            children = [
                render.Box(child = render.Image(src = ICONS["ha"], width = 15, height = 15), height = 15),
                render.WrappedText(
                    align = "center",
                    font = "tom-thumb",
                    content = message,
                    color = "#FF0000",
                    width = 64,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ha_instance",
                desc = "Home Assistant URL. The address of your HomeAssistant instance, as a full URL.",
                icon = "globe",
                name = "Home Assistant URL",
            ),
            schema.Text(
                id = "ha_token",
                desc = "Home Assistant token. Navigate to User Settings > Long-lived access tokens.",
                icon = "key",
                name = "Home Assistant Token",
                secret = True,
            ),
            schema.Text(
                id = "ha_entity",
                desc = "Entity name of the Spotify media player e.g. 'media_player.spotify'.",
                icon = "ruler",
                name = "Entity name",
            ),
        ],
    )
