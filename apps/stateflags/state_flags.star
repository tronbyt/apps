"""
Applet: State Flags
Summary: State Flags
Description: Displays state flags.
Author: Robert Ison
"""

load("images/flag_ak.png", FLAG_AK_ASSET = "file")
load("images/flag_al.png", FLAG_AL_ASSET = "file")
load("images/flag_ar.png", FLAG_AR_ASSET = "file")
load("images/flag_az.png", FLAG_AZ_ASSET = "file")
load("images/flag_ca.png", FLAG_CA_ASSET = "file")
load("images/flag_co.png", FLAG_CO_ASSET = "file")
load("images/flag_ct.png", FLAG_CT_ASSET = "file")
load("images/flag_dc.png", FLAG_DC_ASSET = "file")
load("images/flag_de.png", FLAG_DE_ASSET = "file")
load("images/flag_fl.png", FLAG_FL_ASSET = "file")
load("images/flag_ga.png", FLAG_GA_ASSET = "file")
load("images/flag_hi.png", FLAG_HI_ASSET = "file")
load("images/flag_ia.png", FLAG_IA_ASSET = "file")
load("images/flag_id.png", FLAG_ID_ASSET = "file")
load("images/flag_il.png", FLAG_IL_ASSET = "file")
load("images/flag_in.png", FLAG_IN_ASSET = "file")
load("images/flag_ks.png", FLAG_KS_ASSET = "file")
load("images/flag_ky.png", FLAG_KY_ASSET = "file")
load("images/flag_la.png", FLAG_LA_ASSET = "file")
load("images/flag_ma.png", FLAG_MA_ASSET = "file")
load("images/flag_md.png", FLAG_MD_ASSET = "file")
load("images/flag_me.png", FLAG_ME_ASSET = "file")
load("images/flag_mi.png", FLAG_MI_ASSET = "file")
load("images/flag_mn.png", FLAG_MN_ASSET = "file")
load("images/flag_mo.png", FLAG_MO_ASSET = "file")
load("images/flag_ms.png", FLAG_MS_ASSET = "file")
load("images/flag_mt.png", FLAG_MT_ASSET = "file")
load("images/flag_nc.png", FLAG_NC_ASSET = "file")
load("images/flag_nd.png", FLAG_ND_ASSET = "file")
load("images/flag_ne.png", FLAG_NE_ASSET = "file")
load("images/flag_nh.png", FLAG_NH_ASSET = "file")
load("images/flag_nj.png", FLAG_NJ_ASSET = "file")
load("images/flag_nm.png", FLAG_NM_ASSET = "file")
load("images/flag_nv.png", FLAG_NV_ASSET = "file")
load("images/flag_ny.png", FLAG_NY_ASSET = "file")
load("images/flag_oh.png", FLAG_OH_ASSET = "file")
load("images/flag_ok.png", FLAG_OK_ASSET = "file")
load("images/flag_or.png", FLAG_OR_ASSET = "file")
load("images/flag_pa.png", FLAG_PA_ASSET = "file")
load("images/flag_ri.png", FLAG_RI_ASSET = "file")
load("images/flag_sc.png", FLAG_SC_ASSET = "file")
load("images/flag_sd.png", FLAG_SD_ASSET = "file")
load("images/flag_tn.png", FLAG_TN_ASSET = "file")
load("images/flag_tx.png", FLAG_TX_ASSET = "file")
load("images/flag_ut.png", FLAG_UT_ASSET = "file")
load("images/flag_va.png", FLAG_VA_ASSET = "file")
load("images/flag_vt.png", FLAG_VT_ASSET = "file")
load("images/flag_wa.png", FLAG_WA_ASSET = "file")
load("images/flag_wi.png", FLAG_WI_ASSET = "file")
load("images/flag_wv.png", FLAG_WV_ASSET = "file")
load("images/flag_wy.png", FLAG_WY_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

DISPLAY_FONT = "5x8"
DISPLAY_COLOR_1 = "#B31942"  #Red
DISPLAY_COLOR_2 = "#ffffff"  #White
DISPLAY_COLOR_3 = "#0A3161"  #Blue

STATE_FLAGS = {
    "de": {
        "name": "Delaware",
        "order": "1",
        "entry": "Dec 7, 1787",
        "capital": "Dover",
        "nickname": "First State",
        "flag": FLAG_DE_ASSET.readall(),
    },
    "pa": {
        "name": "Pennsylvania",
        "order": "2",
        "entry": "Dec 12, 1787",
        "capital": "Harrisburg",
        "nickname": "Keystone",
        "flag": FLAG_PA_ASSET.readall(),
    },
    "nj": {
        "name": "New Jersey",
        "order": "3",
        "entry": "Dec 18, 1787",
        "capital": "Trenton",
        "nickname": "Garden",
        "flag": FLAG_NJ_ASSET.readall(),
    },
    "ga": {
        "name": "Georgia",
        "order": "4",
        "entry": "Jan 2, 1788",
        "capital": "Atlanta",
        "nickname": "Peach",
        "flag": FLAG_GA_ASSET.readall(),
    },
    "ct": {
        "name": "Connecticut",
        "order": "5",
        "entry": "Jan 9, 1788",
        "capital": "Hartford",
        "nickname": "Nutmeg",
        "flag": FLAG_CT_ASSET.readall(),
    },
    "ma": {
        "name": "Massachusetts",
        "order": "6",
        "entry": "Feb 6, 1788",
        "capital": "Boston",
        "nickname": "Bay State",
        "flag": FLAG_MA_ASSET.readall(),
    },
    "md": {
        "name": "Maryland",
        "order": "7",
        "entry": "Apr 28, 1788",
        "capital": "Annapolis",
        "nickname": "Old Line",
        "flag": FLAG_MD_ASSET.readall(),
    },
    "sc": {
        "name": "S. Carolina",
        "order": "8",
        "entry": "May 23, 1788",
        "capital": "Columbia",
        "nickname": "Palmetto",
        "flag": FLAG_SC_ASSET.readall(),
    },
    "nh": {
        "name": "New Hampshire",
        "order": "9",
        "entry": "Jun 21, 1788",
        "capital": "Concord",
        "nickname": "Granite",
        "flag": FLAG_NH_ASSET.readall(),
    },
    "va": {
        "name": "Virginia",
        "order": "10",
        "entry": "Jun 25, 1788",
        "capital": "Richmond",
        "nickname": "Old Dominion",
        "flag": FLAG_VA_ASSET.readall(),
    },
    "ny": {
        "name": "New York",
        "order": "11",
        "entry": "Jul 26, 1788",
        "capital": "Albany",
        "nickname": "Empire State",
        "flag": FLAG_NY_ASSET.readall(),
    },
    "nc": {
        "name": "N. Carolina",
        "order": "12",
        "entry": "Nov 21, 1789",
        "capital": "Raleigh",
        "nickname": "Tar Heel",
        "flag": FLAG_NC_ASSET.readall(),
    },
    "ri": {
        "name": "Rhode Island",
        "order": "13",
        "entry": "May 29, 1790",
        "capital": "Providence",
        "nickname": "Ocean State",
        "flag": FLAG_RI_ASSET.readall(),
    },
    "vt": {
        "name": "Vermont",
        "order": "14",
        "entry": "Mar 4, 1791",
        "capital": "Montpelier",
        "nickname": "Green Mtn.",
        "flag": FLAG_VT_ASSET.readall(),
    },
    "ky": {
        "name": "Kentucky",
        "order": "15",
        "entry": "Jun 1, 1792",
        "capital": "Frankfort",
        "nickname": "Bluegrass",
        "flag": FLAG_KY_ASSET.readall(),
    },
    "tn": {
        "name": "Tennessee",
        "order": "16",
        "entry": "Jun 1, 1796",
        "capital": "Nashville",
        "nickname": "Volunteer",
        "flag": FLAG_TN_ASSET.readall(),
    },
    "oh": {
        "name": "Ohio",
        "order": "17",
        "entry": "Mar 1, 1803",
        "capital": "Columbus",
        "nickname": "Buckeye",
        "flag": FLAG_OH_ASSET.readall(),
    },
    "la": {
        "name": "Louisiana",
        "order": "18",
        "entry": "Apr 30, 1812",
        "capital": "Baton Rouge",
        "nickname": "Pelican",
        "flag": FLAG_LA_ASSET.readall(),
    },
    "in": {
        "name": "Indiana",
        "order": "19",
        "entry": "Dec 11, 1816",
        "capital": "Indianapolis",
        "nickname": "Hoosier",
        "flag": FLAG_IN_ASSET.readall(),
    },
    "ms": {
        "name": "Mississippi",
        "order": "20",
        "entry": "Dec 10, 1817",
        "capital": "Jackson",
        "nickname": "Magnolia",
        "flag": FLAG_MS_ASSET.readall(),
    },
    "il": {
        "name": "Illinois",
        "order": "21",
        "entry": "Dec 3, 1818",
        "capital": "Springfield",
        "nickname": "Lincoln",
        "flag": FLAG_IL_ASSET.readall(),
    },
    "al": {
        "name": "Alabama",
        "order": "22",
        "entry": "Dec 14, 1819",
        "capital": "Montgomery",
        "nickname": "Heart Dixie",
        "flag": FLAG_AL_ASSET.readall(),
    },
    "me": {
        "name": "Maine",
        "order": "23",
        "entry": "Mar 15, 1820",
        "capital": "Augusta",
        "nickname": "Pine Tree",
        "flag": FLAG_ME_ASSET.readall(),
    },
    "mo": {
        "name": "Missouri",
        "order": "24",
        "entry": "Aug 10, 1821",
        "capital": "Jefferson Cty",
        "nickname": "Show Me",
        "flag": FLAG_MO_ASSET.readall(),
    },
    "ar": {
        "name": "Arkansas",
        "order": "25",
        "entry": "Jun 15, 1836",
        "capital": "Little Rock",
        "nickname": "Razorback",
        "flag": FLAG_AR_ASSET.readall(),
    },
    "mi": {
        "name": "Michigan",
        "order": "26",
        "entry": "Jan 26, 1837",
        "capital": "Lansing",
        "nickname": "Great Lakes",
        "flag": FLAG_MI_ASSET.readall(),
    },
    "fl": {
        "name": "Florida",
        "order": "27",
        "entry": "Mar 3, 1845",
        "capital": "Tallahassee",
        "nickname": "Sunshine",
        "flag": FLAG_FL_ASSET.readall(),
    },
    "tx": {
        "name": "Texas",
        "order": "28",
        "entry": "Dec 29, 1845",
        "capital": "Austin",
        "nickname": "Lone Star",
        "flag": FLAG_TX_ASSET.readall(),
    },
    "ia": {
        "name": "Iowa",
        "order": "29",
        "entry": "Dec 28, 1846",
        "capital": "Des Moines",
        "nickname": "Hawkeye",
        "flag": FLAG_IA_ASSET.readall(),
    },
    "wi": {
        "name": "Wisconsin",
        "order": "30",
        "entry": "May 29, 1848",
        "capital": "Madison",
        "nickname": "Badger",
        "flag": FLAG_WI_ASSET.readall(),
    },
    "ca": {
        "name": "California",
        "order": "31",
        "entry": "Sep 9, 1850",
        "capital": "",
        "nickname": "Golden",
        "flag": FLAG_CA_ASSET.readall(),
    },
    "mn": {
        "name": "Minnesota",
        "order": "32",
        "entry": "May 11, 1858",
        "capital": "St. Paul",
        "nickname": "Gopher",
        "flag": FLAG_MN_ASSET.readall(),
    },
    "or": {
        "name": "Oregon",
        "order": "33",
        "entry": "Feb 14, 1859",
        "capital": "Salem",
        "nickname": "Beaver",
        "flag": FLAG_OR_ASSET.readall(),
    },
    "ks": {
        "name": "Kansas",
        "order": "34",
        "entry": "Jan 29, 1861",
        "capital": "Topeka",
        "nickname": "Sunflower",
        "flag": FLAG_KS_ASSET.readall(),
    },
    "wv": {
        "name": "W. Virginia",
        "order": "35",
        "entry": "Jun 20, 1863",
        "capital": "Charleston",
        "nickname": "Mountain",
        "flag": FLAG_WV_ASSET.readall(),
    },
    "nv": {
        "name": "Nevada",
        "order": "36",
        "entry": "Oct 31, 1864",
        "capital": "Carson City",
        "nickname": "Silver",
        "flag": FLAG_NV_ASSET.readall(),
    },
    "ne": {
        "name": "Nebraska",
        "order": "37",
        "entry": "Mar 1, 1867",
        "capital": "Lincoln",
        "nickname": "Cornhusker",
        "flag": FLAG_NE_ASSET.readall(),
    },
    "co": {
        "name": "Colorado",
        "order": "38",
        "entry": "Aug 1, 1876",
        "capital": "Denver",
        "nickname": "Centennial",
        "flag": FLAG_CO_ASSET.readall(),
    },
    "nd": {
        "name": "N. Dakota",
        "order": "39",
        "entry": "Nov 2, 1889",
        "capital": "Bismark",
        "nickname": "Roughrider",
        "flag": FLAG_ND_ASSET.readall(),
    },
    "sd": {
        "name": "S. Dakota",
        "order": "40",
        "entry": "Nov 2, 1889",
        "capital": "Pierre",
        "nickname": "Coyote",
        "flag": FLAG_SD_ASSET.readall(),
    },
    "mt": {
        "name": "Montana",
        "order": "41",
        "entry": "Nov 8, 1889",
        "capital": "Helena",
        "nickname": "Big Sky",
        "flag": FLAG_MT_ASSET.readall(),
    },
    "wa": {
        "name": "Washington",
        "order": "42",
        "entry": "Nov 11, 1889",
        "capital": "Olympia",
        "nickname": "Evergreen",
        "flag": FLAG_WA_ASSET.readall(),
    },
    "id": {
        "name": "Idaho",
        "order": "43",
        "entry": "Jul 3, 1890",
        "capital": "Boise",
        "nickname": "Gem State",
        "flag": FLAG_ID_ASSET.readall(),
    },
    "wy": {
        "name": "Wyoming",
        "order": "44",
        "entry": "Jul 10, 1890",
        "capital": "Cheyenne",
        "nickname": "Cowboy",
        "flag": FLAG_WY_ASSET.readall(),
    },
    "ut": {
        "name": "Utah",
        "order": "45",
        "entry": "Jan 4, 1896",
        "capital": "Salt Lake Cty",
        "nickname": "Beehive",
        "flag": FLAG_UT_ASSET.readall(),
    },
    "ok": {
        "name": "Oklahoma",
        "order": "46",
        "entry": "Nov 16, 1907",
        "capital": "Oklahoma City",
        "nickname": "Sooner",
        "flag": FLAG_OK_ASSET.readall(),
    },
    "nm": {
        "name": "New Mexico",
        "order": "47",
        "entry": "Jan 6, 1912",
        "capital": "Santa Fe",
        "nickname": "Enchantment",
        "flag": FLAG_NM_ASSET.readall(),
    },
    "az": {
        "name": "Arizona",
        "order": "48",
        "entry": "Feb 14, 1912",
        "capital": "Phoenix",
        "nickname": "Grand Canyon",
        "flag": FLAG_AZ_ASSET.readall(),
    },
    "ak": {
        "name": "Alaska",
        "order": "49",
        "entry": "Jan 3, 1959",
        "capital": "Juneau",
        "nickname": "Last Frontier",
        "flag": FLAG_AK_ASSET.readall(),
    },
    "hi": {
        "name": "Hawaii",
        "order": "50",
        "entry": "Aug 21, 1959",
        "capital": "Honolulu",
        "nickname": "Aloha State",
        "flag": FLAG_HI_ASSET.readall(),
    },
    "dc": {
        "name": "Washington DC",
        "order": "",
        "entry": "Jan 24, 1791",
        "capital": "Washington DC",
        "nickname": "The District",
        "flag": FLAG_DC_ASSET.readall(),
    },
}

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        Returns Tidbyt Display
    """
    show_hints = config.bool("show_hints", True)
    show_answer = config.bool("show_answer", True)
    show_single_state = config.bool("show_single", False)
    selected_state = config.get("stateSelected")

    frames = []

    display_states_count = 5
    if show_single_state:
        display_states_count = 1

    for _ in range(0, display_states_count):
        if show_single_state:
            state = STATE_FLAGS[selected_state]
        else:
            state = get_random_state()

        frames.append(render.Image(src = state["flag"], height = 32, width = 64))

        if show_hints:
            frames.append(render.Column(get_hint_screen(state)))
            frames.append(render.Image(src = state["flag"], height = 32, width = 64))

        if show_answer:
            frames.append(render.Column(get_state_info_screen(state), main_align = "center"))

    return render.Root(
        delay = 4000,
        child = render.Animation(children = frames),
    )

def get_state_info_screen(state):
    children = [
        render.Text("%s" % (state["name"]), color = DISPLAY_COLOR_1, font = DISPLAY_FONT),
        render.Text(" "),
        render.Text("Capital:", color = DISPLAY_COLOR_2, font = DISPLAY_FONT),
        render.Text("%s" % state["capital"], color = DISPLAY_COLOR_3, font = DISPLAY_FONT),
    ]

    return children

# get hint screen
def get_hint_screen(state):
    children = [
        render.Text("Hints:", color = DISPLAY_COLOR_2, font = DISPLAY_FONT),
        render.Text("%s" % (state["nickname"]), color = DISPLAY_COLOR_1, font = DISPLAY_FONT),
        render.Text("Admitted: %s" % state["order"], color = DISPLAY_COLOR_2, font = DISPLAY_FONT),
        render.Text("%s" % state["entry"], color = DISPLAY_COLOR_3, font = DISPLAY_FONT),
    ]

    return children

# retrieves a random state
def get_random_state():
    random_number = random.number(1, len(STATE_FLAGS) - 1)
    random_state = STATE_FLAGS.values()[random_number]
    return random_state

def get_states(type):
    # Sorting by the 'name' key
    state_flags = dict(sorted(STATE_FLAGS.items(), key = lambda x: x[1]["name"]))
    state_options = []

    for state in state_flags:
        state_options.append(
            schema.Option(
                display = STATE_FLAGS[state]["name"],
                value = state,
            ),
        )

    if (type == "true"):
        return [
            schema.Dropdown(
                id = "stateSelected",
                name = "Selected State",
                desc = "Pick the state you want displayed",
                icon = "flagUsa",
                default = state_options[0].value,
                options = state_options,
            ),
        ]
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_hints",
                name = "Show Hints",
                icon = "newspaper",
                desc = "Show Hints to guess state flag.",
                default = True,
            ),
            schema.Toggle(
                id = "show_answer",
                name = "Show Answer",
                icon = "newspaper",
                desc = "Show the name of the selected state flag.",
                default = True,
            ),
            schema.Toggle(
                id = "show_single",
                name = "Show Single State?",
                icon = "flagUsa",
                desc = "Show just one particular state flag.",
                default = False,
            ),
            schema.Generated(
                id = "statelist",
                source = "show_single",
                handler = get_states,
            ),
        ],
    )
