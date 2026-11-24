# Microseasons

A Tronbyt app inspired by Japan's **72 microseasons** (*Shichijūni-kō*) and daily **Iro-goyomi** traditional Japanese colors. All data is stored locally with no external network requests at runtime.

## Features

- **72 Microseasons (`01/72` – `72/72`):** Displays today's microseason in **English** or **Japanese (Romaji)** using the 24 solar term (*Sekki*) calendar boundaries across all 365/366 days of the year.
- **Daily Iro-goyomi Color Background:** Uses today's traditional Japanese color as the full-screen background and automatically chooses high-contrast `#000000` or `#FFFFFF` text based on WCAG relative luminance.
- **Three Toggleable Screens:**
  1. **Microseason** (always shown): Microseason title, optional `XX/72` & date header, and configurable footer.
  2. **Daily Phrase** (optional): Today's short poetic seasonal reflection.
  3. **Color Note** (optional): Today's Iro-goyomi color name and poetic description.
- **Multi-Panel Support:** Tailored layouts for `64x32` (1x), `128x64` (2x), and `64x64` (square) displays.

## Configuration

| Option | Description | Default |
| --- | --- | --- |
| **Language** | `English` or `Japanese (Romaji)` | `English` |
| **Footer** | `Color + Day Dots (2x/64x64)`, `Color of the Day`, `Day Color Dots`, or `None` | `Color + Day Dots (2x/64x64)` |
| **Background Pattern (2x Only)** | Optional subtle *wagara* texture on `128x64` (2x) displays: `None`, `Seasonal (Auto)`, `Ichimatsu`, `Shippo`, `Seigaiha`, or `Yagasuri` | `None (Solid Color)` |
| **Show Header** | Show the microseason number (`XX/72`) and current date | `True` |
| **Show Daily Phrase** | Cycle to a second screen with today's seasonal phrase | `True` |
| **Show Color Note** | Cycle to a third screen describing today's Iro-goyomi color | `True` |

## Credits

Inspired by and using the 72 microseasons, 24 *Sekki* standard dates, daily *Iro-goyomi* color calendar, daily phrases, and color notes from **[Koyomina](https://koyomina.com/en/seasons/)** ([Iro-goyomi Colors](https://koyomina.com/en/colors/)).
