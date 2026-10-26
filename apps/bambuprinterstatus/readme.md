# Bambu Printer Status

Your printer is busy creating something awesome. Now your display can keep you in the loop.

Bambu Printer Status turns your Tidbyt or compatible Tronbyt display into a colorful, at-a-glance companion for your Bambu printer. Follow the current print’s progress, see when it should finish, and check the most recently completed job without opening your slicer or reaching for your phone.

## Display Formats

The app adapts its presentation to three display formats. Each includes the printer name, current status, scrolling job details, and timing information.

### Standard — 64 × 32

The compact layout for standard-resolution displays.

![Bambu Printer Status on a standard 64 × 32 display](bambuprinterstatus.webp)

### Wide 2× — 128 × 64

The wide layout uses a larger font for higher-resolution displays.

![Bambu Printer Status on a wide 128 × 64 display](bambuprinterstatus@2x.webp)

### Square — 64 × 64

The compact dashboard is centered on the square panel.

![Bambu Printer Status on a square 64 × 64 display](bambuprinterstatus@64x64.webp)


The display includes the printer name, current status, scrolling job details, and timing information.

## Features

- Color-coded status for printing, paused, idle, offline, and error states.
- Current print progress when supplied by the status feed.
- Scrolling job details combining job name, plate name, and printed objects when available.
- Time remaining and an automatic estimated local finish time while printing.
- Last-print details that remain visible while idle, until another print starts.
- Completed-print duration and elapsed time since completion when available.
- A printer dropdown populated from your status feed.
- Slow, medium, or fast scrolling.
- An option to hide the app when the selected printer reports offline.
- Optional print-completion sounds on supported Gen 2 devices.
- On-device setup instructions.

Available details depend on the information supplied by your status feed.

## Setup

The app reads printer information from a `status.json` file served over HTTP. It does not connect directly to your printer.

You must first configure a process that collects your printer information, updates the JSON file, and makes that file accessible to the system running the app.

The complete JSON-feed setup process is covered in the PDF guide included in this folder:

    bambu_printer_status_json_setup_instructions.pdf

The guide covers creating the status feed with the provided Python script, scheduling updates, and serving the resulting JSON file over HTTP.

### Setup Overview

1. Follow the PDF guide to create your printer-status JSON feed.
2. Schedule the feed to update every minute.
3. Serve `status.json` at an HTTP address the app can reach.
4. Enter the complete address in Status JSON URL.
5. Select your printer from the generated printer dropdown.
6. Choose your preferred Scroll Speed.
7. Enable Hide When Printer Offline if desired.
8. Optionally configure a Notification Sound and its connection settings.
9. Turn off Show Setup Instructions to display printer status.

Example Status JSON URL:

    http://your-status-server:8787/status.json

Use the address and port of your own status-feed server. Do not use `localhost` unless the feed is available in the same environment that executes the app.

## Available Settings

| Setting | Description |
|---------|-------------|
| Show Setup Instructions | Display scrolling setup help instead of printer status. |
| Status JSON URL | The full HTTP address of your `status.json` feed. |
| Scroll Speed | Choose Slow, Medium, or Fast. |
| Hide When Printer Offline | Hide the app when the selected printer reports offline. Disabled by default. Setup instructions and configuration/data error messages remain visible. |
| Printer | Choose a printer from the list loaded from your status feed. |
| Notification Sound | Choose No sound, Chime, Ding, Bell, Pop, Alert, or Tron Bit. No sound is the default. |
| Tronbyt Server URL | OPTIONAL - Only Needed for Gen 2 with Sound Option. The base URL of your Tronbyt server, including its port if needed. |
| Notification Device ID | OPTIONAL - Only Needed for Gen 2 with Sound Option. The Tronbyt device ID of the display that should play the sound. |
| Notification API Key | OPTIONAL - Only Needed for Gen 2 with Sound Option. The API key belonging to that Tronbyt display. Treat this value as a secret. |

The three notification connection fields are always visible. Leave them blank if Notification Sound is set to No sound.

When a sound is selected, all three connection fields must be filled in.

The position of the generated Printer dropdown may vary between configuration interfaces. It does not need to be selected last.

## Display Behavior

### Printing

During an active print, the app displays:

- Printer name.
- Printing status and progress percentage when available.
- Current job details.
- Time remaining when available.
- Estimated finish time in the configured display time zone.

Estimated finish time is automatic; there is no separate toggle.

The estimate uses the status feed's update timestamp when available. It is an estimate, not a guarantee, and depends on the accuracy of the remaining-time information.

### Paused or Error

A paused print continues to show current-job information.

When the feed includes a supported error-message field, the app displays that detail. Otherwise, it shows a general message directing you to check the printer.

### Idle

When there is no active print, the app displays the most recently completed job and its duration when available.

The completed job remains visible regardless of how long ago it finished. Starting a new print switches the display to the current job.

If no completed-job history is available, the app displays Idle and No print history.

### Offline

By default, the app displays Offline when the selected printer reports offline.

Enable Hide When Printer Offline to hide the app in that situation.

A failed JSON request or invalid configuration is not treated as a confirmed offline printer. Those problems remain visible as error messages.

### Status Freshness

The app does not display stale-data or future-timestamp warnings.

If the displayed information stops updating, check the process producing `status.json`, its update schedule, and the HTTP server serving the file.

The app can continue displaying old information if the status feed itself stops changing.

## Print-Completion Sound Notifications

On supported Gen 2 devices, the app can request a notification sound when the observed printer state changes directly from `PRINTING` to `IDLE`.

