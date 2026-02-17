"""
Applet: Vinyl Roulette
Summary: Random vinyl from Discogs
Description: Display a random vinyl from your Discogs collection on your Tidbyt device!
Author: kaffolder7
Shows: Album art, Artist, Title, Track count, Total duration
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/roulette_logo.png", ROULETTE_LOGO_1X = "file")
load("images/roulette_logo@2x.png", ROULETTE_LOGO_2X = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# Discogs API base URL
DISCOGS_API_BASE = "https://api.discogs.com"

# Cache keys and TTLs
COLLECTION_CACHE_KEY = "discogs_collection_%s"
RELEASE_CACHE_KEY = "discogs_release_%s"
COLLECTION_CACHE_TTL = 21600  # 6 hours (matches your refresh interval)
RELEASE_CACHE_TTL = 86400  # 24 hours (release data rarely changes)
FOLDERS_CACHE_KEY = "discogs_folders_%s"
FOLDERS_CACHE_TTL = 86400  # 24 hours (folder names rarely change)

ROULETTE_LOGO = ROULETTE_LOGO_2X if canvas.is2x() else ROULETTE_LOGO_1X

def main(config):
    """Main entry point for the Tidbyt app."""

    # Get configuration values
    username = config.str("username", "").strip()
    token = config.str("token", "").strip()
    filter_by_folder = config.str("filter_by_folder", "0")
    excluded_folders = config.str("excluded_folders", "")
    excluded_artists = config.str("excluded_artists", "")

    # Validate required config
    if not username:
        return render_error("Set Discogs username")

    if not token:
        return render_error("Set Discogs personal access token")

    # Fetch a random release from the collection (filtered by folder if specified)
    # and skip any explicitly excluded folder IDs.
    release_data = get_random_release(username, token, filter_by_folder, excluded_folders, excluded_artists)

    if release_data == None:
        return render_error("Could not fetch collection")

    if "error" in release_data:
        return render_error(release_data["error"])

    # Render the display
    return render_vinyl(config, release_data)

def get_random_release(username, token, filter_by_folder = "0", excluded_folders = "", excluded_artists = ""):
    """
    Fetches a random *vinyl* release from the user's Discogs collection.
    Uses caching to minimize API calls.

    Args:
        username: Discogs username
        token: Discogs API token
        filter_by_folder: Comma-separated folder IDs to include (0 = all folders)
        excluded_folders: Comma-separated folder IDs to exclude from random selection
        excluded_artists: Comma-separated artist IDs to exclude from random selection
    """

    # Build headers for Discogs API
    headers = {
        "User-Agent": "TidbytRandomVinyl/1.0",
        "Authorization": "Discogs token=" + token,
    }

    # Folder name lookup (folder_id -> name)
    folder_map = get_folder_map(username, headers)

    filter_folder_ids = parse_filter_folder_ids(filter_by_folder)
    excluded_folder_ids = parse_excluded_folders(excluded_folders)
    excluded_artist_ids = parse_excluded_artists(excluded_artists)

    using_all_folders = "0" in filter_folder_ids
    selected_folder_ids = []

    if using_all_folders:
        selected_folder_ids = ["0"]
    else:
        for folder_id in filter_folder_ids:
            if folder_id in excluded_folder_ids:
                folder_name = folder_map.get(folder_id, "folder %s" % folder_id)
                return {"error": "Filtered folder is excluded: %s" % folder_name}
            selected_folder_ids.append(folder_id)

    folder_totals = {}
    available_folder_ids = []
    total_available_items = 0

    for folder_id in selected_folder_ids:
        collection_info = get_collection_info(username, headers, folder_id)
        if "error" in collection_info:
            return collection_info

        total_items = int(collection_info.get("total_items", 0))
        folder_totals[folder_id] = total_items

        if total_items > 0:
            available_folder_ids.append(folder_id)
            total_available_items += total_items

    if total_available_items == 0:
        if using_all_folders:
            return {"error": "Collection is empty"}
        return {"error": "No releases in selected folders"}

    # Rejection sampling: keep picking random items until we hit a Vinyl entry.
    # (Discogs collection paging doesn't provide a server-side "format=Vinyl" filter.)
    MAX_RANDOM_ATTEMPTS = 25

    for _ in range(MAX_RANDOM_ATTEMPTS):
        folder_id = choose_random_folder(available_folder_ids, folder_totals, total_available_items)
        total_items = int(folder_totals.get(folder_id, 0))
        if total_items <= 0:
            continue

        random_index = random.number(0, total_items - 1)
        page = (random_index // 50) + 1
        item_on_page = random_index % 50

        # Fetch the page containing our random item from the selected folder.
        page_url = "%s/users/%s/collection/folders/%s/releases?page=%d&per_page=50" % (
            DISCOGS_API_BASE,
            username,
            folder_id,
            page,
        )

        resp = http.get(page_url, headers = headers)
        if resp.status_code != 200:
            return {"error": "Failed to fetch page"}

        page_data = resp.json()
        releases = page_data.get("releases", [])
        if len(releases) == 0:
            return {"error": "No releases on page"}

        # Handle edge case where item_on_page might be out of bounds
        if item_on_page >= len(releases):
            item_on_page = len(releases) - 1

        collection_item = releases[item_on_page]
        item_folder_id = int(collection_item.get("folder_id", 0))

        # Exclusion filter always applies, including when "All Folders" (folder_id=0)
        if str(item_folder_id) in excluded_folder_ids:
            continue

        basic_info = collection_item.get("basic_information", {})
        artists = basic_info.get("artists", [])

        # Exclude releases where any credited artist ID is in the excluded list.
        if has_excluded_artist(artists, excluded_artist_ids):
            continue

        formats = basic_info.get("formats", [])
        if not is_vinyl(formats):
            continue

        display_title = basic_info.get("title", "Unknown")
        if has_format_description(formats, "7\"") and not display_title.endswith(" - 7\""):
            display_title = display_title + " - 7\""

        release_id = int(basic_info.get("id", 0))
        if release_id == 0:
            continue

        # Get detailed release info (for duration/track count)
        release_details = get_release_details(release_id, headers)

        folder_name = folder_map.get(str(item_folder_id), "")

        # Combine basic info with details
        return {
            "title": display_title,
            "artist": get_artist_name(artists),
            "thumb": basic_info.get("thumb", ""),
            "year": basic_info.get("year", 0),
            "format": get_format(formats),
            "tracks": release_details.get("tracks", 0),
            "duration": release_details.get("duration", ""),
            "duration_seconds": release_details.get("duration_seconds", 0),
            "folder_id": item_folder_id,
            "folder": folder_name,
        }

    # Provide a more helpful error message based on folder selection
    if using_all_folders:
        if len(excluded_folder_ids) > 0 and len(excluded_artist_ids) > 0:
            return {"error": "Could not find a Vinyl outside excluded folders/artists."}
        if len(excluded_folder_ids) > 0:
            return {"error": "Could not find a Vinyl outside excluded folders."}
        if len(excluded_artist_ids) > 0:
            return {"error": "Could not find a Vinyl outside excluded artists."}
        return {"error": "Could not find a Vinyl release in your collection."}
    if len(excluded_folder_ids) > 0 and len(excluded_artist_ids) > 0:
        return {"error": "Could not find a Vinyl in selected folders outside excluded folders/artists."}
    if len(excluded_folder_ids) > 0:
        return {"error": "Could not find a Vinyl in selected folders outside excluded folders."}
    if len(excluded_artist_ids) > 0:
        return {"error": "Could not find a Vinyl in selected folders outside excluded artists."}
    return {"error": "Could not find a Vinyl in selected folders."}

def parse_filter_folder_ids(filter_by_folder):
    """
    Parses a comma-separated folder filter into a dict-like set.
    If empty (or contains 0), defaults to all folders.
    """

    folder_ids = parse_excluded_ids(filter_by_folder, allow_folder_prefix = True)

    if len(folder_ids) == 0 or "0" in folder_ids:
        return {"0": True}

    return folder_ids

def get_collection_info(username, headers, folder_id):
    """Fetches collection pagination metadata for a specific folder ID."""

    folder_id = ("%s" % folder_id).strip()
    if folder_id.startswith("f_"):
        folder_id = folder_id[2:]
    if folder_id == "" or folder_id == "None":
        folder_id = "0"

    cache_key = (COLLECTION_CACHE_KEY % username) + "_folder_%s" % folder_id
    cached_collection = cache.get(cache_key)
    if cached_collection:
        return json.decode(cached_collection)

    collection_url = "%s/users/%s/collection/folders/%s/releases?per_page=1" % (
        DISCOGS_API_BASE,
        username,
        folder_id,
    )

    resp = http.get(collection_url, headers = headers)
    if resp.status_code != 200:
        return {"error": "API %d: folder %s" % (resp.status_code, folder_id)}

    data = resp.json()
    if "pagination" not in data:
        return {"error": "Invalid API response"}

    collection_info = {
        "total_items": data["pagination"]["items"],
        "per_page": 50,  # Use 50 per page for fetching
    }

    cache.set(cache_key, json.encode(collection_info), ttl_seconds = COLLECTION_CACHE_TTL)
    return collection_info

def choose_random_folder(folder_ids, folder_totals, total_items):
    """Picks one folder ID, weighted by each folder's collection size."""

    if len(folder_ids) == 0:
        return "0"

    if len(folder_ids) == 1:
        return folder_ids[0]

    pick = random.number(1, total_items)
    running = 0

    for folder_id in folder_ids:
        running += int(folder_totals.get(folder_id, 0))
        if pick <= running:
            return folder_id

    return folder_ids[len(folder_ids) - 1]

