"""
Spotify Now Playing - Ultimate Edition for Tronbyt/Tidbyt
=========================================================

Author: gshepperd
Version: 2.0.0

================================================================================
                            INSTALLATION INSTRUCTIONS
================================================================================

STEP 1: CREATE A SPOTIFY DEVELOPER APP
--------------------------------------
1. Go to: https://developer.spotify.com/dashboard
2. Log in with your Spotify account
3. Click "Create App"
4. Fill in the form:
   - App name: "Tronbyt Now Playing" (or whatever you like)
   - App description: "Display currently playing on Tronbyt"
   - Website: (leave blank or enter any URL)
   - Redirect URI: http://127.0.0.1:8888/callback   <-- IMPORTANT!
     (Click "Add" after entering the URI)
   - Which API/SDKs are you planning to use?
     [x] Web API   <-- CHECK THIS ONE
     [ ] Web Playback SDK (not needed)
     [ ] Android (not needed)
     [ ] iOS (not needed)
5. Check the Terms of Service box and click "Save"
6. Click "Settings" on your new app
7. Copy your "Client ID" and "Client Secret" (click "View client secret")

STEP 2: GET YOUR REFRESH TOKEN
------------------------------
Run the included Python script on the SAME MACHINE as your web browser:

    python3 get_refresh_token.py

The script will:
1. Ask for your Client ID and Client Secret
2. Open your browser to authorize with Spotify
3. Display your refresh token when complete

Save all three values:
- Client ID
- Client Secret  
- Refresh Token

ALTERNATIVE: MANUAL METHOD (if script doesn't work)
---------------------------------------------------
If you can't run the Python script on the same machine as your browser
(e.g., you're SSH'd into a remote server), use this manual method:

1. Open this URL in your browser (replace YOUR_CLIENT_ID):

   https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://127.0.0.1:8888/callback&scope=user-read-currently-playing%20user-read-playback-state%20user-read-recently-played&show_dialog=true

2. After authorizing, the page won't load (that's expected). Copy the 
   "code=" value from the URL bar. It will look like:
   
   http://127.0.0.1:8888/callback?code=AQCxxxVERYLONGSTRINGxxx

3. Run this curl command (replace YOUR_CLIENT_ID, YOUR_CLIENT_SECRET, 
   and YOUR_CODE_HERE):

   curl -X POST "https://accounts.spotify.com/api/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "grant_type=authorization_code" \
     -d "code=YOUR_CODE_HERE" \
     -d "redirect_uri=http://127.0.0.1:8888/callback" \
     -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET"

4. Copy the "refresh_token" value from the JSON response.

NOTE: The code expires in ~10 minutes, so run curl quickly after step 2.

STEP 3: CONFIGURE IN TRONBYT
----------------------------
1. Open your Tronbyt web interface (usually http://your-server:8000)
2. Add this app (upload spotify.star or add as custom app)
3. Configure these fields:
   - Spotify Client ID:     [paste your Client ID]
   - Spotify Client Secret: [paste your Client Secret]
   - Refresh Token:         [paste your Refresh Token]
4. Optionally configure display mode, colors, etc.
5. Save and enjoy!

STEP 4: PLAY MUSIC
------------------
Start playing something on Spotify. Within 30-60 seconds (depending on
your Tronbyt refresh rate), you'll see it on your display!

================================================================================
                                 TROUBLESHOOTING
================================================================================

"Setup needed" error:
  -> Your credentials aren't configured. Add them in app settings.

"Auth Error: Token revoked" error:
  -> Run get_refresh_token.py again to get a new token.
  -> This happens if you revoked access or deleted your Spotify app.

"Auth Error: Bad credentials" error:
  -> Double-check your Client ID and Client Secret.

Nothing displays / black screen:
  -> Check that a track is active (playing or paused) on one of your devices.
  -> Some private sessions don't report to the API.
  -> Check that "Show When Idle" is enabled in settings.

Album art not showing:
  -> Local files don't have artwork.
  -> Try a different display mode.

================================================================================
                                    FEATURES
================================================================================

Display Modes:
- Full:      Album art + track + artist + progress bar + time remaining
- Compact:   Album art + track + artist (no progress bar)
- Art Focus: Large album art with text overlay at bottom
- Text Only: No art, full width for text + progress bar
- Minimal:   Just track and artist, centered

Content Support:
- Music tracks with full metadata
- Podcast episodes (show name, episode title)
- Paused playback detection
- Recently played fallback (optional)
- Graceful handling of Spotify ads

Robustness:
- Exponential backoff on rate limits
- Pre-emptive token refresh (at 45 min, expires at 60)
- Multi-layer caching (tokens 45min, album art 24hr)
- Graceful degradation (shows text if art fails)
- Actionable error messages

================================================================================
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
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

# Display Dimensions
DISPLAY_WIDTH = 64
DISPLAY_HEIGHT = 32

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

# Fonts
FONT_TRACK = "tb-8"  # Track name
FONT_ARTIST = "tom-thumb"  # Artist name (smaller)
FONT_TIME = "tom-thumb"  # Time display
FONT_LARGE = "6x13"  # Large text for idle/errors
FONT_SMALL = "CG-pixel-3x5-mono"  # Tiny text

# Device type icons (simple representations)
DEVICE_ICONS = {
    "Computer": "💻",
    "Smartphone": "📱",
    "Speaker": "🔊",
    "TV": "📺",
    "default": "🎵",
}

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

    # Get best album art URL (prefer smaller sizes)
    images = album.get("images", [])
    art_url = None
    for img in reversed(images):  # Smallest last
        if img.get("url"):
            art_url = img["url"]
            break

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
    art_url = None
    for img in reversed(images):
        if img.get("url"):
            art_url = img["url"]
            break

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

    return render.Stack(
        children = [
            # Background
            render.Box(
                width = width,
                height = 2,
                color = bg_color,
            ),
            # Filled portion
            render.Box(
                width = filled_width,
                height = 2,
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
        font = FONT_TIME,
        color = color,
    )

def render_playback_icon(is_playing, color):
    """Render play/pause indicator."""
    if is_playing:
        # Play triangle (approximated with text)
        return render.Text(content = "▶", font = FONT_SMALL, color = color)
    else:
        # Pause bars
        return render.Text(content = "❚❚", font = FONT_SMALL, color = color)

def render_status_icons(state, color):
    """Render shuffle/repeat status icons."""
    icons = []

    if state.get("shuffle"):
        icons.append(render.Text(content = "⤮", font = FONT_SMALL, color = color))

    repeat = state.get("repeat", "off")
    if repeat == "track":
        icons.append(render.Text(content = "↺1", font = FONT_SMALL, color = color))
    elif repeat == "context":
        icons.append(render.Text(content = "↺", font = FONT_SMALL, color = color))

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
                        render.Text(content = "♪", font = FONT_LARGE, color = WHITE),
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
    Full mode: Album art (32x32) + track/artist + progress bar with time.
    Most information-dense layout.
    """
    art_size = 32
    text_width = DISPLAY_WIDTH - art_size - 1
    scroll_speed = int(config.get("scroll_speed", "50"))

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
        render_text_smart(state["name"], text_width, FONT_TRACK, track_color),
    )

    # Artist
    text_children.append(
        render_text_smart(state["artist"], text_width, FONT_ARTIST, artist_color),
    )

    # Progress bar row
    progress_row_children = []

    # Play/pause icon
    progress_row_children.append(
        render_playback_icon(state["is_playing"], LIGHT_GRAY),
    )

    # Progress bar
    bar_width = text_width - 12 if show_time else text_width - 6
    progress_row_children.append(
        render.Padding(
            pad = (1, 0, 1, 0),
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
                    render.Text(content = time_str, font = FONT_TIME, color = DARK_GRAY),
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
                    pad = (1, 0, 0, 0),
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
    art_size = 30
    text_width = DISPLAY_WIDTH - art_size - 2
    scroll_speed = int(config.get("scroll_speed", "50"))

    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)

    # Art with small padding
    art = render.Padding(
        pad = (1, 1, 1, 1),
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
            render_text_smart(state["name"], text_width, FONT_TRACK, track_color),
            render.Box(height = 1),
            render_text_smart(indicator + state["artist"], text_width, FONT_ARTIST, artist_color),
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
    scroll_speed = int(config.get("scroll_speed", "50"))
    track_color = config.get("track_color", WHITE)

    # Full-size art as background
    art = render_album_art(state["art_url"], DISPLAY_HEIGHT, DARK_GRAY)

    # Text overlay at bottom
    overlay_text = state["name"]
    if not state["is_playing"]:
        overlay_text = "❚❚ " + overlay_text

    text_overlay = render.Column(
        expanded = True,
        main_align = "end",
        children = [
            render.Box(
                width = DISPLAY_WIDTH,
                height = 10,
                color = "#00000099",  # Semi-transparent black
                child = render.Padding(
                    pad = (1, 1, 1, 1),
                    child = render.Marquee(
                        width = DISPLAY_WIDTH - 2,
                        child = render.Text(
                            content = overlay_text,
                            font = FONT_ARTIST,
                            color = track_color,
                        ),
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
    scroll_speed = int(config.get("scroll_speed", "50"))
    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)
    progress_color = config.get("progress_color", SPOTIFY_GREEN)

    text_width = DISPLAY_WIDTH - 4  # Small margins

    children = []

    # Track with play/pause
    track_row = render.Row(
        children = [
            render_playback_icon(state["is_playing"], LIGHT_GRAY),
            render.Box(width = 2),
            render_text_smart(state["name"], text_width - 8, FONT_TRACK, track_color),
        ],
        cross_align = "center",
    )
    children.append(track_row)

    # Artist
    children.append(
        render_text_smart(state["artist"], text_width, FONT_ARTIST, artist_color),
    )

    # Progress bar spanning full width
    children.append(render.Box(height = 2))
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
                render.Text(content = elapsed, font = FONT_TIME, color = DARK_GRAY),
                render.Text(content = total, font = FONT_TIME, color = DARK_GRAY),
            ],
        ),
    )

    return render.Root(
        delay = scroll_speed,
        child = render.Padding(
            pad = (2, 2, 2, 2),
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
    scroll_speed = int(config.get("scroll_speed", "50"))
    track_color = config.get("track_color", WHITE)
    artist_color = config.get("artist_color", SPOTIFY_GREEN)

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
                    width = DISPLAY_WIDTH - 4,
                    align = "center",
                    child = render.Text(
                        content = track_text,
                        font = FONT_TRACK,
                        color = track_color,
                    ),
                ),
                render.Box(height = 2),
                render.Marquee(
                    width = DISPLAY_WIDTH - 4,
                    align = "center",
                    child = render.Text(
                        content = state["artist"],
                        font = FONT_ARTIST,
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
        # Return blank/black screen
        return render.Root(
            child = render.Box(
                width = DISPLAY_WIDTH,
                height = DISPLAY_HEIGHT,
                color = "#000000",
            ),
        )

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
                    font = FONT_LARGE,
                    color = SPOTIFY_GREEN,
                ),
                render.Box(height = 4),
                render.Text(
                    content = "Not Playing",
                    font = FONT_ARTIST,
                    color = DARK_GRAY,
                ),
            ],
        ),
    )

def render_error(title, message, hint = None):
    """
    Render error state with helpful information.
    """
    children = [
        render.Text(
            content = title,
            font = FONT_TRACK,
            color = ERROR_RED,
        ),
        render.Box(height = 2),
        render.WrappedText(
            content = message,
            font = FONT_ARTIST,
            color = LIGHT_GRAY,
            width = DISPLAY_WIDTH - 4,
            align = "center",
        ),
    ]

    if hint:
        children.append(render.Box(height = 2))
        children.append(
            render.WrappedText(
                content = hint,
                font = FONT_SMALL,
                color = DARK_GRAY,
                width = DISPLAY_WIDTH - 4,
                align = "center",
            ),
        )

    return render.Root(
        child = render.Padding(
            pad = (2, 4, 2, 4),
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
    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "Spotify",
                    font = FONT_LARGE,
                    color = SPOTIFY_GREEN,
                ),
                render.Box(height = 4),
                render.WrappedText(
                    content = "Setup needed",
                    font = FONT_ARTIST,
                    color = WHITE,
                    width = DISPLAY_WIDTH - 4,
                    align = "center",
                ),
                render.Box(height = 2),
                render.WrappedText(
                    content = "Add credentials in app config",
                    font = FONT_SMALL,
                    color = DARK_GRAY,
                    width = DISPLAY_WIDTH - 4,
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
        if is_current or state["is_playing"]:
            # Currently playing or paused
            return render_playback(state, config)
        else:
            # Showing recently played
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
