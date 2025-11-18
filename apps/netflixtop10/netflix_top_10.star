"""
Applet: Netflix Top 10
Summary: Top shows on Netflix
Description: Shows the top 10 charts for movies or TV shows on Netflix.
Author: Matt Broussard, gabe565
"""

load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")

TTL_SECONDS = 3 * 60 * 60

REGION_GLOBAL = "global"
REGION_UNITED_STATES = "united-states"

CATEGORY_FILMS_ENGLISH = "Films (English)"
CATEGORY_FILMS_NON_ENGLISH = "Films (Non-English)"
CATEGORY_TV_ENGLISH = "TV (English)"
CATEGORY_TV_NON_ENGLISH = "TV (Non-English)"
CATEGORY_FILMS = "Films"
CATEGORY_TV = "TV"

CATEGORY_MAPPING = {
    CATEGORY_FILMS_ENGLISH: "films",
    CATEGORY_FILMS_NON_ENGLISH: "films-non-english",
    CATEGORY_TV_ENGLISH: "tv",
    CATEGORY_TV_NON_ENGLISH: "tv-non-english",
    CATEGORY_FILMS: "films",
    CATEGORY_TV: "tv",
}

FONT_LARGE = "large"
FONT_SMALL = "small"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll_direction",
                name = "Scroll Direction",
                desc = "The direction to scroll text. If horizontal, you'll see a fixed number of entries but the titles will scroll. If vertical, you can see all of the top 10, but the titles will be truncated.",
                icon = "arrowsUpDownLeftRight",
                default = "vertical",
                options = [
                    schema.Option(display = "Vertical", value = "vertical"),
                    schema.Option(display = "Horizontal", value = "horizontal"),
                    schema.Option(display = "Off", value = "off"),
                ],
            ),
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "The region for which to show the Netflix chart.",
                icon = "globe",
                default = REGION_GLOBAL,
                options = get_regions(),
            ),
            schema.Generated(
                id = "category_gen",
                source = "region",
                handler = gen_category_dropdown,
            ),
            schema.Dropdown(
                id = "font_size",
                name = "Font",
                desc = "Font size. Small allows 5 rows on screen; large only allows 4.",
                icon = "font",
                default = "large",
                options = [
                    schema.Option(display = "Large", value = "large"),
                    schema.Option(display = "Small", value = "small"),
                ],
            ),
        ],
    )

def main(config):
    width, height, is2x = canvas.width(), canvas.height(), canvas.is2x()

    region = config.get("region", REGION_GLOBAL)
    category = config.get("category", default_category_for_region(region))
    scroll_direction = config.get("scroll_direction", "vertical")

    font_size = config.get("font_size", FONT_LARGE)

    if font_size == FONT_LARGE:
        font = "terminus-16-light" if is2x else "tb-8"
    else:
        font = "terminus-12" if is2x else "tom-thumb"

    n = 10 if scroll_direction == "vertical" else 4 if font_size == FONT_LARGE else 5
    rows = get_entries(region, category, n)

    # workaround: when changing regions, can have a category setting left over from previous region
    # that matches nothing in the current region
    if len(rows) == 0:
        rows = get_entries(region, default_category_for_region(region), n)

    spacer_width = width // 32

    def h_marquee(child):
        if scroll_direction == "horizontal":
            left_col_width, _ = render.Text("1:", font = font).size()
            left_col_width += spacer_width
            return render.Marquee(child = child, width = width - left_col_width)
        else:
            return child

    def v_marquee(child):
        if scroll_direction == "vertical":
            return render.Marquee(child = child, scroll_direction = "vertical", height = height)
        else:
            return child

    col_spacer = render.Box(width = spacer_width, height = height) if scroll_direction != "vertical" else None

    return render.Root(
        child = v_marquee(
            render.Row(
                children = [
                    render.Column(
                        children = [
                            render.Text(
                                "%d:" % (i + 1,),
                                color = "#f00",
                                font = font,
                            )
                            for i in range(len(rows))
                        ],
                    ),
                    col_spacer,
                    render.Column(
                        children = [
                            h_marquee(render.Text(row, font = font))
                            for row in rows
                        ],
                    ),
                ],
            ),
        ),
        delay = 50 if is2x else 100,
    )

def get_regions():
    url = build_page_url()
    resp = http.get(url, ttl_seconds = TTL_SECONDS)
    if resp.status_code != 200:
        fail("HTTP request failed with status {}".format(resp.status_code))

    matches = re.findall(r"\"countries\":\[.+?\]", resp.body())
    if len(matches) == 0:
        fail("Could not find countries listing")

    # Convert \xXX escape sequences to \u00XX Unicode escapes for JSON decoder
    countriesStr = "{" + re.sub(r"\\x(..)", r"\u00$1", matches[0]) + "}"
    countries = json.decode(countriesStr)

    return [
        schema.Option(display = "Global", value = REGION_GLOBAL),
        schema.Option(display = "United States", value = REGION_UNITED_STATES),
    ] + [
        schema.Option(display = country["displayName"], value = country["urlSegment"])
        for country in sorted(countries["countries"], key = lambda x: x["displayName"])
        if country["urlSegment"] != REGION_UNITED_STATES
    ]

def get_categories(region):
    if region == REGION_GLOBAL:
        return [
            CATEGORY_FILMS_ENGLISH,
            CATEGORY_FILMS_NON_ENGLISH,
            CATEGORY_TV_ENGLISH,
            CATEGORY_TV_NON_ENGLISH,
        ]
    return [CATEGORY_FILMS, CATEGORY_TV]

def default_category_for_region(region):
    return CATEGORY_FILMS_ENGLISH if region == REGION_GLOBAL else CATEGORY_FILMS

def gen_category_dropdown(region):
    categories = get_categories(region)
    return [schema.Dropdown(
        id = "category",
        name = "Category",
        desc = "The category of content to display the chart for",
        default = default_category_for_region(region),
        icon = "cameraMovie",
        options = [
            schema.Option(display = category, value = category)
            for category in categories
        ],
    )]

def category_slug(category, region = REGION_GLOBAL):
    return CATEGORY_MAPPING.get(category, default_category_for_region(region))

def build_page_url(region = REGION_GLOBAL, category = ""):
    url = "https://www.netflix.com/tudum/top10"
    if region and region != REGION_GLOBAL:
        url += "/" + region
    if category:
        url += "/" + category_slug(category, region)
    return url

def get_entries(region, category, limit):
    url = build_page_url(region, category)
    resp = http.get(url, ttl_seconds = TTL_SECONDS)
    if resp.status_code != 200:
        fail("HTTP request failed with status {}".format(resp.status_code))

    doc = html(resp.body())
    trs = doc.find("table tr")
    if trs.len() == 0:
        return []

    result = []
    for i in range(trs.len()):
        tr = trs.eq(i)
        title = tr.find("button").text().strip()
        if title:
            result.append(title)
        if limit != 0 and len(result) >= limit:
            break

    return result
