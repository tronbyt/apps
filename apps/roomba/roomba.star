"""
Applet: Roomba
Summary: Shows status of Roomba
Description: Shows status of Roomba and Braava (i7/i7+, 980, 960, 900, e5, 690, 675, m6, etc). Can setup custom API key or leave blank.
Author: noahpodgurski
"""

load("http.star", "http")
load("images/ricon.png", RICON_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

RICON = RICON_ASSET.readall()

REFRESH_TIME = 180  # every few minutes

WHITE = "#ffffff"
BLACK = "#000000"
RED = "#ff0000"
GREEN = "#00ff00"
ORANGE = "#db8f00"

SAMPLE_DATA = {
    "batPct": 84,
    "name": "MyRoomba",
    "cleanMissionStatus": {
        "rechrgM": 0,
        "error": 0,
        "expireTm": 0,
        "mssnStrtTm": 1689100000,
        "phase": "error",
        "mssnM": 0,
        "cycle": "null",
        "condNotReady": [],
        "operatingMode": 0,
        "expireM": 0,
        "notReady": 0,
        "rechrgTm": 0,
        "initiator": "manual",
        "nMssn": 449,
        "missionId": "82348DVK9CV9CM212K23CM",
    },
}

ROOMBA_STATES = {
    "charge": "Charging",
    "new": "Starting",
    "run": "Cleaning",
    "resume": "Cleaning",
    "hmMidMsn": "Recharging",
    "recharge": "Recharging",
    "stuck": "Stuck",
    "hmUsrDock": "Docking",
    "dock": "Docking",
    "dockend": "Docking",
    "cancelled": "Cancelled",
    "stop": "Stopped",
    "pause": "Paused",
    "hmPostMsn": "Ending",
    "evac": "Emptying",
    "chargeerror": "Error Charging",
    "error": "Error",
    "": "Other",
}

ROOMBA_STATE_COLORS = {
    "charge": GREEN,
    "new": WHITE,
    "run": GREEN,
    "resume": GREEN,
    "hmMidMsn": ORANGE,
    "recharge": GREEN,
    "stuck": RED,
    "hmUsrDock": WHITE,
    "dock": WHITE,
    "dockend": WHITE,
    "cancelled": RED,
    "stop": RED,
    "pause": ORANGE,
    "hmPostMsn": GREEN,
    "evac": WHITE,
    "chargeerror": RED,
    "error": RED,
    "": WHITE,
}

ERROR_CODES = [
    "None",
    "Left wheel off floor",
    "Main Brushes stuck",
    "Right wheel off floor",
    "Left wheel stuck",
    "Right wheel stuck",
    "Stuck near a cliff",
    "Left wheel error",
    "Bin error",
    "Bumper stuck",
    "Right wheel error",
    "Bin error",
    "Cliff sensor issue",
    "Both wheels off floor",
    "Bin missing",
    "Reboot required",
    "Bumped unexpectedly",
    "Path blocked",
    "Docking issue",
    "Undocking issue",
    "Docking issue",
    "Navigation problem",
    "Navigation problem",
    "Battery issue",
    "Navigation problem",
    "Reboot required",
    "Vacuum problem",
    "Vacuum problem",
    "Sftwr Update needed",
    "Vacuum problem",
    "Reboot required",
    "Smart map problem",
    "Path blocked",
    "Reboot required",
    "Unrecognized cleaning pad",
    "Bin full",
    "Tank needed refilling",
    "Vacuum problem",
    "Reboot required",
    "Navigation problem",
    "Timed out",
    "Localization problem",
    "Navigation problem",
    "Pump issue",
    "Lid open",
    "Low battery",
    "Reboot required",
    "Path blocked",
    "Pad required attention",
    "Hardware problem",
    "Low memory",
    "Hardware problem",
    "Pad type changed",
    "Max area reached",
    "Navigation problem",
    "Hardware problem",
]

BATTERY_OUTLINE = [
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
]

BATTERY_CHARGING = [
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
]

BATTERY_PLEASE_CHARGE = [
    [0, 0, 1, 1, 1, 1, 0, 0],
    [0, 0, 1, 0, 0, 1, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 0, 1, 0, 0, 1, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 1, 1, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1],
]

WIDTH = 8
HEIGHT = 16
HEIGHT_ADJ = 2

def requestStatus(serverIP, serverPort, apiKey):
    res = http.get("http://%s:%d/status" % (serverIP, serverPort), headers = {"x-api-key": apiKey}, ttl_seconds = REFRESH_TIME)
    if res.status_code != 200:
        fail("request failed with status %d", res.status_code)
    res = res.json()
    return res

def main(config):
    white_pixel = render.Box(
        width = 1,
        height = 1,
        color = WHITE,
    )
    green_pixel = render.Box(
        width = 1,
        height = 1,
        color = GREEN,
    )
    red_pixel = render.Box(
        width = 1,
        height = 1,
        color = RED,
    )
    orange_pixel = render.Box(
        width = 1,
        height = 1,
        color = ORANGE,
    )
    black_pixel = render.Box(
        width = 1,
        height = 1,
        color = BLACK,
    )

    serverIP = config.str("serverIP")
    serverPort = config.str("serverPort")
    apiKey = config.str("apiKey")

    if not serverIP or type(int(serverPort)) != "int":
        data = SAMPLE_DATA
        batPct = random.number(0, 100)
        name = data["name"]

        # phase = data["cleanMissionStatus"]["phase"]
        phase = ["charge", "run", "new", "resume", "stuck", "dock", "stop", "evac"][random.number(0, 7)]

    else:
        serverPort = int(serverPort)
        data = requestStatus(serverIP, serverPort, apiKey)
        if data and data["batPct"]:
            batPct = data["batPct"]
            name = data["name"]
            phase = data["cleanMissionStatus"]["phase"]
        else:
            fail("Server did not respond correctly")

    batLabel = ""
    phaseLabel = ""
    phaseLabelColor = WHITE
    statusOffset = 7
    phaseLabel = ROOMBA_STATES[phase]
    if phase != "chargeerror":
        batLabel = "%d%%" % batPct
    else:
        statusOffset = 0

    phaseLabelColor = ROOMBA_STATE_COLORS[phase]

    if batPct <= 5 and phase not in ["charge", "hmMidMsn", "recharge", "hmUsrDock", "dock", "dockend", "hmPostMsn"]:
        phaseLabel = "Please Charge"
        statusOffset = 0
        phaseLabelColor = RED
        batLabel = ""

    error = int(data["cleanMissionStatus"]["error"])

    #render battery icon
    # why not just use separate images for batteries? - it's NOT AS FUN
    batteryIconRows = []
    if batPct < 100 and phase == "charge":
        for y in range(HEIGHT):
            row = []
            for x in range(WIDTH):
                if BATTERY_CHARGING[y][x] == 1:
                    row.append(white_pixel)
                else:
                    row.append(black_pixel)
            batteryIconRows.append(row)
    elif batPct < 5 and phase != "charge":
        for y in range(HEIGHT):
            row = []
            for x in range(WIDTH):
                if BATTERY_PLEASE_CHARGE[y][x] == 1:
                    row.append(white_pixel)
                else:
                    row.append(black_pixel)
            batteryIconRows.append(row)
    else:
        for y in range(HEIGHT):
            row = []
            for x in range(WIDTH):
                if x != 0 and x < WIDTH - 1 and y > 2 and y < HEIGHT - 1:
                    #draw filled up battery depending on batPct
                    #green
                    if batPct >= 65 and y - HEIGHT_ADJ >= ((HEIGHT - HEIGHT_ADJ) * (1 - batPct / 100)):
                        row.append(green_pixel)
                        #orange

                    elif batPct >= 35 and y - HEIGHT_ADJ >= ((HEIGHT - HEIGHT_ADJ) * (1 - batPct / 100)):
                        row.append(orange_pixel)
                        #red

                    elif batPct >= 15 and y - HEIGHT_ADJ >= ((HEIGHT - HEIGHT_ADJ) * (1 - batPct / 100)):
                        row.append(red_pixel)
                        #bottom line on almost empty

                    elif batPct >= 5 and y >= 14:
                        row.append(red_pixel)
                        #all empty

                    else:
                        row.append(black_pixel)

                    #draw battery outline
                elif BATTERY_OUTLINE[y][x] == 1:
                    row.append(white_pixel)
                else:
                    row.append(black_pixel)
            batteryIconRows.append(row)
    if error > 55:  # if some other untested error, default to 'navigation problem'
        error = 21

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "start",
            children = [
                render.Column(
                    main_align = "start",
                    cross_align = "start",
                    children = [
                        render.Stack(
                            children = [
                                render.Padding(
                                    pad = 1,
                                    child = render.Row(
                                        expanded = True,
                                        main_align = "space_around",
                                        children = [
                                            render.Stack(children = [
                                                render.Image(src = RICON),
                                            ]),
                                            render.Text(name),
                                        ],
                                    ),
                                ),
                            ],
                        ),
                        render.Padding(
                            pad = (1, 1, 0, 0),
                            child = render.Row(
                                main_align = "space_around",
                                cross_align = "center",
                                expanded = True,
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Padding(
                                                pad = (0, 0, 50, 0),
                                                child = render.Column(
                                                    expanded = True,
                                                    children = [
                                                        render.Row(children = row)
                                                        for row in batteryIconRows
                                                    ],
                                                ),
                                            ),
                                            render.Padding(
                                                pad = (9, 0, 0, 0),
                                                child = render.WrappedText(batLabel, font = "5x8"),
                                            ),
                                            render.Padding(
                                                pad = (13, statusOffset, 1, 1),
                                                child = render.Column(
                                                    expanded = True,
                                                    children = [
                                                        render.WrappedText(phaseLabel, font = "5x8", color = phaseLabelColor),
                                                    ],
                                                ),
                                            ),
                                        ],
                                    ),
                                ],
                            ) if not error else render.Row(
                                main_align = "space_around",
                                cross_align = "center",
                                expanded = True,
                                children = [
                                    render.Stack(
                                        children = [
                                            render.Padding(
                                                pad = 0,
                                                child = render.WrappedText(ERROR_CODES[error], font = "5x8", color = RED),
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "serverIP",
                name = "Server IP",
                desc = "Ex: (192.168.1.123)",
                icon = "gear",
            ),
            schema.Text(
                id = "serverPort",
                name = "Server Port (optional)",
                desc = "Ex: 6565",
                icon = "gear",
            ),
            schema.Text(
                id = "apiKey",
                name = "API Key (optional)",
                desc = "API Key setup in index.js",
                icon = "gear",
                secret = True,
            ),
        ],
    )
