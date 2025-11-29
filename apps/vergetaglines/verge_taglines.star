"""
Applet: Verge Taglines
Summary: The Verge's latest tagline
Description: Displays the latest tagline from the top of popular tech news site The Verge (dot com).
Author: joevgreathead
"""

load("cache.star", "cache")
load("html.star", "html")
load("http.star", "http")
load("images/new_verge_logo.png", NEW_VERGE_LOGO_ASSET = "file")
load("images/placeholder_img.png", PLACEHOLDER_IMG_ASSET = "file")
load("images/verge_logo.png", VERGE_LOGO_ASSET = "file")
load("random.star", "random")
load("render.star", "render")

NEW_VERGE_LOGO = NEW_VERGE_LOGO_ASSET.readall()
PLACEHOLDER_IMG = PLACEHOLDER_IMG_ASSET.readall()
VERGE_LOGO = VERGE_LOGO_ASSET.readall()

# 16x16

NEW_VERGE_TEAL = "#3cffd0"
NEW_VERGE_PURP = "#5200ff"
NEW_VERGE_ORAN = "#ff3d00"
NEW_VERGE_YELL = "#d6f31f"
NEW_VERGE_PINK = "#ffc2e7"

PLACEHOLDER_TEXT = "THE VERGE"

SITE = "https://www.theverge.com"
CACHE_KEY_TAGLINE = "verge-dot-com-tagline"
CACHE_KEY_TAGLINE_BACKUP = "verge-dot-com-tagline-backup"
SELECTOR_TAGLINE = ".duet--recirculation--storystream-header"

def main():
    tagline = cache.get(CACHE_KEY_TAGLINE)
    tagline_backup = cache.get(CACHE_KEY_TAGLINE_BACKUP)

    if tagline == None:
        resp = http.get(SITE)
        resp_body = html(resp.body())
        tagline = get_tagline(resp_body)
        if tagline == None or tagline == "":
            if tagline_backup == None:
                tagline = PLACEHOLDER_TEXT
                display = PLACEHOLDER_TEXT
            else:
                tagline = tagline_backup
                display = "* " + tagline_backup
        else:
            display = tagline

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(CACHE_KEY_TAGLINE, tagline, ttl_seconds = 900)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(CACHE_KEY_TAGLINE_BACKUP, tagline, ttl_seconds = 1200)
    else:
        display = tagline

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = content(display),
        ),
    )

def get_tagline(html_body):
    text = html_body.find(SELECTOR_TAGLINE).children().find("span > a").text()
    if text == None:
        return PLACEHOLDER_TEXT
    else:
        return text

def content(value):
    return [
        image_stack(),
        render.Marquee(
            height = 8,
            width = 64,
            scroll_direction = "horizontal",
            align = "center",
            offset_start = 64,
            offset_end = 64,
            child = render.Text(
                content = value,
            ),
        ),
    ]

def background():
    number = random.number(1, 100)
    if number <= 20:
        return NEW_VERGE_ORAN
    elif number > 20 and number <= 40:
        return NEW_VERGE_PINK
    elif number > 40 and number <= 60:
        return NEW_VERGE_YELL
    elif number > 60 and number <= 80:
        return NEW_VERGE_TEAL
    else:
        return NEW_VERGE_PURP

def image_stack():
    return render.Box(
        color = background(),
        child = render.Image(src = NEW_VERGE_LOGO),
        height = 24,
        width = 64,
    )
