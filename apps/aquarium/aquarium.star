"""
Applet: Aquarium
Summary: Digital Aquarium
Description: A digital aquarium.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_16f532d4.png", IMG_16f532d4_ASSET = "file")
load("images/img_191d0d08.png", IMG_191d0d08_ASSET = "file")
load("images/img_47f9b6e4.png", IMG_47f9b6e4_ASSET = "file")
load("images/img_5c897dd8.png", IMG_5c897dd8_ASSET = "file")
load("images/img_5fc1870a.png", IMG_5fc1870a_ASSET = "file")
load("images/img_69ef2bee.png", IMG_69ef2bee_ASSET = "file")
load("images/img_76487e62.png", IMG_76487e62_ASSET = "file")
load("images/img_780a4fb2.png", IMG_780a4fb2_ASSET = "file")
load("images/img_9685f9ed.png", IMG_9685f9ed_ASSET = "file")
load("images/img_9c266b80.png", IMG_9c266b80_ASSET = "file")
load("images/img_cba93242.png", IMG_cba93242_ASSET = "file")
load("images/img_d766c3c6.png", IMG_d766c3c6_ASSET = "file")
load("images/img_e2ad0e60.png", IMG_e2ad0e60_ASSET = "file")
load("images/img_ebf2314d.png", IMG_ebf2314d_ASSET = "file")
load("images/img_f444f7ed.png", IMG_f444f7ed_ASSET = "file")
load("images/img_fdf59949.png", IMG_fdf59949_ASSET = "file")

SCREEN_WIDTH = 64
SCREEN_HEIGHT = 32

sealife = [
    {
        "direction": "left",
        "name": "Clownfish",
        "height": 15,
        "width": 27,
        "image": IMG_47f9b6e4_ASSET.readall(),
    },
    {
        "direction": "left",
        "name": "AnglerFish",
        "height": 12,
        "width": 22,
        "image": IMG_ebf2314d_ASSET.readall(),
    },
    {
        "direction": "right",
        "name": "Blue Tang",
        "height": 14,
        "width": 25,
        "image": IMG_d766c3c6_ASSET.readall(),
    },
    {
        "direction": "right",
        "name": "Lionfish",
        "height": 14,
        "width": 25,
        "image": IMG_16f532d4_ASSET.readall(),
    },
    {
        "direction": "left",
        "name": "Shark",
        "height": 11,
        "width": 29,
        "image": IMG_e2ad0e60_ASSET.readall(),
    },
    {
        "direction": "right",
        "name": "Blowfish",
        "height": 16,
        "width": 25,
        "image": IMG_76487e62_ASSET.readall(),
    },
    {
        "direction": "right",
        "name": "Cuttlefish",
        "height": 14,
        "width": 30,
        "image": IMG_f444f7ed_ASSET.readall(),
    },
    {
        "direction": "right",
        "name": "Diver",
        "height": 15,
        "width": 25,
        "image": IMG_5fc1870a_ASSET.readall(),
    },
]

ocean_floor = [
    {
        "name": "Brain",
        "height": 12,
        "width": 20,
        "image": IMG_69ef2bee_ASSET.readall(),
    },
    {
        "name": "Finger",
        "height": 15,
        "width": 17,
        "image": IMG_9c266b80_ASSET.readall(),
    },
    {
        "name": "Tubes",
        "height": 18,
        "width": 17,
        "image": IMG_fdf59949_ASSET.readall(),
    },
    {
        "name": "shipwreck",
        "height": 20,
        "width": 25,
        "image": IMG_9685f9ed_ASSET.readall(),
    },
    {
        "name": "helmet",
        "height": 17,
        "width": 15,
        "image": IMG_191d0d08_ASSET.readall(),
    },
    {
        "name": "anchor",
        "height": 12,
        "width": 12,
        "image": IMG_5c897dd8_ASSET.readall(),
    },
    {
        "name": "crab",
        "height": 12,
        "width": 25,
        "image": IMG_cba93242_ASSET.readall(),
    },
    {
        "name": "treasure",
        "height": 16,
        "width": 22,
        "image": IMG_780a4fb2_ASSET.readall(),
    },
]

water = [
    {
        "name": "Aqua",
        "html": "#54cee3",
    },
    {
        "name": "Deep Sky Blue",
        "html": "#00BFFF",
    },
    {
        "name": "Aquamarine",
        "html": "#7fffd4",
    },
    {
        "name": "Light Blue",
        "html": "#ADD8E6",
    },
    {
        "name": "Very Dark Blue",
        "html": "#08056d",
    },
    {
        "name": "Dark Turquoise",
        "html": "#00ced1",
    },
    {
        "name": "Turquoise",
        "html": "#40E0D0",
    },
]

def main(config):
    water_color = config.str("color", "")

    return render.Root(
        get_frames(water_color),
        show_full_animation = True,
        delay = 120,
    )

def get_frames(water_color):
    sand_color = "#C2B280"
    random_sealife = sorted(sealife, key = lambda x: random.number(0, 10))
    random_ocean_floor = sorted(ocean_floor, key = lambda x: random.number(0, 10))

    if water_color == "Random" or water_color == "":
        water_color = water[random.number(0, len(water) - 1)]["html"]

    number_of_fish_to_display = min(3, len(random_sealife))
    widest_fish_length = max(random_sealife, key = lambda x: x["width"])["width"]

    first_offset = random.number(0, 32 - random_ocean_floor[0]["width"])
    second_offset = random.number(32, 64 - random_ocean_floor[1]["width"])
    third_offset = random.number(0, 64 - random_ocean_floor[2]["width"])

    # store each frame of the animation in this list of frame
    frames = []

    for i in range(SCREEN_WIDTH + (widest_fish_length * 2)):
        children = []

        #water
        children.append(render.Box(color = water_color, width = SCREEN_WIDTH, height = SCREEN_HEIGHT))

        #base sand layer -
        children.append(add_padding_to_child_element(render.Box(color = sand_color, width = SCREEN_WIDTH, height = 1), 0, SCREEN_HEIGHT - 2))
        children.append(add_padding_to_child_element(render.Image(src = base64.decode(random_ocean_floor[1]["image"])), second_offset, SCREEN_HEIGHT - random_ocean_floor[1]["height"]))

        for f in range(number_of_fish_to_display):
            children.append(get_fish_frame(random_sealife[f], i, f))

        children.append(add_padding_to_child_element(render.Image(src = base64.decode(random_ocean_floor[0]["image"])), first_offset, SCREEN_HEIGHT - random_ocean_floor[0]["height"]))
        children.append(add_padding_to_child_element(render.Image(src = base64.decode(random_ocean_floor[2]["image"])), third_offset, SCREEN_HEIGHT - random_ocean_floor[2]["height"]))

        #base sand layer
        children.append(add_padding_to_child_element(render.Box(color = sand_color, width = SCREEN_WIDTH, height = 1), 0, SCREEN_HEIGHT - 1))

        frame = render.Stack(
            children = children,
        )

        frames.append(frame)

    return render.Animation(
        children = [frame for frame in frames],
    )

def get_fish_frame(fish, frame, fish_number):
    increment = 1 if fish_number == 1 else 2
    left_offset = -fish["width"] - (10 * fish_number) * fish_number + (frame * increment) if fish["direction"] == "right" else SCREEN_WIDTH - (frame * increment)
    top_offset = fish_number * 9 - 2
    return add_padding_to_child_element(render.Image(src = base64.decode(fish["image"]), width = fish["width"] + random.number(0, 1), height = fish["height"]), left_offset, top_offset)

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_color_options(colors):
    colors = sorted(colors, key = lambda x: x["name"])

    color_options = [
        schema.Option(
            display = color["name"],
            value = color["html"],
        )
        for color in colors
    ]

    color_options.append(
        schema.Option(
            display = "Random",
            value = "Random",
        ),
    )

    return color_options

def get_schema():
    color_options = get_color_options(water)

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "color",
                name = "Water Color",
                desc = "What Water Color do you prefer?",
                icon = "water",  #"palette","paintbrush"
                options = color_options,
                default = color_options[len(color_options) - 1].value,
            ),
        ],
    )
