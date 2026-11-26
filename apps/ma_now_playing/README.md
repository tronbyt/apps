# Music Assistant Now Playing

Shows what a [Music Assistant](https://www.music-assistant.io/) player is playing: the cover, the title, the artist in a color from the cover, the playlist or album the song was started from, and a progress bar that runs while the app is on screen. Paused, the cover gets pause bars and the bar stops. With nothing playing or paused it shows a clock with the date, or skips its turn.

| Size      | Preview                               |
|-----------|---------------------------------------|
| **1x**    | ![1x](ma_now_playing.webp)            |
| **2x**    | ![2x](ma_now_playing@2x.webp)         |
| **64x64** | ![64x64](ma_now_playing@64x64.webp)   |

## Setup

1. In Music Assistant, open Settings → Profile and create a long-lived access token. Its user needs to be able to read players and queues.
2. Add the app and set:
   - **Music Assistant URL:** where your Tronbyt server reaches Music Assistant, like `http://192.168.1.10:8095`.
   - **Token:** the long-lived access token.
   - **Player:** a player's name or ID, or blank for whichever player is playing.
   - **Nothing playing:** Clock or Skip in rotation.
   - **24-hour clock:** on for 24-hour time.
3. Keep the app's render interval at 0 so it shows the current song each time it comes up.

The Tronbyt server must be able to reach Music Assistant, usually on the same network. If Music Assistant answers with an error, such as a rejected token or an unknown player, the clock shows it in red. If Music Assistant can't be reached, the app skips its turn.
