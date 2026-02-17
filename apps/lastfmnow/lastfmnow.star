"""
Applet: Last.fm Now
Summary: Now scrobbling on Last.fm
Description: Turn your Tidbyt into a little "what's playing" sign. This app connects to Last.fm and displays the track you're listening to right now (based on your scrobbles), updating automatically as your music changes.
Author: kaffolder7
"""

load("cache.star", "cache")
load("http.star", "http")
load("images/lastfm_icon.png", LAST_FM_ICON_1X = "file")
load("images/lastfm_icon@2x.png", LAST_FM_ICON_2X = "file")
load("images/lastfm_logo.png", LAST_FM_LOGO_1X = "file")
load("images/lastfm_logo@2x.png", LAST_FM_LOGO_2X = "file")
load("images/music_icon.png", MUSIC_ICON_1X = "file")
load("images/music_icon@2x.png", MUSIC_ICON_2X = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

LAST_FM_URL = "https://ws.audioscrobbler.com/2.0/"
LAST_FM_DEFAULT_IMAGE_TOKEN = "2a96cbd8b46e442fc41c2b86b821562f"

MUSIC_ICON = MUSIC_ICON_2X if canvas.is2x() else MUSIC_ICON_1X
LAST_FM_LOGO = LAST_FM_LOGO_2X if canvas.is2x() else LAST_FM_LOGO_1X
LAST_FM_ICON = LAST_FM_ICON_2X if canvas.is2x() else LAST_FM_ICON_1X

SCALE = 2 if canvas.is2x() else 1

# ROOT_FRAME_DELAY = 35 if canvas.is2x() else 70
ROOT_FRAME_DELAY = 25 if canvas.is2x() else 60
MARQUEE_START_DELAY = 12

# Adaptive cache TTLs:
# - Faster refresh while actively now-playing.
# - Slower refresh when idle or in temporary API error.
TTL_NOW_PLAYING = 15
TTL_NOT_PLAYING = 45
TTL_API_ERROR = 45
TTL_LAST_SUCCESS = 24 * 60 * 60

def _as_text(value):
    if value == None:
        return ""
    return str(value)

def _s(value):
    return value * SCALE

def _spad(pad):
    if type(pad) == "int":
        return _s(pad)
    if type(pad) == "tuple":
        if len(pad) == 2:
            return (_s(pad[0]), _s(pad[1]))
        if len(pad) == 4:
            return (_s(pad[0]), _s(pad[1]), _s(pad[2]), _s(pad[3]))
    return pad

def _root(child):
    return render.Root(
        delay = ROOT_FRAME_DELAY,
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            child = child,
        ),
    )

def _api_key_tag(api_key):
    key = _as_text(api_key)
    if key == "":
        return "nokey"
    if len(key) <= 4:
        return "len%d-%s" % (len(key), key)
    return "len%d-%s-%s" % (len(key), key[:2], key[len(key) - 2:])

def _scoped_cache_key(scope, name):
    return "%s-%s" % (name, scope)

def _compact_line(left, right):
    if left != "" and right != "":
        return "%s %s" % (left, right)
    if left != "":
        return left
    return right

def _is_default_last_fm_image(url):
    return url == "" or LAST_FM_DEFAULT_IMAGE_TOKEN in _as_text(url)

def _extract_cover_art_url(image_list):
    if image_list == None:
        return ""

    cover_art_url = ""
    for image in image_list:
        candidate = ""
        if type(image) == "dict":
            candidate = _as_text(image.get("#text"))
        else:
            candidate = _as_text(image)
        if candidate != "":
            # Last.fm images are ordered from small -> large. Keep last non-empty.
            cover_art_url = candidate

    if _is_default_last_fm_image(cover_art_url):
        return ""

    return cover_art_url

def _download_cover_art(cover_art_url):
    if _is_default_last_fm_image(cover_art_url):
        return ""

    response = http.get(cover_art_url)
    if response.status_code != 200:
        return ""
    return response.body()

def _track_state(state, name, artist, album, image):
    return {
        "state": state,
        "is_now_playing": state == "now_playing",
        "name": name,
        "artist": {"#text": artist},
        "album": {"#text": album},
        "image": image,
    }

