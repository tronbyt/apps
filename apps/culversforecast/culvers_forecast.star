"""
Applet: Custard Forecast
Summary: Custard 3-Day Forecast
Description: See the next 3 days of Flavor of the Day with color-coded pixel-art cones. Supports Culver's, Kopp's, Gille's, Hefner's, Kraverz, and Oscar's with brand-specific header colors.
Author: Chris Kaschner
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Worker API base URL (v1 versioned)
WORKER_BASE = "https://custard-calendar.chris-kaschner.workers.dev"

# Default store when app is unconfigured
DEFAULT_STORE_SLUG = "mt-horeb"
DEFAULT_STORE_NAME = "Mt. Horeb"

# Demo flavor names used as last-resort fallback when API + cache are both unavailable.
# Dates are computed dynamically in demo_flavors() so they never appear stale.
DEMO_FLAVOR_NAMES = ["Chocolate Caramel Twist", "Mint Explosion", "Turtle Dove"]

# Brand theming — drives header color and title text.
# text_color provides contrast: dark brands get white text, light brands get black.
BRAND_CONFIG = {
    "culvers": {"color": "#003366", "text": "#FFFFFF", "label": "Culver's FOTD"},
    "kopps": {"color": "#000000", "text": "#FFFFFF", "label": "Kopp's FOTD"},
    "gilles": {"color": "#EBCC35", "text": "#000000", "label": "Gille's FOTD"},
    "hefners": {"color": "#93BE46", "text": "#000000", "label": "Hefner's FOTD"},
    "kraverz": {"color": "#CE742D", "text": "#FFFFFF", "label": "Kraverz FOTD"},
    "oscars": {"color": "#BC272C", "text": "#FFFFFF", "label": "Oscar's FOTD"},
    "generic": {"color": "#6B4226", "text": "#FFFFFF", "label": "Custard FOTD"},
}

def brand_from_slug(slug):
    """Detect brand from store slug, mirroring server BRAND_REGISTRY patterns."""
    if slug.startswith("kopps-") or slug == "kopps":
        return "kopps"
    elif slug == "gilles":
        return "gilles"
    elif slug == "hefners":
        return "hefners"
    elif slug == "kraverz":
        return "kraverz"
    elif slug.startswith("oscars"):
        return "oscars"
    return "culvers"

def demo_flavors():
    """Generate demo flavors with today's date and the next 2 days."""
    now = time.now()
    result = []
    for i in range(len(DEMO_FLAVOR_NAMES)):
        d = now + time.parse_duration("{}h".format(i * 24))
        result.append({
            "name": DEMO_FLAVOR_NAMES[i],
            "date": d.format("2006-01-02"),
        })
    return result

# --- Color palettes ---

BASE_COLORS = {
    "vanilla": "#F5DEB3",
    "chocolate": "#6F4E37",
    "dark_chocolate": "#3B1F0B",
    "mint": "#2ECC71",
    "strawberry": "#FF6B9D",
    "cheesecake": "#FFF5E1",
    "caramel": "#C68E17",
    "butter_pecan": "#D4A574",
    "peach": "#FFE5B4",
}

RIBBON_COLORS = {
    "caramel": "#DAA520",
    "peanut_butter": "#D4A017",
    "marshmallow": "#FFFFFF",
    "chocolate_syrup": "#1A0A00",
    "fudge": "#3B1F0B",
}

TOPPING_COLORS = {
    "oreo": "#1A1A1A",
    "andes": "#00897B",
    "dove": "#3B1F0B",
    "pecan": "#8B6914",
    "cashew": "#D4C4A8",
    "heath": "#DAA520",
    "butterfinger": "#E6A817",
    "cookie_dough": "#C4A882",
    "strawberry_bits": "#FF1744",
    "raspberry": "#E91E63",
    "peach_bits": "#FF9800",
    "salt": "#FFFFFF",
    "snickers": "#C4A060",
    "cake": "#4A2800",
    "cheesecake_bits": "#FFF8DC",
    "m_and_m": "#FF4444",
    "reeses": "#D4A017",
}