Sound is optional. Users who do not want audio can leave Notification Sound set to No sound and leave all three notification connection fields blank.

### Available Sounds

- No sound — disables audio notifications.
- Chime.
- Ding.
- Bell.
- Pop.
- Alert.
- Tron Bit.

### Configure Audio

1. Select a sound in Notification Sound.
2. Enter the Tronbyt Server URL.
3. Enter the Notification Device ID of the display that should play it.
4. Enter that display's Notification API Key.
5. Save the configuration.

The Notification Device ID is the display's Tronbyt device ID, not the Bambu printer ID.

The API key must belong to the selected display device.

### Which URL Goes Where?

The app uses two separate connections:

| Field | Purpose | Example |
|-------|---------|---------|
| Status JSON URL | Reads printer information. | `http://your-status-server:8787/status.json` |
| Tronbyt Server URL | Requests sound playback through Tronbyt. | `http://your-tronbyt-server:8000` |

For Tronbyt Server URL, enter only the server's base address, including its port if needed.

Do not enter:

- A full Manager device-configuration page URL.
- The Status JSON URL.
- The printer's address instead of the Tronbyt server's address.

Both connections must be reachable from the environment actually executing the app. A URL that works from your browser may not be reachable from a separate server or container.

### How Sound Works

The app caches the previously observed printer state between executions.

When the previous state is `PRINTING` and the current state is `IDLE`, it sends the selected sound to the Tronbyt server's sound API.

The sound request is separate from the rendered WebP image. Sound is not embedded in the image.

- The first observation initializes tracking without playing a sound.
- State tracking continues when No sound is selected.
- Remaining idle does not repeatedly trigger the notification.
- There is no notification when a new print starts.
- Changing the sound selection does not preview it.
- Each detected completion transition makes one playback attempt.
- Failed playback attempts are not retried on subsequent idle updates.

### Requirements and Limitations

- The display and Tronbyt installation must support sound playback.
- The app must be able to reach the configured Tronbyt server.
- The device ID and API key must be valid for the target display.
- Device mute settings can prevent playback.
- Notifications occur when the app executes and observes the state change, not necessarily at the exact moment the print finishes.
- Displaying an already-rendered image does not itself run the completion check.
- Only a direct observed `PRINTING` to `IDLE` transition triggers normal playback.
- If the app does not observe that transition, it will not send a completion sound.
- A canceled print that also produces `PRINTING` to `IDLE` can trigger the same notification. The state transition alone does not prove successful completion.
- Clearing or expiring the cached state causes the next observation to initialize tracking silently.
- Changing the status-feed URL, printer selection, or notification device can establish a separate tracking history.

If you want sounds only for print completion, leave Tronbyt's separate general-purpose app notification sound disabled.

### API Key Privacy

Enter the Notification API Key only in the app's configuration.

Do not put it in:

- The `.star` source file.
- Your README.
- A public repository.
- Shared screenshots or logs.

The app's diagnostic logging does not intentionally print the authorization header or configured API key.

## Troubleshooting

### No Printer Dropdown or No Printers Listed

Check that:

1. Status JSON URL is complete and correct.
2. The URL is reachable from the system running the app.
3. The response is valid JSON.
4. The JSON contains a `printers` list.
5. Printer entries contain an `id`.

The dropdown is populated from the status feed; it is not a fixed list.

### Selected Printer Not Found

The saved printer ID no longer matches an entry in the feed.

Check the feed and select the intended printer again.

### Display Is Not Updating

Check that:

- The JSON producer is still running.
- Scheduled updates are succeeding.
- The HTTP endpoint is serving the latest file.
- The app is being executed often enough to load updates.

### No Completion Sound

Check that:

1. Notification Sound is not set to No sound.
2. All three notification connection fields are filled in.
3. Notification Device ID identifies the display, not the printer.
4. The API key belongs to that display.
5. The display is not muted.
6. The app can reach the Tronbyt server.
7. The app observed `PRINTING`, followed by `IDLE`, on successive executions.

An already-idle printer does not trigger a sound when the app is first configured.

### Diagnostic Logging

The source includes two separate development flags:

    DEBUG_LOGGING = False
    DEBUG_FORCE_SOUND = False

Set `DEBUG_LOGGING = True` to log printer-state comparisons, connection-setting presence, and sound-request results.

Leave `DEBUG_FORCE_SOUND = False` when testing normal completion behavior.

Setting `DEBUG_FORCE_SOUND = True` bypasses the completion-transition requirement and attempts the selected sound on every execution that reaches the notification check. It still requires valid connection settings and a sound selection.

Forced playback can produce repeated sounds during refreshes or setting changes. It does not run before setup and status-data checks.

Leave both flags False for normal use.

## Updating from Earlier Versions

The settings have been simplified:

- Only During Active Prints has been removed.
- Always Show Offline has been replaced by Hide When Printer Offline.
- Estimated Finish Time is now automatic when the required data is available.
- Highlight Recent Completion has been removed; the last completed job remains visible while idle.
- Warn About Old Data and its warning displays have been removed.
- Notification Sound remains completion-only.
- The printer dropdown is still populated from the JSON feed.

Review Hide When Printer Offline after updating. It is a new setting and does not inherit the earlier display-filter options.

The earlier separate Audio Notification toggle is no longer used. Notification Sound controls whether audio is enabled.

## Notes

- Status accuracy depends on the process updating your JSON feed.
- Missing optional information is omitted or replaced with a suitable fallback.
- No printer or notification credentials are embedded in the app source.
- The app is a status display; it does not start, pause, cancel, or otherwise control prints.
