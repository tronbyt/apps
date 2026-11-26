"""
Applet: Stadium Tracker
Summary: Track Stadiums and Ball Parks you've visted.
Description: Track stadiums and ball parks you've visted.
Author: Robert Ison
"""

load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

LEAGUE_OPTIONS = [
    schema.Option(value = "select", display = "Select a league..."),
    schema.Option(value = "mlb", display = "Major League Baseball"),
    schema.Option(value = "nba", display = "National Basketball Association"),
    schema.Option(value = "nfl", display = "National Football League"),
    schema.Option(value = "nhl", display = "National Hockey League"),
    schema.Option(value = "mls", display = "Major League Soccer"),
]

#Tidbyt display is 64x32 -- these are coordinates for the map and each team
USAMAP = [[0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 9], [0, 10], [0, 11], [0, 12], [0, 13], [0, 14], [0, 15], [0, 16], [0, 17], [0, 18], [0, 19], [0, 20], [0, 21], [0, 22], [0, 23], [0, 24], [0, 25], [0, 26], [0, 27], [0, 28], [0, 29], [0, 30], [0, 31], [0, 32], [0, 33], [1, 0], [1, 2], [1, 33], [1, 34], [1, 35], [1, 36], [1, 37], [1, 38], [2, 0], [2, 1], [2, 2], [2, 38], [2, 39], [3, 0], [3, 39], [3, 40], [3, 41], [3, 61], [3, 62], [4, 0], [4, 1], [4, 41], [4, 42], [4, 43], [4, 60], [4, 61], [4, 62], [5, 1], [5, 43], [5, 44], [5, 45], [5, 59], [5, 60], [5, 62], [5, 63], [6, 1], [6, 45], [6, 56], [6, 57], [6, 58], [6, 59], [6, 63], [7, 0], [7, 45], [7, 53], [7, 54], [7, 55], [7, 56], [7, 62], [7, 63], [8, 0], [8, 45], [8, 46], [8, 53], [8, 60], [8, 61], [9, 0], [9, 46], [9, 50], [9, 51], [9, 52], [9, 53], [9, 60], [10, 0], [10, 46], [10, 47], [10, 48], [10, 49], [10, 50], [10, 60], [11, 0], [11, 58], [11, 59], [12, 0], [12, 56], [12, 57], [12, 58], [13, 0], [13, 56], [14, 0], [14, 1], [14, 55], [15, 1], [15, 54], [16, 2], [16, 54], [17, 2], [17, 3], [17, 53], [17, 54], [18, 3], [18, 53], [19, 3], [19, 4], [19, 53], [20, 4], [20, 5], [20, 51], [20, 52], [21, 5], [21, 6], [21, 7], [21, 50], [21, 51], [22, 7], [22, 8], [22, 49], [22, 50], [23, 8], [23, 9], [23, 10], [23, 11], [23, 12], [23, 13], [23, 49], [24, 13], [24, 14], [24, 15], [24, 16], [24, 17], [24, 18], [24, 19], [24, 48], [24, 49], [25, 19], [25, 20], [25, 21], [25, 22], [25, 48], [26, 22], [26, 23], [26, 24], [26, 25], [26, 33], [26, 34], [26, 35], [26, 36], [26, 37], [26, 39], [26, 40], [26, 41], [26, 42], [26, 43], [26, 48], [27, 25], [27, 33], [27, 37], [27, 38], [27, 39], [27, 43], [27, 44], [27, 45], [27, 48], [28, 26], [28, 32], [28, 46], [28, 49], [29, 27], [29, 30], [29, 31], [29, 46], [29, 49], [30, 28], [30, 30], [30, 47], [30, 49], [31, 29], [31, 30], [31, 48]]

