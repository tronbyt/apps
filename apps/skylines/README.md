# Skylines

A familiar silhouette. A little starlight. A city coming to life.

Skylines brings city-inspired pixel art to your Tidbyt or compatible Tronbyt display, tracing each skyline into view before gently revealing its name.

Inspired by the understated charm of the Frasier opening titles, the app lets the architecture take center stage. A city name or your own personal message fades into the finished scene, holds long enough to read, then fades away to leave the skyline unobstructed.

Optional twinkling stars bring a little nighttime atmosphere to the presentation.

Celebrate a favorite destination, remember a place you’ve called home, or let a different skyline spark a little wanderlust.

Big-city character, beautifully small.

## Display Previews

These previews illustrate the supported display formats. They may show an earlier version of the text treatment or animation timing.

### Standard Display — 64 × 32

The original compact presentation: a skyline traces itself across the canvas, followed by optional stars and a fading, outlined text overlay.

![Skylines on a standard 64 × 32 display](skylines.webp)

### Wide 2× Display — 128 × 64

The wide version doubles the skyline’s pixel dimensions and uses a larger text font.

Stars remain individual one-pixel points, adding a delicate contrast to the larger architectural outlines.

![Skylines on a wide 128 × 64 display](skylines@2x.webp)

### Square Display — 64 × 64

The square version uses a centered 64 × 32 skyline composition rather than stretching the buildings vertically.

The text is positioned within that centered composition, keeping the skyline and title together.

![Skylines on a square 64 × 64 display](skylines@64x64.webp)

## Features

- Progressive skyline tracing — Watch the included city artwork appear in a flowing, pen-like sequence.
- Frasier-inspired presentation — A simple architectural silhouette followed by a gently appearing title.
- Consistent drawing duration — Detailed cities take the same selected amount of time to draw as simpler ones.
- Shuffled city rotation — Work through the available collection before beginning another shuffle.
- Personal city shortlist — Limit the rotation to the cities you enable.
- Repeat protection — Avoid consecutive selections of the same city, including across shuffle boundaries, while cached rotation state is available.
- Optional twinkling stars — Adds up to five spaced points of light above the skyline.
- City-name overlay — Identify the featured city after the initial skyline hold.
- Custom text — Add your name, a greeting, or another personal message.
- Text-free mode — Let the skyline and stars speak for themselves.
- Outlined lettering — A narrow black halo separates the letters from the artwork without covering an entire strip of the scene.
- Ten-step text fades — The letters and their outline fade in and out together.
- Centered short titles — Text that fits stays still and centered.
- Readable long titles — Longer text pauses, scrolls to reveal its ending, then pauses again before fading away.
- Custom colors — Choose the main skyline color and the text color.
- Independent timing controls — Adjust drawing, holds, fades, and scrolling separately.
- Bundled artwork — No accounts, API keys, or external image feeds are required.
- Scaled wide presentation — Uses a doubled skyline scale on a 128 × 64 canvas.

## Watch the City Take Shape

The app draws the skyline from left to right, working through one column at a time.

Within each column, it chooses whether to begin at the top or bottom according to the previous drawing position. This gives the reveal a flowing, pen-like character.

The tracing order remains the same regardless of the selected drawing duration. The renderer adjusts how many recorded pixels appear in each frame so that detailed and simple skylines finish in approximately the same amount of time.

Once the drawing is complete:

1. The finished skyline holds, with stars if enabled.
2. The optional title fades in, including its narrow black outline.
3. A short title remains centered. A longer title pauses, scrolls to its ending, then pauses again.
4. The title and its outline fade away.
5. The unobstructed skyline holds before the animation ends.

When an existing animation replays, it begins the same drawing sequence again. A new city is selected when the app renders a new animation.

### Default Sequence

For a title that fits on the display:

| Phase | Default duration |
| --- | --- |
| Draw the skyline | 4 seconds |
| Hold the finished skyline | 1.5 seconds |
| Fade the title in | 1 second |
| Hold the title | 3 seconds |
| Fade the title out | 1 second |
| Hold the unobstructed skyline | 1.5 seconds |

The default sequence lasts approximately 12 seconds.

Long titles add scrolling time between their opening and closing pauses rather than rushing to fit a fixed playback window.

## Choose Your Cities

### Display a Random City

Select this mode to use the entire bundled city collection.

Rather than making an independent random choice on every render, the app keeps a shuffled list and works through it one city at a time.