# Flavor profiles: lowercase name -> {base, ribbon, toppings, density}
FLAVOR_PROFILES = {
    "dark chocolate pb crunch": {
        "base": "dark_chocolate",
        "ribbon": "peanut_butter",
        "toppings": ["butterfinger"],
        "density": "standard",
    },
    "chocolate caramel twist": {
        "base": "chocolate",
        "ribbon": "caramel",
        "toppings": ["dove"],
        "density": "standard",
    },
    "mint explosion": {
        "base": "mint",
        "ribbon": None,
        "toppings": ["oreo", "andes", "dove"],
        "density": "explosion",
    },
    "turtle dove": {
        "base": "vanilla",
        "ribbon": "marshmallow",
        "toppings": ["pecan", "dove"],
        "density": "standard",
    },
    "double strawberry": {
        "base": "strawberry",
        "ribbon": None,
        "toppings": ["strawberry_bits"],
        "density": "double",
    },
    "turtle cheesecake": {
        "base": "cheesecake",
        "ribbon": "caramel",
        "toppings": ["dove", "pecan", "cheesecake_bits"],
        "density": "explosion",
    },
    "caramel turtle": {
        "base": "caramel",
        "ribbon": None,
        "toppings": ["pecan", "dove"],
        "density": "standard",
    },
    "andes mint avalanche": {
        "base": "mint",
        "ribbon": None,
        "toppings": ["andes", "dove"],
        "density": "standard",
    },
    "oreo cookie cheesecake": {
        "base": "cheesecake",
        "ribbon": None,
        "toppings": ["oreo", "cheesecake_bits"],
        "density": "standard",
    },
    "devil's food cake": {
        "base": "dark_chocolate",
        "ribbon": None,
        "toppings": ["cake", "dove"],
        "density": "standard",
    },
    "caramel cashew": {
        "base": "vanilla",
        "ribbon": "caramel",
        "toppings": ["cashew"],
        "density": "standard",
    },
    "butter pecan": {
        "base": "butter_pecan",
        "ribbon": None,
        "toppings": ["pecan"],
        "density": "standard",
    },
    "caramel chocolate pecan": {
        "base": "chocolate",
        "ribbon": "caramel",
        "toppings": ["pecan", "dove"],
        "density": "standard",
    },
    "dark chocolate decadence": {
        "base": "dark_chocolate",
        "ribbon": None,
        "toppings": [],
        "density": "pure",
    },
    "caramel fudge cookie dough": {
        "base": "vanilla",
        "ribbon": "fudge",
        "toppings": ["cookie_dough"],
        "density": "standard",
    },
    "mint cookie": {
        "base": "mint",
        "ribbon": None,
        "toppings": ["oreo"],
        "density": "standard",
    },
    "caramel pecan": {
        "base": "vanilla",
        "ribbon": "caramel",
        "toppings": ["pecan"],
        "density": "standard",
    },
    "really reese's": {
        "base": "chocolate",
        "ribbon": "peanut_butter",
        "toppings": ["reeses"],
        "density": "standard",
    },
    "raspberry cheesecake": {
        "base": "cheesecake",
        "ribbon": None,
        "toppings": ["raspberry", "cheesecake_bits"],
        "density": "standard",
    },
    "chocolate covered strawberry": {
        "base": "vanilla",
        "ribbon": None,
        "toppings": ["strawberry_bits", "dove"],
        "density": "standard",
    },
    "caramel peanut buttercup": {
        "base": "vanilla",
        "ribbon": "peanut_butter",
        "toppings": ["dove"],
        "density": "standard",
    },
    "turtle": {
        "base": "vanilla",
        "ribbon": "caramel",
        "toppings": ["dove", "pecan"],
        "density": "standard",
    },
    "georgia peach": {
        "base": "peach",
        "ribbon": None,
        "toppings": ["peach_bits"],
        "density": "standard",
    },
    "snickers swirl": {
        "base": "chocolate",
        "ribbon": "caramel",
        "toppings": ["snickers"],
        "density": "standard",
    },
    "chocolate volcano": {
        "base": "chocolate",
        "ribbon": "chocolate_syrup",
        "toppings": ["oreo", "dove", "m_and_m"],
        "density": "explosion",
    },
    "oreo cookie overload": {
        "base": "chocolate",
        "ribbon": "chocolate_syrup",
        "toppings": ["oreo"],
        "density": "overload",
    },
    "salted double caramel pecan": {
        "base": "caramel",
        "ribbon": "caramel",
        "toppings": ["pecan", "salt"],
        "density": "double",
    },
    "crazy for cookie dough": {
        "base": "vanilla",
        "ribbon": "fudge",
        "toppings": ["cookie_dough"],
        "density": "standard",
    },
    "chocolate heath crunch": {
        "base": "chocolate",
        "ribbon": None,
        "toppings": ["heath"],
        "density": "standard",
    },
}