MLB_TEAMS = [
    ["Astros", [31, 27], "Daikin Park", "Houston"],
    ["Angels", [5, 18], "Angel Stadium", "Los Angeles"],
    ["Athletics", [5, 14], "Sutter Health Park", "Sacramento"],
    ["Blue Jays", [50, 7], "Rogers Centre", "Toronto"],
    ["Braves", [44, 21], "Truist Park", "Atlanta"],
    ["Brewers", [39, 8], "American Family Field", "Milwaukee"],
    ["Cardinals", [36, 16], "Busch Stadium", "St. Louis"],
    ["Cubs", [38, 11], "Wrigley Field", "Chicago"],
    ["Diamondbacks", [12, 19], "Chase Field", "Arizona"],
    ["Dodgers", [4, 18], "Dodger Stadium", "Los Angeles"],
    ["Giants", [2, 15], "Oracle Park", "San Francisco"],
    ["Guardians", [47, 11], "Progressive Field", "Cleveland"],
    ["Mariners", [2, 3], "T-Mobile Park", "Seattle"],
    ["Marlins", [48, 30], "loanDepot park", "Miami"],
    ["Mets", [57, 11], "Citi Field", "New York"],
    ["Nationals", [52, 15], "Nationals Park", "Washington"],
    ["Orioles", [54, 14], "Oriole Park at Camden Yards", "Baltimore"],
    ["Padres", [6, 20], "Petco Park", "San Diego"],
    ["Phillies", [55, 13], "Citizens Bank Park", "Philadelphia"],
    ["Pirates", [50, 13], "PNC Park", "Pittsburgh"],
    ["Rangers", [30, 22], "Globe Life Field", "Texas"],
    ["Rays", [47, 28], "Tropicana Field", "Tampa Bay"],
    ["Red Sox", [59, 10], "Fenway Park", "Boston"],
    ["Reds", [44, 15], "Great American Ball Park", "Cincinnati"],
    ["Rockies", [19, 11], "Coors Field", "Colorado"],
    ["Royals", [32, 15], "Kauffman Stadium", "Kansas City"],
    ["Tigers", [45, 10], "Comerica Park", "Detroit"],
    ["Twins", [34, 6], "Target Field", "Minnesota"],
    ["White Sox", [40, 12], "Rate Field", "Chicago"],
    ["Yankees", [56, 11], "Yankee Stadium", "New York"],
]

NFL_TEAMS = [
    ["Cardinals", [12, 19], "State Farm Stadium", "Arizona"],
    ["Falcons", [44, 21], "Mercedes-Benz Stadium", "Atlanta"],
    ["Ravens", [54, 14], "M&T Bank Stadium", "Baltimore"],
    ["Bills", [52, 10], "Highmark Stadium", "Buffalo"],
    ["Panthers", [48, 18], "Bank of America Stadium", "Carolina"],
    ["Bears", [38, 11], "Soldier Field", "Chicago"],
    ["Bengals", [44, 15], "Paycor Stadium", "Cincinnati"],
    ["Browns", [47, 11], "Huntington Bank Field", "Cleveland"],
    ["Cowboys", [30, 22], "AT&T Stadium", "Dallas"],
    ["Broncos", [19, 11], "Empower Field at Mile High", "Denver"],
    ["Lions", [45, 10], "Ford Field", "Detroit"],
    ["Packers", [39, 7], "Lambeau Field", "Green Bay"],
    ["Texans", [31, 27], "NRG Stadium", "Houston"],
    ["Colts", [41, 13], "Lucas Oil Stadium", "Indianapolis"],
    ["Jaguars", [47, 26], "EverBank Stadium", "Jacksonville"],
    ["Chiefs", [32, 15], "Arrowhead Stadium", "Kansas City"],
    ["Raiders", [10, 17], "Allegiant Stadium", "Las Vegas"],
    ["Chargers", [6, 20], "SoFi Stadium", "Los Angeles"],
    ["Rams", [5, 18], "SoFi Stadium", "Los Angeles"],
    ["Dolphins", [48, 30], "Hard Rock Stadium", "Miami"],
    ["Vikings", [34, 6], "U.S. Bank Stadium", "Minnesota"],
    ["Patriots", [59, 10], "Gillette Stadium", "New England"],
    ["Saints", [38, 26], "Superdome", "New Orleans"],
    ["Giants", [56, 11], "MetLife Stadium", "New York"],
    ["Jets", [55, 11], "MetLife Stadium", "New York"],
    ["Eagles", [55, 13], "Lincoln Financial Field", "Philadelphia"],
    ["Steelers", [50, 13], "Acrisure Stadium", "Pittsburgh"],
    ["49ers", [2, 15], "Levi's Stadium", "San Francisco"],
    ["Seahawks", [2, 3], "Lumen Field", "Seattle"],
    ["Buccaneers", [47, 28], "Raymond James Stadium", "Tampa Bay"],
    ["Titans", [38, 18], "Nissan Stadium", "Tennessee"],
    ["Commanders", [52, 15], "Northwest Stadium", "Washington"],
]

