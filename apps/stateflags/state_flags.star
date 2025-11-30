"""
Applet: State Flags
Summary: State Flags
Description: Displays state flags.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")  #Used to read encoded image
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_04d1bf9a.png", IMG_04d1bf9a_ASSET = "file")
load("images/img_06d3431d.png", IMG_06d3431d_ASSET = "file")
load("images/img_0a27c5d2.png", IMG_0a27c5d2_ASSET = "file")
load("images/img_11017c91.png", IMG_11017c91_ASSET = "file")
load("images/img_1b51d67d.png", IMG_1b51d67d_ASSET = "file")
load("images/img_1ed7ddf1.png", IMG_1ed7ddf1_ASSET = "file")
load("images/img_2639335e.png", IMG_2639335e_ASSET = "file")
load("images/img_2ada35fa.png", IMG_2ada35fa_ASSET = "file")
load("images/img_309ea9bb.png", IMG_309ea9bb_ASSET = "file")
load("images/img_30ac6b0b.png", IMG_30ac6b0b_ASSET = "file")
load("images/img_3c76df69.png", IMG_3c76df69_ASSET = "file")
load("images/img_3d6614c8.png", IMG_3d6614c8_ASSET = "file")
load("images/img_42e6ae32.png", IMG_42e6ae32_ASSET = "file")
load("images/img_43b24441.png", IMG_43b24441_ASSET = "file")
load("images/img_47f17164.png", IMG_47f17164_ASSET = "file")
load("images/img_520492ae.png", IMG_520492ae_ASSET = "file")
load("images/img_57079cf3.png", IMG_57079cf3_ASSET = "file")
load("images/img_5a5c90af.png", IMG_5a5c90af_ASSET = "file")
load("images/img_5d693a6c.png", IMG_5d693a6c_ASSET = "file")
load("images/img_61cdd3ab.png", IMG_61cdd3ab_ASSET = "file")
load("images/img_6780e5e6.png", IMG_6780e5e6_ASSET = "file")
load("images/img_67926122.png", IMG_67926122_ASSET = "file")
load("images/img_6bd8d451.png", IMG_6bd8d451_ASSET = "file")
load("images/img_713b5e21.png", IMG_713b5e21_ASSET = "file")
load("images/img_80055138.png", IMG_80055138_ASSET = "file")
load("images/img_8112cb2a.png", IMG_8112cb2a_ASSET = "file")
load("images/img_82d8bc29.png", IMG_82d8bc29_ASSET = "file")
load("images/img_83e6eb30.png", IMG_83e6eb30_ASSET = "file")
load("images/img_84aa384a.png", IMG_84aa384a_ASSET = "file")
load("images/img_87389e52.png", IMG_87389e52_ASSET = "file")
load("images/img_8b70b1ea.png", IMG_8b70b1ea_ASSET = "file")
load("images/img_9227be5c.png", IMG_9227be5c_ASSET = "file")
load("images/img_96466064.png", IMG_96466064_ASSET = "file")
load("images/img_979e1351.png", IMG_979e1351_ASSET = "file")
load("images/img_9cfca98b.png", IMG_9cfca98b_ASSET = "file")
load("images/img_a0a88751.png", IMG_a0a88751_ASSET = "file")
load("images/img_a3a888e2.png", IMG_a3a888e2_ASSET = "file")
load("images/img_a71ed156.png", IMG_a71ed156_ASSET = "file")
load("images/img_a775e393.png", IMG_a775e393_ASSET = "file")
load("images/img_aff113cf.png", IMG_aff113cf_ASSET = "file")
load("images/img_b0c189de.png", IMG_b0c189de_ASSET = "file")
load("images/img_ba2135d0.png", IMG_ba2135d0_ASSET = "file")
load("images/img_c5d69c7b.png", IMG_c5d69c7b_ASSET = "file")
load("images/img_c7e06b00.png", IMG_c7e06b00_ASSET = "file")
load("images/img_c7e66d67.png", IMG_c7e66d67_ASSET = "file")
load("images/img_cc2c771e.png", IMG_cc2c771e_ASSET = "file")
load("images/img_d3af4e28.png", IMG_d3af4e28_ASSET = "file")
load("images/img_d3e15147.png", IMG_d3e15147_ASSET = "file")
load("images/img_dfbd410d.png", IMG_dfbd410d_ASSET = "file")
load("images/img_e6f7cb59.png", IMG_e6f7cb59_ASSET = "file")
load("images/img_f817700d.png", IMG_f817700d_ASSET = "file")

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
        "flag": IMG_84aa384a_ASSET.readall(),
    },
    "pa": {
        "name": "Pennsylvania",
        "order": "2",
        "entry": "Dec 12, 1787",
        "capital": "Harrisburg",
        "nickname": "Keystone",
        "flag": IMG_2ada35fa_ASSET.readall(),
    },
    "nj": {
        "name": "New Jersey",
        "order": "3",
        "entry": "Dec 18, 1787",
        "capital": "Trenton",
        "nickname": "Garden",
        "flag": IMG_1b51d67d_ASSET.readall(),
    },
    "ga": {
        "name": "Georgia",
        "order": "4",
        "entry": "Jan 2, 1788",
        "capital": "Atlanta",
        "nickname": "Peach",
        "flag": IMG_a0a88751_ASSET.readall(),
    },
    "ct": {
        "name": "Connecticut",
        "order": "5",
        "entry": "Jan 9, 1788",
        "capital": "Hartford",
        "nickname": "Nutmeg",
        "flag": IMG_06d3431d_ASSET.readall(),
    },
    "ma": {
        "name": "Massachusetts",
        "order": "6",
        "entry": "Feb 6, 1788",
        "capital": "Boston",
        "nickname": "Bay State",
        "flag": IMG_dfbd410d_ASSET.readall(),
    },
    "md": {
        "name": "Maryland",
        "order": "7",
        "entry": "Apr 28, 1788",
        "capital": "Annapolis",
        "nickname": "Old Line",
        "flag": IMG_3c76df69_ASSET.readall(),
    },
    "sc": {
        "name": "S. Carolina",
        "order": "8",
        "entry": "May 23, 1788",
        "capital": "Columbia",
        "nickname": "Palmetto",
        "flag": IMG_9227be5c_ASSET.readall(),
    },
    "nh": {
        "name": "New Hampshire",
        "order": "9",
        "entry": "Jun 21, 1788",
        "capital": "Concord",
        "nickname": "Granite",
        "flag": IMG_5a5c90af_ASSET.readall(),
    },
    "va": {
        "name": "Virginia",
        "order": "10",
        "entry": "Jun 25, 1788",
        "capital": "Richmond",
        "nickname": "Old Dominion",
        "flag": IMG_80055138_ASSET.readall(),
    },
    "ny": {
        "name": "New York",
        "order": "11",
        "entry": "Jul 26, 1788",
        "capital": "Albany",
        "nickname": "Empire State",
        "flag": IMG_57079cf3_ASSET.readall(),
    },
    "nc": {
        "name": "N. Carolina",
        "order": "12",
        "entry": "Nov 21, 1789",
        "capital": "Raleigh",
        "nickname": "Tar Heel",
        "flag": IMG_42e6ae32_ASSET.readall(),
    },
    "ri": {
        "name": "Rhode Island",
        "order": "13",
        "entry": "May 29, 1790",
        "capital": "Providence",
        "nickname": "Ocean State",
        "flag": IMG_2639335e_ASSET.readall(),
    },
    "vt": {
        "name": "Vermont",
        "order": "14",
        "entry": "Mar 4, 1791",
        "capital": "Montpelier",
        "nickname": "Green Mtn.",
        "flag": IMG_b0c189de_ASSET.readall(),
    },
    "ky": {
        "name": "Kentucky",
        "order": "15",
        "entry": "Jun 1, 1792",
        "capital": "Frankfort",
        "nickname": "Bluegrass",
        "flag": IMG_6bd8d451_ASSET.readall(),
    },
    "tn": {
        "name": "Tennessee",
        "order": "16",
        "entry": "Jun 1, 1796",
        "capital": "Nashville",
        "nickname": "Volunteer",
        "flag": IMG_6780e5e6_ASSET.readall(),
    },
    "oh": {
        "name": "Ohio",
        "order": "17",
        "entry": "Mar 1, 1803",
        "capital": "Columbus",
        "nickname": "Buckeye",
        "flag": IMG_c5d69c7b_ASSET.readall(),
    },
    "la": {
        "name": "Louisiana",
        "order": "18",
        "entry": "Apr 30, 1812",
        "capital": "Baton Rouge",
        "nickname": "Pelican",
        "flag": IMG_1ed7ddf1_ASSET.readall(),
    },
    "in": {
        "name": "Indiana",
        "order": "19",
        "entry": "Dec 11, 1816",
        "capital": "Indianapolis",
        "nickname": "Hoosier",
        "flag": IMG_83e6eb30_ASSET.readall(),
    },
    "ms": {
        "name": "Mississippi",
        "order": "20",
        "entry": "Dec 10, 1817",
        "capital": "Jackson",
        "nickname": "Magnolia",
        "flag": IMG_87389e52_ASSET.readall(),
    },
    "il": {
        "name": "Illinois",
        "order": "21",
        "entry": "Dec 3, 1818",
        "capital": "Springfield",
        "nickname": "Lincoln",
        "flag": IMG_96466064_ASSET.readall(),
    },
    "al": {
        "name": "Alabama",
        "order": "22",
        "entry": "Dec 14, 1819",
        "capital": "Montgomery",
        "nickname": "Heart Dixie",
        "flag": IMG_aff113cf_ASSET.readall(),
    },
    "me": {
        "name": "Maine",
        "order": "23",
        "entry": "Mar 15, 1820",
        "capital": "Augusta",
        "nickname": "Pine Tree",
        "flag": IMG_cc2c771e_ASSET.readall(),
    },
    "mo": {
        "name": "Missouri",
        "order": "24",
        "entry": "Aug 10, 1821",
        "capital": "Jefferson Cty",
        "nickname": "Show Me",
        "flag": IMG_979e1351_ASSET.readall(),
    },
    "ar": {
        "name": "Arkansas",
        "order": "25",
        "entry": "Jun 15, 1836",
        "capital": "Little Rock",
        "nickname": "Razorback",
        "flag": IMG_0a27c5d2_ASSET.readall(),
    },
    "mi": {
        "name": "Michigan",
        "order": "26",
        "entry": "Jan 26, 1837",
        "capital": "Lansing",
        "nickname": "Great Lakes",
        "flag": IMG_82d8bc29_ASSET.readall(),
    },
    "fl": {
        "name": "Florida",
        "order": "27",
        "entry": "Mar 3, 1845",
        "capital": "Tallahassee",
        "nickname": "Sunshine",
        "flag": IMG_67926122_ASSET.readall(),
    },
    "tx": {
        "name": "Texas",
        "order": "28",
        "entry": "Dec 29, 1845",
        "capital": "Austin",
        "nickname": "Lone Star",
        "flag": IMG_c7e06b00_ASSET.readall(),
    },
    "ia": {
        "name": "Iowa",
        "order": "29",
        "entry": "Dec 28, 1846",
        "capital": "Des Moines",
        "nickname": "Hawkeye",
        "flag": IMG_8112cb2a_ASSET.readall(),
    },
    "wi": {
        "name": "Wisconsin",
        "order": "30",
        "entry": "May 29, 1848",
        "capital": "Madison",
        "nickname": "Badger",
        "flag": IMG_11017c91_ASSET.readall(),
    },
    "ca": {
        "name": "California",
        "order": "31",
        "entry": "Sep 9, 1850",
        "capital": "",
        "nickname": "Golden",
        "flag": IMG_d3af4e28_ASSET.readall(),
    },
    "mn": {
        "name": "Minnesota",
        "order": "32",
        "entry": "May 11, 1858",
        "capital": "St. Paul",
        "nickname": "Gopher",
        "flag": IMG_47f17164_ASSET.readall(),
    },
    "or": {
        "name": "Oregon",
        "order": "33",
        "entry": "Feb 14, 1859",
        "capital": "Salem",
        "nickname": "Beaver",
        "flag": IMG_ba2135d0_ASSET.readall(),
    },
    "ks": {
        "name": "Kansas",
        "order": "34",
        "entry": "Jan 29, 1861",
        "capital": "Topeka",
        "nickname": "Sunflower",
        "flag": IMG_43b24441_ASSET.readall(),
    },
    "wv": {
        "name": "W. Virginia",
        "order": "35",
        "entry": "Jun 20, 1863",
        "capital": "Charleston",
        "nickname": "Mountain",
        "flag": IMG_c7e66d67_ASSET.readall(),
    },
    "nv": {
        "name": "Nevada",
        "order": "36",
        "entry": "Oct 31, 1864",
        "capital": "Carson City",
        "nickname": "Silver",
        "flag": IMG_520492ae_ASSET.readall(),
    },
    "ne": {
        "name": "Nebraska",
        "order": "37",
        "entry": "Mar 1, 1867",
        "capital": "Lincoln",
        "nickname": "Cornhusker",
        "flag": IMG_f817700d_ASSET.readall(),
    },
    "co": {
        "name": "Colorado",
        "order": "38",
        "entry": "Aug 1, 1876",
        "capital": "Denver",
        "nickname": "Centennial",
        "flag": IMG_a3a888e2_ASSET.readall(),
    },
    "nd": {
        "name": "N. Dakota",
        "order": "39",
        "entry": "Nov 2, 1889",
        "capital": "Bismark",
        "nickname": "Roughrider",
        "flag": IMG_04d1bf9a_ASSET.readall(),
    },
    "sd": {
        "name": "S. Dakota",
        "order": "40",
        "entry": "Nov 2, 1889",
        "capital": "Pierre",
        "nickname": "Coyote",
        "flag": IMG_d3e15147_ASSET.readall(),
    },
    "mt": {
        "name": "Montana",
        "order": "41",
        "entry": "Nov 8, 1889",
        "capital": "Helena",
        "nickname": "Big Sky",
        "flag": IMG_8b70b1ea_ASSET.readall(),
    },
    "wa": {
        "name": "Washington",
        "order": "42",
        "entry": "Nov 11, 1889",
        "capital": "Olympia",
        "nickname": "Evergreen",
        "flag": IMG_61cdd3ab_ASSET.readall(),
    },
    "id": {
        "name": "Idaho",
        "order": "43",
        "entry": "Jul 3, 1890",
        "capital": "Boise",
        "nickname": "Gem State",
        "flag": IMG_30ac6b0b_ASSET.readall(),
    },
    "wy": {
        "name": "Wyoming",
        "order": "44",
        "entry": "Jul 10, 1890",
        "capital": "Cheyenne",
        "nickname": "Cowboy",
        "flag": IMG_a775e393_ASSET.readall(),
    },
    "ut": {
        "name": "Utah",
        "order": "45",
        "entry": "Jan 4, 1896",
        "capital": "Salt Lake Cty",
        "nickname": "Beehive",
        "flag": IMG_713b5e21_ASSET.readall(),
    },
    "ok": {
        "name": "Oklahoma",
        "order": "46",
        "entry": "Nov 16, 1907",
        "capital": "Oklahoma City",
        "nickname": "Sooner",
        "flag": IMG_309ea9bb_ASSET.readall(),
    },
    "nm": {
        "name": "New Mexico",
        "order": "47",
        "entry": "Jan 6, 1912",
        "capital": "Santa Fe",
        "nickname": "Enchantment",
        "flag": IMG_a71ed156_ASSET.readall(),
    },
    "az": {
        "name": "Arizona",
        "order": "48",
        "entry": "Feb 14, 1912",
        "capital": "Phoenix",
        "nickname": "Grand Canyon",
        "flag": IMG_5d693a6c_ASSET.readall(),
    },
    "ak": {
        "name": "Alaska",
        "order": "49",
        "entry": "Jan 3, 1959",
        "capital": "Juneau",
        "nickname": "Last Frontier",
        "flag": IMG_3d6614c8_ASSET.readall(),
    },
    "hi": {
        "name": "Hawaii",
        "order": "50",
        "entry": "Aug 21, 1959",
        "capital": "Honolulu",
        "nickname": "Aloha State",
        "flag": IMG_9cfca98b_ASSET.readall(),
    },
    "dc": {
        "name": "Washington DC",
        "order": "",
        "entry": "Jan 24, 1791",
        "capital": "Washington DC",
        "nickname": "The District",
        "flag": IMG_e6f7cb59_ASSET.readall(),
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

        frames.append(render.Image(src = base64.decode(state["flag"]), height = 32, width = 64))

        if show_hints:
            frames.append(render.Column(get_hint_screen(state)))
            frames.append(render.Image(src = base64.decode(state["flag"]), height = 32, width = 64))

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
