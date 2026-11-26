"""
Applet: SUBWAVE Now Playing
Summary: Shows what's playing on a SUB/WAVE station
Description: Configure with your SUB/WAVE (github.com/perminder-klair/subwave) station's base URL to display the current track, artist, show, host, listener count, album art, time/temp, and a progress bar.
Author: poprhythm
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/json.star", "json")
load("filter.star", "filter")
load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_STATION_URL = ""
NOWPLAYING_TTL = 20
COVER_TTL = 300

# tom-thumb average rendered width (px/char), measured via the CLI.
# Used for centering / right-align / fit heuristics -- pixlet can't
# measure text width from Starlark. WIDTH_ESTIMATE_SLACK is subtracted
# when packing multiple estimated segments into a fixed row so a slightly
# wide real glyph doesn't clip the right edge.
TOM_THUMB_PX_PER_CHAR = 3.9
WIDTH_ESTIMATE_SLACK = 2
LISTENER_BADGE_GAP = 3  # px between host text and the listener badge

# Cap unique glitch flicker frames at 1x so busy album art doesn't blow
# the Gen1 ~460KB WebP budget; 2x keeps full per-frame randomization.
# 2x payloads run well past 460KB (see README "Payload size") -- only
# verified on a 2x device with firmware patched to allow more memory.
GLITCH_1X_UNIQUE_FRAMES = 4

# These match SUB/WAVE's own web UI theme picker (Blueprint, Classic Dark,
# Classic Light, Cyberpunk, Flare, Recon, Signal, Vinyl), so a station's own
# site theme can be mirrored on the device. Each scheme sets a background
# fill, the main text color (title/artist/show), an accent (host/DJ name +
# progress bar fill), a muted meta color (time/temp), a separator, and the
# progress bar's empty-track color.
COLOR_SCHEMES = {
    "blueprint": {
        "background": "#0a1128",
        "text": "#8ecae6",
        "accent": "#4a90e2",
        "meta": "#3f5a7a",
        "separator": "#1f3a5f",
        "bar_empty": "#12223d",
    },
    "classic_dark": {
        "background": "#1a1a1a",
        "text": "#f0e6d2",
        "accent": "#d32f2f",
        "meta": "#8a8070",
        "separator": "#3a3a3a",
        "bar_empty": "#2b2b2b",
    },
    "classic_light": {
        "background": "#f0e6d2",
        "text": "#1a1a1a",
        "accent": "#e63946",
        "meta": "#7a7062",
        "separator": "#d8cdb8",
        "bar_empty": "#ded2ba",
    },
    "cyberpunk": {
        "background": "#0d0d0d",
        "text": "#22d3ee",
        "accent": "#ec4899",
        "meta": "#7a7a8a",
        "separator": "#2a2a35",
        "bar_empty": "#241f2e",
    },
    "flare": {
        "background": "#120a00",
        "text": "#ff8c1a",
        "accent": "#ff6600",
        "meta": "#8a5a2a",
        "separator": "#3a2000",
        "bar_empty": "#2a1800",
    },
    "recon": {
        "background": "#4a4331",
        "text": "#f2ecd9",
        "accent": "#ff8c3a",
        "meta": "#a89f85",
        "separator": "#2a2519",
        "bar_empty": "#332e20",
    },
    "signal": {
        "background": "#2b2b2b",
        "text": "#d9d9d9",
        "accent": "#9a9a9a",
        "meta": "#6e6e6e",
        "separator": "#3a3a3a",
        "bar_empty": "#1e1e1e",
    },
    "vinyl": {
        "background": "#3e2f23",
        "text": "#e8d5b5",
        "accent": "#c97d3d",
        "meta": "#8a7358",
        "separator": "#2a1f16",
        "bar_empty": "#241b13",
    },
}
DEFAULT_COLOR_SCHEME = "cyberpunk"  # matches the station's own site theme

# How many seconds into a track's start, or before its reported end, the
# glitch overlay shows over the album art. Only used when the "Static
# overlay" schema field is enabled.
#
# These aren't symmetric on purpose: SUB/WAVE's reported `duration` is a
# track's full metadata length, but in practice the station appears to
# cut/crossfade to the next track a bit before that duration actually
# elapses (observed via the progress bar consistently stalling a few
# segments short of full, never reaching the end) -- so `remaining` was
# rarely if ever dropping below a short end-window before the subsonic_id
# changed out from under it. Widening the end window compensates for that
# observed early cutoff; the start window doesn't have the same problem
# (elapsed genuinely starts at 0) so it stays short.
STATIC_OVERLAY_START_SECONDS = 5
STATIC_OVERLAY_END_SECONDS = 22
DEFAULT_STATIC_OVERLAY = "on"

# How far in the album art zoom goes, relative to its fully-zoomed-out rest
# state (see _art_widget below for why scale never goes below 1.0).
# 1x-only reduction: a busy/high-detail album cover (a "NOW" compilation,
# reports of an overrun with moderate zoom on one) pushed worst-case
# payload up -- the breathing zoom cycling through a wider scale range
# means more genuinely distinct crops to encode over the animation. 2x
# keeps the original values -- verified on a 2x device whose firmware
# was patched to allow more memory (stock firmware may not have that
# headroom; see README "Payload size"), so this is deliberately not a
# blanket reduction. Verified against a real "NOW"-style compilation
# cover: "moderate" at 1.2 measured ~309-315KB across several runs, vs
# ~329-336KB at the original 1.4 -- a real, repeatable margin gain, not
# just noise from the glitch segment's own randomness. "strong" trimmed
# the same way (1.7 -> 1.35). Crop-centering safety re-checked with the
# calibration tool (not real album art, which can have genuinely black
# regions that a naive corner-pixel check can't tell apart from an
# actual exposed margin) at the new "strong" value across every
# ZOOM_RANDOM_SPOTS position: 0 black/void corner hits.
ZOOM_LEVELS_1X = {
    "off": 1.0,
    "subtle": 1.1,
    "moderate": 1.2,
    "strong": 1.35,
}
ZOOM_LEVELS_2X = {
    "off": 1.0,
    "subtle": 1.15,
    "moderate": 1.4,
    "strong": 1.7,
}
DEFAULT_ZOOM_LEVEL = "moderate"

# Where the zoom centers on, as animation.Origin fractions of the image's
# own 36x36 bounds. Kept modest (0.3-0.7, not full 0.0-1.0) and verified
# safe (no black border, even at the strongest 1.7x zoom) via the
# calibration tool -- more extreme corners weren't tested and may not be.
# Only used when the "Zoom position" schema field is set to "random" --
# "center" always zooms on the image's own center, exposed as a config
# choice since some covers (e.g. ones with a centered logo or face) read
# better with a predictable center zoom than a random one.
#
# Rotates on a ~10s cadence (matching ART_ZOOM_DURATION below) based on
# wall-clock time, not just per-track: a time bucket picks the spot, offset
# by a per-track hash so different tracks don't all land on the same spot
# at the same moment. This means the spot can change on *every* refresh,
# including mid-playback of a single still-running track -- not just when
# the track itself changes -- so a long track gets to show off different
# sections of its art over time, which is the whole point of "random"
# rather than "center". One real limitation: a one-shot `pixlet render`
# CLI call reads the system clock same as the live server would, so this
# is still deterministic for a given moment -- it just varies *which*
# moment you rendered at, same as the live progress bar in _track_progress.
ZOOM_CENTER_SPOT = (0.5, 0.5)
ZOOM_RANDOM_SPOTS = [
    (0.5, 0.5),
    (0.3, 0.3),
    (0.7, 0.7),
    (0.3, 0.7),
    (0.7, 0.3),
]
ZOOM_SPOT_ROTATE_SECONDS = 10
DEFAULT_ZOOM_POSITION = "center"

def _zoom_spot(zoom_position, subsonic_id):
    if zoom_position != "random":
        return ZOOM_CENTER_SPOT

    track_offset = 0
    for ch in subsonic_id.elems():
        track_offset += ord(ch)

    time_bucket = int(time.now().unix / ZOOM_SPOT_ROTATE_SECONDS)
    return ZOOM_RANDOM_SPOTS[(time_bucket + track_offset) % len(ZOOM_RANDOM_SPOTS)]

def main(config):
    # `scale` is the single source of truth for 2x support: 2 when the
    # device/preview is rendering at 2x resolution (canvas.is2x()), else
    # 1. Every size-based constant in this file is expressed as its 1x
    # value and multiplied by `scale` at the point of use, rather than
    # hardcoding separate 1x/2x numbers -- this keeps every hand-tuned
    # relationship (black-border margins, scanline period divisibility,
    # band overlap gaps) proportionally identical at both resolutions,
    # since scaling every term in an already-verified-safe linear
    # relationship by the same integer factor can't change its sign or
    # introduce a new overlap/exposure that wasn't already ruled out at
    # 1x. Tick counts/durations are deliberately *not* scaled -- those
    # are real time, not space, and should take the same number of
    # seconds regardless of resolution.
    scale = 2 if canvas.is2x() else 1

    station_url = _normalize_station_url(config.get("station_url", DEFAULT_STATION_URL))

    colors = COLOR_SCHEMES.get(config.get("color_scheme", DEFAULT_COLOR_SCHEME), COLOR_SCHEMES[DEFAULT_COLOR_SCHEME])
    zoom_levels = ZOOM_LEVELS_2X if scale == 2 else ZOOM_LEVELS_1X
    zoom_scale = zoom_levels.get(config.get("zoom_level", DEFAULT_ZOOM_LEVEL), zoom_levels[DEFAULT_ZOOM_LEVEL])
    zoom_position = config.get("zoom_position", DEFAULT_ZOOM_POSITION)
    static_overlay_enabled = config.get("static_overlay", DEFAULT_STATIC_OVERLAY) == "on"

    if not station_url:
        return render.Root(child = _with_background(_message_screen(["Set station URL", "in app settings"], colors), colors))

    now = _fetch_now_playing(station_url)
    if now == None:
        return render.Root(child = _with_background(_message_screen(["Can't reach", "station"], colors), colors))

    if not now["online"]:
        return render.Root(child = _with_background(_message_screen([now["station"], "offline"], colors), colors))

    # A show's own theme override (if any) wins over the user's configured
    # color_scheme, mirroring what SUB/WAVE's own web UI does -- see
    # _fetch_show_colors. Only when activeSource is genuinely "show" (a
    # show with its own themeId pinned, outranking the station default) --
    # when it's "station" (no show-level override), the user's own
    # configured color_scheme is respected instead, not the station's
    # default. Falls back to the configured scheme on any fetch / parse
    # failure (including unrecognized CSS color tokens).
    show_colors = _fetch_show_colors(station_url)
    if show_colors != None:
        colors = show_colors

    art = _fetch_cover(station_url, now["subsonic_id"])
    progress = _track_progress(now["subsonic_id"], now["duration"], now["started_at"])

    # Glitch window uses wall-clock elapsed from the track's real start
    # (API timestamp) -- see _track_progress.
    show_static = (
        static_overlay_enabled and
        progress != None and
        (progress["elapsed"] < STATIC_OVERLAY_START_SECONDS or progress["remaining"] < STATIC_OVERLAY_END_SECONDS)
    )

    # With art: text column is the other half of the canvas. Without art:
    # reuse the same text layout at full canvas width rather than a
    # title/artist-only fallback.
    text_width = ART_SLOT * scale if art else canvas.width()
    text_height = ART_SLOT * scale if art else canvas.height()

    time_temp_text = render.Text(now["time_temp"], font = "tom-thumb", color = colors["meta"])

    # At 2x, the extra width usually fits e.g. "9:54 pm \xb7 65\xb0F" without
    # scrolling -- tried as a first, contained experiment in using 2x's
    # extra room rather than just stretching the same 1x layout. But
    # tom-thumb is variable-width and pixlet has no way to measure
    # rendered text width from within Starlark, so this is a length
    # heuristic, not an exact fit check: measured via the CLI,
    # "12:59 pm \xb7 100\xb0F" (16 chars, a realistic worst case -- 2-digit
    # hour, 3-digit temp) comes out to 63px against a 64px budget, 1px of
    # margin; "11:59 am \xb7 -5\xb0F" (15 chars) is a safer 59px. Capping at
    # 15 chars keeps a real margin against overflowing into the art
    # column instead of relying on a 1px coincidence. Always Marquee at
    # 1x, where the available width is tighter regardless of length.
    #
    # Counted via codepoints, not a bare len(): Starlark's len() on a
    # string counts UTF-8 *bytes*, and this string almost always has at
    # least one multi-byte character (the \xb7 separator, \xb0 in the temp,
    # if any) -- confirmed len() reports 16 for a real 14-character
    # string here, which silently sent every normal-length string down
    # the Marquee branch instead of the intended centered-static-text one
    # (visually: text appeared "stuck" left-aligned with no error, since
    # Marquee just shows already-fitting content statically rather than
    # scrolling it -- easy to mistake for "the centering didn't work").
    time_temp_char_count = _codepoint_len(now["time_temp"])
    time_temp_fits = scale == 2 and time_temp_char_count <= 15

    # Centered via a computed left Padding, not render.Row(expanded=True,
    # main_align="center") -- that version centered the text correctly,
    # but Row's `expanded` also grabbed extra *vertical* space from the
    # enclosing Column (main_align="space_between"), which pushed the
    # progress bar below it out of view. Padding only nudges this one
    # line horizontally, so it can't affect the Column's vertical
    # distribution the way a flexible/expanding child can.
    #
    # tom-thumb is variable-width, so this is an estimate
    # (TOM_THUMB_PX_PER_CHAR, measured via the CLI against several real
    # time/temp strings), not pixel-exact centering -- close enough that
    # it isn't visibly off-center for strings in the length range this
    # branch allows.
    estimated_text_width = _estimate_text_width(now["time_temp"])
    pad_left = max(0, (text_width - estimated_text_width) // 2)
    time_temp_line = (
        render.Padding(pad = (pad_left, 0, 0, 0), child = time_temp_text) if time_temp_fits else render.Marquee(width = text_width, child = time_temp_text)
    )

    # terminus-16 is exactly double tb-8's height (8px -> 16px) -- also
    # pixlet's own documented default font for 2x displays, so it's a
    # natural "the title gets to be genuinely bigger, not just more
    # pixels" choice for the one line this was asked for, rather than
    # applying it everywhere (artist/show/time stay tb-8/tom-thumb, same
    # as before).
    title_font = "terminus-16" if scale == 2 else "tb-8"

    # 1x and 2x build show/host differently -- branched here so neither
    # path constructs widgets the other will throw away.
    #
    # 2x: split show and host onto their own lines (no spare row at 1x).
    # Show names can run ~60 chars, so that line stays a Marquee.
    # Host + listener badge share a row (left/right), with Marquee only
    # on the host side when it doesn't fit the remaining width.
    #
    # 1x: show, host, and optional listener badge share one Marquee row.
    if scale == 2:
        host_text = render.Text(now["host"], font = "tom-thumb", color = colors["accent"]) if now["host"] else None
        host_badge = _listener_badge(now["listeners"], colors["meta"]) if now["listeners"] else None
        host_badge_width = _listener_badge_width(now["listeners"]) if host_badge else 0
        if host_text == None and host_badge == None:
            # Empty placeholder -- keeps the row count/position fixed
            # even with no host credited.
            host_line = render.Box(width = text_width, height = 6)
        else:
            # Host left, listeners right, computed spacer Box between
            # (same approach as the BPM/track-length row: nothing
            # flexible that could steal vertical space from the Column).
            badge_reserve = host_badge_width + LISTENER_BADGE_GAP if host_badge else 0
            host_area = text_width - badge_reserve
            host_est_width = _estimate_text_width(now["host"]) if host_text else 0
            row_children = []
            if host_text:
                row_children.append(host_text if host_est_width <= host_area else render.Marquee(width = host_area, child = host_text))
            if host_badge:
                used_host = min(host_est_width, host_area) if host_text else 0
                gap = max(0, text_width - used_host - host_badge_width - WIDTH_ESTIMATE_SLACK)
                row_children.append(render.Box(width = gap, height = 1))
                row_children.append(host_badge)

            # height=6 is required -- see the BPM/track-length row for
            # the Box-expands-when-unconstrained bug it avoids.
            host_line = render.Box(width = text_width, height = 6, child = render.Row(children = row_children, cross_align = "center"))

        show_lines = [
            render.Marquee(width = text_width, child = render.Text(now["show"], font = "tom-thumb", color = colors["text"])),
            host_line,
        ]
    else:
        show_host_row = [render.Text(now["show"], font = "tom-thumb", color = colors["text"])]
        if now["host"]:
            show_host_row.append(render.Text(" " + now["host"], font = "tom-thumb", color = colors["accent"]))
        if now["listeners"]:
            show_host_row.append(render.Box(width = LISTENER_BADGE_GAP, height = 1))
            show_host_row.append(_listener_badge(now["listeners"], colors["meta"]))
        show_lines = [render.Marquee(width = text_width, child = render.Row(children = show_host_row))]

    # Album/year only at 2x -- there's no spare row for it at 1x's tighter
    # layout, same reasoning as the show/host split above. Marquee, not a
    # centered static line like host/time_temp: album titles can run as
    # long as track titles, so there's no "assumed short" case here to
    # justify skipping it.
    album_year_lines = (
        [render.Marquee(width = text_width, child = render.Text(now["album_year"], font = "tom-thumb", color = colors["meta"]))] if scale == 2 else []
    )

    top_lines = [
        render.Marquee(width = text_width, child = render.Text(now["title"], font = title_font, color = colors["text"])),
        render.Marquee(width = text_width, child = render.Text(now["artist"], font = "tb-8", color = colors["text"])),
    ] + album_year_lines + [
        render.Box(width = text_width, height = 1, color = colors["separator"]),  # kept at a crisp 1px at every scale, per request, rather than growing to match
    ] + show_lines + [time_temp_line]

    children = [render.Column(children = top_lines)]

    # BPM (left) / track length (right), 2x only -- same reasoning as the
    # other 2x-only additions above: no spare row for it at 1x's tighter
    # layout. Only when at least one of the two strings is non-empty, so
    # we don't reserve a blank 6px strip above the progress bar.
    #
    # A plain Row with a computed Box spacer (not expanded /
    # space_between): `expanded` on a Row grabs extra *vertical* space
    # from this Column and has pushed the progress bar off-screen before.
    if scale == 2 and (now["bpm"] or now["track_length"]):
        bpm_width = _estimate_text_width(now["bpm"])
        length_width = _estimate_text_width(now["track_length"])

        # WIDTH_ESTIMATE_SLACK: 3.9px/char is an average; real strings can
        # render a little wider on the right. Flat correction rather than
        # per-character widths.
        gap = max(0, text_width - bpm_width - length_width - WIDTH_ESTIMATE_SLACK)

        # Box(width, height=6) hard-clips estimation overflow and stops
        # Box's expand-when-unconstrained behavior from stealing vertical
        # space inside space_between (same bug class as the time_temp
        # centering fix).
        children.append(render.Box(
            width = text_width,
            height = 6,
            child = render.Row(children = [
                render.Text(now["bpm"], font = "tom-thumb", color = colors["meta"]),
                render.Box(width = gap, height = 1),
                render.Text(now["track_length"], font = "tom-thumb", color = colors["meta"]),
            ]),
        ))

    if progress != None:
        children.append(_progress_bar(progress["fraction"], colors, width = text_width, height = 2 * scale))

    text_column = render.Box(
        width = text_width,
        height = text_height,
        child = render.Column(
            main_align = "space_between",
            cross_align = "start",
            expanded = True,
            children = children,
        ),
    )

    if art:
        content = render.Row(children = [_art_widget(art, zoom_scale, zoom_position, now["subsonic_id"], show_static, scale), text_column])
    else:
        content = text_column

    return render.Root(child = _with_background(content, colors))

def _codepoint_len(s):
    # Starlark's len() on a string counts UTF-8 bytes, not characters.
    return len(list(s.codepoints()))

def _estimate_text_width(s):
    # Approximate tom-thumb render width in px (see TOM_THUMB_PX_PER_CHAR).
    return int(_codepoint_len(s) * TOM_THUMB_PX_PER_CHAR)

def _with_background(child, colors):
    return render.Stack(children = [
        render.Box(width = canvas.width(), height = canvas.height(), color = colors["background"]),
        child,
    ])

# Album art gets a slow "Ken Burns" breathing effect: starts and ends on
# the full frame, easing in to a zoomed-in crop at the midpoint, on a
# continuous loop -- not a one-shot reveal. A one-shot version (start
# zoomed in, end on the full frame, then hold) looked jumpy: since the app
# re-renders on NOWPLAYING_TTL
# and each fresh render restarts its own animation from tick 0, whatever the
# *previous* pushed image happened to be showing at that moment gets
# abruptly replaced by a fresh zoomed-in frame. The back-and-forth loop
# doesn't eliminate that (a server-side re-render always restarts at tick 0
# regardless), but ending exactly where it started means the animation also
# loops seamlessly on-device between refreshes.
#
# Duration is intentionally short (a handful of seconds each way), not the
# ~60s round-trip originally tried: on the real device/server, a fresh
# render replaces the still-playing animation well before a minute-long
# cycle can complete, so only the outbound half (zoom out) was ever visible
# and it never appeared to "zoom back in". A short loop guarantees at least
# one full out-and-back cycle plays before that happens.
#
# Art is rendered slightly oversized (36x36, vs. the 32x32 display slot).
# animation.Scale is only ever applied at 1.0 or above here -- empirically,
# scaling this *below* 1.0 (tried while chasing a "show the literal whole
# image at rest" design) reintroduces a real, on-device black-border bug:
# below roughly 0.9-0.95 a visible gap opens up along one edge, well before
# the math (scaled size vs. box size) would predict any gap at all, so it
# isn't a simple "runs out of image" overflow -- treat scale < 1.0 as
# unsafe regardless of the numbers. That rules out "native size at rest,
# shrink down to reveal everything" -- so instead ART_SIZE is kept just
# barely larger than ART_SLOT: at the safe floor of scale = 1.0, only
# ART_SLOT/ART_SIZE (~89%) of the image is visible, which reads as
# "fully zoomed out" (a sliver cropped off each edge, not noticeable) while
# leaving just enough headroom above 1.0 for a real zoom-in effect. The
# zoom-in amount itself (`zoom_scale`, from the ZOOM_LEVELS schema option)
# must stay >= 1.0 for the same reason.
ART_SIZE = 36
ART_SLOT = 32
ART_ZOOM_DURATION = 200  # 10s round-trip (5s in, 5s out) at the default 50ms/tick

def _art_widget(art_bytes, zoom_scale, zoom_position, subsonic_id, show_static, scale):
    zoom = _zoom_transformation(art_bytes, zoom_scale, zoom_position, subsonic_id, scale)
    cropped = render.Box(width = ART_SLOT * scale, height = ART_SLOT * scale, child = zoom)

    if not show_static:
        return cropped

    # The glitch segment gets its own non-animated, full-resolution
    # (scale locked at 1.0) rendering of the art, rather than the live
    # `zoom` above -- simpler than keeping the jitter in sync with
    # wherever the real zoom's 10s cycle currently is (see
    # _glitch_rest_art for why that was worth avoiding). The live zoom on
    # the base `cropped` layer underneath keeps running throughout; once
    # the glitch window ends, that's what's left showing.
    rest_art = _glitch_rest_art(art_bytes, zoom_position, subsonic_id, scale)
    return render.Stack(children = [cropped, _glitch_effect(rest_art, scale)])

def _zoom_transformation(art_bytes, zoom_scale, zoom_position, subsonic_id, scale):
    # Decoding at ART_SIZE * scale (not a fixed ART_SIZE) is what actually
    # makes 2x worth anything for the art specifically: the source JPEG
    # fetched live from the station is typically much higher resolution
    # than even a doubled target, so a bigger decode genuinely pulls in
    # more real detail rather than just stretching the same 36x36-logical-
    # pixel result pixlet would otherwise produce by passively upscaling
    # the final composited image (confirmed empirically: a non-2x-aware
    # render, downscaled back with nearest-neighbor, matched the 1x render
    # exactly -- no extra detail, just bigger blocks).
    art = render.Image(src = art_bytes, width = ART_SIZE * scale, height = ART_SIZE * scale)

    # Always route through animation.Transformation, even when zoom is off
    # (a degenerate animation whose two keyframes are both Scale(1.0, 1.0),
    # i.e. no visible movement). Wrapping the art in a Transformation shifts
    # its crop by a few pixels versus a bare, unwrapped Image in the same
    # Box -- confirmed empirically, even at an explicit Scale(1.0, 1.0) --
    # so a plain-Image "off" path and a Transformation-wrapped zoom path
    # don't actually agree on framing despite both nominally being "scale
    # 1.0". Using the same wrapper unconditionally guarantees the "off"
    # state and the rest state of every zoom level line up exactly.
    #
    # `origin` picks where the zoom centers on, which also gives a free
    # "zoom to a different spot each time" effect (ZOOM_RANDOM_SPOTS above) by
    # just varying it per track. An earlier version tried to recenter the
    # zoom by pairing Scale with a *computed, animated* Translate, on the
    # mistaken assumption that Scale's default pivot is the top-left
    # corner -- it isn't; pixlet's own docs say the default origin is
    # already the center (0.5, 0.5). That Translate was sized assuming
    # Scale had no self-centering at all, so it overcorrected, visibly
    # skewing the zoom toward the bottom-right -- the opposite of the bug
    # it was meant to fix. Since `origin` already does directly and
    # correctly what that Translate was clumsily approximating, this uses
    # `origin` for the zoom-position pivot.
    #
    # Separately, though: `origin` only has any effect while Scale is
    # actually changing frame to frame -- confirmed empirically (varying
    # origin_x/origin_y produced byte-identical output for a Scale that's
    # pinned to the same constant value across every keyframe, at *any*
    # scale, not just 1.0). At the two instants where this animation's own
    # Scale is momentarily constant (percentage 0.0 and 1.0, i.e. "rest"),
    # there's nothing for origin to pivot, so the crop that's left falls
    # back to render.Box's own default handling of an oversized
    # Transformation child -- which isn't a centered crop at all: checked
    # with the calibration tool (concentric rings plus a center crosshair),
    # the crosshair sat several pixels down-and-right of where a centered
    # crop would put it, i.e. the box was effectively showing more of the
    # image's top-left and cropping away a disproportionate amount from
    # the bottom-right -- matching exactly what was reported ("losing
    # ~10% on bottom and right, not zoomed").
    #
    # Fixed with a *constant* Translate -- the same (tx, ty) at every
    # keyframe, found empirically via the calibration tool's crosshair
    # (the value that put it dead-center at rest also held up at peak
    # zoom). This is not the same mistake as the earlier abandoned
    # attempt: that Translate *varied* over the animation (fighting
    # Origin's own pivot, and per pixlet's own source, interacting badly
    # with Scale's continuous interpolation vs. Translate's per-frame
    # rounding -- the "periodic pop" bug). A constant value changes
    # nothing frame to frame, so there's no interpolation for it to
    # mismatch against -- confirmed smooth across a full cycle, no pop.
    # It's purely compensating for render.Box's own fixed crop bias, which
    # doesn't depend on zoom_scale/zoom_position at all.
    origin_x, origin_y = _zoom_spot(zoom_position, subsonic_id)
    top_scale = max(zoom_scale, 1.0)
    box_crop_bias = -2 * scale
    zoom = animation.Transformation(
        child = art,
        duration = ART_ZOOM_DURATION,
        origin = animation.Origin(origin_x, origin_y),
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Scale(1.0, 1.0), animation.Translate(box_crop_bias, box_crop_bias)],
            ),
            animation.Keyframe(
                percentage = 0.5,
                transforms = [animation.Scale(top_scale, top_scale), animation.Translate(box_crop_bias, box_crop_bias)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Scale(1.0, 1.0), animation.Translate(box_crop_bias, box_crop_bias)],
                curve = "ease_in_out",
            ),
        ],
    )
    return zoom

# Modeled on SUB/WAVE's own web UI, which applies a track-transition
# effect to the cover art (found via its compiled CSS/JS, not written down
# anywhere as a spec): an RGB-split/chromatic-aberration glitch -- two
# duplicate, differently-tinted copies of the art, each cropped to a
# shifting horizontal band -- plus scanlines and viewfinder-style corner
# tick marks. Built here from scratch against the *live* art via
# filter.Hue, not a bundled asset -- pixlet's `filter` module (confirmed
# real and working, same as `animation.Origin`) can recolor an arbitrary
# widget, including an already-zoomed render.Image, so the glitch bands
# reflect whatever's actually on screen rather than a generic texture.
# This replaced an earlier version built as a bundled static.gif overlay
# (first sparse noise specks, briefly a VHS-footage-derived band) -- that
# approach is still viable for projects without filter.star, but once a
# live-recolor option exists it's a better match for what SUB/WAVE itself
# does, and it means this app goes back to a single-file upload (no
# bundled asset to zip alongside it).
#
# The exact keyframe sequence/timing SUB/WAVE's CSS uses past the first
# keyframe isn't visible in its compiled output (no source maps), so
# GLITCH_STATES below is an original sequence in the same spirit (shifting
# inset bands, step-end/snap timing via a Sequence rather than eased
# motion) rather than a reproduction of unseen code. Band proportions
# (top/height as a fraction of ART_SLOT) are loosely modeled on the one
# keyframe that was visible: roughly the top third and an overlapping
# middle band, each about 30% of the frame's height.
GLITCH_HOLD_TICKS = 2  # ~100ms per flicker frame at the default 50ms/tick

# Explicit on/off timing: (is_on, duration_ms) pairs, one cycle, repeated
# GLITCH_REPEATS times. Each ms value must be a multiple of 50 (one tick),
# and "on" values a multiple of 100 (GLITCH_HOLD_TICKS-aligned) so a burst
# splits into whole flicker frames. Adapted from the diagnostic app's
# pattern, starting at its 2s peak burst (no leading clean second) and
# settling off through the tail of it.
GLITCH_PATTERN_MS = [
    (True, 1000),
    (True, 1000),
    (False, 100),
    (True, 300),
    (False, 500),
    (True, 100),
    (False, 1000),
]

GLITCH_TINT_HUE_MAGNITUDE = 40  # degrees, random each frame in [-40, 40]
GLITCH_SHADE_ALPHA_MIN = 15  # out of 255, random darkening wash each frame
GLITCH_SHADE_ALPHA_MAX = 70

# render.Sequence doesn't loop on its own (see _glitch_scanlines below), so
# to repeat the burst-then-pause pattern, the repeats have to be spelled
# out as one long children list up front rather than relying on any
# runtime looping. That matters here: with GLITCH_ACTIVE_SECONDS shorter
# than the actual show_static window, the sequence simply ran out and
# stopped painting partway through -- jitter played once near the start
# of the window and then silently went quiet for the rest of it, while
# the scanlines/corner ticks (which aren't Sequence-based) kept going,
# making it look like jitter wasn't working at all once past that
# opening burst.
#
# An earlier version capped this well below the full show_static window
# (which can be up to STATIC_OVERLAY_END_SECONDS = 22s) because the
# hue-shifted RGB-split bands this used to also drive were expensive
# enough to push a real render past the 460KB device limit if sized
# against the full window (measured 481KB at the time). Those bands were
# dropped for a while (jitter alone, measured ~54KB worst-case at the
# full 22s) and this was widened to match -- but the bands have since
# come back (see _glitch_burst_frames below), and worst-case payload tracks
# the *album art's own complexity*, not just whether bands are on: a
# busy/high-entropy cover compresses far worse than typical art, since
# every jitter/band/hue-shift state built from it ends up genuinely
# distinct rather than mostly redundant. Measured against synthetic
# noise art at the full 22s + strong zoom + random position: 354KB,
# uncomfortably close to the Gen1 460KB limit for art this adversarial.
#
# Capped at 18s (not the full 22) as a deliberate safety margin against
# that -- shorter than the max show_static window, so jitter/bands (and
# the scanline sweep, which shares this duration -- see
# SCANLINE_SWEEP_DURATION below) go static for the last few seconds of
# an "ending" window on a very long remaining-time case, the same
# tradeoff this was widened past once already, just re-accepted on
# purpose this time for the payload margin.
GLITCH_ACTIVE_SECONDS = 18
_GLITCH_TICKS_PER_SECOND = 20  # 1000ms / 50ms-per-tick

def _glitch_cycle_ticks():
    total_ms = 0
    for _, ms in GLITCH_PATTERN_MS:
        total_ms += ms
    return total_ms * _GLITCH_TICKS_PER_SECOND // 1000

_GLITCH_CYCLE_TICKS = _glitch_cycle_ticks()
GLITCH_REPEATS = int(GLITCH_ACTIVE_SECONDS * _GLITCH_TICKS_PER_SECOND / _GLITCH_CYCLE_TICKS) + 1

def _glitch_rest_art(art_bytes, zoom_position, subsonic_id, scale):
    # A separate, non-animated rendering of the art for the glitch segment
    # to jitter, instead of reusing the live `zoom` that's actually
    # mid-cycle on the base layer underneath. Simpler than keeping the
    # jitter synced to wherever that 10s cycle currently is -- there's
    # nothing here that depends on frame position, so nothing to desync
    # regardless of how the jitter's own timing is built. Same
    # origin/zoom_position as the real zoom, so it doesn't visually jump
    # to a different part of the image when the glitch starts or ends.
    #
    # Scale is locked at 1.0 (via _zoom_transformation's own top_scale =
    # max(zoom_scale, 1.0), so passing 1.0 forces a constant Scale(1.0,
    # 1.0) with no breathing at all) -- this is exactly the "rest" state
    # _glitch_shift's own margin was already validated against (see its
    # comment below). A black border was seen here earlier, but it traced
    # to the *shift* mechanism (animation.Transformation + Translate,
    # since replaced -- see _glitch_jitter), not to this scale; two
    # different attempts to fix it by bumping the scale (1.15 breathing,
    # then a constant 1.15) each made the border worse, not better, which
    # was the tell that scale was never the real problem.
    return _zoom_transformation(art_bytes, 1.0, zoom_position, subsonic_id, scale)

def _glitch_shift(zoom, shift_x):
    # Applied to the *raw* zoom Transformation (not an already-cropped
    # ART_SLOT x ART_SLOT image) and only clipped to ART_SLOT afterward,
    # so a horizontal nudge reveals more of the same oversized margin the
    # zoom animation itself relies on, rather than exposing a blank edge
    # with nothing behind it -- confirmed empirically (no black border at
    # +-2px, at both rest and peak zoom) before building this in.
    return render.Padding(pad = (max(0, shift_x), 0, max(0, -shift_x), 0), child = zoom)

def _glitch_band(zoom, top, height, shift_x, hue_change, scale):
    # top/height/shift_x arrive already multiplied by `scale` (see
    # _glitch_jitter, which scales GLITCH_STATE_POOL's 1x values once at
    # the point of use) -- doubling every term in an already-verified
    # non-overlapping, safe-margin relationship can't change its sign or
    # introduce a new overlap/exposure that wasn't already ruled out at
    # 1x, so the pool itself doesn't need a separate 2x copy.
    art_slot = ART_SLOT * scale
    tinted = filter.Hue(child = _glitch_shift(zoom, shift_x), change = hue_change)
    band = render.Padding(
        pad = (0, top, 0, max(0, art_slot - top - height)),
        child = render.Box(width = art_slot, height = height, child = tinted),
    )

    # render.Padding *grows* its child's declared size by the pad amount
    # rather than nudging content within a fixed frame -- without this
    # outer Box to clip it back down to exactly art_slot, the horizontal
    # shift above made this (and everything stacked with it) wider than
    # the art slot, bleeding into the text column next to it.
    return render.Box(width = art_slot, height = art_slot, child = band)

def _glitch_hold(child, duration, scale):
    # A no-op Transformation purely to pin a Sequence child's FrameCount
    # to `duration` ticks, so render.Sequence holds on it for that long
    # before advancing to the next child -- Sequence has no other way to
    # control how long a given child plays.
    #
    # This matters more than it looks: an earlier version of this
    # function "held" a state by appending the same widget reference to
    # the children list GLITCH_HOLD_TICKS times in a row instead of
    # wrapping it once in a duration-N _glitch_hold. That rendered fine
    # via plain `pixlet render` to a file (confirmed, pixel-diffed, a
    # clean alternating shift) but was reported as showing no jitter at
    # all in pixlet serve's live preview -- repeated-identical-children
    # apparently doesn't advance the same way every consumer of a
    # Sequence expects. Wrapping each state in its own _glitch_hold is
    # the original, proven-working pattern this app used before that
    # rewrite.
    return _hold_frame(child, duration, ART_SLOT * scale, ART_SLOT * scale)

def _hold_frame(child, duration, width, height):
    # The no-op Transformation behind _glitch_hold and the progress
    # marker's blink: pins a Sequence child to `duration` ticks at a fixed
    # width x height.
    return animation.Transformation(
        child = child,
        duration = duration,
        width = width,
        height = height,
        keyframes = [
            animation.Keyframe(percentage = 0.0, transforms = []),
            animation.Keyframe(percentage = 1.0, transforms = []),
        ],
    )

def _glitch_flicker_state(zoom, scale):
    # One randomized flicker Stack. Bands follow the old fixed-pool rules:
    # heights 2-4px, hue2 (magenta) 3-5px above hue1 (cyan), gap measured
    # edge-to-edge so band2 can't land inside band1. Values drawn at 1x and
    # scaled at the point of use (see _glitch_band). random.number requires
    # min >= 0, hence the "- 1" offsets for signed shifts.
    art_slot = ART_SLOT * scale
    top1 = random.number(0, ART_SLOT - 6)
    h1 = random.number(2, 4)
    shift1 = random.number(0, 4) - 2
    h2 = random.number(2, 4)
    gap = random.number(3, 5)
    top2 = max(0, top1 - h2 - gap)
    shift2 = random.number(0, 4) - 2

    # Capped to +-1px (1x) -- a full-frame shift reads very differently
    # than a thin band shifting, so it stays subtle.
    shift = (random.number(0, 2) - 1) * scale

    # Whole-frame tone + shade, re-rolled so a burst doesn't read as a
    # flat color cast. Hue wraps the already-clipped Box so only the art
    # (and the transparent margin a shift opens) is recolored.
    tint_hue = float(random.number(0, 2 * GLITCH_TINT_HUE_MAGNITUDE) - GLITCH_TINT_HUE_MAGNITUDE)
    shade_alpha = random.number(GLITCH_SHADE_ALPHA_MIN, GLITCH_SHADE_ALPHA_MAX)
    tinted = filter.Hue(
        child = render.Box(width = art_slot, height = art_slot, child = _glitch_shift(zoom, shift)),
        change = tint_hue,
    )
    shade = render.Box(width = art_slot, height = art_slot, color = "#000000" + _hex2(shade_alpha))

    return render.Stack(children = [
        tinted,
        _glitch_band(zoom, top1 * scale, h1 * scale, shift1 * scale, 150.0, scale),
        _glitch_band(zoom, top2 * scale, h2 * scale, shift2 * scale, -60.0, scale),
        shade,
    ])

def _glitch_burst_frames(zoom, segment_ticks, scale):
    # One Sequence child per GLITCH_HOLD_TICKS of an "on" segment. At 2x
    # every hold gets a fresh random state; at 1x unique visuals are
    # capped (GLITCH_1X_UNIQUE_FRAMES) and recycled so busy covers don't
    # encode dozens of near-unique frames into the Gen1 WebP budget.
    # Each hold still gets its own _glitch_hold wrapper -- repeating the
    # identical widget reference in a Sequence has been flaky in pixlet
    # serve before (see _glitch_hold).
    frame_count = max(1, segment_ticks // GLITCH_HOLD_TICKS)
    unique_count = frame_count if scale > 1 else min(frame_count, GLITCH_1X_UNIQUE_FRAMES)
    visuals = [_glitch_flicker_state(zoom, scale) for _ in range(unique_count)]
    return [
        _glitch_hold(visuals[i % unique_count], GLITCH_HOLD_TICKS, scale)
        for i in range(frame_count)
    ]

def _glitch_jitter(zoom, scale):
    # Built as a render.Sequence of discrete shifted states, each using
    # _glitch_shift (Padding-based), not animation.Transformation +
    # Translate -- Translate can't reveal content beyond what's visible at
    # rest and produced a confirmed-on-device black border. `zoom` is
    # _glitch_rest_art's static image, so Sequence rebasing the frame index
    # per child (which desynced the old live-zoom version) is harmless.
    art_slot = ART_SLOT * scale
    clean = render.Box(width = art_slot, height = art_slot, child = zoom)

    children = []
    for _ in range(GLITCH_REPEATS):
        for is_on, ms in GLITCH_PATTERN_MS:
            segment_ticks = ms * _GLITCH_TICKS_PER_SECOND // 1000
            if is_on:
                children.extend(_glitch_burst_frames(zoom, segment_ticks, scale))
            else:
                children.append(_glitch_hold(clean, segment_ticks, scale))

    return render.Sequence(children = children)

# Line count and spacing are derived from each other, not picked
# independently: the small-sawtooth sweep below only loops seamlessly
# when sweeping by exactly one full repeat-period of the line pattern,
# which only exists (as a *small* shift, not the full ART_SLOT) when
# SCANLINE_COUNT evenly divides ART_SLOT. 6 lines was tried first (an
# explicit skip-tuple dropping 2 of 8 period-4 positions) and looked
# uneven/inconsistent during the sweep -- traced to exactly this: with 2
# positions skipped, the pattern's true repeat period became the full 32
# (not 4), so shifting by 4 and snapping back no longer reproduced an
# identical-looking frame. 4 divides 32 cleanly (spacing/sweep = 8px);
# the only other clean option near the original density is 8 (spacing
# 4px, the original count). Confirmed separately (pixel-sampled test
# renders) that pixlet's Transformation+Translate can't reveal content
# beyond what's visible at rest -- shifting only moves already-visible
# pixels, it doesn't pull in new rows from an off-screen duplicate -- so
# a single large sweep (shifting by the full ART_SLOT, tried as an
# alternative to this small-sawtooth approach) isn't viable either;
# small periodic shifts are the only mechanism that actually works here.
SCANLINE_COUNT = 4

# Sized against the full show_static window (GLITCH_ACTIVE_SECONDS), not
# a fixed 8s -- it used to be a flat 160 ticks while GLITCH_ACTIVE_SECONDS
# only covered a short burst, which was fine since nothing animated past
# that burst anyway. Once GLITCH_ACTIVE_SECONDS was extended to cover the
# full window, this fell behind: animation.Transformation holds at its
# last keyframe once its own declared duration is up, so the scanline
# sweep visibly froze (while jitter/bands, sized against the full window,
# kept animating) for however much of the window was left after 8s.
# _SCANLINE_CYCLE_TICKS is kept fixed (same sweep speed as before) and
# SCANLINE_CYCLES derived from it, rather than the other way around, so
# extending the window doesn't also slow the sweep down.
_SCANLINE_CYCLE_TICKS = 20  # 1s per sawtooth cycle at the default 50ms/tick
SCANLINE_SWEEP_DURATION = GLITCH_ACTIVE_SECONDS * _GLITCH_TICKS_PER_SECOND
SCANLINE_CYCLES = SCANLINE_SWEEP_DURATION // _SCANLINE_CYCLE_TICKS

def _glitch_scanlines(scale):
    # Modeled on SUB/WAVE's own scanlines, which sweep continuously via
    # an animated `background-position-y` rather than sitting still.
    #
    # An earlier version tried a single large sweep across a buffer built
    # twice as tall as the art slot, pre-shifted with a *negative*
    # render.Padding so the pattern's middle 32 rows lined up with the
    # window at rest. That didn't work how a positive Padding (which
    # reliably *grows* a widget's declared size -- used elsewhere in this
    # file, e.g. _glitch_band) does; empirically it went blank partway
    # through instead of revealing new rows at the top, which is what
    # "scanlines disappearing at the bottom without regenerating at the
    # top" looked like.
    #
    # This avoids all of that: the buffer is only ONE extra
    # SCANLINE_SPACING taller than the art slot (the same small, proven-
    # safe oversized margin used everywhere else in this file -- e.g. the
    # zoom's own ART_SIZE vs. ART_SLOT), and instead of one big sweep it's
    # a repeating sawtooth -- ramp down by exactly one SCANLINE_SPACING,
    # then snap back to 0 and repeat. Since the pattern repeats every
    # SCANLINE_SPACING (see SCANLINE_COUNT above for why), a one-period
    # displacement looks identical to the starting position, so the snap
    # is invisible -- a standard infinite-scrolling-texture trick -- while
    # the translate distance never has to leave the small range already
    # confirmed safe.
    #
    # SCANLINE_SPACING is computed from the *scaled* art_slot (not a
    # fixed 1x constant) so it stays the true repeat period at either
    # resolution -- SCANLINE_COUNT=4 still divides it evenly (32/4=8 at
    # 1x, 64/4=16 at 2x), which is what the sweep's seamless loop depends
    # on (see the note above SCANLINE_COUNT for why that divisibility
    # matters). Each line is `scale` rows thick (not a fixed 1px), so the
    # line's own weight stays proportional to the bigger canvas too.
    art_slot = ART_SLOT * scale
    scanline_spacing = art_slot // SCANLINE_COUNT
    tall = art_slot + scanline_spacing
    lines = []
    for y in range(tall):
        if y % scanline_spacing < scale:
            lines.append(render.Box(width = art_slot, height = 1, color = "#00000080"))
        else:
            lines.append(render.Box(width = art_slot, height = 1, color = "#00000000"))
    pattern = render.Column(children = lines)

    # The ramp's end and the next cycle's snap-back share the exact same
    # percentage (a zero-duration jump), rather than the snap landing one
    # tick later -- that one-tick gap got linearly interpolated, which
    # for a single tick showed the pattern at a fractional, not-quite-0
    # offset instead of cleanly snapping, producing a brief flicker right
    # at the loop point.
    keyframes = []
    for cycle in range(SCANLINE_CYCLES):
        cycle_start = cycle * _SCANLINE_CYCLE_TICKS
        cycle_end = cycle_start + _SCANLINE_CYCLE_TICKS  # == next cycle's cycle_start
        keyframes.append(animation.Keyframe(
            percentage = float(cycle_start) / SCANLINE_SWEEP_DURATION,
            transforms = [animation.Translate(0, 0)],
        ))
        keyframes.append(animation.Keyframe(
            percentage = float(cycle_end) / SCANLINE_SWEEP_DURATION,
            transforms = [animation.Translate(0, scanline_spacing)],
            curve = "linear",
        ))

    sweeping = animation.Transformation(child = pattern, duration = SCANLINE_SWEEP_DURATION, keyframes = keyframes)
    return render.Box(width = art_slot, height = art_slot, child = sweeping)

def _glitch_corner_ticks(color, scale):
    tick_size = 5 * scale
    line_thickness = 1  # kept at a crisp 1px at every scale, per request, rather than growing to `scale`

    # A single tick shape (two short perpendicular lines) always draws
    # the same way regardless of which corner it's placed in -- it has no
    # idea it's "the top-right one". To make the bracket actually open
    # toward the image's center at every corner (not just top-left), each
    # line has to be explicitly pushed to the correct edge of its own
    # tick_size x tick_size box via Padding: the horizontal line to the
    # top or bottom, the vertical line to the left or right. Wrapped in an
    # outer Box for the same reason as _glitch_band -- Padding grows its
    # child's declared size, so without this the tick would be wider/
    # taller than tick_size.
    def tick(top_aligned, left_aligned):
        far_edge = tick_size - line_thickness
        h_line = render.Padding(
            pad = (0, 0 if top_aligned else far_edge, 0, far_edge if top_aligned else 0),
            child = render.Box(width = tick_size, height = line_thickness, color = color),
        )
        v_line = render.Padding(
            pad = (0 if left_aligned else far_edge, 0, far_edge if left_aligned else 0, 0),
            child = render.Box(width = line_thickness, height = tick_size, color = color),
        )
        return render.Box(width = tick_size, height = tick_size, child = render.Stack(children = [h_line, v_line]))

    art_slot = ART_SLOT * scale
    return render.Box(
        width = art_slot,
        height = art_slot,
        child = render.Column(
            main_align = "space_between",
            expanded = True,
            children = [
                render.Row(main_align = "space_between", expanded = True, children = [
                    tick(top_aligned = True, left_aligned = True),
                    tick(top_aligned = True, left_aligned = False),
                ]),
                render.Row(main_align = "space_between", expanded = True, children = [
                    tick(top_aligned = False, left_aligned = True),
                    tick(top_aligned = False, left_aligned = False),
                ]),
            ],
        ),
    )

def _glitch_effect(zoom, scale):
    art_slot = ART_SLOT * scale
    return render.Box(
        width = art_slot,
        height = art_slot,
        child = render.Stack(children = [
            _glitch_jitter(zoom, scale),
            _glitch_scanlines(scale),
            _glitch_corner_ticks("#00000080", scale),
        ]),
    )

def _message_screen(lines, colors):
    return render.Column(
        main_align = "center",
        cross_align = "center",
        expanded = True,
        children = [render.Text(line, font = "tom-thumb", color = colors["text"]) for line in lines],
    )

PROGRESS_MARKER_BLINK_TICKS = 10  # ~500ms per on/off state at the default 50ms/tick
PROGRESS_MARKER_BLINK_CYCLES = 20  # ~20s total -- covers the longest other animation in this file (GLITCH_ACTIVE_SECONDS=18s) with room to spare

def _progress_marker(width, height, color):
    # Blinks on/off at the filled/empty boundary -- a playhead marker for
    # "here's where playback actually is right now", not just the static
    # filled-vs-empty split. Built as a render.Sequence alternating an
    # opaque Box with a fully transparent one (not alternating between
    # two opaque colors), so it reads as a clean on/off blink regardless
    # of what's underneath, via Stack rather than needing to match
    # whichever of accent/bar_empty the marker happens to sit on.
    #
    # render.Sequence doesn't loop on its own (same fact this file
    # already leans on for the glitch jitter/scanlines), so the on/off
    # pattern is spelled out for PROGRESS_MARKER_BLINK_CYCLES repeats
    # rather than relying on any runtime looping -- 20s was picked to
    # comfortably cover this file's other longest-running animation
    # (the glitch window) rather than visibly going static mid-render.
    on_state = _hold_frame(render.Box(width = width, height = height, color = color), PROGRESS_MARKER_BLINK_TICKS, width, height)
    off_state = _hold_frame(render.Box(width = width, height = height, color = "#00000000"), PROGRESS_MARKER_BLINK_TICKS, width, height)
    children = []
    for _ in range(PROGRESS_MARKER_BLINK_CYCLES):
        children.append(on_state)
        children.append(off_state)
    return render.Sequence(children = children)

def _progress_bar(fraction, colors, width = 32, height = 2):
    filled = int(width * fraction + 0.5)
    filled = max(0, min(filled, width))
    children = []
    if filled > 0:
        children.append(render.Box(width = filled, height = height, color = colors["accent"]))
    if filled < width:
        children.append(render.Box(width = width - filled, height = height, color = colors["bar_empty"]))
    bar = render.Row(children = children)

    # Marker is centered on the fill boundary, clamped so it never pokes
    # outside the bar's own width (e.g. at 0% or 100% progress, where a
    # naively-centered marker would hang half off one edge).
    marker_width = min(2, width)
    marker_x = max(0, min(filled - marker_width // 2, width - marker_width))
    marker = render.Padding(
        pad = (marker_x, 0, width - marker_x - marker_width, 0),
        child = _progress_marker(marker_width, height, colors["text"]),
    )

    return render.Stack(children = [
        render.Box(width = width, height = height, child = bar),
        render.Box(width = width, height = height, child = marker),
    ])

def _fetch_now_playing(station_url):
    rep = http.get(station_url + "/api/now-playing", ttl_seconds = NOWPLAYING_TTL)
    if rep.status_code != 200:
        return None

    data = json.decode(rep.body(), None)
    if type(data) != "dict":
        return None

    # `.get(key, {})` only falls back to the default when the key is
    # *absent* -- SUB/WAVE sends these as explicit JSON null (e.g.
    # activeShow between scheduled shows), which decodes to Starlark None
    # and passes right through .get(), so `or {}` is needed too.
    np = data.get("nowPlaying", {}) or {}
    dj = data.get("dj", {}) or {}
    context = data.get("context", {}) or {}
    active_show = context.get("activeShow", {}) or {}

    return {
        "title": np.get("title", "Unknown title"),
        "artist": np.get("artist", "Unknown artist"),
        "subsonic_id": np.get("subsonic_id", ""),
        "duration": np.get("duration", 0),
        # Unix seconds when this track went on air (SUB/WAVE). Used for
        # the progress bar -- see _track_progress. Absent/null on older
        # station builds; those fall back to a cache stamp.
        "started_at": np.get("timestamp", None),
        "station": dj.get("station", "SUB/WAVE"),
        "show": active_show.get("name", ""),
        "host": dj.get("name", ""),
        "time_temp": _format_time_temp(context.get("clock", {}) or {}, context.get("weather", {}) or {}),
        "album_year": _format_album_year(np.get("album", ""), np.get("year", None)),
        "track_length": _format_track_length(np.get("duration", 0)),
        "bpm": _format_bpm(np.get("bpm", None)),
        "online": bool(data.get("streamOnline", False)),
        "listeners": _format_listeners(data.get("listeners", None)),
    }

def _format_listeners(listeners):
    # Top-level `listeners` on /api/now-playing is an object,
    # {"current": n, "peak": n} (SUB/WAVE's StreamStatus) -- not the bare
    # number its connect-catalog sample shows. A bare number is still
    # accepted. Empty string (badge hidden) when absent/null/unparseable/
    # zero, e.g. an older station build or an empty room.
    if type(listeners) == "dict":
        listeners = listeners.get("current", None)
    if type(listeners) not in ["int", "float"]:
        return ""
    count = int(listeners)
    if count <= 0:
        return ""
    return str(count)

# 5x5 headphones glyph, 1px per cell. Drawn at 1px even at 2x because
# tom-thumb itself isn't scaled up there.
LISTENER_ICON_ROWS = [
    ".###.",
    "#...#",
    "#...#",
    "##.##",
    "##.##",
]

def _listener_badge(listeners, color):
    icon_rows = []
    for row in LISTENER_ICON_ROWS:
        cells = []
        for ch in row.elems():
            cells.append(render.Box(width = 1, height = 1, color = color if ch == "#" else "#00000000"))
        icon_rows.append(render.Row(children = cells))
    return render.Row(
        cross_align = "center",
        children = [
            render.Column(children = icon_rows),
            render.Box(width = 1, height = 1),
            render.Text(listeners, font = "tom-thumb", color = color),
        ],
    )

def _listener_badge_width(listeners):
    # icon + gap (1px) + text, text width estimated like the other
    # tom-thumb width estimates in this file.
    return len(LISTENER_ICON_ROWS[0]) + 1 + _estimate_text_width(listeners)

def _format_album_year(album, year):
    parts = []
    if album:
        parts.append(album)
    if year:
        parts.append(str(int(year)))
    return " · ".join(parts)

def _format_track_length(duration):
    if not duration:
        return ""
    total = int(duration)
    minutes = total // 60
    seconds = total % 60
    secs_str = "0" + str(seconds) if seconds < 10 else str(seconds)
    return str(minutes) + ":" + secs_str

def _format_bpm(bpm):
    if not bpm:
        return ""
    return str(int(bpm + 0.5)) + " bpm"

def _format_time_temp(clock, weather):
    parts = []
    display_time = clock.get("display", "")
    if display_time:
        parts.append(display_time)

    temp = weather.get("temp", None)
    unit = weather.get("tempUnit", "")
    if temp != None:
        parts.append("%d°%s" % (int(temp), unit))

    return " · ".join(parts)

# SUB/WAVE themes are plain CSS custom properties, not just a fixed set of
# 8 preset ids: an operator can add their own theme JSON with arbitrary
# token values (controller/src/themes.ts loads built-ins from a bundled
# dir *plus* optional files from ${STATE_DIR}/themes/), so a theme named
# e.g. "cyberpunk" on one station isn't guaranteed to be *this app's*
# hardcoded COLOR_SCHEMES["cyberpunk"] hex values. /api/themes exposes
# the real, currently-in-effect token values directly, so _fetch_show_colors
# below reads those instead of mapping a theme id to our own guess.
#
# Token values aren't all plain hex, though -- surveyed every token across
# every theme on the live test station and found three formats in use:
# "#rrggbb", "oklch(L C H)", and "color-mix(in oklab, COLOR1 P1%, COLOR2)"
# (where COLOR1/COLOR2 can themselves be hex or oklch, nested). The oklch
# <-> sRGB math below (and the inverse, hex -> OKLab, needed to mix a hex
# color against an oklch one) is the standard CSS Color 4 / Bjorn Ottosson
# OKLab conversion -- verified two ways before trusting it: round-tripping
# hex -> OKLab -> hex returned the exact original hex for several colors,
# and converting oklch(L C H) for pure red/green/blue/white against their
# well-known reference hex values matched exactly. The color-mix outputs
# were cross-checked against an independent Python implementation of the
# same formulas and matched exactly too.
PI = 3.14159265358979

def _clamp01(x):
    return max(0.0, min(1.0, x))

def _hex2(n):
    # Starlark's %-formatting has no %02x width specifier, so pad by hand.
    s = "%x" % n
    return "0" + s if len(s) < 2 else s

def _normalize_station_url(url):
    # Trim whitespace, add https:// when the scheme is missing, strip a
    # trailing slash. Empty / whitespace-only / embedded spaces stay empty
    # so main() can show the "Set station URL" screen instead of letting
    # http.get raise on a malformed host (Starlark has no try/except).
    if not url:
        return ""
    url = url.strip()
    if not url or " " in url:
        return ""
    if "://" not in url:
        url = "https://" + url
    return url.rstrip("/")

def _srgb_to_linear(c):
    if c <= 0.04045:
        return c / 12.92
    return math.pow((c + 0.055) / 1.055, 2.4)

def _linear_to_srgb(c):
    c = _clamp01(c)
    if c <= 0.0031308:
        return c * 12.92
    return 1.055 * math.pow(c, 1.0 / 2.4) - 0.055

def _rgb01_to_hex(r, g, b):
    ri = int(_clamp01(r) * 255 + 0.5)
    gi = int(_clamp01(g) * 255 + 0.5)
    bi = int(_clamp01(b) * 255 + 0.5)
    return "#" + _hex2(ri) + _hex2(gi) + _hex2(bi)

def _linear_rgb_to_oklab(r, g, b):
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l_ = math.pow(l, 1.0 / 3.0) if l >= 0 else -math.pow(-l, 1.0 / 3.0)
    m_ = math.pow(m, 1.0 / 3.0) if m >= 0 else -math.pow(-m, 1.0 / 3.0)
    s_ = math.pow(s, 1.0 / 3.0) if s >= 0 else -math.pow(-s, 1.0 / 3.0)
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    A = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    B = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    return (L, A, B)

def _oklab_to_linear_rgb(L, A, B):
    l_ = L + 0.3963377774 * A + 0.2158037573 * B
    m_ = L - 0.1055613458 * A - 0.0638541728 * B
    s_ = L - 0.0894841775 * A - 1.2914855480 * B
    l = l_ * l_ * l_
    m = m_ * m_ * m_
    s = s_ * s_ * s_
    r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    bb = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return (r, g, bb)

def _oklab_to_hex(L, A, B):
    r, g, b = _oklab_to_linear_rgb(L, A, B)
    return _rgb01_to_hex(_linear_to_srgb(r), _linear_to_srgb(g), _linear_to_srgb(b))

def _oklch_to_oklab(l, c, h_deg):
    h_rad = h_deg * PI / 180.0
    return (l, c * math.cos(h_rad), c * math.sin(h_rad))

def _rgb255_to_oklab(r, g, b):
    return _linear_rgb_to_oklab(_srgb_to_linear(r / 255.0), _srgb_to_linear(g / 255.0), _srgb_to_linear(b / 255.0))

def _find_top_level_comma(s):
    # First comma not nested inside parens -- splits color-mix's two
    # "COLOR PERCENT%" segments. A nested oklch(...) has no commas
    # (space-separated), but rgb(...)/rgba(...) does, so this has to
    # track paren depth rather than just split(",").
    depth = 0
    for i in range(len(s)):
        ch = s[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            return i
    return -1

HEX_DIGITS = "0123456789abcdefABCDEF"

def _parse_number(s):
    # float() with no try/except would abort the whole render on bad input,
    # so validate first: optional sign, digits, at most one ".". Returns
    # None when s isn't a plain decimal number.
    s = s.strip()
    body = s[1:] if s.startswith("-") or s.startswith("+") else s
    if not body or body == "." or body.count(".") > 1:
        return None
    for ch in body.elems():
        if ch != "." and not ch.isdigit():
            return None
    return float(s)

def _parse_css_number(s, percent_scale):
    # A CSS channel value: a plain number, or N% (meaning N/100 *
    # percent_scale), or "none" (treated as 0). None when unparseable.
    s = s.strip()
    if s == "none":
        return 0.0
    if s.endswith("%"):
        n = _parse_number(s[:-1])
        return None if n == None else n * percent_scale / 100.0
    return _parse_number(s)

def _parse_hex(hex_str):
    # #rgb, #rgba, #rrggbb, or #rrggbbaa (no leading "#") -> (r, g, b, a)
    # as 0-255 ints, or None for any other length or a non-hex digit.
    for ch in hex_str.elems():
        if ch not in HEX_DIGITS:
            return None
    if len(hex_str) in (3, 4):
        hex_str = "".join([ch + ch for ch in hex_str.elems()])
    if len(hex_str) == 6:
        hex_str += "ff"
    if len(hex_str) != 8:
        return None
    return tuple([int(hex_str[i:i + 2], 16) for i in (0, 2, 4, 6)])

def _split_alpha(inner):
    # Modern CSS syntax puts alpha after a slash: "L C H / A". Returns
    # (channels, alpha), with alpha 1.0 when absent and None if unparseable.
    if "/" not in inner:
        return inner, 1.0
    channels, alpha_str = inner.split("/", 1)
    return channels, _parse_css_number(alpha_str, 1.0)

def _parse_color_token(s):
    # Returns (L, A, B, alpha) in OKLab + a 0-1 alpha. Returns None on
    # unrecognized / malformed tokens -- Starlark has no try/except, so
    # every numeric conversion is validated first and callers treat None
    # as "fall back" rather than letting fail() take down the whole render.
    if type(s) != "string" or not s:
        return None
    s = s.strip()
    if s.startswith("#"):
        rgba = _parse_hex(s[1:])
        if rgba == None:
            return None
        r, g, b, a = rgba
        L, A, B = _rgb255_to_oklab(r, g, b)
        return (L, A, B, a / 255.0)
    if s.startswith("oklch(") and s.endswith(")"):
        channels, alpha = _split_alpha(s[len("oklch("):-1])
        parts = channels.split()
        if len(parts) < 3 or alpha == None:
            return None
        hue = parts[2][:-len("deg")] if parts[2].endswith("deg") else parts[2]

        # Per CSS Color 4: L 100% = 1.0, C 100% = 0.4.
        l = _parse_css_number(parts[0], 1.0)
        c = _parse_css_number(parts[1], 0.4)
        h = _parse_css_number(hue, 0.0) if not hue.endswith("%") else None
        if l == None or c == None or h == None:
            return None
        L, A, B = _oklch_to_oklab(l, c, h)
        return (L, A, B, alpha)
    if (s.startswith("rgba(") or s.startswith("rgb(")) and s.endswith(")"):
        inner = s[s.index("(") + 1:-1]
        if "," in inner:
            parts = [p.strip() for p in inner.split(",")]
            alpha = _parse_css_number(parts[3], 1.0) if len(parts) > 3 else 1.0
        else:
            channels, alpha = _split_alpha(inner)
            parts = channels.split()
        if len(parts) < 3 or alpha == None:
            return None
        rgb = [_parse_css_number(p, 255.0) for p in parts[0:3]]
        if None in rgb:
            return None
        L, A, B = _rgb255_to_oklab(rgb[0], rgb[1], rgb[2])
        return (L, A, B, alpha)
    if s.startswith("color-mix(") and s.endswith(")"):
        inner = s[len("color-mix("):-1]
        after_space = inner[len("in oklab,"):].strip() if inner.startswith("in oklab,") else inner
        split_at = _find_top_level_comma(after_space)
        if split_at < 0:
            return None
        seg1 = after_space[:split_at].strip()
        seg2 = after_space[split_at + 1:].strip()

        # -> (color, pct) with pct None when the segment has no
        # percentage, or None overall when the segment is malformed.
        def _split_color_pct(seg):
            if not seg:
                return None
            if seg.endswith("%"):
                if " " not in seg:
                    return None
                last_space = seg.rindex(" ")
                pct = _parse_number(seg[last_space + 1:-1])
                if pct == None:
                    return None
                return (seg[:last_space].strip(), pct)
            return (seg, None)

        split1 = _split_color_pct(seg1)
        split2 = _split_color_pct(seg2)
        if split1 == None or split2 == None:
            return None
        color1, pct1 = split1
        color2, pct2 = split2
        if pct1 == None and pct2 == None:
            pct1 = 50.0
        elif pct1 == None:
            pct1 = 100.0 - pct2
        c1 = _parse_color_token(color1)
        c2 = _parse_color_token(color2)
        if c1 == None or c2 == None:
            return None
        L1, A1, B1, Alpha1 = c1
        L2, A2, B2, Alpha2 = c2
        t = pct1 / 100.0
        return (
            L1 * t + L2 * (1 - t),
            A1 * t + A2 * (1 - t),
            B1 * t + B2 * (1 - t),
            Alpha1 * t + Alpha2 * (1 - t),
        )
    return None

def _token_to_hex(s):
    # 8-digit #rrggbbaa when the token isn't fully opaque (e.g. --line is
    # usually a translucent rgba in SUB/WAVE's own themes), matching the
    # alpha-hex format already used elsewhere in this file (e.g. the
    # corner ticks' "#00000080") rather than flattening semi-transparent
    # tokens to an opaque color that wouldn't match the station's own site.
    # None when the token can't be parsed -- _fetch_show_colors then
    # abandons the show theme entirely.
    parsed = _parse_color_token(s)
    if parsed == None:
        return None
    L, A, B, alpha = parsed
    hex6 = _oklab_to_hex(L, A, B)
    if alpha >= 1.0:
        return hex6
    return hex6 + _hex2(int(_clamp01(alpha) * 255 + 0.5))

def _fetch_show_colors(station_url):
    rep = http.get(station_url + "/api/themes", ttl_seconds = NOWPLAYING_TTL)
    if rep.status_code != 200:
        return None

    data = json.decode(rep.body(), None)
    if type(data) != "dict" or data.get("activeSource", "") != "show":
        return None

    active_id = data.get("active", "")
    theme = None
    for t in data.get("themes", []) or []:
        if type(t) == "dict" and t.get("id", "") == active_id:
            theme = t
            break
    if theme == None:
        return None

    tokens = theme.get("tokens", {}) or {}
    if type(tokens) != "dict":
        return None
    required = ("--bg", "--ink", "--accent", "--muted", "--line", "--surface")
    if not all([k in tokens for k in required]):
        return None

    mapped = {
        "background": _token_to_hex(tokens["--bg"]),
        "text": _token_to_hex(tokens["--ink"]),
        "accent": _token_to_hex(tokens["--accent"]),
        "meta": _token_to_hex(tokens["--muted"]),
        "separator": _token_to_hex(tokens["--line"]),
        "bar_empty": _token_to_hex(tokens["--surface"]),
    }
    for value in mapped.values():
        if value == None:
            return None
    return mapped

def _fetch_cover(station_url, subsonic_id):
    if not subsonic_id:
        return None
    rep = http.get(station_url + "/api/cover/" + subsonic_id, ttl_seconds = COVER_TTL)
    if rep.status_code != 200:
        return None
    return rep.body()

# Progress = now - track start, against duration.
#
# Prefer nowPlaying.timestamp from the API (unix seconds when the track
# went on air) -- that advances correctly on every render with no cache,
# including mid-join and one-shot `pixlet render`. The older approach of
# stamping first-seen time into pixlet's cache stayed at 0% whenever the
# cache didn't persist across renders (common depending on server setup).
# Cache stamp remains only as a fallback for older stations that omit
# timestamp.
def _track_progress(subsonic_id, duration, started_at):
    if not duration:
        return None

    now_unix = time.now().unix
    start_unix = None

    if type(started_at) in ["int", "float"] and started_at > 0:
        start_unix = int(started_at)

        # Defensive: some SUB/WAVE fields are epoch ms; timestamp is
        # seconds, but if a build ever sent ms this still works.
        if start_unix > 10000000000:
            start_unix = start_unix // 1000
    elif subsonic_id:
        key = "subwave_track_start_" + subsonic_id
        cached = cache.get(key)
        if cached == None:
            cache.set(key, str(now_unix), ttl_seconds = int(duration) + 30)
            start_unix = now_unix
        else:
            start_unix = int(cached)

    if start_unix == None:
        return None

    elapsed = max(0, now_unix - start_unix)
    remaining = max(0, int(duration) - elapsed)
    fraction = min(1.0, float(elapsed) / float(duration))

    return {"elapsed": elapsed, "remaining": remaining, "fraction": fraction}

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "station_url",
                name = "Station URL",
                desc = "Base URL of your SUB/WAVE station, e.g. https://radio.example.com",
                icon = "server",
                default = DEFAULT_STATION_URL,
            ),
            schema.Dropdown(
                id = "color_scheme",
                name = "Color scheme",
                desc = "Matches SUB/WAVE's own web UI themes -- pick the one your station uses.",
                icon = "palette",
                default = DEFAULT_COLOR_SCHEME,
                options = [
                    schema.Option(display = "Cyberpunk", value = "cyberpunk"),
                    schema.Option(display = "Blueprint", value = "blueprint"),
                    schema.Option(display = "Classic Dark", value = "classic_dark"),
                    schema.Option(display = "Classic Light", value = "classic_light"),
                    schema.Option(display = "Flare", value = "flare"),
                    schema.Option(display = "Recon", value = "recon"),
                    schema.Option(display = "Signal", value = "signal"),
                    schema.Option(display = "Vinyl", value = "vinyl"),
                ],
            ),
            schema.Dropdown(
                id = "zoom_level",
                name = "Album art zoom",
                desc = "How far the album art zooms in during its breathing effect.",
                icon = "magnifyingGlass",
                default = DEFAULT_ZOOM_LEVEL,
                options = [
                    schema.Option(display = "Off", value = "off"),
                    schema.Option(display = "Subtle", value = "subtle"),
                    schema.Option(display = "Moderate", value = "moderate"),
                    schema.Option(display = "Strong", value = "strong"),
                ],
            ),
            schema.Dropdown(
                id = "zoom_position",
                name = "Zoom position",
                desc = "Where the album art zoom centers on.",
                icon = "crosshairs",
                default = DEFAULT_ZOOM_POSITION,
                options = [
                    schema.Option(display = "Center", value = "center"),
                    schema.Option(display = "Random", value = "random"),
                ],
            ),
            schema.Dropdown(
                id = "static_overlay",
                name = "Static overlay",
                desc = "Show a brief TV-static effect over the album art as a track starts and ends.",
                icon = "tv",
                default = DEFAULT_STATIC_OVERLAY,
                options = [
                    schema.Option(display = "On", value = "on"),
                    schema.Option(display = "Off", value = "off"),
                ],
            ),
        ],
    )