NBA_TEAMS = [
    ["Hawks", [44, 21], "State Farm Arena", "Atlanta"],
    ["Celtics", [59, 10], "TD Garden", "Boston"],
    ["Nets", [56, 11], "Barclays Center", "Brooklyn"],
    ["Hornets", [48, 20], "Spectrum Center", "Charlotte"],
    ["Bulls", [38, 11], "United Center", "Chicago"],
    ["Cavaliers", [47, 11], "Rocket Arena", "Cleveland"],
    ["Mavericks", [30, 22], "American Airlines Center", "Dallas"],
    ["Nuggets", [19, 11], "Ball Arena", "Denver"],
    ["Pistons", [45, 10], "Little Caesars Arena", "Detroit"],
    ["Warriors", [2, 15], "Chase Center", "Golden State"],
    ["Rockets", [31, 27], "Toyota Center", "Houston"],
    ["Pacers", [41, 13], "Gainbridge Fieldhouse", "Indiana"],
    ["Clippers", [4, 18], "Intuit Dome", "Los Angeles"],
    ["Lakers", [5, 18], "Crypto.com Arena", "Los Angeles"],
    ["Grizzlies", [36, 18], "FedExForum", "Memphis"],
    ["Heat", [48, 30], "Kaseya Center", "Miami"],
    ["Bucks", [39, 8], "Fiserv Forum", "Milwaukee"],
    ["Timberwolves", [34, 6], "Target Center", "Minnesota"],
    ["Pelicans", [38, 26], "Smoothie King Center", "New Orleans"],
    ["Knicks", [56, 10], "Madison Square Garden", "New York"],
    ["Thunder", [31, 20], "Paycom Center", "Oklahoma City"],
    ["Magic", [47, 28], "Kia Center", "Orlando"],
    ["76ers", [55, 13], "Xfinity Mobile Arena", "Philadelphia"],
    ["Suns", [12, 19], "Mortgage Matchup Center", "Phoenix"],
    ["Trail Blazers", [3, 7], "Moda Center", "Portland"],
    ["Kings", [5, 14], "Golden 1 Center", "Sacramento"],
    ["Spurs", [28, 27], "Frost Bank Center", "San Antonio"],
    ["Raptors", [50, 7], "Scotiabank Arena", "Toronto"],
    ["Jazz", [14, 10], "Delta Center", "Utah"],
    ["Wizards", [52, 15], "Capital One Arena", "Washington"],
]

NHL_TEAMS = [
    ["Ducks", [6, 19], "Honda Center", "Anaheim"],
    ["Mammoth", [14, 10], "Delta Center", "Utah"],
    ["Bruins", [59, 10], "TD Garden", "Boston"],
    ["Sabres", [52, 10], "KeyBank Center", "Buffalo"],
    ["Flames", [12, 0], "Saddledome", "Calgary"],
    ["Hurricanes", [48, 18], "Lenovo Center", "Carolina"],
    ["Blackhawks", [37, 11], "United Center", "Chicago"],
    ["Avalanche", [19, 11], "Ball Arena", "Colorado"],
    ["Blue Jackets", [45, 14], "Nationwide Arena", "Columbus"],
    ["Stars", [30, 22], "American Airlines Center", "Dallas"],
    ["Red Wings", [45, 10], "Little Caesars Arena", "Detroit"],
    ["Oilers", [14, 0], "Rogers Place", "Edmonton"],
    ["Panthers", [48, 30], "Amerant Bank Arena", "Florida"],
    ["Kings", [5, 18], "Crypto.com Arena", "Los Angeles"],
    ["Wild", [34, 6], "Grand Casino Arena", "Minnesota"],
    ["Canadiens", [55, 5], "Bell Centre", "Montreal"],
    ["Predators", [40, 17], "Bridgestone Arena", "Nashville"],
    ["Devils", [55, 12], "Prudential Center", "New Jersey"],
    ["Islanders", [57, 10], "UBS Arena", "New York"],
    ["Rangers", [56, 10], "Madison Square Garden", "New York"],
    ["Senators", [53, 6], "Canadian Tire Centre", "Ottawa"],
    ["Flyers", [55, 13], "Xfinity Mobile Arena", "Philadelphia"],
    ["Penguins", [50, 13], "PPG Paints Arena", "Pittsburgh"],
    ["Sharks", [3, 16], "SAP Center", "San Jose"],
    ["Kraken", [2, 3], "Climate Pledge Arena", "Seattle"],
    ["Blues", [36, 16], "Enterprise Center", "St. Louis"],
    ["Lightning", [47, 28], "Benchmark International Arena", "Tampa Bay"],
    ["Maple Leafs", [50, 7], "Scotiabank Arena", "Toronto"],
    ["Canucks", [1, 1], "Rogers Arena", "Vancouver"],
    ["Golden Knights", [10, 17], "T-Mobile Arena", "Vegas"],
    ["Capitals", [52, 15], "Capital One Arena", "Washington"],
    ["Jets", [32, 0], "Canada Life Centre", "Winnipeg"],
]

