load("http.star", "http")
load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

ZEN_API_URL = "https://zenquotes.io/api/today"

DEFAULT_FONT = "tb-8"
DEFAULT_TEXT_COLOR = "#ffffff"
DEFAULT_AUTHOR_COLOR = "#aaaaaa"
DEFAULT_BG_COLOR = "#000000"

def main(config):
    rep = http.get(ZEN_API_URL)
    if rep.status_code != 200:
        quote = "Nature does not hurry, yet everything is accomplished."
        author = "Lao Tzu - " + str(rep.status_code)
    else:
        data = rep.json()
        if not data or len(data) == 0:
            quote = "The void is silent today."
            author = "Unknown"
        else:
            quote_data = data[0]
            quote = quote_data.get("q", "No quote available")
            author = quote_data.get("a", "Unknown")

    font = config.str("font", DEFAULT_FONT)
    random_colors = config.bool("random_colors", False)

    if random_colors:
        text_color, bg_color = generate_contrasting_colors()

        # Keep author color same as text color for guaranteed contrast in random mode
        author_color = text_color
    else:
        text_color = config.str("text_color", DEFAULT_TEXT_COLOR)
        author_color = config.str("author_color", DEFAULT_AUTHOR_COLOR)
        bg_color = config.str("bg_color", DEFAULT_BG_COLOR)

    display_content = render.Column(
        children = [
            render.WrappedText(
                content = quote,
                font = font,
                color = text_color,
            ),
            render.Box(height = 1),  # Spacer
            render.WrappedText(
                content = "- " + author,
                font = "tom-thumb",
                color = author_color,
                align = "right",
            ),
        ],
    )

    # Auto-detect height using canvas module
    display_height = canvas.height()
    full_height = canvas.is2x() or display_height > 32
    marquee_height = display_height

    breathe_mode = config.bool("breathe_mode", False)

    if breathe_mode:
        breath_duration = int(config.str("breath_duration", "4"))
        num_dots = breath_duration

        dot_color_on = config.str("breath_color", "#008080")
        dot_color_off = bg_color

        # Dynamic sizing for 1x vs 2x
        # 1x (32px height): use 3px dots
        # 2x (64px height): use 6px dots
        dot_size = 6 if full_height else 3

        # Slow down animation to ~15fps (66ms) to reduce frame count
        # and prevent cutoff for longer durations (e.g. 6s)
        delay = 66
        frames = []

        def render_dots(fill_progress, pulse_brightness = 1.0):
            children = []
            for i in range(num_dots):
                val = fill_progress - i
                if val >= 1.0:
                    c = dot_color_on
                elif val <= 0.0:
                    c = dot_color_off
                else:
                    c = interpolate_color(dot_color_off, dot_color_on, val)

                if pulse_brightness < 1.0 and val > 0:
                    c = interpolate_color(dot_color_off, c, pulse_brightness)

                children.append(render.Box(width = dot_size, height = dot_size, color = c))

            return render.Row(
                children = children,
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
            )

        # Inhale: Smooth Fill
        # Iterate per second to match duration
        steps_per_second = int(1000 / delay)

        for i in range(breath_duration * steps_per_second):
            p = i / float(breath_duration * steps_per_second)
            progress = p * num_dots
            frames.append(render_dots(progress))
        frames.append(render_dots(float(num_dots)))

        # Hold: "Steady on, quick pulse"
        # Iterate exactly breath_duration times (ticks)
        for i in range(breath_duration):
            # For each second/tick:
            for step in range(steps_per_second):
                p = step / float(steps_per_second)

                # "Quick Pulse": Dip brightness at start, then steady
                # e.g., first 30% of the second is the pulse
                pulse_duration_fraction = 0.3
                factor = 1.0

                if p < pulse_duration_fraction:
                    # Map p (0..0.3) to 0..PI
                    # sin(0)..sin(PI) -> 0..1..0
                    val = math.sin((p / pulse_duration_fraction) * 3.14159)

                    # Dip brightness to 0.4 then back to 1.0
                    factor = 1.0 - (0.6 * val)

                frames.append(render_dots(num_dots, pulse_brightness = factor))

        # Exhale: Unfill
        for i in range(breath_duration * steps_per_second):
            p = i / float(breath_duration * steps_per_second)
            progress = num_dots - (p * num_dots)
            frames.append(render_dots(progress))
        frames.append(render_dots(0.0))

        # Hold Empty (Pause) - 2 seconds
        pause_seconds = 2
        for i in range(pause_seconds * steps_per_second):
            frames.append(render_dots(0.0))

        dot_animation = render.Animation(children = frames)

        # Dynamic layout calculation
        # padding_bottom: 2 for 2x, 1 for 1x
        padding_bottom = 2 if full_height else 1
        spacer_height = 1

        # Calculate available height for marquee
        # Total - (dot_size + padding_bottom + spacer_height)
        marquee_h = marquee_height - (dot_size + padding_bottom + spacer_height)

        return render.Root(
            child = render.Box(
                color = bg_color,
                child = render.Column(
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            height = marquee_h,
                            width = 64,
                            scroll_direction = "vertical",
                            child = display_content,
                            delay = 100,
                        ),
                        render.Box(height = spacer_height),
                        dot_animation,
                        render.Box(height = padding_bottom),
                    ],
                ),
            ),
            delay = delay,
        )
    else:
        return render.Root(
            child = render.Padding(
                pad = (0, 0, 0, 0),
                expanded = True,
                child = render.Box(
                    color = bg_color,
                    child = render.Marquee(
                        height = marquee_height,
                        scroll_direction = "vertical",
                        offset_start = 32,
                        offset_end = 32,
                        child = display_content,
                        delay = 100,
                    ),
                ),
            ),
        )

