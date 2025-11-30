"""
Applet: IcoNote
Summary: Scrolling message and image
Description: Display a message with one of 75 predefined icons or your photo.
Author: J. Keybl
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("images/iconote_8738782e.png", ICONOTE_8738782e_ASSET = "file")
load("images/img_01ca078d.png", IMG_01ca078d_ASSET = "file")
load("images/img_0a6e754f.png", IMG_0a6e754f_ASSET = "file")
load("images/img_1060e9a4.png", IMG_1060e9a4_ASSET = "file")
load("images/img_1d184ad5.png", IMG_1d184ad5_ASSET = "file")
load("images/img_206b3372.png", IMG_206b3372_ASSET = "file")
load("images/img_24d80596.png", IMG_24d80596_ASSET = "file")
load("images/img_278d8527.png", IMG_278d8527_ASSET = "file")
load("images/img_367824a8.png", IMG_367824a8_ASSET = "file")
load("images/img_37343f6d.png", IMG_37343f6d_ASSET = "file")
load("images/img_38735b4a.png", IMG_38735b4a_ASSET = "file")
load("images/img_38ad83cd.png", IMG_38ad83cd_ASSET = "file")
load("images/img_3b569aea.png", IMG_3b569aea_ASSET = "file")
load("images/img_3e077491.png", IMG_3e077491_ASSET = "file")
load("images/img_3e43baa8.png", IMG_3e43baa8_ASSET = "file")
load("images/img_452c91a6.png", IMG_452c91a6_ASSET = "file")
load("images/img_45bc9b6e.png", IMG_45bc9b6e_ASSET = "file")
load("images/img_4c2ab3a3.png", IMG_4c2ab3a3_ASSET = "file")
load("images/img_4fafe6f2.png", IMG_4fafe6f2_ASSET = "file")
load("images/img_53c425d8.png", IMG_53c425d8_ASSET = "file")
load("images/img_555f3b74.png", IMG_555f3b74_ASSET = "file")
load("images/img_561b2087.png", IMG_561b2087_ASSET = "file")
load("images/img_56aa2087.png", IMG_56aa2087_ASSET = "file")
load("images/img_57e2c0a1.png", IMG_57e2c0a1_ASSET = "file")
load("images/img_5c5c71f0.png", IMG_5c5c71f0_ASSET = "file")
load("images/img_5cdd88fe.png", IMG_5cdd88fe_ASSET = "file")
load("images/img_5e204f86.png", IMG_5e204f86_ASSET = "file")
load("images/img_5f69ac46.png", IMG_5f69ac46_ASSET = "file")
load("images/img_61832e17.png", IMG_61832e17_ASSET = "file")
load("images/img_64d460b1.png", IMG_64d460b1_ASSET = "file")
load("images/img_64fc03ea.png", IMG_64fc03ea_ASSET = "file")
load("images/img_652cd973.png", IMG_652cd973_ASSET = "file")
load("images/img_6991de6c.png", IMG_6991de6c_ASSET = "file")
load("images/img_6d197562.png", IMG_6d197562_ASSET = "file")
load("images/img_6e1ad94e.png", IMG_6e1ad94e_ASSET = "file")
load("images/img_73427a66.png", IMG_73427a66_ASSET = "file")
load("images/img_74d5ed3e.png", IMG_74d5ed3e_ASSET = "file")
load("images/img_762345cd.png", IMG_762345cd_ASSET = "file")
load("images/img_773b6110.png", IMG_773b6110_ASSET = "file")
load("images/img_7964f8e0.png", IMG_7964f8e0_ASSET = "file")
load("images/img_7a584cf2.png", IMG_7a584cf2_ASSET = "file")
load("images/img_7cec9757.png", IMG_7cec9757_ASSET = "file")
load("images/img_7e6ee4a5.png", IMG_7e6ee4a5_ASSET = "file")
load("images/img_807d5735.png", IMG_807d5735_ASSET = "file")
load("images/img_8170b4c6.png", IMG_8170b4c6_ASSET = "file")
load("images/img_82eca42a.png", IMG_82eca42a_ASSET = "file")
load("images/img_89fbcc05.png", IMG_89fbcc05_ASSET = "file")
load("images/img_8e7efd98.png", IMG_8e7efd98_ASSET = "file")
load("images/img_8f123075.png", IMG_8f123075_ASSET = "file")
load("images/img_8f1f8d22.png", IMG_8f1f8d22_ASSET = "file")
load("images/img_9521cde4.png", IMG_9521cde4_ASSET = "file")
load("images/img_9628ffdf.png", IMG_9628ffdf_ASSET = "file")
load("images/img_96d24b52.png", IMG_96d24b52_ASSET = "file")
load("images/img_9c278919.png", IMG_9c278919_ASSET = "file")
load("images/img_9d1d366b.png", IMG_9d1d366b_ASSET = "file")
load("images/img_9f366ac8.png", IMG_9f366ac8_ASSET = "file")
load("images/img_a40cb9fd.png", IMG_a40cb9fd_ASSET = "file")
load("images/img_a676b1fb.png", IMG_a676b1fb_ASSET = "file")
load("images/img_a83ac675.png", IMG_a83ac675_ASSET = "file")
load("images/img_acf77f3b.png", IMG_acf77f3b_ASSET = "file")
load("images/img_adc39651.png", IMG_adc39651_ASSET = "file")
load("images/img_b204a6db.png", IMG_b204a6db_ASSET = "file")
load("images/img_b359044d.png", IMG_b359044d_ASSET = "file")
load("images/img_b3ddace0.png", IMG_b3ddace0_ASSET = "file")
load("images/img_b970b4f6.png", IMG_b970b4f6_ASSET = "file")
load("images/img_bb8dce5f.png", IMG_bb8dce5f_ASSET = "file")
load("images/img_bcbbfc72.png", IMG_bcbbfc72_ASSET = "file")
load("images/img_c39f83f7.png", IMG_c39f83f7_ASSET = "file")
load("images/img_c90aa2d5.png", IMG_c90aa2d5_ASSET = "file")
load("images/img_c9b02c19.png", IMG_c9b02c19_ASSET = "file")
load("images/img_ca3d6d3c.png", IMG_ca3d6d3c_ASSET = "file")
load("images/img_ca5a5df5.png", IMG_ca5a5df5_ASSET = "file")
load("images/img_d4f70a90.png", IMG_d4f70a90_ASSET = "file")
load("images/img_defadc05.png", IMG_defadc05_ASSET = "file")
load("images/img_ecf1527c.png", IMG_ecf1527c_ASSET = "file")
load("images/img_f9076fc3.png", IMG_f9076fc3_ASSET = "file")

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

ICONOTE = ICONOTE_8738782e_ASSET.readall()

ICONS = [["Airplane", IMG_5c5c71f0_ASSET.readall()], ["Balloon", IMG_ca3d6d3c_ASSET.readall()], ["Baseball", IMG_3e077491_ASSET.readall()], ["Basketball", IMG_7964f8e0_ASSET.readall()], ["Beach with Umbrella", IMG_8170b4c6_ASSET.readall()], ["Beer Mug", IMG_01ca078d_ASSET.readall()], ["Bicycle", IMG_7a584cf2_ASSET.readall()], ["Birthday Cake", IMG_6991de6c_ASSET.readall()], ["Bottle with Popping Cork", IMG_452c91a6_ASSET.readall()], ["Bouquet", IMG_a40cb9fd_ASSET.readall()], ["Camera", IMG_9f366ac8_ASSET.readall()], ["Camping", IMG_c90aa2d5_ASSET.readall()], ["Candle", IMG_6d197562_ASSET.readall()], ["Carousel Horse", IMG_b970b4f6_ASSET.readall()], ["Carp Streamer", IMG_38735b4a_ASSET.readall()], ["Christmas Tree", IMG_3b569aea_ASSET.readall()], ["Clinking Glasses", IMG_4fafe6f2_ASSET.readall()], ["Compass", IMG_8f123075_ASSET.readall()], ["Confetti Ball", IMG_8e7efd98_ASSET.readall()], ["Cricket Game", IMG_7e6ee4a5_ASSET.readall()], ["Diving Mask", IMG_24d80596_ASSET.readall()], ["Dove", IMG_5f69ac46_ASSET.readall()], ["Drum", IMG_b204a6db_ASSET.readall()], ["Egg", IMG_f9076fc3_ASSET.readall()], ["Field Hockey", IMG_762345cd_ASSET.readall()], ["Firecracker", IMG_defadc05_ASSET.readall()], ["Fireworks", IMG_38ad83cd_ASSET.readall()], ["Football", IMG_1d184ad5_ASSET.readall()], ["Fork and Knife with Plate", IMG_73427a66_ASSET.readall()], ["Four Leaf Clover", IMG_acf77f3b_ASSET.readall()], ["Full Moon", IMG_367824a8_ASSET.readall()], ["Gift", IMG_4c2ab3a3_ASSET.readall()], ["Glowing Star", IMG_64fc03ea_ASSET.readall()], ["Golf", IMG_7cec9757_ASSET.readall()], ["Guitar", IMG_b3ddace0_ASSET.readall()], ["Historic Landmark", IMG_89fbcc05_ASSET.readall()], ["Ice Hockey", IMG_5cdd88fe_ASSET.readall()], ["Jack-O-Lantern", IMG_a83ac675_ASSET.readall()], ["Lion", IMG_9628ffdf_ASSET.readall()], ["Man Dancing", IMG_74d5ed3e_ASSET.readall()], ["Medal", IMG_b359044d_ASSET.readall()], ["Menorah", IMG_64d460b1_ASSET.readall()], ["Microphone", IMG_37343f6d_ASSET.readall()], ["Military Medal", IMG_96d24b52_ASSET.readall()], ["Mountain", IMG_56aa2087_ASSET.readall()], ["Mrs. Claus", IMG_773b6110_ASSET.readall()], ["Musical Note", IMG_9c278919_ASSET.readall()], ["National Park", IMG_9521cde4_ASSET.readall()], ["Palm Tree", IMG_c9b02c19_ASSET.readall()], ["Party Popper", IMG_ecf1527c_ASSET.readall()], ["Partying Face", IMG_ca5a5df5_ASSET.readall()], ["Performing Arts", IMG_3e43baa8_ASSET.readall()], ["Rabbit Face", IMG_c39f83f7_ASSET.readall()], ["Racing Car", IMG_53c425d8_ASSET.readall()], ["Rainbow", IMG_d4f70a90_ASSET.readall()], ["Red Envelope", IMG_bcbbfc72_ASSET.readall()], ["Red Heart", IMG_807d5735_ASSET.readall()], ["Red Paper Lantern", IMG_a676b1fb_ASSET.readall()], ["Roller Coaster", IMG_0a6e754f_ASSET.readall()], ["Rose", IMG_206b3372_ASSET.readall()], ["Sailing", IMG_82eca42a_ASSET.readall()], ["Santa Claus", IMG_bb8dce5f_ASSET.readall()], ["Saxophone", IMG_6e1ad94e_ASSET.readall()], ["Ship", IMG_61832e17_ASSET.readall()], ["Skis", IMG_45bc9b6e_ASSET.readall()], ["Soccer Ball", IMG_1060e9a4_ASSET.readall()], ["Sparkler", IMG_561b2087_ASSET.readall()], ["Studio Microphone", IMG_5e204f86_ASSET.readall()], ["Suitcase", IMG_adc39651_ASSET.readall()], ["Sunglasses", IMG_9d1d366b_ASSET.readall()], ["Surfing", IMG_8f1f8d22_ASSET.readall()], ["Tennis Ball", IMG_652cd973_ASSET.readall()], ["Turkey", IMG_57e2c0a1_ASSET.readall()], ["Volleyball", IMG_555f3b74_ASSET.readall()], ["Woman Dancing", IMG_278d8527_ASSET.readall()]]
