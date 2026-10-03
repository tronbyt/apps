"""
Applet: RestDbIoDashboard
Summary: Restdb.io dashboard
Description: Generic dashboard based on a restdb.io database.
Author: romerod
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/icon_new.png", ICON_NEW_ASSET = "file")
load("images/icon_restdb.png", ICON_RESTDB_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

TTL_ICONS = 216000

DEMO_PAGE = json.encode([
    {"text": "create", "colortext": "#FFFFFF", "subtext": "", "colorsubtext": "#FFFFFF", "icon": "new", "order": 0, "name": "create"},
    {"text": "restdb.io", "colortext": "#777777", "subtext": "", "colorsubtext": "#000000", "icon": "restdb", "order": 1, "name": "restdb"},
    {"text": "database", "colortext": "#FFFFFF", "subtext": "", "colorsubtext": "#FFFFFF", "icon": "new", "order": 2, "name": "database"},
])

DEMO_ICONS = json.encode([
    {"name": "new", "data": base64.encode(ICON_NEW_ASSET.readall())},
    {"name": "restdb", "data": base64.encode(ICON_RESTDB_ASSET.readall())},
])

def render_fail(rep):
    return render.Root(render.Box(render.WrappedText("%s" % rep.status_code), color = "#AA0000"))

def get_col(text, subtext, coltext, colsubtext, icon):
    return render.Column(
        cross_align = "center",
        main_align = "space_evenly",
        expanded = True,
        children = [
            render.Image(src = icon, height = 15),
            render.Column(
                cross_align = "center",
                children = [
                    render.Text(text, color = coltext),
                    render.Text(subtext, color = colsubtext),
                ],
            ),
        ],
    )

def get_row(text, subtext, coltext, colsubtext, icon):
    return render.Row(
        expanded = True,
        cross_align = "center",
        main_align = "left",
        children = [
            render.Padding(pad = (2, 0, 0, 0), child = render.Image(src = icon, height = 10, width = 10)),
            render.Padding(pad = (2, 1, 0, 0), child = render.Text(text, color = coltext)),
            render.Padding(pad = (2, 1, 0, 0), child = render.Text(subtext, color = colsubtext)),
        ],
    )

def main(config):
    icons = dict()

    db_name = config.str("db_name")
    table_name = config.str("table_name")
    vertical_layout = config.bool("vertical")
    api_key = config.str("api_key")
    offline_page = config.str("offline_page")
    offline_icons = config.str("offline_icons")
    data_cache_time = int(config.get("cache_time", "5"))

    use_offline_data = False

    if not db_name or db_name == "offline":
        use_offline_data = True
        db_name = "offline"
        print("using offline data")
        if not offline_page:
            offline_page = DEMO_PAGE
            offline_icons = DEMO_ICONS
            vertical_layout = True

    if config.bool("reset_icon_cache") and not use_offline_data:
        return reset_icon_cache(db_name, api_key)

    if not use_offline_data:
        data_cache_key = "{}-data".format(db_name)
        body = cache.get(data_cache_key)
        if not body:
            rep = http.get(
                "https://{}.restdb.io/rest/{}?max=3&q={{%22visible%22:true}}&sort=order".format(db_name, table_name),
                headers = {
                    "Accept": "application/json",
                    "x-apikey": api_key,
                },
            )

            if rep.status_code != 200:
                print(rep.body())
                return render_fail(rep)
            body = rep.body()

            if not body.startswith("{") and not body.startswith("["):
                print("Response is not JSON: " + body[:100])
                return render.Root(
                    child = render.WrappedText("Invalid API Response", color = "#FF0000"),
                )

            cache.set(data_cache_key, body, ttl_seconds = data_cache_time)

        items = json.decode(body)
    else:
        items = json.decode(offline_page)
        for icon in json.decode(offline_icons):
            icons.update([(icon["name"], icon["data"])])

    if not use_offline_data:
        icons_to_load = list()

        for item in items:
            icon_cache_key = "{}-icon-{}".format(db_name, item["icon"])
            icon = cache.get(icon_cache_key)
            if not icon:
                icons_to_load.insert(-1, item["icon"])
            else:
                icons.update([(item["icon"], icon)])

        if len(icons_to_load) > 0:
            fail = load_icons(icons_to_load, icons, db_name, api_key)
            if fail:
                return fail

        for name in icons:
            icon_cache_key = "{}-icon-{}".format(db_name, name)

            cache.set(icon_cache_key, icons[name], ttl_seconds = TTL_ICONS)

    if len(items) == 0:
        return []

    if vertical_layout:
        rows = list()
        for item in items:
            rows.append(get_row(item["text"], item["subtext"], item["colortext"], item["colorsubtext"], base64.decode(icons.get(item["icon"]))))

        return render.Root(child =
                               render.Column(
                                   children = rows,
                                   main_align = "space_around",
                                   cross_align = "center",
                                   expanded = True,
                               ))

    columns = list()
    for item in items:
        columns.append(get_col(item["text"], item["subtext"], item["colortext"], item["colorsubtext"], base64.decode(icons.get(item["icon"]))))

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            children = columns,
        ),
    )

def reset_icon_cache(db_name, api_key):
    load_icon_names = 'https://{}.restdb.io/rest/icons?&h={{"$fields":{{"name":1}}}}'
    load_icon_names = load_icon_names.format(db_name)

    rep = http.get(
        load_icon_names,
        headers = {
            "Accept": "application/json",
            "x-apikey": api_key,
        },
    )

    if rep.status_code != 200:
        print(rep.body())
        return render_fail(rep)

    for icon in json.decode(rep.body()):
        icon_cache_key = "{}-icon-{}".format(db_name, icon["name"])

        cache.set(icon_cache_key, "", ttl_seconds = TTL_ICONS)

    return render.Root(render.Box(render.WrappedText("icon cache reset"), color = "#FFA500"))

def load_icons(icons_to_load, icons, db_name, api_key):
    load_icon_url = 'https://{}.restdb.io/rest/icons?q={{"name":{{"$in":{}}}}}'
    load_icon_url = load_icon_url.format(db_name, json.encode(icons_to_load))

    rep = http.get(
        load_icon_url,
        headers = {
            "Accept": "application/json",
            "x-apikey": api_key,
        },
    )

    if rep.status_code != 200:
        print(rep.body())
        return render_fail(rep)

    print("loaded icons")

    for icon in json.decode(rep.body()):
        icons.update([(icon["name"], icon["data"])])

    return None

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "db_name",
                name = "Database name",
                desc = "The name of the database on restdb.io",
                icon = "database",
            ),
            schema.Text(
                id = "table_name",
                name = "Table name",
                desc = "The name of the table on restdb.io",
                icon = "table",
                default = "home",
            ),
            schema.Text(
                id = "api_key",
                name = "API key",
                desc = "The API key to access restdb.io (read only is enough)",
                icon = "user",
                secret = True,
            ),
            schema.Text(
                id = "cache_time",
                name = "Cache time",
                desc = "How long to cache data from the database (api rate limit)",
                icon = "clock",
                default = "5",
            ),
            schema.Toggle(
                id = "vertical",
                name = "Vertical layout?",
                desc = "Show lines instead of columns",
                icon = "gripLines",
                default = False,
            ),
            schema.Toggle(
                id = "reset_icon_cache",
                name = "Reset icon caching",
                desc = "If the script fails due to a badly encoded icon or you change want to change an image, use this to clear the cache",
                icon = "trash",
                default = False,
            ),
            schema.Text(
                id = "offline_page",
                name = "JSON data offline",
                desc = "JSON data for offline usage",
                icon = "table",
            ),
            schema.Text(
                id = "offline_icons",
                name = "JSON icons offline",
                desc = "JSON icons data for offline usage",
                icon = "table",
            ),
        ],
    )