# --- Flavor profile lookup ---

def get_flavor_profile(flavor_name):
    """Look up flavor profile by name, with keyword fallback for unknown flavors."""
    key = flavor_name.lower()
    if key in FLAVOR_PROFILES:
        return FLAVOR_PROFILES[key]

    # Normalize unicode curly quotes to ASCII for matching
    normalized = key.replace("\u2019", "'").replace("\u2018", "'")
    if normalized in FLAVOR_PROFILES:
        return FLAVOR_PROFILES[normalized]

    # Keyword fallback for unknown flavors
    if "mint" in key:
        return {"base": "mint", "ribbon": None, "toppings": [], "density": "standard"}
    elif "dark choc" in key:
        return {"base": "dark_chocolate", "ribbon": None, "toppings": [], "density": "standard"}
    elif "chocolate" in key or "cocoa" in key:
        return {"base": "chocolate", "ribbon": None, "toppings": [], "density": "standard"}
    elif "strawberry" in key:
        return {"base": "strawberry", "ribbon": None, "toppings": [], "density": "standard"}
    elif "cheesecake" in key:
        return {"base": "cheesecake", "ribbon": None, "toppings": [], "density": "standard"}
    elif "caramel" in key:
        return {"base": "caramel", "ribbon": "caramel", "toppings": [], "density": "standard"}
    elif "peach" in key:
        return {"base": "peach", "ribbon": None, "toppings": [], "density": "standard"}
    elif "butter pecan" in key:
        return {"base": "butter_pecan", "ribbon": None, "toppings": ["pecan"], "density": "standard"}
    elif "vanilla" in key:
        return {"base": "vanilla", "ribbon": None, "toppings": [], "density": "standard"}
    return {"base": "vanilla", "ribbon": None, "toppings": [], "density": "standard"}

# --- Mini cone renderer ---

