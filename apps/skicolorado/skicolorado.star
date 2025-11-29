"""
Applet: ColoradoSki
Summary: Colorado ski reports
Description: Checks all the colorado ski resorts for their current conditions.
Author: mharlach
"""

load("html.star", "html")
load("http.star", "http")
load("images/a_basin_logo.png", A_BASIN_LOGO_ASSET = "file")
load("images/aspen_logo.png", ASPEN_LOGO_ASSET = "file")
load("images/beaver_creek_logo.png", BEAVER_CREEK_LOGO_ASSET = "file")
load("images/breckenridge_logo.png", BRECKENRIDGE_LOGO_ASSET = "file")
load("images/cable_car.png", CABLE_CAR_ASSET = "file")
load("images/cooper_logo.png", COOPER_LOGO_ASSET = "file")
load("images/copper_mountain_logo.png", COPPER_MOUNTAIN_LOGO_ASSET = "file")
load("images/crested_butte_logo.png", CRESTED_BUTTE_LOGO_ASSET = "file")
load("images/echo_mountain_logo.png", ECHO_MOUNTAIN_LOGO_ASSET = "file")
load("images/eldora_logo.png", ELDORA_LOGO_ASSET = "file")
load("images/grandby_ranch_logo.png", GRANDBY_RANCH_LOGO_ASSET = "file")
load("images/howelsen_hill_logo.png", HOWELSEN_HILL_LOGO_ASSET = "file")
load("images/keystone_logo.png", KEYSTONE_LOGO_ASSET = "file")
load("images/loveland_logo.png", LOVELAND_LOGO_ASSET = "file")
load("images/monarch_mountain_logo.png", MONARCH_MOUNTAIN_LOGO_ASSET = "file")
load("images/powderhorn_logo.png", POWDERHORN_LOGO_ASSET = "file")
load("images/purgatory_logo.png", PURGATORY_LOGO_ASSET = "file")
load("images/sign_post.png", SIGN_POST_ASSET = "file")
load("images/silverton_logo.png", SILVERTON_LOGO_ASSET = "file")
load("images/steamboat_logo.png", STEAMBOAT_LOGO_ASSET = "file")
load("images/sunlight_logo.png", SUNLIGHT_LOGO_ASSET = "file")
load("images/telluride_logo.png", TELLURIDE_LOGO_ASSET = "file")
load("images/vail_logo.png", VAIL_LOGO_ASSET = "file")
load("images/winter_park_logo.png", WINTER_PARK_LOGO_ASSET = "file")
load("images/wolf_creek_logo.png", WOLF_CREEK_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ASPEN_LOGO = ASPEN_LOGO_ASSET.readall()
A_BASIN_LOGO = A_BASIN_LOGO_ASSET.readall()
BEAVER_CREEK_LOGO = BEAVER_CREEK_LOGO_ASSET.readall()
BRECKENRIDGE_LOGO = BRECKENRIDGE_LOGO_ASSET.readall()
CABLE_CAR = CABLE_CAR_ASSET.readall()
COOPER_LOGO = COOPER_LOGO_ASSET.readall()
COPPER_MOUNTAIN_LOGO = COPPER_MOUNTAIN_LOGO_ASSET.readall()
CRESTED_BUTTE_LOGO = CRESTED_BUTTE_LOGO_ASSET.readall()
ECHO_MOUNTAIN_LOGO = ECHO_MOUNTAIN_LOGO_ASSET.readall()
ELDORA_LOGO = ELDORA_LOGO_ASSET.readall()
GRANDBY_RANCH_LOGO = GRANDBY_RANCH_LOGO_ASSET.readall()
HOWELSEN_HILL_LOGO = HOWELSEN_HILL_LOGO_ASSET.readall()
KEYSTONE_LOGO = KEYSTONE_LOGO_ASSET.readall()
LOVELAND_LOGO = LOVELAND_LOGO_ASSET.readall()
MONARCH_MOUNTAIN_LOGO = MONARCH_MOUNTAIN_LOGO_ASSET.readall()
POWDERHORN_LOGO = POWDERHORN_LOGO_ASSET.readall()
PURGATORY_LOGO = PURGATORY_LOGO_ASSET.readall()
SIGN_POST = SIGN_POST_ASSET.readall()
SILVERTON_LOGO = SILVERTON_LOGO_ASSET.readall()
STEAMBOAT_LOGO = STEAMBOAT_LOGO_ASSET.readall()
SUNLIGHT_LOGO = SUNLIGHT_LOGO_ASSET.readall()
TELLURIDE_LOGO = TELLURIDE_LOGO_ASSET.readall()
VAIL_LOGO = VAIL_LOGO_ASSET.readall()
WINTER_PARK_LOGO = WINTER_PARK_LOGO_ASSET.readall()
WOLF_CREEK_LOGO = WOLF_CREEK_LOGO_ASSET.readall()

TITLE = "title"
WEATHER = "weather"
CONDITIONS = "conditions"
TRAILS = "trails"

RESORTS_DATA = [
    struct(
        id = "a-basin",
        title = "Arapahoe Basin Ski Area",
        urlPath = "arapahoe-basin-ski-area",
        logo = A_BASIN_LOGO,
    ),
    struct(
        id = "aspen-snowmass",
        title = "Aspen Snowmass",
        urlPath = "aspen-snowmass",
        logo = ASPEN_LOGO,
    ),
    struct(
        id = "beaver-creek",
        title = "Beaver Creek",
        urlPath = "beaver-creek",
        logo = BEAVER_CREEK_LOGO,
    ),
    struct(
        id = "breck",
        title = "Breckenridge",
        urlPath = "breckenridge",
        logo = BRECKENRIDGE_LOGO,
    ),
    struct(
        id = "cooper",
        title = "Cooper",
        urlPath = "ski-cooper",
        logo = COOPER_LOGO,
    ),
    struct(
        id = "copper",
        title = "Copper Mountain",
        urlPath = "copper-mountain-resort",
        logo = COPPER_MOUNTAIN_LOGO,
    ),
    struct(
        id = "cb",
        title = "Crested Butte Mountain Resort",
        urlPath = "crested-butte-mountain-resort",
        logo = CRESTED_BUTTE_LOGO,
    ),
    struct(
        id = "echo",
        title = "Echo Mountain",
        urlPath = "echo-mountain",
        logo = ECHO_MOUNTAIN_LOGO,
    ),
    struct(
        id = "eldora",
        title = "Eldora Mountain Resort",
        urlPath = "eldora-mountain-resort",
        logo = ELDORA_LOGO,
    ),
    struct(
        id = "keystone",
        title = "Keystone",
        urlPath = "keystone",
        logo = KEYSTONE_LOGO,
    ),
    struct(
        id = "loveland",
        title = "Loveland",
        urlPath = "loveland",
        logo = LOVELAND_LOGO,
    ),
    struct(
        id = "monarch",
        title = "Monarch Mountain",
        urlPath = "monarch-mountain",
        logo = MONARCH_MOUNTAIN_LOGO,
    ),
    struct(
        id = "pwdr",
        title = "Powderhorn",
        urlPath = "powderhorn",
        logo = POWDERHORN_LOGO,
    ),
    struct(
        id = "purgatory",
        title = "Purgatory",
        urlPath = "durango-mountain-resort",
        logo = PURGATORY_LOGO,
    ),
    struct(
        id = "gr",
        title = "Ski Granby Ranch",
        urlPath = "ski-granby-ranch",
        logo = GRANDBY_RANCH_LOGO,
    ),
    struct(
        id = "steamboat",
        title = "Steamboat",
        urlPath = "steamboat",
        logo = STEAMBOAT_LOGO,
    ),
    struct(
        id = "sun",
        title = "Sunlight Mountain Resort",
        urlPath = "sunlight-mountain-resort",
        logo = SUNLIGHT_LOGO,
    ),
    struct(
        id = "telluride",
        title = "Telluride",
        urlPath = "telluride",
        logo = TELLURIDE_LOGO,
    ),
    struct(
        id = "vail",
        title = "Vail",
        urlPath = "vail",
        logo = VAIL_LOGO,
    ),
    struct(
        id = "wp",
        title = "Winter Park",
        urlPath = "winter-park-resort",
        logo = WINTER_PARK_LOGO,
    ),
    struct(
        id = "wolf",
        title = "Wolf Creek Ski Area",
        urlPath = "wolf-creek-ski-area",
        logo = WOLF_CREEK_LOGO,
    ),
]

def get_schema():
    toggles = []
    for resort in RESORTS_DATA:
        toggles.append(
            schema.Toggle(
                id = resort.id,
                name = resort.title,
                desc = "Show: " + resort.title,
                default = True,
                icon = "gear",
            ),
        )
    return schema.Schema(
        version = "1",
        fields = toggles,
    )

def main(config):
    displays = [TITLE, WEATHER, CONDITIONS, TRAILS]
    screens = []
    for resort in RESORTS_DATA:
        if config.bool(resort.id):
            for display in displays:
                screens.append(build_screen(resort, display))

    return render.Root(
        delay = 5000,
        show_full_animation = True,
        child = render.Box(
            child = render.Animation(
                children = screens,
            ),
        ),
    )

def build_screen(resort, display):
    data = get_data(resort.urlPath)
    isOpen = is_open(data)
    logoBox = build_logo_box(resort)

    if display == WEATHER:
        return render.Row(
            expanded = True,
            main_align = "start",
            children = [
                logoBox,
                build_weather_screen(data),
            ],
        )
    elif display == CONDITIONS:
        return render.Row(
            expanded = True,
            main_align = "start",
            children = [
                logoBox,
                build_conditions_screen(data, isOpen),
            ],
        )
    elif display == TRAILS:
        return render.Row(
            expanded = True,
            main_align = "start",
            children = [
                logoBox,
                build_trails_screen(data, isOpen),
            ],
        )
    elif display == TITLE:
        return render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                logoBox,
                build_title_screen(resort),
            ],
        )

    fail("Error loading screen")