def parse_excluded_folders(excluded_folders):
    """
    Parses a comma-separated list of folder IDs into a dict-like set.
    Accepts values like: "5176672,5524697,f_5176666"
    """

    return parse_excluded_ids(excluded_folders, allow_folder_prefix = True)

def parse_excluded_artists(excluded_artists):
    """Parses a comma-separated list of artist IDs into a dict-like set."""

    return parse_excluded_ids(excluded_artists)

def parse_excluded_ids(raw_value, allow_folder_prefix = False):
    """Parses a comma-separated ID list into a dict-like set of numeric string IDs."""

    folder_ids = {}
    raw = "%s" % raw_value

    if raw == "" or raw == "None":
        return folder_ids

    for part in raw.split(","):
        value = part.strip()
        if value == "":
            continue

        if allow_folder_prefix and value.startswith("f_"):
            value = value[2:]

        # Keep only numeric IDs
        if value.isdigit():
            folder_ids[value] = True

    return folder_ids

def has_excluded_artist(artists, excluded_artist_ids):
    """True if any artist id in artists exists in excluded_artist_ids."""

    if len(excluded_artist_ids) == 0:
        return False

    for artist in artists or []:
        artist_id = artist.get("id", None)
        if artist_id == None:
            continue
        if ("%s" % artist_id) in excluded_artist_ids:
            return True

    return False

