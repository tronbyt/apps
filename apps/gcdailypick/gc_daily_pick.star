"""
Applet: GC Daily Pick
Summary: Guitar Center daily pick
Description: Shows the daily pick deal from Guitar Center.
Author: Bennett Schoonerman
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/guitarCenter.png", GUITAR_CENTER_LOGO_ASSET = "file")
load("images/musiciansFriend.png", MUSICIANS_FRIEND_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

# only changes once per day but we will refetch on the hour to be safe
CACHE_TTL = 3600

GOOGLE_SHEET_CSV_URL = "https://docs.google.com/spreadsheets/d/1z4UprVH5z79gc85e_inF0NDzAD7pmmExNme1V17Ne-c/export?format=csv&"
SOURCE_SHEETS = {
    "guitar_center": "gid=1900080353",
    "musicians_friend": "gid=1879148122",
}

SOURCE_OPTIONS = [
    schema.Option(
        display = "Guitar Center",
        value = "guitar_center",
    ),
    schema.Option(
        display = "Musician's Friend",
        value = "musicians_friend",
    ),
]

def splitCsvLine(line):
    cells = []
    current = ""
    in_quotes = False

    i = 0
    for i in range(len(line)):
        char = line[i]
        if char == '"':
            if in_quotes and i + 1 < len(line) and line[i + 1] == '"':
                current += '"'
                i = i + 1
            else:
                in_quotes = not in_quotes
        elif char == "," and not in_quotes:
            cells.append(current)
            current = ""
        else:
            current += char

    cells.append(current)
    return cells

def fetchDealImage(image_url):
    if image_url == "":
        return GUITAR_CENTER_LOGO_ASSET.readall()

    resp = http.get(url = image_url, ttl_seconds = CACHE_TTL)
    if resp.status_code != 200:
        return GUITAR_CENTER_LOGO_ASSET.readall()
    return resp.body()

def parseDealRow(raw_csv):
    lines = raw_csv.split("\n")
    if len(lines) < 2:
        return {}

    header = splitCsvLine(lines[0])
    latest_row = {}
    latest_timestamp = ""

    for i in range(1, len(lines)):
        row_text = lines[i]
        if row_text == "":
            continue

        values = splitCsvLine(row_text)
        if len(values) < len(header):
            continue

        row = {}
        for j in range(len(header)):
            key = header[j].strip()
            row[key] = values[j].strip()

        row_timestamp = row.get("scrapedAt", "")
        if row_timestamp > latest_timestamp:
            latest_row = row
            latest_timestamp = row_timestamp

    return latest_row

def getDailyPick(source_name):
    selected_sheet = SOURCE_SHEETS.get(source_name, SOURCE_SHEETS["guitar_center"])
    sheet_url = GOOGLE_SHEET_CSV_URL + selected_sheet
    resp = http.get(url = sheet_url, ttl_seconds = CACHE_TTL)
    row = parseDealRow(resp.body())

    if row == {}:
        return {
            "itemName": "Daily Pick",
            "originalPrice": "$0.00",
            "savings": "$0.00",
            "price": "$0.00",
            "dealImage": GUITAR_CENTER_LOGO_ASSET.readall(),
        }

    discount = row.get("discount", "$0.00")
    if discount == "":
        discount = "$0.00"

    return {
        "itemName": row.get("title", "Daily Pick"),
        "originalPrice": row.get("originalPrice", "$0.00"),
        "savings": discount,
        "price": row.get("price", discount),
        "dealImage": fetchDealImage(row.get("image", "")),
    }

def getBrandLabel(source_name):
    if source_name == "musicians_friend":
        return "MF"
    return "GC"

def getBrandLogo(source_name):
    if source_name == "musicians_friend":
        return MUSICIANS_FRIEND_LOGO_ASSET.readall()
    return GUITAR_CENTER_LOGO_ASSET.readall()

def main(config):
    source_name = config.get("source", "guitar_center")
    if source_name not in SOURCE_SHEETS:
        source_name = "guitar_center"

    data = getDailyPick(source_name)
    brand_label = getBrandLabel(source_name)
    brand_logo = getBrandLogo(source_name)
    deal_image = render.Box(
        width = 24,
        height = 24,
        color = "#111111",
        child = render.Text(brand_label, color = "#FFFFFF", font = "tb-8"),
    )
    if data["dealImage"] != "":
        deal_image = render.Image(width = 24, height = 24, src = data["dealImage"])

    # print(data)
    return render.Root(
        child = render.Stack(
            children = [
                animation.Transformation(
                    duration = 350,
                    child = render.Box(
                        width = 64,
                        height = 32,
                        color = "#020202",
                        child = render.Image(brand_logo, width = 64, height = 32),
                    ),
                    keyframes = [
                        #slide GC logo up
                        animation.Keyframe(
                            percentage = 0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 0.1,
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = 0.2,
                            transforms = [animation.Translate(0, -64)],
                        ),
                        animation.Keyframe(
                            percentage = 1,
                            transforms = [animation.Translate(0, -64)],
                            curve = "ease_in",
                        ),
                    ],
                ),
                animation.Transformation(
                    duration = 350,
                    child = render.Column(
                        children = [
                            render.Marquee(
                                width = 64,
                                child = render.Text(data["itemName"], ""),
                                offset_start = 4,
                                offset_end = 64,
                                delay = 75,
                            ),
                            render.Row(
                                children = [
                                    render.Column(
                                        children = [
                                            render.Box(width = 40, height = 8, child = render.Row(children = [render.Text(content = data["originalPrice"])])),
                                            render.Box(width = 40, height = 8, child = render.Text(content = "-" + data["savings"], color = "#EA202E")),
                                            render.Box(width = 40, height = 1, child = render.Row(children = [render.Box(width = 30, height = 1, color = "#ccc")])),
                                            render.Box(width = 40, height = 8, child = render.Text(content = data["price"], color = "#85BB65")),
                                        ],
                                    ),
                                    deal_image,
                                ],
                            ),
                        ],
                    ),
                    keyframes = [
                        #slide GC logo up
                        animation.Keyframe(
                            percentage = 0,
                            transforms = [animation.Translate(0, 64)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            percentage = 0.1,
                            transforms = [animation.Translate(0, 64)],
                            curve = "ease_out",
                        ),
                        animation.Keyframe(
                            percentage = 0.20,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "source",
                name = "Source",
                desc = "Choose where to pull the daily pick from.",
                icon = "guitar",
                options = SOURCE_OPTIONS,
                default = "guitar_center",
            ),
        ],
    )