MLS_TEAMS = [
    ["Atlanta United", [44, 21], "Mercedes-Benz Stadium", "Atlanta"],
    ["Austin FC", [28, 28], "Q2 Stadium", "Austin"],
    ["Charlotte FC", [48, 18], "Bank of America Stadium", "Carolina"],
    ["Chicago Fire", [38, 11], "Soldier Field", "Chicago"],
    ["FC Cincinnati", [44, 15], "TQL Stadium", "Cincinnati"],
    ["Colorado Rapids", [19, 11], "Dick's Sporting Goods Park", "Colorado"],
    ["Columbus Crew", [45, 14], "ScottsMiracle-Gro Field", "Columbus"],
    ["DC United", [52, 15], "Audi Field", "Washington"],
    ["FC Dallas", [30, 22], "Toyota Stadium", "Dallas"],
    ["Houston Dynamo", [31, 27], "Shell Energy Stadium", "Houston"],
    ["Sporting Kansas City", [32, 15], "Sporting Park", "Kansas City"],
    ["LA Galaxy", [5, 18], "Dignity Health Sports Park", "Los Angeles"],
    ["LAFC", [4, 18], "BMO Stadium", "Los Angeles"],
    ["Inter Miami", [48, 30], "Nu Stadium", "Miami"],
    ["Minnesota United", [34, 6], "Allianz Field", "Minnesota"],
    ["CF Montreal", [55, 5], "Saputo Stadium", "Montreal"],
    ["Nashville SC", [40, 17], "GEODIS Park", "Nashville"],
    ["New England Revolution", [59, 10], "Gillette Stadium", "New England"],
    ["New York Red Bulls", [55, 12], "Sports Illustrated Stadium", "New Jersey"],
    ["New York City FC", [56, 11], "Yankee Stadium", "New York"],
    ["Orlando City", [47, 28], "Inter&Co Stadium", "Orlando"],
    ["Philadelphia Union", [55, 13], "Subaru Park", "Philadelphia"],
    ["Portland Timbers", [3, 7], "Providence Park", "Portland"],
    ["Real Salt Lake", [14, 10], "America First Field", "Utah"],
    ["San Diego FC", [6, 20], "Snapdragon Stadium", "San Diego"],
    ["San Jose Earthquakes", [3, 16], "PayPal Park", "San Jose"],
    ["Seattle Sounders", [2, 3], "Lumen Field", "Seattle"],
    ["St. Louis City", [36, 16], "Energizer Park", "St. Louis"],
    ["Toronto FC", [50, 7], "BMO Field", "Toronto"],
    ["Vancouver Whitecaps", [1, 1], "BC Place", "Vancouver"],
]

# Constants
MAP_OUTLINE_COLOR = "#1C8E61"
VISITED_PARKS = "#FFFF80"
UNVISITED_PARKS = "#666600"

WIDTH = 64
HEIGHT = 32
FRAME_DELAY = 120

TEAMS_BY_LEAGUE = {
    "mlb": MLB_TEAMS,
    "nba": NBA_TEAMS,
    "nfl": NFL_TEAMS,
    "nhl": NHL_TEAMS,
    "mls": MLS_TEAMS,
}

ICONS_BY_LEAGUE = {
    "mlb": "baseball",
    "nba": "basketball",
    "nfl": "football",
    "nhl": "hockeyPuck",
    "mls": "soccerBall",
}

def normalize_league(league):
    if league in TEAMS_BY_LEAGUE:
        return league
    return "mlb"

def main(config):
    league = config.get("type")

    if league not in TEAMS_BY_LEAGUE:
        return render.Root(
            child = render.Text(
                "Select a league",
                color = "#ffffff",
                font = "CG-pixel-3x5-mono",
            ),
        )

    return map_locations(
        config,
        TEAMS_BY_LEAGUE[league],
        league,
    )