def get_release_details(release_id, headers):
    """
    Fetches detailed release information including tracklist.
    Returns track count and total duration.
    """

    if release_id == 0:
        return {"tracks": 0, "duration": "", "duration_seconds": 0}

    # Check cache first
    cache_key = RELEASE_CACHE_KEY % str(release_id)
    cached_release = cache.get(cache_key)

    if cached_release:
        return json.decode(cached_release)

    # Fetch release details
    release_url = "%s/releases/%d" % (DISCOGS_API_BASE, release_id)
    resp = http.get(release_url, headers = headers)

    if resp.status_code != 200:
        return {"tracks": 0, "duration": "", "duration_seconds": 0}

    data = resp.json()
    tracklist = data.get("tracklist", [])

    # Count actual tracks (exclude headings, index tracks, etc.)
    track_count = 0
    total_seconds = 0

    for track in tracklist:
        track_type = track.get("type_", "track")
        if track_type == "track":
            track_count += 1
            duration_str = track.get("duration", "")
            if duration_str:
                total_seconds += parse_duration(duration_str)

    # Format total duration
    duration_formatted = format_duration(total_seconds)

    result = {
        "tracks": track_count,
        "duration": duration_formatted,
        "duration_seconds": total_seconds,
    }

    # Cache the result
    cache.set(cache_key, json.encode(result), ttl_seconds = RELEASE_CACHE_TTL)

    return result

