# Retro NFL

Classic 64×32 NFL scoreboard: select any team, see live scores, possession, timeouts, quarter/time, down-and-distance and field position, plus upcoming kickoff and division standings.

Defaults: Philadelphia, Eastern time, game-time focus on, and celebrations for either team. **My team only** is available in settings.

**Game-time focus and touchdown celebrations require a separately installed Retro NFL companion service.** Without it, this app is a normal rotating scoreboard; the companion settings have no effect. The companion requires local access to a Tronbyt 2.4.x SQLite data directory. [Companion source and installation instructions](https://github.com/cdadamo/retro-nfl#companion-setup-docker-on-the-existing-tronbyt-server).

For companion use, leave generic Autopin off. Render interval 0 allows refresh on every display request with 10-second live-feed caching; interval 1 is a conservative default. Feed and display timing determine actual latency.

Created by cdadamo with OpenAI Codex. Independent community project; not endorsed by OpenAI, NFL, ESPN, or Tronbyt. Team marks belong to their owners; data and logos come from ESPN. Screenshot illustrates the display layout.
