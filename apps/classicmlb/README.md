# Classic MLB

A Tidbyt-inspired 64×32 baseball scoreboard, created by cdadamo with OpenAI Codex. Defaults to Philadelphia; choose any MLB team and your IANA time zone in settings.

Pregame shows the start time, padded team logos, secondary-color abbreviations, and the selected team's division standings ticker. Games today use START with no AM/PM; future games show their weekday. Live games show scores, occupied bases, inning direction, ball/strike count and two out boxes. Final and postponed/canceled/suspended states have their own views. Numeric values are normalized to avoid decimal suffixes.

No API key or companion service is required. Data and logos come from ESPN; division standings come from MLB StatsAPI. Phillies alternate logo comes from FOX Sports. This independent fan project is not affiliated with MLB, any team, ESPN, FOX, Tidbyt, Tronbyt or OpenAI.

## Settings

- Choose your team (Philadelphia by default) and time zone (`America/New_York` by default).
- Normal rotation: render interval **0 minutes**, display time **10 seconds**, Autopin **OFF**.
- Optional game focus: install a second copy with the same team/time zone, select **Postseason focus** or **All-game focus**, and enable **Autopin** on that copy only. Focus includes inning breaks and reported delays, ends at final, and has a six-hour bound from scheduled start. The normal copy continues to show final scores. Disable the focus copy to stop takeover.

This standalone catalog version does not include the home server's persistent feed cache or 15-minute final-score takeover. Network/render failures can interrupt focus. The feed is cached for 10 seconds during live lookup, but provider and device timing add delay. This is not a guarantee of a 10-second display update. Schedules refresh every minute and standings every 15 minutes. The app prioritizes a live game, then an upcoming game; it can show a recent final when no upcoming game is listed. Native 128×64 artwork is not included.

The Philadelphia layout was reviewed during live games on physical displays. The portable team-selection version is a beta. Report bugs at [Tronbyt apps Issues](https://github.com/tronbyt/apps/issues), mentioning Classic MLB, team, game/date, and what was wrong. Do not include credentials or private server details.
