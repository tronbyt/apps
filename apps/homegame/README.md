# HomeGame Applet

Shows your college football team's next game with a home/away indicator.
Targets a 64x32 Tronbyt device (Tidbyt Gen1/Gen2, Tronbyt S3).

## Features

- Next scheduled game for any team ESPN covers, chosen from a search box
- Always shows the matchup as `YOUR TEAM vs OPPONENT`
- Colour-coded band for where *your* team is playing:
  - **RED** for home games
  - **GREEN** for away games
- Kickoff date and time, or a countdown once it's game day
- **"IN PROGRESS"** while the game is being played
- Follows the device's timezone automatically on Tronbyt
- Caches ESPN responses for 5 minutes; time-sensitive values are recomputed every render

## Configuration

- **Team** — type a few letters and pick from the list. Every division ESPN
  carries is searchable, not just FBS. Defaults to Texas A&M until you choose.
- **Timezone** — leave on *Follow the device*; pick a zone only to override

The timezone is a dropdown rather than a text box on purpose. `in_location`
raises on a zone it doesn't recognise and Starlark cannot catch that, so a
single mistyped name used to take the whole render down. `resolve_timezone`
also treats the dropdown's own list as an allow-list, so a value left behind
by an older install or edited by hand is ignored rather than fatal.

The picker is a `schema.Typeahead`, so it stores `{"display": ..., "value": ...}`
as JSON. A bare team id is accepted too, which is what makes
`pixlet render homegame.star team=251` work during development. The `team_id`
field this app used before the picker existed is still read, so installs that
predate it keep working.

## API

ESPN's unofficial college football API:

- Teams: `.../college-football/teams/{team_id}`
- Fallback: `.../scoreboard?dates=YYYYMM`, this month and next, used when the
  team payload has no `nextEvent`. A `YYYYMMDD-YYYYMMDD` range is **not**
  accepted here — the endpoint answers 400 whatever the span — and the events
  come back in no particular order, so the app picks the earliest kickoff
  still ahead of it rather than the first match in the list.
- Team search: `.../college-football/teams?limit=1000`, fetched once a day and
  filtered in the app

The scoreboard only ever covers FBS, with or without `groups=80`. A smaller
division team whose payload has no `nextEvent` therefore has no second source,
and the app says so with **No game** instead of blanking the panel.

## Display layout

```
+----------------------------+
| TA&M      vs      SC       | <- matchup (white)
+----------------------------+
| [RED/GREEN]  HOME/AWAY     | <- status band
+----------------------------+
| 2h 29m          2:00 PM    | <- game day: countdown (yellow) + kickoff (white)
|            OR              |
| Nov 7            2:00PM    | <- not game day: date + kickoff (both white)
|            OR              |
| IN PROGRESS                | <- during the game (yellow)
+----------------------------+
```

The matchup row (8px), the two spacers (2+2px) and the status band (12px) take 24 of the
32 rows, so exactly one 8px line is left. Every state fits onto that single row.

Team labels are capped at five characters. ESPN's abbreviations run to nine outside FBS,
which overflowed the row and cut the opponent in half — `GRANDVIEW vs FAULKNER` rendered
as `GRANDVIEW vs F`. Five is measured rather than guessed: the widest real pairing at
that length sits flush against the edge with every glyph intact.

## States

1. **Upcoming** — kickoff is on a later calendar day: date on the left, kickoff time on
   the right. The AM/PM space is dropped here so the widest pairings (`Sep 13` +
   `12:00 PM`) keep a visible gap.
2. **Countdown** — kickoff is today and hasn't happened: `Xh Ym` on the left, kickoff
   time on the right. Holds at `0m` if kickoff passes before ESPN flips the status.
3. **In progress** — ESPN reports the game as live: `IN PROGRESS`. This outranks the
   countdown, which would otherwise claim every kickoff falling on today's date.
4. **Final** — the game has been played: `FINAL` in grey. ESPN usually advances
   `nextEvent` within the hour, but until it does there is no kickoff left to count
   down to; without this state the panel sat at `0m` until midnight.
5. **Postponed / Canceled** — `POSTPONED` or `CANCELED` in amber. These arrive as the
   same `post` state as a finished game, so they are separated out by status name.
6. **No game** — ESPN answered but the team has nothing scheduled: `NO GAME` in amber
   over a wrapped line. This is the off-season display, so it is a normal state, and
   amber rather than red because nothing is wrong.
7. **Unreachable** — ESPN could not be reached at all: `main` returns `[]`, so the app
   sits the cycle out instead of holding the panel on a failure the viewer cannot fix.
   A team that simply has nothing scheduled is **not** this state — it is state 6.

"Game day" means the same calendar day as kickoff in the display timezone, not a
rolling 24-hour window.

## Refresh interval

`recommendedInterval: 1`, where most sports apps in the community repo use 5. The
countdown is displayed in minutes, so a 5-minute cycle would leave it visibly stale.
This costs no extra traffic: ESPN responses are cached for 5 minutes either way, and
only the countdown is recomputed from the clock on the cycles in between.

## Development

```bash
pixlet serve homegame.star --port 81       # live preview at http://localhost:81
pixlet check homegame.star                 # format + lint + manifest
pixlet render -z 9 homegame.star -o homegame.webp
```

Tronbyt pins pixlet to the version in the apps repo's `PIXLET_VERSION` (v0.55.0 at the
time of writing). Upstream Tidbyt pixlet has no `time.tz()`; the applet guards for that
and runs on both.
