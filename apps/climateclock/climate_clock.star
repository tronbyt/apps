"""
Applet: Climate Clock
Summary: ClimateClock.world
Description: The most important number in the world.
Author: Rob Kimball
"""

load("images/bg_renewables.png", BG_RENEWABLES_ASSET = "file")
load("images/bg_warming.png", BG_WARMING_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BG_RENEWABLES = BG_RENEWABLES_ASSET.readall()
BG_WARMING = BG_WARMING_ASSET.readall()

# This is everything we would get from the API if we were to retrieve it over HTTP. In reality, the data here is only
# updated every couple of years so pinging the API isn't really necessary. I've pasted a recent JSON pull below, which
# makes updating the app easier and means fewer code changes if we do decide to start pulling it directly.
# This might be helpful if we add a screen to this app that displays their climate change news feed or the fund AUM.
# Source: https://api.climateclock.world/v1/clock
ALL_DATA = {
    "data": {
        "api_version": "v1.0",
        "config": {
            "device": "generic",
            "display": {
                "deadline": {
                    "color_primary": "#eb1c23",
                    "color_secondary": "#eb1c23",
                },
                "lifeline": {
                    "color_primary": "#4aa1cc",
                    "color_secondary": "#4aa1cc",
                },
                "neutral": {
                    "color_primary": "#ffffff",
                    "color_secondary": "#ffffff",
                },
                "newsfeed": {
                    "separator": " | ",
                },
                "timer": {
                    "unit_labels": {
                        "day": [
                            "DAY",
                            "D",
                        ],
                        "days": [
                            "DAYS",
                            "D",
                        ],
                        "year": [
                            "YEAR",
                            "YR",
                            "Y",
                        ],
                        "years": [
                            "YEARS",
                            "YRS",
                            "Y",
                        ],
                    },
                },
            },
            "modules": [
                "carbon_deadline_1",
                "renewables_1",
                "newsfeed_1",
            ],
        },
        "modules": {
            "carbon_deadline_1": {
                "description": "Time to act before we reach irreversible 1.5°C global temperature rise",
                "flavor": "deadline",
                "labels": [
                    "TIME LEFT TO LIMIT GLOBAL WARMING TO 1.5°C",
                    "TIME LEFT BEFORE 1.5°C GLOBAL WARMING",
                    "TIME TO ACT",
                ],
                "lang": "en",
                "timestamp": "2029-07-23T00:46:03+00:00",
                "type": "timer",
                "update_interval_seconds": 604800,
            },
            "green_climate_fund_1": {
                "description": "USD in the Green Climate Fund",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 9.52,
                "labels": [
                    "GREEN CLIMATE FUND",
                    "CLIMATE FUND",
                    "GCF",
                ],
                "lang": "en",
                "rate": "0",
                "resolution": "0.01",
                "timestamp": "2021-09-20T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "$B",
                ],
                "update_interval_seconds": 86400,
            },
            "indigenous_land_1": {
                "description": "Despite threats and lack of recognition, indigenous people are protecting this much land.",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 43.5,
                "labels": [
                    "LAND PROTECTED BY INDIGENOUS PEOPLE",
                    "INDIGENOUS PROTECTED LAND",
                    "INDIGENOUS PROTECTED",
                ],
                "lang": "en",
                "rate": "0",
                "resolution": "0.1",
                "timestamp": "2021-10-01T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "M KM²",
                ],
                "update_interval_seconds": 86400,
            },
            "newsfeed_1": {
                "description": "A newsfeed of hope: good news about climate change.",
                "flavor": "lifeline",
                "lang": "en",
                "newsfeed": [
                    {
                        "date": "2022-02-03T14:48:23+00:00",
                        "headline": "Snoqualmie Tribe Acquires 12,000 Acres of Ancestral Forestland in King County",
                        "headline_original": "Snoqualmie Tribe Acquires 12,000 Acres of Ancestral Forestland in King County ",
                        "link": "https://snoqualmietribe.us/snoqualmie-tribe-acquires-12000-acres-of-ancestral-forestland-in-king-county/?fbclid=IwAR390NwqMLsCso8T0gI1OYcOyxEJjOvCGgHUXEQmDjK78Aq6vW_ehPdJpu4 ",
                        "source": "Snoqualmie Tribe",
                        "summary": "",
                    },
                    {
                        "date": "2022-02-01T14:48:23+00:00",
                        "headline": "Earth has 14% more tree species than previously thought",
                        "headline_original": "Earth has more tree species than we thought ",
                        "link": "https://www.bbc.com/news/science-environment-60198433 ",
                        "source": "BBC",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-28T14:48:23+00:00",
                        "headline": "US federal judge blocks leasing more than 80 million acres for oil and gas production by the US Depa",
                        "headline_original": "In blow to Biden administration, judge halts oil and gas leases in Gulf of Mexico",
                        "link": "https://grist.org/energy/in-blow-to-biden-administration-judge-halts-oil-and-gas-leases-in-gulf-of-mexico/  ",
                        "source": "Grist",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-28T14:48:23+00:00",
                        "headline": "Australia pledges $700 million to protect Great Barrier Reef amid climate change threat",
                        "headline_original": "Australia pledges $700 million to protect Great Barrier Reef amid climate change threat  ",
                        "link": "https://edition.cnn.com/2022/01/27/australia/australia-great-barrier-reef-intl-hnk/index.html ",
                        "source": "CNN",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-27T14:48:23+00:00",
                        "headline": "China’s renewable energy sources may make up 50% of the country’s power capacity in 2022",
                        "headline_original": "Non-fossil fuels forecast to be 50% of China’s power capacity in 2022",
                        "link": "https://www.reuters.com/world/china/non-fossil-fuels-forecast-be-50-chinas-power-capacity-2022-2022-01-28/ ",
                        "source": "Reuters",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-26T14:48:23+00:00",
                        "headline": "Los Angeles City Council will ban new oil and gas wells and phase out existing wells",
                        "headline_original": "In historic vote, Los Angeles will phase out oil drilling",
                        "link": "https://grist.org/energy/in-historic-vote-los-angeles-will-phase-out-oil-drilling/ ",
                        "source": "Grist",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-24T14:48:23+00:00",
                        "headline": "China to cut energy consumption intensity by 13.5% in five years",
                        "headline_original": "China to cut energy consumption intensity by 13.5% pct in five years",
                        "link": "http://www.xinhuanet.com/english/20220124/b53f7dc6f5c246569cb440d87e387d83/c.html ",
                        "source": "Xinhua",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-13T14:48:23+00:00",
                        "headline": "Container shipping giant, Maersk, speeds up decarbonisation target by a decade",
                        "headline_original": "Maersk speeds up decarbonisation target by a decade",
                        "link": "https://www.reuters.com/markets/commodities/maersk-moves-net-zero-target-forward-by-decade-2040-2022-01-12/",
                        "source": "Reuters",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-02T14:48:23+00:00",
                        "headline": "France bans plastic packaging for most fruits and vegetables",
                        "headline_original": "France bans plastic packaging for most fruits and vegetables",
                        "link": "https://www.aljazeera.com/news/2022/1/2/france-bans-plastic-packaging-for-most-fruits-and-vegetables ",
                        "source": "AlJazeera",
                        "summary": "",
                    },
                ],
                "type": "newsfeed",
                "update_interval_seconds": 3600,
            },
            "renewables_1": {
                "description": "The percentage share of global energy consumption currently generated by renewable resources (solar, wind, hydroelectricity, wave and tidal, and bioenergy).",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 11.4,
                "labels": [
                    "WORLD'S ENERGY FROM RENEWABLES",
                    "GLOBAL RENEWABLE ENERGY",
                    "RENEWABLES",
                ],
                "lang": "en",
                "rate": "2.0428359571070087e-8",
                "resolution": "1e-9",
                "timestamp": "2020-01-01T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "%",
                ],
                "update_interval_seconds": 86400,
            },
        },
        "retrieval_timestamp": "2022-04-05T22:19:55+00:00",
    },
    "status": "success",
}

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def duration_to_string(sec):
    """
    Builds a prettier duration display from the total seconds than what is natively available in Go.
    This function was adapted from LukiLeu's Google Traffic app.

    :param sec: numeric type, total seconds of the trip duration
    :return: tuple of strings, years, days and a HH:MM:SS timestamp
    """
    seconds_in_year = 60 * 60 * 24 * 365
    seconds_in_day = 60 * 60 * 24
    seconds_in_hour = 60 * 60
    seconds_in_minute = 60

    years = sec // seconds_in_year
    days = (sec - (years * seconds_in_year)) // seconds_in_day
    hours = (sec - (years * seconds_in_year) - (days * seconds_in_day)) // seconds_in_hour
    minutes = (sec - (years * seconds_in_year) - (days * seconds_in_day) - (hours * seconds_in_hour)) // seconds_in_minute
    seconds = (sec - (years * seconds_in_year) - (days * seconds_in_day) - (hours * seconds_in_hour) - (minutes * seconds_in_minute))

    str_years, str_days, timestamp = "", "", ""
    for part in (hours, minutes, seconds):
        if part < 10:
            timestamp = timestamp + "0%i:" % part
        else:
            timestamp = timestamp + "%i:" % part
    timestamp = timestamp[:-1]  # final colon

    if years > 0:
        str_years = "%i Years" % years
    if days > 0:
        str_days = "%i Days" % days

    return str_years, str_days, timestamp

