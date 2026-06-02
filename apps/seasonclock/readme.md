# Season Clock

A lively seasonal scene with two display modes:

- **Countdown to next season** — e.g. `65 DAYS TO SUMMER`
- **Current day of season** — e.g. `10th DAY OF SPRING`

Stack two instances back-to-back to see both at once (e.g. *"10th day of
spring"* and *"65 days to summer"*).

Each season has its own animated scene:

| Season | Scene |
| ------ | ----- |
| Spring | flowers growing + butterflies |
| Summer | sun, pool & splashing droplets |
| Autumn | tree with falling leaves |
| Winter | falling snow + a snowman |

## Configuration

- **Location** — used only to determine your **hemisphere** (northern /
  southern, from latitude) and **timezone**. The southern hemisphere maps the
  astronomical instants to the opposite seasons automatically.
- **Display** — *Countdown to next season* or *Current day of season*.

## Accuracy

Season changes are the true **astronomical equinoxes and solstices**, which
drift by date and time each year. Their UTC instants for **2024–2036** are
embedded directly in the app (computed via Meeus' algorithm, validated to the
minute against published values) — no network call, no external data feed.
Outside that range the app shows an "update" notice; refresh the `BOUNDARIES`
table to extend it.

## Testing

`test_harness.py` renders the full matrix (2 hemispheres × 4 seasons × 2 modes ×
1x/2x) deterministically using the hidden `dev_date` override, and independently
re-computes the expected season and day count in Python to cross-check the
rendered output. It parses the `BOUNDARIES` table out of `seasonclock.star` so
there is a single source of truth.

```sh
PIXLET=/path/to/pixlet python3 apps/seasonclock/test_harness.py
```

The `dev_date` config key (an RFC3339 instant) is a test-only hook and is not
part of the published schema.
