# AirGradient ONE for Tronbyt / Tidbyt

A companion display app for the [AirGradient ONE](https://www.airgradient.com/indoor/) indoor air quality monitor (Model I-9PSL).

Captures both the physical 11-LED status & pollutant bar and the environmental metrics displayed on the monitor's screen so you can read your indoor air quality clearly from across the room.

## Features

- **Hardware LED Bar Emulation**: Replicates the physical AirGradient ONE top LED bar:
  - 1 Status LED on the far left (alerting to connectivity issues).
  - 9 Pollutant LEDs extending from right to left (matching hardware behavior) with official AirGradient color thresholds: Green (Good), Yellow (Moderate), Orange (Elevated), Red (High), and Purple (Hazardous).
  - Configurable to follow the device's active LED mode (CO2, PM2.5, IAQS) or override to your preference.
- **Multiple Display Modes**:
  - **Classic 3-Column**: Faithful replica of the AirGradient ONE OLED screen layout with Temperature, Humidity, CO2, PM2.5, VOC Index, and NOx Index.
  - **Big Numbers (Across the Room)**: High-visibility large font layout optimized for effortless reading across a living room or office.
  - **Cycling**: Alternates between the classic dashboard view and big number view.
- **Dual Connection Options**:
  - **Direct Local Network (Default)**: Connects directly to the monitor's local HTTP API (e.g. `http://192.168.1.27` or `http://air.gradient.lan`). No cloud or third-party service required.
  - **Home Assistant**: Query Home Assistant sensors directly using a Long-Lived Access Token, supporting entity prefix conventions (`sensor.airgradient_one_*`) and custom entity overrides.
- **Native 2x & 1x Support**:
  - Full 128×64 resolution support matching the native OLED resolution of the AirGradient ONE.
  - Pixel-perfect 64×32 standard rendering.
- **Temperature Units**: Switch between Fahrenheit (°F) and Celsius (°C).
