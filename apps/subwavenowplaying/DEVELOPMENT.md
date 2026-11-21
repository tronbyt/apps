# Development notes

Design notes and history for `subwave_nowplaying.star`: why things are the
way they are, what was tried and dropped, and how to test. For what the app
does and how to configure it, see [README.md](README.md). The code itself
carries more detail in comments next to each piece.

## Dev/test

```
pixlet render subwave_nowplaying.star station_url=https://your-station.example.com
pixlet render -2 subwave_nowplaying.star station_url=https://your-station.example.com
pixlet serve subwave_nowplaying.star
pixlet lint subwave_nowplaying.star
pixlet check subwave_nowplaying.star
```

Render 2x from a folder that has `manifest.yaml` (with `supports2x: true`)
next to the `.star` file. Without it, Pixlet produces a 128x64 image that
was actually rendered at 1x and upscaled, which makes 2x payload sizes look
much smaller than they are.

### Calibration tool

`dev/calibration_test.star` (in the app's development repo, not shipped
with the app) renders a synthetic test grid (`dev/calibration.png` —
concentric color rings, corner markers, a crosshair) through the exact same
zoom logic as the real `_art_widget`, to visually check cropping without
depending on what a live station happens to be playing:

```
pixlet render dev/calibration_test.star -o calib.gif
```

At rest you should see a thin, *even* sliver of magenta on all four edges;
as it zooms in, each corner marker should get clipped by the same amount.
If one side loses noticeably more than the others, the zoom isn't
centered. Keep its copy of the zoom math in sync with `_art_widget` if that
ever changes.

## Album art zoom

Album art gets a slow "Ken Burns" breathing effect: starts and ends on the
full frame, easing in to a zoomed-in crop at the midpoint, on a continuous
~10s round-trip loop. Rendered oversized (36x36 vs. the 32x32 display slot,
just enough headroom for `animation.Scale` to have a visible effect) and
scaled *up only*, from 1.0 to the configured zoom amount, never below 1.0 —
scaling down was tried (to make the rest state reveal the literal whole
image, or to re-center an off-center crop) and both attempts produced a
real, on-device black border.

### Zoom position

Where the zoom centers on is controlled via `animation.Origin`, which works
correctly and does real work here — contrary to an earlier, mistaken belief
that it "had no effect" (that came from testing it set to its own default
value and comparing the result against itself, which is of course identical
either way). The "Random" zoom position picks from a handful of preset
off-center spots (`ZOOM_RANDOM_SPOTS`), kept modest (0.3-0.7 of the image's
own bounds, not the full 0.0-1.0 range) and verified safe (no black border,
even at the strongest 1.7x zoom) via the calibration tool; more extreme
corners weren't tested and may not be safe. Which spot is picked rotates on
a `ZOOM_SPOT_ROTATE_SECONDS` (10s) cadence based on wall-clock time
(`time.now().unix`), offset by a hash of `subsonic_id` so different tracks
don't all land on the same spot in the same 10s window. This was
deliberately *not* made purely per-track-stable: the ask was to see
different sections of a single piece of art over time, which requires the
spot to be able to change mid-playback, not just when the track changes.

### The abandoned Translate approach

An earlier version tried to fix a *different* problem — `animation.Scale`
zooming in asymmetrically toward one corner — by pairing Scale with a
*computed* `animation.Translate`, reasoning (wrongly) that Scale's default
pivot is the top-left corner. It isn't: pixlet's own docs say the default
origin is already the center. That Translate, sized assuming Scale had no
self-centering at all, overcorrected and visibly skewed the zoom toward the
*opposite* corner instead. It also introduced a periodic rendering "pop"
(confirmed with both WebP and GIF output, independent of zoom amplitude)
root-caused to pixlet's own source (`render/animation/translate.go`): a
Translate's x/y are rounded to the nearest whole pixel every frame by
default, while Scale never rounds, so a continuously-changing Scale
combined with a rounded Translate holds still for several frames and then
jumps a whole pixel at once. Since `animation.Origin` already does directly
and correctly what that Translate was clumsily approximating, the
Translate was removed entirely rather than patched further (e.g. with
`rounding = "none"`, which does fix the popping but wasn't needed once
Origin replaced it).

A *constant* Translate (`box_crop_bias`, the same value at every keyframe)
is still used, for a different reason: at the instants the zoom is at rest,
`render.Box`'s own crop of the oversized image isn't centered. A constant
value never changes frame to frame, so it can't cause the pop above.

### Why a loop, not a one-shot reveal, and why it's short

A one-way version looked jumpy in practice — since the app re-renders on
every refresh, a fresh render restarts its own animation from tick 0, so
whatever the *previous* pushed image happened to be showing gets abruptly
replaced. A loop that starts and ends in the same state doesn't eliminate
that restart, but makes it invisible — and keeping the round-trip short
(~10s) makes it far more likely a full cycle plays before the next refresh
cuts it off; a 60s version tried earlier only ever showed its outbound
half.

