"""
Applet: Zotero Reading
Summary: Your latest highlighted paper
Description: Shows the paper you most recently highlighted in Zotero, with an optional reading streak, a two-person "reading buddies" view, and a gentle nudge when you haven't read in a while.
Author: Kai Davidson
"""

load("animation.star", "animation")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

RED = "#cc2936"
WHITE = "#ffffff"
ORANGE = "#ff9a1f"
GREY = "#9a9a9a"
BLUE = "#5ab0ff"

Z = ["11111111", "10000001", "11111011", "11110111", "11101111", "11011111", "10000001", "11111111"]

def days_ago(today, n):
    return (time.parse_time(today, format = "2006-01-02") - time.parse_duration("%dh" % (24 * n))).format("2006-01-02")

def demo_person(name, today, variant):
    """Shown when no API key is configured (app gallery preview)."""
    p = {
        "name": name,
        "title": "Attention Is All You Need",
        "authors": "Vaswani et al",
        "days": [days_ago(today, n) for n in [0, 0, 1, 2, 4]],
        "error": None,
    }
    if variant == "empty":
        p["days"] = []
    elif variant == "old":
        p["days"] = [days_ago(today, 12)]
    elif variant == "long":
        p["title"] = "Schrödinger's cat and the Ψ-function: a very long title that has to scroll"
        p["name"], p["authors"] = "Christina", "Krizhevsky & Sutskever"
    return p

NUDGES = [
    "One page today?",
    "Start a streak today",
    "Highlight one thing",
    "Future you says thanks",
    "Coffee + a paper?",
    "5 minutes, 1 abstract",
    "Your reading list misses you",
    "Day 1 starts now",
    "Science awaits",
    "Read a little, learn a lot",
]

def creator_name(c):
    return c.get("lastName") or c.get("name") or ""

def format_authors(creators):
    authors = [c for c in creators if c.get("creatorType") == "author"] or creators[:1]
    names = [creator_name(c) for c in authors]
    if len(names) == 0:
        return ""
    if len(names) == 1:
        return names[0]
    if len(names) == 2:
        return names[0] + " & " + names[1]
    return names[0] + " et al"

def to_local_day(iso, tz):
    return time.parse_time(iso).in_location(tz).format("2006-01-02")