def mark_location_on_map(x, y, color):
    return [x, y, color]

def generate_screen(locations):
    scale = 2 if canvas.is2x() else 1
    screen_width = WIDTH * scale
    screen_height = HEIGHT * scale

    screen = [
        ["#000000" for _ in range(screen_width)]
        for _ in range(screen_height)
    ]

    # Collect the currently visible outline pixels.
    outline_points = {}

    for location in locations:
        if location[2] == MAP_OUTLINE_COLOR:
            x = int(location[0])
            y = int(location[1])
            outline_points[(x, y)] = True

    # Draw the outline at scaled coordinates.
    for point in outline_points:
        x = point[0]
        y = point[1]

        screen_x = x * scale
        screen_y = y * scale

        if (
            screen_x >= 0 and
            screen_x < screen_width and
            screen_y >= 0 and
            screen_y < screen_height
        ):
            screen[screen_y][screen_x] = MAP_OUTLINE_COLOR

        # On 2x displays, connect adjacent outline pixels.
        # Only check half the directions to avoid duplicate work.
        if scale == 2:
            for offset in [
                (1, 0),
                (0, 1),
                (1, 1),
                (1, -1),
            ]:
                dx = offset[0]
                dy = offset[1]

                neighbor = (x + dx, y + dy)

                if neighbor in outline_points:
                    midpoint_x = screen_x + dx
                    midpoint_y = screen_y + dy

                    if (
                        midpoint_x >= 0 and
                        midpoint_x < screen_width and
                        midpoint_y >= 0 and
                        midpoint_y < screen_height
                    ):
                        screen[midpoint_y][midpoint_x] = (
                            MAP_OUTLINE_COLOR
                        )

    # Draw team markers after the outline.
    # Each marker occupies exactly one output pixel.
    # Later markers overwrite earlier markers, preserving
    # the existing visited/unvisited behavior.
    for location in locations:
        color = location[2]

        if color != MAP_OUTLINE_COLOR:
            screen_x = int(location[0]) * scale
            screen_y = int(location[1]) * scale

            if (
                screen_x >= 0 and
                screen_x < screen_width and
                screen_y >= 0 and
                screen_y < screen_height
            ):
                screen[screen_y][screen_x] = color

    return screen

def render_frame(frame):
    return render.Column(
        children = [
            render_row(row)
            for row in frame
        ],
    )

def render_row(row):
    return render.Row(
        children = [
            render_cell(cell)
            for cell in row
        ],
    )

def render_cell(cell):
    return render.Box(
        width = 1,
        height = 1,
        color = cell,
    )

def render_animation(frames, league):
    scale = 2 if canvas.is2x() else 1
    league_text_color = "#fff"

    if league == "nfl" or league == "mlb":
        league_text_color = "#f00"

    return render.Root(
        render.Stack(
            children = [
                render.Animation(
                    children = frames,
                ),
                render.Padding(
                    pad = (0, HEIGHT * scale - 5, 0, 0),
                    child = render.Text(
                        league,
                        color = league_text_color,
                        font = "CG-pixel-3x5-mono",
                    ),
                ),
            ],
        ),
        show_full_animation = True,
        delay = FRAME_DELAY,
    )

def sort_ballparks(ballparks):
    random_sort_method = random.number(0, 5)

    if random_sort_method == 0:
        # Sort by y.
        return sorted(
            ballparks,
            key = lambda team: team[1][1],
        )

    elif random_sort_method == 1:
        # Sort by team name.
        return sorted(
            ballparks,
            key = lambda team: team[0],
        )

    elif random_sort_method == 2:
        # Sort by x.
        return sorted(
            ballparks,
            key = lambda team: team[1][0],
        )

    elif random_sort_method == 3:
        # Sort by stadium name.
        return sorted(
            ballparks,
            key = lambda team: team[2],
        )

    elif random_sort_method == 4:
        # Sort by location, ignoring stray surrounding spaces.
        return sorted(
            ballparks,
            key = lambda team: team[3].strip(),
        )

    else:
        # Sort by x + y.
        return sorted(
            ballparks,
            key = lambda team: team[1][0] + team[1][1],
        )