def _read_now_state_cache(scope):
    return {
        "song_title": cache.get(_scoped_cache_key(scope, "name")),
        "artist_name": cache.get(_scoped_cache_key(scope, "artist")),
        "album_name": cache.get(_scoped_cache_key(scope, "album")),
        "cover_art_url": cache.get(_scoped_cache_key(scope, "cover-art-url")),
        "cover_art": cache.get(_scoped_cache_key(scope, "cover-art")),
        "is_now_playing": cache.get(_scoped_cache_key(scope, "is-now-playing")),
        "is_stale": cache.get(_scoped_cache_key(scope, "is-stale")),
    }

def _now_state_cache_hit(cached):
    return (
        cached.get("song_title") != None and
        cached.get("artist_name") != None and
        cached.get("album_name") != None and
        cached.get("cover_art_url") != None and
        cached.get("cover_art") != None and
        cached.get("is_now_playing") != None and
        cached.get("is_stale") != None
    )

def _write_now_state_cache(scope, song_title, artist_name, album_name, cover_art_url, cover_art, is_now_playing, is_stale, ttl_seconds):
    cache.set(_scoped_cache_key(scope, "name"), song_title, ttl_seconds = ttl_seconds)
    cache.set(_scoped_cache_key(scope, "artist"), artist_name, ttl_seconds = ttl_seconds)
    cache.set(_scoped_cache_key(scope, "album"), album_name, ttl_seconds = ttl_seconds)
    cache.set(_scoped_cache_key(scope, "cover-art-url"), cover_art_url, ttl_seconds = ttl_seconds)
    cache.set(_scoped_cache_key(scope, "cover-art"), cover_art, ttl_seconds = ttl_seconds)
    cache.set(_scoped_cache_key(scope, "is-now-playing"), "true" if is_now_playing else "false", ttl_seconds = ttl_seconds)
    cache.set(_scoped_cache_key(scope, "is-stale"), "true" if is_stale else "false", ttl_seconds = ttl_seconds)

def _read_last_success_cache(scope):
    return {
        "song_title": cache.get(_scoped_cache_key(scope, "last-success-name")),
        "artist_name": cache.get(_scoped_cache_key(scope, "last-success-artist")),
        "album_name": cache.get(_scoped_cache_key(scope, "last-success-album")),
        "cover_art_url": cache.get(_scoped_cache_key(scope, "last-success-cover-art-url")),
        "cover_art": cache.get(_scoped_cache_key(scope, "last-success-cover-art")),
    }

def _last_success_cache_hit(cached):
    return (
        cached.get("song_title") != None and
        cached.get("artist_name") != None and
        cached.get("album_name") != None and
        cached.get("cover_art_url") != None and
        cached.get("cover_art") != None
    )

def _write_last_success_cache(scope, song_title, artist_name, album_name, cover_art_url, cover_art):
    cache.set(_scoped_cache_key(scope, "last-success-name"), song_title, ttl_seconds = TTL_LAST_SUCCESS)
    cache.set(_scoped_cache_key(scope, "last-success-artist"), artist_name, ttl_seconds = TTL_LAST_SUCCESS)
    cache.set(_scoped_cache_key(scope, "last-success-album"), album_name, ttl_seconds = TTL_LAST_SUCCESS)
    cache.set(_scoped_cache_key(scope, "last-success-cover-art-url"), cover_art_url, ttl_seconds = TTL_LAST_SUCCESS)
    cache.set(_scoped_cache_key(scope, "last-success-cover-art"), cover_art, ttl_seconds = TTL_LAST_SUCCESS)

def _clock_wrapped_text(clock_text, width):
    return render.WrappedText(
        content = clock_text,
        font = "terminus-12" if canvas.is2x() else "tom-thumb",
        width = _s(width),
        color = "#777",
        align = "right",
    )

def _album_text(album, show_clock):
    if show_clock:
        return ""
    return album

def _cover_art_src(coverart, has_album_art):
    if has_album_art:
        return coverart
    return LAST_FM_ICON.readall()