def renewables(DATA):
    fps = 20

    data = DATA["data"]["modules"]["renewables_1"]
    initial = data["initial"]  # 11.4
    units = data["unit_labels"][0]
    rate = float(data["rate"])
    start = time.parse_time(data["timestamp"])
    resolution = int(data["rate"][-1]) + 1

    end = time.now()
    elapsed = end - start
    current = elapsed.seconds * rate + initial

    def generate_data(x):
        # Decimal; generate {speed} values per second to animate over
        d = current + ((x * rate) / fps)

        # String; convert each one to a string, rounded to {resolution} digits
        s = "%s" % round(d, resolution)

        # Formatted; pad each string if it isn't at least {resolution + 3} long, so the animation doesn't jump
        f = s + "0" * (resolution - len(s) + 3) + units

        return render.Box(
            # expanded=True,
            # main_align="center",
            child = render.Text(f, color = "#050"),
            height = 16,
            width = 64,
        )

    # Generate enough frames to fill 15 seconds
    frames = [generate_data(x) for x in range(15 * 1000 // fps)]

    return render.Root(
        delay = 1000 // fps,
        child = render.Stack(
            children = [
                render.Image(BG_RENEWABLES),
                # render.Box(width = 64, height = 32, color = "#0006"),
                render.Column(
                    expanded = True,
                    main_align = "top",
                    cross_align = "center",
                    children = [render.Animation(children = frames)],
                ),
            ],
        ),
    )

def global_warming(DATA):
    fps = 1

    data = DATA["data"]["modules"]["carbon_deadline_1"]
    deadline = time.parse_time(data["timestamp"])
    rate = -1

    start = time.now()
    if deadline <= start:
        frames = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text("FIN", color = "#00094d"),
                ],
            ),
        ]
    else:
        remaining = int((deadline - start).seconds)

        frames = []

        for i in range(1, 15 * fps):
            years, days, stamp = duration_to_string(remaining + (rate * i))
            childs = []
            for element in (years, days, stamp):
                if len(element):
                    childs.append(
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [
                                render.Text(element, color = "#00094d"),
                            ],
                        ),
                    )
            frames.append(
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = childs,
                ),
            )

    return render.Root(
        delay = 1000 // fps,
        child = render.Stack(
            children = [
                render.Image(BG_WARMING),
                # render.Box(width = 64, height = 32, color = "#0003"),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [render.Animation(children = frames)],
                ),
            ],
        ),
    )

SCREENS = {
    "Renewable Energy": renewables,
    "Global Warming": global_warming,
}

def main(config):
    display = config.get("display", list(SCREENS.keys())[0])
    print(display)
    return SCREENS.get(display)(ALL_DATA)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display",
                name = "Display type",
                desc = "",
                icon = "chartPie",
                options = [
                    schema.Option(value = k, display = k)
                    for k, v in SCREENS.items()
                ],
                default = list(SCREENS.keys())[0],
            ),
        ],
    )
