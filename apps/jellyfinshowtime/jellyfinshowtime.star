"""
Applet: Jellyfin Showtime
Summary: Explore your Jellyfin library
Description: View recently added or released media from your Jellyfin server.
Author: radiocolin (Forked from Michael Yagi's Plex Showtime)
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/jellyfin_banner.png", JELLYFIN_BANNER_ASSET = "file")
load("images/jellyfin_banner@2x.png", JELLYFIN_BANNER_2X_ASSET = "file")
load("images/jellyfin_banner_portrait.png", JELLYFIN_BANNER_PORTRAIT_ASSET = "file")
load("images/jellyfin_banner_portrait@2x.png", JELLYFIN_BANNER_PORTRAIT_2X_ASSET = "file")
load("images/jellyfin_icon.png", JELLYFIN_ICON_ASSET = "file")
load("images/jellyfin_icon@2x.png", JELLYFIN_ICON_2X_ASSET = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

JELLYFIN_BANNER = JELLYFIN_BANNER_ASSET.readall()
JELLYFIN_BANNER_2X = JELLYFIN_BANNER_2X_ASSET.readall()
JELLYFIN_BANNER_PORTRAIT = JELLYFIN_BANNER_PORTRAIT_ASSET.readall()
JELLYFIN_BANNER_PORTRAIT_2X = JELLYFIN_BANNER_PORTRAIT_2X_ASSET.readall()
JELLYFIN_ICON = JELLYFIN_ICON_ASSET.readall()
JELLYFIN_ICON_2X = JELLYFIN_ICON_2X_ASSET.readall()

MAX_TEXT_LENGTH = 1000
GET_TOP = 15

def main(config):
    scale = 2 if canvas.is2x() else 1
    jellyfin_server_url = config.str("jellyfin_server_url", "")
    jellyfin_api_key = config.str("jellyfin_api_key", "")
    show_heading = config.bool("show_heading", True)
    show_only_artwork = config.bool("show_only_artwork", False)
    heading_color = config.str("heading_color", "#00A4DC")  # Jellyfin Blue
    font_color = config.str("font_color", "#FFFFFF")
    show_summary = config.bool("show_summary", False)
    show_released = config.bool("show_released", True)
    show_added = config.bool("show_added", True)
    show_recent = config.bool("show_recent", True)
    show_library = config.bool("show_library", True)
    filter_movie = config.bool("filter_movie", True)
    filter_tv = config.bool("filter_tv", True)
    filter_music = config.bool("filter_music", True)
    show_playing = config.bool("show_playing", False)
    fit_screen = config.bool("fit_screen", True)
    debug_output = config.bool("debug_output", False)
    release_window = int(config.str("release_window", "90"))
    added_window = int(config.str("added_window", "30"))

    if show_only_artwork:
        show_heading = False
        show_summary = False

    ttl_seconds = 5

    endpoints = []

    if show_playing:
        endpoints.append({"title": "Playing", "id": 1})

    if show_released:
        endpoints.append({"title": "Released", "id": 2})

    if show_added:
        endpoints.append({"title": "Added", "id": 3})

    if show_recent:
        endpoints.append({"title": "Played", "id": 4})

    if show_library:
        endpoints.append({"title": "Library", "id": 5})

    endpoint_map = {"title": "None", "id": 0}
    if len(endpoints) > 0:
        random_endpoint_index = random.number(0, len(endpoints) - 1)
        endpoint_map = endpoints[random_endpoint_index]

    if debug_output:
        print("------------------------------")
        print("CONFIG - server: " + jellyfin_server_url)
        print("CONFIG - endpoint: " + str(endpoint_map))

    return get_text(jellyfin_server_url, jellyfin_api_key, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, show_heading, show_only_artwork, show_summary, heading_color, font_color, ttl_seconds, release_window, added_window, scale)

def get_text(server_url, api_key, endpoint_map, debug_output, fit_screen, filter_movie, filter_tv, filter_music, show_heading, show_only_artwork, show_summary, heading_color, font_color, ttl_seconds, release_window, added_window, scale):
    base_url = server_url
    if base_url.endswith("/"):
        base_url = base_url[0:len(base_url) - 1]

    if server_url == "" or api_key == "":
        return display_message(debug_output, [{"message": "Jellyfin URL and API key required", "color": "#FF0000"}], False, scale)
    elif endpoint_map["id"] == 0:
        return display_message(debug_output, [{"message": "Select library type in config", "color": "#FF0000"}], False, scale)

    headers = {"X-Emby-Token": api_key}
    items = []

    # Common filters
    include_types = []
    if filter_movie:
        include_types.append("Movie")
    if filter_tv:
        include_types.append("Series")
    if filter_music:
        include_types.append("MusicAlbum")
    include_types_str = ",".join(include_types)

    if endpoint_map["id"] == 1:  # Playing
        url = base_url + "/Sessions"
        content = get_data(url, debug_output, headers, ttl_seconds)
        if content:
            sessions = json.decode(content)
            for s in sessions:
                if s.get("NowPlayingItem"):
                    items.append(s["NowPlayingItem"])

    elif endpoint_map["id"] == 2:  # Recently Released
        min_date = time.now() - time.parse_duration("%dh" % (release_window * 24))
        min_date_str = min_date.format("2006-01-02")

        url = base_url + "/Items?SortBy=PremiereDate&SortOrder=Descending&Recursive=true&IncludeItemTypes=" + include_types_str + "&MinPremiereDate=" + min_date_str + "&Limit=" + str(GET_TOP)
        content = get_data(url, debug_output, headers, ttl_seconds)
        if content:
            items = json.decode(content).get("Items", [])

        if not items:
            url = base_url + "/Items?SortBy=PremiereDate&SortOrder=Descending&Recursive=true&IncludeItemTypes=" + include_types_str + "&Limit=" + str(GET_TOP)
            content = get_data(url, debug_output, headers, ttl_seconds)
            if content:
                items = json.decode(content).get("Items", [])

    elif endpoint_map["id"] == 3:  # Recently Added
        min_date = time.now() - time.parse_duration("%dh" % (added_window * 24))
        min_date_str = min_date.format("2006-01-02T15:04:05Z")  # Jellyfin often expects ISO for MinDateCreated

        url = base_url + "/Items?SortBy=DateCreated&SortOrder=Descending&Recursive=true&IncludeItemTypes=" + include_types_str + "&MinDateCreated=" + min_date_str + "&Limit=" + str(GET_TOP)
        content = get_data(url, debug_output, headers, ttl_seconds)
        if content:
            items = json.decode(content).get("Items", [])

        if not items:
            url = base_url + "/Items?SortBy=DateCreated&SortOrder=Descending&Recursive=true&IncludeItemTypes=" + include_types_str + "&Limit=" + str(GET_TOP)
            content = get_data(url, debug_output, headers, ttl_seconds)
            if content:
                items = json.decode(content).get("Items", [])

    elif endpoint_map["id"] == 4:  # Played
        url = base_url + "/Items?SortBy=DatePlayed&SortOrder=Descending&Recursive=true&IncludeItemTypes=" + include_types_str + "&Limit=" + str(GET_TOP)
        content = get_data(url, debug_output, headers, ttl_seconds)
        if content:
            items = json.decode(content).get("Items", [])

    elif endpoint_map["id"] == 5:  # Library
        url = base_url + "/Library/VirtualFolders"
        content = get_data(url, debug_output, headers, ttl_seconds)
        if content:
            folders = json.decode(content)
            valid_folders = []
            for f in folders:
                collection_type = f.get("CollectionType", "")
                if (filter_movie and collection_type == "movies") or (filter_tv and collection_type == "tvshows") or (filter_music and collection_type == "music"):
                    valid_folders.append(f)

            if len(valid_folders) > 0:
                folder = valid_folders[random.number(0, len(valid_folders) - 1)]
                url = base_url + "/Items?ParentId=" + folder["ItemId"] + "&Recursive=true&IncludeItemTypes=" + include_types_str + "&Limit=50"
                content = get_data(url, debug_output, headers, ttl_seconds)
                if content:
                    items = json.decode(content).get("Items", [])

    if not items:
        return display_message(debug_output, [{"message": "No results for " + endpoint_map["title"], "color": "#FF0000"}], False, scale)

    item = items[random.number(0, len(items) - 1)]

    media_type = item.get("Type", "Unknown")
    if media_type == "Series":
        media_type = "TV Show"
    elif media_type == "MusicAlbum":
        media_type = "Music"

    header_text = ""
    if show_heading:
        header_text = (media_type + " " + endpoint_map["title"]).strip()

    title = item.get("Name", "Unknown")
    parent_title = item.get("SeriesName", "")

    body_text = title
    if parent_title:
        body_text = parent_title + ": " + title

    title_text = body_text

    summary = item.get("Overview", "")
    if show_summary and summary:
        body_text = summary
    else:
        show_summary = False

    img_type = "Primary" if not show_summary else "Backdrop"
    img_url = base_url + "/Items/" + item["Id"] + "/Images/" + img_type + "?maxHeight=64"
    if show_summary:
        img_url = base_url + "/Items/" + item["Id"] + "/Images/Backdrop?maxWidth=64"

    img_data = get_data(img_url, debug_output, headers, ttl_seconds)

    using_portrait_banner = False
    if not img_data:
        if show_summary:
            img_data = JELLYFIN_BANNER_PORTRAIT if scale == 1 else JELLYFIN_BANNER_PORTRAIT_2X
            using_portrait_banner = True
        else:
            img_data = JELLYFIN_BANNER if scale == 1 else JELLYFIN_BANNER_2X

    if len(title_text) >= MAX_TEXT_LENGTH:
        title_text = title_text[0:MAX_TEXT_LENGTH] + "..."
    if len(body_text) >= MAX_TEXT_LENGTH:
        body_text = body_text[0:MAX_TEXT_LENGTH] + "..."

    if show_summary and not show_only_artwork:
        rendered_image = render.Image(width = 22 * scale, src = img_data)
        marquee_text_array = [
            {"type": "heading", "message": header_text, "color": "#FFFFFF"},
            {"type": "title", "message": title_text, "color": heading_color},
            {"type": "body", "message": body_text, "color": font_color},
        ]
    elif fit_screen and not show_only_artwork:
        rendered_image = render.Image(width = 64 * scale, src = img_data)
        marquee_text_array = [
            {"type": "heading", "message": header_text, "color": heading_color},
            {"type": "body", "message": body_text, "color": font_color},
        ]
    elif show_only_artwork:
        if fit_screen:
            rendered_image = render.Image(height = 32 * scale, src = img_data)
        else:
            rendered_image = render.Image(width = 64 * scale, src = img_data)
        marquee_text_array = []
    else:
        rendered_image = render.Image(height = 25 * scale, src = img_data)
        marquee_text_array = [
            {"type": "heading", "message": header_text, "color": heading_color},
            {"type": "body", "message": body_text, "color": font_color},
        ]

    return render_marquee(show_only_artwork, marquee_text_array, rendered_image, show_summary, using_portrait_banner, scale)

def display_message(debug_output, message_array = [], show_summary = False, scale = 1):
    if show_summary:
        img = JELLYFIN_BANNER_PORTRAIT if scale == 1 else JELLYFIN_BANNER_PORTRAIT_2X
    else:
        img = JELLYFIN_BANNER if scale == 1 else JELLYFIN_BANNER_2X

    if not debug_output:
        return render.Root(child = render.Box(child = render.Image(src = img, width = 64 * scale)))

    rendered_image = render.Image(width = 64 * scale, src = img)
    return render_marquee(False, message_array, rendered_image, show_summary, False, scale)

def render_marquee(show_only_artwork, message_array, image, show_summary, using_portrait_banner = False, scale = 1):
    icon_img = JELLYFIN_ICON if scale == 1 else JELLYFIN_ICON_2X
    text_array = []

    text_font = "tom-thumb" if scale == 1 else "terminus-12"

    if show_only_artwork:
        return render.Root(child = render.Box(child = image))

    for message in message_array:
        if not show_summary:
            msg = message["message"]
            text_array.append(render.Text(msg, color = message["color"], font = text_font))
        else:
            wrap_len = 9 if scale == 1 else 16
            wrapped = wrap(message["message"], wrap_len)
            text_array.append(render.WrappedText(content = wrapped, font = text_font, color = message["color"], width = 41 * scale))

    if show_summary:
        return render.Root(
            delay = 90,
            child = render.Row(
                children = [
                    render.Stack(children = [image, render.Image(src = icon_img, width = 7 * scale, height = 7 * scale)] if not using_portrait_banner else [image]),
                    render.Padding(
                        pad = (1 * scale, 0, 0, 0),
                        child = render.Marquee(
                            height = 32 * scale,
                            scroll_direction = "vertical",
                            width = 41 * scale,
                            child = render.Column(children = text_array),
                        ),
                    ),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Column(
                children = [
                    render.Box(
                        width = 64 * scale,
                        height = 7 * scale,
                        child = render.Row(
                            children = [
                                render.Image(src = icon_img, width = 7 * scale, height = 7 * scale),
                                render.Marquee(width = 57 * scale, child = render.Row(children = text_array)),
                            ],
                        ),
                    ),
                    render.Box(width = 64 * scale, height = 25 * scale, child = image),
                ],
            ),
        )

def wrap(string, line_length):
    words = string.split(" ")
    lines = []
    cur = ""
    for w in words:
        if len(cur) + len(w) > line_length:
            lines.append(cur)
            cur = w
        else:
            cur = (cur + " " + w).strip()
    lines.append(cur)
    return "\n".join(lines)

def get_data(url, debug_output, headers = {}, ttl_seconds = 20):
    res = http.get(url, headers = headers, ttl_seconds = ttl_seconds)
    if res.status_code != 200:
        if debug_output:
            print("Error " + str(res.status_code) + " on " + url)
        return None
    return res.body()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "jellyfin_server_url", name = "Jellyfin Server URL", desc = "e.g. http://192.168.1.100:8096", icon = "globe"),
            schema.Text(id = "jellyfin_api_key", name = "API Key", desc = "Jellyfin API Key", icon = "key", secret = True),
            schema.Text(id = "release_window", name = "Release Window (days)", desc = "Look for items released in the last X days.", icon = "calendar", default = "90"),
            schema.Text(id = "added_window", name = "Added Window (days)", desc = "Look for items added in the last X days.", icon = "calendar", default = "30"),
            schema.Toggle(id = "show_heading", name = "Show heading", desc = "Display media type and view name.", icon = "eye", default = True),
            schema.Text(id = "heading_color", name = "Heading color", desc = "Hex color for heading.", icon = "paintbrush", default = "#00A4DC"),
            schema.Text(id = "font_color", name = "Font color", desc = "Hex color for body text.", icon = "paintbrush", default = "#FFFFFF"),
            schema.Toggle(id = "show_summary", name = "Show summary", desc = "Show overview/description.", icon = "alignLeft", default = False),
            schema.Toggle(id = "show_only_artwork", name = "Show Only Artwork", desc = "Display only the poster/backdrop.", icon = "eye", default = False),
            schema.Toggle(id = "fit_screen", name = "Fit screen", desc = "Fit image to display.", icon = "arrowsLeftRightToLine", default = True),
            schema.Toggle(id = "debug_output", name = "Debug messages", desc = "Display debug info on device.", icon = "bug", default = False),
            schema.Toggle(id = "show_released", name = "Show recent releases", desc = "Show recently released items.", icon = "calendar", default = True),
            schema.Toggle(id = "show_added", name = "Show recently added", desc = "Show recently added items.", icon = "plus", default = True),
            schema.Toggle(id = "show_recent", name = "Show played", desc = "Show recently played.", icon = "arrowTrendUp", default = True),
            schema.Toggle(id = "show_library", name = "Show library", desc = "Show random item from library.", icon = "layerGroup", default = True),
            schema.Toggle(id = "show_playing", name = "Show playing", desc = "Show now playing.", icon = "play", default = False),
            schema.Toggle(id = "filter_movie", name = "Filter Movies", desc = "Include movies.", icon = "film", default = True),
            schema.Toggle(id = "filter_tv", name = "Filter TV", desc = "Include TV shows.", icon = "tv", default = True),
            schema.Toggle(id = "filter_music", name = "Filter Music", desc = "Include music.", icon = "music", default = True),
        ],
    )