def rgb_to_hex(r, g, b):
    return "%x%x%x%x%x%x" % (
        r // 16,
        r % 16,
        g // 16,
        g % 16,
        b // 16,
        b % 16,
    )

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    if len(hex_color) == 3:
        hex_color = hex_color[0] * 2 + hex_color[1] * 2 + hex_color[2] * 2
    return int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)

def luminance(hex_color):
    r, g, b = hex_to_rgb(hex_color)
    a = [x / 255.0 for x in [r, g, b]]
    new_a = []
    for x in a:
        if x > 0.03928:
            new_a.append(math.pow((x + 0.055) / 1.055, 2.4))
        else:
            new_a.append(x / 12.92)
    return 0.2126 * new_a[0] + 0.7152 * new_a[1] + 0.0722 * new_a[2]

def contrast_ratio(hex1, hex2):
    lum1 = luminance(hex1)
    lum2 = luminance(hex2)
    brightest = max(lum1, lum2)
    darkest = min(lum1, lum2)
    return (brightest + 0.05) / (darkest + 0.05)

def random_hex_color():
    return "#" + rgb_to_hex(
        random.number(0, 255),
        random.number(0, 255),
        random.number(0, 255),
    )

def generate_contrasting_colors():
    # Try multiple times to find a good pair
    for _ in range(20):
        c1 = random_hex_color()
        c2 = random_hex_color()
        if contrast_ratio(c1, c2) >= 4.5:
            return c1, c2

    # Fallback if no pair found
    return "#ffffff", "#000000"

def interpolate_color(color1_hex, color2_hex, progress):
    r1, g1, b1 = hex_to_rgb(color1_hex)
    r2, g2, b2 = hex_to_rgb(color2_hex)

    r = int(r1 + (r2 - r1) * progress)
    g = int(g1 + (g2 - g1) * progress)
    b = int(b1 + (b2 - b1) * progress)

    return "#" + rgb_to_hex(r, g, b)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "font",
                name = "Font",
                desc = "Font for the quote text",
                icon = "font",
                default = DEFAULT_FONT,
                options = [
                    schema.Option(display = font, value = font)
                    for font in sorted(render.fonts)
                ],
            ),
            schema.Toggle(
                id = "random_colors",
                name = "Random Colors",
                desc = "Use random text and background colors",
                icon = "shuffle",
                default = False,
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color of the quote text",
                icon = "brush",
                default = DEFAULT_TEXT_COLOR,
            ),
            schema.Color(
                id = "author_color",
                name = "Author Color",
                desc = "Color of the author text",
                icon = "brush",
                default = DEFAULT_AUTHOR_COLOR,
            ),
            schema.Color(
                id = "bg_color",
                name = "Background Color",
                desc = "Background color of the app",
                icon = "palette",
                default = DEFAULT_BG_COLOR,
            ),
            schema.Toggle(
                id = "breathe_mode",
                name = "Zen Breath Pacer",
                desc = "Animate background for breathing exercise",
                icon = "star",
                default = False,
            ),
            schema.Color(
                id = "breath_color",
                name = "Breath Color",
                desc = "Color of the breathing dots",
                icon = "palette",
                default = "#008080",
            ),
            schema.Text(
                id = "breath_duration",
                name = "Breath Duration",
                desc = "Cycle duration (sec) & dot count",
                icon = "clock",
                default = "4",
            ),
        ],
    )
