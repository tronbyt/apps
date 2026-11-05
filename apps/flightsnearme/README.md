# Flight Overhead

Configure Location in Tronbyt app management. Search radius is in meters. Optionally choose a fallback airport/location and radius. Direction arrows appear only for the primary search; the original flight callsign stays visible. Owned regional subsidiaries use their parent airline logo; independent multi-brand operators are not guessed.

## Flight service

This app requires the compatible `/flights` service from https://github.com/davidozhang/tidbyt (server/app.py). Run that project's backend and enter a URL reachable from Tronbyt Server. `http://backend:5050` works with that project's Docker Compose deployment. The backend uses FlightRadar24; users must comply with the provider's terms. This is not a standalone direct-provider app.

No personal coordinates or credentials are bundled. Set Location before rendering; fallback is optional. See THIRD_PARTY_NOTICES.md for logo provenance and trademarks.
