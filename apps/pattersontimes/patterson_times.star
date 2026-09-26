"""
Applet: Patterson Times
Summary: Patterson SkyTrain Times
Description: Displays next train times for Patterson SkyTrain station in Vancouver. More stations coming soon.
Author: Aiden Mitchell
"""

load("http.star", "http")
load("images/expo_icon.png", EXPO_ICON_ASSET = "file")
load("render.star", "render")
load("time.star", "time")

EXPO_ICON = EXPO_ICON_ASSET.readall()

API_URL = "https://gist.githubusercontent.com/aidenmitchell/95184f9d8a352908afc118b08a537d3f/raw"

def fetch_train_data():
    r = http.get(API_URL)
    if r.status_code == 200:
        return r.json()
    else:
        return None

def get_local_time():
    # Get the current UTC time
    utc_time = time.now()

    # Convert the UTC time into total minutes since midnight
    utc_minutes_since_midnight = utc_time.hour * 60 + utc_time.minute

    # Offset for PDT (UTC-7 hours)
    offset_minutes = -7 * 60

    # Calculate local minutes since midnight
    local_minutes_since_midnight = (utc_minutes_since_midnight + offset_minutes) % (24 * 60)

    # Convert the total minutes back to hours and minutes for the local time
    local_hour = local_minutes_since_midnight // 60
    local_minute = local_minutes_since_midnight % 60

    # Construct a new time object for local time
    local_time = time.time(hour = local_hour, minute = local_minute)

    return local_time

def format_time_difference(time_diff):
    """Format the time difference. If it's 0, return 'now'."""
    return "now" if time_diff == 0 else "{} min".format(time_diff)

def parse_time_to_minutes(time_str):
    """Convert a time string in the format 'HH:MM:SS' to minutes since midnight."""
    hours, minutes, _ = [int(part) for part in time_str.split(":")]
    return hours * 60 + minutes

def time_difference_in_minutes(start, end):
    """Calculate the time difference in minutes, accounting for times that cross over midnight."""
    if end >= start:
        return end - start
    else:
        # Account for times that cross over midnight
        return (24 * 60 - start) + end

def get_towards_waterfront_times(train_data):
    """Retrieve the two nearest train times towards Waterfront."""
    current_time_minutes = get_local_time().hour * 60 + get_local_time().minute
    towards_waterfront_times = sorted([t for t, dest in train_data.items() if dest == "Waterfront" and parse_time_to_minutes(t) > current_time_minutes])
    two_nearest_towards_waterfront = towards_waterfront_times[:2]
    towards_waterfront_diff = [time_difference_in_minutes(current_time_minutes, parse_time_to_minutes(t)) for t in two_nearest_towards_waterfront]

    return towards_waterfront_diff

def get_away_from_waterfront_times(train_data):
    """Retrieve the nearest "away from Waterfront" destination and its two nearest departure times."""
    current_time_minutes = get_local_time().hour * 60 + get_local_time().minute
    away_from_waterfront_times = sorted([t for t, dest in train_data.items() if dest != "Waterfront" and parse_time_to_minutes(t) > current_time_minutes])
    nearest_away_destination = train_data[away_from_waterfront_times[0]]
    two_nearest_away_times_for_nearest_destination = sorted([t for t, dest in train_data.items() if dest == nearest_away_destination and parse_time_to_minutes(t) > current_time_minutes])[:2]
    away_from_waterfront_diff = [time_difference_in_minutes(current_time_minutes, parse_time_to_minutes(t)) for t in two_nearest_away_times_for_nearest_destination]

    return nearest_away_destination, away_from_waterfront_diff

def render_train_times():
    train_data = fetch_train_data()
    if not train_data:
        return render.Text("Failed to fetch train data.")

    # Retrieve times
    towards_waterfront_diff = get_towards_waterfront_times(train_data)
    nearest_away_destination, away_from_waterfront_diff = get_away_from_waterfront_times(train_data)

    # Convert times to relative format
    waterfront_relative_times = [format_time_difference(diff) for diff in towards_waterfront_diff]
    kg_pwu_relative_times = [format_time_difference(diff) for diff in away_from_waterfront_diff]

    return render.Root(
        child = render.Column(
            children = [
                # First row for "Waterfront"
                render.Row(
                    children = [
                        # Column 1
                        render.Image(src = EXPO_ICON, width = 14),
                        # Column 2
                        render.Column(
                            children = [
                                render.Marquee(width = 64, child = render.Text("Waterfront", font = "CG-pixel-4x5-mono")),
                                render.Box(height = 1),
                                render.Marquee(width = 64 - 10, child = render.Text(",".join(waterfront_relative_times), font = "CG-pixel-4x5-mono", color = "#B84")),
                            ],
                        ),
                    ],
                ),
                # Padding of 8 pixels between rows
                render.Box(height = 4),
                # Second row for the nearest away destination
                render.Row(
                    children = [
                        # Column 3
                        render.Image(src = EXPO_ICON, width = 14),
                        # Column 4
                        render.Column(
                            children = [
                                render.Marquee(width = 64 - 10, child = render.Text(nearest_away_destination, font = "CG-pixel-4x5-mono")),
                                render.Box(height = 1),
                                render.Marquee(width = 64 - 10, child = render.Text(",".join(kg_pwu_relative_times), font = "CG-pixel-4x5-mono", color = "#B84")),
                            ],
                        ),
                    ],
                ),
            ],
        ),
    )

def main():
    return render_train_times()
