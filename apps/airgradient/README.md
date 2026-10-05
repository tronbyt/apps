# AirGradient for Tronbyt / Tidbyt

A companion display app for [AirGradient](https://www.airgradient.com/) air quality monitors, supporting both the **AirGradient ONE** indoor monitor (Model I-9PSL) and the **AirGradient Open Air** outdoor monitor (Model O-1PST).

Captures both the hardware pollutant LED bar and the environmental metrics displayed on the monitor so you can read your air quality clearly from across the room.

## Features

- **Hardware LED Bar Emulation**: Replicates the physical AirGradient pollutant LED bar:
  - 9 Pollutant LEDs extending from right to left with official AirGradient color thresholds: Green (Good), Yellow (Moderate), Orange (Elevated), Red (High), and Purple (Hazardous).
  - Configurable to follow the device's active LED mode (CO2, PM2.5, IAQS) or override to your preference. Automatically defaults to PM2.5 on Open Air monitors.
  - Can be toggled off completely via `Show LED Bar` or `LED Bar Metric: Off` with zero residual gray dots.
- **Multiple Display Modes**:
  - **AirGradient ONE / Open Air (Classic 3-Column)**: Faithful recreation of the AirGradient screen layout with Temperature (upper left), Relative Humidity (upper right), Column 1 (CO2 or PM1.0), Column 2 (PM2.5), and Column 3 (VOC Index & NOx Index, or PM10).
  - **Big Numbers (Across the Room)**: High-visibility large font layout optimized for effortless reading across a living room or office.
  - **Color Blocks (Section Backgrounds)**: Colored alert tiles where each section's background turns green, yellow, orange, red, or purple based on that pollutant's level, with high-contrast text and labels.
  - **Ambient (Full Background Color)**: The entire screen background changes dynamically to match the current air quality alert color.
  - **Color-Coded Graph (Air Quality Bars)**: A multi-color historical timeline where every vertical bar is individually color-coded according to the pollutant's Air Quality category (Green $\rightarrow$ Yellow $\rightarrow$ Orange $\rightarrow$ Red $\rightarrow$ Purple) at that specific moment in time.
  - **Sparkline History (Area Plot)**: Plots a continuous smooth curve with shaded under-area for any selected pollutant (**PM2.5, CO2, TVOC, NOx, PM10, or PM1.0**) across **8, 12, 24, or 48 hours** with min/max statistics.
- **Open Air (Outdoor) Auto-Detection**:
  - Automatically identifies AirGradient Open Air models (`O-` prefix or missing CO2 sensor).
  - Seamlessly shifts Column 1 from CO2 (ppm) to PM1.0 (µg/m³), Column 2 to PM2.5, and Column 3 to PM10, while configuring the LED bar for PM2.5.
- **Label Contrast / Color Options**:
  - Customize the metric labels and units (`CO2`, `PM2.5`, `VOC`, `ppm`, `ug`, etc.) with choices for **Bright White (High Contrast)**, **Muted Grey (Classic)**, **Warm Gold**, **Cool Cyan**, or a **Custom Color** picker to ensure maximum legibility against ambient and tinted backgrounds.
- **Dual Connection Support**:
  - **Direct Local Network (Default)**: Connects directly to the monitor's local HTTP API (e.g. `http://192.168.1.27` or `http://air.gradient.lan`).
  - **Home Assistant**: Query Home Assistant sensors directly using a Long-Lived Access Token, with support for entity prefixes and per-sensor overrides.
- **Native 2x & 1x Support**:
  - Full 128×64 resolution support matching the native OLED resolution of the AirGradient ONE.
  - Pixel-perfect 64×32 standard rendering.
- **Screen Metrics**:
  - **Upper Left**: Temperature (°F or °C).
  - **Upper Right**: Relative Humidity (RH %).
  - **Column 1**: CO2 (ppm) on indoor models; PM1.0 (µg/m³) on Open Air.
  - **Column 2**: PM2.5 (µg/m³).
  - **Column 3**: VOC Index & NOx Index (or PM10).
