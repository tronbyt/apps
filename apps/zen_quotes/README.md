# Zen Quotes

A daily dose of wisdom from [ZenQuotes.io](https://zenquotes.io), featuring a customizable display and a built-in breath pacer to help you center yourself.

## Configuration

### Cache Duration (Important!)

Since the quote only updates once per day, please set the **Cache-Control** / **TTL** to **86400 seconds (24 hours)**.

- This prevents unnecessary API calls to ZenQuotes.io.
- It ensures you always see the Quote of the Day without hitting rate limits.

### App Rotation (Dwell Time)

If you use the **Zen Breath Pacer** feature, you need to ensure the app stays on screen long enough to complete a full breathing cycle.

The total cycle time is calculated as:
`Cycle Time = (3 * Breath Duration) + 2 seconds`

| Breath Duration  | Total Cycle Time | Recommended Dwell Time |
| :--------------- | :--------------- | :--------------------- |
| 2s               | 8 seconds        | **10 seconds**         |
| 3s               | 11 seconds       | **13 seconds**         |
| **4s (Default)** | 14 seconds       | **16 seconds**         |
| 5s               | 17 seconds       | **19 seconds**         |
| 6s               | 20 seconds       | **22 seconds**         |
| 7s               | 23 seconds       | **25 seconds**         |
| 8s               | 26 seconds       | **28 seconds**         |

**Note**: If your Tidbyt is set to rotate apps every 10 or 15 seconds, a longer breathing cycle (like 6s) will be cut off before it finishes. Please adjust your installation's rotation duration accordingly.