Once every city in that list has been selected, it reshuffles the collection.

When more than one city is available, the first city of a new shuffle is prevented from matching the last city of the previous shuffle.

### Pick from Selected

Select this mode to reveal an alphabetical checklist of the included cities.

Leave your favorites enabled and disable the others. The app then works through a shuffled rotation of your selected collection.

To keep one city on display, leave only that city enabled.

If every city is disabled, the app falls back to the full collection rather than producing an empty selection.

### How the Rotation Is Remembered

The app stores its remaining city selections in the runtime’s cache, with a separate rotation key for each selected collection.

The rotation advances when the app renders a new animation—not when a display replays an existing animation.

The cached state has a 30-day expiration, renewed whenever that rotation is used. If the cache expires, is cleared, or is unavailable across runs, the app cannot preserve the previous rotation.

Changing the selected collection uses a different rotation. Returning to an earlier collection may resume its previous rotation if that cached state is still available.

Repeat protection applies within a remembered rotation. It does not guarantee a different city after a cache reset or a change between collections.

## Add Your Own Opening Title

The “Text Overlay” setting offers three choices.

### Display City Name

Shows the selected city’s name.

This is the default and makes the app a small rotating showcase of the included skyline collection.

### Display No Text

Keeps the presentation focused on architecture and optional stars.

The app skips the title fades and title hold. The initial and final skyline holds still apply.

### Display Custom Text

Uses the words entered in “Custom Text” instead of the city name.

Try:

- Your name
- A greeting
- A favorite short phrase
- A label for your desk or room
- A message that belongs with a memorable city

If Custom Text is selected but the field is blank, the app falls back to the city name.

### Lettering Without a Background Strip

The title is drawn directly over the skyline.

A one-pixel black halo around the lettering provides separation from the artwork. There is no full-width black background strip.

Only the letters and their immediate outline cover the underlying scene.

### Fading In and Out

The lettering and its halo fade together through ten opacity steps.

“Name Fade Duration” controls how long each fade takes. Select “Instant” to disable both fades.

The text remains still during the fades.

### Short and Long Titles

Titles that fit within the display width, including their outline, stay centered.

Longer titles:

1. Fade in at their starting position.
2. Pause so the beginning can be read.
3. Scroll left until the ending is visible.
4. Pause at the ending.
5. Fade out without restarting the scroll.

For long titles, the selected “Name Hold” is divided between the opening and closing pauses. Scrolling time is added between them.

Very long custom messages create longer animations. Short messages work best with the understated title-sequence presentation.

## A Few Stars Above the Rooftops

“Display Stars” is enabled by default.

The app looks for open-sky positions above the drawn skyline, leaving clearance from the buildings and spacing between selected stars.

It attempts to place up to five stars. A skyline with limited suitable space may show fewer.

The stars:

- Appear during the completed-scene portion of the animation.
- Twinkle with staggered timing.
- Move through dim blue, cool white, bright white, and warm-white shades.
- Briefly disappear during one phase of the cycle.
- Remain in fixed positions within a rendered animation.
- Continue twinkling during the title sequence and skyline holds.

This is an artistic star field, not an astronomical map.

## Make It Your Own

Two color settings are available:

| Setting | Default |
| --- | --- |
| Skyline | White |
| Text | Blue |

The Skyline setting changes the main outline color.

Artwork can also include red and green detail pixels. Those accents retain their predefined colors rather than following the main skyline setting.

The text’s black outline is fixed. Its opacity follows the lettering during fades.

Star colors are defined by the animation and are not independently configurable.

## Set the Pace

Drawing, title playback, and viewing time now have separate controls.

Changing the drawing duration does not shorten the skyline holds or speed up the text.

The renderer uses a fixed 50-millisecond frame delay. The timing controls determine how many frames are used for each phase.

### Drawing Duration

Sets how long the skyline takes to trace.

| Choice | Duration |
| --- | --- |
| Quick | 2 seconds |
| Classic — default | 4 seconds |
| Relaxed | 6 seconds |
| Slow | 8 seconds |

All cities use the selected duration, regardless of their number of recorded pixels.

### Skyline Hold

Sets the pause between the completed drawing and the title appearing.

Choices: 0.5, 1.5, 3, or 5 seconds.

Default: 1.5 seconds.

### Name Hold

Sets how long a short, centered title stays fully visible.

For a long title, this time is divided between pauses at the beginning and end, with scrolling time added between them.

