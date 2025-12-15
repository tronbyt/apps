# Arc Raiders Stats

Display current Arc Raiders player count and active event timers on your Tidbyt.

## Features

- **Real-time Player Count**: Shows the current number of active players from Steam
- **Event Timers**: Displays currently active in-game events with their map locations
- **Auto-refresh**: Updates events every 5 minutes and player count every 10 minutes

## Configuration

### Settings

- **Show Player Count** (toggle): Display the current player count from Steam
- **Show Events** (toggle): Display currently active event timers
- **Scroll Speed** (dropdown): Control the speed of event scrolling animation (Slow/Medium/Fast)

## Data Sources

### Steam public API
- **Endpoint**: `https://api.steampowered.com/ISteamUserStats/GetNumberOfCurrentPlayers/v1/`
- **App ID**: 1808500 (Arc Raiders)
- **Cache**: 10 minutes

### MetaForge API
- **Endpoint**: `https://metaforge.app/api/arc-raiders/event-timers`
- **Data**: Event schedules with times and map locations
- **Cache**: 5 minutes
- **Attribution**: Data provided by [metaforge.app/arc-raiders](https://metaforge.app/arc-raiders)

## Display

The app shows:
1. **Title bar**: Pixelated ARC RAIDERS 
2. **Player count**: Current active players (if enabled)
3. **Active events**: Scrolling list of events currently happening with their map locations

## Technical Details

- **Language**: Starlark
- **Refresh Rate**: Recommended 10-second interval
- **Cache Strategy**:
  - Event data cached for 5 minutes
  - Player count cached for 10 minutes
- **Error Handling**: Gracefully handles API failures with fallback messages

## Attribution

- Arc Raiders is a game by Embark Studios
- Event timer data provided by [MetaForge](https://metaforge.app/arc-raiders)
- Player count data from Steam Web API

## Author
Chris Nourse
