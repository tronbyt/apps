# subwave-nowplaying

Tronbyt/Tidbyt app showing what's playing on a [SUB/WAVE](https://github.com/perminder-klair/subwave)
internet radio station: the album art with a slow zoom, the track title
and artist, the current show and host, listener count, local time and
temperature, and a progress bar.

- **1x (64x32):** album art on the left; title, artist, show + host +
  listeners, and time/temperature scrolling on the right; progress bar
  along the bottom.
- **2x (128x64):** a larger title, plus an album/year line, host and
  listeners on their own row, and BPM and track length above the progress
  bar.

Not tied to any specific station — set your own station's base URL in the
app's config when adding it to a device.

Design notes, history and dev tools are in [DEVELOPMENT.md](DEVELOPMENT.md).

## Configuration

- **Station URL** — the base URL of your SUB/WAVE instance, e.g.
  `https://radio.example.com` (scheme optional — `https://` is assumed
  when missing; trailing slash stripped). No auth required — SUB/WAVE's
  now-playing and cover-art endpoints are public.
- **Color scheme** — matches SUB/WAVE's own web UI theme picker (Blueprint,
  Classic Dark, Classic Light, Cyberpunk, Flare, Recon, Signal, Vinyl), so
  the device can mirror your station's own site theme. Defaults to
  Cyberpunk. Each theme sets a background fill, the main text color
  (title/artist/show), an accent (host/DJ name + progress bar fill), and a
  muted color for the time/temp line. If the current show has its own
  theme on the station, that theme's colors are used instead.
- **Album art zoom** — how far the album art's breathing zoom effect goes
  in: Off, Subtle, Moderate (default), or Strong.
- **Zoom position** — where the zoom centers on: Center (default), or
  Random (a handful of preset off-center spots). The random spot changes
  every ~10s, so a long track shows off different parts of its art over
  time.
- **Static overlay** — On (default) or Off. When on, shows a brief
  chromatic-aberration glitch (RGB-split bands, scanlines, and corner tick
  marks) over the album art during the first 5s and last 22s of a track,
  as a transition cue.

## How it works

- `GET {station_url}/api/now-playing` — track, artist, album/year,
  duration, BPM, show, host, listener count, clock/weather, and stream
  status. Cached 20s.
- `GET {station_url}/api/cover/{subsonic_id}` — album art, proxied by
  SUB/WAVE itself (no Navidrome credentials needed). Cached 300s.
- `GET {station_url}/api/themes` — only used when the current show has its
  own theme; the station's CSS color tokens are converted to hex.
- If the station reports `streamOnline: false`, shows "<station> offline"
  instead of stale track info.
- If a track has no cover, or the cover fetch fails, the text uses the full
  width instead of showing a broken image.
- The progress bar uses the track's start time from the API
  (`nowPlaying.timestamp`), so it advances on every render. Older stations
  without it fall back to the first time the app saw the track.
- The album art zoom is a ~10s loop that starts and ends on the full frame,
  so each refresh picks up seamlessly.

**Errors:** HTTP errors (404, 500, …) and replies that aren't valid JSON
(e.g. a reverse proxy's error page) show "Can't reach station"; for the
theme endpoint, or a show theme with colors the app can't read, it just
falls back to the configured color scheme. If the host is completely
unreachable (DNS failure, connection refused), the render fails for that
cycle — Pixlet has no way to catch that.

**Known quirk:** with several scrolling lines of different lengths, Pixlet's
`Marquee` can occasionally blank or garble one line for a frame. It's a
Pixlet issue shared by other now-playing apps, and subtle on a real
display. See [DEVELOPMENT.md](DEVELOPMENT.md#marquee-glitch) for details.

## Payload size

Album art zoom and the glitch overlay are the expensive parts. Each zoom
frame is a different crop of the cover, so it can't be reused between
frames. Measured with Pixlet v0.55.1 against a detailed cover:

| | Mid-track | Glitch window (track start/end) |
|---|---|---|
| 1x, defaults | ~180KB | ~215KB |
| 2x, defaults | ~840KB | ~605KB |
| 2x, zoom Off | ~41KB | ~605KB |
| 2x, static overlay Off | ~840KB | ~840KB |
| zoom Off + static overlay Off (1x / 2x) | ~25KB / ~41KB | ~25KB / ~41KB |

1x stays under the ~460KB limit of stock Gen1 firmware. 2x has only been
tested on a device with firmware patched to allow more memory; stock
firmware on a 2x device may not handle payloads this large. If you hit
memory issues there, set **Album art zoom** to Off: that brings normal
playback down to ~41KB. The glitch window at track start/end still reaches
~605KB with zoom off, so if problems persist around track changes, set
**Static overlay** to Off as well.

## Install on your own server

Upload `subwave_nowplaying.star` directly through your Tronbyt server's
"Upload app" button on a device's Add App page (single file, no bundled
assets — no need to zip). Configure the Station URL field when adding it to
your device's schedule.

To upload as a zip instead (app + manifest):

```
zip subwave-nowplaying-app.zip subwave_nowplaying.star manifest.yaml
```

## Preview credits

The preview images (`subwavenowplaying.webp`, `subwavenowplaying@2x.webp`)
were rendered against a mock station:

- **Cover art:** *Wobble* by Black Market Karma, artwork by Stanley Belton,
  released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)
  ([Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Black_Market_Karma_-_Wobble.jpg)).
- **Song:** "Sonic Broth Soul Taster" by Black Market Karma, written by
  Stanley Belton, from *Wobble* (Fuzz Club Records, 2024). Only the title,
  artist, album, year and length appear; no audio is used.
- The show ("Late Night Drift"), host ("Nova"), listener count, time and
  temperature are made up.

Each preview is spliced from two real renders: the first 3 seconds of one
inside the track-start glitch window, then the rest of one just after it.
