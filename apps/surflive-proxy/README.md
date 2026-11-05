# Surflive Proxy

Shows the current surf conditions for a surf spot, plus a short wave-height
forecast, identical in spirit to the [Surflive](../surflive) app, but routes
all Surfline API calls through a self-hosted [**proxy sidecar**](https://github.com/mpias670/tronbyt-proxy-sidecar) instead of
calling `services.surfline.com` directly.

## Why?

Surfline's API sits behind Cloudflare bot protection that blocks non-browser
HTTP clients (including `pixlet`'s `http.star`, even with spoofed browser
headers). This app instead talks to a small companion service — the
[`tronbyt-proxy-sidecar`](https://github.com/mpias670/tronbyt-proxy-sidecar) —
which handles the Cloudflare challenge (TLS fingerprinting, and an on-demand
headless-browser solve when necessary) and returns Surfline's plain JSON
response.

```
Surflive Proxy (pixlet)  --http-->  sidecar  --bypasses CF-->  Surfline API
```

## What it shows

The app cycles through two screens each render (4s each by default):

1. **Current conditions** — surf/swell height, period, and wind.
2. **Forecast** — max wave height per day for the next several days (5 by
   default; the underlying Surfline API returns more, but 5 columns is what
   comfortably fits a 64px-wide display).

## Setup

Deploy the sidecar **colocated with your tronbyt-server** (same Docker
Compose project/network) so the app can reach it by container name — see the
[sidecar README](https://github.com/mpias670/tronbyt-proxy-sidecar#readme) for
a compose example. Colocating avoids depending on a LAN IP and keeps the
proxy on the same private network as the server, with no host port needed.

In this app's config, set:

- **Proxy Sidecar URL** — base URL of the sidecar. Defaults to
  `http://tronbyt-sidecar:8080`, matching the container name in the compose
  example. Override this if you named the service differently or run it
  elsewhere (e.g. a LAN IP).
- **Proxy Auth Token** (optional) — must match the sidecar's configured
  `AUTH_TOKEN`, if set.
- **Spot ID** — the Surfline spot ID. Find it in the spot's surfline.com URL:
  `surfline.com/surf-report/<spot-name>/<spot-id>` — e.g. for
  `surfline.com/surf-report/pacific-beach/5842041f4e65fad6a7708841` the spot
  ID is `5842041f4e65fad6a7708841`.
- **Display Name** — freeform label shown on the screen (doesn't need to
  match Surfline's name for the spot).

## Config

- `proxy_url` — Base URL of the sidecar.
- `proxy_token` — Optional shared secret sent as the `X-Proxy-Token` header.
- `spot_id` — Surfline spot ID (see Setup above for how to find it).
- `spot_name` — Display name shown on screen.
- `use_wave_height` — Show surf height range instead of dominant swell height
  on the current-conditions screen (the forecast screen always shows max
  wave/surf height per day, independent of this toggle).
- `min_height` — Skip rendering entirely when current conditions are below
  this size.

## Why no spot search?

The original `surflive` app (and an earlier draft of this one) offered a
typeahead spot search backed by Surfline's `search/site` endpoint. In
practice this endpoint sits behind the same (or stricter) Cloudflare
protection as the forecast API, and Pixlet's `Typeahead` schema handler runs
at schema-render time without access to the in-progress config — so it can't
even use your configured `proxy_url`/`proxy_token`, only the sidecar's
default address with no auth. That combination made spot search unreliable
in practice, so this app instead asks for the spot ID directly (a one-time,
copy-paste lookup from the spot's Surfline URL) rather than shipping a
flaky/non-functional search box.
