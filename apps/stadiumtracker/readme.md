# Stadium Tracker

Every venue has a story. Start mapping yours.

Stadium Tracker turns your Tidbyt or compatible Tronbyt display into a colorful record of your sporting adventures.

From ballpark afternoons to arena nights and stadium road trips, mark the team venues you’ve visited and watch them light up across a compact map. The outline draws first, the league’s locations appear, and your selected stops shine in bright yellow before blinking into the spotlight.

Part travel journal, part sports bucket list, and part reminder that there’s always another great place to catch a game.

## Display Previews

### Standard Display — 64 × 32

The original compact map: a green outline, muted-yellow venue markers, and bright-yellow highlights for your selected visits.

![Stadium Tracker on a standard 64 × 32 display](stadiumtracker.webp)

### Wide 2× Display — 128 × 64

The wide version doubles the map coordinates and connects adjacent outline points for a more continuous silhouette.

Venue markers remain individual output pixels rather than becoming larger blocks. The league label also retains its compact font.

![Stadium Tracker on a wide 128 × 64 display](stadiumtracker@2x.webp)

### Square Display — 64 × 64

The square render retains the compact 64 × 32 map at the top of the taller canvas.

The current script does not vertically center or stretch the map to fill the square panel.

![Stadium Tracker on a square 64 × 64 display](stadiumtracker@64x64.webp)

## Features

- Five supported leagues — Track MLB, NBA, NFL, NHL, and MLS team venues.
- Personal visit checklists — Mark your selected stops in the app’s settings.
- Animated map outline — Watch the map take shape in a varying drawing order.
- League location markers — See the included venues for your selected league.
- Visited-location highlights — Selected entries appear in bright yellow over the muted markers.
- Blinking emphasis — Your selected locations blink during the completed-map sequence.
- Varied marker order — Changes how the initial venue markers appear between renders.
- Alphabetical team lists — Find checklist entries by team name, with venue names shown in their descriptions.
- League label — Identifies the selected league on the map.
- Bundled data — No accounts, API keys, or external sports-data feeds are required.

## Choose Your League

The app includes separate collections for:

| League | Collection |
| --- | --- |
| MLB | Major League Baseball |
| NBA | National Basketball Association |
| NFL | National Football League |
| NHL | National Hockey League |
| MLS | Major League Soccer |

Select a league to reveal its team checklist.

The app displays one league at a time. It does not automatically rotate through all five.

## Mark Your Visits

After choosing a league, enable the entries you want to highlight.

Each checklist item:

- Uses the team name as its label.
- Shows the bundled venue name in its description.
- Controls that team entry’s map marker.

Use the selections to remember your visits, build a bucket list, or create your own personal map of game-day experiences.

The app does not detect visits automatically.

## An Important Detail: Entries Are Team-Based

Selections are saved by league and team name—not by a unique stadium identifier.

That means:

- Two teams sharing a stadium have separate checklist entries.
- A venue used by teams in different leagues is tracked separately in each league.
- The app is not a historical record of every stadium a team has occupied.
- If a team’s listed venue changes in a future dataset update, its saved selection can remain attached to the team.

Use the checklist according to your own tracking convention, and review selections when venue data changes.

## Reading the Map

### Green: Map Outline

The green outline provides a compact geographic reference.

It is stylized pixel artwork, not a detailed navigation map.

### Muted Yellow: League Locations

The initial muted-yellow markers show the team locations included for the selected league.

All entries first appear in this color, including ones you’ve marked as visited.

### Bright Yellow: Your Selected Entries

Visited selections are added afterward in bright yellow.

Drawing them last ensures a selected marker remains visible when it shares a pixel with an unselected entry.

### League Label

A small label identifies the selected league near the lower-left of the map scene.

MLB and NFL labels are red. The other league labels are white.

These colors are decorative and do not indicate a score, status, or completion level.

## Watch Your Collection Light Up

Each animation follows this sequence:

1. Draw the map outline in groups of ten points.
2. Add the league’s venue markers in groups of three.
3. Pause on the initial map.
4. Add your selected markers one at a time.
5. Blink between the initial and highlighted maps.
6. Hold the highlighted map.
7. Blink again before the loop repeats.

The drawing and marker ordering can vary on a new render.

Replaying the same animation repeats its existing order and selections.

## Why Locations Can Share a Dot

A lot of sporting geography has to fit into a very small map.

Nearby venues—and sometimes entries in the same metropolitan area—can share a pixel. The coordinates are hand-positioned display locations, not precise geographic plotting from latitude and longitude.

As a result:

- A visible dot does not always represent a unique stadium.
- Two selected team entries can occupy the same point.
- Highlighting one entry can make a shared pixel look visited even when another entry there is unchecked.

There is no numerical visited counter in the current app.

## Get Started

No API keys, subscriptions, or external data feeds are required.

1. Add Stadium Tracker to your display.
2. Open the app’s settings.
3. Choose a league.
4. Mark the team venues you want to highlight.
5. Save your settings.
6. Watch your sporting travels light up.

Until a valid league is selected, the app displays:

> Select a league

You can track other leagues by changing the selection or creating additional app instances, depending on your hosting setup.

## Available Settings

| Setting | What it does |
| --- | --- |
| League | Selects MLB, NBA, NFL, NHL, or MLS. Initially prompts you to choose a league. |
| Team checklist | Marks entries to highlight for the selected league. Venue names appear in the item descriptions. |

Map colors, marker colors, frame delay, and blinking behavior are currently defined in code rather than exposed as settings.

## A Little Road-Trip Inspiration

Use the display to celebrate places you’ve been—or notice gaps worth exploring.

It makes a natural companion to:

- A ballpark road-trip collection
- A favorite team’s travel calendar
- A sports-themed desk or room
- A personal arena or stadium bucket list
- Memories of games shared with friends and family

The app provides a visual collection, not event schedules, ticket availability, or route planning.

## Dataset and Display Notes

- Team and venue information is bundled in the script.
- Names and locations change only when the dataset is updated.
- The collection does not automatically follow relocations, temporary home venues, or naming-rights changes.
- Canadian team entries are included where present, but the app does not draw a complete Canada outline.
- Some metropolitan-area markers are offset for readability.
- There are no separate Alaska or Hawaii insets.
- The 2× map uses scaled positions while keeping venue markers one pixel each.
- Square rendering retains the standard map dimensions rather than using the full panel height.
- Different team entries can refer to the same physical venue.
- The app does not show live scores, schedules, ticket links, or attendance history.

---

Keep the memories. Find the next game-day destination.

Created by Robert Ison.
