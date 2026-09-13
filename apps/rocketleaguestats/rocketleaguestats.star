load("http.star", "http")
load("humanize.star", "humanize")
load("images/logo.png", LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

LOGO = LOGO_ASSET.readall()

# https://www.base64encoder.io/image-to-base64-converter/

TWELVE_HOURS = 43200

# This is used whenever an error or invalid data appears.
EMPTY_DATA = {
    "total_games": "0 gs",
    "win_percent": "0% wr",
    "total_time": "0 hrs",
}

def winning_team(replay):
    """Returns which team won."""
    orange = replay["orange"].get("goals", 0)
    blue = replay["blue"].get("goals", 0)

    return "orange" if orange > blue else "blue"

def which_team(replay, name):
    """Return which team the uploader was on."""
    for team in ["orange", "blue"]:
        players = replay[team]["players"]
        for p in players:
            if p["name"] == name:
                return team
    return None

def win_percentage(replays, name):
    wins = 0
    total = 0
    for replay in replays["list"]:
        winner = winning_team(replay)
        color = which_team(replay, name)
        if color == None:
            continue
        total += 1

        if winner == color:
            wins += 1
    if total == 0:
        return 0, 0

    return total, wins / total

def total_duration(replays):
    duration = 0
    for replay in replays["list"]:
        duration += replay["duration"]

    # Seconds to hours.
    return duration / 60 / 60

def get_data(tag, token, playlist, since):
    params = {
        "player-name": tag,
        "count": "200",
    }

    if playlist != "all":
        params["playlist"] = playlist

    if since != None:
        params["replay-date-after"] = since

    API_ENDPOINT = "https://ballchasing.com/api/replays"

    res = http.get(
        API_ENDPOINT,
        headers = {"Authorization": token},
        params = params,
        ttl_seconds = TWELVE_HOURS,
    )

    if res.status_code != 200:
        fail("Error calling Ballchasing API")

    replays = res.json()

    total_games, win_percent = win_percentage(replays, tag)
    total_time = total_duration(replays)

    data = {
        "total_games": str(total_games) + " gs",
        "win_percent": humanize.float("###.", win_percent * 100) + "% wr",
        "total_time": humanize.float("#,###.#", total_time) + " hrs",
    }

    return data

def render_data(data):
    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Padding(child = render.Image(src = LOGO), pad = (1, 1, 1, 1)),
                    render.Column(children = [
                        render.Text(
                            data["total_games"],
                        ),
                        render.Text(
                            data["win_percent"],
                        ),
                        render.Text(
                            data["total_time"],
                        ),
                    ]),
                ],
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "All",
            value = "all",
        ),
        schema.Option(
            display = "Unranked Duels",
            value = "unranked-duels",
        ),
        schema.Option(
            display = "Unranked Doubles",
            value = "unranked-doubles",
        ),
        schema.Option(
            display = "Unranked Standard",
            value = "unranked-standard",
        ),
        schema.Option(
            display = "Unranked Chaos",
            value = "unranked-chaos",
        ),
        schema.Option(
            display = "Ranked Duels",
            value = "ranked-duels",
        ),
        schema.Option(
            display = "Ranked Doubles",
            value = "ranked-doubles",
        ),
        schema.Option(
            display = "Ranked Standard",
            value = "ranked-standard",
        ),
        schema.Option(
            display = "Snowday",
            value = "ranked-snowday",
        ),
        schema.Option(
            display = "Hoops",
            value = "ranked-hoops",
        ),
        schema.Option(
            display = "Rumble",
            value = "ranked-rumble",
        ),
        schema.Option(
            display = "Dropshot",
            value = "ranked-dropshot",
        ),
        schema.Option(
            display = "Tournament",
            value = "tournament",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "token",
                name = "Ballchasing API Token",
                desc = "https://ballchasing.com/upload",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "tag",
                name = "Player Tag",
                desc = "Ex: Flakes",
                icon = "user",
            ),
            schema.Dropdown(
                id = "playlist",
                name = "Playlist",
                desc = "Playlist to get data for",
                # All replays by default.
                default = options[0].value,
                options = options,
                icon = "gamepad",
            ),
            schema.DateTime(
                id = "since",
                name = "Games Since",
                desc = "Only use games played after the given date",
                icon = "clock",
            ),
        ],
    )

def main(config):
    tag = config.get("tag")
    token = config.get("token")
    playlist = config.get("playlist")
    since = config.get("since")

    if tag == None or token == None:
        print("error: tag or token is not set")
        return render_data(EMPTY_DATA)

    data = get_data(tag, token, playlist, since)
    print(data)

    return render_data(data)
