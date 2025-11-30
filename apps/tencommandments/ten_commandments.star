"""
Applet: Ten Commandments
Summary: Displays ten commandments
Description: Displays the ten commandments.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")  #to encode/decode json data going to and from cache
load("images/ten_commandments_generic_1.png", TEN_COMMANDMENTS_GENERIC_1_ASSET = "file")
load("images/ten_commandments_generic_2.png", TEN_COMMANDMENTS_GENERIC_2_ASSET = "file")
load("images/ten_commandments_generic_3.png", TEN_COMMANDMENTS_GENERIC_3_ASSET = "file")
load("images/ten_commandments_generic_4.png", TEN_COMMANDMENTS_GENERIC_4_ASSET = "file")
load("images/ten_commandments_generic_5.png", TEN_COMMANDMENTS_GENERIC_5_ASSET = "file")
load("images/ten_commandments_generic_6.png", TEN_COMMANDMENTS_GENERIC_6_ASSET = "file")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TIMEZONE = "America/New_York"

commandments = {
    0: {
        "commandment": "I am the Lord thy God, thou shalt not have any gods before Me.",
        "commands": "faith, hope, love, and worship of God; reverence for holy things; prayer.",
        "forbids": "idolatry; superstition; spiritism; tempting God; sacrilege; attendance at false worship.",
    },
    1: {
        "commandment": "Thou shalt not take the name of the Lord thy God in vain.",
        "commands": "reverence in speaking about God and holy things; the keeping of oaths and vows.",
        "forbids": "blasphemy; the irreverent use of God's name.",
    },
    2: {
        "commandment": "Remember to keep holy the Sabbath day.",
        "commands": "going to church on Sundays and holy days of obligation.",
        "forbids": "missing church through one's own fault; unnecessary servile work on Sunday and holy days of obligation.",
    },
    3: {
        "commandment": "Honor thy father and mother.",
        "commands": "love; respect; obedience of children; care for the spiritual and temporal welfare of your children.",
        "forbids": "hatred of parents and superiors; disrespect.",
    },
    4: {
        "commandment": "Thou shalt not murder.",
        "commands": "safeguarding of one's own life and bodily welfare and that of others.",
        "forbids": "unjust killing; suicide; abortion; sterilization; dueling; endangering life and limb of self or others.",
    },
    5: {
        "commandment": "Thou shalt not commit adultery.",
        "commands": "chastity in word and deed.",
        "forbids": "obscene speech; impure actions alone or with others.",
    },
    6: {
        "commandment": "Thou shalt not steal.",
        "commands": "respect for property of rights; paying of just debts and just wages.",
        "forbids": "theft; damage to property; not returning found or borrowed articles.",
    },
    7: {
        "commandment": "Thou shalt not bear false witness against thy neighbor.",
        "commands": "truthfulness; respect for the good name of others; the observance of secrecy when required.",
        "forbids": "lying; injury to the good name of others; slander; talebearing.",
    },
    8: {
        "commandment": "Thou shalt not covet thy neighbor's wife.",
        "commands": "purity in thought.",
        "forbids": "willful impure thought and desires.",
    },
    9: {
        "commandment": "Thou shalt not covet thy neighbor's goods.",
        "commands": "respect for the rights of others.",
        "forbids": "the desire to take, to keep, or damage the property of others.",
    },
}

#Christian images
images = {
    0: {
        "image": TEN_COMMANDMENTS_GENERIC_3_ASSET.readall(),
    },
    1: {
        "image": TEN_COMMANDMENTS_GENERIC_5_ASSET.readall(),
    },
    2: {
        "image": TEN_COMMANDMENTS_GENERIC_2_ASSET.readall(),
    },
    3: {
        "image": TEN_COMMANDMENTS_GENERIC_6_ASSET.readall(),
    },
    4: {
        "image": TEN_COMMANDMENTS_GENERIC_4_ASSET.readall(),
    },
    5: {
        "image": TEN_COMMANDMENTS_GENERIC_1_ASSET.readall(),
    },
}

def day_of_year(date, timezone):
    """ day_of_year

    Args:
        date: the current time
        timezone: the current timezone

    Returns:
        The day of the year, and integer between 1 and 366
    """

    firstdayofyear = time.time(year = date.year, month = 1, day = 1, hour = 0, minute = 0, second = 0, location = timezone)
    day_of_year = math.ceil(time.parse_duration(date - firstdayofyear).seconds / 86400)
    return (day_of_year)

def main(config):
    """ Main

    Args:
        config: Configuration Items to control how the app is displayed
    Returns:
        The display inforamtion for the Tidbyt
    """

    #choose one commandment per day based on day of year. or always random
    if (config.get("display", "OncePerDay") == "OncePerDay"):
        now = config.get("time")
        now = (time.parse_time(now) if now else time.now())
        current_commandment = commandments[day_of_year(now, DEFAULT_TIMEZONE) % len(commandments)]
    else:
        #default is random element
        current_commandment = commandments[random.number(0, len(commandments) - 1)]

    #for testing: pick a specific commandment
    #current_commandment = commandments[7]

    #Always get a random image
    current_image = random.number(0, len(images) - 1)
    print(current_image)

    return render.Root(
        render.Row(
            children = [
                render.Stack(
                    children = [
                        render.Image(
                            src = base64.decode(images[current_image]["image"]),
                            width = 12,
                            height = 32,
                        ),
                        render.Padding(
                            pad = (12, 0, 0, 0),
                            child = render.Marquee(
                                width = 64,
                                child = render.Text(current_commandment["commandment"], color = "#E0A42B", font = "6x13"),
                            ),
                        ),
                        render.Padding(
                            pad = (12, 20, 0, 0),
                            child = render.Marquee(
                                width = 64,
                                offset_start = len(current_commandment["commandment"]) * 6,
                                child = render.Text("Commands %s Forbids %s" % (current_commandment["commands"], current_commandment["forbids"]), color = "#F2C900", font = "Dina_r400-6"),
                            ),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    element_display_options = [
        schema.Option(
            display = "One Commandment Per Day",
            value = "OncePerDay",
        ),
        schema.Option(
            display = "Random Commandment Each Time",
            value = "Random",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Dropdown(
                id = "display",
                name = "Display",
                desc = "Display Choice",
                icon = "display",
                options = element_display_options,
                default = element_display_options[0].value,
            ),
        ],
    )
