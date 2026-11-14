# Rachio

A little insight into what’s happening outside.

Rachio brings recent sprinkler activity to your Tidbyt or compatible Tronbyt display, making it easy to see what your irrigation controller has been up to without reaching for your phone.

View recent schedule starts, completions, weather-related skips, and zone-start details in a compact scrolling dashboard. Choose a controller, show its name, and let the app quietly step out of your display rotation when there’s no recent activity.

A small window into the watering routine—right where you can see it.

## Display Previews

### Standard Display — 64 × 32

A compact activity dashboard with the Rachio icon, controller name, event time, and scrolling status details.

![Rachio on a standard 64 × 32 display](rachio.webp)

### Wide 2× Display — 128 × 64

The wide version uses a larger text font and wider scrolling regions for device and event information.

The Rachio icon retains its original image dimensions rather than automatically doubling in size.

![Rachio on a wide 128 × 64 display](rachio@2x.webp)

### Square Display — 64 × 64

The square version centers the compact dashboard vertically within the taller canvas.

![Rachio on a square 64 × 64 display](rachio@64x64.webp)

## Features

- Recent controller activity — Looks back through approximately one week of event history.
- Schedule starts and completions — See when watering schedules started or finished.
- Weather-related skips — Displays rain, soil-saturation, and freeze skips when reported.
- Zone-start details — Shows available zone numbers and event summaries.
- Inferred activity status — Uses recent schedule and zone events to identify when a run is likely active.
- Controller selection — Choose from the devices returned by your Rachio account.
- Optional device name — Display your controller’s name or a simple “Rachio” heading.
- Local event times — Formats event dates and times using the runtime time zone.
- Adjustable scrolling — Choose slow, medium, or fast playback.
- Quiet-period hiding — Skip the app when no relevant events are found within the lookback period.
- Cached requests — Reuses account information and event responses to reduce repeated API calls.
- Read-only behavior — The script retrieves information; it does not start, stop, or change watering schedules.

## Before You Begin

You’ll need:

- A Rachio account with a controller available to it.
- Your Rachio API key.
- Network access to the Rachio public API.

The API key is an account credential. Keep it private and avoid including it in screenshots, public configuration files, or repository commits.

The app’s API-key field is marked as secret, but the credential still needs to be handled carefully.

## Setup

### 1. Find Your API Key

Open your Rachio account settings and locate your API key.

The current app expects this key directly; it does not provide an interactive Rachio sign-in flow.

### 2. Enter the Key

1. Add Rachio to your display.
2. Open the app’s settings.
3. Paste your key into “Rachio API Key.”
4. Allow the app to retrieve the devices associated with your account.

### 3. Choose Your Controller

A “Device” dropdown is generated from the returned account information.

Select the controller you want to display.

If no device is explicitly selected, the script uses the first returned device. Selecting one yourself is preferable when your account contains multiple controllers.

### 4. Set Your Preferences

Choose whether to show the device name, select a scrolling speed, and decide whether the app should hide during periods without relevant activity.

Save your settings to begin displaying events.

## Reading the Display

### Header: Controller Name

With “Display Device Name” enabled, the heading uses the selected controller’s name.

Disable it to use “Rachio” instead.

### Event Date and Time

The next header line identifies when the displayed event occurred.

Events on the current local date are shown as:

> Today at 6:15 AM

Older events include the weekday, month, day, and time.

These are event timestamps—not the last time the app refreshed.

### Status and Details

The lower rows describe the selected event or inferred activity state.

Examples include:

- Last: Finished
- Last: Rain Skip
- Last: Soil Saturation Skip
- Last: Freeze Skip
- Last: Zone Started
- Likely active: Started

Available event summaries and zone information appear in the final row.

## “Likely Active” Is an Inference

The app does not use a live water-flow measurement or a dedicated current-run endpoint to confirm watering.

It displays “Likely active: Started” when its selected event history contains:

1. A schedule start as the latest relevant schedule event.
2. A zone-start event at or after that start.
3. A schedule start no more than three hours old.

The three-hour limit is a display safeguard—not proof that watering stops after three hours.

### What the Zone Detail Means

The accompanying zone information comes from a recorded zone-start event.

It is historical evidence, not a guarantee that the named zone is still running.

### When a Start Appears Alone

A schedule start without enough supporting evidence is shown as history with:

> Live status unconfirmed

This avoids presenting every start event as confirmed current activity.

