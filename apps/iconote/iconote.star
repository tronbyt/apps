"""
Applet: IcoNote
Summary: Scrolling message and image
Description: Display a message with one of 75 predefined icons or your photo.
Author: J. Keybl
"""

load("encoding/base64.star", "base64")
load("images/icon_airplane.png", ICON_AIRPLANE_ASSET = "file")
load("images/icon_balloon.png", ICON_BALLOON_ASSET = "file")
load("images/icon_baseball.png", ICON_BASEBALL_ASSET = "file")
load("images/icon_basketball.png", ICON_BASKETBALL_ASSET = "file")
load("images/icon_beach_with_umbrella.png", ICON_BEACH_WITH_UMBRELLA_ASSET = "file")
load("images/icon_beer_mug.png", ICON_BEER_MUG_ASSET = "file")
load("images/icon_bicycle.png", ICON_BICYCLE_ASSET = "file")
load("images/icon_birthday_cake.png", ICON_BIRTHDAY_CAKE_ASSET = "file")
load("images/icon_bottle_with_popping_cork.png", ICON_BOTTLE_WITH_POPPING_CORK_ASSET = "file")
load("images/icon_bouquet.png", ICON_BOUQUET_ASSET = "file")
load("images/icon_camera.png", ICON_CAMERA_ASSET = "file")
load("images/icon_camping.png", ICON_CAMPING_ASSET = "file")
load("images/icon_candle.png", ICON_CANDLE_ASSET = "file")
load("images/icon_carousel_horse.png", ICON_CAROUSEL_HORSE_ASSET = "file")
load("images/icon_carp_streamer.png", ICON_CARP_STREAMER_ASSET = "file")
load("images/icon_christmas_tree.png", ICON_CHRISTMAS_TREE_ASSET = "file")
load("images/icon_clinking_glasses.png", ICON_CLINKING_GLASSES_ASSET = "file")
load("images/icon_compass.png", ICON_COMPASS_ASSET = "file")
load("images/icon_confetti_ball.png", ICON_CONFETTI_BALL_ASSET = "file")
load("images/icon_cricket_game.png", ICON_CRICKET_GAME_ASSET = "file")
load("images/icon_diving_mask.png", ICON_DIVING_MASK_ASSET = "file")
load("images/icon_dove.png", ICON_DOVE_ASSET = "file")
load("images/icon_drum.png", ICON_DRUM_ASSET = "file")
load("images/icon_egg.png", ICON_EGG_ASSET = "file")
load("images/icon_field_hockey.png", ICON_FIELD_HOCKEY_ASSET = "file")
load("images/icon_firecracker.png", ICON_FIRECRACKER_ASSET = "file")
load("images/icon_fireworks.png", ICON_FIREWORKS_ASSET = "file")
load("images/icon_football.png", ICON_FOOTBALL_ASSET = "file")
load("images/icon_fork_and_knife_with_plate.png", ICON_FORK_AND_KNIFE_WITH_PLATE_ASSET = "file")
load("images/icon_four_leaf_clover.png", ICON_FOUR_LEAF_CLOVER_ASSET = "file")
load("images/icon_full_moon.png", ICON_FULL_MOON_ASSET = "file")
load("images/icon_gift.png", ICON_GIFT_ASSET = "file")
load("images/icon_glowing_star.png", ICON_GLOWING_STAR_ASSET = "file")
load("images/icon_golf.png", ICON_GOLF_ASSET = "file")
load("images/icon_guitar.png", ICON_GUITAR_ASSET = "file")
load("images/icon_historic_landmark.png", ICON_HISTORIC_LANDMARK_ASSET = "file")
load("images/icon_ice_hockey.png", ICON_ICE_HOCKEY_ASSET = "file")
load("images/icon_jack_o_lantern.png", ICON_JACK_O_LANTERN_ASSET = "file")
load("images/icon_lion.png", ICON_LION_ASSET = "file")
load("images/icon_man_dancing.png", ICON_MAN_DANCING_ASSET = "file")
load("images/icon_medal.png", ICON_MEDAL_ASSET = "file")
load("images/icon_menorah.png", ICON_MENORAH_ASSET = "file")
load("images/icon_microphone.png", ICON_MICROPHONE_ASSET = "file")
load("images/icon_military_medal.png", ICON_MILITARY_MEDAL_ASSET = "file")
load("images/icon_mountain.png", ICON_MOUNTAIN_ASSET = "file")
load("images/icon_mrs_claus.png", ICON_MRS_CLAUS_ASSET = "file")
load("images/icon_musical_note.png", ICON_MUSICAL_NOTE_ASSET = "file")
load("images/icon_national_park.png", ICON_NATIONAL_PARK_ASSET = "file")
load("images/icon_palm_tree.png", ICON_PALM_TREE_ASSET = "file")
load("images/icon_party_popper.png", ICON_PARTY_POPPER_ASSET = "file")
load("images/icon_partying_face.png", ICON_PARTYING_FACE_ASSET = "file")
load("images/icon_performing_arts.png", ICON_PERFORMING_ARTS_ASSET = "file")
load("images/icon_rabbit_face.png", ICON_RABBIT_FACE_ASSET = "file")
load("images/icon_racing_car.png", ICON_RACING_CAR_ASSET = "file")
load("images/icon_rainbow.png", ICON_RAINBOW_ASSET = "file")
load("images/icon_red_envelope.png", ICON_RED_ENVELOPE_ASSET = "file")
load("images/icon_red_heart.png", ICON_RED_HEART_ASSET = "file")
load("images/icon_red_paper_lantern.png", ICON_RED_PAPER_LANTERN_ASSET = "file")
load("images/icon_roller_coaster.png", ICON_ROLLER_COASTER_ASSET = "file")
load("images/icon_rose.png", ICON_ROSE_ASSET = "file")
load("images/icon_sailing.png", ICON_SAILING_ASSET = "file")
load("images/icon_santa_claus.png", ICON_SANTA_CLAUS_ASSET = "file")
load("images/icon_saxophone.png", ICON_SAXOPHONE_ASSET = "file")
load("images/icon_ship.png", ICON_SHIP_ASSET = "file")
load("images/icon_skis.png", ICON_SKIS_ASSET = "file")
load("images/icon_soccer_ball.png", ICON_SOCCER_BALL_ASSET = "file")
load("images/icon_sparkler.png", ICON_SPARKLER_ASSET = "file")
load("images/icon_studio_microphone.png", ICON_STUDIO_MICROPHONE_ASSET = "file")
load("images/icon_suitcase.png", ICON_SUITCASE_ASSET = "file")
load("images/icon_sunglasses.png", ICON_SUNGLASSES_ASSET = "file")
load("images/icon_surfing.png", ICON_SURFING_ASSET = "file")
load("images/icon_tennis_ball.png", ICON_TENNIS_BALL_ASSET = "file")
load("images/icon_turkey.png", ICON_TURKEY_ASSET = "file")
load("images/icon_volleyball.png", ICON_VOLLEYBALL_ASSET = "file")
load("images/icon_woman_dancing.png", ICON_WOMAN_DANCING_ASSET = "file")
load("images/iconote_default.png", ICONOTE_DEFAULT_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_MSG = "Display a scrolling message with one of the 75 predefined icons or your photo."
SLOW = "300"
NORMAL = "100"
FAST = "50"
DISPLAY_ICON = "1"
DISPLAY_PHOTO = "2"
DISPLAY_ICONOTE = "default"
DEFAULT_COLOR = "#FFFFFF"
DEFAULT_LINESPACING = "0"
ALIGN_CENTER = "center"
DEFAULT_FONT = "tb-8"
BLANK_LINE_FONT = "CG-pixel-3x5-mono"
BOX_COLOR = "#000000"
IMAGE_DURATION = "2"  # seconds

def handle_icon(config):
    icon_name = config.get("icon", DISPLAY_ICONOTE)

    encoded = None
    if icon_name != DISPLAY_ICONOTE:
        for sublist in ICONS:
            if icon_name in sublist:
                encoded = sublist[sublist.index(icon_name)]
                break

    if encoded == None or icon_name == DISPLAY_ICONOTE:
        encoded = ICONOTE

    return encoded

def handle_photo(config):
    encoded = config.get("photo", ICONOTE)

    return encoded

def create_image_frame(icon):
    image_frame = render.Box(
        color = BOX_COLOR,
        width = 64,
        height = 32,
        child = render.Image(
            src = icon,
        ),
    )

    return image_frame

def create_message_frame(msg_txt, color_opt, font_opt, align_opt, linespacing_opt, icon):
    children = []

    image = render.Box(
        color = BOX_COLOR,
        width = 64,
        height = 32,
        child = render.Image(
            src = icon,
        ),
    )
    blank_line = render.Text(
        content = " ",
        color = color_opt,
        font = BLANK_LINE_FONT,
    )
    text = render.WrappedText(
        content = msg_txt,
        width = 64,
        color = color_opt,
        font = font_opt,
        linespacing = linespacing_opt,
        align = align_opt,
    )

    children.append(image)
    if msg_txt != "":
        children.append(blank_line)  # Add a blank line before showing text
        children.append(text)

    message_frame = render.Marquee(
        width = 64,
        height = 32,
        scroll_direction = "vertical",
        child = render.Column(
            children = children,
        ),
    )

    return message_frame

def main(config):
    display_type = config.get("iconOrimage", DISPLAY_ICON)
    encoded = ""
    if display_type == DISPLAY_ICON:
        encoded = handle_icon(config)
    elif display_type == DISPLAY_PHOTO:
        encoded = handle_photo(config)

    icon = base64.decode(encoded)

    color_opt = config.str("color", DEFAULT_COLOR)
    msg_txt = config.str("msg", DEFAULT_MSG)
    linespacing_opt = int(config.str("linespacing", DEFAULT_LINESPACING))
    scroll_opt = config.str("speed", NORMAL)
    align_opt = config.str("text_align", ALIGN_CENTER)
    font_opt = config.str("font", DEFAULT_FONT)
    delay_opt = int(config.str("delay", IMAGE_DURATION))

    image_frame = create_image_frame(icon)
    message_frame = create_message_frame(msg_txt, color_opt, font_opt, align_opt, linespacing_opt, icon)

    # Create lists of repeated frames
    n_image_frames = int(delay_opt * 1000 / int(scroll_opt))
    n_message_frames = 1  # Only 1 frame is needed
    image_frames = [image_frame] * n_image_frames
    message_frames = [message_frame] * n_message_frames

    return render.Root(
        delay = int(scroll_opt),
        show_full_animation = True,
        child = render.Sequence(
            children = image_frames + message_frames,
        ),
    )

def get_image(iconOrimage):
    if iconOrimage == "1":
        return []
    elif iconOrimage == "2":
        return [
            schema.PhotoSelect(
                id = "photo",
                name = "Add Photo",
                desc = "A photo to display.",
                icon = "image",
            ),
        ]
    else:
        return []

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slow", value = SLOW),
        schema.Option(display = "Normal", value = NORMAL),
        schema.Option(display = "Fast", value = FAST),
    ]
    fonts = [
        schema.Option(display = key.upper(), value = value)
        for key, value in render.fonts.items()
    ]
    fonts = sorted(fonts, key = lambda option: option.display)
    align_opt = [
        schema.Option(display = "Left", value = "left"),
        schema.Option(display = "Center", value = "center"),
        schema.Option(display = "Right", value = "right"),
    ]
    choose_type = [
        schema.Option(display = "Icon", value = "1"),
        schema.Option(display = "Photo", value = "2"),
    ]
    choose_icon = [
        schema.Option(display = key, value = value)
        for key, value in ICONS
    ]
    choose_image_delay = [
        schema.Option(display = "1 sec", value = "1"),
        schema.Option(display = "2 sec", value = "2"),
        schema.Option(display = "3 sec", value = "3"),
        schema.Option(display = "4 sec", value = "4"),
        schema.Option(display = "5 sec", value = "5"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "iconOrimage",
                name = "Icon or Photo",
                desc = "Select to display an icon or photo.",
                icon = "gears",
                default = "1",
                options = choose_type,
            ),
            schema.Dropdown(
                id = "icon",
                name = "Select Icon",
                desc = "Select icon name from list.",
                icon = "icons",
                default = "default",
                options = choose_icon,
            ),
            schema.PhotoSelect(
                id = "photo",
                name = "Select Photo",
                desc = "Choose photo to display.",
                icon = "image",
            ),
            schema.Dropdown(
                id = "speed",
                name = "Scrolling Speed",
                desc = "Change scrolling speed of text and image.",
                icon = "sliders",
                default = scroll_speed[1].value,
                options = scroll_speed,
            ),
            schema.Dropdown(
                id = "delay",
                name = "Image Delay",
                desc = "Change how long image displayed before scrolling begins.",
                icon = "sliders",
                default = choose_image_delay[1].value,
                options = choose_image_delay,
            ),
            schema.Text(
                id = "msg",
                name = "Message",
                desc = "Your message.",
                icon = "message",
                default = DEFAULT_MSG,
            ),
            schema.Color(
                id = "color",
                name = "Text Color",
                desc = "Change color of text.",
                icon = "brush",
                default = "ffffff",
            ),
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Select font size.",
                icon = "font",
                default = "tb-8",
                options = fonts,
            ),
            schema.Dropdown(
                id = "text_align",
                name = "Text Alignment",
                desc = " Select how to align the text.",
                icon = "arrowsLeftRight",
                default = align_opt[1].value,
                options = align_opt,
            ),
            schema.Text(
                id = "linespacing",
                name = "Line Spacing",
                desc = "Adjust line spacing of text.",
                icon = "arrowsUpDown",
                default = "0",
            ),
        ],
    )

