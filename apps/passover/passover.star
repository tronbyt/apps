"""
Applet: Passover
Summary: Passover Countdown & Celebration
Description: Shows countdown to Passover or which day of the 8-day celebration it is
Author: jvivona
"""

load("images/cup.png", CUP = "file")
load("images/star.png", STAR = "file")
load("render.star", "canvas", "render")
load("time.star", "time")

# 2x (128x64) adds a Star of David + Kiddush cup and an expanded date line;
# 1x (64x32) is unchanged.
IS2X = canvas.is2x()

STAR_IMG = STAR.readall()
CUP_IMG = CUP.readall()

PASSOVER_DATES = [
    {"year": 2026, "start": "2026-04-01", "end": "2026-04-08"},
    {"year": 2027, "start": "2027-04-22", "end": "2027-04-29"},
    {"year": 2028, "start": "2028-04-10", "end": "2028-04-17"},
    {"year": 2029, "start": "2029-03-31", "end": "2029-04-07"},
    {"year": 2030, "start": "2030-04-18", "end": "2030-04-25"},
    {"year": 2031, "start": "2031-04-08", "end": "2031-04-15"},
    {"year": 2032, "start": "2032-03-27", "end": "2032-04-03"},
    {"year": 2033, "start": "2033-04-14", "end": "2033-04-21"},
    {"year": 2034, "start": "2034-04-04", "end": "2034-04-11"},
    {"year": 2035, "start": "2035-03-24", "end": "2035-03-31"},
    {"year": 2036, "start": "2036-04-10", "end": "2036-04-17"},
]

# Hebrew text for Passover
PASSOVER_HEBREW = "פסח"
CHAG_SAMEACH = "חג שמח"

def main():
    now = time.now().in_location(time.tz())

    # Find current or next Passover
    current_passover = None
    next_passover = None

    for passover in PASSOVER_DATES:
        start_time = time.parse_time(passover["start"] + "T00:00:00Z").in_location(time.tz())
        end_time = time.parse_time(passover["end"] + "T23:59:59Z").in_location(time.tz())

        # Check if we're currently in Passover
        if now >= start_time and now <= end_time:
            current_passover = passover
            break

        # Find next Passover
        if now < start_time and next_passover == None:
            next_passover = passover
            break

    if current_passover:
        return render_during_passover(current_passover, now, time.tz())
    elif next_passover:
        return render_countdown(next_passover, now, time.tz())
    else:
        return render_default()

# --- 2x sprite helpers -------------------------------------------------------

def top_row_2x(with_cup):
    """Star of David + Hebrew word, optionally flanked by the Kiddush cup."""
    children = [
        render.Image(src = STAR_IMG),
        render.Box(width = 5, height = 1),
        render.Text(content = PASSOVER_HEBREW, font = "6x13", color = "#FFD700"),
    ]
    if with_cup:
        children.append(render.Box(width = 5, height = 1))
        children.append(render.Image(src = CUP_IMG))
    return render.Row(
        main_align = "center",
        cross_align = "center",
        children = children,
    )

