# Audiobookshelf Now Playing

Track currently playing audiobooks and podcasts from your [Audiobookshelf](https://www.audiobookshelf.org/) server on your Tronbyt / Tidbyt device.

## Features

- **Now Playing Display**: Shows current title, author, progress bar, and realistic time remaining (or elapsed / total).
- **Clean 1x & 2x Layouts**:
  - **1x (64x32)**: Clean layout with title, author, progress bar, and dedicated right-aligned time remaining.
  - **2x (128x64)**: High-resolution layout featuring chapter title, progress bar, percentage, and time remaining.
- **Configurable Listen Speed Factor**: Select your listening speed multiplier (`0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`, `1.75x`, `2.0x`, `2.5x`) to dynamically recalculate remaining listening time.
- **Aspect Ratio Detection**: Automatically detects square vs. rectangular book covers.
- **Stylized Fallback**: Procedurally renders a book cover if server covers are unavailable.
- **Customizable Appearance**: Multiple color themes, custom hex colors, progress bar styles, and scroll modes.

## Configuration Options

| Option | Type | Description | Default |
| --- | --- | --- | --- |
| `server_url` | Text | Host URL of your Audiobookshelf server | `http://localhost:13378` |
| `api_token` | Text (Secret) | User API token or Bearer token | — |
| `only_playing` | Toggle | Only display when an audiobook is actively playing | `false` |
| `listen_speed` | Dropdown | Listening speed multiplier (`0.5x` to `2.5x`) to recalculate realistic time remaining | `1.0` |
| `time_mode` | Dropdown | Time display format (`remaining`, `elapsed`, `total`) | `remaining` |
| `scroll_mode` | Dropdown | Title animation (`scroll`, `static`) | `scroll` |
| `bar_style` | Dropdown | Progress bar style (`standard`, `centered`) | `standard` |
| `color_scheme` | Dropdown | Accent color theme (ABS Gold, Teal, Green, etc., or Custom) | `gold` |
| `custom_color` | Text | Custom hex color code when `custom` color scheme is selected | `#f59e0b` |
