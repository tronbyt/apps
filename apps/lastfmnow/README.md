# Last.fm Now - Tidbyt/Tronbyt App

Display your current Last.fm scrobble on Tidbyt or Tronbyt.

![Last.fm Now screenshot](lastfmnow.webp)

## Features

- Shows your current "now playing" track from Last.fm
- Displays album art when available (with Last.fm icon fallback) ![Last.fm icon](images/lastfm_icon.png)
- Includes 4 layout presets (`preset1` through `preset4`)
- Supports configurable colors for song title, artist, and album text
- Optional clock display
- Optional hide mode when nothing is currently scrobbling
- Uses adaptive caching to reduce API calls and keep refreshes responsive
- Falls back to last successful track during temporary API errors, labeled `LAST SEEN`
- Supports standard and 2x rendering (`supports2x: true`)

## Requirements

- A Tidbyt or Tronbyt device
- A Last.fm account with scrobbling enabled
- A Last.fm API key

## Setup

### 1. Create a Last.fm API key

1. Sign in to Last.fm.
2. Go to [last.fm/api/account/create](https://www.last.fm/api/account/create).
3. Create an API account and copy the API key.

### 2. Configure app settings

| Field ID | Required | Description |
| --- | --- | --- |
| `username` | Yes | Your Last.fm username |
| `dev_api_key` | Yes | Your Last.fm API key |
| `showClock` | No | Show local time clock on the display |
| `now_playing_only` | No | Hide the app when not currently scrobbling |
| `color_song_title` | No | Song title text color |
| `color_artist_name` | No | Artist text color |
| `color_album_name` | No | Album text color |
| `layout` | No | Layout preset (`preset1`, `preset2`, `preset3`, `preset4`) |

## Local development (Pixlet)

Run from this app directory:

```bash
pixlet check lastfmnow.star
pixlet render lastfmnow.star
pixlet serve lastfmnow.star
```

For 2x testing:

```bash
pixlet render -2 lastfmnow.star
pixlet serve -2 lastfmnow.star
```

## Runtime behavior

- Fetches data from Last.fm `user.getrecenttracks` with `limit=1`
- Treats tracks as "now playing" only when Last.fm returns `@attr.nowplaying = "true"`
- Cache TTLs:
  - Now playing state: 15 seconds
  - Not playing state: 45 seconds
  - API error state: 45 seconds
  - Last successful now playing fallback: 24 hours
- On temporary API failures, the app can display the last successful track as stale data

## Files

- `lastfmnow.star`: main app logic and schema
- `manifest.yaml`: app metadata
- `images/`: app icons and branding assets

## References

- [Tidbyt developer docs](https://tidbyt.dev)
- [Last.fm API docs](https://www.last.fm/api)