def frame_2x(children):
    return render.Root(
        child = render.Box(
            width = 128,
            height = 64,
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
    )

# --- During Passover ---------------------------------------------------------

def render_during_passover(passover, now, timezone):
    """Render display during Passover showing which day it is"""
    start_time = time.parse_time(passover["start"] + "T00:00:00Z").in_location(timezone)

    # Calculate which day of Passover (1-8)
    days_diff = int((now - start_time).hours / 24) + 1
    day_of_passover = min(days_diff, 8)

    # Day names for the 8 days
    day_names = [
        "First Seder",
        "Second Seder",
        "Third Day",
        "Fourth Day",
        "Fifth Day",
        "Sixth Day",
        "Seventh Day",
        "Eighth Day",
    ]

    day_name = day_names[day_of_passover - 1]

    if IS2X:
        return frame_2x([
            top_row_2x(True),
            render.Text(content = CHAG_SAMEACH, font = "6x13", color = "#87CEEB"),
            render.Text(content = day_name, font = "5x8", color = "#FFFFFF"),
            render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(content = "Day ", font = "tb-8", color = "#98D8C8"),
                    render.Text(content = str(day_of_passover), font = "tb-8", color = "#FFD700"),
                    render.Text(content = " of 8", font = "tb-8", color = "#98D8C8"),
                ],
            ),
        ])

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    # Top section with Hebrew
                    render.Box(
                        height = 8,
                        child = render.Text(
                            content = PASSOVER_HEBREW,
                            font = "6x13",
                            color = "#FFD700",
                        ),
                    ),
                    # Middle section with celebration text
                    render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = "חג שמח",
                                font = "6x13",
                                color = "#87CEEB",
                            ),
                            render.Box(height = 2),
                            render.Text(
                                content = day_name,
                                font = "tom-thumb",
                                color = "#FFFFFF",
                            ),
                        ],
                    ),
                    # Bottom section with day number
                    render.Box(
                        height = 12,
                        child = render.Row(
                            main_align = "center",
                            cross_align = "center",
                            children = [
                                render.Text(
                                    content = "Day ",
                                    font = "tb-8",
                                    color = "#98D8C8",
                                ),
                                render.Text(
                                    content = str(day_of_passover),
                                    font = "tb-8",
                                    color = "#FFD700",
                                ),
                                render.Text(
                                    content = " of 8",
                                    font = "tb-8",
                                    color = "#98D8C8",
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        ),
    )

# --- Countdown ---------------------------------------------------------------

def render_countdown(passover, now, timezone):
    """Render countdown to next Passover"""
    start_time = time.parse_time(passover["start"] + "T00:00:00Z").in_location(timezone)

    # Calculate time until Passover
    time_until = start_time - now
    days_until = int(time_until.hours / 24)

    if IS2X:
        # Parse at noon UTC so the displayed calendar date never shifts a day
        # under a negative UTC offset (e.g. America/New_York).
        start_disp = time.parse_time(passover["start"] + "T12:00:00Z").in_location(timezone)
        return frame_2x([
            top_row_2x(True),
            render.Row(
                cross_align = "center",
                children = [
                    render.Text(content = str(days_until), font = "6x13", color = "#FFD700"),
                    render.Text(content = " days", font = "6x13", color = "#FFFFFF"),
                ],
            ),
            render.Column(
                cross_align = "center",
                children = [
                    render.Text(content = start_disp.format("Monday"), font = "5x8", color = "#FFFFFF"),
                    render.Text(content = start_disp.format("January 2"), font = "tom-thumb", color = "#FFFFFF"),
                    render.Text(content = str(passover["year"]), font = "tom-thumb", color = "#98D8C8"),
                ],
            ),
        ])

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    # Top section with Hebrew
                    render.Box(
                        height = 12,
                        child = render.Text(
                            content = PASSOVER_HEBREW,
                            font = "6x13",
                            color = "#FFD700",
                        ),
                    ),
                    # Middle section with countdown
                    render.Column(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Text(
                                content = "Countdown",
                                font = "tom-thumb",
                                color = "#87CEEB",
                            ),
                            render.Box(height = 1),
                            render.Row(
                                main_align = "center",
                                children = [
                                    render.Text(
                                        content = str(days_until),
                                        font = "6x13",
                                        color = "#FFD700",
                                    ),
                                    render.Box(width = 2),
                                    render.Text(
                                        content = "days" if days_until != 1 else "day",
                                        font = "6x13",
                                        color = "#FFFFFF",
                                    ),
                                ],
                            ),
                        ],
                    ),
                    # Bottom section with year
                    render.Box(
                        height = 8,
                        child = render.Text(
                            content = str(passover["year"]),
                            font = "tom-thumb",
                            color = "#98D8C8",
                        ),
                    ),
                ],
            ),
        ),
    )

# --- Default -----------------------------------------------------------------

def render_default():
    """Default render if no Passover data available"""
    if IS2X:
        return frame_2x([
            top_row_2x(True),
            render.Text(content = "Passover", font = "6x13", color = "#FFFFFF"),
        ])

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(
                        content = PASSOVER_HEBREW,
                        font = "6x13",
                        color = "#FFD700",
                    ),
                    render.Box(height = 4),
                    render.Text(
                        content = "Passover",
                        font = "tom-thumb",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        ),
    )