Considered using genuinely random per-frame content (like
`ormakers-tronbyt`'s LoRa segment, which pre-crops 60 frames directly from
a high-resolution *static* source photo via offline Pillow processing) for
a sharper zoom, but that technique doesn't transfer here: album art is
fetched live per-track at render time, and pixlet's Starlark sandbox has no
image-cropping/pixel-analysis capability at all (confirmed by checking its
full module list) — so there's no way to pre-bake or crop-at-render-time
from a source we don't have until the request hits the live station.

## Static overlay (glitch)

During the first `STATIC_OVERLAY_START_SECONDS` (5s) or last
`STATIC_OVERLAY_END_SECONDS` (22s) of a track, shows a chromatic-aberration
glitch over the album art as a transition cue: two duplicate,
differently-tinted copies of the *actual* art, each cropped to a shifting
horizontal band (RGB-split look), plus scanlines and viewfinder-style
corner tick marks. Loosely modeled on SUB/WAVE's own web UI, which does
something similar to its cover art on track change (found via its compiled
CSS/JS — not published anywhere as a spec, and the exact keyframe timing
past the first step wasn't visible in the minified output, so the on/off
burst pattern here, `GLITCH_PATTERN_MS`, and its randomized flicker frames
are original, in the same spirit rather than a reproduction of unseen
code).

The end window is wider than the start window on purpose: SUB/WAVE's
reported `duration` is the track's full metadata length, but the station
appears to crossfade to the next track a little before that, so a short
end window was rarely reached before the track changed.

Built from the live art via `filter.Hue`, not a bundled asset — pixlet's
`filter` module can recolor an arbitrary widget, so the glitch bands
reflect whatever's actually on screen. `render.Sequence` doesn't loop on
its own, so the burst pattern is spelled out for `GLITCH_ACTIVE_SECONDS`
(18s) up front; the scanline sweep runs for the same length, and the
corner ticks stay for the whole window. At 1x, only
`GLITCH_1X_UNIQUE_FRAMES` random flicker frames are generated and reused,
to keep busy covers under the Gen1 payload limit; 2x randomizes every
frame.

Went through two earlier, discarded designs before landing here, both
bundled pre-baked animated GIFs rather than working from the live art:
first sparse noise specks, then a version derived from a real "VHS glitch"
stock-footage clip (downloaded, downsampled, and thresholded for
transparency) — dropped because, even licensed as free-to-use, cropping it
down to 32x32 let recognizable footage content show through at any opacity
that read as an actual "band" rather than noise, and it compressed
noticeably worse than procedural noise. The live-`filter.Hue` version needs
no bundled asset at all, so the app stays a single-file upload.

## Marquee glitch

Pixlet's `render.Marquee` runs its own internal scroll-cycle animation, and
stacking several Marquees of different text lengths in one Root can
occasionally desync them — a line may briefly blank or show a garbled frame
while another Marquee is mid-cycle. This is a currently-unfixed pixlet bug
(there's an open `FIXME: Behaviour when children themselves are animated is
a bit weird` in pixlet's own widget docs), not something introduced by this
app. It's also not unique to this app: `tronbyt/apps/apps/goosefm/goose_fm.star`
stacks 3 Marquees for the same kind of now-playing info and shows the
identical occasional glitch on close frame-by-frame inspection. In practice
it's subtle enough to be easy to miss on a real, continuously-scrolling
display.

A custom hand-rolled scroll (via `animation.Transformation` + `Translate`,
avoiding `Marquee` entirely) was prototyped and could fully eliminate this,
but only by consolidating down to 2 scrolling lines total (title alone,
everything else combined into one line) — full independent lines for every
field was preferred instead, accepting the same minor quirk other
Tidbyt/Tronbyt apps already ship with.

## JSON nulls

SUB/WAVE sends some fields as explicit JSON `null` (e.g.
`context.activeShow` between scheduled shows) rather than omitting the key.
Starlark's `dict.get(key, default)` only falls back to `default` when the
key is *absent* — an explicit `null` (decoded to Starlark `None`) passes
straight through, so the app does `... or {}` on those lookups before
chaining another `.get()` off them, to avoid a `NoneType has no .get` crash.

## Progress bar

Elapsed time comes from `nowPlaying.timestamp` (unix seconds when the track
went on air) minus wall clock, over `duration`. That advances on every
render without needing pixlet's cache, including a one-shot
`pixlet render`. Older stations that omit `timestamp` fall back to a
first-seen cache stamp, which only works on a long-lived server with a
persistent cache (and a one-shot render then always sees the start of the
track).
