"""
Applet: Birdnet Go
Summary: Backyard bird sound detections
Description: Displays the latest real-time bird acoustic detection, photo, and confidence score from your local BirdNET-Go station.
Author: brombomb
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/sample_bird.png", SAMPLE_BIRD_ASSET = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")

CYAN = "#38bdf8"
GREEN = "#00ff66"
WHITE = "#ffffff"
MUTED = "#94a3b8"
BG_COLOR = "#000000"

BIRD_BUDDY_GRAPHQL_URL = "https://graphql.app-api.prod.aws.mybirdbuddy.com/graphql"

SAMPLE_DETECTION = {
    "commonName": "Blue Jay",
    "scientificName": "Cyanocitta cristata",
    "confidence": 0.99,
    "time": "09:27",
}

def fetch_recent_detections(station_url):
    if not station_url or station_url.strip() == "":
        return [SAMPLE_DETECTION]

    clean_url = station_url.strip()
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    endpoint = clean_url + "/api/v2/detections/recent"
    cache_key = "birdnet_recent_" + endpoint
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    headers = {"User-Agent": "Tronbyt-BirdNET-Go"}
    res = http.get(endpoint, headers = headers, ttl_seconds = 15)
    if res.status_code != 200:
        print("Failed to fetch BirdNET-Go detections:", res.status_code, endpoint)
        return None

    data = res.json()
    if type(data) != "list":
        return None

    cache.set(cache_key, json.encode(data), ttl_seconds = 15)
    return data

def fetch_bird_image(station_url, scientific_name):
    if not station_url or not scientific_name or scientific_name.strip() == "":
        return None

    clean_url = station_url.strip()
    if clean_url.endswith("/"):
        clean_url = clean_url[:-1]

    safe_name = scientific_name.strip().replace(" ", "%20")
    image_url = clean_url + "/api/v2/media/image/" + safe_name

    headers = {"User-Agent": "Tronbyt-BirdNET-Go"}
    res = http.get(image_url, headers = headers, ttl_seconds = 86400)
    if res.status_code == 200:
        return res.body()

    return None

def get_bird_buddy_token(username, password):
    cache_key = "bb_token_" + username
    cached = cache.get(cache_key)
    if cached:
        return cached

    auth_mutation = {
        "query": """
            mutation emailSignIn($emailSignInInput: EmailSignInInput!) {
                authEmailSignIn(emailSignInInput: $emailSignInInput) {
                    ... on Auth {
                        accessToken
                        __typename
                    }
                    __typename
                }
            }
        """,
        "variables": {
            "emailSignInInput": {
                "email": username,
                "password": password,
            },
        },
    }
    res = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = auth_mutation,
        headers = {"Content-Type": "application/json"},
        ttl_seconds = 60,
    )
    if res.status_code != 200:
        return None

    data = res.json()
    auth_data = ((data.get("data") or {}).get("authEmailSignIn") or {})
    token = auth_data.get("accessToken")
    if token:
        cache.set(cache_key, token, ttl_seconds = 840)
        return token
    return None

def fetch_bird_buddy_species_map(token, username):
    cache_key = "bb_species_map_" + username
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    query = {
        "query": """
            query meCollections {
                me {
                    collections {
                        ... on CollectionBird {
                            species {
                                ... on SpeciesBird {
                                    name
                                    iconUrl
                                }
                            }
                            __typename
                        }
                    }
                }
            }
        """,
    }
    res = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = query,
        headers = {"Authorization": "Bearer " + token, "Content-Type": "application/json"},
        ttl_seconds = 300,
    )
    if res.status_code != 200:
        return {}

    data = res.json()
    collections = (((data.get("data") or {}).get("me") or {}).get("collections") or [])
    species_map = {}
    for c in collections:
        if c.get("__typename") == "CollectionBird":
            sp = c.get("species") or {}
            name = sp.get("name")
            icon_url = sp.get("iconUrl")
            if name and icon_url:
                species_map[name.lower().strip()] = icon_url

    if species_map:
        cache.set(cache_key, json.encode(species_map), ttl_seconds = 86400)
    return species_map

def fetch_bird_buddy_image(username, password, bird_name):
    if not username or not password or not bird_name:
        return None

    token = get_bird_buddy_token(username, password)
    if not token:
        return None

    species_map = fetch_bird_buddy_species_map(token, username)
    icon_url = species_map.get(bird_name.lower().strip())
    if not icon_url:
        return None

    res = http.get(icon_url, ttl_seconds = 86400)
    if res.status_code == 200:
        return res.body()
    return None

def render_bird_view(scale, width, detection, photo_bytes, show_scientific, font_title, font_tiny):
    photo_width = 24 * scale
    photo_height = 30 * scale

    photo_widget = render.Image(
        src = photo_bytes,
        width = photo_width,
        height = photo_height,
    )

    text_width = width - photo_width - (4 * scale)
    conf_pct = int(detection.get("confidence", 0.0) * 100)

    conf_badge = render.Box(
        color = "#002b11",
        child = render.Padding(
            pad = (2 * scale, 1 * scale, 2 * scale, 1 * scale),
            child = render.Text("%d%% CONF" % conf_pct, font = font_tiny, color = GREEN),
        ),
    )

    time_raw = detection.get("time", "")
    time_display = time_raw[:5] if len(time_raw) >= 5 else time_raw

    details = []
    details.append(
        render.Marquee(
            width = text_width,
            child = render.Text(detection.get("commonName", "Bird"), font = font_title, color = WHITE),
        ),
    )

    if show_scientific:
        details.append(
            render.Marquee(
                width = text_width,
                child = render.Text(detection.get("scientificName", ""), font = font_tiny, color = MUTED),
            ),
        )

    details.append(
        render.Row(
            expanded = True,
            cross_align = "center",
            main_align = "space_between",
            children = [
                conf_badge,
                render.Text(time_display, font = font_tiny, color = MUTED),
            ],
        ),
    )

    text_column = render.Column(
        expanded = True,
        main_align = "space_between",
        cross_align = "start",
        children = details,
    )

    return render.Row(
        expanded = True,
        cross_align = "center",
        children = [
            render.Padding(
                pad = (1 * scale, 1 * scale, 2 * scale, 1 * scale),
                child = photo_widget,
            ),
            render.Padding(
                pad = (0, 1 * scale, 1 * scale, 1 * scale),
                child = text_column,
            ),
        ],
    )

def main(config):
    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1

    font_title = "tb-8" if scale == 1 else "terminus-14"
    font_tiny = "tom-thumb" if scale == 1 else "tb-8"

    station_url = config.str("station_url", "")
    min_conf = int(config.str("min_confidence", "70"))
    show_scientific = config.bool("show_scientific", True)
    image_source = config.str("image_source", "birdnet")
    bb_username = config.str("bb_username", "")
    bb_password = config.str("bb_password", "")

    detections = fetch_recent_detections(station_url)

    if not detections:
        return render.Root(
            child = render.Box(
                width = width,
                height = height,
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("BirdNET Offline", font = font_title, color = CYAN),
                        render.Text("Check Station URL", font = font_tiny, color = MUTED),
                    ],
                ),
            ),
        )

    # Find newest detection meeting minimum confidence
    target_detection = None
    min_threshold = float(min_conf) / 100.0

    for d in detections:
        if d.get("confidence", 0.0) >= min_threshold:
            target_detection = d
            break

    if not target_detection:
        target_detection = detections[0]

    photo_bytes = None
    common_name = target_detection.get("commonName", "")
    scientific_name = target_detection.get("scientificName", "")

    # Try Bird Buddy if chosen
    if image_source in ["birdbuddy", "auto"]:
        photo_bytes = fetch_bird_buddy_image(bb_username, bb_password, common_name)

    # Fallback to BirdNET-Go local photo if needed
    if not photo_bytes and station_url and station_url.strip() != "":
        photo_bytes = fetch_bird_image(station_url, scientific_name)

    if not photo_bytes:
        photo_bytes = SAMPLE_BIRD_ASSET.readall()

    root_child = render_bird_view(
        scale,
        width,
        target_detection,
        photo_bytes,
        show_scientific,
        font_title,
        font_tiny,
    )

    delay = 40 // scale
    return render.Root(
        delay = delay,
        child = render.Box(
            width = width,
            height = height,
            color = BG_COLOR,
            child = root_child,
        ),
    )

def get_schema():
    conf_options = [
        schema.Option(display = "50% Confidence", value = "50"),
        schema.Option(display = "60% Confidence", value = "60"),
        schema.Option(display = "70% Confidence", value = "70"),
        schema.Option(display = "80% Confidence", value = "80"),
        schema.Option(display = "90% Confidence", value = "90"),
    ]

    source_options = [
        schema.Option(display = "BirdNET-Go (Local Photo)", value = "birdnet"),
        schema.Option(display = "Bird Buddy (Avatar)", value = "birdbuddy"),
        schema.Option(display = "Auto (Bird Buddy first, then Local)", value = "auto"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station_url",
                name = "Station URL",
                desc = "Host URL of your BirdNET-Go station",
                icon = "server",
                default = "http://localhost:8080",
            ),
            schema.Dropdown(
                id = "image_source",
                name = "Image Source",
                desc = "Choose where bird images are fetched from",
                icon = "image",
                default = "birdnet",
                options = source_options,
            ),
            schema.Text(
                id = "bb_username",
                name = "Bird Buddy Email (Optional)",
                desc = "Account email for Bird Buddy avatar images",
                icon = "user",
            ),
            schema.Text(
                id = "bb_password",
                name = "Bird Buddy Password (Optional)",
                desc = "Account password for Bird Buddy avatar images",
                icon = "lock",
                secret = True,
            ),
            schema.Dropdown(
                id = "min_confidence",
                name = "Minimum Confidence",
                desc = "Only display detections at or above this confidence",
                icon = "sliders",
                default = "70",
                options = conf_options,
            ),
            schema.Toggle(
                id = "show_scientific",
                name = "Show Scientific Name",
                desc = "Display the Latin scientific name under common name",
                icon = "feather",
                default = True,
            ),
        ],
    )
