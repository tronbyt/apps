"""
Applet: GC Daily Pick
Summary: Guitar Center daily pick
Description: Shows the daily pick deal from Guitar Center.
Author: Bennett Schoonerman
"""

load("animation.star", "animation")
load("html.star", "html")
load("http.star", "http")
load("images/guitar_center_logo.png", GUITAR_CENTER_LOGO_ASSET = "file")
load("render.star", "render")

GUITAR_CENTER_LOGO = GUITAR_CENTER_LOGO_ASSET.readall()

# only changes once per day but we will refetch on the hour to be safe
CACHE_TTL = 3600

# Load Guitar Center logo from base64 encoded data

def fetchDealImage(page):
    imageUrl = page.find(".daily_pick_content .dealImage").attr("src")
    resp = http.get(
        url = imageUrl,
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        },
        ttl_seconds = CACHE_TTL,
    )
    return resp.body()

# helper to remove new lines like Price or Save that is part of the scraped text
def polishStrings(input_string):
    # Find the indices of '\n' and '\u00a0'
    start_index = input_string.find("\n")
    end_index = input_string.find("\u00a0")

    if start_index != -1 and end_index != -1:
        modified_string = input_string[:start_index] + input_string[end_index + 2:]
        return modified_string
    else:
        return input_string

def extractDealInfo(page):
    dealImageData = fetchDealImage(page)
    data = {
        "itemName": page.find(".daily_pick_content .displayNameColor").text(),
        "originalPrice": page.find(".dailypick-was .price-display-value").text(),
        "savings": polishStrings(page.find(".daily_pick_content .dailypick-save").text()),
        "price": polishStrings(page.find(".daily_pick_content .dailypick-price").text()),
        "dealImage": dealImageData,
    }
    return data

def getDailyPick():
    resp = http.get(
        url = "https://www.guitarcenter.com/Daily-Pick.gc",
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        },
        ttl_seconds = CACHE_TTL,
    )
    page = html(resp.body())
    return extractDealInfo(page)

def main():
    data = getDailyPick()

    # print(data)
    return render.Root(
        child = render.Stack(
            children = [
                animation.Transformation(
                    duration = 450,
                    child = render.Image(src = GUITAR_CENTER_LOGO, width = 64, height = 32),
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
                    duration = 450,
                    child = render.Column(
                        children = [
                            render.Marquee(
                                width = 64,
                                child = render.Text(data["itemName"], ""),
                                offset_start = 5,
                                offset_end = 32,
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
                                    render.Image(width = 24, height = 24, src = data["dealImage"]),
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
