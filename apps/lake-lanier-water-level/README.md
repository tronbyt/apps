# Lake Lanier Water Level Tidbyt App

A Tidbyt app that displays real-time water level information for Lake Lanier, including current levels, trend indicators, and historical charts.

## Prerequisites

- **Pixlet**: The app runtime for Tidbyt. Installation instructions are provided below.
- **Tidbyt Device**: Ensure your device is set up and connected to your network. Refer to the [Tidbyt Quickstart Guide](https://help.tidbyt.com/quickstart) for setup instructions.

## Installation Instructions for Pixlet

Pixlet is the tool used to develop and render apps for Tidbyt. Follow the steps below to install Pixlet on your system:

### macOS

1. **Install Homebrew** (if not already installed):

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install Pixlet**:

   ```bash
   brew install tidbyt/tidbyt/pixlet
   ```

### Linux

1. **Download the Latest Release**: Visit the [Pixlet Releases Page](https://github.com/tidbyt/pixlet/releases) and download the latest release for your Linux distribution.

2. **Install Pixlet**: Follow the installation instructions provided on the releases page for your specific distribution.

### Windows

1. **Download the Latest Release**: Visit the [Pixlet Releases Page](https://github.com/tidbyt/pixlet/releases) and download the Windows release.

2. **Extract and Add to PATH**: Extract the archive and add the `pixlet.exe` location to your system PATH.

For more detailed information, refer to the [Pixlet GitHub Repository](https://github.com/tidbyt/pixlet).

## Rendering and Previewing the App Locally

Once Pixlet is installed, you can render and preview the app locally:

1. **Navigate to the App Directory**: Open your terminal and change to the directory containing the `lanier_level.star` file:

   ```bash
   cd tidbyt
   ```

2. **Render the App**: Run the following command to render the app to a WebP image:

   ```bash
   pixlet render lanier_level.star
   ```

   This generates a `lanier_level.webp` file that you can view.

3. **Serve the App Locally** (Recommended for Testing): To preview the app in your browser with live updates, run:

   ```bash
   pixlet serve lanier_level.star
   ```

   Open your browser and navigate to `http://localhost:8080` to view the app. The app will automatically refresh when you make changes to the `.star` file.

## Pushing the App to Your Tidbyt Device

To deploy the app to your Tidbyt device:

1. **Obtain Your Device ID and API Key**:

   - Open the Tidbyt app on your phone.
   - Navigate to **Settings** > **General** > **Get API Key**.
   - Note down your **Device ID** and **API Key**.

2. **Render the App** (if not already done):

   ```bash
   pixlet render lanier_level.star
   ```

3. **Push the App to Your Device**: Run the following command, replacing `<YOUR_DEVICE_ID>` and `<YOUR_API_KEY>` with the values obtained in step 1:

   ```bash
   pixlet push --api-token <YOUR_API_KEY> <YOUR_DEVICE_ID> lanier_level.webp
   ```

   This command sends the rendered app to your Tidbyt device.

   **Alternative**: You can also push directly from the `.star` file without rendering first:

   ```bash
   pixlet push --api-token <YOUR_API_KEY> <YOUR_DEVICE_ID> lanier_level.star
   ```

For more details on pushing apps to your Tidbyt, refer to the [Pixlet GitHub Repository](https://github.com/tidbyt/pixlet).

## Configuration Options

The `lanier_level.star` file includes the following configuration options:

### Display Mode

The `DISPLAY_MODE` constant at the top of the file controls which display mode the app uses:

```python
DISPLAY_MODE = "alternate"  # Options: "A", "B", or "alternate"
```

**Available Modes:**

- **`"A"`** - Simple Stats Display
  - Shows "Lake Lanier" header
  - Current water level in feet (large text)
  - Feet above/below full pool with color-coded status and trend arrow

- **`"B"`** - Mini Chart Display
  - Top: Current level + trend icon
  - Bottom: 7-day historical chart showing water level changes

- **`"alternate"`** - Automatically switches between modes
  - Shows chart mode when sufficient historical data is available (7+ data points)
  - Falls back to simple stats mode otherwise

To change the display mode, edit line 7 in `lanier_level.star`:

```python
DISPLAY_MODE = "A"  # Change to "A", "B", or "alternate"
```

After making changes, re-render and push the app to your device.

### Schema Configuration (Tidbyt App Store)

The app includes a schema for Tidbyt App Store submission, which allows users to configure the app through the Tidbyt mobile app interface. The schema provides a toggle option:

- **Show Chart** (`show_chart`): Toggle to show the 7-day history chart
  - `False` (default): Shows simple stats display
  - `True`: Shows mini chart display with historical data

When the app is installed from the Tidbyt App Store, users can configure this option directly in the Tidbyt mobile app without editing the code.

**Note**: The schema configuration takes priority over the `DISPLAY_MODE` constant. When using the app directly (not from App Store), you can still use the `DISPLAY_MODE` constant or pass configuration via the `config` parameter.

### Color-Coded Status Indicators

The app uses color coding to indicate water level status relative to full pool (1071 ft):

- **Green (#00FF00)**: `feet_above_full >= -1` - Near or above full
- **Yellow (#FFFF00)**: `feet_above_full >= -3` - Slightly below
- **Orange (#FFA500)**: `feet_above_full >= -5` - Moderately below
- **Red (#FF0000)**: `feet_above_full < -5` - Significantly below

### Trend Indicators

The app displays trend arrows based on water level changes:

- **↑** - Water level is rising
- **↓** - Water level is falling
- **→** - Water level is stable

## App Features

- **Real-time Data**: Fetches latest water level data from the Lake Lanier API
- **Historical Charts**: Displays 7-day water level trends (Mode B)
- **Color-Coded Status**: Visual indicators for water level conditions
- **Trend Analysis**: Shows whether water levels are rising, falling, or stable
- **Dual Display Modes**: Choose between simple stats or chart view

## Troubleshooting

### Common Issues

**Pixlet command not found**
- Ensure Pixlet is installed and added to your system PATH
- Try reinstalling Pixlet using the installation instructions above

**API Error displayed on device**
- Check your internet connection
- Verify the API endpoint is accessible: `https://attrhlvatssgurlriewu.supabase.co/functions/v1/water-level-api?endpoint=latest`
- The API may be temporarily unavailable

**App not appearing on device**
- Verify your Device ID and API Key are correct
- Ensure your Tidbyt device is connected to the internet
- Check that the device is not in sleep mode

**Chart not displaying (Mode B)**
- Ensure you have at least 7 days of historical data
- The app will automatically fall back to Mode A if insufficient data is available

### Getting Help

For additional support:
- [Tidbyt Help Center](https://help.tidbyt.com/)
- [Pixlet GitHub Repository](https://github.com/tidbyt/pixlet)
- [Tidbyt Community Forum](https://community.tidbyt.com/)

## Submitting to Tidbyt App Store

If you want to publish this app to the Tidbyt community App Store:

1. **Prepare Your App Files**:
   - `lanier_level.star` - Main app file (already includes schema)
   - `icon.png` - 20x20 pixel icon (optional but recommended)
   - `README.md` - Documentation (this file)

2. **Create the Icon** (optional):
   - Create a 20x20 pixel PNG image
   - Save it as `tidbyt/icon.png`
   - The icon should represent Lake Lanier or water levels

3. **Test Your App**:
   - Ensure the app works correctly with both display modes
   - Test with the schema configuration toggle
   - Verify API connectivity and error handling

4. **Submit to Tidbyt**:
   - Follow the [Tidbyt App Store submission guidelines](https://tidbyt.dev/)
   - Submit your app through the Tidbyt community portal
   - Include a description, tags, and screenshots

The app already includes the `get_schema()` function required for App Store submission, which allows users to toggle the chart display through the Tidbyt mobile app interface.

## Data Source

This app fetches water level data from the Lake Lanier Water Level API, which provides real-time information from the USGS monitoring station for Lake Sidney Lanier (site ID: 02334400).

---

**Note**: Full pool elevation for Lake Lanier is 1071 feet above sea level. The app displays both the absolute gage height and the feet above/below full pool level.

