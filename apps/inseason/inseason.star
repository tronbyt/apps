"""
Applet: In Season
Summary: Displays In Season Foods
Description: Displays In Season Foods for your location.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")  #Used to read encoded image
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_01bd9e5f.png", IMG_01bd9e5f_ASSET = "file")
load("images/img_063ac7cb.png", IMG_063ac7cb_ASSET = "file")
load("images/img_064a8383.png", IMG_064a8383_ASSET = "file")
load("images/img_0680f9f3.png", IMG_0680f9f3_ASSET = "file")
load("images/img_114464d7.png", IMG_114464d7_ASSET = "file")
load("images/img_17ebae2d.png", IMG_17ebae2d_ASSET = "file")
load("images/img_19df056f.png", IMG_19df056f_ASSET = "file")
load("images/img_25f49966.png", IMG_25f49966_ASSET = "file")
load("images/img_28e8ff80.png", IMG_28e8ff80_ASSET = "file")
load("images/img_2f716788.png", IMG_2f716788_ASSET = "file")
load("images/img_33dc04d0.png", IMG_33dc04d0_ASSET = "file")
load("images/img_38c5d89e.png", IMG_38c5d89e_ASSET = "file")
load("images/img_40f3e4c2.png", IMG_40f3e4c2_ASSET = "file")
load("images/img_481ee65d.png", IMG_481ee65d_ASSET = "file")
load("images/img_4967d45a.png", IMG_4967d45a_ASSET = "file")
load("images/img_499f91cb.png", IMG_499f91cb_ASSET = "file")
load("images/img_4a3d712d.png", IMG_4a3d712d_ASSET = "file")
load("images/img_4f7c9a59.png", IMG_4f7c9a59_ASSET = "file")
load("images/img_590cdc64.png", IMG_590cdc64_ASSET = "file")
load("images/img_5bf48d7f.png", IMG_5bf48d7f_ASSET = "file")
load("images/img_5bfa6d1d.png", IMG_5bfa6d1d_ASSET = "file")
load("images/img_5ece558b.png", IMG_5ece558b_ASSET = "file")
load("images/img_667f5043.png", IMG_667f5043_ASSET = "file")
load("images/img_6fee8141.png", IMG_6fee8141_ASSET = "file")
load("images/img_721734fa.png", IMG_721734fa_ASSET = "file")
load("images/img_7a1f2e08.png", IMG_7a1f2e08_ASSET = "file")
load("images/img_7abe27ed.png", IMG_7abe27ed_ASSET = "file")
load("images/img_87839352.png", IMG_87839352_ASSET = "file")
load("images/img_8b3799f4.png", IMG_8b3799f4_ASSET = "file")
load("images/img_8f4ac4da.png", IMG_8f4ac4da_ASSET = "file")
load("images/img_933a80e2.png", IMG_933a80e2_ASSET = "file")
load("images/img_969c7d43.png", IMG_969c7d43_ASSET = "file")
load("images/img_9e877618.png", IMG_9e877618_ASSET = "file")
load("images/img_9ee81ac5.png", IMG_9ee81ac5_ASSET = "file")
load("images/img_a819a760.png", IMG_a819a760_ASSET = "file")
load("images/img_ab995983.png", IMG_ab995983_ASSET = "file")
load("images/img_ae61468d.png", IMG_ae61468d_ASSET = "file")
load("images/img_bf5600be.png", IMG_bf5600be_ASSET = "file")
load("images/img_c6a4d978.png", IMG_c6a4d978_ASSET = "file")
load("images/img_cbb7179c.png", IMG_cbb7179c_ASSET = "file")
load("images/img_cf7a77a0.png", IMG_cf7a77a0_ASSET = "file")
load("images/img_e86a81d4.png", IMG_e86a81d4_ASSET = "file")
load("images/img_e9d579ad.png", IMG_e9d579ad_ASSET = "file")
load("images/img_ebe679f1.png", IMG_ebe679f1_ASSET = "file")
load("images/img_ec81005b.png", IMG_ec81005b_ASSET = "file")
load("images/img_f2cf6c1c.png", IMG_f2cf6c1c_ASSET = "file")
load("images/img_f71c9d87.png", IMG_f71c9d87_ASSET = "file")
load("images/img_fcbf5f4d.png", IMG_fcbf5f4d_ASSET = "file")

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
    "apples": IMG_5bf48d7f_ASSET.readall(),
    "celery": IMG_ae61468d_ASSET.readall(),
    "avocados": IMG_933a80e2_ASSET.readall(),
    "beans": IMG_7abe27ed_ASSET.readall(),
    "beets": IMG_19df056f_ASSET.readall(),
    "blueberries": IMG_667f5043_ASSET.readall(),
    "broccoli": IMG_17ebae2d_ASSET.readall(),
    "brussel sprouts": IMG_4a3d712d_ASSET.readall(),
    "cabbage": IMG_481ee65d_ASSET.readall(),
    "carrots": IMG_38c5d89e_ASSET.readall(),
    "cauliflower": IMG_33dc04d0_ASSET.readall(),
    "cherries": IMG_01bd9e5f_ASSET.readall(),
    "chilis": IMG_721734fa_ASSET.readall(),
    "clementines": IMG_e9d579ad_ASSET.readall(),
    "corn": IMG_25f49966_ASSET.readall(),
    "cranberries": IMG_a819a760_ASSET.readall(),
    "cucumbers": IMG_5bfa6d1d_ASSET.readall(),
    "eggplant": IMG_f2cf6c1c_ASSET.readall(),
    "garlic": IMG_cf7a77a0_ASSET.readall(),
    "grapefruit": IMG_8f4ac4da_ASSET.readall(),
    "grapes": IMG_cbb7179c_ASSET.readall(),
    "green beans": IMG_4f7c9a59_ASSET.readall(),
    "lemons": IMG_499f91cb_ASSET.readall(),
    "lettuce": IMG_e86a81d4_ASSET.readall(),
    "limes": IMG_ab995983_ASSET.readall(),
    "mangoes (florida)": IMG_8b3799f4_ASSET.readall(),
    "mushrooms": IMG_ebe679f1_ASSET.readall(),
    "nectarines": IMG_4967d45a_ASSET.readall(),
    "okra": IMG_064a8383_ASSET.readall(),
    "onions": IMG_7a1f2e08_ASSET.readall(),
    "oranges": IMG_6fee8141_ASSET.readall(),
    "peaches": IMG_ec81005b_ASSET.readall(),
    "pears": IMG_5ece558b_ASSET.readall(),
    "peas": IMG_fcbf5f4d_ASSET.readall(),
    "peppers": IMG_969c7d43_ASSET.readall(),
    "plums": IMG_9ee81ac5_ASSET.readall(),
    "pomegranates": IMG_87839352_ASSET.readall(),
    "potatoes": IMG_114464d7_ASSET.readall(),
    "pumpkins": IMG_c6a4d978_ASSET.readall(),
    "radishes": IMG_0680f9f3_ASSET.readall(),
    "raspberries": IMG_40f3e4c2_ASSET.readall(),
    "rhubarb": IMG_9e877618_ASSET.readall(),
    "spinach": IMG_f71c9d87_ASSET.readall(),
    "squash": IMG_063ac7cb_ASSET.readall(),
    "strawberries": IMG_bf5600be_ASSET.readall(),
    "tomatoes": IMG_28e8ff80_ASSET.readall(),
    "watermelon": IMG_590cdc64_ASSET.readall(),
    "zucchini": IMG_2f716788_ASSET.readall(),
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
            return_value.append(base64.decode(ITEM_IMAGES[ITEMS[i]]))

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