def create_mini_cone(profile):
    """Create a mini ice cream cone (9x11) per profile-driven rendering.

    Geometry: 6-row scoop (no outline), 4-row checkerboard cone, 1px tip.
    Rendering order: base fill -> toppings -> ribbon (ribbon wins at overlap) -> cone -> tip.
    """
    base = BASE_COLORS[profile["base"]]
    ribbon_key = profile.get("ribbon")
    topping_keys = profile.get("toppings", [])
    density = profile.get("density", "standard")

    # Ribbon present unless pure density or no ribbon defined
    has_ribbon = ribbon_key != None and density != "pure"

    # Determine topping slots based on density encoding
    topping_slots = []

    if density == "pure":
        pass  # No toppings, no ribbon
    elif density == "double":
        # Duplicate primary topping in T1 and T2
        if len(topping_keys) > 0:
            topping_slots = [topping_keys[0], topping_keys[0]]
            if len(topping_keys) > 1:
                topping_slots.append(topping_keys[1])
    elif density == "explosion":
        # Use 3-4 topping slots
        topping_slots = list(topping_keys[:4])
    elif density == "overload":
        # Duplicate dominant topping
        if len(topping_keys) > 0:
            topping_slots = [topping_keys[0], topping_keys[0]]
    else:
        # standard: fill slots in order
        topping_slots = list(topping_keys[:4])

    # Build overlay children (toppings first, then ribbon on top)
    overlays = []

    if len(topping_slots) > 0:
        overlays.append(
            render.Padding(
                pad = (2, 1, 0, 0),
                child = render.Box(width = 1, height = 1, color = TOPPING_COLORS[topping_slots[0]]),
            ),
        )
    if len(topping_slots) > 1:
        overlays.append(
            render.Padding(
                pad = (6, 1, 0, 0),
                child = render.Box(width = 1, height = 1, color = TOPPING_COLORS[topping_slots[1]]),
            ),
        )
    if len(topping_slots) > 2:
        overlays.append(
            render.Padding(
                pad = (3, 3, 0, 0),
                child = render.Box(width = 1, height = 1, color = TOPPING_COLORS[topping_slots[2]]),
            ),
        )
    if len(topping_slots) > 3 and not has_ribbon:
        overlays.append(
            render.Padding(
                pad = (5, 2, 0, 0),
                child = render.Box(width = 1, height = 1, color = TOPPING_COLORS[topping_slots[3]]),
            ),
        )

    if has_ribbon:
        ribbon = RIBBON_COLORS[ribbon_key]
        overlays.append(
            render.Padding(
                pad = (3, 0, 0, 0),
                child = render.Box(width = 1, height = 1, color = ribbon),
            ),
        )
        overlays.append(
            render.Padding(
                pad = (4, 1, 0, 0),
                child = render.Box(width = 1, height = 1, color = ribbon),
            ),
        )
        overlays.append(
            render.Padding(
                pad = (5, 2, 0, 0),
                child = render.Box(width = 1, height = 1, color = ribbon),
            ),
        )

    return render.Stack(
        children = [
            render.Box(width = 9, height = 11),
            render.Column(
                children = [
                    render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Box(width = 5, height = 1, color = base),
                    ),
                    render.Padding(
                        pad = (1, 0, 0, 0),
                        child = render.Box(width = 7, height = 5, color = base),
                    ),
                    render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Row(
                            children = [
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (2, 0, 0, 0),
                        child = render.Row(
                            children = [
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (3, 0, 0, 0),
                        child = render.Row(
                            children = [
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (3, 0, 0, 0),
                        child = render.Row(
                            children = [
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                                render.Box(width = 1, height = 1, color = "#D2691E"),
                                render.Box(width = 1, height = 1, color = "#B8860B"),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (4, 0, 0, 0),
                        child = render.Box(width = 1, height = 1, color = "#B8860B"),
                    ),
                ],
            ),
        ] + overlays,
    )

# --- Text formatting for small displays ---

def format_flavor_for_display(name, max_chars = 5):
    """Format flavor name using base noun anchoring principle.

    Returns [line1, line2] where:
    - line2 = base noun (anchor)
    - line1 = descriptors/modifiers
    Max 5 chars per line for optimal 3-cone display.
    """

    # Special case patterns for common flavors
    if "Dark Chocolate PB Crunch" in name or "Dk Choc PB Crunch" in name:
        return ["DK PB", "Crunc"]
    elif "OREO Cookie Cheesecake" in name or "Oreo" in name.lower():
        if "Cheesecake" in name:
            return ["Oreo", "Chees"]
        else:
            return ["Oreo", "Cook"]
    elif "Chocolate Covered Strawberry" in name:
        return ["Choc", "Straw"]
    elif "Devil's Food Cake" in name or "Devils Food Cake" in name:
        return ["Devil", "Cake"]
    elif "Snickers" in name:
        return ["Snkrs", "Swirl"]
    elif "Georgia Peach" in name:
        return ["GA", "Peach"]
    elif "Really Reese" in name or "Reese" in name:
        return ["Reese"]
    elif "Turtle Cheesecake" in name:
        return ["Turtl", "Chees"]
    elif "Turtle Dove" in name:
        return ["Turtl", "Dove"]
    elif "Caramel Turtle" in name:
        return ["Crml", "Turtl"]
    elif "Butter Pecan" in name:
        return ["Buttr", "Pecan"]
    elif "Caramel Cashew" in name:
        return ["Crml", "Cashw"]
    elif "Andes Mint Avalanche" in name:
        return ["Mint", "Avlnc"]
    elif "Chocolate Volcano" in name or "Choc Volcano" in name:
        return ["Choc", "Volc"]
    elif "Chocolate Decadence" in name or "Choc Decadence" in name:
        return ["Choc", "Decad"]
    elif "Chocolate Heath Crunch" in name or "Choc Heath Crunch" in name:
        return ["Heath", "Crunc"]
    elif "Caramel Fudge Cookie Dough" in name or "Crml Fudge Cook Dough" in name:
        return ["Fudge", "Dough"]
    elif "Salted Double Caramel Pecan" in name or "Salt Dbl Crml Pecan" in name:
        return ["Salt", "Pecan"]
    elif name == "Turtle":
        return ["Turtl"]

    # Base noun whitelist (5-char abbreviated forms)
    base_nouns = [
        "Avlnc",
        "Volc",
        "Chees",
        "Flury",
        "Cake",
        "Crumb",
        "Bliss",
        "Ovld",
        "Dough",
        "Pecan",
        "Cashw",
        "Fudge",
        "Crml",
        "Choc",
        "Expl",
        "Delit",
        "Dream",
        "Swirl",
        "Crunc",
        "Cook",
        "Brown",
        "Twist",
        "Turtl",
        "Mint",
        "Toff",
        "Decad",
        "Straw",
        "PBcup",
        "Dove",
    ]

    # Comprehensive abbreviation map (optimized for 5 chars)
    abbr_map = {
        "Chocolate": "Choc",
        "Caramel": "Crml",
        "Raspberry": "Rasp",
        "Strawberry": "Straw",
        "Cappuccino": "Capp",
        "Peanut Butter": "PB",
        "Explosion": "Expl",
        "Crumble": "Crumb",
        "Midnight": "Midn",
        "Brownie": "Brown",
        "Batter": "Batt",
        "Toffee": "Toff",
        "Salted": "Salt",
        "Cookie": "Cook",
        "Crazy for": "Crazy4",
        "Dark": "Dk",
        "Double": "Dbl",
        "Triple": "Trpl",
        "Covered": "Covr",
        "Cheesecake": "Chees",
        "Avalanche": "Avlnc",
        "Volcano": "Volc",
        "Decadence": "Decad",
        "Turtle": "Turtl",
        "Crunch": "Crunc",
        "Cashew": "Cashw",
        "Butter": "Buttr",
    }

    # Apply abbreviations to full name first
    abbreviated = name
    for full, short in abbr_map.items():
        abbreviated = abbreviated.replace(full, short)

    words = abbreviated.split()

    if len(words) == 0:
        return ["???"]

    # Detect base noun (last word matching whitelist)
    base_noun = ""
    desc_words = words

    # Check if last word is a known base noun
    if words[-1] in base_nouns:
        base_noun = words[-1]
        desc_words = words[:-1]

        # Check for 2-word base nouns (Cookie Dough, Layer Cake, etc.)
    elif len(words) >= 2:
        two_word = " ".join(words[-2:])
        if two_word in ["Cook Dough", "Layer Cake", "Batt Bliss"]:
            base_noun = two_word
            desc_words = words[:-2]
        else:
            # Default: last word is base noun
            base_noun = words[-1]
            desc_words = words[:-1]
    else:
        # Single word
        return [words[0][:max_chars]]

    # Build lines
    line1 = " ".join(desc_words) if desc_words else ""
    line2 = base_noun

    # Trim line1 if too long
    if len(line1) > max_chars:
        # Try dropping least important word (first descriptor)
        if len(desc_words) > 1:
            line1 = " ".join(desc_words[1:])
        if len(line1) > max_chars:
            line1 = line1[:max_chars]

    # Trim line2 if too long (last resort)
    if len(line2) > max_chars:
        line2 = line2[:max_chars]

    # Return appropriate format
    if line1 and line2:
        return [line1, line2]
    elif line2:
        return [line2]
    else:
        return [name[:max_chars]]

# --- Three-day view layout ---

def create_three_day_view(flavors, location_name, brand_color = "#003366", text_color = "#FFFFFF"):
    """Create 3-day forecast with mini cones and flavor names.

    Pixel budget (32px):
      y=0-4:  header (5px brand color, descent clipped)
      y=5:    gap (1px black)
      y=6-31: content (26px per column)
      y=30:   cone tips / text baselines
      y=31:   descenders only (or black)
    """
    columns = []

    # Target column height: fills y=6 to y=31
    col_height = 26
    cone_height = 11

    for i, flavor in enumerate(flavors[:3]):
        flavor_name = flavor.get("name", "Unknown")
        profile = get_flavor_profile(flavor_name)
        name_lines = format_flavor_for_display(flavor_name)

        text_children = []
        for line in name_lines:
            text_children.append(
                render.Text(
                    content = line.upper(),
                    font = "tom-thumb",
                    color = "#FFFFFF",
                ),
            )

        cone = create_mini_cone(profile)
        text_height = len(name_lines) * 6  # tom-thumb = 6px per line

        # Staggered layout with dynamic spacer to fill 26px exactly
        if i == 1:
            # Middle: cone top, text bottom (descenders reach y=31)
            spacer = col_height - cone_height - text_height
            column = render.Column(
                main_align = "start",
                cross_align = "center",
                children = [cone, render.Box(width = 1, height = spacer)] + text_children,
            )
        else:
            # Outer: text top, cone bottom (tip at y=30, 1px pad at y=31)
            spacer = col_height - text_height - cone_height - 1
            column = render.Padding(
                pad = (0, 0, 0, 1),
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = text_children + [render.Box(width = 1, height = spacer), cone],
                ),
            )

        columns.append(column)

    # Pad with empty columns if less than 3 flavors
    if len(columns) < 3:
        for _ in range(3 - len(columns)):
            columns.append(render.Box(width = 1))

    return render.Box(
        width = 64,
        height = 32,
        child = render.Column(
            main_align = "space_between",
            cross_align = "center",
            expanded = True,
            children = [
                # Header: 6px tall (full font height), brand color behind y=0-4
                # y=5 is descent row with no color = appears black
                render.Box(
                    width = 64,
                    height = 6,
                    child = render.Stack(
                        children = [
                            render.Box(width = 64, height = 5, color = brand_color),
                            render.Box(
                                width = 64,
                                height = 6,
                                child = render.Marquee(
                                    width = 64,
                                    child = render.Text(
                                        content = location_name,
                                        font = "tom-thumb",
                                        color = text_color,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
                # Content: pinned to bottom via space_between
                render.Row(
                    main_align = "space_evenly",
                    children = columns,
                ),
            ],
        ),
    )

# --- Data fetching with two-tier cache ---

def fetch_flavors(slug):
    """Fetch flavor data from Worker API with two-tier cache resilience.

    Tier 1: Primary cache key with 12h TTL (normal refresh cycle).
    Tier 2: Stale cache key with 1h TTL, re-persisted on every read.
             Since Tidbyt renders every ~15 min, the stale key stays
             alive indefinitely through continuous re-persist.
    Tier 3: demo_flavors() as absolute last resort.

    Network resilience: http.get() uses ttl_seconds = 3600 (max allowed)
    so pixlet's built-in HTTP cache can serve stale responses when the
    network is unreachable, preventing script crashes after the first
    successful fetch.
    """
    cache_key = "flavors:{}".format(slug)
    stale_key = "flavors_stale:{}".format(slug)

    # Tier 1: Check primary cache
    cached = cache.get(cache_key)
    if cached != None:
        data = json.decode(cached)

        # Re-persist stale copy (keeps it alive as long as app renders)
        cache.set(stale_key, cached, ttl_seconds = 3600)
        return data

    # Tier 2: Check stale cache BEFORE making a network call.
    stale = cache.get(stale_key)
    if stale != None:
        data = json.decode(stale)

        # Re-persist stale to keep it alive
        cache.set(stale_key, stale, ttl_seconds = 3600)

        # Still attempt a background-style refresh via http.get with max
        # ttl_seconds. If the HTTP cache has a response, this is instant
        # and free. If not, it fetches and populates the HTTP cache for
        # next render cycle.
        url = "{}/api/v1/flavors?slug={}".format(WORKER_BASE, humanize.url_encode(slug))
        rep = http.get(url, ttl_seconds = 3600)
        if rep.status_code == 200:
            mapped = _map_flavor_response(rep.json())
            encoded = json.encode(mapped)
            cache.set(cache_key, encoded, ttl_seconds = 43200)
            cache.set(stale_key, encoded, ttl_seconds = 3600)
        return data

    # Both caches empty: fetch from Worker API.
    url = "{}/api/v1/flavors?slug={}".format(WORKER_BASE, humanize.url_encode(slug))
    rep = http.get(url, ttl_seconds = 3600)

    if rep.status_code == 200:
        mapped = _map_flavor_response(rep.json())

        # Persist to both cache tiers
        encoded = json.encode(mapped)
        cache.set(cache_key, encoded, ttl_seconds = 43200)  # 12 hours
        cache.set(stale_key, encoded, ttl_seconds = 3600)  # 1 hour

        return mapped

    # Tier 3: HTTP error (non-200), return demo flavors
    return demo_flavors()

def _map_flavor_response(data):
    """Map Worker API field names to renderer field names."""
    flavors = data.get("flavors", [])
    mapped = []
    for f in flavors:
        mapped.append({
            "name": f.get("title", "Unknown"),
            "date": f.get("date", ""),
        })
    return mapped

# --- Typeahead store search ---

def search_stores(pattern):
    """Handler for schema.Typeahead — searches Worker API for matching stores across all brands."""
    if len(pattern) < 2:
        return []

    url = "{}/api/v1/stores?q={}".format(WORKER_BASE, humanize.url_encode(pattern))
    rep = http.get(url, ttl_seconds = 3600)  # max allowed; store list is static

    if rep.status_code != 200:
        return []

    data = rep.json()
    stores = data.get("stores", [])

    results = []
    for store in stores:
        results.append(
            schema.Option(
                display = store.get("name", "Unknown"),
                value = store.get("slug", ""),
            ),
        )

    return results

# --- App entry point ---

def main(config):
    """Main entry point — fetches flavors and renders 3-day view."""

    # Read store selection from schema config
    store_json = config.get("store")
    if store_json:
        store = json.decode(store_json)
        slug = store.get("value", DEFAULT_STORE_SLUG)
        display_name = store.get("display", DEFAULT_STORE_NAME)
    else:
        # Unconfigured: use default store
        slug = DEFAULT_STORE_SLUG
        display_name = DEFAULT_STORE_NAME

    # Detect brand from slug and get theme
    brand_key = brand_from_slug(slug)
    brand_cfg = BRAND_CONFIG.get(brand_key, BRAND_CONFIG["culvers"])

    # Fetch flavor data
    flavors = fetch_flavors(slug)

    # Filter to today and future dates
    now = time.now()
    today = now.format("2006-01-02")

    upcoming = []
    for f in flavors:
        if f.get("date", "") >= today:
            upcoming.append(f)

    # Use upcoming flavors if available, otherwise show whatever we have
    header_name = display_name
    if len(upcoming) > 0:
        display_flavors = upcoming
    elif len(flavors) > 0:
        # All dates are in the past (stale cache) — show last 3 as-is
        display_flavors = flavors
        header_name = "stale data - {}".format(display_name)
    else:
        display_flavors = demo_flavors()

    # Render three-day view with brand-specific header
    return render.Root(
        delay = 75,  # ms between frames (enables marquee animation)
        child = create_three_day_view(display_flavors, header_name, brand_cfg["color"], brand_cfg["text"]),
    )

def get_schema():
    """Configuration schema — store selection via typeahead search."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "store",
                name = "Store",
                desc = "Search for your nearest custard store (Culver's, Kopp's, Gille's, and more)",
                icon = "magnifyingGlass",
                handler = search_stores,
            ),
        ],
    )