Choices: 2, 3, 5, or 8 seconds.

Default: 3 seconds.

### Name Fade Duration

Sets the duration of each fade: one as the title appears and another as it disappears.

Choices: Instant, 0.5, 1, 1.5, or 2 seconds.

Default: 1 second per fade.

### Final Skyline Hold

Sets the unobstructed viewing time after the title disappears.

Choices: None, 0.5, 1.5, or 3 seconds.

Default: 1.5 seconds.

### Long Name Scroll Speed

Sets the time taken to move a long title by one pixel.

| Choice | Time per pixel |
| --- | --- |
| Fast | 50 milliseconds |
| Medium — default | 100 milliseconds |
| Slow | 150 milliseconds |

This setting does not affect skyline tracing, fades, holds, or star-twinkle timing.

## Get Started

No accounts, API keys, or external data feeds are required.

1. Add Skylines to your display.
2. Open the app’s settings.
3. Choose the full city collection or a selected-city shortlist.
4. Decide whether to show stars.
5. Select a city-name, custom-text, or text-free presentation.
6. Choose your skyline and text colors.
7. Adjust the drawing duration, holds, fades, and scrolling speed—or keep the defaults.
8. Save your settings and watch the city take shape.

## Available Settings

| Setting | What it does |
| --- | --- |
| Drawing Duration | Sets the tracing time for every city. Defaults to 4 seconds. |
| Skyline Hold | Sets the pause before the title appears. Defaults to 1.5 seconds. |
| Name Hold | Sets the fully visible title hold, or the combined opening and closing pauses for long titles. Defaults to 3 seconds. |
| Name Fade Duration | Sets the duration of each ten-step fade. Defaults to 1 second. “Instant” disables fades. |
| Final Skyline Hold | Sets the unobstructed hold after the title disappears. Defaults to 1.5 seconds. |
| Long Name Scroll Speed | Sets scrolling speed independently of other timing. Defaults to 100 milliseconds per pixel. |
| Display Stars | Adds twinkling stars above the finished skyline. Enabled by default. |
| Skyline | Sets the main skyline color. Defaults to white. |
| Text | Sets the overlay text color. Defaults to blue. |
| Text Overlay | Chooses city name, no text, or custom text. Defaults to city name. |
| Custom Text | Supplies the message used by the custom-text option. |
| What to display | Chooses the full collection or a selected-city shortlist. |
| City checklist | Enables cities for shortlist mode. Entries default to enabled. |

## For Tinkerers: Skyline Artwork

City artwork is included in:

[View the skyline dataset](skylines_data.star)

The folder also includes a browser-based tracing tool:

[View the Skyline Tracer source](Skyline_Tracer.html)

Artwork customization is a source-level project, not an app setting.

Each skyline dataset is a rectangular grid whose values identify:

- `0` — Empty space
- `1` — Main skyline color
- `2` — Red detail
- `3` — Green detail

The renderer checks that rows have matching widths and contain only these supported values.

### Rendering and State

The app uses:

- A fixed frame delay for consistent timing.
- Frame-by-frame pixel counts to normalize drawing duration.
- Text measurements to choose centered or scrolling placement.
- Explicit text positioning to pause scrolling during fades.
- Cached shuffle state to remember city selections between renders.

The square display centers the complete skyline scene, including its text.

The wide display scales the skyline and uses a larger font, while stars and the text halo remain one pixel thick.

## Notes

- The app uses its bundled collection rather than downloading current city imagery.
- Skylines are stylized pixel artwork, not complete or continuously updated architectural records.
- A single rendered animation features one city; it does not cycle through multiple cities.
- Replaying an existing animation does not advance the city rotation.
- The shuffle advances on rendering, so a rendered city is consumed from the rotation even if that animation is not subsequently displayed.
- Rotation memory and repeat protection depend on cached state being retained.
- The title appears after the initial completed-skyline hold.
- Short titles remain centered; long titles add scrolling time to the sequence.
- The title and its narrow black outline fade together without a full-width background strip.
- Text uses a compact display font, not an exact recreation of the Frasier title typography.
- Wide rendering enlarges skyline pixels, but stars remain one pixel each.
- Square rendering keeps the title within the centered skyline composition.
- The scene returns to the beginning when the animation replays; there is no whole-scene fade-to-black transition.
- This is a fan-inspired visual presentation, not an official Frasier product.

---

A little architecture. A little atmosphere. A city worth another glance.

Created by Robert Ison.