def days_between(a, b):
    """Whole calendar days from day string a to day string b."""
    d = time.parse_time(b, format = "2006-01-02") - time.parse_time(a, format = "2006-01-02")
    return int(d.hours // 24)

def streak(days, today):
    unique = sorted({d: True for d in days}.keys(), reverse = True)

    # Alive through the day after the last highlight, so it doesn't drop to 0 each morning.
    if not unique or days_between(unique[0], today) > 1:
        return 0
    n = 1
    for i in range(1, len(unique)):
        if days_between(unique[i], unique[i - 1]) != 1:
            break
        n += 1
    return n

def week_count(days, today):
    return len([d for d in days if days_between(d, today) < 7])

def is_idle(days, today, idle_days):
    return not days or days_between(days[0], today) >= idle_days

def age_text(days, today):
    n = days_between(days[0], today)
    return "1 day ago" if n == 1 else "%d days ago" % n

def reading_state(days, today, idle_days, show_age):
    if not is_idle(days, today, idle_days):
        return "active"
    return "age" if show_age and days else "nudge"

def nudge_for(today):
    epoch_day = int(time.parse_time(today, format = "2006-01-02").unix // 86400)
    return NUDGES[epoch_day % len(NUDGES)]

API = "https://api.zotero.org"
MAX_PAGES = 5

def error_for_status(code):
    if code == 200:
        return None
    if code == 403:
        return "Check API key"
    if code == 404:
        return "Check user ID"
    return "Zotero offline"

def config_mode(user_id, key):
    if not user_id and not key:
        return "demo"
    if not user_id or not key:
        return "incomplete"
    return "ok"

def needs_more(days, today):
    """True if the streak reaches the oldest fetched day, so an older page could extend it."""
    s = streak(days, today)
    return s > 0 and days_between(days[-1], days[0]) + 1 == s

def resolve_paper(attachment, paper):
    if paper:
        return (paper["data"].get("title") or "Untitled", format_authors(paper["data"].get("creators", [])))
    if attachment:
        return (attachment["data"].get("title") or "Untitled", "")
    return ("Untitled", "")

def zotero_get(user_id, key, query):
    return http.get(
        "%s/users/%s/items?%s" % (API, user_id, query),
        headers = {"Zotero-API-Key": key, "Zotero-API-Version": "3"},
        ttl_seconds = 900,
    )

def first_item(user_id, key, item_key):
    """Item by key, or None if missing/deleted. itemKey= returns [] instead of a 404."""
    if not item_key:
        return None
    resp = zotero_get(user_id, key, "itemKey=" + item_key)
    items = resp.json() if resp.status_code == 200 else []
    return items[0] if items else None

def fetch_person(name, user_id, key, tz):
    person = {"name": name, "title": "", "authors": "", "days": [], "error": None}

    today = time.now().in_location(tz).format("2006-01-02")
    annotations = []

    # shortcut: at most MAX_PAGES*100 annotations, so streaks/week counts cap there; raise MAX_PAGES if that bites
    for page in range(MAX_PAGES):
        resp = zotero_get(user_id, key, "itemType=annotation&sort=dateAdded&direction=desc&limit=100&start=%d" % (page * 100))
        if resp.status_code != 200:
            if page == 0:
                person["error"] = error_for_status(resp.status_code)
                return person
            break
        batch = resp.json()
        annotations += batch
        person["days"] = [to_local_day(a["data"]["dateAdded"], tz) for a in annotations]
        if len(batch) < 100 or not needs_more(person["days"], today):
            break

    if not annotations:
        return person
    attachment = first_item(user_id, key, annotations[0]["data"].get("parentItem"))
    paper = first_item(user_id, key, attachment["data"].get("parentItem")) if attachment else None
    person["title"], person["authors"] = resolve_paper(attachment, paper)
    return person

def logo():
    return render.Column(children = [
        render.Row(children = [render.Box(width = 1, height = 1, color = RED if c == "1" else WHITE) for c in row.elems()])
        for row in Z
    ])

def header(text):
    return render.Row(cross_align = "center", children = [
        logo(),
        render.Padding(pad = (2, 0, 0, 0), child = render.Marquee(width = 52, child = render.Text(text, font = "tom-thumb", color = GREY))),
    ])

def hold(child, frames):
    """Show child for at least `frames` frames (and until its marquee finishes)."""
    return animation.Transformation(child = child, duration = frames, keyframes = [], wait_for_child = True)

def full(top, middle, bottom):
    return render.Padding(pad = 1, child = render.Column(expanded = True, main_align = "space_between", children = [top, middle, bottom]))

def screen_simple(p, age = ""):
    bottom = " - ".join([t for t in [p["authors"], age] if t])
    return full(
        header(p["name"] + " reads"),
        # Two lines of title; longer titles scroll upward.
        render.Marquee(width = 62, height = 16, scroll_direction = "vertical", child = render.WrappedText(p["title"], width = 62, font = "tb-8", color = WHITE)),
        render.Marquee(width = 62, child = render.Text(bottom, font = "tom-thumb", color = ORANGE)),
    )

def screen_stats(p, today):
    s = streak(p["days"], today)
    return full(
        header(p["name"]),
        render.Text("%d day streak" % s if s else "Start a streak!", font = "tom-thumb", color = ORANGE),
        render.Text("%d hl this wk" % week_count(p["days"], today), font = "tom-thumb", color = BLUE),
    )

def screen_nudge(p, today):
    return full(
        header(p["name"]),
        render.Marquee(width = 62, child = render.Text(nudge_for(today), font = "tb-8", color = WHITE)),
        render.Text("Open a paper :)", font = "tom-thumb", color = ORANGE),
    )

def screen_error(p):
    return full(header(p["name"]), render.Text(p["error"], font = "tom-thumb", color = ORANGE), render.Box(height = 1))

def half(p, today, idle_days, show_age):
    state = reading_state(p["days"], today, idle_days, show_age)
    if p["error"]:
        line, color = p["error"], ORANGE
    elif state == "nudge":
        line, color = nudge_for(today), ORANGE
    elif state == "age":
        line, color = p["title"] + " - " + age_text(p["days"], today), WHITE
    else:
        line, color = p["title"], WHITE
    return render.Box(width = 64, height = 16, child = render.Column(expanded = True, main_align = "space_around", children = [
        header(p["name"]),
        render.Marquee(width = 64, child = render.Text(line, font = "tom-thumb", color = color)),
    ]))

def screen_for(p, layout, today, idle_days, show_age):
    state = reading_state(p["days"], today, idle_days, show_age)
    if p["error"]:
        return screen_error(p)
    if state == "nudge":
        return screen_nudge(p, today)
    if state == "age":
        return screen_simple(p, age_text(p["days"], today))
    if layout == "stats":
        return render.Sequence(children = [hold(screen_simple(p), 100), hold(screen_stats(p, today), 100)])
    return screen_simple(p)

def load_person(config, n, tz):
    name = config.str("name%d" % n, "") or ("Me" if n == 1 else "Buddy")
    user_id, key = config.str("user%d" % n, ""), config.str("key%d" % n, "")
    mode = config_mode(user_id, key)
    if mode == "demo":
        return None
    if mode == "incomplete":
        return {"name": name, "title": "", "authors": "", "days": [], "error": "Finish setup"}
    return fetch_person(name, user_id, key, tz)

def expect(got, want, label):
    if got != want:
        fail("selftest %s: got %r, want %r" % (label, got, want))

def self_check():
    a = lambda last: {"creatorType": "author", "lastName": last}
    expect(format_authors([a("Vaswani")]), "Vaswani", "1 author")
    expect(format_authors([a("He"), a("Zhang")]), "He & Zhang", "2 authors")
    expect(format_authors([a("Vaswani"), a("B"), a("C")]), "Vaswani et al", "3 authors")
    expect(format_authors([{"creatorType": "editor", "name": "WHO"}]), "WHO", "non-author fallback")
    expect(format_authors([]), "", "no creators")

    expect(to_local_day("2026-11-08T03:30:00Z", "America/New_York"), "2026-11-07", "local day")

    days = ["2026-11-08", "2026-11-07", "2026-11-05"]
    expect(streak(days, "2026-11-08"), 2, "streak today")
    expect(streak(days, "2026-11-09"), 2, "streak alive next day")
    expect(streak(days, "2026-11-10"), 0, "streak broken")
    expect(streak([], "2026-11-08"), 0, "streak empty")
    expect(streak(["2026-11-08", "2026-11-08", "2026-11-07"], "2026-11-08"), 2, "streak dup days")

    expect(week_count(["2026-11-08", "2026-11-08", "2026-11-01"], "2026-11-08"), 2, "week count")
    expect(week_count(["2026-11-02"], "2026-11-08"), 1, "week edge")

    expect(is_idle([], "2026-11-08", 7), True, "idle empty")
    expect(is_idle(["2026-11-01"], "2026-11-08", 7), True, "idle 7 days")
    expect(is_idle(["2026-11-02"], "2026-11-08", 7), False, "not idle 6 days")

    expect(nudge_for("2026-11-08"), nudge_for("2026-11-08"), "nudge stable")
    expect(nudge_for("2026-11-08") in NUDGES, True, "nudge from list")
    expect(nudge_for("2026-11-08") != nudge_for("2026-11-09"), True, "nudge rotates")

    expect(error_for_status(200), None, "status 200")
    expect(error_for_status(403), "Check API key", "status 403")
    expect(error_for_status(429), "Zotero offline", "status 429")
    expect(error_for_status(404), "Check user ID", "status 404")

    expect(config_mode("", ""), "demo", "unconfigured")
    expect(config_mode("123", ""), "incomplete", "missing key")
    expect(config_mode("", "abc"), "incomplete", "missing id")
    expect(config_mode("123", "abc"), "ok", "configured")

    expect(needs_more(["2026-11-08", "2026-11-07"], "2026-11-08"), True, "page fully inside streak")
    expect(needs_more(["2026-11-08", "2026-11-05"], "2026-11-08"), False, "streak ends inside page")
    expect(needs_more(["2026-11-01"], "2026-11-08"), False, "no streak")

    expect(age_text(["2026-10-27"], "2026-11-08"), "12 days ago", "age plural")
    expect(age_text(["2026-11-07"], "2026-11-08"), "1 day ago", "age singular")

    expect(reading_state(["2026-11-08"], "2026-11-08", 7, False), "active", "state active")
    expect(reading_state(["2026-10-27"], "2026-11-08", 7, False), "nudge", "state nudge")
    expect(reading_state(["2026-10-27"], "2026-11-08", 7, True), "age", "state age")
    expect(reading_state([], "2026-11-08", 7, True), "nudge", "state age but never read")
    expect(error_for_status(500), "Zotero offline", "status 500")

    paper = {"data": {"title": "ResNet", "creators": [a("He"), a("Zhang")]}}
    expect(resolve_paper({"data": {"title": "x.pdf"}}, None), ("x.pdf", ""), "standalone pdf")
    expect(resolve_paper(None, None), ("Untitled", ""), "deleted attachment")
    expect(resolve_paper({"data": {"title": "x.pdf"}}, paper), ("ResNet", "He & Zhang"), "paper")

def main(config):
    if config.bool("selftest"):
        self_check()
        return render.Root(child = render.Text("OK"))
    tz = time.tz()
    today = time.now().in_location(tz).format("2006-01-02")
    idle = config.str("idle_days", "7")
    idle_days = int(idle) if idle.isdigit() and int(idle) > 0 else 7
    layout = config.str("layout", "simple")
    show_age = config.bool("show_age", False)

    p1 = load_person(config, 1, tz)
    p2 = load_person(config, 2, tz)
    if p1 == None:
        # No key configured: demo data so the app gallery preview shows something.
        variant = config.str("demo", "")
        p1 = demo_person("Ada", today, variant)
        p2 = demo_person("Alan", today, "")
        p2["title"], p2["authors"] = "On Computable Numbers", "Turing"

    if layout == "buddies" and p2 != None:
        child = render.Column(children = [half(p1, today, idle_days, show_age), half(p2, today, idle_days, show_age)])
    else:
        child = screen_for(p1, layout, today, idle_days, show_age)
    return render.Root(delay = 50, show_full_animation = True, child = child)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(id = "name1", name = "Name", desc = "Name shown on the display", icon = "user", default = "Me"),
            schema.Text(id = "user1", name = "Zotero user ID", desc = "Numeric ID from zotero.org/settings/keys", icon = "hashtag"),
            schema.Text(id = "key1", name = "Zotero API key", desc = "Read-only key from zotero.org/settings/keys", icon = "key", secret = True),
            schema.Dropdown(
                id = "layout",
                name = "Layout",
                desc = "What to show",
                icon = "tableCells",
                default = "simple",
                options = [
                    schema.Option(display = "Simple", value = "simple"),
                    schema.Option(display = "With stats", value = "stats"),
                    schema.Option(display = "Reading buddies", value = "buddies"),
                ],
            ),
            schema.Toggle(id = "show_age", name = "Show days since last read", desc = "When idle, keep showing the last paper with 'N days ago' instead of a motivational message", icon = "calendarDay", default = False),
            schema.Text(id = "idle_days", name = "Nudge after (days)", desc = "Show a motivational message after this many days without highlights", icon = "clock", default = "7"),
            schema.Text(id = "name2", name = "Buddy name", desc = "Reading buddies only", icon = "userGroup"),
            schema.Text(id = "user2", name = "Buddy Zotero user ID", desc = "Reading buddies only", icon = "hashtag"),
            schema.Text(id = "key2", name = "Buddy Zotero API key", desc = "Reading buddies only", icon = "key", secret = True),
        ],
    )
