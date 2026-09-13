"""
Applet: In Season
Summary: Displays In Season Foods
Description: Displays In Season Foods for your location.
Author: Robert Ison
"""

load("images/apples.png", APPLES_ASSET = "file")
load("images/avocados.png", AVOCADOS_ASSET = "file")
load("images/beans.png", BEANS_ASSET = "file")
load("images/beets.png", BEETS_ASSET = "file")
load("images/blueberries.png", BLUEBERRIES_ASSET = "file")
load("images/broccoli.png", BROCCOLI_ASSET = "file")
load("images/brussel_sprouts.png", BRUSSEL_SPROUTS_ASSET = "file")
load("images/cabbage.png", CABBAGE_ASSET = "file")
load("images/carrots.png", CARROTS_ASSET = "file")
load("images/cauliflower.png", CAULIFLOWER_ASSET = "file")
load("images/celery.png", CELERY_ASSET = "file")
load("images/cherries.png", CHERRIES_ASSET = "file")
load("images/chilis.png", CHILIS_ASSET = "file")
load("images/clementines.png", CLEMENTINES_ASSET = "file")
load("images/corn.png", CORN_ASSET = "file")
load("images/cranberries.png", CRANBERRIES_ASSET = "file")
load("images/cucumbers.png", CUCUMBERS_ASSET = "file")
load("images/eggplant.png", EGGPLANT_ASSET = "file")
load("images/garlic.png", GARLIC_ASSET = "file")
load("images/grapefruit.png", GRAPEFRUIT_ASSET = "file")
load("images/grapes.png", GRAPES_ASSET = "file")
load("images/green_beans.png", GREEN_BEANS_ASSET = "file")
load("images/lemons.png", LEMONS_ASSET = "file")
load("images/lettuce.png", LETTUCE_ASSET = "file")
load("images/limes.png", LIMES_ASSET = "file")
load("images/mangoes_florida_.png", MANGOES_FLORIDA_ASSET = "file")
load("images/mushrooms.png", MUSHROOMS_ASSET = "file")
load("images/nectarines.png", NECTARINES_ASSET = "file")
load("images/okra.png", OKRA_ASSET = "file")
load("images/onions.png", ONIONS_ASSET = "file")
load("images/oranges.png", ORANGES_ASSET = "file")
load("images/peaches.png", PEACHES_ASSET = "file")
load("images/pears.png", PEARS_ASSET = "file")
load("images/peas.png", PEAS_ASSET = "file")
load("images/peppers.png", PEPPERS_ASSET = "file")
load("images/plums.png", PLUMS_ASSET = "file")
load("images/pomegranates.png", POMEGRANATES_ASSET = "file")
load("images/potatoes.png", POTATOES_ASSET = "file")
load("images/pumpkins.png", PUMPKINS_ASSET = "file")
load("images/radishes.png", RADISHES_ASSET = "file")
load("images/raspberries.png", RASPBERRIES_ASSET = "file")
load("images/rhubarb.png", RHUBARB_ASSET = "file")
load("images/spinach.png", SPINACH_ASSET = "file")
load("images/squash.png", SQUASH_ASSET = "file")
load("images/strawberries.png", STRAWBERRIES_ASSET = "file")
load("images/tomatoes.png", TOMATOES_ASSET = "file")
load("images/watermelon.png", WATERMELON_ASSET = "file")
load("images/zucchini.png", ZUCCHINI_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

REGION_OPTIONS = [
    schema.Option(value = "0", display = "Northwest (Wyoming, Montana, Idaho, Washington, Oregon"),
    schema.Option(value = "1", display = "Southwest (Texas, Oklahoma, New Mexico, Colorado, Utah, Nevada, California)"),
    schema.Option(value = "2", display = "Midwest (Ohio, Michigan, Indiana, Kentucky, Missouri, Kansas, Nebraska, North & South Dakota, Minnesota, Wisconsin, Iowa, Illinios)"),
    schema.Option(value = "3", display = "Southeast (West Virginia, Virginia, Carolinas, Tennessee, Arkansas, Louisiana, Mississippi, Alabama, Georgia, Florida)"),
    schema.Option(value = "4", display = "Northeast (Main, New Hampshire, Vermont, New York, Massachusetts, Connecticut, Rhode Island, New Jersey, Pennsylvania, Maryland, Deleware)"),
]

SEASON_OPTIONS = [
    schema.Option(value = "auto", display = "Automatically Select Current Season"),
    schema.Option(value = "0", display = "Spring"),
    schema.Option(value = "1", display = "Summer"),
    schema.Option(value = "2", display = "Autumn"),
    schema.Option(value = "3", display = "Winter"),
]

ICON_ROTATION_SPEED = [
    schema.Option(value = "5", display = "Fast"),
    schema.Option(value = "10", display = "Medium"),
    schema.Option(value = "20", display = "Slow"),
    schema.Option(value = "50", display = "Extremely Slow"),
]

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

# NW: [0,5,12,14,17,21,27,33,36,39,51,53,55,56,57,59],[1,2,3,0,5,8,9,10,12,13,14,15,17,18,19,21,22,24,26,27,28,29,31,33,34,36,39,40,42,44,46,47,48,49,51,53,54,55,56,57,58,59,62,63,64,65],[1,3,0,8,11,12,13,14,16,17,21,22,24,26,27,29,31,33,34,36,39,42,44,46,48,51,52,53,56,57,58,62,63,65],[8,11,12,14,17,20,21,27,33,34,39,44,51,56,58,63]
# SW: [0,2,5,6,10,12,14,15,16,17,21,22,24,26,28,29,30,32,33,34,35,36,39,40,42,43,45,47,51,53,57,58,59,62,63,65],[0,1,9,13,19,22,24,26,28,29,31,32,34,39,40,41,42,45,46,48,49,50,51,52,54,58,62,64,65],[0,1,6,10,11,14,15,17,21,22,25,28,32,33,34,36,37,39,44,48,50,51,52,53,54,57,58,60,62,63],[0,6,10,11,12,14,15,17,21,29,30,33,34,36,35,39,43,44,53,57,58,59,60,61,63]
# MW: [0,5,8,14,36,39,44,48,53,55,56,57],[1,0,5,8,9,10,11,12,13,14,15,16,17,18,22,24,26,29,31,33,34,36,39,42,45,46,47,48,49,51,52,53,54,55,56,57,58,59,62,63,64,65],[1,8,10,11,12,14,15,16,17,24,26,29,33,34,36,39,42,44,46,52,53,56,57,58,62,63,65].[39]
# SE: [5,8,9,10,12,15,21,22,24,26,30,32,36,38,41,43,45,48,49,52,56,57,58,60,62,59],[1,5,8,9,12,13,15,21,22,24,26,28,31,32,41,43,45,47,48,49,51,52,54,56,57,58,60,62,64],[1,12,21,24,31,33,34,36,41,45,48,52,56,57,58,60,62],[1,21,30,33,36,43,56,57]
# NE: [0,5,8,10,12,14,15,17,18,29,33,36,39,44,47,53,55,56,57,59],[1,0,5,8,7,9,10,11,12,13,14,15,16,17,18,21,22,24,26,27,29,31,32,33,34,36,39,40,41,42,45,46,47,48,49,51,52,53,54,55,56,57,58,59,60,62,63,64,65],[1,8,10,11,12,15,16,17,21,23,24,26,27,29,31,33,34,36,39,42,44,46,47,48,51,52,53,56,57,58,60,63],[39,44]

# 2D Array [region][season] returns list of in season items
IN_SEASON_ARRAY = [[0, 5, 12, 14, 17, 21, 27, 33, 36, 39, 51, 53, 55, 56, 57, 59], [1, 2, 3, 0, 5, 8, 9, 10, 12, 13, 14, 15, 17, 18, 19, 21, 22, 24, 26, 27, 28, 29, 31, 33, 34, 36, 39, 40, 42, 44, 46, 47, 48, 49, 51, 53, 54, 55, 56, 57, 58, 59, 62, 63, 64, 65], [1, 3, 0, 8, 11, 12, 13, 14, 16, 17, 21, 22, 24, 26, 27, 29, 31, 33, 34, 36, 39, 42, 44, 46, 48, 51, 52, 53, 56, 57, 58, 62, 63, 65], [8, 11, 12, 14, 17, 20, 21, 27, 33, 34, 39, 44, 51, 56, 58, 63]], [[0, 2, 5, 6, 10, 12, 14, 15, 16, 17, 21, 22, 24, 26, 28, 29, 30, 32, 33, 34, 35, 36, 39, 40, 42, 43, 45, 47, 51, 53, 57, 58, 59, 62, 63, 65], [0, 1, 9, 13, 19, 22, 24, 26, 28, 29, 31, 32, 34, 39, 40, 41, 42, 45, 46, 48, 49, 50, 51, 52, 54, 58, 62, 64, 65], [0, 1, 6, 10, 11, 14, 15, 17, 21, 22, 25, 28, 32, 33, 34, 36, 37, 39, 44, 48, 50, 51, 52, 53, 54, 57, 58, 60, 62, 63], [0, 6, 10, 11, 12, 14, 15, 17, 21, 29, 30, 33, 34, 36, 35, 39, 43, 44, 53, 57, 58, 59, 60, 61, 63]], [[0, 5, 8, 14, 36, 39, 44, 48, 53, 55, 56, 57], [1, 0, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 22, 24, 26, 29, 31, 33, 34, 36, 39, 42, 45, 46, 47, 48, 49, 51, 52, 53, 54, 55, 56, 57, 58, 59, 62, 63, 64, 65], [1, 8, 10, 11, 12, 14, 15, 16, 17, 24, 26, 29, 33, 34, 36, 39, 42, 44, 46, 52, 53, 56, 57, 58, 62, 63, 65], [39]], [[5, 8, 9, 10, 12, 15, 21, 22, 24, 26, 30, 32, 36, 38, 41, 43, 45, 48, 49, 52, 56, 57, 58, 60, 62, 59], [1, 5, 8, 9, 12, 13, 15, 21, 22, 24, 26, 28, 31, 32, 41, 43, 45, 47, 48, 49, 51, 52, 54, 56, 57, 58, 60, 62, 64], [1, 12, 21, 24, 31, 33, 34, 36, 41, 45, 48, 52, 56, 57, 58, 60, 62], [1, 21, 30, 33, 36, 43, 56, 57]], [[0, 5, 8, 10, 12, 14, 15, 17, 18, 29, 33, 36, 39, 44, 47, 53, 55, 56, 57, 59], [1, 0, 5, 8, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 21, 22, 24, 26, 27, 29, 31, 32, 33, 34, 36, 39, 40, 41, 42, 45, 46, 47, 48, 49, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 62, 63, 64, 65], [1, 8, 10, 11, 12, 15, 16, 17, 21, 23, 24, 26, 27, 29, 31, 33, 34, 36, 39, 42, 44, 46, 47, 48, 51, 52, 53, 56, 57, 58, 60, 63], [39, 44]]
SEASONS = ("spring", "summer", "autumn", "winter")
SEASONS_COLORS = ("#00FF00", "#FFFF00", "#FF3300", "#3399FF")
REGIONS = ("Northwest", "Southwest", "Midwest", "Southeast", "NorthEast")
ITEMS = ("arugula", "apples", "apricots", "artichokes", "arugula", "asparagus", "avocados", "beans", "beets", "blueberries", "broccoli", "brussel sprouts", "cabbage", "cantaloupes", "carrots", "cauliflower", "celery", "chard", "cherries", "chilis", "clementines", "collards", "corn", "cranberries", "cucumbers", "dates", "eggplant", "fennel", "figs", "garlic", "grapefruit", "grapes", "green beans", "kale", "leeks", "lemons", "lettuce", "limes", "mangoes (florida)", "mushrooms", "nectarines", "okra", "onions", "oranges", "parsnips", "peaches", "pears", "peas", "peppers", "plums", "pomegranates", "potatoes", "pumpkins", "radishes", "raspberries", "rhubarb", "salad greens", "spinach", "squash", "strawberries", "sweet potatoes", "tangerines", "tomatoes", "turnips", "watermelon", "zucchini")

ITEM_IMAGES = {
    "apples": APPLES_ASSET.readall(),
    "celery": CELERY_ASSET.readall(),
    "avocados": AVOCADOS_ASSET.readall(),
    "beans": BEANS_ASSET.readall(),
    "beets": BEETS_ASSET.readall(),
    "blueberries": BLUEBERRIES_ASSET.readall(),
    "broccoli": BROCCOLI_ASSET.readall(),
    "brussel sprouts": BRUSSEL_SPROUTS_ASSET.readall(),
    "cabbage": CABBAGE_ASSET.readall(),
    "carrots": CARROTS_ASSET.readall(),
    "cauliflower": CAULIFLOWER_ASSET.readall(),
    "cherries": CHERRIES_ASSET.readall(),
    "chilis": CHILIS_ASSET.readall(),
    "clementines": CLEMENTINES_ASSET.readall(),
    "corn": CORN_ASSET.readall(),
    "cranberries": CRANBERRIES_ASSET.readall(),
    "cucumbers": CUCUMBERS_ASSET.readall(),
    "eggplant": EGGPLANT_ASSET.readall(),
    "garlic": GARLIC_ASSET.readall(),
    "grapefruit": GRAPEFRUIT_ASSET.readall(),
    "grapes": GRAPES_ASSET.readall(),
    "green beans": GREEN_BEANS_ASSET.readall(),
    "lemons": LEMONS_ASSET.readall(),
    "lettuce": LETTUCE_ASSET.readall(),
    "limes": LIMES_ASSET.readall(),
    "mangoes (florida)": MANGOES_FLORIDA_ASSET.readall(),
    "mushrooms": MUSHROOMS_ASSET.readall(),
    "nectarines": NECTARINES_ASSET.readall(),
    "okra": OKRA_ASSET.readall(),
    "onions": ONIONS_ASSET.readall(),
    "oranges": ORANGES_ASSET.readall(),
    "peaches": PEACHES_ASSET.readall(),
    "pears": PEARS_ASSET.readall(),
    "peas": PEAS_ASSET.readall(),
    "peppers": PEPPERS_ASSET.readall(),
    "plums": PLUMS_ASSET.readall(),
    "pomegranates": POMEGRANATES_ASSET.readall(),
    "potatoes": POTATOES_ASSET.readall(),
    "pumpkins": PUMPKINS_ASSET.readall(),
    "radishes": RADISHES_ASSET.readall(),
    "raspberries": RASPBERRIES_ASSET.readall(),
    "rhubarb": RHUBARB_ASSET.readall(),
    "spinach": SPINACH_ASSET.readall(),
    "squash": SQUASH_ASSET.readall(),
    "strawberries": STRAWBERRIES_ASSET.readall(),
    "tomatoes": TOMATOES_ASSET.readall(),
    "watermelon": WATERMELON_ASSET.readall(),
    "zucchini": ZUCCHINI_ASSET.readall(),
}

def main(config):
    """ 
    Main routine to display in season foods

    Args:
        config: The config obejct to get user preferences
    Returns:
        main display
    """

    # Figure out what season we are in
    season_number = config.get("season") or "auto"
    if season_number == "auto":
        current_time = time.now()
        season_number = get_season(current_time)
    else:
        season_number = int(season_number)

    # What region are we in
    region = config.get("region") or REGION_OPTIONS[0].value

    # get the list of seasonal items
    display_items = "Seasonal in %s: %s." % (SEASONS[season_number], get_display_list(IN_SEASON_ARRAY[int(region)][season_number]))

    # get the coresponding images, if they exist
    images = get_display_images(IN_SEASON_ARRAY[int(region)][season_number])

    return render.Root(
        render.Column(
            children = [
                render.Row(
                    children = [
                        render.Marquee(
                            width = 48,
                            child = render.Text(REGIONS[int(region)], color = SEASONS_COLORS[season_number], font = "5x8"),
                        ),
                        get_animation_items(images, int(config.get("speed") or ICON_ROTATION_SPEED[2].value)),
                    ],
                ),
                render.Row(
                    children = [
                        render.Box(width = 1, height = 6, color = "#000000"),
                    ],
                ),
                render.Row(
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(display_items, color = "#FFF000"),
                        ),
                    ],
                ),
            ],
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_display_list(items):
    """ 
    Gets the list of in season foods in a human readable format

    Args:
        items: This list of items that are in season
    Returns:
        Easy to read display list
    """

    return_value = ""
    for i in items:
        if i == items[0]:
            return_value = ITEMS[items[0]]
        elif i == items[-1]:
            return_value = return_value + " and "
            return_value = return_value + ITEMS[i]
        else:
            return_value = return_value + ", "
            return_value = return_value + ITEMS[i]

    return return_value

def get_display_images(items):
    """ 
    Gets the images that we can display based on the in season items

    Args:
        items: The list of items that are in season
    Returns:
        An image, if it exists, for each item passed in
    """

    return_value = []
    for i in items:
        if ITEMS[i] in ITEM_IMAGES:
            return_value.append(ITEM_IMAGES[ITEMS[i]])

    return return_value

def get_animation_items(images, speed):
    """ 
    Get Animation Items

    Args:
        images: The list of images to display
        speed: An integer > 1
    Returns:
        The list of images (multiples of speed for each to slow down the interval time between images)
    """
    animation = []

    #protect against a speed of 0 which leads to a divide by zero error
    if speed < 1:
        speed = 10

    for image in images:
        for _ in range(1, speed):
            animation.append(render.Image(src = image))

    return render.Animation(
        children = animation,
    )

def get_season(date):
    """ 
    Gets the season number based on the current date

    Args:
        date: The date we want to know the season for
    Returns:
        The season number
    """

    m = date.month
    x = m % 12 // 3 + 1

    season = 0

    if x == 1:
        season = 3
    if x == 2:
        season = 0
    if x == 3:
        season = 1
    if x == 4:
        season = 2

    return season

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "What region of the USA are you in?",
                icon = "globe",
                options = REGION_OPTIONS,
                default = REGION_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "season",
                name = "Season",
                desc = "What season do you want to display?",
                icon = "calendar",
                options = SEASON_OPTIONS,
                default = SEASON_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "speed",
                name = "Icon Rotation Speed",
                desc = "How fast do you want the icons to rotate?",
                icon = "truckFast",
                options = ICON_ROTATION_SPEED,
                default = ICON_ROTATION_SPEED[3].value,
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
        ],
    )
