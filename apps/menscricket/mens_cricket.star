"""
Applet: Cricket Scoreboard (formerly Mens Cricket)
Summary: Display cricket scores
Description: For a selected team, this app shows the scorecard for a current match. If no match in progress, it will display scorecard for a recently completed match. If none of these, it will display the next match details in user's local timezone.
Author: adilansari

v 1.0 - Initial version with T20/ODI match support
v 1.1 - Using CricBuzz API for match data and adding Test match support
v 1.2 - Add Big Bash League team support
v 1.3 - Add support for womens' teams where listed in CricBuzz
v 1.4 - Add 2x support
"""

load("cricbuzz.star", "load_display_match")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("scoreboard.star", "render_scoreboard")
load("time.star", "time")

DEFAULT_TEAM_ID = "4"
DEFAULT_RESULT_DAYS = 1
ALWAYS_SHOW_FIXTURES = "Always"
BLACK_COLOR = "#222222"

def _team_setting(id, name, abbr, fg_color, bg_color):
    return struct(id = str(id), name = name, abbr = abbr, fg_color = fg_color, bg_color = bg_color)

team_settings_by_id = {
    team.id: team
    for team in [
        # International teams
        _team_setting("96", "Afghanistan", "AFG", "#D32011", BLACK_COLOR),
        _team_setting("4", "Australia", "AUS", "#FFCE00", "#006A4A"),
        _team_setting("100", "Australia Women", "AUSW", "#FFCE00", "#006A4A"),
        _team_setting("6", "Bangladesh", "BAN", "#F42A41", "#006A4E"),
        _team_setting("329", "Bangladesh Women", "BANW", "#F42A41", "#006A4E"),
        _team_setting("9", "England", "ENG", "#FFFFFF", "#CE1124"),
        _team_setting("99", "England Women", "ENGW", "#FFFFFF", "#CE1124"),
        _team_setting("2", "India", "IND", "#FFAC1C", "#050CEB"),
        _team_setting("97", "India Women", "INDW", "#FFAC1C", "#050CEB"),
        _team_setting("27", "Ireland", "IRE", "#169B62", "#FF883E"),
        _team_setting("189", "Ireland Women", "IREW", "#169B62", "#FF883E"),
        _team_setting("24", "Netherlands", "NED", "#FFFFFF", "#FF4F00"),
        _team_setting("188", "Netherlands Women", "NEDW", "#FFFFFF", "#FF4F00"),
        _team_setting("13", "New Zealand", "NZ", "#FFFFFF", "#008080"),
        _team_setting("98", "New Zealand Women", "NZW", "#FFFFFF", "#008080"),
        _team_setting("3", "Pakistan", "PAK", "#FFFFFF", "#115740"),
        _team_setting("259", "Pakistan Women", "PAKW", "#FFFFFF", "#115740"),
        _team_setting("23", "Scotland", "SCO", "#FFFFFF", "#005EB8"),
        _team_setting("389", "Scotland Women", "SCOW", "#FFFFFF", "#005EB8"),
        _team_setting("11", "South Africa", "SA", "#FFB81C", "#007749"),
        _team_setting("260", "South Africa Women", "RSAW", "#FFB81C", "#007749"),
        _team_setting("5", "Sri Lanka", "SL", "#EB7400", "#0A2351"),
        _team_setting("258", "Sri Lanka Women", "SLW", "#EB7400", "#0A2351"),
        _team_setting("15", "United States", "USA", "#B31942", "#003087"),
        _team_setting("592", "United States Women", "USAW", "#B31942", "#003087"),
        _team_setting("10", "West Indies", "WI", "#f2b10e", "#660000"),
        _team_setting("257", "West Indies Women", "WIW", "#f2b10e", "#660000"),
        _team_setting("12", "Zimbabwe", "ZIM", "#FCE300", "#EF3340"),
        _team_setting("388", "Zimbabwe Women", "ZIMW", "#FCE300", "#EF3340"),

        # Indian Premier League teams
        _team_setting("63", "Kolkata Knight Riders", "KKR", "#F7D54E", "#3A225D"),
        _team_setting("65", "Punjab Kings", "PK", "#D3D3D3", "#DD1F2D"),
        _team_setting("62", "Mumbai Indians", "MI", "#E9530D", "#004B8D"),
        _team_setting("1468", "Mumbai Indians Women", "MIW", "#E9530D", "#004B8D"),
        _team_setting("966", "Lucknow Giants", "LSG", "#F28B00", "#0057E2"),
        _team_setting("971", "Gujarat Titans", "GT", "#DBBE6E", "#002244"),
        _team_setting("1479", "Gujarat Giants Women", "GGTW", "#DBBE6E", "#002244"),
        _team_setting("255", "Sunrisers Hyderabad", "SRH", "#FCCB11", "#B02528"),
        _team_setting("61", "Delhi Capitals", "DC", "#D71921", "#282968"),
        _team_setting("1461", "Delhi Capitals Women", "DCW", "#D71921", "#282968"),
        _team_setting("59", "Royal Challengers Bangaluru", "RCB", "#D1AB3E", "#EC1C24"),
        _team_setting("1465", "Royal Challengers Bangaluru Women", "RCBW", "#D1AB3E", "#EC1C24"),
        _team_setting("58", "Chennai Super Kings", "CSK", "#FFFF3C", "#2B5DA8"),
        _team_setting("64", "Rajasthan Royals", "RR", "#C3A11F", "#074EA2"),
        _team_setting("1472", "UP Warriorz Women", "UPW", "#6A0DAD", "#FFD700"),

        # Australian Big Bash League teams
        _team_setting("199", "Adelaide Strikers", "ADS", "#FFFFFF", "#0084D6"),
        _team_setting("355", "Adelaide Strikers Women", "ADSW", "#FFFFFF", "#0084D6"),
        _team_setting("193", "Brisbane Heat", "BRH", "#FFFFFF", "#27A6B0"),
        _team_setting("356", "Brisbane Heat Women", "BRHW", "#FFFFFF", "#27A6B0"),
        _team_setting("194", "Hobart Hurricanes", "HBH", "#FFFFFF", "#674398"),
        _team_setting("357", "Hobart Hurricanes Women", "HBHW", "#FFFFFF", "#674398"),
        _team_setting("195", "Melbourne Renegades", "MLR", "#FFFFFF", "#EE343F"),
        _team_setting("358", "Melbourne Renegades Women", "MLRW", "#FFFFFF", "#EE343F"),
        _team_setting("196", "Melbourne Stars", "MLS", "#FFFFFF", "#287246"),
        _team_setting("359", "Melbourne Stars Women", "MLSW", "#FFFFFF", "#287246"),
        _team_setting("197", "Perth Scorchers", "PRS", "#FFFFFF", "#CC5A1E"),
        _team_setting("360", "Perth Scorchers Women", "PRSW", "#FFFFFF", "#CC5A1E"),
        _team_setting("198", "Sydney Sixers", "SYS", "#FFFFFF", "#EC2A90"),
        _team_setting("361", "Sydney Sixers Women", "WSYS", "#FFFFFF", "#EC2A90"),
        _team_setting("192", "Sydney Thunder", "SYT", "#FFFFFF", "#7CB002"),
        _team_setting("362", "Sydney Thunder Women", "SYTW", "#FFFFFF", "#7CB002"),
    ]
}

