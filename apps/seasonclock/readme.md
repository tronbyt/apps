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

## Previewing any date

The `dev_date` config key (an RFC3339 instant, e.g. `2026-12-25T12:00:00Z`)
overrides the current time so you can preview any season or day. It is a
test-only hook and is intentionally not part of the published schema:

```sh
pixlet render seasonclock.star dev_date=2026-12-25T12:00:00Z
```