def _render_layout_preset1(ctx):
    return render.Padding(
        pad = _spad(1),
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(
                            pad = _spad((0, 0, 2, 0)) if canvas.is2x() else _spad((0, 0, 0, 0)),
                            child = render.Image(src = MUSIC_ICON.readall(), width = 24 if canvas.is2x() else 16),
                        ),
                        render.Marquee(
                            width = _s(44) if not ctx["show_clock"] else 0,
                            child = render.Text(
                                content = ctx["username"] if not ctx["show_clock"] else "",
                                font = "tb-8" if canvas.is2x() else "tom-thumb",
                                color = "#c0c0c0",
                            ),
                        ),
                        render.Padding(
                            pad = _spad((2, 0, 0, 4)),
                            child = _clock_wrapped_text(ctx["clock_text"], 44) if canvas.is2x() else _clock_wrapped_text(ctx["clock_text"], 43),
                        ),
                    ],
                    main_align = "center",
                    cross_align = "center",
                ),
                render.Padding(
                    child = render.Marquee(
                        width = _s(64),
                        child = render.Text(
                            content = ctx["track"],
                            color = ctx["song_title_color"] or "#ffffff",
                            font = "terminus-18" if canvas.is2x() else "6x10",
                        ),
                    ),
                    pad = _spad((0, 2, 0, 0)) if canvas.is2x() else _spad((0, 0, 0, 0)),
                ),
                render.Marquee(
                    width = _s(64),
                    child = render.Text(
                        content = ctx["artist"],
                        color = ctx["artist_name_color"],
                        font = "6x13" if canvas.is2x() else "tom-thumb",
                    ),
                ),
            ],
        ),
    )