def parse_duration(duration_str):
    """Parses a duration string like '3:45' or '1:23:45' into seconds."""

    if not duration_str:
        return 0

    parts = duration_str.split(":")

    if len(parts) == 2:
        # MM:SS format
        minutes = int(parts[0]) if parts[0].isdigit() else 0
        seconds = int(parts[1]) if parts[1].isdigit() else 0
        return minutes * 60 + seconds
    elif len(parts) == 3:
        # HH:MM:SS format
        hours = int(parts[0]) if parts[0].isdigit() else 0
        minutes = int(parts[1]) if parts[1].isdigit() else 0
        seconds = int(parts[2]) if parts[2].isdigit() else 0
        return hours * 3600 + minutes * 60 + seconds

    return 0

def format_duration(total_seconds):
    """Formats seconds into a readable duration string."""

    if total_seconds == 0:
        return ""

    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60

    if hours > 0:
        return "%dh %dm" % (hours, minutes)
    else:
        return "%dm" % minutes

def get_artist_name(artists):
    """Extracts the primary artist name from the artists array."""

    if not artists or len(artists) == 0:
        return "Unknown Artist"

    # Join multiple artists with " & "
    names = []
    for artist in artists:
        name = artist.get("name", "")
        if name:
            # Remove trailing number disambiguation (e.g., "Artist (2)")
            if " (" in name and name.endswith(")"):
                name = name.rsplit(" (", 1)[0]
            names.append(name)

    if len(names) == 0:
        return "Unknown Artist"
    elif len(names) == 1:
        return names[0]
    elif len(names) == 2:
        return names[0] + " & " + names[1]
    else:
        return names[0] + " & others"

def is_vinyl(formats):
    """True if formats contains an object with name == 'Vinyl'."""
    for f in formats or []:
        if (f.get("name", "") or "").strip().lower() == "vinyl":
            return True
    return False

def has_format_description(formats, target_description):
    """True if any format description matches target_description."""
    target = (target_description or "").strip().lower()
    if target == "":
        return False

    for f in formats or []:
        for desc in f.get("descriptions", []) or []:
            if ("%s" % desc).strip().lower() == target:
                return True

    return False

def get_folder_map(username, headers):
    """
    Returns a dict mapping folder_id (as a string) -> folder name.
    Cached to avoid extra API calls.
    """
    cache_key = FOLDERS_CACHE_KEY % username
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    url = "%s/users/%s/collection/folders" % (DISCOGS_API_BASE, username)
    resp = http.get(url, headers = headers)
    if resp.status_code != 200:
        # Non-fatal: just omit folder names.
        return {}

    data = resp.json()
    folders = data.get("folders", [])
    folder_map = {}
    for f in folders:
        fid = int(f.get("id", -1))
        if fid >= 0:
            folder_map[str(fid)] = f.get("name", "")

    cache.set(cache_key, json.encode(folder_map), ttl_seconds = FOLDERS_CACHE_TTL)
    return folder_map

def get_format(formats):
    """Extracts the primary format (e.g., 'LP', '12\"', 'CD')."""

    if not formats or len(formats) == 0:
        return ""

    return formats[0].get("name", "")

def hold(frame, n):
    # Repeat `frame` n times (at least once)
    if n < 1:
        n = 1
    return [frame] * n

def get_target_display_frames(config, root_delay_ms):
    """
    Returns the app's target frame budget based on display_time_seconds.
    Keep this aligned with Tronbyt's per-app Display Time Seconds.
    """
    total_ms = 15000  # 15s default
    display_time_raw = ("%s" % config.str("display_time_seconds", "15")).strip()
    if display_time_raw.isdigit():
        parsed_seconds = int(display_time_raw)
        if parsed_seconds > 0:
            total_ms = parsed_seconds * 1000

    if total_ms < root_delay_ms:
        total_ms = root_delay_ms

    total_frames = total_ms // root_delay_ms
    if total_frames < 1:
        total_frames = 1

    return total_frames

def repeat_child_to_cover_frames(child, min_frames):
    """
    Repeat child as full animation cycles until at least min_frames are covered.
    This keeps marquee/animated widgets moving instead of freezing on their last frame.
    """
    if min_frames < 1:
        min_frames = 1

    cycle_frames = child.frame_count()
    if cycle_frames < 1:
        cycle_frames = 1

    loops = (min_frames + cycle_frames - 1) // cycle_frames
    if loops < 1:
        loops = 1

    if loops == 1:
        return child

    return render.Sequence(children = hold(child, loops))