def build_logo_box(resort):
    return render.Image(
        src = resort.logo,
        height = 16,
        width = 16,
    )

def build_title_screen(resort):
    return render.WrappedText(
        content = resort.title,
        font = "tom-thumb",
        align = "center",
    )

def build_weather_screen(data):
    temperature = data.find(".styles_h4__2Uc5w").eq(1).text()

    # print(temperature)
    temperatureSplit = temperature.split(" ")

    weatherIcon = render.WrappedText(
        content = data.find(".styles_iconWeather__R1V9M").children().eq(0).attr("title"),
        font = "tom-thumb",
        align = "center",
    )

    highData = render.Text(
        content = "H:" + temperatureSplit[0] + "°",
        font = "tom-thumb",
    )

    lowData = render.Text(
        content = "L:" + temperatureSplit[2] + "°",
        font = "tom-thumb",
    )

    data = render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            weatherIcon,
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                children = [
                    highData,
                    lowData,
                ],
            ),
        ],
    )

    return data

def build_conditions_screen(data, isOpen):
    summit = "-"
    base = "-"
    if isOpen:
        summit = data.find("[title='Summit']").parent().find("figcaption").text()
        base = data.find("[title='Base']").parent().find("figcaption").text()

    baseData = render.Text(
        content = " Summit " + summit,
        font = "tom-thumb",
    )

    forecastData = render.Text(
        content = " Base " + base,
        font = "tom-thumb",
    )

    return render.Column(
        expanded = True,
        main_align = "space_around",
        cross_align = "start",
        children = [baseData, forecastData],
    )