A later relevant schedule completion or skip can also prevent the active inference.

## Events Included in the Dashboard

The app recognizes these event types:

| Event | Display label |
| --- | --- |
| Schedule started | Started |
| Schedule completed | Finished |
| Weather intelligence skip | Rain Skip |
| Climate skip | Soil Saturation Skip |
| Freeze skip | Freeze Skip |
| Zone started | Zone Started |

Other event types are not included in the activity selection.

Future-dated entries are ignored.

When schedule timestamps tie, the selection logic favors a completion over a start rather than inferring activity from that tie.

## Recent History, Not a Full Event Log

The app retrieves a week-long event window and builds a compact presentation from the most relevant recent information.

It does not scroll through every event in chronological order.

Depending on the event history, it displays:

- An inferred active schedule and associated zone-start detail.
- The most recent zone start as historical activity.
- The latest recognized schedule event and its available summary.

After a completion, a zone detail may be shown when the code can place it between a known start and that completion.

## Hide During Quiet Periods

“Skip when nothing to display” is enabled by default.

When no recognized events are found in the lookback window, the app returns no display.

Disable this option to show:

> No events within a week.

This setting does not mean “show only while watering.” Recent completed schedules and skips can remain visible even when the controller is idle.

It also does not suppress configuration or handled API-error messages.

## Multiple Controllers

The app displays one selected controller per instance.

If you have several Rachio controllers, add separate app instances and choose a different device in each.

Each instance provides its own controller view; the app does not automatically cycle through all devices.

Additional instances can generate additional device-event requests, so consider your refresh schedule and API usage.

## Refreshes and Caching

The current script uses two caching intervals:

| Information | Cache interval |
| --- | --- |
| Account and device information | Two hours |
| Event responses | Three minutes |

Event request URLs use three-minute time buckets so repeated renders within the same bucket can reuse a stable request.

The query endpoint is rounded to the next bucket boundary, but future-dated events are filtered out before display.

### What This Means in Practice

- The dashboard is not an instantaneous live monitor.
- New events may not appear immediately.
- Device-name or account changes can take time to appear.
- Replaying an existing animation does not fetch fresh events.
- Cache retention and network availability affect actual behavior.
- The app does not track or enforce a monthly request budget.

There is no separate last-successful-event fallback implemented by the script.

## Available Settings

| Setting | What it does |
| --- | --- |
| Rachio API Key | Authenticates requests to your Rachio account. |
| Display Device Name | Uses the controller’s name instead of “Rachio.” Enabled by default. |
| Scroll | Selects Slow, Medium, or Fast scrolling. Defaults to Slow. |
| Skip when nothing to display | Hides the app when no relevant events are found within a week. Enabled by default. |
| Device | Selects a controller from the generated account-device list. |

## Troubleshooting

### “Please enter your API key.”

The API-key setting is blank.

Enter your Rachio API key and save the settings.

### “Unable to load Rachio devices.”

The account or device lookup did not return a usable response.

Check your key, network access, and the render logs. The message can also appear during a service problem.

### “No Rachio devices found.”

The lookup completed without finding usable device entries.

Check which Rachio account the key belongs to and whether your controller is available to that account.

### “Selected device is unavailable.”

The saved device ID is not in the returned device list.

Open the settings and select an available controller.

### “Unable to load Rachio events.”

The event request failed or did not return the expected list.

Check the API key, connectivity, and render logs.

### The Status Seems Behind

Allow for event caching, your hosting system’s render interval, and the time it takes events to become available through the API.

Remember that “Likely active” is inferred from history and does not confirm current water flow.

## Time-Zone Notes

The script uses the runtime time zone through `time.tz()`.

There is no separate location or time-zone setting in this app. Configure the appropriate time zone in your display or hosting environment so event times and “Today” labels match your location.

## Important Limitations

- This is an activity display, not an irrigation-control interface.
- It does not start, stop, or edit schedules.
- “Likely active” does not confirm valve state, sprinkler operation, or water flow.
- A historical zone-start event does not prove that zone is currently running.
- The three-hour inference limit is not an irrigation timeout.
- Only selected event types are considered.
- The dashboard does not show upcoming schedules, water consumption, or leak detection.
- Error handling covers several expected failures, but not every possible malformed response or runtime problem.
- Use the Rachio app or controller interface to verify current operation.

---

Keep your watering routine in view—without stepping outside.

Created by Matt Fischer and Rob Ison.