def render_with_optional_logo_intro(config, main_child, root_delay_ms):
    """Wrap main content with an optional centered intro logo screen."""
    scale = 2 if canvas.is2x() else 1
    target_display_frames = get_target_display_frames(config, root_delay_ms)
    repeated_main_child = repeat_child_to_cover_frames(main_child, target_display_frames)

    if not config.bool("show_logo_intro", True):
        return render.Root(
            delay = root_delay_ms,
            child = repeated_main_child,
        )

    intro_duration_ms = 500
    intro_duration_raw = "%s" % config.str("logo_intro_duration_ms", "500")
    if intro_duration_raw.isdigit():
        intro_duration_ms = int(intro_duration_raw)
    if intro_duration_ms < root_delay_ms:
        intro_duration_ms = root_delay_ms

    intro_frames = intro_duration_ms // root_delay_ms
    if intro_frames < 1:
        intro_frames = 1
    if intro_frames >= target_display_frames and target_display_frames > 1:
        # Reserve at least one frame for main content.
        intro_frames = target_display_frames - 1

    main_frames = target_display_frames - intro_frames
    if main_frames < 1:
        main_frames = 1
    repeated_main_child = repeat_child_to_cover_frames(main_child, main_frames)

    intro_screen = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Padding(
                child = render.Image(
                    src = ROULETTE_LOGO.readall(),
                    height = 30 * scale,
                ),
                pad = (9 * scale, 0, 0, 0),
            ),
        ],
    )

    return render.Root(
        delay = root_delay_ms,
        child = render.Sequence(
            children = [
                render.Animation(children = hold(intro_screen, intro_frames)),
                repeated_main_child,
            ],
        ),
    )

