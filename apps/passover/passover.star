"""
Applet: Passover
Summary: Passover Countdown & Celebration
Description: Shows countdown to Passover or which day of the 8-day celebration it is
Author: jvivona
"""

load("render.star", "render")
load("time.star", "time")

# Hebrew text for Passover
PASSOVER_HEBREW = "פסח"

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

def render_countdown(passover, now, timezone):
    """Render countdown to next Passover"""
    start_time = time.parse_time(passover["start"] + "T00:00:00Z").in_location(timezone)

    # Calculate time until Passover
    time_until = start_time - now
    days_until = int(time_until.hours / 24)

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

def render_default():
    """Default render if no Passover data available"""
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
