"""
Applet: Fine Art
Summary: Paintings and Fine Art
Description: The masterpieces of van Gogh, Picasso, Monet, and more.
Author: chrisbateman
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_00a35da2.png", IMG_00a35da2_ASSET = "file")
load("images/img_0d5e880e.png", IMG_0d5e880e_ASSET = "file")
load("images/img_1240b1c4.png", IMG_1240b1c4_ASSET = "file")
load("images/img_12a7913b.png", IMG_12a7913b_ASSET = "file")
load("images/img_152bd3b5.png", IMG_152bd3b5_ASSET = "file")
load("images/img_163522bf.png", IMG_163522bf_ASSET = "file")
load("images/img_1792a021.png", IMG_1792a021_ASSET = "file")
load("images/img_18f11b42.png", IMG_18f11b42_ASSET = "file")
load("images/img_1f5209b5.png", IMG_1f5209b5_ASSET = "file")
load("images/img_26896799.png", IMG_26896799_ASSET = "file")
load("images/img_2ff5ee48.png", IMG_2ff5ee48_ASSET = "file")
load("images/img_36617945.png", IMG_36617945_ASSET = "file")
load("images/img_369dfb45.png", IMG_369dfb45_ASSET = "file")
load("images/img_3f0ab317.png", IMG_3f0ab317_ASSET = "file")
load("images/img_4225c180.png", IMG_4225c180_ASSET = "file")
load("images/img_4560f18d.png", IMG_4560f18d_ASSET = "file")
load("images/img_504ec14c.png", IMG_504ec14c_ASSET = "file")
load("images/img_50f623e9.png", IMG_50f623e9_ASSET = "file")
load("images/img_5391317f.png", IMG_5391317f_ASSET = "file")
load("images/img_54346127.png", IMG_54346127_ASSET = "file")
load("images/img_56034ddc.png", IMG_56034ddc_ASSET = "file")
load("images/img_5a3c7cb3.png", IMG_5a3c7cb3_ASSET = "file")
load("images/img_5de0ca14.png", IMG_5de0ca14_ASSET = "file")
load("images/img_61e0995f.png", IMG_61e0995f_ASSET = "file")
load("images/img_6be01cd4.png", IMG_6be01cd4_ASSET = "file")
load("images/img_6c92c318.png", IMG_6c92c318_ASSET = "file")
load("images/img_6d295450.png", IMG_6d295450_ASSET = "file")
load("images/img_6f9a307c.png", IMG_6f9a307c_ASSET = "file")
load("images/img_7003c2e6.png", IMG_7003c2e6_ASSET = "file")
load("images/img_77ab95d3.png", IMG_77ab95d3_ASSET = "file")
load("images/img_77b6a4ac.png", IMG_77b6a4ac_ASSET = "file")
load("images/img_876ac107.png", IMG_876ac107_ASSET = "file")
load("images/img_88e59d7d.png", IMG_88e59d7d_ASSET = "file")
load("images/img_8d49e82f.png", IMG_8d49e82f_ASSET = "file")
load("images/img_8eb89aac.png", IMG_8eb89aac_ASSET = "file")
load("images/img_93a0c7b9.png", IMG_93a0c7b9_ASSET = "file")
load("images/img_995d643a.png", IMG_995d643a_ASSET = "file")
load("images/img_9aed94a0.png", IMG_9aed94a0_ASSET = "file")
load("images/img_9b10b075.png", IMG_9b10b075_ASSET = "file")
load("images/img_9b788bee.png", IMG_9b788bee_ASSET = "file")
load("images/img_9ebe4b20.png", IMG_9ebe4b20_ASSET = "file")
load("images/img_a16e7928.png", IMG_a16e7928_ASSET = "file")
load("images/img_ada5e127.png", IMG_ada5e127_ASSET = "file")
load("images/img_b264695a.png", IMG_b264695a_ASSET = "file")
load("images/img_b30e3d6b.png", IMG_b30e3d6b_ASSET = "file")
load("images/img_c28b99bb.png", IMG_c28b99bb_ASSET = "file")
load("images/img_c3d7ddc4.png", IMG_c3d7ddc4_ASSET = "file")
load("images/img_c7ee47ef.png", IMG_c7ee47ef_ASSET = "file")
load("images/img_c81a6222.png", IMG_c81a6222_ASSET = "file")
load("images/img_cb65947e.png", IMG_cb65947e_ASSET = "file")
load("images/img_ccd17f21.png", IMG_ccd17f21_ASSET = "file")
load("images/img_d90a1dae.png", IMG_d90a1dae_ASSET = "file")
load("images/img_db650a4c.png", IMG_db650a4c_ASSET = "file")
load("images/img_dbfaced6.png", IMG_dbfaced6_ASSET = "file")
load("images/img_e0a88ed8.png", IMG_e0a88ed8_ASSET = "file")
load("images/img_e21a283b.png", IMG_e21a283b_ASSET = "file")
load("images/img_e30960f6.png", IMG_e30960f6_ASSET = "file")
load("images/img_e3216a4c.png", IMG_e3216a4c_ASSET = "file")
load("images/img_e53d4b70.png", IMG_e53d4b70_ASSET = "file")
load("images/img_e9393714.png", IMG_e9393714_ASSET = "file")
load("images/img_e9a168be.png", IMG_e9a168be_ASSET = "file")
load("images/img_e9b19f43.png", IMG_e9b19f43_ASSET = "file")
load("images/img_ec21cc39.png", IMG_ec21cc39_ASSET = "file")
load("images/img_f05195df.png", IMG_f05195df_ASSET = "file")
load("images/img_f6174c7f.png", IMG_f6174c7f_ASSET = "file")
load("images/img_f90836f8.png", IMG_f90836f8_ASSET = "file")

MS_PER_FRAME = 32
FRAMES_PER_SECOND = 1000 / MS_PER_FRAME
MAX_APP_TIME = 15
MARQUEE_OFFSET_START = 10
MARQUEE_OFFSET_END = 10
PAN_SPEED = 12

def main(config):
    caption = config.bool("caption", False)
    rotate_daily = config.bool("rotate_daily", True)
    configIndex = config.str("index")

    # Tidbyt animates slower than pixlet serve does
    dev = config.bool("dev", False)
    set_prod_adjust_ratio(1 if dev else 0.44)
    frame_delay = math.round(MS_PER_FRAME * get_prod_adjust_ratio())

    if rotate_daily:
        # rotate at 2am
        timezone = time.tz()
        now = time.now().in_location(timezone)
        two_hours_back = time.from_timestamp(now.unix - (2 * 60 * 60)).in_location(timezone)
        start_of_day_utc = time.time(year = two_hours_back.year, month = two_hours_back.month, day = two_hours_back.day, hour = 0, minute = 0, second = 0)
        unix_day = int(math.round(start_of_day_utc.unix / 60 / 60 / 24))

        index = unix_day % len(PAINTINGS)
    else:
        index = random.number(0, len(PAINTINGS) - 1)

    # for dev
    if configIndex:
        index = int(configIndex)

    painting = PAINTINGS[index]

    transform_start, transform_final, padding_final = get_transforms(painting)

    image = render.Image(src = painting["binary"])
    finalFrame = render.Padding(
        child = image,
        pad = padding_final,
    )

    pan_animation, pan_time = get_simple_pan(image, transform_start, transform_final)

    if caption:
        title = painting["title"] + " - " + painting["artistLast"]
        caption_animation, caption_time = get_caption(title)

        animations = [
            pan_animation,
            render.Stack(
                children = [
                    finalFrame,
                    caption_animation,
                ],
            ),
            get_still_frames(finalFrame, MAX_APP_TIME - pan_time - caption_time + 1),
        ]
    else:
        animations = [
            pan_animation,
            get_still_frames(finalFrame, MAX_APP_TIME - pan_time + 1),
        ]

    return render.Root(
        delay = int(frame_delay),
        child = render.Sequence(children = animations),
    )

####

def set_prod_adjust_ratio(val):
    # Using cache as a mutable global
    cache.set("PROD_ADJUST_RATIO", str(val))

def get_prod_adjust_ratio():
    return float(cache.get("PROD_ADJUST_RATIO"))

def get_caption(text):
    # 4 pixels/character for monospaced tom-thumb
    text_length = len(text) * 4

    pos_start = 64 - MARQUEE_OFFSET_START
    pos_end = -text_length + MARQUEE_OFFSET_END
    distance = pos_start - pos_end
    duration = int(distance / 1.75)
    pos_increment = distance / duration

    if (text_length < 65):
        pos_start = 0
        pos_increment = 0
        duration = 220

    frames = []

    for i in range(duration):
        pos = pos_start - int(math.round(pos_increment * i))

        opacity_percent = get_fade_opacity(i, duration)
        box_opacity = to_hex(opacity_percent * 0.5 * 255)
        text_opacity = to_hex(opacity_percent * 255)

        frames.append(
            render.Padding(
                child = render.Stack(children = [
                    render.Box(
                        width = 64,
                        height = 6,
                        color = "000000%s" % box_opacity,
                    ),
                    render.Padding(
                        child = render.Text(text, font = "tom-thumb", color = "#ffffff%s" % text_opacity),
                        pad = (pos, 0, 0, 0),
                    ),
                ]),
                pad = (0, 32 - 6, 0, 0),
            ),
        )

    return render.Animation(children = frames), duration / FRAMES_PER_SECOND

def get_fade_opacity(i, duration):
    if i < 10:
        return i * 0.1
    elif i > duration - 10:
        return (duration - i) * 0.1
    else:
        return 1

def to_hex(i):
    hex = "%x" % i

    if len(hex) == 1:
        hex = "0" + hex

    return hex

def get_still_frames(child, seconds):
    frame_count = get_frame_count_still(seconds)

    return render.Animation(
        children = [child for x in range(frame_count)],
    )

def get_transforms(painting):
    framing_offset = -abs(painting.get("framing")) if "framing" in painting else 0

    if painting["height"] > 32:
        transform_start = get_start_transform(painting, framing_offset, "vertical")
        transform_final = animation.Translate(0, framing_offset)
        final_framing = (0, framing_offset, 0, 0)
    elif painting["width"] > 64:
        transform_start = get_start_transform(painting, framing_offset, "horizontal")
        transform_final = animation.Translate(framing_offset, 0)
        final_framing = (framing_offset, 0, 0, 0)
    else:
        transform_start = animation.Translate(0, 0)
        transform_final = animation.Translate(0, 0)
        final_framing = (0, 0, 0, 0)

    return transform_start, transform_final, final_framing

def get_start_transform(painting, framing_offset, orientation):
    if orientation == "vertical":
        center = abs(framing_offset) + (32 / 2)

        if center / painting["height"] > 0.5:
            return animation.Translate(0, 0)
        else:
            return animation.Translate(0, -abs(painting["height"] - 32))
    else:
        center = abs(framing_offset) + (64 / 2)

        if center / painting["width"] > 0.5:
            return animation.Translate(0, 0)
        else:
            return animation.Translate(-abs(painting["width"] - 64), 0)

def get_simple_pan(child, transform_start, transform_final):
    delay_seconds = 0.25
    pan_distance = abs((transform_start.x or transform_start.y) - (transform_final.x or transform_final.y))
    pan_time = max(3, pan_distance / PAN_SPEED)

    return animation.Transformation(
        child = child,
        duration = get_frame_count(pan_time),
        delay = get_frame_count_still(delay_seconds),
        keyframes = [
            animation.Keyframe(
                percentage = 0,
                curve = "ease_in_out",
                transforms = [transform_start],
            ),
            animation.Keyframe(
                percentage = 1,
                curve = "ease_in_out",
                transforms = [transform_final],
            ),
        ],
    ), pan_time

def get_frame_count(seconds):
    return int(math.round(seconds * FRAMES_PER_SECOND))

def get_frame_count_still(seconds):
    return int(math.round(seconds * FRAMES_PER_SECOND / get_prod_adjust_ratio()))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "caption",
                name = "Show caption",
                desc = "Show title and artist",
                icon = "tag",
                default = True,
            ),
            schema.Toggle(
                id = "rotate_daily",
                name = "Rotate daily",
                desc = "Rotate paintings daily, instead of constantly",
                icon = "calendarDay",
                default = True,
            ),
        ],
    )

PAINTINGS = [
    {
        "binary": IMG_9aed94a0_ASSET.readall(),
        "title": "Starry Night",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 51,
        "framing": 8,
    },
    {
        "binary": IMG_8eb89aac_ASSET.readall(),
        "title": "Composition with Red Blue and Yellow",
        "artistFirst": "Piet",
        "artistLast": "Mondrian",
        "width": 64,
        "height": 64,
        "framing": 32,
    },
    {
        "binary": IMG_4225c180_ASSET.readall(),
        "title": "A Sunday Afternoon on the Island of La Grande Jatte",
        "artistFirst": "Georges",
        "artistLast": "Seurat",
        "width": 64,
        "height": 43,
        "framing": 4,
    },
    {
        "binary": IMG_9b788bee_ASSET.readall(),
        "title": "The Scream",
        "artistFirst": "Edvard",
        "artistLast": "Munch",
        "width": 64,
        "height": 79,
        "framing": 28,
    },
    {
        "binary": IMG_d90a1dae_ASSET.readall(),
        "title": "The Third of May 1808",
        "artistFirst": "Francisco ",
        "artistLast": "Goya",
        "width": 64,
        "height": 49,
        "framing": 14,
    },
    {
        "binary": IMG_1240b1c4_ASSET.readall(),
        "title": "The School of Athens",
        "artistFirst": "",
        "artistLast": "Raphael",
        "width": 64,
        "height": 46,
        "framing": 11,
    },
    {
        "binary": IMG_3f0ab317_ASSET.readall(),
        "title": "Dance at Le moulin de la Galette",
        "artistFirst": "Pierre-Auguste",
        "artistLast": "Renoir",
        "width": 64,
        "height": 48,
        "framing": 10,
    },
    {
        "binary": IMG_e21a283b_ASSET.readall(),
        "title": "Self-Portrait (1889)",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 77,
        "framing": 16,
    },
    {
        "binary": IMG_7003c2e6_ASSET.readall(),
        "title": "American Gothic",
        "artistFirst": "Grant",
        "artistLast": "Wood",
        "width": 64,
        "height": 77,
        "framing": 10,
    },
    {
        "binary": IMG_a16e7928_ASSET.readall(),
        "title": "Three Musicians",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 58,
        "framing": 4,
    },
    {
        "binary": IMG_9b10b075_ASSET.readall(),
        "title": "The Persistence of Memory",
        "artistFirst": "Salvador",
        "artistLast": "Dali",
        "width": 64,
        "height": 47,
        "framing": 9,
    },
    {
        "binary": IMG_163522bf_ASSET.readall(),
        "title": "Impression, Sunrise",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 50,
        "framing": 9,
    },
    {
        "binary": IMG_8d49e82f_ASSET.readall(),
        "title": "Nighthawks",
        "artistFirst": "Edward",
        "artistLast": "Hopper",
        "width": 64,
        "height": 32,
    },
    {
        "binary": IMG_6f9a307c_ASSET.readall(),
        "title": "Liberty Leading the People",
        "artistFirst": "Eugène",
        "artistLast": "Delacroix",
        "width": 64,
        "height": 51,
        "framing": 0,
    },
    {
        "binary": IMG_2ff5ee48_ASSET.readall(),
        "title": "Arnolfini Portrait",
        "artistFirst": "Jan",
        "artistLast": "van Eyck",
        "width": 64,
        "height": 88,
        "framing": 12,
    },
    {
        "binary": IMG_f05195df_ASSET.readall(),
        "title": "Café Terrace at Night",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 80,
        "framing": 35,
    },
    {
        "binary": IMG_cb65947e_ASSET.readall(),
        "title": "Untitled (1982)",
        "artistFirst": "Jean-Michel",
        "artistLast": "Basquiat",
        "width": 64,
        "height": 68,
        "framing": 18,
    },
    {
        "binary": IMG_9ebe4b20_ASSET.readall(),
        "title": "Whistler's Mother",
        "artistFirst": "James",
        "artistLast": "Whistler",
        "width": 64,
        "height": 57,
        "framing": 6,
    },
    {
        "binary": IMG_152bd3b5_ASSET.readall(),
        "title": "The Son of Man",
        "artistFirst": "René",
        "artistLast": "Magritte",
        "width": 64,
        "height": 90,
        "framing": 9,
    },
    {
        "binary": IMG_e9393714_ASSET.readall(),
        "title": "The Night Watch",
        "artistFirst": "",
        "artistLast": "Rembrandt",
        "width": 64,
        "height": 53,
        "framing": 20,
    },
    {
        "binary": IMG_c81a6222_ASSET.readall(),
        "title": "Les Demoiselles d'Avignon",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 66,
        "framing": 5,
    },
    {
        "binary": IMG_6c92c318_ASSET.readall(),
        "title": "Las Meninas",
        "artistFirst": "Diego",
        "artistLast": "Velázquez",
        "width": 64,
        "height": 74,
        "framing": 38,
    },
    {
        "binary": IMG_56034ddc_ASSET.readall(),
        "title": "Transverse Line",
        "artistFirst": "Wassily",
        "artistLast": "Kandinsky",
        "width": 64,
        "height": 44,
        "framing": 8,
    },
    {
        "binary": IMG_e9a168be_ASSET.readall(),
        "title": "Wanderer above the Sea of Fog",
        "artistFirst": "Caspar",
        "artistLast": "Friedrich",
        "width": 64,
        "height": 82,
        "framing": 25,
    },
    {
        "binary": IMG_504ec14c_ASSET.readall(),
        "title": "Starry Night Over the Rhône",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 4,
    },
    {
        "binary": IMG_995d643a_ASSET.readall(),
        "title": "San Giorgio Maggiore at Dusk",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 45,
        "framing": 0,
    },
    {
        "binary": IMG_88e59d7d_ASSET.readall(),
        "title": "The Milkmaid",
        "artistFirst": "Johannes",
        "artistLast": "Vermeer",
        "width": 64,
        "height": 72,
        "framing": 13,
    },
    {
        "binary": IMG_c28b99bb_ASSET.readall(),
        "title": "The Great Wave off Kanagawa",
        "artistFirst": "Katsushika",
        "artistLast": "Hokusai",
        "width": 64,
        "height": 43,
        "framing": 5,
    },
    {
        "binary": IMG_1f5209b5_ASSET.readall(),
        "title": "The Birth of Venus",
        "artistFirst": "Sandro",
        "artistLast": "Botticelli",
        "width": 64,
        "height": 40,
        "framing": 2,
    },
    {
        "binary": IMG_e53d4b70_ASSET.readall(),
        "title": "The Last Supper",
        "artistFirst": "Leonardo",
        "artistLast": "da Vinci",
        "width": 64,
        "height": 32,
    },
    {
        "binary": IMG_0d5e880e_ASSET.readall(),
        "title": "The Flower Carrier",
        "artistFirst": "Diego",
        "artistLast": "Rivera",
        "width": 64,
        "height": 64,
        "framing": 9,
    },
    {
        "binary": IMG_00a35da2_ASSET.readall(),
        "title": "Guernica",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 70,
        "height": 32,
        "framing": 0,
    },
    {
        "binary": IMG_c7ee47ef_ASSET.readall(),
        "title": "Wheat Field with Cypresses",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 10,
    },
    {
        "binary": IMG_369dfb45_ASSET.readall(),
        "title": "Untitled",
        "artistFirst": "Jackson",
        "artistLast": "Pollock",
        "width": 64,
        "height": 46,
    },
    {
        "binary": IMG_50f623e9_ASSET.readall(),
        "title": "The Kiss",
        "artistFirst": "Gustav",
        "artistLast": "Klimt",
        "width": 64,
        "height": 64,
        "framing": 0,
    },
    {
        "binary": IMG_f6174c7f_ASSET.readall(),
        "title": "The Creation of Adam",
        "artistFirst": "",
        "artistLast": "Michelangelo",
        "width": 64,
        "height": 32,
    },
    {
        "binary": IMG_e30960f6_ASSET.readall(),
        "title": "Woman with a Parasol",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 79,
        "framing": 28,
    },
    {
        "binary": IMG_61e0995f_ASSET.readall(),
        "title": "Portrait of Dora Maar",
        "artistFirst": "Pablo",
        "artistLast": "Picasso",
        "width": 64,
        "height": 89,
        "framing": 10,
    },
    {
        "binary": IMG_b30e3d6b_ASSET.readall(),
        "title": "The Two Fridas",
        "artistFirst": "Frida",
        "artistLast": "Kahlo",
        "width": 64,
        "height": 64,
        "framing": 3,
    },
    {
        "binary": IMG_ec21cc39_ASSET.readall(),
        "title": "The Red Vineyard",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 50,
        "framing": 0,
    },
    {
        "binary": IMG_e9b19f43_ASSET.readall(),
        "title": "Girl with a Pearl Earring",
        "artistFirst": "Johannes",
        "artistLast": "Vermeer",
        "width": 64,
        "height": 76,
        "framing": 18,
    },
    {
        "binary": IMG_36617945_ASSET.readall(),
        "title": "A Bar at the Folies-Bergère",
        "artistFirst": "Édouard",
        "artistLast": "Manet",
        "width": 64,
        "height": 47,
        "framing": 2,
    },
    {
        "binary": IMG_26896799_ASSET.readall(),
        "title": "The Gleaners",
        "artistFirst": "Jean-François",
        "artistLast": "Millet",
        "width": 64,
        "height": 48,
        "framing": 11,
    },
    {
        "binary": IMG_12a7913b_ASSET.readall(),
        "title": "In a Roman Osteria",
        "artistFirst": "Carl",
        "artistLast": "Bloch",
        "width": 64,
        "height": 51,
        "framing": 9,
    },
    {
        "binary": IMG_18f11b42_ASSET.readall(),
        "title": "The Fighting Temeraire",
        "artistFirst": "J. M. W.",
        "artistLast": "Turner",
        "width": 64,
        "height": 48,
        "framing": 16,
    },
    {
        "binary": IMG_ada5e127_ASSET.readall(),
        "title": "Mont Sainte-Victoire",
        "artistFirst": "Paul",
        "artistLast": "Cézanne",
        "width": 64,
        "height": 42,
        "framing": 4,
    },
    {
        "binary": IMG_dbfaced6_ASSET.readall(),
        "title": "Water Lilies",
        "artistFirst": "Claude",
        "artistLast": "Monet",
        "width": 64,
        "height": 32,
    },
    {
        "binary": IMG_5de0ca14_ASSET.readall(),
        "title": "Wheatfield with Crows",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 32,
    },
    {
        "binary": IMG_77ab95d3_ASSET.readall(),
        "title": "The Blue Rider",
        "artistFirst": "Wassily",
        "artistLast": "Kandinsky",
        "width": 64,
        "height": 60,
        "framing": 15,
    },
    {
        "binary": IMG_5a3c7cb3_ASSET.readall(),
        "title": "The Garden of Earthly Delights",
        "artistFirst": "Hieronymus",
        "artistLast": "Bosch",
        "width": 64,
        "height": 32,
    },
    {
        "binary": IMG_4560f18d_ASSET.readall(),
        "title": "Luncheon of the Boating Party",
        "artistFirst": "Pierre-Auguste",
        "artistLast": "Renoir",
        "width": 64,
        "height": 47,
        "framing": 3,
    },
    {
        "binary": IMG_6be01cd4_ASSET.readall(),
        "title": "The Absinthe Drinker",
        "artistFirst": "Edgar",
        "artistLast": "Degas",
        "width": 64,
        "height": 88,
        "framing": 10,
    },
    {
        "binary": IMG_93a0c7b9_ASSET.readall(),
        "title": "Mona Lisa",
        "artistFirst": "Leonardo",
        "artistLast": "da Vinci",
        "width": 64,
        "height": 95,
        "framing": 10,
    },
    {
        "binary": IMG_876ac107_ASSET.readall(),
        "title": "The Execution of Lady Jane Grey",
        "artistFirst": "Paul",
        "artistLast": "Delaroche",
        "width": 64,
        "height": 53,
        "framing": 13,
    },
    {
        "binary": IMG_1792a021_ASSET.readall(),
        "title": "The Banjo Lesson",
        "artistFirst": "Henry Ossawa",
        "artistLast": "Tanner",
        "width": 64,
        "height": 91,
        "framing": 15,
    },
    {
        "binary": IMG_54346127_ASSET.readall(),
        "title": "The Hay Wain",
        "artistFirst": "John",
        "artistLast": "Constable",
        "width": 64,
        "height": 44,
        "framing": 10,
    },
    {
        "binary": IMG_77b6a4ac_ASSET.readall(),
        "title": "Washington Crossing the Delaware",
        "artistFirst": "Emanuel",
        "artistLast": "Leutze",
        "width": 64,
        "height": 32,
        "framing": 4,
    },
    {
        "binary": IMG_e3216a4c_ASSET.readall(),
        "title": "Stańczyk",
        "artistFirst": "Jan",
        "artistLast": "Matejko",
        "width": 64,
        "height": 47,
        "framing": 8,
    },
    {
        "binary": IMG_5391317f_ASSET.readall(),
        "title": "Christina's World",
        "artistFirst": "Andrew",
        "artistLast": "Wyeth",
        "width": 64,
        "height": 43,
        "framing": 4,
    },
    {
        "binary": IMG_e0a88ed8_ASSET.readall(),
        "title": "The Night Café",
        "artistFirst": "Vincent",
        "artistLast": "van Gogh",
        "width": 64,
        "height": 51,
        "framing": 5,
    },
    {
        "binary": IMG_db650a4c_ASSET.readall(),
        "title": "The Jungle",
        "artistFirst": "Wilfredo",
        "artistLast": "Lam",
        "width": 64,
        "height": 67,
        "framing": 10,
    },
    {
        "binary": IMG_f90836f8_ASSET.readall(),
        "title": "The Anatomy Lesson of Dr. Nicolaes Tulp",
        "artistFirst": "",
        "artistLast": "Rembrandt",
        "width": 64,
        "height": 48,
        "framing": 7,
    },
    {
        "binary": IMG_c3d7ddc4_ASSET.readall(),
        "title": "The Death of Marat",
        "artistFirst": "Jacques-Louis",
        "artistLast": "David",
        "width": 64,
        "height": 51,
        "framing": 0,
    },
    {
        "binary": IMG_ccd17f21_ASSET.readall(),
        "title": "Judith Slaying Holofernes",
        "artistFirst": "Artemisia",
        "artistLast": "Gentileschi",
        "width": 64,
        "height": 78,
        "framing": 25,
    },
    {
        "binary": IMG_6d295450_ASSET.readall(),
        "title": "Flaming June",
        "artistFirst": "Frederic",
        "artistLast": "Leighton",
        "width": 64,
        "height": 65,
        "framing": 11,
    },
    {
        "binary": IMG_b264695a_ASSET.readall(),
        "title": "The Eclipse",
        "artistFirst": "Alma",
        "artistLast": "Thomas",
        "width": 64,
        "height": 79,
        "framing": 23,
    },
]