def render_vinyl(config, release_data):
    """Renders the release information for the Tidbyt display."""
    scale = 2 if canvas.is2x() else 1
    display_width = canvas.width()
    display_height = canvas.height()
    column_width = display_width // 2
    art_size = 28 * scale
    gap_size = 2 * scale
    small_spacer = 1 * scale
    large_spacer = 3 * scale
    content_padding = 1 * scale
    full_marquee_width = display_width - (2 * content_padding)

    title = release_data["title"]
    artist = release_data["artist"]
    thumb_url = release_data["thumb"]
    year = release_data["year"]
    tracks = release_data["tracks"]
    duration = release_data["duration"]
    folder = release_data.get("folder", "")

    # Build info line (folder + year + tracks + duration)
    info_parts = []

    if year:
        info_parts.append(str(int(year)))

    if tracks >= 0:
        label = "track" if tracks == 1 else "tracks"
        info_parts.append("%d %s" % (tracks, label))

    if duration:
        info_parts.append(duration)

    # Fetch album art if available
    album_art = None
    if thumb_url:
        art_resp = http.get(thumb_url)
        if art_resp.status_code == 200:
            album_art = art_resp.body()

    root_delay_ms = 25 if canvas.is2x() else 50
    hold_ms = 2000  # shorten `hold_ms` time to cycle stats sooner
    n = hold_ms // root_delay_ms
    stats_color = config.str("album_stats_color", "#888888")

    children = []

    # Year (always show if present)
    if len(info_parts) > 0 and info_parts[0]:
        text0 = render.Text(content = info_parts[0], font = "6x10" if canvas.is2x() else "tom-thumb", color = stats_color)
        children += hold(text0, n)

    # Number of tracks (only include if it exists and is non-empty)
    if len(info_parts) > 1 and info_parts[1]:
        text1 = render.Text(content = info_parts[1], font = "6x10" if canvas.is2x() else "tom-thumb", color = stats_color)
        children += hold(text1, n)

    # Album duration (only include if it exists and is non-empty)
    if len(info_parts) > 2 and info_parts[2]:
        text2 = render.Text(content = info_parts[2], font = "6x10" if canvas.is2x() else "tom-thumb", color = stats_color)
        children += hold(text2, n)

    # Fallback: ensure at least one frame
    if len(children) == 0:
        # children = [render.Box()]
        children = [render.Text(content = "", font = "6x10" if canvas.is2x() else "tom-thumb", color = stats_color)]

    info_cycler = render.Animation(children = children)

    # Build the display layout
    if album_art:
        # Layout with album art on the left
        main_layout = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                # Album art (scaled to fit height)
                render.Image(
                    src = album_art,
                    width = art_size,
                    height = art_size,
                ),
                render.Box(width = gap_size, height = small_spacer),  # Spacer
                # Text info
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "start",
                    children = [
                        # Album name
                        render.Marquee(
                            width = column_width,
                            child = render.Text(
                                content = title,
                                font = "terminus-14" if canvas.is2x() else "tb-8",
                                color = config.str("album_title_color", "#FFFFFF"),
                            ),
                        ),
                        render.Box(width = 0, height = small_spacer),  # Spacer

                        # Artist name
                        render.Marquee(
                            width = column_width,
                            child = render.Text(
                                content = artist,
                                font = "terminus-12" if canvas.is2x() else "tom-thumb",
                                color = config.str("album_artist_color", "#AAAAAA"),
                            ),
                        ),
                        render.Box(width = 0, height = large_spacer),  # Spacer

                        # Scrolling info line (folder, year, tracks, duration, etc.)
                        info_cycler if len(info_parts) > 0 and config.bool("show_stats", True) else render.Box(height = small_spacer),
                        render.Box(width = 0, height = small_spacer),  # Spacer

                        # Folder name
                        render.Marquee(
                            width = column_width,
                            child = render.Text(
                                content = folder,
                                font = "6x10" if canvas.is2x() else "tom-thumb",
                                color = config.str("folder_name_color", "#666666"),
                            ),
                        ),
                    ],
                ),
            ],
        )
    else:
        # Text-only layout (no album art)
        main_layout = render.Box(
            padding = content_padding,
            child = render.Column(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = [
                    # Album name
                    render.Marquee(
                        width = full_marquee_width,
                        align = "center",
                        child = render.Text(
                            content = title,
                            font = "terminus-18" if canvas.is2x() else "6x10",
                            color = config.str("album_title_color", "#FFFFFF"),
                        ),
                    ),
                    render.Box(width = 0, height = small_spacer),  # Spacer

                    # Artist name
                    render.Marquee(
                        width = full_marquee_width,
                        align = "center",
                        child = render.Text(
                            content = artist,
                            font = "6x13" if canvas.is2x() else "tom-thumb",
                            color = config.str("album_artist_color", "#AAAAAA"),
                        ),
                    ),
                    render.Box(width = 0, height = small_spacer + (3 if canvas.is2x() else 0)),  # Spacer

                    # Scrolling info line (folder, year, tracks, duration, etc.)
                    info_cycler if len(info_parts) > 0 and config.bool("show_stats", True) else render.Box(height = small_spacer),

                    # Folder name
                    render.Marquee(
                        width = full_marquee_width,
                        align = "center",
                        child = render.Text(
                            content = folder,
                            font = "6x10" if canvas.is2x() else "tom-thumb",
                            color = config.str("folder_name_color", "#666666"),
                        ),
                    ),
                ],
            ),
        )

    main_layout = render.Box(
        width = display_width,
        height = display_height,
        child = main_layout,
    )

    return render_with_optional_logo_intro(
        config = config,
        main_child = main_layout,
        root_delay_ms = root_delay_ms,
    )

def render_error(message):
    """Renders an error message on the display."""
    scale = 2 if canvas.is2x() else 1

    return render.Root(
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            padding = 2 * scale,
            child = render.WrappedText(
                content = message,
                font = "6x10" if canvas.is2x() else "tom-thumb",
                color = "#FF6666",
                align = "center",
            ),
        ),
    )

