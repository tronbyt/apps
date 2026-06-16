"""
Applet: This Day History
Summary: Historical events today
Description: Display historical events from today including births and deaths (if selected).  Uses Wikipedia information.
Author: jvivona
"""

# 2025-apr-01 - change URL to wikipedia REST API instead of the FEED api.   more reliable apparently
# 2026-may-31 - switch to pre-generated tidbyt-data JSON (jvivona/tidbyt-data).  The generator pre-shuffles
#               the metadata index orderings throughout the day, giving us a "semi-random" item per fetch
#               without an in-app RNG.  Languages that lack births/deaths get an extra event substituted in.

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

VERSION = 26167

# 2x (128x64) uses the wider canvas and a larger font; 1x is unchanged.
IS2X = canvas.is2x()

TEXT_COLOR = "#fff"
TITLE_TEXT_COLOR = "#fff"
TITLE_BKG_COLOR = "#6666ff88"
TITLE_FONT = "tb-8" if IS2X else "tom-thumb"
TITLE_HEIGHT = 9 if IS2X else 7
TITLE_WIDTH = 128 if IS2X else 64

# tb-8 centers cleanly with no offset (matches the news apps); tom-thumb at 1x
# still wants the -1 nudge.
TITLE_OFFSET = 0 if IS2X else -1

ARTICLE_SUB_TITLE_FONT = "tb-8" if IS2X else "tom-thumb"
ARTICLE_SUB_TITLE_COLOR = "#ff8c00"
ARTICLE_COLOR = "#00eeff"
SPACER_COLOR = "#000"
ARTICLE_AREA_HEIGHT = 55 if IS2X else 24
SPACER_HEIGHT = 6 if IS2X else 3

# data is regenerated through the day with a freshly shuffled item ordering - cache 1 hour so each refresh
# surfaces a new "semi-random" selection while still saving network traffic.
CACHE_TTL_SECONDS = 3600

# pre-generated data feed (jvivona/tidbyt-data).  English lives at the root; other languages under /<lang>/.
DATA_BASE_URL = "https://raw.githubusercontent.com/jvivona/tidbyt-data/main/thisdayinhistwikipedia/"
DATA_FILE = "thisdayinhist.json"

ENGLISH = "en"
SPANISH = "es"
GERMAN = "de"
ITALIAN = "it"

BIRTHS = "births"
DEATHS = "deaths"
EVENTS = "events"
METADATA = "metadata"
LANGUAGE = "language"

OPTBIRTHS = "inch_births"
OPTDEATHS = "incl_deaths"
OPTDISPLANG = "displayLanguage"

# In-app strings used by the schema UI (rendered before any data fetch) plus fallbacks for the error path.
# Content titles and the b/d year prefixes now come from the feed's metadata.language element.
LANG = {
    "es": {
        "title": "Hoy en Historia",
        "Include Births": "Incluir Nacimientos",
        "Include random person who was born on this day.": "Incluir una persona al azar que nació en este día",
        "Include Deaths": "Incluir Defunciones",
        "Include random person who died on this day.": "Incluir una persona al azar que falleció en este día",
        "Data error": "Error {} de datos",
    },
    "en": {
        "title": "Today in History",
        "Include Births": "Include Births",
        "Include random person who was born on this day.": "Include random person who was born on this day.",
        "Include Deaths": "Include Deaths",
        "Include random person who died on this day.": "Include random person who died on this day.",
        "Data error": "Data {} error.",
    },
    "de": {
        "title": "Geschichte heute",
        "Include Births": "Mit Geburtstagen",
        "Include random person who was born on this day.": "Eine zufällige Person, die am heutigen Tag geboren wurde, einbeziehen.",
        "Include Deaths": "Mit Todestagen",
        "Include random person who died on this day.": "Eine zufällige Person, die am heutigen Tag gestorben ist, einbeziehen.",
        "Data error": "Fehler {} der Daten.",
    },
    "it": {
        "title": "Oggi nella Storia",
        "Include Births": "Includi Nascite",
        "Include random person who was born on this day.": "Includi una persona a caso nata in questo giorno.",
        "Include Deaths": "Includi Morti",
        "Include random person who died on this day.": "Includi una persona a caso morta in questo giorno.",
        "Data error": "Errore dati {}.",
    },
}

def main(config):
    language = config.get(OPTDISPLANG, ENGLISH)
    rc, json_data = getData(language)

    if rc == 0:
        title = json_data[METADATA][LANGUAGE].get("title", LANG[language]["title"])

        # drop the "(Wikipedia)" parenthetical from the feed title (language-agnostic,
        # so localized titles keep working); attribution stays in the app description.
        title = title.replace(" (Wikipedia)", "").replace("(Wikipedia)", "")
        body = render.Marquee(
            height = ARTICLE_AREA_HEIGHT,
            scroll_direction = "vertical",
            offset_start = ARTICLE_AREA_HEIGHT,
            child = render.Column(
                main_align = "space_between",
                children = getItems(json_data, config.bool(OPTBIRTHS, True), config.bool(OPTDEATHS, True)),
            ),
        )
    else:
        title = LANG[language]["title"]
        body = render.WrappedText(json_data, font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR)

    return render.Root(
        delay = 100,
        show_full_animation = True,
        child = render.Column(
            children = [
                render.Box(
                    width = TITLE_WIDTH,
                    height = TITLE_HEIGHT,
                    padding = 0,
                    color = TITLE_BKG_COLOR,
                    child = render.Marquee(
                        width = TITLE_WIDTH,
                        align = "center",
                        child = render.Text(title, color = TITLE_TEXT_COLOR, font = TITLE_FONT, offset = TITLE_OFFSET),
                    ),
                ),
                body,
            ],
        ),
    )

