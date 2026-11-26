# Retro Phillies (beta)

Animated Phillies baseball for 64×32 Tronbyt displays: pitch locations, hits, runners, scoring names, and Phanatic inning breaks. Created by cdadamo with OpenAI Codex.

**Requires a separately installed companion service.** The complete source, Docker setup, limitations, and bug reports are at [cdadamo/retro-phillies](https://github.com/cdadamo/retro-phillies). No MLB account or API key is required by this implementation. This is an independent fan project.

After installing the companion, set its URL (normally `http://retro-phillies:8767`) and a unique Display ID in the app. Use a 0-minute render interval and 10-second display time. Leave Autopin OFF on the Normal rotation copy.

For focus, install a second copy with the same Display ID, select Postseason focus or All-game focus, and turn Autopin ON for that copy only. Disable it to turn off game focus. Phanatic inning breaks can be toggled independently.

Five-second feed polling does not remove provider and display latency. Animation is illustrative; not all plays can be replayed faithfully. The home version was tested during a live game; the portable package is an early beta.