ICONOTE = ICONOTE_DEFAULT_ASSET.readall()

ICONS = [["Airplane", ICON_AIRPLANE_ASSET.readall()], ["Balloon", ICON_BALLOON_ASSET.readall()], ["Baseball", ICON_BASEBALL_ASSET.readall()], ["Basketball", ICON_BASKETBALL_ASSET.readall()], ["Beach with Umbrella", ICON_BEACH_WITH_UMBRELLA_ASSET.readall()], ["Beer Mug", ICON_BEER_MUG_ASSET.readall()], ["Bicycle", ICON_BICYCLE_ASSET.readall()], ["Birthday Cake", ICON_BIRTHDAY_CAKE_ASSET.readall()], ["Bottle with Popping Cork", ICON_BOTTLE_WITH_POPPING_CORK_ASSET.readall()], ["Bouquet", ICON_BOUQUET_ASSET.readall()], ["Camera", ICON_CAMERA_ASSET.readall()], ["Camping", ICON_CAMPING_ASSET.readall()], ["Candle", ICON_CANDLE_ASSET.readall()], ["Carousel Horse", ICON_CAROUSEL_HORSE_ASSET.readall()], ["Carp Streamer", ICON_CARP_STREAMER_ASSET.readall()], ["Christmas Tree", ICON_CHRISTMAS_TREE_ASSET.readall()], ["Clinking Glasses", ICON_CLINKING_GLASSES_ASSET.readall()], ["Compass", ICON_COMPASS_ASSET.readall()], ["Confetti Ball", ICON_CONFETTI_BALL_ASSET.readall()], ["Cricket Game", ICON_CRICKET_GAME_ASSET.readall()], ["Diving Mask", ICON_DIVING_MASK_ASSET.readall()], ["Dove", ICON_DOVE_ASSET.readall()], ["Drum", ICON_DRUM_ASSET.readall()], ["Egg", ICON_EGG_ASSET.readall()], ["Field Hockey", ICON_FIELD_HOCKEY_ASSET.readall()], ["Firecracker", ICON_FIRECRACKER_ASSET.readall()], ["Fireworks", ICON_FIREWORKS_ASSET.readall()], ["Football", ICON_FOOTBALL_ASSET.readall()], ["Fork and Knife with Plate", ICON_FORK_AND_KNIFE_WITH_PLATE_ASSET.readall()], ["Four Leaf Clover", ICON_FOUR_LEAF_CLOVER_ASSET.readall()], ["Full Moon", ICON_FULL_MOON_ASSET.readall()], ["Gift", ICON_GIFT_ASSET.readall()], ["Glowing Star", ICON_GLOWING_STAR_ASSET.readall()], ["Golf", ICON_GOLF_ASSET.readall()], ["Guitar", ICON_GUITAR_ASSET.readall()], ["Historic Landmark", ICON_HISTORIC_LANDMARK_ASSET.readall()], ["Ice Hockey", ICON_ICE_HOCKEY_ASSET.readall()], ["Jack-O-Lantern", ICON_JACK_O_LANTERN_ASSET.readall()], ["Lion", ICON_LION_ASSET.readall()], ["Man Dancing", ICON_MAN_DANCING_ASSET.readall()], ["Medal", ICON_MEDAL_ASSET.readall()], ["Menorah", ICON_MENORAH_ASSET.readall()], ["Microphone", ICON_MICROPHONE_ASSET.readall()], ["Military Medal", ICON_MILITARY_MEDAL_ASSET.readall()], ["Mountain", ICON_MOUNTAIN_ASSET.readall()], ["Mrs. Claus", ICON_MRS_CLAUS_ASSET.readall()], ["Musical Note", ICON_MUSICAL_NOTE_ASSET.readall()], ["National Park", ICON_NATIONAL_PARK_ASSET.readall()], ["Palm Tree", ICON_PALM_TREE_ASSET.readall()], ["Party Popper", ICON_PARTY_POPPER_ASSET.readall()], ["Partying Face", ICON_PARTYING_FACE_ASSET.readall()], ["Performing Arts", ICON_PERFORMING_ARTS_ASSET.readall()], ["Rabbit Face", ICON_RABBIT_FACE_ASSET.readall()], ["Racing Car", ICON_RACING_CAR_ASSET.readall()], ["Rainbow", ICON_RAINBOW_ASSET.readall()], ["Red Envelope", ICON_RED_ENVELOPE_ASSET.readall()], ["Red Heart", ICON_RED_HEART_ASSET.readall()], ["Red Paper Lantern", ICON_RED_PAPER_LANTERN_ASSET.readall()], ["Roller Coaster", ICON_ROLLER_COASTER_ASSET.readall()], ["Rose", ICON_ROSE_ASSET.readall()], ["Sailing", ICON_SAILING_ASSET.readall()], ["Santa Claus", ICON_SANTA_CLAUS_ASSET.readall()], ["Saxophone", ICON_SAXOPHONE_ASSET.readall()], ["Ship", ICON_SHIP_ASSET.readall()], ["Skis", ICON_SKIS_ASSET.readall()], ["Soccer Ball", ICON_SOCCER_BALL_ASSET.readall()], ["Sparkler", ICON_SPARKLER_ASSET.readall()], ["Studio Microphone", ICON_STUDIO_MICROPHONE_ASSET.readall()], ["Suitcase", ICON_SUITCASE_ASSET.readall()], ["Sunglasses", ICON_SUNGLASSES_ASSET.readall()], ["Surfing", ICON_SURFING_ASSET.readall()], ["Tennis Ball", ICON_TENNIS_BALL_ASSET.readall()], ["Turkey", ICON_TURKEY_ASSET.readall()], ["Volleyball", ICON_VOLLEYBALL_ASSET.readall()], ["Woman Dancing", ICON_WOMAN_DANCING_ASSET.readall()]]
