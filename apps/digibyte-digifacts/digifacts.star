"""
Applet: DigiFacts
Summary: Facts about DigiByte
Description: Shows a DigiFact - a bite-size fact about DigiByte - in your language. Choose the DigiFact of the day, or a random DigiFact each time.
Author: DigiNode Tools
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/dgb_icon.png", DGB_ICON = "file")
load("images/dgb_icon@2x.png", DGB_ICON_2X = "file")
load("qrcode.star", "qrcode")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

SITE = "https://digifacts.diginode.tools"

# Languages the display fonts can show (no fonts for Chinese, Hindi, Japanese or Korean yet)
LANGUAGES = [
    ("English", "en"),
    ("Deutsch", "de"),
    ("Español", "es"),
    ("Français", "fr"),
    ("Italiano", "it"),
    ("Nederlands", "nl"),
    ("Português", "pt"),
    ("Русский", "ru"),
]

# Fonts for each text size: (64 pixel wide displays: 64x32 and 64x64, 128x64 displays)
FONTS = {
    "small": ("tom-thumb", "terminus-12"),
    "medium": ("tb-8", "terminus-16"),
    "large": ("6x10", "terminus-20"),
}
NO_CYRILLIC = ["tom-thumb"]  # Fonts without Cyrillic letters (for Russian, the medium font is used instead)

DIGIBYTE_BLUE = "#0066cc"
TEXT_COLOR = "#ffffff"
STALE_COLOR = "#ffa500"  # The DigiFact's number is shown in amber if the website hasn't been reached for a week
CACHE_SECONDS = 3600
DAY_CACHE_SECONDS = 2 * 86400  # How long the DigiFact of the day being shown is remembered
FALLBACK_CACHE_SECONDS = 30 * 86400  # How long the DigiFacts are kept, to show if the website can't be reached
STALE_SECONDS = 7 * 86400  # After this long without reaching the website, the DigiFact's number is shown in amber
DEFAULT_CHANGE_HOUR = "4"  # The DigiFact of the day changes at 04:00, unless another time is chosen
INTRO_SECONDS = 2  # How long the DigiByte logo and the DigiFact number are shown before the DigiFact scrolls
QR_SECONDS = 5  # How long the QR code for the DigiFact's link is shown at the end

def main(config):
    lang = config.get("language", "en")
    if lang not in [code for _, code in LANGUAGES]:
        lang = "en"

    if config.get("mode", "today") == "random":
        fact = random_fact(lang)
    else:
        tz = config.get("$tz") or "UTC"
        hour = config.get("change_hour", DEFAULT_CHANGE_HOUR)
        if hour not in [str(h) for h in range(24)]:
            hour = DEFAULT_CHANGE_HOUR
        fact = fact_of_the_day(lang, tz if time.is_valid_timezone(tz) else "UTC", int(hour))
    if fact == None:
        return []  # Skip this time if the DigiFacts can't be loaded

    size = config.get("size", "medium")
    if size not in FONTS:
        size = "medium"
    return render_fact(fact, size, lang)

def get_json(url):
    # Returns the file's data, and whether it is stale: the last copy fetched, used because the website can't be
    # reached, and older than STALE_SECONDS. The last copy of each file is kept, so DigiFacts can still be shown if
    # the website can't be reached for a while.
    key = "json:" + url
    now = time.now().unix
    res = http.get(url = url, ttl_seconds = CACHE_SECONDS)
    if res.status_code == 200:
        body = res.body()
        cache.set(key, json.encode({"time": now, "body": body}), ttl_seconds = FALLBACK_CACHE_SECONDS)
        return json.decode(body), False
    print("Couldn't load %s (status %d)" % (url, res.status_code))
    saved = cache.get(key)
    if saved == None:
        return None, False
    saved = json.decode(saved)
    age = now - int(saved["time"])
    print("Using the last copy fetched, %d seconds ago" % age)
    return json.decode(saved["body"]), age > STALE_SECONDS

def header_of(title):
    # "DigiFact # 22 - Did you know..." -> "DigiFact #22" (short enough for a 64 pixel wide display)
    return title.split(" - ")[0].strip().replace("# ", "#")

def make_fact(title, social, plain, url, short_url):
    # The DigiFact's text, and its link sentence (e.g. "View more stats here:") without the address - that is shown
    # next to the link's QR code instead. The social text has the short link in lower case (older data: the full
    # address).
    link_text = ""
    if url and short_url and social.startswith(plain):
        link_text = social[len(plain):].replace(short_url.lower(), "").replace(url, "").strip()
    return {
        "header": header_of(title or "DigiFact"),
        "text": plain,
        "link": short_url if url else "",
        "link_text": link_text,
    }

def fact_of_the_day(lang, tz, change_hour):
    # The DigiFact of the day changes at midnight UTC on the website. Here it changes at the chosen hour where the
    # display is: the DigiFact being shown is remembered until the local day changes, then the newest one is shown.
    latest, stale = get_json("%s/%s/today.json" % (SITE, lang))
    if latest != None and not latest.get("plain"):
        latest = None

    # The local day starts at the chosen hour, so it is the date that hour's worth of time ago
    local_date = (time.now().in_location(tz) - time.parse_duration("%dh" % change_hour)).format("2006-01-02")

    # The cache is shared by every display using this app, so remember a DigiFact for each language, time zone and
    # change time
    key = "today:%s:%s:%d" % (lang, tz, change_hour)
    saved = cache.get(key)
    saved = json.decode(saved) if saved else None

    if saved != None and saved["local_date"] == local_date:
        data = saved["fact"]
    elif latest != None and (saved == None or latest.get("date", "") > saved["fact"].get("date", "")):
        # A new day here, and a newer DigiFact of the day to show
        data = {k: latest.get(k, "") for k in ["date", "title", "text", "plain", "url", "short_url"]}
        cache.set(key, json.encode({"local_date": local_date, "fact": data}), ttl_seconds = DAY_CACHE_SECONDS)
    elif saved != None:
        # A new day here, but the next DigiFact of the day isn't out yet (it is published just after midnight UTC),
        # or the website can't be reached: keep showing the last one
        data = saved["fact"]
    else:
        return None
    fact = make_fact(data.get("title"), data.get("text", ""), data["plain"], data.get("url", ""), data.get("short_url", ""))
    fact["stale"] = stale
    return fact

def random_fact(lang):
    social, social_stale = get_json("%s/%s/social.json" % (SITE, lang))
    plain, plain_stale = get_json("%s/%s/plain.json" % (SITE, lang))
    if social == None or plain == None or len(plain) == 0:
        return None
    keys = list(plain.keys())
    key = keys[random.number(0, len(keys) - 1)]
    data = plain[key]
    fact = make_fact(data.get("title"), social.get(key, {}).get("content", ""), data.get("content", ""), data.get("url", ""), data.get("short_url", ""))
    fact["stale"] = social_stale or plain_stale
    return fact

def text_width(text, font):
    return render.Text(text, font = font).size()[0]

def wrap(text, font, width):
    # Word wrap, measuring each line - so the height of the DigiFact is known exactly (render.WrappedText can't
    # say how tall it is), and the scroll can stop with the QR code in view
    lines = []
    for paragraph in text.split("\n"):
        line = ""
        for word in paragraph.split(" "):
            if not word:
                continue
            candidate = line + " " + word if line else word
            if text_width(candidate, font) <= width:
                line = candidate
                continue
            if line:
                lines.append(line)
            line = ""
            for ch in word.elems():  # A word wider than the display is split across lines
                if text_width(line + ch, font) > width and line:
                    lines.append(line)
                    line = ""
                line += ch
        if line:
            lines.append(line)
    return lines

def logo(big):
    # The hand-drawn 18x18 DigiByte logo, or the smoothed 36x36 version for bigger displays
    if big:
        return render.Image(src = DGB_ICON_2X.readall(), width = 36, height = 36)
    return render.Image(src = DGB_ICON.readall(), width = 18, height = 18)

def intro_card(header, width, height, font, color):
    # The DigiByte logo with the DigiFact's name and number ("DigiFact" above "#22")
    parts = header.rsplit("#", 1)
    name = [
        render.Text(parts[0].strip(), font = font, color = color),
        render.Text("#" + parts[1] if len(parts) == 2 else "", font = font, color = color),
    ]
    if width == height:
        # Square (64x64): the bigger logo, with the name and number underneath
        layout = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [logo(True), render.Column(cross_align = "center", children = name)],
        )
    else:
        layout = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [logo(canvas.is2x()), render.Column(cross_align = "center", children = name)],
        )
    return render.Box(width = width, height = height, child = layout)

def qr_size():
    return 50 if canvas.is2x() else 25

def fit_label(link_text, width, height, lang, body_font):
    # The link's sentence to show beside the QR code, in the DigiFact's font if it fits or one size smaller, starting
    # level with the top of the QR code. None if it doesn't fit (it then stays at the end of the scrolling text).
    if not link_text:
        return None
    big = canvas.is2x()
    space_w = width - qr_size() - (6 if big else 3)  # Leaves room for gaps around both
    space_h = height - (height - qr_size()) // 2

    # The DigiFact's font, or one size smaller - never smaller than that, so it stays easy to read
    sizes = ["tb-8", "terminus-12", "terminus-16", "terminus-20"] if big else ["tom-thumb", "tb-8", "6x10"]
    i = sizes.index(body_font) if body_font in sizes else 0
    for font in [body_font] + ([sizes[i - 1]] if i > 0 else []):
        if lang == "ru" and font in NO_CYRILLIC:
            continue
        if [w for w in link_text.split(" ") if text_width(w, font) > space_w]:
            continue  # A word wouldn't fit on one line - try a smaller font rather than split it
        lines = wrap(link_text, font, space_w)
        if len(lines) * render.Text("Ag", font = font).size()[1] <= space_h:
            return render.Column(children = [render.Text(line, font = font, color = TEXT_COLOR) for line in lines])
    return None

def qrcode_image(link):
    return render.Image(src = qrcode.generate(url = link, size = "medium", color = TEXT_COLOR, background = "#000"))

def qr_card(link, label, width, height):
    # The DigiFact's short link as a QR code (white on black - the dark display around it is its border), in the
    # middle of the display. If the link's sentence fits, it's on the left, starting level with the top of the QR
    # code so it reads on from the DigiFact.
    qr = qrcode_image(link)
    if not label:
        return render.Box(width = width, height = height, child = qr)  # Box centres it
    qr_top = (height - qr_size()) // 2
    row = render.Row(expanded = True, main_align = "space_evenly", cross_align = "start", children = [label, qr])
    return render.Box(
        width = width,
        height = height,
        child = render.Column(expanded = True, main_align = "start", children = [render.Box(width = width, height = qr_top), row]),
    )

def hold(widget, seconds, delay):
    return render.Animation(children = [widget] * (seconds * 1000 // delay))

def scroll(column, width, view_height, distance, start_frames, end_frames):
    # Scroll the column up by exactly `distance` pixels (one pixel a frame), holding it still for start_frames
    # first and end_frames at the end. (render.Marquee always scrolls its content right off, so it can't stop with
    # the QR code in view.) The animation is as tall as everything that scrolls, so all of it gets drawn; the
    # display (or the layout around it) clips it to what's visible.
    total = start_frames + distance + end_frames
    return animation.Transformation(
        child = column,
        duration = total,
        width = width,
        height = view_height + distance,
        keyframes = [
            animation.Keyframe(percentage = 0.0, transforms = [animation.Translate(0, 0)]),
            animation.Keyframe(percentage = start_frames / total, transforms = [animation.Translate(0, 0)]),
            animation.Keyframe(percentage = (start_frames + distance) / total, transforms = [animation.Translate(0, -distance)]),
            animation.Keyframe(percentage = 1.0, transforms = [animation.Translate(0, -distance)]),
        ],
    )

def render_fact(fact, size, lang):
    # Works on every display: 64x32, 128x64 (2x) and 64x64 (square). The DigiByte logo and the DigiFact's number are
    # shown first. On 64x32 and 128x64 they then scroll up off the display, with the DigiFact following; on 64x64 the
    # DigiFact scrolls up under a header. If the DigiFact has a link, its QR code slides up underneath the text and
    # stays on the display for a few seconds; otherwise the text scrolls off.
    # show_full_animation lets Tronbyt play the whole DigiFact, however long it is.
    width, height = canvas.size()
    big = canvas.is2x()
    square = width == height
    delay = 37 if big else 75  # The same speed on every display (128x64 has twice as many pixels)
    intro_frames = INTRO_SECONDS * 1000 // delay
    qr_frames = QR_SECONDS * 1000 // delay

    body_font = FONTS[size][1] if big else FONTS[size][0]
    if lang == "ru" and body_font in NO_CYRILLIC:
        body_font = FONTS["medium"][0]
    title_font = "terminus-16" if big else "tb-8"
    line_height = render.Text("Ag", font = body_font).size()[1]
    header_height = 9 if square else 0  # The square display keeps a header (8 pixels, then a 1 pixel gap)
    view = height - header_height

    # On the square display the link sentence stays in the text: there's room for the last few lines of text above
    # the QR code, so the QR code follows the text closely and stops at the bottom of the display.
    label = fit_label(fact["link_text"], width, view, lang, body_font) if fact.get("link") and not square else None
    text_to_show = fact["text"]
    if fact.get("link") and fact["link_text"] and not label:
        text_to_show = text_to_show + " " + fact["link_text"]  # Too long to fit beside the QR code

    # Space between the text and the QR card. With nothing beside the QR code, the card's own space above the code
    # is enough: the text leaves the top of the display just as the QR code stops in the middle.
    gap = line_height // 2 if label else 0

    # On the square display the QR code stops in the middle of the space below the banner (its top this far down)
    qr_stop = (view - qr_size()) // 2
    if square:
        # Just enough space above the QR code that the lines above it are all whole (none cut off under the banner)
        gap = qr_stop % line_height
        if gap < 2:
            gap += line_height
    lines = wrap(text_to_show, body_font, width)
    text = render.Column(children = [render.Text(line, font = body_font, color = TEXT_COLOR) for line in lines])
    text_height = len(lines) * line_height

    header_color = STALE_COLOR if fact.get("stale") else TEXT_COLOR
    intro = intro_card(fact["header"], width, height, title_font, header_color)

    # What scrolls: (the intro card on wide displays,) the text, then the QR code, which ends up filling the view
    if square:
        children = [render.Box(width = width, height = view), text]  # The text starts just below the view
        top = view
    else:
        children = [intro, text]
        top = height
    if fact.get("link"):
        if gap:
            children.append(render.Box(width = width, height = gap))  # (A Box with height 0 would fill the space)
        if square:
            # Just the QR code, centred across the display; it stops in the middle of the space below the banner,
            # with the end of the text above it
            children.append(render.Box(width = width, height = qr_size(), child = qrcode_image(fact["link"])))
            distance = max(0, top + text_height + gap - qr_stop)
        else:
            children.append(qr_card(fact["link"], label, width, view))
            distance = top + text_height + gap
        end_frames = qr_frames
    else:
        distance = top + text_height  # Scroll the text right off
        end_frames = 0
    moving = scroll(render.Column(children = children), width, view, distance, 0 if square else intro_frames, end_frames)

    if square:
        banner = render.Box(
            width = width,
            height = 8,
            color = DIGIBYTE_BLUE,
            child = render.Text(fact["header"], font = "tb-8", color = header_color),
        )
        body = render.Column(children = [banner, render.Box(width = width, height = 1), moving])
        parts = [hold(intro, INTRO_SECONDS, delay), body]
        if not fact.get("link"):
            # The text has scrolled off - slide the banner up off too, so it ends on black
            parts.append(scroll(banner, width, header_height, header_height, 0, 0))
        return render.Root(delay = delay, show_full_animation = True, child = render.Sequence(children = parts))

    return render.Root(delay = delay, show_full_animation = True, child = moving)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "language",
                name = "Language",
                desc = "The language of the DigiFacts.",
                icon = "language",
                default = "en",
                options = [schema.Option(display = name, value = code) for name, code in LANGUAGES],
            ),
            schema.Dropdown(
                id = "size",
                name = "Text size",
                desc = "The size of the DigiFact text.",
                icon = "textHeight",
                default = "medium",
                options = [
                    schema.Option(display = "Small", value = "small"),
                    schema.Option(display = "Medium", value = "medium"),
                    schema.Option(display = "Large", value = "large"),
                ],
            ),
            schema.Dropdown(
                id = "mode",
                name = "Show",
                desc = "The DigiFact of the day, or a random DigiFact each time.",
                icon = "lightbulb",
                default = "today",
                options = [
                    schema.Option(display = "DigiFact of the day", value = "today"),
                    schema.Option(display = "A random DigiFact", value = "random"),
                ],
            ),
            schema.Dropdown(
                id = "change_hour",
                name = "New DigiFact at",
                desc = "When the DigiFact of the day changes, in your time zone.",
                icon = "clock",
                default = DEFAULT_CHANGE_HOUR,
                options = [schema.Option(display = ("0%d:00" % h)[-5:], value = str(h)) for h in range(24)],
            ),
        ],
    )
