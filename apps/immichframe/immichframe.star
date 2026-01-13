load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

def main(config):
    URL = config.get("immich_url", "https://example.com")
    API_KEY = config.get("immich_api_key", "")

    # SHOW_FAVORITES = config.bool("show_favorites", False)
    ALBUM = config.get("immich_album_id", "invalid")
    STATUS_URL = "%s/api/server/ping" % (URL)
    ALBUM_URL = "%s/api/albums/%s" % (URL, ALBUM)
    SHOW_DATE = config.bool("show_date", True)
    SHOW_LOCATION = config.bool("show_location", False)

    res = http.get(STATUS_URL)

    if res.status_code != 200:
        return render.Root(
            child = render.WrappedText("Server not accessible"),
        )
    else:
        headers = {
            "x-api-key": API_KEY,
        }
        res = http.get(ALBUM_URL, headers = headers)
        status = res.json().get("statusCode")
        if status != None:
            return render.Root(
                child = render.WrappedText("Album not accessible"),
            )
        assets = res.json()["assets"]
        assetCount = int(res.json()["assetCount"]) - 1
        if assetCount < 0:
            return render.Root(
                child = render.WrappedText("Album is Empty"),
            )
        randomCount = random.number(0, assetCount)
        assetID = assets[randomCount]["id"]
        IMG_URL = "%s/api/assets/%s" % (URL, assetID)
        print(IMG_URL)
        res_img = http.get("%s/thumbnail" % IMG_URL, headers = headers)
        res_req_metadata = http.get(IMG_URL, headers = headers)
        if (res_req_metadata.status_code != 200):
            return render.Root(
                child = render.WrappedText("Unable to retrieve image. Check API Perms"),
            )
        res_metadata = res_req_metadata.json()
        country = res_metadata["exifInfo"].get("country")
        state = res_metadata["exifInfo"].get("state")
        city = res_metadata["exifInfo"].get("city")
        photo_date = res_metadata["exifInfo"].get("dateTimeOriginal")
        return render.Root(
            child = render.Stack(
                children = [
                    render.Box(
                        padding = 1,
                        color = "#fff",
                        child = render.Image(
                            src = res_img.body(),
                            width = 62,
                            height = 30,
                        ),
                    ),
                    render.Column(
                        children = get_text(photo_date, country, state, city, SHOW_DATE, SHOW_LOCATION),
                        main_align = "end",
                        expanded = True,
                    ),
                ],
            ),
        )

def get_text(date, country, state, city, toggle_date, toggle_location):
    font = "CG-pixel-3x5-mono"
    bgcolor = "#00000078"
    strdate = parse_date(date)
    full_string = ""

    if toggle_date:
        full_string += "%s" % strdate

    if toggle_location and country != None:
        if toggle_date:
            full_string += " | "
        full_string += "%s, %s, %s" % (city, state, country)
    if full_string == "":
        return []
    else:
        return [
            render.Padding(
                child = render.Marquee(
                    child = render.Text(
                        content = full_string,
                        font = font,
                        height = 5,
                    ),
                    width = 62,
                    height = 5,
                ),
                pad = (1, 1, 1, 1),
                color = bgcolor,
            ),
        ]

def parse_date(date):
    splitDate = date.split("-")
    year = splitDate[0]
    month = splitDate[1]
    day = splitDate[2].split("T")[0]

    return "%s/%s/%s" % (month, day, year)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "immich_url",
                name = "Immich Instance URL",
                desc = "The URL for your Immich Instance",
                icon = "globe",
            ),
            schema.Text(
                id = "immich_api_key",
                name = "Immich API Key",
                desc = "Your Immich API key. See Immich documentation on how you can retrieve this.",
                icon = "key",
            ),
            schema.Toggle(
                id = "show_favorites",
                name = "Show Favorites",
                desc = "(Does nothing right now) Show the images that you have added to your favorites. This will override any albums you have selected to be shown",
                icon = "heart",
                default = False,
            ),
            schema.Text(
                id = "immich_album_id",
                name = "Albums",
                desc = "Enter the UUID of the Albums you would like to be displayed",
                icon = "image",
            ),
            schema.Toggle(
                id = "show_date",
                name = "Show Date",
                desc = "Toggle to show the date that the picture shown was taken",
                icon = "calendar",
                default = True,
            ),
            schema.Toggle(
                id = "show_location",
                name = "Show Location",
                desc = "Toggle to show the location in which a picture was taken where applicable.",
                icon = "mapPin",
                default = False,
            ),
        ],
    )
