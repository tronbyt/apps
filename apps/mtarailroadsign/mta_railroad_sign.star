"""
Applet: MTA Railroad Sign
Summary: Metro-North/LIRR next train
Description: Adds a realtime next train sign for any Metro-North or Long Island Rail Road station to your Tidbyt.
Author: nataliemakhijani
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/alert_icon.png", ALERT_ICON_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_13926c21.png", IMG_13926c21_ASSET = "file")
load("images/img_19e94761.png", IMG_19e94761_ASSET = "file")
load("images/img_1aeaa611.png", IMG_1aeaa611_ASSET = "file")
load("images/img_2514fb38.png", IMG_2514fb38_ASSET = "file")
load("images/img_2c972329.png", IMG_2c972329_ASSET = "file")
load("images/img_2e3a727b.png", IMG_2e3a727b_ASSET = "file")
load("images/img_3b30bc3b.png", IMG_3b30bc3b_ASSET = "file")
load("images/img_485c94a7.png", IMG_485c94a7_ASSET = "file")
load("images/img_4a1f51c0.png", IMG_4a1f51c0_ASSET = "file")
load("images/img_51b84519.png", IMG_51b84519_ASSET = "file")
load("images/img_5fd189ea.png", IMG_5fd189ea_ASSET = "file")
load("images/img_5fdc3b60.png", IMG_5fdc3b60_ASSET = "file")
load("images/img_71358aab.png", IMG_71358aab_ASSET = "file")
load("images/img_72ff3d64.png", IMG_72ff3d64_ASSET = "file")
load("images/img_7aa6aa91.png", IMG_7aa6aa91_ASSET = "file")
load("images/img_7b469ff3.png", IMG_7b469ff3_ASSET = "file")
load("images/img_acf95546.png", IMG_acf95546_ASSET = "file")
load("images/img_ad13b136.png", IMG_ad13b136_ASSET = "file")
load("images/img_b356754b.png", IMG_b356754b_ASSET = "file")
load("images/img_f3feaf78.png", IMG_f3feaf78_ASSET = "file")
load("images/img_f97e5229.png", IMG_f97e5229_ASSET = "file")

ALERT_ICON = ALERT_ICON_ASSET.readall()

# OBJECTS
STATION_NAMES = {
    "ALL": "No filter",
    "ABT": "Albertson",
    "AGT": "Amagansett",
    "AVL": "Amityville",
    "5AN": "Ansonia",
    "1AT": "Appalachian Trail",
    "0AR": "Ardsley-on-Hudson",
    "ATL": "Atlantic Term",
    "ADL": "Auburndale",
    "BTA": "Babylon",
    "BWN": "Baldwin",
    "BSR": "Bay Shore",
    "BSD": "Bayside",
    "0BC": "Beacon",
    "5BF": "Beacon Falls",
    "1BH": "Bedford Hills",
    "BRS": "Bellerose",
    "BMR": "Bellmore",
    "BPT": "Bellport",
    "BRT": "Belmont Pk",
    "4BE": "Bethel",
    "BPG": "Bethpage",
    "BOL": "Bolands-Crew",
    "1BG": "Botanical Garden",
    "4BV": "Branchville",
    "0BK": "Breakneck Rdg",
    "BWD": "Brentwood",
    "1BW": "Brewster",
    "BHN": "Bridgehampton",
    "2BP": "Bridgeport",
    "BDY": "Broadway",
    "1BX": "Bronxville",
    "4CA": "Cannondale",
    "CPL": "Carle Pl",
    "CHT": "Cedarhurst",
    "CI": "Cntrl Islip",
    "CAV": "Centre Av",
    "1CQ": "Chappaqua",
    "0CS": "Cold Spring",
    "CSH": "Cold Sprng Hbr",
    "CPG": "Copiague",
    "0CT": "Cortlandt",
    "2CC": "Cos Cob",
    "CLP": "Cty Life Press",
    "1CW": "Crestwood",
    "1CF": "Croton Falls",
    "0HM": "Croton-Harmon",
    "4DN": "Danbury",
    "2DA": "Darien",
    "DPK": "Deer Pk",
    "5DB": "Derby-Shelton",
    "0DF": "Dobbs Ferry",
    "DGL": "Douglaston",
    "1DO": "Dover Plains",
    "EHN": "East Hampton",
    "ENY": "East New York",
    "2EN": "East Norwalk",
    "ERY": "East Rockaway",
    "EWN": "East Williston",
    "EMT": "Elmont UBS",
    "2FF": "Fairfield",
    "2FM": "Fairfield-B Rock",
    "FRY": "Far Rockaway",
    "FMD": "Farmingdale",
    "1FW": "Fleetwood",
    "FPK": "Floral Pk",
    "FLS": "Flushing",
    "1FO": "Fordham",
    "FHL": "Forest Hills",
    "FPT": "Freeport",
    "GCY": "Garden City",
    "0GA": "Garrison",
    "GBN": "Gibson",
    "GCV": "Glen Cove",
    "GHD": "Glen Head",
    "GST": "Glen St",
    "3GB": "Glenbrook",
    "0GD": "Glenwood",
    "1GO": "Goldens Br",
    "GCT": "Grand Central",
    "0NY": "Grand Central",
    "_GC": "Grand Central",
    "GNK": "Great Neck",
    "GRV": "Great River",
    "2GF": "Green's Farms",
    "GWN": "Greenlawn",
    "GPT": "Greenport",
    "GVL": "Greenvale",
    "2GN": "Greenwich",
    "0GY": "Greystone",
    "HBY": "Hampton Bays",
    "1WI": "Harlem Valley-Wingdale",
    "0HL": "Halem-125 St",
    "2HS": "Harrison",
    "1HA": "Hartsdale",
    "0HS": "Hastings-on-Hudson",
    "1HN": "Hawthorne",
    "HEM": "Hempstead",
    "HGN": "Hempst'd Grdns",
    "HWT": "Hewlett",
    "HVL": "Hicksville",
    "0HB": "CREW-Highbridge",
    "HIL": "CREW-Hillside",
    "HOL": "Hollis",
    "HPA": "Hunterspoint Av",
    "HUN": "Huntington",
    "IWD": "Inwood",
    "0IV": "Irvington",
    "IPK": "Island Pk",
    "ISP": "Islip",
    "JAM": "Jamaica",
    "1KA": "Katonah",
    "KGN": "Kew Gardens",
    "KPK": "Kings Park",
    "LVW": "Lakeview",
    "2LA": "Larchmont",
    "LTN": "Laurelton",
    "LCE": "Lawrence",
    "LHT": "Lindenhurst",
    "LNK": "Little Neck",
    "LMR": "Locust Manor",
    "LVL": "Locust Valley",
    "LBH": "Long Beach",
    "LIC": "LI City",
    "0LU": "Ludlow",
    "LYN": "Lynbrook",
    "MVN": "Malverne",
    "2MA": "Mamaroneck",
    "MHT": "Manhasset",
    "0MN": "Manitou",
    "0MB": "Marble Hill",
    "MQA": "Massapequa",
    "MPK": "Massapequa Pk",
    "MSY": "Mastic-Sh'rl'y",
    "MAK": "Mattituck",
    "MFD": "Medford",
    "1ML": "Melrose",
    "MAV": "Merillon Av",
    "MRK": "Merrick",
    "4M7": "Merritt 7",
    "SSM": "Mets-Willets",
    "2MI": "Milford",
    "MIN": "Mineola",
    "MTK": "Montauk",
    "0MH": "Morris Hts",
    "1MK": "Mt Kisco",
    "1MP": "Mt Pleasant",
    "2ME": "Mt Vernon E",
    "1MW": "Mt Vernon W",
    "MHL": "Murray Hill",
    "NBD": "Nassau Bl",
    "5NG": "Naugatuck",
    "3NC": "New Canaan",
    "0NM": "New Hamburg",
    "2NH": "New Haven",
    "2SS": "N Haven-State",
    "NHP": "New Hyde Pk",
    "2NR": "New Rochelle",
    "2NO": "Noroton Hts",
    "1NW": "N White Plains",
    "NPT": "Northport",
    "NAV": "Nostrand Av",
    "ODL": "Oakdale",
    "ODE": "Oceanside",
    "2OG": "Old Greenwich",
    "0OS": "Ossining",
    "OBY": "Oyster Bay",
    "PGE": "Patchogue",
    "1PA": "Patterson",
    "1PW": "Pawling",
    "0PE": "Peekskill",
    "2PH": "Pelham",
    "NYK": "Penn Station",
    "0PM": "Philipse Manor",
    "PLN": "Pinelawn",
    "PDM": "Plandome",
    "1PV": "Pleasantville",
    "2PC": "Port Chester",
    "PJN": "Port Jefferson",
    "PWS": "Pt Washington",
    "0PO": "Poughkeepsie",
    "1PY": "Purdy's",
    "QVG": "Queens Village",
    "4RD": "Redding",
    "0RV": "Riverdale",
    "RHD": "Riverhead",
    "2RS": "Riverside",
    "RVC": "Rockville Ctr",
    "RON": "Ronkonkoma",
    "ROS": "Rosedale",
    "RSN": "Roslyn",
    "2RO": "Rowayton",
    "2RY": "Rye",
    "SVL": "Sayville",
    "0SB": "Scarborough",
    "1SC": "Scarsdale",
    "SCF": "Sea Cliff",
    "SFD": "Seaford",
    "5SY": "Seymour",
    "STN": "Smithtown",
    "2SN": "South Norwalk",
    "SHN": "Southampton",
    "1BR": "Southeast",
    "SHD": "Southold",
    "2SP": "Southport",
    "SPK": "Speonk",
    "3SD": "Springdale",
    "0DV": "Spuyten Duyvil",
    "SAB": "St. Albans",
    "SJM": "St. James",
    "2SM": "Stamford",
    "SMR": "Stewart Manor",
    "BK": "Stony Brook",
    "2SR": "Stratford",
    "SYT": "Syosset",
    "3TH": "Talmadge Hill",
    "0TT": "Tarrytown",
    "1TM": "Tenmile River",
    "1TR": "Tremont",
    "1TK": "Tuckahoe",
    "0UH": "University Hts",
    "1VA": "Valhalla",
    "VSM": "Valley Stream",
    "1WF": "Wakefield",
    "WGH": "Wantagh",
    "1WA": "Wassaic",
    "5WB": "Waterbury",
    "2WH": "W Haven",
    "WHD": "W Hempstead",
    "WBY": "Westbury",
    "WHN": "Westhampton",
    "2WP": "Westport",
    "WWD": "Westwood",
    "1WP": "White Plains",
    "1WG": "Williams Br",
    "4WI": "Wilton",
    "1WN": "Woodlawn",
    "WMR": "Woodmere",
    "WDD": "Woodside",
    "WYD": "Wyandanch",
    "0YS": "Yankees-E 153 St",
    "YPK": "Yaphank",
    "0YK": "Yonkers",
}
BRANCH_CODES = {
    "ALL": "All branches",
    "BY": "Babylon",
    # "":"Belmont", # Not sure what the branch code for Belmont is. Need to wait for horse racing season to find out.
    "CI": "City Terminal Zone",
    "FR": "Far Rockaway",
    "HM": "Hempstead",
    "LB": "Long Beach",
    "MK": "Montauk",
    "OB": "Oyster Bay",
    "HH": "Port Jefferson",
    "PJ": "Port Jefferson",
    "PW": "Port Washington",
    "RK": "Ronkonkoma",
    "WH": "West Hempstead",
    "HU": "Hudson",
    "NH": "New Haven",
    "HA": "Harlem",
    "NC": "New Canaan",
    "WB": "Waterbury",
    "DN": "Danbury",
    "??": "Unknown",
}
API_HEADERS = {
    "Accept-Version": "3.0",
}
TERMINAL_CODES = {
    "All": "All",
    "NYK NYP": "Penn Station",
    "GCT 0NY _GCT": "Grand Central",
    "JAM": "Jamaica",
    "HPA": "Hunterspoint Av",
    "ATL": "Atlantic Terminal",
    "LIC": "Long Island City",
    "0PO": "Poughkeepsie",
    "0HM": "Croton-Harmon",
    "2SM": "Stamford",
    "3NC": "New Canaan",
    "2NH": "New Haven",
    "2SS": "New Haven-State St",
    "4DN": "Danbury",
    "5WB": "Waterbury",
    "1WA": "Wassaic",
    "1BR": "Southeast",
}

# ERRORS
def NO_TRAINS(station):
    return render.Root(
        child = render.Column(
            children = [
                render.Text("No trains for"),
                render.Text("this station +"),
                render.Text("branch at this"),
                render.Text("time (%s)." % station),
            ],
        ),
    )

def API_ERROR(code):
    return render.Root(
        child = render.Column(
            children = [
                render.Text("An error (%s)" % code),
                render.Text("occured while"),
                render.Text("fetching data."),
            ],
        ),
    )

# DEFAULTS
DEFAULT_STATION = "JAM"
DEFAULT_DIRECTION = "NESW"
DEFAULT_BRANCH = "ALL"
DEFAULT_FILTER_STOP = "ALL"

# COLORS
OCCUPANCY_COLORS = {
    "EMPTY": "#00c164",  # #00c364
    "MANY_SEATS": "#e5a400",  # #fae100
    "FEW_SEATS": "#e6a500",  # #e6a500
    "SRO": "#ff1500",  # #ff1500
    "FULL": "#ff1500",
    "NO_DATA": "#aaaaaa",  # #ababab
    "NON_REVENUE": "#aaaaaa",  #rgb(67, 67, 67)
    "LOCOMOTIVE": "#0080ff",  # #0080ff
}
BRANCH_COLORS = {
    "Babylon": "#00985F",  #00985F
    "Belmont": "#60269E",  #60269E
    "City Terminal Zone": "#4D5357",  #4D5357
    "Far Rockaway": "#6E3219",  #6E3219
    "Hempstead": "#CE8E00",  #CE8E00
    "Long Beach": "#FF6319",  #FF6319
    "Montauk": "#00B2A9",  #00B2A9
    "Oyster Bay": "#00AF3F",  #00AF3F
    "Port Jefferson": "#006EC7",  #006EC7
    "Port Washington": "#C60C30",  #C60C30
    "Ronkonkoma": "#A626AA",  #A626AA
    "West Hempstead": "#00A1DE",  #00A1DE
    "Hudson": "#009B3A",  #009B3A
    "New Haven": "#EE0034",  #EE0034
    "New Canaan": "#EE0034",  #EE0034
    "Danbury": "#EE0034",  #EE0034
    "Waterbury": "#EE0034",  #EE0034
    "Harlem": "#0039A6",  #0039A6
    "Unknown": "#FFFFFF",  #FFFFFF
}
STATUS_COLORS = {
    "EN_ROUTE": "#808080",  #808080
    "ARRIVING": "#0064fa",  #0064fa
    "BERTHED": "#e3d218",  #e3d218
    "DEPARTED": "#C60C30",  #C60C30
}

# ICONS
TERMINAL_ICONS = {
    "HPA": IMG_19e94761_ASSET.readall(),
    "NYK": IMG_5fdc3b60_ASSET.readall(),
    "NYP": IMG_5fdc3b60_ASSET.readall(),
    "GCT": IMG_ad13b136_ASSET.readall(),
    "0NY": IMG_ad13b136_ASSET.readall(),  # GCT
    "LIC": IMG_b356754b_ASSET.readall(),
    "ATL": IMG_3b30bc3b_ASSET.readall(),
    "JAM": IMG_485c94a7_ASSET.readall(),
    "???": IMG_2e3a727b_ASSET.readall(),
}
BRANCH_ICONS = {
    "Port Jefferson": IMG_7b469ff3_ASSET.readall(),
    "Montauk": IMG_1aeaa611_ASSET.readall(),
    "Ronkonkoma": IMG_72ff3d64_ASSET.readall(),
    "Far Rockaway": IMG_2c972329_ASSET.readall(),
    "Long Beach": IMG_51b84519_ASSET.readall(),
    "Babylon": IMG_4a1f51c0_ASSET.readall(),
    "Hempstead": IMG_7aa6aa91_ASSET.readall(),
    "West Hempstead": IMG_13926c21_ASSET.readall(),
    "Oyster Bay": IMG_71358aab_ASSET.readall(),
    "Port Washington": IMG_2514fb38_ASSET.readall(),
    "New Haven": IMG_f3feaf78_ASSET.readall(),
    "Harlem": IMG_f97e5229_ASSET.readall(),
    "Hudson": IMG_acf95546_ASSET.readall(),
    "New Canaan": IMG_5fd189ea_ASSET.readall(),
}

# MAIN CODE
def main(config):
    # get user settings
    station_code = config.str("station", DEFAULT_STATION)
    filter_direction = config.str("filter_direction", DEFAULT_DIRECTION)
    filter_branch = config.str("filter_branch", DEFAULT_BRANCH)
    filter_stop = config.str("filter_stop", DEFAULT_FILTER_STOP)

    # Make request
    RADAR_ARRIVALS_API_URL = "https://backend-unified.mylirr.org/arrivals/%s" % station_code
    rep = http.get(RADAR_ARRIVALS_API_URL, headers = API_HEADERS)
    if rep.status_code != 200:  # error checking
        return API_ERROR(rep.status_code)  # handle error
    json = rep.json()  # parse json

    # Pick apart data
    is_alert = True if len(json["alerts"]) > 0 or len(json["banners"]) > 0 else False
    trains = json["arrivals"]  # extract trains
    trains = [train for train in trains if train["direction"] in filter_direction]
    if filter_branch != "ALL":
        trains = [train for train in trains if train["branch"] == filter_branch]
    if filter_stop != "ALL":
        trains = [train for train in trains if filter_stop in train["stops"]]

    if len(trains) == 0:  # if there are no trains
        return NO_TRAINS(station_code)  # return the no trains error screen

    # train info extraction
    train = trains[0]  # select next to arrive train
    train_number = train["train_num"]
    train_id = train["train_id"]
    train_dest = train["stops"][-1]  # extract terminal
    is_peak = train["peak_code"] == "P"  # determine if this is a peak train

    # branch determination and settings
    branch_name = BRANCH_CODES[train["branch"]] if train["branch"] in BRANCH_CODES else "Unknown"
    branch_color = BRANCH_COLORS[branch_name] if branch_name in BRANCH_COLORS else "#ffffff"

    # find icons
    branch_icon = BRANCH_ICONS[branch_name] if branch_name in BRANCH_ICONS else TERMINAL_ICONS["???"]
    train_icon = TERMINAL_ICONS[train_dest] if train_dest in TERMINAL_ICONS else branch_icon

    # stop info
    track_change = False if not "track_change" in train else train["track_change"]  # Figure out if there has been a track change, with extra logic because sometimes there is no "track_change" key
    stop_track = train["track"] if "track" in train else "?"  # If there isn't a track assigned, show ?. This is often the case at Grand Central Madison and Penn Station
    stop_track_type = "Track" if len(stop_track) > 1 or stop_track.isdigit() else "Plat"  # Determine if it's a "Platform" or "Track"
    stop_status = train["stop_status"]  # Stop status
    status_color = STATUS_COLORS[stop_status]  # Assign correct status color

    # next stops
    next_stops = [STATION_NAMES[stop] if stop in STATION_NAMES else stop for stop in train["stops"]]

    # get more info from the location endpoint
    RADAR_LOCATION_API_URL = "https://backend-unified.mylirr.org/locations/%s?geometry=NONE&events=true" % train_id
    rep = http.get(RADAR_LOCATION_API_URL, headers = API_HEADERS)

    if rep.status_code != 200:  # error checking
        return API_ERROR(rep.status_code)  # handle error by returning error screen
    json = rep.json()  # parse json
    train_info = json

    # on-time-performance
    if not "otp" in train["status"]:  # if there isn't an otp value
        train_otp = 0  # assume it's on time. it probably hasn't left the terminal yet, and isn't scheduled to have.
    else:
        train_otp = train_info["status"]["otp"]  # otherwise, take MTA's word for it.

    if train_otp < -600:
        train_otp_color = OCCUPANCY_COLORS["SRO"]
    elif train_otp < -300:
        train_otp_color = OCCUPANCY_COLORS["FEW_SEATS"]
    elif train_otp <= -60:
        train_otp_color = OCCUPANCY_COLORS["MANY_SEATS"]
    else:
        train_otp_color = "#ffffff"

    # time stuff
    stop_time = time.from_timestamp(int(train["time"]))  # parse the time that
    eta = int(math.round(time.parse_duration(str(int(train["time"]) - time.now().unix) + "s").minutes))  # this could *maybe* break if the train is later than 59 minutes, but I haven't had a chance to test this yet, which is probably a good thing!
    eta_str = "%dm" % eta if eta > 0 else "Due"

    # consist rendering
    consist = train_info["consist"]["cars"]
    cars = [render_car(car, i) for i, car in enumerate(consist)]

    return render.Root(
        delay = 850,  # make sure we can make it through the stops before our window on the device ends
        child = render.Column(
            children = [
                render.Box(
                    # branch color
                    width = 64,
                    height = 1,
                    color = branch_color,
                ),
                render.Box(
                    # alerts, if any
                    width = 64,
                    height = 1,
                    color = "#ffe91f" if is_alert else "#000000",
                ),
                render.Row(
                    children = [
                        render.Padding(child = render.Image(train_icon), pad = (0, 0, 1, 0)),  # branch/terminal icon
                        render.Column(children = [
                            # train number, eta, peak info
                            render.Row(expanded = True, main_align = "space_between", children = [
                                render.Box(
                                    child = render.Marquee(
                                        child = render.Text(train_number),
                                        align = "center",
                                        width = 20,
                                    ),
                                    width = 20,
                                    height = 8,
                                    color = branch_color,
                                ),  # make the train number look nice, use a marquee to scroll it in case it's longer than usual (ie special gameday trains)
                                render.Animation(children = [
                                    render.Text(stop_time.in_location("America/New_York").format("3:04"), color = train_otp_color),  # janky way of slowing this animation down
                                    render.Text(stop_time.in_location("America/New_York").format("3:04"), color = train_otp_color),
                                    render.Text(stop_time.in_location("America/New_York").format("3:04"), color = train_otp_color),
                                    render.Text("%s %s" % ("▴" if is_peak else "▾", eta_str if eta != 0 else "Arr")),  # peak icon and eta, or "Arr"iving if it's zero.
                                    render.Text("%s %s" % ("▴" if is_peak else "▾", eta_str if eta != 0 else "Arr")),
                                    render.Text("%s %s" % ("▴" if is_peak else "▾", eta_str if eta != 0 else "Arr")),
                                ]),
                            ]),
                            render.Row(children = [
                                render.Text("%s " % stop_track_type),  # "Track" or "Platform"
                                render.Text(stop_track, color = "#ffffff" if not track_change else STATUS_COLORS["ARRIVING"]),  # change the color if there's a track change to draw attention to it.
                                render.Image(ALERT_ICON) if track_change else None,  # show the alert icon if there's been a track change
                            ]),
                        ]),
                    ],
                ),
                render.Animation(children = [
                    # stops
                    render.Text(stop, font = "tb-8")
                    for stop in next_stops[:-1]  # all but the last stop get 1 frame.
                ] + [render.Text(next_stops[-1], font = "tb-8")] * 3),  # hold the last stop on screen longer
                render.Padding(
                    # consist
                    child = render.Row(children = cars, expanded = True, main_align = "center"),
                    pad = (1, 2, 0, 0),
                ),
                render.Row(expanded = True, main_align = "center", children = [
                    # train loading and platform indicator
                    render.Padding(pad = (0, 1, 0, 0), child = render.Box(width = 62, height = 1, color = status_color) if stop_status != "ARRIVING" else render.Animation(children = [
                        # flash the "platform" if the train is arriving
                        render.Box(width = 62, height = 1, color = STATUS_COLORS["ARRIVING"]),
                        render.Box(width = 62, height = 1, color = STATUS_COLORS["BERTHED"]),
                    ])),
                ]),
            ],
        ),
    )

def render_car(car, i):
    if car["locomotive"]:
        locomotive_parts = [
            render.Column(children = [
                render.Box(height = 1, width = 1, color = "#000000"),
                render.Box(height = 1, width = 1, color = OCCUPANCY_COLORS["LOCOMOTIVE"]),
            ]),
            render.Box(height = 2, width = 3, color = OCCUPANCY_COLORS["LOCOMOTIVE"]),
        ]
        if not i == 0:  # if this isn't the first locomotive, reverse it.
            locomotive_parts = reversed(locomotive_parts)
        return render.Row(children = locomotive_parts + [render.Box(height = 2, width = 1, color = "#000000")])

    elif not car["revenue"]:
        car_color = OCCUPANCY_COLORS["NON_REVENUE"]
    else:
        car_color = OCCUPANCY_COLORS[car["loading"]] if car["loading"] in OCCUPANCY_COLORS else OCCUPANCY_COLORS["NO_DATA"]

    car["restroom"] = False if "restroom" not in car else car["restroom"]

    if car["restroom"]:
        return render.Row(children = [
            render.Column(children = [
                render.Box(height = 1, width = 1, color = car_color),
                render.Box(height = 1, width = 1, color = "#2540ed"),
            ]),
            render.Box(height = 2, width = 3, color = car_color),
            render.Box(height = 1, width = 1, color = "#000000"),
        ])
    else:
        return render.Row(children = [
            render.Box(height = 2, width = 4, color = car_color),
            render.Box(height = 1, width = 1, color = "#000000"),
        ])

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Station to show arrivals for",
                icon = "houseFlag",
                default = "JAM",
                options = [schema.Option(display = "%s %s" % (key, value), value = key) for key, value in STATION_NAMES.items() if key != "ALL"],
            ),
            schema.Dropdown(
                id = "filter_direction",
                name = "Direction",
                desc = "Filter trains by direction (optional)",
                icon = "compass",
                default = "NESW",
                options = [
                    schema.Option(display = "Both", value = "NESW"),
                    schema.Option(display = "North/East", value = "NE"),
                    schema.Option(display = "South/West", value = "SW"),
                ],
            ),
            schema.Dropdown(
                id = "filter_branch",
                name = "Branch",
                desc = "Filter trains by branch or line (optional)",
                icon = "filter",
                default = "ALL",
                options = [
                    schema.Option(value = key, display = value)
                    for key, value in BRANCH_CODES.items()
                    if key != "??"
                ],
            ),
            schema.Dropdown(
                id = "filter_stop",
                name = "To station",
                desc = "Filter by stops (optional)",
                icon = "briefcase",
                default = "ALL",
                options = [schema.Option(display = "%s %s" % (key, value), value = key) for key, value in STATION_NAMES.items()],
            ),
        ],
    )