def getItems(json_data, incl_births, incl_deaths):
    meta = json_data[METADATA]
    lang = meta[LANGUAGE]
    prefix_b = "{}. ".format(lang.get("b", "b"))
    prefix_d = "{}. ".format(lang.get("d", "d"))

    events = json_data.get(EVENTS, [])
    births = json_data.get(BIRTHS, [])
    deaths = json_data.get(DEATHS, [])
    events_order = meta.get(EVENTS, [])
    births_order = meta.get(BIRTHS, [])
    deaths_order = meta.get(DEATHS, [])

    # 2x has the vertical room for a richer feed: two births and two deaths.
    # A disabled toggle or a language with no births/deaths (e.g. Italian) is
    # back-filled with the same count of extra events so the layout stays full.
    # 1x is unchanged: one pick per enabled section, nothing when a toggle is off.
    per_section = 2 if IS2X else 1

    this_day = []
    cursor = 0

    # two primary events - the metadata ordering is reshuffled through the day,
    # so the leading positions are our semi-random picks
    for _ in range(2):
        item, cursor = pickFromOrder(events, events_order, cursor)
        if item != None:
            this_day += displayItem(item, "")

    # births then deaths - substituted events are drawn from the same shared
    # cursor so nothing repeats across the layout
    birth_items, cursor = sectionItems(incl_births, births, births_order, prefix_b, per_section, events, events_order, cursor)
    this_day += birth_items

    death_items, cursor = sectionItems(incl_deaths, deaths, deaths_order, prefix_d, per_section, events, events_order, cursor)
    this_day += death_items

    return this_day

def sectionItems(incl, items, order, prefix, per_section, events, events_order, cursor):
    # Build the display rows for a births/deaths section, returning the rows and
    # the advanced events cursor.
    out = []

    # A disabled section shows nothing at 1x (original behavior).  At 2x we keep
    # the canvas full by substituting the section's worth of extra events.
    if not incl:
        if IS2X:
            out, cursor = addEvents(out, events, events_order, cursor, per_section)
        return out, cursor

    # Enabled: take up to per_section picks from the section's shuffled order,
    # back-filling any shortfall (missing or short data) with extra events.
    sect_cursor = 0
    for _ in range(per_section):
        item, sect_cursor = pickFromOrder(items, order, sect_cursor)
        if item != None:
            out += displayItem(item, prefix)
        else:
            out, cursor = addEvents(out, events, events_order, cursor, 1)

    return out, cursor

def addEvents(out, events, events_order, cursor, count):
    # Append `count` extra events to `out`, advancing the shared events cursor.
    for _ in range(count):
        item, cursor = pickFromOrder(events, events_order, cursor)
        if item != None:
            out += displayItem(item, "")
    return out, cursor

def displayItem(item, prefix):
    return [
        render.Text("{}{}".format(prefix, int(item["year"])), color = ARTICLE_SUB_TITLE_COLOR, font = ARTICLE_SUB_TITLE_FONT),
        render.WrappedText(item["text"], font = ARTICLE_SUB_TITLE_FONT, color = ARTICLE_COLOR),
        render.Box(width = TITLE_WIDTH, height = SPACER_HEIGHT, color = SPACER_COLOR),
    ]

def pickFromOrder(items, order, cursor):
    # walk the ordering from cursor, returning the item and the advanced cursor (for event substitution)
    if cursor < len(order):
        idx = int(order[cursor])
        if idx >= 0 and idx < len(items):
            return items[idx], cursor + 1
        return None, cursor + 1
    if cursor < len(items):
        return items[cursor], cursor + 1
    return None, cursor

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = OPTDISPLANG,
                name = "English / Español / Deutsch / Italiano",
                desc = "",
                icon = "hashtag",
                default = ENGLISH,
                options = [
                    schema.Option(
                        display = "English",
                        value = ENGLISH,
                    ),
                    schema.Option(
                        display = "Español",
                        value = SPANISH,
                    ),
                    schema.Option(
                        display = "Deutsch",
                        value = GERMAN,
                    ),
                    schema.Option(
                        display = "Italiano",
                        value = ITALIAN,
                    ),
                ],
            ),
            schema.Generated(
                id = "generated",
                source = OPTDISPLANG,
                handler = includeOptions,
            ),
        ],
    )

def includeOptions(language):
    return [
        schema.Toggle(
            id = OPTBIRTHS,
            name = LANG[language]["Include Births"],
            desc = LANG[language]["Include random person who was born on this day."],
            icon = "baby",
            default = True,
        ),
        schema.Toggle(
            id = OPTDEATHS,
            name = LANG[language]["Include Deaths"],
            desc = LANG[language]["Include random person who died on this day."],
            icon = "bookSkull",
            default = True,
        ),
    ]

def getData(language):
    # English lives at the feed root; other languages live under a /<lang>/ subfolder.
    if language == ENGLISH:
        url = DATA_BASE_URL + DATA_FILE
    else:
        url = DATA_BASE_URL + language + "/" + DATA_FILE

    response = http.get(url = url, ttl_seconds = CACHE_TTL_SECONDS)
    if response.status_code != 200:
        return -1, LANG[language]["Data error"].format(str(response.status_code))

    return 0, response.json()
