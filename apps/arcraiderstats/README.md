# Arc Raiders Stats

Display current Arc Raiders player count and active event timers with live countdowns on your Tronbyt.

## Features

- **Real-time Player Count**: Shows the current number of active players from Steam
- **Live Event Countdowns**: Displays currently active in-game events with real-time countdown timers
- **Dynamic Animations**: Smooth scroll-in, pause, and scroll-out transitions that adapt to the number of events
- **Adaptive Time Formatting**: Countdown displays automatically adjust format based on remaining time (days/hours, hours/minutes, or minutes/seconds)
- **Horizontal Scrolling**: Long event names and map names scroll horizontally to fit the display
- **Auto-refresh**: Updates events every 12 hours and player count every 10 minutes

## Configuration

This app has no user-configurable settings. Animation timing automatically adapts to your device's display time settings configured on the Tidbyt server.

## Data Sources

### Steam public API
- **Endpoint**: `https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/`
- **App ID**: 1808500 (Arc Raiders)
- **Cache**: 10 minutes

### ARCRaidersHub API
- **Endpoint**: `https://arcraidershub.com/data/events.json`
- **Data**: Hourly event schedules with map locations for all game maps
- **Cache**: 12 hours
- **Attribution**: Data provided by [arcraidershub.com](https://arcraidershub.com)

## Display

The app shows:
1. **Title bar**: Pixelated ARC RAIDERS logo
2. **Player count**: Current active players with formatted numbers (e.g., "286.2K")
3. **Active events**: Animated list of events with:
   - Map name (white text)
   - Event name (yellow text)
   - Live countdown timer (red text) showing time remaining until event ends

## Technical Details

- **Language**: Starlark
- **Refresh Rate**: Recommended 10-second interval
- **Cache Strategy**:
  - Event data cached for 12 hours
  - Player count cached for 10 minutes
- **Countdown Updates**: Event timers count down in real-time during the entire animation sequence
- **Error Handling**: Gracefully handles API failures with fallback messages

## Attribution

- Arc Raiders is a game by Embark Studios
- Event timer data provided by [ARCRaidersHub](https://arcraidershub.com)
- Player count data from Steam Web API

## Author
Chris Nourse
