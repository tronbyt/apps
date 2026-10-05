# AirGradient ONE for Tronbyt / Tidbyt

A companion display app for the [AirGradient ONE](https://www.airgradient.com/indoor/) indoor air quality monitor (Model I-9PSL).

Captures both the physical 11-LED status & pollutant bar and the environmental metrics displayed on the monitor's screen so you can read your indoor air quality clearly from across the room.

## Features

- **Hardware LED Bar Emulation**: Replicates the physical AirGradient ONE top LED bar:
  - 1 Status LED on the far left (alerting to connectivity issues).
  - 9 Pollutant LEDs extending from right to left (matching hardware behavior) with official AirGradient color thresholds: Green (Good), Yellow (Moderate), Orange (Elevated), Red (High), and Purple (Hazardous).
  - Configurable to follow the device's active LED mode (CO2, PM2.5, IAQS) or override to your preference.
  - Can be toggled off completely via `Show LED Bar` or `LED Bar Metric: Off` with zero residual gray dots.
- **Multiple Display Modes**:
  - **AirGradient ONE (Classic 3-Column)**: Faithful recreation of the AirGradient ONE OLED screen layout with Temperature, Humidity, CO2, PM2.5, VOC Index, and NOx Index.
  - **Big Numbers (Across the Room)**: High-visibility large font layout optimized for effortless reading across a living room or office.
  - **Color Blocks (Section Backgrounds)**: Colored alert tiles where each section's background turns green, yellow, orange, red, or purple based on that pollutant's level, with high-contrast text and labels.
  - **Ambient (Full Background Color)**: The entire screen background changes dynamically to match the current air quality alert color.
- **Label Contrast / Color Options**:
  - Customize the metric labels and units (`CO2`, `PM2.5`, `VOC`, `ppm`, etc.) with choices for **Bright White (High Contrast)**, **Muted Grey (Classic)**, **Warm Gold**, or **Cool Cyan** to ensure maximum legibility against ambient and tinted backgrounds.
- **Dynamic Dual Connection Support**:
  - **Direct Local Network (Default)**: Connects directly to the monitor's local HTTP API (e.g. `http://192.168.1.27` or `http://air.gradient.lan`). The schema dynamically shows only the local device URL.
  - **Home Assistant**: Query Home Assistant sensors directly using a Long-Lived Access Token, dynamically revealing HA URL, token, and entity prefix/override options when selected.
- **Native 2x & 1x Support**:
  - Full 128×64 resolution support matching the native OLED resolution of the AirGradient ONE.
  - Pixel-perfect 64×32 standard rendering.
- **Temperature Units**: Switch between Fahrenheit (°F) and Celsius (°C).
