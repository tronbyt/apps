"""
Applet: School Lunch
Author: zandif
Summary: School lunch from MealViewer
Description: Displays today's or tomorrow's school lunch menu from MealViewer.com.
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("re.star", "re")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

# 16x15 pixelated version of the fox mascot
FOX_ICON_BASE64 = (
    "iVBORw0KGgoAAAANSUhEUgAAABAAAAAPCAYAAADtc08vAAAAAXNSR0IB2cksfwAAAARnQU1BAACx" +
    "jwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOpgAABdwnLpRPAAAAAZiS0dE" +
    "AP8A/wD/oL2nkwAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+oIGQEjIOJv/A4AAALTSURB" +
    "VCjPdVNfSFNxGD2/u7t752bT/Btzrk0TFJeZmlphIaFEibYUSqyHyFfrQaSEQI2CAiVNjQLBAkvC" +
    "MFIRQ0jzb3+gqUNrZTZbuphM79TN5nZ3e0nQpufp+x7O4Xyc84nwHzo6OyXZrHX41KGEIkaj7bia" +
    "4N/kp4p3TU3PfMM2oDYvHMeR1ifNERrhXapsofdYhr+rN1ehLzqaklyMHUBvDCUlJXGDg4MDx8Ml" +
    "HrFrN2KP5FOHzfXJAgiG+nr7dhIgOp2ugWGYhRQ5EjM0IWdUC42wpT5EVO5FTJWlQsEa8Xg+czI8" +
    "61xacXGxw8cBx3HmxsbGOwxNw7myjEXqMhwWM7rrbiNOGoQl/wJEy0Lju/r7KwGU+TgoLS0VJyUl" +
    "vczMzDxN0zSMX41IT0sHIQQ8z8Pr9WJycpKvq6urZyXsg8QDiYXBwcHRc3Nz+vb29md0TU2Nu6qq" +
    "Sre0tJTGsmyY0WgUKRQRLVEaDeN0OjE+Po7h4eHumJgYc2FhoV6j0cgoioLBYNA5HI59NABUVFS4" +
    "AQwBQHl5eY7g9QrG0bdoaahxuiJim+XwGJV71bW8e51yu90YGR351dnRmV1bW/uZbL4nLy9vT2Vl" +
    "5RetVhswcf0kTLaVHueJK2elA03TWlavsK7tgkW8HxNhqedv3ax6viVGAFAqlZfkcnkAx3FYdvGI" +
    "ZOayX7fd776g/qSQ0ICccUDFWzD+nQnc4Ig2C6jVarNnoLVAPHBPrmQmECxxkBDRvFrKEIj/VU5E" +
    "ESzSWtGrj1NPfZrY1tY2O+uSvJESE7g14KddQKiUwLIibIkucNmQsG2V71ZXhx6UcTluXoCJE6AK" +
    "IGBoQES2Zr/KRPzwEbhRlJevMryYiSQfgsQU4OYFeLyAdRUQb1Iwceyf91a+3OcXiMOWbhN7/Gm/" +
    "JCzYCYJkAsaWgTEb5dwbJB/8bbdnrXv4iR572LVHXT1DG7y/3EEcQSPNdo4AAAAASUVORK5CYII="
)

SUPPORTED_LOGO_EXTS = (".png", ".jpg", ".jpeg", ".gif", ".webp")

# Generic regex rules to shorten verbose school menu item names
CLEANUP_RULES = [
    # Standardize dietary labels
    (r"(?i)\(\s*vegetarian\s*\)|\bvegetarian\b", "(v)"),
    (r"(?i)\(\s*vegan\s*\)|\bvegan\b", "(V)"),
    # Remove common parenthetical qualifiers (pork-free, redundant protein notes)
    (r"(?i)\(\s*(?:pork\s*-?\s*free|turkey|beef|chicken)\s*\)", ""),
    # Remove school-nutrition filler adjectives
    (r"(?i)\b(?:schoolmade|housemade|homemade|all[\s-]+natural|whole[\s-]+muscle|whole[\s-]+grain|whole[\s-]+wheat|plant[\s-]+powered|breaded)\b", ""),
    # Collapse spaces before multi-word phrase rules
    (r"\s+", " "),
    # Remove redundant protein prefixes on classic dishes
    (r"(?i)\bbeef\s+((?:cheese|ham)burger)\b", "$1"),
    (r"(?i)\bturkey\s+(pepperoni)\b", "$1"),
    (r"(?i)\b(?:chicken|beef|turkey)\s+(meatballs?)\b", "$1"),
    # Shorten common bun/roll and accompaniment phrasing
    (r"(?i)\bon\s+(?:a\s+)?(?:bun|roll)\b", "Sandwich"),
    (r"(?i)\bwith\s+marinara\s+and\b", "&"),
    (r"(?i)\bwith\s+sauce\b", ""),
    (r"(?i)\bwith\s+granola\b", ""),
    (r"(?i)\bpenne\s+pasta\b", "Penne"),
    (r"(?i)\bnacho\s+cheese\s+topping\b", "Nachos"),
    # Simplify verbose yogurt parfaits and MealViewer's 50-char truncated cheese trays
    (r"(?i)^.*\byogurt\s+parfait\b.*$", "Yogurt Parfait"),
    (r"(?i)\band\s+[\w\s]+?\bcheese\s+tr(?:ay)?\b", ""),
    # Normalize "Flavor- Flavor" hyphenation (e.g., "Strawberry- Banana" -> "Strawberry/Banana")
    (r"([A-Za-z])-\s+([A-Za-z])", "$1/$2"),
    # Shorten conjunctions
    (r"(?i)\band\b", "&"),
]

def sanitize_school_id(raw_id):
    sid = (raw_id or "").strip()
    if not sid:
        return ""

    # Allow users to paste a full MealViewer school URL
    if "/" in sid:
        sid = sid.split("?")[0].rstrip("/")
        sid = sid.split("/")[-1]
    return sid.strip()

def clean_item_name(name):
    text = name or ""
    for pattern, replacement in CLEANUP_RULES:
        text = re.sub(pattern, replacement, text)
    return " ".join(text.split())

def is_supported_logo(filename, headers):
    content_type = ""
    if headers:
        content_type = (headers.get("Content-Type") or headers.get("content-type") or "").lower()
    if content_type:
        if content_type.startswith("image/"):
            return "svg" not in content_type
        if "octet-stream" not in content_type:
            return False
    lower_name = filename.lower()
    for ext in SUPPORTED_LOGO_EXTS:
        if lower_name.endswith(ext):
            return True
    return False

def fit_image(src, max_size):
    probe = render.Image(src = src)
    img_w, img_h = probe.size()
    if img_w <= 0 or img_h <= 0:
        return None
    if img_w >= img_h:
        return render.Image(src = src, width = max_size)
    return render.Image(src = src, height = max_size)

def main(config):
    width, _ = canvas.size()
    is_2x = canvas.is2x()
    scale = 2 if is_2x else 1
    status_font = "6x10" if is_2x else "CG-pixel-3x5-mono"
    item_font = "terminus-12" if is_2x else "tom-thumb"
    logo_size = 16 * scale
    marquee_delay = 30 * scale

    school_id = sanitize_school_id(config.get("school_id", ""))
    date_format = config.get("date_format", "us")
    show_logo = config.bool("show_logo", True)
    hide_no_school = config.bool("hide_no_school", False)

    if not school_id:
        return render_layout("School Lunch", [
            render.Padding(
                pad = (0, 4 * scale, 0, 0),
                child = render.Box(
                    width = width,
                    child = render.Text(content = "School ID needed", color = "#ff6666", font = status_font),
                ),
            ),
        ])

    # Localize current time
    timezone = config.get("$tz") or "UTC"
    now = time.now().in_location(timezone)
    today_str = now.format("01-02-2006")

    # Advance 10 hours so the menu switches to tomorrow at 2:00 PM local time
    future = now + time.parse_duration("10h")
    future_str = future.format("01-02-2006")

    # Format header date
    if today_str != future_str:
        date_title = future.format("Mon") + ", TMRW"
    elif date_format == "eu":
        date_title = now.format("Mon, 02/01")
    else:
        date_title = now.format("Mon, 01/02")

    # API Request to MealViewer
    url = "https://api.mealviewer.com/api/v4/school/{}/{}/{}".format(school_id, future_str, future_str)
    res = http.get(url, ttl_seconds = 3600)

    if res.status_code != 200:
        return render_layout("Lunch " + date_title, [
            render.Padding(
                pad = (0, 8 * scale, 0, 0),
                child = render.Box(
                    width = width,
                    child = render.Text(content = "Error loading menu", color = "#ff6666", font = status_font),
                ),
            ),
        ])

    data = res.json()
    if not data or not data.get("physicalLocation"):
        return render_layout("Lunch " + date_title, [
            render.Padding(
                pad = (0, 8 * scale, 0, 0),
                child = render.Box(
                    width = width,
                    child = render.Text(content = "Invalid School ID", color = "#ff6666", font = status_font),
                ),
            ),
        ])

    logo_widget = None
    if show_logo:
        if "fox" in school_id.lower():
            logo_widget = fit_image(base64.decode(FOX_ICON_BASE64), logo_size)
        else:
            phys_loc = data.get("physicalLocation") or {}
            settings = phys_loc.get("schoolSettings") or {}
            logo_filename = settings.get("schoolLogo") or settings.get("SchoolLogo")

            if logo_filename:
                logo_url = "https://custcdn.mealviewer.com/schoollogo/{}".format(logo_filename)
                img_res = http.get(logo_url, ttl_seconds = 86400)
                if img_res.status_code == 200 and is_supported_logo(logo_filename, img_res.headers):
                    logo_widget = fit_image(img_res.body(), logo_size)

    entrees = []

    # Parse JSON for the target date's lunch entrees
    for schedule in data.get("menuSchedules") or []:
        for menu_block in schedule.get("menuBlocks") or []:
            block_name = (menu_block.get("blockName") or "").lower()
            if "lunch" not in block_name:
                continue

            cafeteria_lines = (menu_block.get("cafeteriaLineList") or {}).get("data") or []
            for line in cafeteria_lines:
                food_items = (line.get("foodItemList") or {}).get("data") or []
                for item in food_items:
                    item_type = (item.get("item_Type") or "").lower()
                    if "entree" in item_type or "entrée" in item_type:
                        raw_name = item.get("item_Name") or ""
                        cleaned = clean_item_name(raw_name)
                        if cleaned and cleaned not in entrees:
                            entrees.append(cleaned)

    # Check for no meals
    if not entrees:
        if hide_no_school:
            return []
        no_meals_text = "No School Tmrw" if today_str != future_str else "No School Today"
        return render_layout("Lunch " + date_title, [
            render.Padding(
                pad = (0, 8 * scale, 0, 0),
                child = render.Box(
                    width = width,
                    child = render.Text(content = no_meals_text, color = "#ff6666", font = status_font),
                ),
            ),
        ], logo_widget)

    top_meals = entrees[:4]
    meal_widgets = []
    for meal in top_meals:
        meal_widgets.append(
            render.Marquee(
                width = width,
                delay = marquee_delay,
                child = render.Text(content = "- " + meal, color = "#ffffff", font = item_font),
            ),
        )

    return render_layout("Lunch " + date_title, meal_widgets, logo_widget)

def render_layout(header, content_widgets, logo_widget = None):
    width, height = canvas.size()
    is_2x = canvas.is2x()
    scale = 2 if is_2x else 1
    header_font = "6x10" if is_2x else "CG-pixel-3x5-mono"
    logo_size = 16 * scale
    root_delay = 25 if is_2x else 50

    stack_layers = []

    # Render school logo in the bottom-right corner behind the menu when provided
    if logo_widget:
        stack_layers.append(
            render.Padding(
                pad = (width - logo_size, height - logo_size, 0, 0),
                child = render.Box(
                    width = logo_size,
                    height = logo_size,
                    child = logo_widget,
                ),
            ),
        )

    stack_layers.append(
        render.Column(
            cross_align = "start",
            children = [
                render.Marquee(
                    width = width,
                    child = render.Text(
                        content = header,
                        color = "#ffcc00",
                        font = header_font,
                    ),
                ),
                render.Box(width = width, height = scale, color = "#555555"),
                render.Column(
                    cross_align = "start",
                    children = content_widgets,
                ),
            ],
        ),
    )

    return render.Root(
        delay = root_delay,
        child = render.Stack(
            children = stack_layers,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "school_id",
                name = "School ID",
                desc = "MealViewer school slug (from schools.mealviewer.com/school/<ID>)",
                icon = "school",
            ),
            schema.Toggle(
                id = "show_logo",
                name = "Show Logo",
                desc = "Display the school mascot/logo in the corner",
                icon = "image",
                default = True,
            ),
            schema.Toggle(
                id = "hide_no_school",
                name = "Hide When No School",
                desc = "Skip displaying the app when no lunch entrees are listed",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Dropdown(
                id = "date_format",
                name = "Date Format",
                desc = "Date formatting convention",
                icon = "calendarDay",
                default = "us",
                options = [
                    schema.Option(
                        display = "American (MM/DD)",
                        value = "us",
                    ),
                    schema.Option(
                        display = "European (DD/MM)",
                        value = "eu",
                    ),
                ],
            ),
        ],
    )