team_list_schema_options = [schema.Option(display = team.name, value = team.id) for team in team_settings_by_id.values()]
past_results_day_options = [schema.Option(display = value, value = value) for value in ["1", "2", "3", "5", "7", "30", "90"]]
upcoming_fixtures_day_options = [schema.Option(display = value, value = value) for value in ["1", "2", "3", "5", "7", ALWAYS_SHOW_FIXTURES]]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(id = "team", name = "Team", desc = "Choose your team", icon = "tag", default = DEFAULT_TEAM_ID, options = team_list_schema_options),
            schema.Dropdown(id = "days_back", name = "# of days back to show scores", desc = "Number of days back to search for scores", icon = "arrowLeft", default = str(DEFAULT_RESULT_DAYS), options = past_results_day_options),
            schema.Dropdown(id = "days_forward", name = "# of days forward to show fixtures", desc = "Number of days forward to search for fixtures", icon = "arrowRight", default = ALWAYS_SHOW_FIXTURES, options = upcoming_fixtures_day_options),
        ],
    )

def main(config):
    scale = 2 if canvas.is2x() else 1
    tz = time.tz()
    now = time.now().in_location(tz)
    team_id = config.get("team", DEFAULT_TEAM_ID)
    team = team_settings_by_id.get(team_id)
    if not team:
        return render.Root(
            child = render.WrappedText(
                content = "Match cannot be displayed. Please choose a different team.",
                font = "terminus-12" if scale == 2 else "tom-thumb",
            ),
        )

    fixture_value = config.get("days_forward", ALWAYS_SHOW_FIXTURES)
    fixture_days = None if fixture_value == ALWAYS_SHOW_FIXTURES else int(fixture_value)
    result_days = int(config.get("days_back", DEFAULT_RESULT_DAYS))
    match = load_display_match(
        team_id = team.id,
        team_name = team.name,
        supported_team_ids = team_settings_by_id.keys(),
        now_ms = now.unix * 1000,
        result_days = result_days,
        fixture_days = fixture_days,
    )
    if match == None:
        return []
    return render_scoreboard(match, team_settings_by_id, tz, now, scale)