def sort_maps(coordinates):
    random_sort_method = random.number(0, 6)

    # USAMAP coordinates are [row, column], not [x, y].
    if random_sort_method == 0:
        return sorted(
            coordinates,
            key = lambda dot: dot[0],
        )

    elif random_sort_method == 1:
        return sorted(
            coordinates,
            key = lambda dot: dot[1],
        )

    elif random_sort_method == 2:
        return sorted(
            coordinates,
            key = lambda dot: dot[0] + dot[1],
        )

    elif random_sort_method == 3:
        return sorted(
            coordinates,
            key = lambda dot: -dot[0],
        )

    elif random_sort_method == 4:
        return sorted(
            coordinates,
            key = lambda dot: -dot[1],
        )

    elif random_sort_method == 5:
        return sorted(
            coordinates,
            key = lambda dot: (
                dot[1] * random.number(0, 6) -
                dot[0] * random.number(0, 6)
            ),
        )

    else:
        return sorted(
            coordinates,
            key = lambda dot: -dot[0] - dot[1],
        )

def append_hold(frames, frame, count):
    # Reuse the existing frame instead of rebuilding its widgets.
    for _ in range(count):
        frames.append(frame)

def append_blinks(frames, unvisited_frame, visited_frame, count):
    for _ in range(count):
        frames.append(unvisited_frame)
        frames.append(visited_frame)

def map_locations(config, teams, league):
    locations = []
    frames = []

    shuffled_teams = sort_ballparks(teams)
    full_map = sort_maps(USAMAP)

    # Draw the map outline, ten pixels per animation frame.
    dot_count = 0

    for dot in full_map:
        row = dot[0]
        col = dot[1]

        # Leave room above the outline for Canadian team markers.
        if league == "nhl" or league == "mls":
            if row == 0:
                row = 1

        locations.append(
            mark_location_on_map(
                col,
                row,
                MAP_OUTLINE_COLOR,
            ),
        )

        dot_count += 1

        if dot_count % 10 == 0:
            frames.append(
                render_frame(generate_screen(locations)),
            )

    # Include any remaining outline pixels without duplicating
    # the last frame when the total is divisible by ten.
    if dot_count % 10 != 0:
        frames.append(
            render_frame(generate_screen(locations)),
        )

    # Add three unvisited team markers per animation frame.
    markers_per_frame = 3
    marker_count = 0

    for team in shuffled_teams:
        locations.append(
            mark_location_on_map(
                team[1][0],
                team[1][1],
                UNVISITED_PARKS,
            ),
        )

        marker_count += 1

        # Also render the final group if it has fewer than three.
        if (
            marker_count % markers_per_frame == 0 or
            marker_count == len(shuffled_teams)
        ):
            frames.append(
                render_frame(generate_screen(locations)),
            )

    # This frame is reused for the initial hold and blinking.
    unvisited_frame = frames[-1]
    append_hold(frames, unvisited_frame, 15)

    # Add visited markers after all unvisited markers so a checked
    # team remains visible if multiple teams share a pixel.
    visited_frame = unvisited_frame

    for team in teams:
        # Preserve the original checkbox IDs.
        key = "%s%s" % (league, team[0])

        if config.bool(key, False):
            locations.append(
                mark_location_on_map(
                    team[1][0],
                    team[1][1],
                    VISITED_PARKS,
                ),
            )

            visited_frame = render_frame(
                generate_screen(locations),
            )
            frames.append(visited_frame)

    append_blinks(
        frames,
        unvisited_frame,
        visited_frame,
        5,
    )

    append_hold(frames, visited_frame, 25)

    append_blinks(
        frames,
        unvisited_frame,
        visited_frame,
        5,
    )

    return render_animation(frames, league)

def get_teams(league):
    if league not in TEAMS_BY_LEAGUE:
        return []

    teams = sorted(
        TEAMS_BY_LEAGUE[league],
        key = lambda team: team[0],
    )
    icon = ICONS_BY_LEAGUE[league]

    return [
        schema.Toggle(
            id = "%s%s" % (league, team[0]),
            name = team[0],
            desc = team[2],
            icon = icon,
        )
        for team in teams
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "type",
                name = "League",
                desc = "Which league to map?",
                icon = "globe",
                options = LEAGUE_OPTIONS,
                default = LEAGUE_OPTIONS[0].value,
            ),
            schema.Generated(
                id = "teamlist",
                source = "type",
                handler = get_teams,
            ),
        ],
    )
