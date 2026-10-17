# School Days Left

Tidbyt/Pixlet applet for counting actual school days left in a school year.

The app counts weekdays from today through the configured last day of school,
excluding Saturdays, Sundays, and configured days off.

## Configuration

- `Last Day`: the final school day, counted inclusively.
- `Days Off`: optional `YYYY-MM-DD` dates to skip, one per line or comma separated.
- `Accent Color`: highlight color for the ruler stripe and completed state.

## Local Preview

Install Pixlet, then from the community repo root:

```bash
pixlet serve apps/schooldaysleft \
  last_day=2026-06-12T15:00:00-07:00 \
  days_off=2026-05-25
```

Render a static preview:

```bash
pixlet render apps/schooldaysleft \
  last_day=2026-06-12T15:00:00-07:00 \
  days_off=2026-05-25
```

Generate a magnified preview:

```bash
pixlet render apps/schooldaysleft \
  last_day=2026-06-12T15:00:00-07:00 \
  days_off=2026-05-25 \
  --gif \
  --magnify 10 \
  -o schooldaysleft.gif
```
