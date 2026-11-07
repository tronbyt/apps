"""
Applet: HomeGame
Summary: Next college football game
Description: Shows your college football team's next game - the matchup, a red HOME or green AWAY band, and the kickoff time, counting down once it's game day. Pick any team ESPN covers from the search box.
Author: tscott98
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# ESPN API endpoint for college football
ESPN_API_BASE = "http://site.api.espn.com/apis/site/v2/sports/football/college-football"

# Every team ESPN knows about, for the team picker. One payload covers the
# whole search, so it is fetched once and reused for the day.
TEAMS_URL = "%s/teams?limit=1000" % ESPN_API_BASE
TEAMS_TTL_SECONDS = 86400

# How long ESPN responses are reused before refetching
API_TTL_SECONDS = 300

# Picker tuning: shortest search worth running, and how many hits to offer.
MIN_SEARCH_LENGTH = 2
MAX_TEAM_RESULTS = 25

# Returned instead of game data when ESPN could not be reached at all, so the
# caller can skip the cycle rather than report a problem the user can't fix.
FETCH_FAILED = "fetch_failed"

# Default configuration
DEFAULT_TEAM_ID = "245"  # Example: Texas A&M
FALLBACK_TIMEZONE = "America/Chicago"

def main(config):
    """
    Main entry point for the HomeGame applet.

    Args:
        config: Configuration object with user settings

    Returns:
        render.Root object with the display layout, or an empty list to sit
        this cycle out
    """

    # Get configuration values
    team_id = resolve_team_id(config)
    timezone = resolve_timezone(config)

    # Fetch game data
    game_data = get_next_game(team_id, timezone)

    # ESPN is unreachable. Show nothing and let the next render retry rather
    # than holding the panel on a failure the viewer can do nothing about.
    if game_data == FETCH_FAILED:
        return []

    # ESPN answered, but this team has nothing on the schedule - the normal
    # state for most of the year.
    if game_data == None:
        return render_notice("NO GAME", "Nothing scheduled")

    # Parse game data
    our_team = game_data.get("our_team", "TEAM")
    opponent = game_data.get("opponent", "OPP")
    is_home_game = game_data.get("is_home_game", True)
    kickoff_date = game_data.get("kickoff_date", "")
    kickoff_time = game_data.get("kickoff_time", "")
    game_status = game_data.get("status", "upcoming")  # upcoming, countdown, in_progress
    countdown_text = game_data.get("countdown_text", "")

    # Render the display
    return render_game_display(
        our_team,
        opponent,
        is_home_game,
        kickoff_date,
        kickoff_time,
        game_status,
        countdown_text,
    )

def resolve_team_id(config):
    """
    Determines which team's schedule to show.

    The picker is a typeahead, which stores the choice as a JSON object of the
    form {"display": ..., "value": ...}. A bare string is accepted too, so the
    app can be driven from the command line, and the plain `team_id` field the
    app used before the picker existed is still honoured so that installs
    predating it keep working.

    Args:
        config: Configuration object with user settings

    Returns:
        ESPN team ID as a string
    """

    selection = config.get("team", "")
    if selection:
        if selection.startswith("{"):
            team_id = json.decode(selection).get("value", "")
            if team_id:
                return team_id
        else:
            return selection

    return config.get("team_id", DEFAULT_TEAM_ID)

def search_teams(pattern):
    """
    Typeahead handler backing the team picker.

    Args:
        pattern: What the user has typed so far

    Returns:
        List of schema.Option, best matches first
    """

    pattern = pattern.strip().lower()
    if len(pattern) < MIN_SEARCH_LENGTH:
        return []

    response = http.get(TEAMS_URL, ttl_seconds = TEAMS_TTL_SECONDS)
    if response.status_code != 200:
        print("Error fetching team list: HTTP %d" % response.status_code)
        return []

    leagues = response.json().get("sports", [{}])[0].get("leagues", [])
    if len(leagues) == 0:
        return []

    # ESPN lists every division, so a substring search alone buries the
    # obvious answer: "texas" matches East Texas Baptist as readily as the
    # Longhorns. Rank an abbreviation hit first, then names that start with
    # what was typed, and only then the rest.
    exact = []
    prefix = []
    contains = []

    for entry in leagues[0].get("teams", []):
        team = entry.get("team", {})
        name = team.get("displayName", "")
        team_id = team.get("id", "")
        if not name or not team_id:
            continue

        option = schema.Option(display = name, value = team_id)
        lowered = name.lower()

        if team.get("abbreviation", "").lower() == pattern:
            exact.append(option)
        elif lowered.startswith(pattern):
            prefix.append(option)
        elif pattern in lowered:
            contains.append(option)

    return (exact + prefix + contains)[:MAX_TEAM_RESULTS]

def resolve_timezone(config):
    """
    Determines which timezone to display kickoff times in.

    Prefers an explicit override from the app's config, then the timezone the
    host reports for the device, and finally a hardcoded fallback. On
    tronbyt-server the device timezone is always supplied, so the override
    field can be left empty.

    Args:
        config: Configuration object with user settings

    Returns:
        IANA timezone name as a string
    """

    override = config.get("timezone", "")
    if override:
        return override

    # tronbyt-server's pixlet exposes the device timezone as time.tz().
    # Guard the lookup so the app still runs on builds without it.
    tz_func = getattr(time, "tz", None)
    if tz_func != None:
        device_tz = tz_func()
        if device_tz and device_tz != "Local":
            return device_tz

    # Legacy config key, still set by tronbyt-server
    return config.get("$tz", FALLBACK_TIMEZONE)

def get_next_game(team_id, timezone):
    """
    Fetches the next scheduled game for the specified team.

    Args:
        team_id: ESPN team ID for the college football team
        timezone: User's timezone for time conversion

    Returns:
        Dictionary with game data, None if the team has no game scheduled, or
        FETCH_FAILED if ESPN could not be reached
    """

    # Fetch team schedule from ESPN API
    url = "%s/teams/%s" % (ESPN_API_BASE, team_id)

    # Make HTTP request with error handling. The response is cached by the
    # http module, so the time-sensitive fields below are always recomputed
    # from a fresh clock even when the payload is reused.
    response = http.get(url, ttl_seconds = API_TTL_SECONDS)

    if response.status_code != 200:
        print("Error fetching team data: HTTP %d" % response.status_code)
        return FETCH_FAILED

    # Parse response
    team_data = response.json()

    # Extract next event from team data
    # Note: The API structure may vary, this is a best-effort parse
    if not team_data or "team" not in team_data:
        print("Invalid team data structure")
        return FETCH_FAILED

    team_info = team_data.get("team", {})
    next_event = team_info.get("nextEvent", None)

    if next_event == None:
        # Try alternate API endpoint - scoreboard
        return get_next_game_from_scoreboard(team_id, timezone)

    # Parse next event
    return parse_game_event(next_event, team_id, timezone)

def get_next_game_from_scoreboard(team_id, timezone):
    """
    Fallback method to fetch game from scoreboard API.

    Args:
        team_id: ESPN team ID
        timezone: User's timezone for time conversion

    Returns:
        Dictionary with game data, None if nothing is scheduled, or
        FETCH_FAILED if ESPN could not be reached
    """

    # Get current date and next 30 days
    now = time.now()
    end_date = now + time.parse_duration("720h")  # 30 days

    date_range = "%s-%s" % (
        now.format("20060102"),
        end_date.format("20060102"),
    )

    url = "%s/scoreboard?dates=%s&groups=80" % (ESPN_API_BASE, date_range)

    response = http.get(url, ttl_seconds = API_TTL_SECONDS)

    if response.status_code != 200:
        print("Error fetching scoreboard: HTTP %d" % response.status_code)
        return FETCH_FAILED

    scoreboard_data = response.json()
    events = scoreboard_data.get("events", [])

    # Find the next game for this team
    for event in events:
        competitions = event.get("competitions", [])
        for competition in competitions:
            competitors = competition.get("competitors", [])

            # Check if this game involves our team
            for competitor in competitors:
                if competitor.get("id") == team_id or competitor.get("team", {}).get("id") == team_id:
                    return parse_game_event(event, team_id, timezone)

    return None

def parse_game_event(event, team_id, timezone):
    """
    Parses game event data from ESPN API.

    Args:
        event: Event data from ESPN API
        team_id: Our team's ID to determine home/away
        timezone: User's timezone for time conversion

    Returns:
        Dictionary with parsed game data
    """

    # Handle both dict and list access patterns
    if type(event) == "list":
        if len(event) == 0:
            return None
        event = event[0]

    competitions = event.get("competitions", [])
    if len(competitions) == 0:
        return None

    competition = competitions[0]

    # Safely access competitors
    if type(competition) == "dict":
        competitors = competition.get("competitors", [])
    else:
        return None

    # Find home and away teams
    home_team_data = None
    away_team_data = None
    is_home_game = False
    our_team_data = None
    opponent_team_data = None

    for competitor in competitors:
        home_away = competitor.get("homeAway", "")
        team = competitor.get("team", {})
        comp_team_id = str(team.get("id", ""))

        if home_away == "home":
            home_team_data = team
        elif home_away == "away":
            away_team_data = team

        # Check if this is our team
        if comp_team_id == str(team_id):
            our_team_data = team
            is_home_game = (home_away == "home")
        else:
            opponent_team_data = team

    if not home_team_data or not away_team_data:
        return None

    if not our_team_data or not opponent_team_data:
        return None

    # Get team names (use abbreviation for compact display)
    # Always show: OUR_TEAM vs OPPONENT
    our_team = our_team_data.get("abbreviation", our_team_data.get("name", "TEAM"))
    opponent = opponent_team_data.get("abbreviation", opponent_team_data.get("name", "OPP"))

    # Get game date/time
    # ESPN API returns time in UTC (with "Z" suffix)
    date_str = event.get("date", "")
    if date_str:
        # Parse the time from ESPN
        if date_str.endswith("Z") and date_str.count(":") == 1:
            # Format: "YYYY-MM-DDTHH:MMZ" (no seconds)
            parsed_time = time.parse_time(date_str, format = "2006-01-02T15:04Z")
        else:
            # Try RFC3339 format (with seconds)
            parsed_time = time.parse_time(date_str)

        # Convert to the display timezone
        game_time = parsed_time.in_location(timezone)
    else:
        game_time = time.now().in_location(timezone)

    # Determine game status
    status_data = competition.get("status", {})
    status_type = status_data.get("type", {})
    status_name = status_type.get("name", "scheduled")
    status_state = status_type.get("state", "")

    game_status = "upcoming"
    countdown_text = ""

    # time.now() is already device-local on tronbyt-server, but pin it to the
    # display timezone so the calendar-day comparison below can't straddle a
    # date boundary.
    now = time.now().in_location(timezone)
    time_until_game = game_time - now

    # Check if it's game day (same calendar day)
    # Compare dates: game date vs current date in same timezone
    game_date = game_time.format("2006-01-02")
    current_date = now.format("2006-01-02")

    if status_state == "in" or status_name == "STATUS_IN_PROGRESS":
        # Game is underway. This outranks the countdown, which would otherwise
        # claim every kickoff that falls on today's date.
        game_status = "in_progress"
    elif game_date == current_date and time_until_game.seconds > 0:
        # It's game day and game hasn't started yet - show countdown
        game_status = "countdown"
        countdown_text = format_countdown(time_until_game)
    elif game_date == current_date:
        # It's game day and kickoff has passed, but the API hasn't flipped the
        # status yet - hold at zero instead of falling back to the date
        game_status = "countdown"
        countdown_text = "0m"

    # Format kickoff time - split into date and time for flexible display
    kickoff_date = game_time.format("Jan 2")
    kickoff_time = game_time.format("3:04 PM")

    return {
        "our_team": our_team,
        "opponent": opponent,
        "is_home_game": is_home_game,
        "kickoff_date": kickoff_date,
        "kickoff_time": kickoff_time,
        "status": game_status,
        "countdown_text": countdown_text,
    }

def format_countdown(duration):
    """
    Formats time duration as countdown string.

    Args:
        duration: time.duration object

    Returns:
        Formatted countdown string (e.g., "2h 30m")
    """

    hours = int(duration.hours)
    minutes = int(duration.minutes % 60)

    if hours > 0:
        return "%dh %dm" % (hours, minutes)
    else:
        return "%dm" % minutes

def render_game_display(our_team, opponent, is_home_game, kickoff_date, kickoff_time, game_status, countdown_text):
    """
    Renders the game display layout with context-aware date/time formatting.

    Args:
        our_team: Our team name/abbreviation
        opponent: Opponent team name/abbreviation
        is_home_game: Boolean indicating if it's a home game for our team
        kickoff_date: Formatted kickoff date (e.g., "Oct 12")
        kickoff_time: Formatted kickoff time (e.g., "3:30 PM")
        game_status: Game status (upcoming, countdown, in_progress)
        countdown_text: Countdown text if applicable

    Returns:
        render.Root object
    """

    # Determine status color and text
    # REQUIREMENTS: HOME in RED, AWAY in GREEN
    if is_home_game:
        status_color = "#FF0000"  # RED for HOME
        status_text = "HOME"
    else:
        status_color = "#00FF00"  # GREEN for AWAY
        status_text = "AWAY"

    # Build display children
    children = [
        # Team matchup: OUR_TEAM vs OPPONENT
        render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                render.Text(
                    content = our_team,
                    font = "tb-8",
                    color = "#FFFFFF",
                ),
                render.Text(
                    content = " vs ",
                    font = "tb-8",
                    color = "#AAAAAA",
                ),
                render.Text(
                    content = opponent,
                    font = "tb-8",
                    color = "#FFFFFF",
                ),
            ],
        ),
        render.Box(width = 64, height = 2),  # Spacer

        # Home/Away indicator
        render.Box(
            width = 64,
            height = 12,
            color = status_color,
            child = render.Text(
                content = status_text,
                font = "6x13",
                color = "#000000",
            ),
        ),
        render.Box(width = 64, height = 2),  # Spacer
    ]

    # Add status-specific content based on game state
    if game_status == "in_progress":
        # Game is in progress: Show "IN PROGRESS"
        children.append(
            render.Text(
                content = "IN PROGRESS",
                font = "tb-8",
                color = "#FFFF00",
            ),
        )
    elif game_status == "countdown":
        # Game day (same calendar day): Show countdown timer and kickoff time on same line
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text(
                        content = countdown_text,
                        font = "tb-8",
                        color = "#FFFF00",
                    ),
                    render.Text(
                        content = kickoff_time,
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        )
    else:
        # Not game day: Show date on the left, kickoff time on the right.
        # Both share one row because the matchup, spacers and status band
        # leave only a single 8px line - a second one is clipped off the panel.
        # The space before AM/PM is dropped so the widest combinations
        # ("Sep 13" + "12:00 PM") keep a visible gap at 64px.
        children.append(
            render.Row(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Text(
                        content = kickoff_date,
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                    render.Text(
                        content = kickoff_time.replace(" ", ""),
                        font = "tb-8",
                        color = "#FFFFFF",
                    ),
                ],
            ),
        )

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "start",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def render_notice(headline, message):
    """
    Renders a short headline over an explanatory line.

    Used for the states that have no game to show. Amber rather than red:
    an empty schedule is the normal off-season condition, not a fault.

    Args:
        headline: Short all-caps word or two
        message: Explanatory line below it

    Returns:
        render.Root object
    """

    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text(
                        content = headline,
                        font = "6x13",
                        color = "#FFA500",
                    ),
                    render.Box(width = 64, height = 2),

                    # Wrapped, because the messages are longer than the 64px
                    # panel - a plain Text clips them at both ends.
                    render.WrappedText(
                        content = message,
                        font = "tb-8",
                        color = "#FFFFFF",
                        width = 64,
                        align = "center",
                    ),
                ],
            ),
        ),
    )

def get_schema():
    """
    Defines the configuration schema for user customization.

    Returns:
        schema.Schema object
    """

    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "team",
                name = "Team",
                desc = "Start typing a college football team, then pick it from the list.",
                icon = "football",
                handler = search_teams,
            ),
            schema.Text(
                id = "timezone",
                name = "Timezone",
                desc = "Override the device timezone (e.g. America/Chicago). Leave empty to follow the device.",
                icon = "clock",
                default = "",
            ),
        ],
    )