def _render_layout_preset2(ctx):
    return render.Stack(
        children = [
            render.Padding(
                pad = _spad((31, 2, 0, 0)),
                child = render.WrappedText(
                    content = ctx["clock_text"],
                    font = "tb-8" if canvas.is2x() else "tom-thumb",
                    width = _s(32),
                    color = "#777",
                    align = "right",
                ),
            ),
            render.Padding(
                pad = _spad((0, 0, 0, 0)) if ctx["has_album_art"] else _spad(2),
                child = render.Image(ctx["coverart_img"], width = _s(32)),
            ),
            render.Box(
                color = "#00FF0000",
                child = render.Padding(
                    pad = _spad((0, 0, 1, 1)) if ctx["has_album_art"] else _spad((0, 0, 0, 1)),
                    color = "#FF000000",
                    child = render.Column(
                        cross_align = "end",
                        main_align = "start",
                        expanded = False,
                        children = [
                            render.Box(
                                color = "#0000FF00",
                                height = _s(10),
                            ),
                            render.Padding(
                                pad = _spad((1, 1, 0, 0)),
                                color = "#111111A1",
                                child = render.Marquee(
                                    child = render.Text(
                                        content = ctx["track_upper"],
                                        font = "terminus-14" if canvas.is2x() else "tb-8",
                                        color = ctx["song_title_color"] or "#ffffff",
                                    ),
                                    width = _s(58) if ctx["has_album_art"] else _s(62),
                                    scroll_direction = "horizontal",
                                    align = "end",
                                    delay = MARQUEE_START_DELAY,
                                ),
                            ),
                            render.Padding(
                                pad = _spad((1, 1, 0, 0)),
                                color = "#111111A1",
                                child = render.Marquee(
                                    child = render.Text(
                                        content = ctx["artist"],
                                        font = "terminus-12" if canvas.is2x() else "tom-thumb",
                                        color = ctx["artist_name_color"],
                                    ),
                                    width = _s(52) if ctx["has_album_art"] else _s(62),
                                    scroll_direction = "horizontal",
                                    align = "end",
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        ],
    )

def _render_layout_preset3(ctx):
    return render.Stack(
        children = [
            render.Padding(
                pad = _spad((2, 12, 0, 0)),
                child = render.Image(ctx["coverart_img"], width = _s(18), height = _s(18)),
            ),
            render.Padding(
                pad = _spad((2, 2, 2, 1)),
                child = render.Marquee(
                    child = render.Text(
                        content = ctx["track_upper"],
                        font = "terminus-20" if canvas.is2x() else "6x10",
                        color = ctx["song_title_color"] or "#B90000",
                    ),
                    width = _s(60),
                    offset_start = _s(2),
                    scroll_direction = "horizontal",
                    align = "start",
                    delay = MARQUEE_START_DELAY,
                ),
            ),
            render.Padding(
                pad = _spad((22, 12, 0, 0)),
                child = render.Marquee(
                    child = render.Text(
                        content = ctx["artist_upper"],
                        font = "terminus-12" if canvas.is2x() else "tb-8",
                        color = ctx["artist_name_color"],
                    ),
                    width = _s(40),
                    scroll_direction = "horizontal",
                    align = "start",
                ),
            ),
            render.Padding(
                pad = _spad((22, 24, 0, 0)),
                child = render.Marquee(
                    child = render.Text(
                        content = ctx["album_text"],
                        font = "tb-8" if canvas.is2x() else "tom-thumb",
                        color = ctx["album_name_color"],
                    ),
                    width = _s(40),
                    scroll_direction = "horizontal",
                    align = "start",
                ),
            ),
            render.Padding(
                pad = _spad((42, 25, 0, 0)),
                child = _clock_wrapped_text(ctx["clock_text"], 20),
            ),
        ],
    )

def _render_layout_preset4(ctx):
    return render.Stack(
        children = [
            render.Padding(
                pad = _spad((2, 1, 2, 1)) if canvas.is2x() else _spad((2, 0, 2, 1)),
                child = render.Marquee(
                    child = render.Text(
                        content = ctx["track"],
                        font = "terminus-22" if canvas.is2x() else "6x13",
                        color = ctx["song_title_color"] or "#B90000",
                    ),
                    width = _s(60),
                    offset_start = _s(2),
                    scroll_direction = "horizontal",
                    align = "start",
                    delay = MARQUEE_START_DELAY,
                ),
            ),
            render.Padding(
                pad = _spad((2, 14, 0, 0)),
                child = render.Image(ctx["coverart_img"], width = _s(16), height = _s(16)),
            ),
            render.Padding(
                pad = _spad((21, 14, 0, 0)),
                child = render.Marquee(
                    child = render.Text(
                        content = ctx["artist_upper"],
                        font = "terminus-14-light" if canvas.is2x() else "tb-8",
                        color = ctx["artist_name_color"],
                    ),
                    width = _s(41),
                    offset_start = _s(4),
                    scroll_direction = "horizontal",
                    align = "start",
                ),
            ),
            render.Padding(
                pad = _spad((21, 24, 0, 0)),
                child = render.Marquee(
                    child = render.Text(
                        content = ctx["album_text"],
                        font = "6x10" if canvas.is2x() else "tom-thumb",
                        color = ctx["album_name_color"],
                    ),
                    width = _s(41),
                    offset_start = _s(4),
                    scroll_direction = "horizontal",
                    align = "start",
                ),
            ),
            render.Padding(
                pad = _spad((42, 25, 0, 0)),
                child = _clock_wrapped_text(ctx["clock_text"], 20),
            ),
        ],
    )

LAYOUT_RENDERERS = {
    "preset1": _render_layout_preset1,
    "preset2": _render_layout_preset2,
    "preset3": _render_layout_preset3,
    "preset4": _render_layout_preset4,
}

def get_track_info(username, api_key):
    if username == "":
        return _track_state(
            state = "config_error",
            name = "Missing username",
            artist = "",
            album = "Please supply a Last.fm username.",
            image = [],
        )

    if api_key == "":
        return _track_state(
            state = "config_error",
            name = "Missing API key",
            artist = "",
            album = "Please supply a Last.fm API key.",
            image = [],
        )

    response = http.get(
        url = LAST_FM_URL,
        params = {
            "method": "user.getrecenttracks",
            "limit": "1",
            "user": username,
            "api_key": api_key,
            "format": "json",
        },
    )

    if response.status_code != 200:
        return _track_state(
            state = "api_error",
            name = "Last.fm API error",
            artist = "",
            album = "Temporary API issue. Retrying soon.",
            image = [],
        )

    payload = response.json()
    if payload.get("error") != None:
        return _track_state(
            state = "api_error",
            name = "Last.fm API error",
            artist = "",
            album = _as_text(payload.get("message")) or "Temporary API issue. Retrying soon.",
            image = [],
        )

    recent_tracks = payload.get("recenttracks")
    if recent_tracks == None:
        return _track_state(
            state = "api_error",
            name = "Invalid API response",
            artist = "",
            album = "No recent tracks returned.",
            image = [],
        )

    tracks = recent_tracks.get("track")
    if tracks == None or len(tracks) == 0:
        return _track_state(
            state = "not_playing",
            name = "No track history",
            artist = "",
            album = "No scrobbles found for this user.",
            image = [],
        )

    track = tracks[0]
    nowplaying = track.get("@attr")
    if nowplaying == None or nowplaying.get("nowplaying") != "true":
        return _track_state(
            state = "not_playing",
            name = "",
            artist = "",
            album = "Waiting for a live scrobble.",
            image = [],
        )

    artist_data = track.get("artist")
    album_data = track.get("album")

    artist_name = ""
    if type(artist_data) == "dict":
        artist_name = _as_text(artist_data.get("#text"))
    else:
        artist_name = _as_text(artist_data)

    album_name = ""
    if type(album_data) == "dict":
        album_name = _as_text(album_data.get("#text"))
    else:
        album_name = _as_text(album_data)

    return _track_state(
        state = "now_playing",
        name = _as_text(track.get("name")),
        artist = artist_name,
        album = album_name,
        image = track.get("image") or [],
    )

def now_playing(config, username, track, artist, album, coverarturl, coverart, show_clock, clock_text, is_stale):
    if track == "" or artist == "":
        return not_playing(config, track, artist, album)

    song_title_color = config.get("color_song_title")
    artist_name_color = config.get("color_artist_name")
    album_name_color = config.get("color_album_name")
    track_upper = track.upper()
    artist_upper = artist.upper()
    album_text = _album_text(album, show_clock)

    has_album_art = coverart != None and coverart != "" and not _is_default_last_fm_image(coverarturl)
    coverart_img = _cover_art_src(coverart, has_album_art)
    layout_ctx = {
        "username": username,
        "track": track,
        "artist": artist,
        "song_title_color": song_title_color,
        "artist_name_color": artist_name_color,
        "show_clock": show_clock,
        "clock_text": clock_text,
        "track_upper": track_upper,
        "artist_upper": artist_upper,
        "album_text": album_text,
        "album_name_color": album_name_color,
        "has_album_art": has_album_art,
        "coverart_img": coverart_img,
    }

    layout_renderer = LAYOUT_RENDERERS.get(config.get("layout"))
    layout = render.Text("")
    if layout_renderer != None:
        layout = layout_renderer(layout_ctx)

    if is_stale:
        layout = render.Stack(
            children = [
                layout,
                render.Padding(
                    pad = _spad((1, 1, 0, 0)),
                    child = render.Box(
                        color = "#AA000000",
                        child = render.Padding(
                            pad = _spad((1, 0, 1, 0)),
                            child = render.Text(
                                content = "LAST SEEN",
                                font = "tom-thumb",
                                color = "#F6B73C",
                            ),
                        ),
                    ),
                ),
            ],
        )

    return _root(layout)

def not_playing(config, songtitle, artistname, albumname):
    if config.bool("now_playing_only", False):
        return []

    first_line = _compact_line(songtitle, artistname)
    if first_line == "":
        first_line = "Not currently scrobbling."

    second_line = albumname
    if second_line == "":
        second_line = "Waiting for a live scrobble."

    return _root(
        child = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Padding(
                            pad = _spad((2, 2, 2, 3)),
                            child = render.Image(
                                src = LAST_FM_LOGO.readall(),
                                width = _s(28),
                            ),
                        ),
                    ],
                    main_align = "center",
                    cross_align = "center",
                ),
                render.Padding(
                    pad = _spad((2, 0, 0, 1)),
                    child = render.WrappedText(
                        content = first_line,
                        font = "tom-thumb",
                        width = _s(60),
                        height = _s(12),
                        align = "left",
                    ),
                ),
                render.Padding(
                    pad = _spad((2, 0, 0, 0)),
                    child = render.Marquee(
                        delay = MARQUEE_START_DELAY,
                        width = _s(64),
                        child = render.Text(
                            content = second_line,
                            font = "tom-thumb",
                            color = "#555",
                        ),
                    ),
                ),
            ],
        ),
    )

def main(config):
    username = _as_text(config.get("username"))
    api_key = _as_text(config.get("dev_api_key"))
    cache_scope = "%s|%s" % (username, _api_key_tag(api_key))
    show_clock = config.bool("showClock", True)
    clock_text = time.now().format("3:04") if show_clock else ""

    cached_state = _read_now_state_cache(cache_scope)
    if _now_state_cache_hit(cached_state):
        song_title = cached_state.get("song_title")
        artist_name = cached_state.get("artist_name")
        album_name = cached_state.get("album_name")
        cover_art_url = cached_state.get("cover_art_url")
        cover_art = cached_state.get("cover_art")
        is_now_playing = _as_text(cached_state.get("is_now_playing")) == "true"
        is_stale = _as_text(cached_state.get("is_stale")) == "true"
    else:
        info = get_track_info(username, api_key)
        info_state = _as_text(info.get("state"))

        song_title = _as_text(info.get("name"))
        artist_name = _as_text(info.get("artist").get("#text"))
        album_name = _as_text(info.get("album").get("#text"))
        is_now_playing = info.get("is_now_playing") == True
        is_stale = False

        cover_art_url = ""
        cover_art = ""
        ttl_seconds = TTL_NOT_PLAYING

        if info_state == "now_playing":
            cover_art_url = _extract_cover_art_url(info.get("image"))
            cover_art = _download_cover_art(cover_art_url)
            is_now_playing = True
            ttl_seconds = TTL_NOW_PLAYING

            # Keep a longer-lived "last successful now-playing" fallback.
            _write_last_success_cache(
                scope = cache_scope,
                song_title = song_title,
                artist_name = artist_name,
                album_name = album_name,
                cover_art_url = cover_art_url,
                cover_art = cover_art,
            )

        elif info_state == "api_error":
            ttl_seconds = TTL_API_ERROR
            fallback = _read_last_success_cache(cache_scope)
            if _last_success_cache_hit(fallback):
                song_title = fallback.get("song_title")
                artist_name = fallback.get("artist_name")
                album_name = fallback.get("album_name")
                cover_art_url = fallback.get("cover_art_url")
                cover_art = fallback.get("cover_art")
                is_now_playing = True
                is_stale = True
            else:
                is_now_playing = False

        else:
            ttl_seconds = TTL_NOT_PLAYING
            is_now_playing = False
            is_stale = False

        _write_now_state_cache(
            scope = cache_scope,
            song_title = song_title,
            artist_name = artist_name,
            album_name = album_name,
            cover_art_url = cover_art_url,
            cover_art = cover_art,
            is_now_playing = is_now_playing,
            is_stale = is_stale,
            ttl_seconds = ttl_seconds,
        )

    if is_now_playing:
        return now_playing(
            config = config,
            username = username,
            track = song_title,
            artist = artist_name,
            album = album_name,
            coverarturl = cover_art_url,
            coverart = cover_art,
            show_clock = show_clock,
            clock_text = clock_text,
            is_stale = is_stale,
        )

    return not_playing(
        config = config,
        songtitle = song_title,
        artistname = artist_name,
        albumname = album_name,
    )

def get_schema():
    layoutOptions = [
        schema.Option(
            display = "Preset 1",
            value = "preset1",
        ),
        schema.Option(
            display = "Preset 2",
            value = "preset2",
        ),
        schema.Option(
            display = "Preset 3",
            value = "preset3",
        ),
        schema.Option(
            display = "Preset 4",
            value = "preset4",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Last.fm Username",
                desc = "The username to look up on Last.fm.",
                icon = "user",
                default = "",
            ),
            schema.Text(
                id = "dev_api_key",
                name = "Last.fm API Key",
                desc = "Supply your own API key. (Apply for one at last.fm/api/account/create)",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Toggle(
                id = "showClock",
                name = "Show clock?",
                icon = "clock",
                desc = "Displays a clock showing the local time.",
                default = True,
            ),
            schema.Toggle(
                id = "now_playing_only",
                name = "Hide when not playing",
                desc = "Enable to only show app when a track is currently being scrobbled to Last.fm.",
                icon = "eyeSlash",
                default = False,
            ),
            schema.Color(
                id = "color_song_title",
                name = "Song Title Color",
                desc = "The color to display the song title.",
                icon = "brush",
                default = "#FFFFFF",
                palette = [
                    "#FFFFFF",
                    "#B90000",
                ],
            ),
            schema.Color(
                id = "color_artist_name",
                name = "Artist Name Color",
                desc = "The color to display the artist name.",
                icon = "brush",
                default = "#FFFFFF",
                palette = [
                    "#FFFFFF",
                    "#B90000",
                ],
            ),
            schema.Color(
                id = "color_album_name",
                name = "Album Name Color",
                desc = "The color to display the album name.",
                icon = "brush",
                default = "#FFFFFF",
                palette = [
                    "#FFFFFF",
                ],
            ),
            schema.Dropdown(
                id = "layout",
                name = "Layout",
                desc = "Preset layouts for the display.",
                icon = "brush",
                default = layoutOptions[0].value,
                options = layoutOptions,
            ),
        ],
    )
