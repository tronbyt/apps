# Icecast Now Playing - Tidbyt App

A Tidbyt app that displays the currently playing track from any Icecast streaming server in real-time.

## About

This app connects to an Icecast server's `status-json.xsl` endpoint to show what's currently playing on your Tidbyt display. It's perfect for displaying your internet radio station, personal stream, or any Icecast-powered audio stream.

### Features

- Displays the current track title from your Icecast stream
- Shows the server name from Icecast (or use a custom name)
- Customizable text color
- Automatic scrolling for long titles
- 30-second cache for efficient API usage

### Configuration

The app supports the following configuration options:

- **Icecast Status URL** (required): The URL to your Icecast server's `status-json.xsl` endpoint
  - Example: `http://icecast.example.com:8000/status-json.xsl`
- **Custom Stream Name** (optional): Override the server name with your own custom name
  - Leave blank to use the `server_name` from your Icecast server
- **Text Color**: Color for track information text (default: `#0ff1b2`)

### How to Find Your Icecast Status URL

1. Find your Icecast server address and port (e.g., `icecast.example.com:8000`)
2. Add `/status-json.xsl` to the end
3. Full URL example: `http://icecast.example.com:8000/status-json.xsl`

### Icecast JSON Format

This app expects the Icecast `status-json.xsl` endpoint to return JSON in the standard Icecast format:

```json
{
  "icestats": {
    "source": {
      "title": "Artist - Song Title",
      "server_name": "My Radio Station"
    }
  }
}
```

The app extracts the `title` field from the first source and displays it along with the `server_name`.

## License

MIT License - see LICENSE file for details