def build_trails_screen(data, isOpen):
    trails = "-/-"
    lifts = "-/-"
    if isOpen:
        trailsSplit = data.find("[title='Runs Open']").parent().find("figcaption").text().split(" ")
        trails = trailsSplit[0] + "/" + trailsSplit[2]

        liftsSplit = data.find("[title='Lifts Open']").parent().find("figcaption").text().split(" ")
        lifts = liftsSplit[0] + "/" + liftsSplit[2]

    # print(trails)

    trailsData = render.Row(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Image(
                src = SIGN_POST,
                width = 10,
                height = 10,
            ),
            render.Text(
                content = trails,
                font = "tom-thumb",
            ),
        ],
    )

    forecastData = render.Row(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [
            render.Image(
                src = CABLE_CAR,
                width = 10,
                height = 10,
            ),
            render.Text(
                content = lifts,
                font = "tom-thumb",
            ),
        ],
    )

    return render.Column(
        expanded = True,
        main_align = "space_around",
        cross_align = "center",
        children = [trailsData, forecastData],
    )

def is_open(data):
    open = data.find(".styles_open__3MfH6")
    if open.len() == 1:
        return True
    else:
        return False

def get_data(resort):
    url = "https://www.onthesnow.com/colorado/" + resort + "/skireport"

    response = http.get(url)
    if response.status_code != 200:
        fail("Webpage down")

    return html(response.body())
