# Kīlauea Activity

Kīlauea Activity turns the latest official USGS Hawaiian Volcano Observatory notice into an original animated pixel-art caldera. It intentionally complements Tronbyt's existing webcam-based Kilauea app rather than replacing it.

The app distinguishes quiet, precursor/building, erupting, warning, and unavailable states. Its status cards show the literal bulletin phase, the USGS alert level and aviation color, and either the update date or a forecast window extracted from the bulletin. A paused eruption can therefore remain labeled **PAUSED** while the caldera uses the warmer building treatment when USGS reports precursor or forecast signals.

Data comes from the structured USGS HANS endpoint for volcano `332010`:

<https://volcanoes.usgs.gov/hans-public/api/volcano/newestForVolcano/332010>

Responses are cached for five minutes. The app retains the last valid normalized notice as a temporary fallback, marks notices stale after 48 hours, and will not present a notice older than seven days as current. It requires no API key, secrets, user data, or configuration.

For deterministic visual review, render every primary state in one loop:

```sh
pixlet render apps/kilaueaactivity fixture=cycle -o kilaueaactivity.webp
```

This is an informational display, not an emergency-alerting system. Follow current USGS and civil-defense guidance for safety decisions.