def stats_options_handler(show_stats):
    """
    Handler called when show_stats changes.
    Returns sub-toggles only when show_stats is "true".
    """
    if show_stats == "true":
        return [
            schema.Toggle(
                id = "show_year",
                name = "Show Year",
                desc = "Display album year (only when Show Stats is enabled).",
                icon = "calendar",
                default = True,
            ),
            schema.Toggle(
                id = "show_tracks",
                name = "Show Tracks",
                desc = "Display album tracks (only when Show Stats is enabled).",
                icon = "list",
                default = True,
            ),
            schema.Toggle(
                id = "show_duration",
                name = "Show Duration",
                desc = "Display album duration (only when Show Stats is enabled).",
                icon = "clock",
                default = True,
            ),
            schema.Color(
                id = "album_stats_color",
                name = "Album Stats Color",
                desc = "The text color of the album's stats. (e.g. what cycles through)",
                icon = "brush",
                default = "#888888",
            ),
        ]
    else:
        return []  # Hide these fields when stats are disabled

def logo_intro_options_handler(show_logo_intro):
    """
    Handler called when show_logo_intro changes.
    Returns logo-intro related options only when show_logo_intro is "true".
    """
    if show_logo_intro == "true":
        return [
            schema.Text(
                id = "display_time_seconds",
                name = "Display Time Seconds",
                desc = "Match Tronbyt's per-app Display Time Seconds (whole seconds) so the intro shows once and the rest fills the remaining time.",
                icon = "clock",
                default = "15",
            ),
            schema.Dropdown(
                id = "logo_intro_duration_ms",
                name = "Logo Intro Duration",
                desc = "How long to display the intro logo.",
                icon = "clock",
                default = "500",
                options = [
                    schema.Option(display = "0.5s", value = "500"),
                    schema.Option(display = "1.0s", value = "1000"),
                    schema.Option(display = "1.2s", value = "1200"),
                    schema.Option(display = "1.5s", value = "1500"),
                    schema.Option(display = "2.0s", value = "2000"),
                    schema.Option(display = "3.0s", value = "3000"),
                ],
            ),
        ]
    else:
        return []

def get_schema():
    """
    Defines the configuration schema for the Tidbyt mobile app.
    Users will enter their Discogs username and personal access token.
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Discogs Username",
                desc = "Enter your Discogs username",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "token",
                name = "Discogs Personal Access Token",
                desc = "Enter your Discogs personal access token",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = "filter_by_folder",
                name = "Filter by Folder (optional)",
                desc = "Limit results to specific Discogs folder IDs. Enter one or more IDs separated by commas (e.g., 12345, 67890). Use 0 or leave blank to include all folders.",
                icon = "filter",
                default = "",
            ),
            schema.Text(
                id = "excluded_folders",
                name = "Exclude folder IDs (optional)",
                desc = "Any vinyl that appears in these Discogs folders will not be returned. Enter ID numbers separated by commas (e.g., 12345, 67890).",
                icon = "folderMinus",
            ),
            schema.Text(
                id = "excluded_artists",
                name = "Exclude artist IDs (optional)",
                desc = "Any vinyl with these artist IDs will not be returned. Enter ID numbers separated by commas (e.g., 12345, 67890).",
                icon = "userSlash",
            ),
            schema.Color(
                id = "album_title_color",
                name = "Album Title Color",
                desc = "The text color of the album title.",
                icon = "brush",
                default = "#FFFFFF",
            ),
            schema.Color(
                id = "album_artist_color",
                name = "Album Artist Name Color",
                desc = "The text color of the album artist.",
                icon = "brush",
                default = "#AAAAAA",
            ),
            schema.Color(
                id = "folder_name_color",
                name = "Folder Name Color",
                desc = "The text color of the folder name.",
                icon = "brush",
                default = "#888888",
                palette = [
                    "#888888",
                    "#34495E",
                    "#666666",
                    "#8E44AD",
                ],
            ),
            schema.Toggle(
                id = "show_logo_intro",
                name = "Show Logo Intro",
                desc = "Display a brief centered logo before the album details.",
                icon = "play",
                default = False,
            ),
            schema.Generated(
                id = "logo_intro_options",
                source = "show_logo_intro",  # Watch this field
                handler = logo_intro_options_handler,  # Call this when it changes
            ),
            schema.Toggle(
                id = "show_stats",
                name = "Show Stats",
                desc = "Display album stats (year, duration, etc.)",
                icon = "info",
                default = False,
            ),
            schema.Generated(
                id = "stats_options",
                source = "show_stats",  # Watch this field
                handler = stats_options_handler,  # Call this when it changes
            ),
        ],
    )
