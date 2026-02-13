"""\r
Spotify Now Playing - Ultimate Edition for Tronbyt/Tidbyt\r
=========================================================\r
\r
Author: gshepperd\r
Version: 2.1.0\r
\r
================================================================================\r
                            INSTALLATION INSTRUCTIONS\r
================================================================================\r
\r
STEP 1: CREATE A SPOTIFY DEVELOPER APP\r
--------------------------------------\r
1. Go to: https://developer.spotify.com/dashboard\r
2. Log in with your Spotify account\r
3. Click "Create App"\r
4. Fill in the form:\r
   - App name: "Tronbyt Now Playing" (or whatever you like)\r
   - App description: "Display currently playing on Tronbyt"\r
   - Website: (leave blank or enter any URL)\r
   - Redirect URI: http://127.0.0.1:8888/callback   <-- IMPORTANT!\r
     (Click "Add" after entering the URI)\r
   - Which API/SDKs are you planning to use?\r
     [x] Web API   <-- CHECK THIS ONE\r
     [ ] Web Playback SDK (not needed)\r
     [ ] Android (not needed)\r
     [ ] iOS (not needed)\r
5. Check the Terms of Service box and click "Save"\r
6. Click "Settings" on your new app\r
7. Copy your "Client ID" and "Client Secret" (click "View client secret")\r
\r
STEP 2: GET YOUR REFRESH TOKEN\r
------------------------------\r
Run the included Python script on the SAME MACHINE as your web browser:\r
\r
    python3 get_refresh_token.py\r
\r
The script will:\r
1. Ask for your Client ID and Client Secret\r
2. Open your browser to authorize with Spotify\r
3. Display your refresh token when complete\r
\r
Save all three values:\r
- Client ID\r
- Client Secret  \r
- Refresh Token\r
\r
ALTERNATIVE: MANUAL METHOD (if script doesn't work)\r
---------------------------------------------------\r
If you can't run the Python script on the same machine as your browser\r
(e.g., you're SSH'd into a remote server), use this manual method:\r
\r
1. Open this URL in your browser (replace YOUR_CLIENT_ID):\r
\r
   https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://127.0.0.1:8888/callback&scope=user-read-currently-playing%20user-read-playback-state%20user-read-recently-played&show_dialog=true\r
\r
2. After authorizing, the page won't load (that's expected). Copy the \r
   "code=" value from the URL bar. It will look like:\r
   \r
   http://127.0.0.1:8888/callback?code=AQCxxxVERYLONGSTRINGxxx\r
\r
3. Run this curl command (replace YOUR_CLIENT_ID, YOUR_CLIENT_SECRET, \r
   and YOUR_CODE_HERE):\r
\r
   curl -X POST "https://accounts.spotify.com/api/token" \\\r
     -H "Content-Type: application/x-www-form-urlencoded" \\\r
     -d "grant_type=authorization_code" \\\r
     -d "code=YOUR_CODE_HERE" \\\r
     -d "redirect_uri=http://127.0.0.1:8888/callback" \\\r
     -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET"\r
\r
4. Copy the "refresh_token" value from the JSON response.\r
\r
NOTE: The code expires in ~10 minutes, so run curl quickly after step 2.\r
\r
STEP 3: CONFIGURE IN TRONBYT\r
----------------------------\r
1. Open your Tronbyt web interface (usually http://your-server:8000)\r
2. Add this app (upload spotify.star or add as custom app)\r
3. Configure these fields:\r
   - Spotify Client ID:     [paste your Client ID]\r
   - Spotify Client Secret: [paste your Client Secret]\r
   - Refresh Token:         [paste your Refresh Token]\r
4. Optionally configure display mode, colors, etc.\r
5. Save and enjoy!\r
\r
STEP 4: PLAY MUSIC\r
------------------\r
Start playing something on Spotify. Within 30-60 seconds (depending on\r
your Tronbyt refresh rate), you'll see it on your display!\r
\r
================================================================================\r
                                 TROUBLESHOOTING\r
================================================================================\r
\r
"Setup needed" error:\r
  -> Your credentials aren't configured. Add them in app settings.\r
\r
"Auth Error: Token revoked" error:\r
  -> Run get_refresh_token.py again to get a new token.\r
  -> This happens if you revoked access or deleted your Spotify app.\r
\r
"Auth Error: Bad credentials" error:\r
  -> Double-check your Client ID and Client Secret.\r
\r
Nothing displays / black screen:\r
  -> Check that a track is active (playing or paused) on one of your devices.\r
  -> Some private sessions don't report to the API.\r
  -> Check that "Show When Idle" is enabled in settings.\r
\r
Album art not showing:\r
  -> Local files don't have artwork.\r
  -> Try a different display mode.\r
\r
================================================================================\r
                                    FEATURES\r
================================================================================\r
\r
Display Modes:\r
- Full:      Album art + track + artist + progress bar + time remaining\r
- Compact:   Album art + track + artist (no progress bar)\r
- Art Focus: Large album art with text overlay at bottom\r
- Text Only: No art, full width for text + progress bar\r
- Minimal:   Just track and artist, centered\r
\r
Content Support:\r
- Music tracks with full metadata\r
- Podcast episodes (show name, episode title)\r
- Paused playback detection\r
- Recently played fallback (optional)\r
- Graceful handling of Spotify ads\r
\r
Robustness:\r
- Exponential backoff on rate limits\r
- Pre-emptive token refresh (at 45 min, expires at 60)\r
- Multi-layer caching (tokens 45min, album art 24hr)\r
- Graceful degradation (shows text if art fails)\r
- Actionable error messages\r
\r
================================================================================\r
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# =============================================================================
# CONSTANTS
# =============================================================================

# API Endpoints
TOKEN_URL = "https://accounts.spotify.com/api/token"
NOW_PLAYING_URL = "https://api.spotify.com/v1/me/player/currently-playing"
PLAYER_URL = "https://api.spotify.com/v1/me/player"
RECENTLY_PLAYED_URL = "https://api.spotify.com/v1/me/player/recently-played"

# Cache Configuration
CACHE_PREFIX = "spotify_v2_"
TOKEN_CACHE_TTL = 2700  # 45 min (tokens last 60, refresh early)
ART_CACHE_TTL = 86400  # 24 hours (album art URLs are stable)
ERROR_CACHE_TTL = 30  # 30 sec backoff on errors
MAX_ERROR_BACKOFF = 300  # Max 5 min backoff

# Display Modes
MODE_FULL = "full"  # Art + text + progress bar
MODE_COMPACT = "compact"  # Art + text, no progress
MODE_ART_FOCUS = "art_focus"  # Large art + minimal text overlay
MODE_TEXT_ONLY = "text"  # No art, full width text
MODE_MINIMAL = "minimal"  # Just track name, nothing else

# Colors
SPOTIFY_GREEN = "#1DB954"
SPOTIFY_BLACK = "#191414"
WHITE = "#FFFFFF"
LIGHT_GRAY = "#B3B3B3"
DARK_GRAY = "#535353"
ERROR_RED = "#E74C3C"
WARNING_YELLOW = "#F39C12"
PROGRESS_BG = "#404040"

# Fonts - 1x resolution
FONT_TRACK_1X = "tb-8"
FONT_ARTIST_1X = "tom-thumb"
FONT_TIME_1X = "tom-thumb"
FONT_LARGE_1X = "6x13"
FONT_SMALL_1X = "CG-pixel-3x5-mono"

# Fonts - 2x resolution
FONT_TRACK_2X = "terminus-16"
FONT_ARTIST_2X = "tb-8"
FONT_TIME_2X = "tb-8"
FONT_LARGE_2X = "terminus-16"
FONT_SMALL_2X = "tom-thumb"

# Device type icons (simple representations)
DEVICE_ICONS = {
    "Computer": "💻",
    "Smartphone": "📱",
    "Speaker": "🔊",
    "TV": "📺",
    "default": "🎵",
}

# =============================================================================
# 2X RESOLUTION HELPERS
# =============================================================================

def s(val):
    """Scale a dimension value for 2x rendering."""
    return val * 2 if canvas.is2x() else val

def font_track():
    """Get track name font for current resolution."""
    return FONT_TRACK_2X if canvas.is2x() else FONT_TRACK_1X

def font_artist():
    """Get artist name font for current resolution."""
    return FONT_ARTIST_2X if canvas.is2x() else FONT_ARTIST_1X

def font_time():
    """Get time display font for current resolution."""
    return FONT_TIME_2X if canvas.is2x() else FONT_TIME_1X

def font_large():
    """Get large text font for current resolution."""
    return FONT_LARGE_2X if canvas.is2x() else FONT_LARGE_1X

def font_small():
    """Get small text font for current resolution."""
    return FONT_SMALL_2X if canvas.is2x() else FONT_SMALL_1X

def scale_delay(delay):
    """Halve animation delay at 2x to maintain perceived scroll speed."""
    if canvas.is2x():
        return max(delay // 2, 1)
    return delay

def select_best_image(images):
    """Select the best image URL based on display resolution."""
    if not images:
        return None
    if canvas.is2x():
        # For 2x, prefer a larger image for better quality
        for img in reversed(images):
            url = img.get("url")
            w = img.get("width", 0)
            if url and w >= 128:
                return url

        # Fallback to largest available
        for img in images:
            if img.get("url"):
                return img["url"]
    else:
        # For 1x, prefer smallest image
        for img in reversed(images):
            if img.get("url"):
                return img["url"]
    return None

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

def cache_key(suffix):
    """Generate a namespaced cache key."""
    return CACHE_PREFIX + suffix

def clamp(value, min_val, max_val):
    """Clamp a value between min and max."""
    if value < min_val:
        return min_val
    if value > max_val:
        return max_val
    return value

def format_duration(ms):
    """Format milliseconds as M:SS or H:MM:SS."""
    if ms == None or ms < 0:
        return "--:--"

    total_seconds = int(ms / 1000)
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60

    # Pad seconds with leading zero if needed
    seconds_str = str(seconds)
    if seconds < 10:
        seconds_str = "0" + seconds_str

    if hours > 0:
        # Pad minutes with leading zero if needed
        minutes_str = str(minutes)
        if minutes < 10:
            minutes_str = "0" + minutes_str
        return str(hours) + ":" + minutes_str + ":" + seconds_str

    return str(minutes) + ":" + seconds_str

def truncate_text(text, max_chars):
    """Truncate text with ellipsis if too long."""
    if len(text) <= max_chars:
        return text
    return text[:max_chars - 1] + "…"

def text_width_estimate(text, font):
    """
    Estimate pixel width of text.
    This is approximate since we don't have actual font metrics.
    """

    # Rough character widths for common fonts
    widths = {
        "tb-8": 6,
        "tom-thumb": 4,
        "6x13": 6,
        "CG-pixel-3x5-mono": 4,
        "terminus-16": 8,
        "10x20": 10,
    }
    char_width = widths.get(font, 5)
    return len(text) * char_width

def needs_scroll(text, available_width, font):
    """Determine if text needs scrolling marquee."""
    return text_width_estimate(text, font) > available_width

def get_error_backoff():
    """Get current error backoff time, implementing exponential backoff."""
    backoff_str = cache.get(cache_key("error_backoff"))
    if backoff_str:
        return int(backoff_str)
    return 0

def set_error_backoff(seconds):
    """Set error backoff time."""
    cache.set(cache_key("error_backoff"), str(seconds), ttl_seconds = seconds + 10)

def increase_error_backoff():
    """Increase error backoff exponentially."""
    current = get_error_backoff()
    if current == 0:
        new_backoff = ERROR_CACHE_TTL
    else:
        new_backoff = min(current * 2, MAX_ERROR_BACKOFF)
    set_error_backoff(new_backoff)
    return new_backoff

def clear_error_backoff():
    """Clear error backoff on success."""
    cache.set(cache_key("error_backoff"), "", ttl_seconds = 1)

def hash_string(s):
    """Simple string hash for cache keys."""
    h = 0
    for c in s.elems():
        h = (h * 31 + ord(c)) % 2147483647
    return str(h)

# =============================================================================
# AUTHENTICATION
# =============================================================================

def make_basic_auth(client_id, client_secret):
    """Create HTTP Basic auth header value."""
    credentials = client_id + ":" + client_secret
    encoded = base64.encode(credentials)
    return "Basic " + encoded

def get_access_token(client_id, client_secret, refresh_token):
    """
    Get a valid access token, refreshing if necessary.
    Implements caching and pre-emptive refresh.
    """

    # Check if we're in error backoff
    backoff = get_error_backoff()
    if backoff > 0:
        # Still use cached token if available during backoff
        cached = cache.get(cache_key("access_token"))
        if cached:
            return cached, None
        return None, "Rate limited (retry in %ds)" % backoff

    # Check cache for valid token
    cached_token = cache.get(cache_key("access_token"))
    if cached_token:
        return cached_token, None

    # Need to refresh - build request
    auth_header = make_basic_auth(client_id, client_secret)
    body = "grant_type=refresh_token&refresh_token=" + refresh_token

    # Make token request
    resp = http.post(
        url = TOKEN_URL,
        headers = {
            "Authorization": auth_header,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        body = body,
        ttl_seconds = 30,  # Don't cache this request
    )

    # Handle response
    if resp.status_code == 200:
        data = resp.json()
        token = data.get("access_token")
        if token:
            # Cache token
            cache.set(cache_key("access_token"), token, ttl_seconds = TOKEN_CACHE_TTL)
            clear_error_backoff()
            return token, None
        return None, "No token in response"

    # Handle errors
    if resp.status_code == 400:
        error_data = resp.json()
        error = error_data.get("error", "")
        if "invalid_grant" in error:
            return None, "Token revoked - reauthorize"
        return None, "Bad request: " + error

    if resp.status_code == 401:
        return None, "Invalid credentials"

    if resp.status_code == 429:
        # Rate limited
        increase_error_backoff()
        return None, "Rate limited"

    # Other errors - implement backoff
    increase_error_backoff()
    return None, "Auth error: " + str(resp.status_code)

# =============================================================================
# SPOTIFY API
# =============================================================================

def fetch_player_state(access_token):
    """
    Fetch full player state including device info.
    Returns dict with player info or None.
    """
    resp = http.get(
        url = PLAYER_URL,
        headers = {"Authorization": "Bearer " + access_token},
        ttl_seconds = 5,  # Short cache for real-time data
    )

    if resp.status_code == 204:
        return None  # No active player

    if resp.status_code == 401:
        # Token expired - clear cache
        cache.set(cache_key("access_token"), "", ttl_seconds = 1)
        return None

    if resp.status_code != 200:
        return None

    return resp.json()

def fetch_currently_playing(access_token):
    """
    Fetch currently playing track/episode.
    Returns dict with track info or None.
    """

    # Include additional_types to get podcast episodes
    url = NOW_PLAYING_URL + "?additional_types=track,episode"

    resp = http.get(
        url = url,
        headers = {"Authorization": "Bearer " + access_token},
        ttl_seconds = 5,
    )

    if resp.status_code == 204:
        return None

    if resp.status_code == 401:
        cache.set(cache_key("access_token"), "", ttl_seconds = 1)
        return None

    if resp.status_code != 200:
        return None

    return resp.json()

def fetch_recently_played(access_token):
    """Fetch most recently played track."""
    url = RECENTLY_PLAYED_URL + "?limit=1"

    resp = http.get(
        url = url,
        headers = {"Authorization": "Bearer " + access_token},
        ttl_seconds = 60,  # Cache recent tracks longer
    )

    if resp.status_code != 200:
        return None

    data = resp.json()
    items = data.get("items", [])

    if not items:
        return None

    return items[0]

def fetch_album_art(url):
    """
    Fetch album art image data with caching.
    Returns image bytes or None.
    """
    if not url:
        return None

    # Use URL hash for cache key
    art_cache_key = cache_key("art_" + hash_string(url))

    cached = cache.get(art_cache_key)
    if cached:
        return cached

    resp = http.get(url, ttl_seconds = ART_CACHE_TTL)

    if resp.status_code != 200:
        return None

    art_data = resp.body()
    cache.set(art_cache_key, art_data, ttl_seconds = ART_CACHE_TTL)

    return art_data

# =============================================================================
# DATA PARSING
# =============================================================================

def parse_track(item):
    """Parse track object from Spotify API."""
    if not item:
        return None

    name = item.get("name", "Unknown Track")

    # Parse artists
    artists = item.get("artists", [])
    artist_names = [a.get("name", "") for a in artists if a.get("name")]
    artist = ", ".join(artist_names) if artist_names else "Unknown Artist"

    # Parse album
    album = item.get("album", {})
    album_name = album.get("name", "")

    # Get best album art URL for current resolution
    images = album.get("images", [])
    art_url = select_best_image(images)

    # Duration
    duration_ms = item.get("duration_ms", 0)

    # Explicit flag
    explicit = item.get("explicit", False)

    return {
        "type": "track",
        "name": name,
        "artist": artist,
        "album": album_name,
        "art_url": art_url,
        "duration_ms": duration_ms,
        "explicit": explicit,
    }

def parse_episode(item):
    """Parse podcast episode from Spotify API."""
    if not item:
        return None

    name = item.get("name", "Unknown Episode")

    # Show info
    show = item.get("show", {})
    show_name = show.get("name", "Unknown Podcast")
    publisher = show.get("publisher", "")

    # Images - episode or show
    images = item.get("images", []) or show.get("images", [])
    art_url = select_best_image(images)

    duration_ms = item.get("duration_ms", 0)
    explicit = item.get("explicit", False)

    return {
        "type": "episode",
        "name": name,
        "artist": show_name,  # Use show name as "artist"
        "album": publisher,
        "art_url": art_url,
        "duration_ms": duration_ms,
        "explicit": explicit,
    }

def parse_playback_state(data, player_data = None):
    """
    Parse full playback state from API responses.
    Combines currently playing and player state data.
    """
    if not data:
        return None

    # Determine content type
    content_type = data.get("currently_playing_type", "track")
    item = data.get("item")

    # Parse based on type
    if content_type == "episode":
        content = parse_episode(item)
    elif content_type == "ad":
        content = {
            "type": "ad",
            "name": "Advertisement",
            "artist": "Spotify",
            "album": "",
            "art_url": None,
            "duration_ms": 0,
            "explicit": False,
        }
    else:
        content = parse_track(item)

    if not content:
        return None

    # Add playback state
    content["is_playing"] = data.get("is_playing", False)
    content["progress_ms"] = data.get("progress_ms", 0)

    # Add player state if available
    if player_data:
        content["shuffle"] = player_data.get("shuffle_state", False)
        content["repeat"] = player_data.get("repeat_state", "off")

        device = player_data.get("device", {})
        content["device_name"] = device.get("name", "")
        content["device_type"] = device.get("type", "")
        content["volume"] = device.get("volume_percent", 100)
    else:
        content["shuffle"] = False
        content["repeat"] = "off"
        content["device_name"] = ""
        content["device_type"] = ""
        content["volume"] = 100

    return content

def get_playback_info(access_token, include_recent):
    """
    Get current playback info, optionally falling back to recent.
    Returns (playback_dict, is_current, error_string)
    """

    # Try currently playing
    now_playing = fetch_currently_playing(access_token)

    if now_playing and now_playing.get("is_playing"):
        # Get additional player state for device/shuffle/repeat info
        player = fetch_player_state(access_token)
        state = parse_playback_state(now_playing, player)
        if state:
            return state, True, None

    # Not playing - try paused state
    if now_playing and now_playing.get("item"):
        player = fetch_player_state(access_token)
        state = parse_playback_state(now_playing, player)
        if state:
            state["is_playing"] = False
            return state, True, None

    # Nothing in player - try recently played
    if include_recent:
        recent = fetch_recently_played(access_token)
        if recent:
            track = recent.get("track")
            if track:
                content = parse_track(track)
                if content:
                    content["is_playing"] = False
                    content["progress_ms"] = 0
                    content["shuffle"] = False
                    content["repeat"] = "off"
                    content["device_name"] = ""
                    content["device_type"] = ""
                    content["volume"] = 0
                    return content, False, None

    return None, False, None

# =============================================================================
# RENDERING - COMPONENTS
# =============================================================================

def render_progress_bar(progress_ms, duration_ms, width, color, bg_color):
    """Render a progress bar."""
    if duration_ms <= 0:
        progress_pct = 0
    else:
        progress_pct = clamp(progress_ms / duration_ms, 0, 1)

    filled_width = int(progress_pct * width)
    if filled_width < 1 and progress_pct > 0:
        filled_width = 1

    bar_height = s(2)

    return render.Stack(
        children = [
            # Background
            render.Box(
                width = width,
                height = bar_height,
                color = bg_color,
            ),
            # Filled portion
            render.Box(
                width = filled_width,
                height = bar_height,
                color = color,
            ),
        ],
    )

def render_time_display(progress_ms, duration_ms, color):
    """Render time as 'elapsed / total' or just remaining."""
    elapsed = format_duration(progress_ms)
    total = format_duration(duration_ms)

    return render.Text(
        content = elapsed + "/" + total,
        font = font_time(),
        color = color,
    )

def render_playback_icon(is_playing, color):
    """Render play/pause indicator."""
    if is_playing:
        # Play triangle (approximated with text)
        return render.Text(content = "▶", font = font_small(), color = color)
    else:
        # Pause bars
        return render.Text(content = "❚❚", font = font_small(), color = color)

def render_status_icons(state, color):
    """Render shuffle/repeat status icons."""
    icons = []

    if state.get("shuffle"):
        icons.append(render.Text(content = "⤮", font = font_small(), color = color))

    repeat = state.get("repeat", "off")
    if repeat == "track":
        icons.append(render.Text(content = "↺1", font = font_small(), color = color))
    elif repeat == "context":
        icons.append(render.Text(content = "↺", font = font_small(), color = color))

    if not icons:
        return None

    return render.Row(
        children = icons,
        main_align = "end",
    )

def render_text_smart(text, width, font, color):
    """
    Render text, using marquee only if needed.
    This reduces visual noise for short text.
    """
    if needs_scroll(text, width, font):
        return render.Marquee(
            width = width,
            child = render.Text(content = text, font = font, color = color),
            offset_start = width,
            offset_end = width,
        )
    else:
        return render.Text(content = text, font = font, color = color)

def render_album_art(art_url, size, fallback_color):
    """
    Render album art with fallback.
    Returns a widget of the specified size.
    """
    if art_url:
        art_data = fetch_album_art(art_url)
        if art_data:
            return render.Image(
                src = art_data,
                width = size,
                height = size,
            )

    # Fallback: colored box with music note
    return render.Stack(
        children = [
            render.Box(width = size, height = size, color = fallback_color),
            render.Box(
                width = size,
                height = size,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text(content = "♪", font = font_large(), color = WHITE),
                    ],
                ),
            ),
        ],
    )

# =============================================================================
# RENDERING - LAYOUTS
# =============================================================================

def render_full_mode(state, config):
    """
    Full mode: Album art + track/artist + progress bar with time.
    Most information-dense layout.
    """
    art_size = canvas.height()
    text_width = canvas.width() - art_size - s(1)
    scroll_speed = scale_delay(int(config.get("scroll_speed", "50")))

    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)
    progress_color = config.get("progress_color", SPOTIFY_GREEN)
    show_time = config.bool("show_time", True)

    # Album art
    art = render_album_art(state["art_url"], art_size, DARK_GRAY)

    # Build text section
    text_children = []

    # Track name
    text_children.append(
        render_text_smart(state["name"], text_width, font_track(), track_color),
    )

    # Artist
    text_children.append(
        render_text_smart(state["artist"], text_width, font_artist(), artist_color),
    )

    # Progress bar row
    progress_row_children = []

    # Play/pause icon
    progress_row_children.append(
        render_playback_icon(state["is_playing"], LIGHT_GRAY),
    )

    # Progress bar
    bar_width = text_width - s(12) if show_time else text_width - s(6)
    progress_row_children.append(
        render.Padding(
            pad = (s(1), 0, s(1), 0),
            child = render_progress_bar(
                state["progress_ms"],
                state["duration_ms"],
                bar_width,
                progress_color,
                PROGRESS_BG,
            ),
        ),
    )

    text_children.append(
        render.Row(
            children = progress_row_children,
            cross_align = "center",
        ),
    )

    # Time display (below progress or inline)
    if show_time:
        remaining = state["duration_ms"] - state["progress_ms"]
        time_str = "-" + format_duration(remaining)
        text_children.append(
            render.Row(
                expanded = True,
                main_align = "end",
                children = [
                    render.Text(content = time_str, font = font_time(), color = DARK_GRAY),
                ],
            ),
        )

    text_column = render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "start",
        children = text_children,
    )

    return render.Root(
        delay = scroll_speed,
        child = render.Row(
            expanded = True,
            children = [
                art,
                render.Padding(
                    pad = (s(1), 0, 0, 0),
                    child = text_column,
                ),
            ],
        ),
    )

def render_compact_mode(state, config):
    """
    Compact mode: Album art + track/artist, no progress bar.
    Clean and simple.
    """
    art_size = s(30)
    art_pad = s(1)
    text_width = canvas.width() - art_size - art_pad * 2
    scroll_speed = scale_delay(int(config.get("scroll_speed", "50")))

    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)

    # Art with small padding
    art = render.Padding(
        pad = (art_pad, art_pad, art_pad, art_pad),
        child = render_album_art(state["art_url"], art_size, DARK_GRAY),
    )

    # Playback indicator
    indicator = ""
    if not state["is_playing"]:
        indicator = "❚❚ "

    text_column = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "start",
        children = [
            render_text_smart(state["name"], text_width, font_track(), track_color),
            render.Box(height = s(1)),
            render_text_smart(indicator + state["artist"], text_width, font_artist(), artist_color),
        ],
    )

    return render.Root(
        delay = scroll_speed,
        child = render.Row(
            expanded = True,
            cross_align = "center",
            children = [art, text_column],
        ),
    )

def render_art_focus_mode(state, config):
    """
    Art focus mode: Large album art with text overlay at bottom.
    Visually striking.
    """
    scroll_speed = scale_delay(int(config.get("scroll_speed", "50")))
    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)

    # Full-size art as background
    art = render_album_art(state["art_url"], canvas.height(), DARK_GRAY)

    # Text overlay at bottom
    overlay_text = state["name"]
    if not state["is_playing"]:
        overlay_text = "❚❚ " + overlay_text

    overlay_pad = s(1)
    overlay_height = s(10)
    overlay_text_width = canvas.width() - overlay_pad * 2

    # At 2x, show both track and artist in the overlay
    overlay_children = [
        render.Marquee(
            width = overlay_text_width,
            child = render.Text(
                content = overlay_text,
                font = font_artist(),
                color = track_color,
            ),
        ),
    ]
    if canvas.is2x():
        overlay_children.append(
            render.Marquee(
                width = overlay_text_width,
                child = render.Text(
                    content = state["artist"],
                    font = font_small(),
                    color = artist_color,
                ),
            ),
        )

    text_overlay = render.Column(
        expanded = True,
        main_align = "end",
        children = [
            render.Box(
                width = canvas.width(),
                height = overlay_height,
                color = "#00000099",  # Semi-transparent black
                child = render.Padding(
                    pad = (overlay_pad, overlay_pad, overlay_pad, overlay_pad),
                    child = render.Column(
                        children = overlay_children,
                    ),
                ),
            ),
        ],
    )

    return render.Root(
        delay = scroll_speed,
        child = render.Stack(
            children = [
                render.Row(
                    expanded = True,
                    main_align = "center",
                    children = [art],
                ),
                text_overlay,
            ],
        ),
    )

def render_text_only_mode(state, config):
    """
    Text only mode: No art, full width for text.
    Maximum readability.
    """
    scroll_speed = scale_delay(int(config.get("scroll_speed", "50")))
    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)
    progress_color = config.get("progress_color", SPOTIFY_GREEN)

    margin = s(2)
    text_width = canvas.width() - margin * 2

    children = []

    # Track with play/pause
    icon_space = s(8)
    track_row = render.Row(
        children = [
            render_playback_icon(state["is_playing"], LIGHT_GRAY),
            render.Box(width = s(2)),
            render_text_smart(state["name"], text_width - icon_space, font_track(), track_color),
        ],
        cross_align = "center",
    )
    children.append(track_row)

    # Artist
    children.append(
        render_text_smart(state["artist"], text_width, font_artist(), artist_color),
    )

    # Progress bar spanning full width
    children.append(render.Box(height = s(2)))
    children.append(
        render_progress_bar(
            state["progress_ms"],
            state["duration_ms"],
            text_width,
            progress_color,
            PROGRESS_BG,
        ),
    )

    # Time
    elapsed = format_duration(state["progress_ms"])
    total = format_duration(state["duration_ms"])
    children.append(
        render.Row(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text(content = elapsed, font = font_time(), color = DARK_GRAY),
                render.Text(content = total, font = font_time(), color = DARK_GRAY),
            ],
        ),
    )

    return render.Root(
        delay = scroll_speed,
        child = render.Padding(
            pad = (margin, margin, margin, margin),
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                children = children,
            ),
        ),
    )

def render_minimal_mode(state, config):
    """
    Minimal mode: Just the essentials.
    Track name only, centered.
    """
    scroll_speed = scale_delay(int(config.get("scroll_speed", "50")))
    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)

    marquee_width = canvas.width() - s(4)

    # Icon + track centered
    track_text = state["name"]
    if not state["is_playing"]:
        track_text = "❚❚ " + track_text

    return render.Root(
        delay = scroll_speed,
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = marquee_width,
                    align = "center",
                    child = render.Text(
                        content = track_text,
                        font = font_track(),
                        color = track_color,
                    ),
                ),
                render.Box(height = s(2)),
                render.Marquee(
                    width = marquee_width,
                    align = "center",
                    child = render.Text(
                        content = state["artist"],
                        font = font_artist(),
                        color = artist_color,
                    ),
                ),
            ],
        ),
    )

def render_playback(state, config):
    """Route to appropriate display mode."""
    mode = config.get("display_mode", MODE_FULL)

    if mode == MODE_COMPACT:
        return render_compact_mode(state, config)
    elif mode == MODE_ART_FOCUS:
        return render_art_focus_mode(state, config)
    elif mode == MODE_TEXT_ONLY:
        return render_text_only_mode(state, config)
    elif mode == MODE_MINIMAL:
        return render_minimal_mode(state, config)
    else:
        return render_full_mode(state, config)

def render_idle(config, recent_state = None):
    """
    Render idle state when nothing is playing.
    Can show recently played if available and configured.
    """
    show_when_idle = config.bool("show_when_idle", True)
    idle_message = config.get("idle_message", "Spotify")

    if not show_when_idle:
        # Mark app as "inactive" by returning an empty list
        return []

    # Show recent track if available
    if recent_state:
        # Render with dimmed colors to indicate not current
        dimmed_config = {
            "scroll_speed": config.get("scroll_speed", "50"),
            "track_color": LIGHT_GRAY,
            "artist_color": DARK_GRAY,
        }

        # Add "Last played" indicator somehow
        # For now, just render in compact mode with dimmed colors
        return render_compact_mode(recent_state, dimmed_config)

    # Default idle screen
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = idle_message,
                    font = font_large(),
                    color = SPOTIFY_GREEN,
                ),
                render.Box(height = s(4)),
                render.Text(
                    content = "Not Playing",
                    font = font_artist(),
                    color = DARK_GRAY,
                ),
            ],
        ),
    )

def render_error(title, message, hint = None):
    """
    Render error state with helpful information.
    """
    text_width = canvas.width() - s(4)
    children = [
        render.Text(
            content = title,
            font = font_track(),
            color = ERROR_RED,
        ),
        render.Box(height = s(2)),
        render.WrappedText(
            content = message,
            font = font_artist(),
            color = LIGHT_GRAY,
            width = text_width,
            align = "center",
        ),
    ]

    if hint:
        children.append(render.Box(height = s(2)))
        children.append(
            render.WrappedText(
                content = hint,
                font = font_small(),
                color = DARK_GRAY,
                width = text_width,
                align = "center",
            ),
        )

    return render.Root(
        child = render.Padding(
            pad = (s(2), s(4), s(2), s(4)),
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def render_setup_needed():
    """Render first-run / configuration needed screen."""
    text_width = canvas.width() - s(4)
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "Spotify",
                    font = font_large(),
                    color = SPOTIFY_GREEN,
                ),
                render.Box(height = s(4)),
                render.WrappedText(
                    content = "Setup needed",
                    font = font_artist(),
                    color = WHITE,
                    width = text_width,
                    align = "center",
                ),
                render.Box(height = s(2)),
                render.WrappedText(
                    content = "Add credentials in app config",
                    font = font_small(),
                    color = DARK_GRAY,
                    width = text_width,
                    align = "center",
                ),
            ],
        ),
    )

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

def main(config):
    """Main app entry point."""

    # Get credentials
    client_id = config.get("client_id", "").strip()
    client_secret = config.get("client_secret", "").strip()
    refresh_token = config.get("refresh_token", "").strip()

    # Check configuration
    if not client_id or not client_secret or not refresh_token:
        return render_setup_needed()

    # Get access token
    access_token, auth_error = get_access_token(client_id, client_secret, refresh_token)

    if auth_error:
        if "revoked" in auth_error or "reauthorize" in auth_error:
            return render_error("Auth Error", "Token revoked", "Run setup again")
        elif "credentials" in auth_error:
            return render_error("Auth Error", "Bad credentials", "Check ID/Secret")
        elif "Rate limited" in auth_error:
            return render_error("Rate Limited", "Too many requests", "Wait a moment")
        else:
            return render_error("Auth Error", auth_error)

    if not access_token:
        return render_error("Auth Error", "No token", "Check config")

    # Get playback info
    include_recent = config.bool("show_recently_played", False)
    state, is_current, fetch_error = get_playback_info(access_token, include_recent)

    if fetch_error:
        return render_error("API Error", fetch_error)

    if state:
        show_paused = config.bool("show_paused_tracks", True)
        should_display = state["is_playing"] or (is_current and show_paused)

        if should_display:
            # Currently playing or paused (if enabled)
            return render_playback(state, config)
        else:
            # Showing recently played or paused track (when disabled)
            return render_idle(config, recent_state = state)
    else:
        # Nothing to show
        return render_idle(config)

# =============================================================================
# CONFIGURATION SCHEMA
# =============================================================================

def get_schema():
    """Configuration schema for Tronbyt UI."""
    return schema.Schema(
        version = "1",
        fields = [
            # Credentials
            schema.Text(
                id = "client_id",
                name = "Spotify Client ID",
                desc = "From your Spotify Developer app. See https://github.com/tronbyt/apps/blob/main/apps/spotify/README.md for setup instructions.",
                icon = "key",
            ),
            schema.Text(
                id = "client_secret",
                name = "Spotify Client Secret",
                desc = "From your Spotify Developer app. See https://github.com/tronbyt/apps/blob/main/apps/spotify/README.md for setup instructions.",
                icon = "lock",
            ),
            schema.Text(
                id = "refresh_token",
                name = "Refresh Token",
                desc = "Required before use. See https://github.com/tronbyt/apps/blob/main/apps/spotify/README.md for setup instructions to generate this token.",
                icon = "rotate",
            ),

            # Display options
            schema.Dropdown(
                id = "display_mode",
                name = "Display Mode",
                desc = "Layout style for now playing display",
                icon = "display",
                default = MODE_FULL,
                options = [
                    schema.Option(display = "Full (art + text + progress)", value = MODE_FULL),
                    schema.Option(display = "Compact (art + text)", value = MODE_COMPACT),
                    schema.Option(display = "Art Focus (large art + overlay)", value = MODE_ART_FOCUS),
                    schema.Option(display = "Text Only (no art)", value = MODE_TEXT_ONLY),
                    schema.Option(display = "Minimal (centered text)", value = MODE_MINIMAL),
                ],
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll Speed",
                desc = "Speed of text scrolling animation",
                icon = "gaugeHigh",
                default = "50",
                options = [
                    schema.Option(display = "Slow", value = "80"),
                    schema.Option(display = "Normal", value = "50"),
                    schema.Option(display = "Fast", value = "30"),
                ],
            ),
            schema.Toggle(
                id = "show_time",
                name = "Show Time Remaining",
                desc = "Display remaining time on track (full mode only)",
                icon = "clock",
                default = True,
            ),
            schema.Toggle(
                id = "show_recently_played",
                name = "Show Recently Played",
                desc = "When nothing playing, show last played track",
                icon = "clockRotateLeft",
                default = False,
            ),
            schema.Toggle(
                id = "show_paused_tracks",
                name = "Show Paused Tracks",
                desc = "Display tracks when paused (if disabled, only shows actively playing tracks)",
                icon = "pause",
                default = True,
            ),
            schema.Toggle(
                id = "show_when_idle",
                name = "Show When Idle",
                desc = "Display Spotify branding when nothing playing",
                icon = "eye",
                default = True,
            ),
            schema.Text(
                id = "idle_message",
                name = "Idle Message",
                desc = "Text shown when nothing is playing",
                icon = "comment",
                default = "Spotify",
            ),

            # Colors
            schema.Color(
                id = "track_color",
                name = "Track Name Color",
                desc = "Color for the song/episode title",
                icon = "palette",
                default = WHITE,
            ),
            schema.Color(
                id = "artist_color",
                name = "Artist/Show Color",
                desc = "Color for artist or podcast name",
                icon = "palette",
                default = SPOTIFY_GREEN,
            ),
            schema.Color(
                id = "progress_color",
                name = "Progress Bar Color",
                desc = "Color for the progress bar fill",
                icon = "palette",
                default = SPOTIFY_GREEN,
            ),
        ],
    )
