"""
Applet: Halloween Count
Summary: Days until Halloween with configurable animations
Description: Displays how many days remain until Halloween with customizable spooky animation effects including floating sprites, orbiting motion, particles, and pulsing text.
Author: Starrlord
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Ghost pixel art pattern (12x14 pixels) - simplified for Tidbyt screen
GHOST_PIXELS = [
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1],  # Eyes
    [1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1],  # Eyes
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1],  # Mouth
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0],  # Bottom wavy edge
    [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],  # Bottom wavy edge
]

# Jack-o'-lantern pixel art patterns with glow effects
# Each pattern has: [body_pattern, glow_pattern] where:
# 0 = transparent, 1 = pumpkin body, 2 = carved hole (black), 3 = inner glow (yellow)

# Classic Happy Pumpkin (triangular eyes, curved smile)
PUMPKIN_HAPPY = {
    "body": [
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 2, 1, 2, 1, 1, 2, 1, 2, 1, 1],  # Eyes top
        [1, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1],  # Eyes triangular
        [1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1],  # Eyes bottom
        [1, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 1],  # Nose
        [1, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1, 1],  # Mouth curved
        [1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1],  # Mouth smile
        [1, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 1],  # Mouth bottom
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    ],
    "glow": [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 3, 0, 3, 0, 0, 3, 0, 3, 0, 0],  # Eye glow
        [0, 0, 3, 3, 3, 0, 0, 3, 3, 3, 0, 0],  # Eye glow
        [0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0],  # Eye glow
        [0, 0, 0, 0, 3, 0, 0, 3, 0, 0, 0, 0],  # Nose glow
        [0, 0, 3, 0, 0, 0, 0, 0, 0, 3, 0, 0],  # Mouth glow
        [0, 0, 3, 3, 0, 0, 0, 0, 3, 3, 0, 0],  # Mouth glow
        [0, 0, 0, 3, 3, 3, 3, 3, 3, 0, 0, 0],  # Mouth glow
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
}

# Scary/Angry Pumpkin (jagged features, angry expression)
PUMPKIN_SCARY = {
    "body": [
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 2, 2, 2, 1, 1, 1, 1, 2, 2, 2, 1],  # Angry slanted eyes
        [1, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1],  # Eyes
        [1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1],  # Eyes bottom
        [1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1],  # Nose jagged
        [1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2],  # Mouth jagged top
        [1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 1],  # Mouth jagged
        [1, 1, 1, 2, 1, 2, 1, 2, 1, 1, 1, 1],  # Mouth bottom
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    ],
    "glow": [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 3, 3, 3, 0, 0, 0, 0, 3, 3, 3, 0],  # Angry eye glow
        [0, 0, 3, 3, 3, 0, 0, 3, 3, 3, 0, 0],  # Eye glow
        [0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0],  # Eye glow
        [0, 0, 0, 0, 3, 3, 3, 0, 0, 0, 0, 0],  # Nose glow
        [0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3],  # Mouth glow
        [0, 0, 3, 0, 3, 0, 3, 0, 3, 0, 0, 0],  # Mouth glow
        [0, 0, 0, 3, 0, 3, 0, 3, 0, 0, 0, 0],  # Mouth glow
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
}

# Skeletal/Jack Skellington Style (oval eyes, stitched smile)
PUMPKIN_SKELETAL = {
    "body": [
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1],  # Oval eyes
        [1, 1, 2, 2, 1, 1, 1, 1, 2, 2, 1, 1],  # Oval eyes
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1],  # Nose holes
        [1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2],  # Stitched mouth
        [1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 1],  # Stitched pattern
        [1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2],  # Stitched bottom
        [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
    ],
    "glow": [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 3, 3, 0, 0, 0, 0, 3, 3, 0, 0],  # Oval eye glow
        [0, 0, 3, 3, 0, 0, 0, 0, 3, 3, 0, 0],  # Oval eye glow
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0],  # Nose glow
        [0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3],  # Stitched glow
        [0, 0, 3, 0, 3, 0, 3, 0, 3, 0, 0, 0],  # Stitched glow
        [0, 3, 0, 3, 0, 3, 0, 3, 0, 3, 0, 3],  # Stitched glow
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
}

# Default to happy pumpkin
PUMPKIN_PIXELS = PUMPKIN_HAPPY

def create_sprite_pixels(pattern, x_offset, y_offset, color):
    """Create pixel elements for a sprite pattern at given offset"""
    pixels = []

    for row_idx, row in enumerate(pattern):
        for col_idx, pixel in enumerate(row):
            if pixel == 1:  # Only draw filled pixels
                x = x_offset + col_idx
                y = y_offset + row_idx

                # Keep pixels on screen
                if x >= 0 and x < 64 and y >= 0 and y < 32:
                    pixels.append(
                        render.Padding(
                            pad = (x, y, 0, 0),
                            child = render.Box(
                                width = 1,
                                height = 1,
                                color = color,
                            ),
                        ),
                    )

    return pixels

def create_pumpkin_pixels(pumpkin_pattern, x_offset, y_offset):
    """Create multi-layered pumpkin pixels with glowing effects"""
    pixels = []

    body_pattern = pumpkin_pattern["body"]
    glow_pattern = pumpkin_pattern["glow"]

    for row_idx, row in enumerate(body_pattern):
        for col_idx, pixel in enumerate(row):
            x = x_offset + col_idx
            y = y_offset + row_idx

            # Keep pixels on screen
            if x >= 0 and x < 64 and y >= 0 and y < 32:
                pixel_color = None

                # Determine pixel color based on pattern value
                if pixel == 1:  # Pumpkin body (orange)
                    pixel_color = "#FF6600"
                elif pixel == 2:  # Carved hole (black)
                    pixel_color = "#000000"

                # Add body pixel if it exists
                if pixel_color:
                    pixels.append(
                        render.Padding(
                            pad = (x, y, 0, 0),
                            child = render.Box(
                                width = 1,
                                height = 1,
                                color = pixel_color,
                            ),
                        ),
                    )

                # Add glow pixel if it exists
                glow_pixel = glow_pattern[row_idx][col_idx]
                if glow_pixel == 3:  # Yellow glow
                    pixels.append(
                        render.Padding(
                            pad = (x, y, 0, 0),
                            child = render.Box(
                                width = 1,
                                height = 1,
                                color = "#FFFF00",  # Bright yellow glow
                            ),
                        ),
                    )

    return pixels

def add_spooky_particles(progress):
    """Add floating sparkles or spirits in the background"""
    particles = []
    particle_count = 6

    for i in range(particle_count):
        # Particles drift at different speeds
        x = int((i * 12 + progress * (15 + i * 3)) % 70) - 5
        y = int((i * 4) + 2 * math.sin(progress * 6.28 * (1 + i * 0.2)))

        if x >= 0 and x < 64 and y >= 0 and y < 32:
            # Twinkling effect - only show particle sometimes
            if int(progress * 8 + i) % 4 != 0:
                color = "#444444" if i % 3 == 0 else "#666666" if i % 3 == 1 else "#999999"
                particles.append(
                    render.Padding(
                        pad = (x, y, 0, 0),
                        child = render.Box(
                            width = 1,
                            height = 1,
                            color = color,
                        ),
                    ),
                )

    return particles

def get_pulsing_color(progress):
    """Make text pulse between Halloween colors"""
    intensity = (math.sin(progress * 12.56) + 1) / 2  # 0.0 to 1.0
    if intensity > 0.7:
        return "#ff751a"  # Orange
    elif intensity > 0.3:
        return "#ff4500"  # Red-orange
    else:
        return "#cc3300"  # Dark red

def load_sprite_gif(gif_url):
    """Load an animated sprite GIF from cache or web"""

    # Create cache key based on URL
    cache_key = "halloween_gif_" + str(hash(gif_url))

    # Check cache first
    gif_data = cache.get(cache_key)
    if gif_data:
        return base64.decode(gif_data)

    # If not cached, load from web
    response = http.get(gif_url)
    if response.status_code == 200:
        gif_bytes = response.body()

        # Cache for 24 hours
        cache.set(cache_key, base64.encode(gif_bytes), ttl_seconds = 86400)
        return gif_bytes

    # Fallback to None if loading fails
    return None

def get_pumpkin_pattern(pumpkin_style):
    """Get the appropriate pumpkin pattern based on style"""
    if pumpkin_style == "scary":
        return PUMPKIN_SCARY
    elif pumpkin_style == "skeletal":
        return PUMPKIN_SKELETAL
    elif pumpkin_style == "animated":
        return "animated"  # Special marker for GIF
    else:  # default to happy
        return PUMPKIN_HAPPY

def get_ghost_pattern(ghost_style):
    """Get the appropriate ghost pattern based on style"""
    if ghost_style == "animated":
        return "animated"  # Special marker for GIF
    else:  # default to pixel art
        return GHOST_PIXELS

def create_pumpkin_sprite(pumpkin_style, x_offset, y_offset, gif_url = None):
    """Create pumpkin sprite - either pixel art or GIF"""
    if pumpkin_style == "animated":
        # Load and render the GIF if URL provided
        if gif_url:
            gif_data = load_sprite_gif(gif_url)
            if gif_data:
                return [render.Padding(
                    pad = (x_offset, y_offset, 0, 0),
                    child = render.Image(
                        src = gif_data,
                        width = 16,
                        height = 16,
                    ),
                )]

        # Fallback to pixel art if GIF fails to load or no URL provided
        pumpkin_pattern = PUMPKIN_HAPPY
        return create_pumpkin_pixels(pumpkin_pattern, x_offset, y_offset)
    else:
        # Use pixel art
        pumpkin_pattern = get_pumpkin_pattern(pumpkin_style)
        return create_pumpkin_pixels(pumpkin_pattern, x_offset, y_offset)

def create_ghost_sprite(ghost_style, x_offset, y_offset, gif_url = None):
    """Create ghost sprite - either pixel art or GIF"""
    if ghost_style == "animated":
        # Load and render the GIF if URL provided
        if gif_url:
            gif_data = load_sprite_gif(gif_url)
            if gif_data:
                return [render.Padding(
                    pad = (x_offset, y_offset, 0, 0),
                    child = render.Image(
                        src = gif_data,
                        width = 16,
                        height = 16,
                    ),
                )]

        # Fallback to pixel art if GIF fails to load or no URL provided
        return create_sprite_pixels(GHOST_PIXELS, x_offset, y_offset, "#FFFFFF")
    else:
        # Use pixel art
        return create_sprite_pixels(GHOST_PIXELS, x_offset, y_offset, "#FFFFFF")

def create_floating_frame(progress, display_content, font_size, enable_particles, enable_pulsing, pumpkin_style, config):
    """Floating/drifting animation with sprites gently bobbing"""
    animated_elements = []

    # Add particles if enabled
    if enable_particles:
        animated_elements.extend(add_spooky_particles(progress))

    # Calculate floating offsets using sine waves
    ghost_y_offset = int(3 * math.sin(progress * 6.28))  # Float up/down 3 pixels
    pumpkin_y_offset = int(2 * math.sin(progress * 6.28 + 3.14))  # Opposite phase

    # Floating ghost (left side)
    ghost_x, ghost_y = 5, 8 + ghost_y_offset
    ghost_style = config.get("ghost_style", "pixel")
    ghost_sprites = create_ghost_sprite(ghost_style, ghost_x, ghost_y, config.get("ghost_gif_url"))
    animated_elements.extend(ghost_sprites)

    # Floating pumpkin (right side) - use selected style
    pumpkin_x, pumpkin_y = 47, 9 + pumpkin_y_offset
    pumpkin_sprites = create_pumpkin_sprite(pumpkin_style, pumpkin_x, pumpkin_y, config.get("gif_url"))
    animated_elements.extend(pumpkin_sprites)

    # Text color
    text_color = get_pulsing_color(progress) if enable_pulsing else "#ff751a"

    # Centered countdown text overlay with shadow
    text_overlay = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Box(
                color = "#00000000",  # Transparent
                child = render.Stack(
                    children = [
                        # Black shadow for readability
                        render.Padding(
                            pad = (1, 1, 0, 0),
                            child = render.WrappedText(
                                content = display_content,
                                font = font_size,
                                color = "#000000",
                                align = "center",
                            ),
                        ),
                        # Main colored text
                        render.WrappedText(
                            content = display_content,
                            font = font_size,
                            color = text_color,
                            align = "center",
                        ),
                    ],
                ),
            ),
        ],
    )

    return render.Stack(children = animated_elements + [text_overlay])

def create_orbiting_frame(progress, display_content, font_size, enable_particles, enable_pulsing, pumpkin_style, config):
    """Orbiting animation with sprites circling the countdown text"""
    animated_elements = []

    # Add particles if enabled
    if enable_particles:
        animated_elements.extend(add_spooky_particles(progress))

    center_x, center_y = 32, 16
    radius = 16

    # Calculate positions using circular motion
    ghost_angle = progress * 6.28  # Full rotation
    pumpkin_angle = ghost_angle + 3.14  # Opposite side

    ghost_x = int(center_x + radius * math.cos(ghost_angle) - 6)
    ghost_y = int(center_y + radius * math.sin(ghost_angle) - 7)

    pumpkin_x = int(center_x + radius * math.cos(pumpkin_angle) - 6)
    pumpkin_y = int(center_y + radius * math.sin(pumpkin_angle) - 6)

    # Add boundary checks and sprites
    if ghost_x >= -6 and ghost_x < 58 and ghost_y >= -7 and ghost_y < 25:
        ghost_style = config.get("ghost_style", "pixel")
        ghost_sprites = create_ghost_sprite(ghost_style, ghost_x, ghost_y, config.get("ghost_gif_url"))
        animated_elements.extend(ghost_sprites)

    if pumpkin_x >= -6 and pumpkin_x < 58 and pumpkin_y >= -6 and pumpkin_y < 26:
        pumpkin_sprites = create_pumpkin_sprite(pumpkin_style, pumpkin_x, pumpkin_y, config.get("gif_url"))
        animated_elements.extend(pumpkin_sprites)

    # Text color
    text_color = get_pulsing_color(progress) if enable_pulsing else "#ff751a"

    # Text overlay with shadow for readability
    text_overlay = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Box(
                color = "#00000000",  # Transparent
                child = render.Stack(
                    children = [
                        # Black shadow
                        render.Padding(
                            pad = (1, 1, 0, 0),
                            child = render.WrappedText(
                                content = display_content,
                                font = font_size,
                                color = "#000000",
                                align = "center",
                            ),
                        ),
                        # Main colored text
                        render.WrappedText(
                            content = display_content,
                            font = font_size,
                            color = text_color,
                            align = "center",
                        ),
                    ],
                ),
            ),
        ],
    )

    return render.Stack(children = animated_elements + [text_overlay])

def create_crossing_frame(progress, display_content, font_size, enable_particles, enable_pulsing, pumpkin_style, config):
    """Crossing animation - sprites move across the screen in opposite directions"""
    animated_elements = []

    # Add particles if enabled
    if enable_particles:
        animated_elements.extend(add_spooky_particles(progress))

    # Ghost floating across the top (left to right)
    ghost_x = int(-12 + (88 * progress))  # Starts off-screen left, exits off-screen right
    ghost_y = int(1 + 2 * math.sin(progress * 6.28 * 2))  # Gentle vertical bob

    if ghost_x > -12 and ghost_x < 64:  # Only render when potentially on screen
        ghost_style = config.get("ghost_style", "pixel")
        ghost_sprites = create_ghost_sprite(ghost_style, ghost_x, ghost_y, config.get("ghost_gif_url"))
        animated_elements.extend(ghost_sprites)

    # Pumpkin floating across the bottom (right to left) - use selected style
    pumpkin_x = int(64 - (88 * progress))  # Starts off-screen right, exits off-screen left
    pumpkin_y = int(18 + 2 * math.sin(progress * 6.28 * 1.5))  # Different bob pattern

    if pumpkin_x > -12 and pumpkin_x < 64:  # Only render when potentially on screen
        pumpkin_sprites = create_pumpkin_sprite(pumpkin_style, pumpkin_x, pumpkin_y, config.get("gif_url"))
        animated_elements.extend(pumpkin_sprites)

    # Text color
    text_color = get_pulsing_color(progress) if enable_pulsing else "#ff751a"

    # Create text overlay with shadow for readability
    text_overlay = render.Column(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [
            render.Box(
                color = "#00000000",  # Transparent background
                child = render.Stack(
                    children = [
                        # Black shadow for readability
                        render.Padding(
                            pad = (1, 1, 0, 0),
                            child = render.WrappedText(
                                content = display_content,
                                font = font_size,
                                color = "#000000",
                                align = "center",
                            ),
                        ),
                        # Main colored text
                        render.WrappedText(
                            content = display_content,
                            font = font_size,
                            color = text_color,
                            align = "center",
                        ),
                    ],
                ),
            ),
        ],
    )

    return render.Stack(children = animated_elements + [text_overlay])

def main(config):
    timezone = time.tz()
    now = time.now().in_location(timezone)

    halloween_year = now.year
    if now.month > 10:
        halloween_year = now.year + 1

    halloween = time.time(year = halloween_year, month = 10, day = 31, hour = 0, minute = 0, location = timezone)
    days_til_halloween = math.ceil(time.parse_duration(halloween - now).seconds / 86400)

    display_content = ""
    font_size = "6x13"
    if days_til_halloween == 0:
        display_content = "HALL\n-O-\nWEEN!"
        font_size = "5x8"
    elif days_til_halloween == 1:
        display_content = "1\nday!"
    else:
        display_content = "%s\ndays" % days_til_halloween

    # Get animation configuration
    animation_type = config.get("animation_type", "floating")
    enable_particles = config.bool("enable_particles", True)
    enable_pulsing = config.bool("enable_pulsing", False)
    pumpkin_style = config.get("pumpkin_style", "happy")

    # Create animation frames
    frames = []
    total_frames = 40  # ~4 seconds at 100ms delay

    for frame in range(total_frames):
        progress = frame / (total_frames - 1)  # 0.0 to 1.0

        # Choose animation style based on config
        if animation_type == "floating":
            animated_frame = create_floating_frame(progress, display_content, font_size, enable_particles, enable_pulsing, pumpkin_style, config)
        elif animation_type == "orbiting":
            animated_frame = create_orbiting_frame(progress, display_content, font_size, enable_particles, enable_pulsing, pumpkin_style, config)
        else:  # crossing (default from previous implementation)
            animated_frame = create_crossing_frame(progress, display_content, font_size, enable_particles, enable_pulsing, pumpkin_style, config)

        frames.append(animated_frame)

    return render.Root(
        delay = 100,  # Smooth animation at 100ms per frame
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "animation_type",
                name = "Animation Style",
                desc = "Choose the main animation pattern for the sprites",
                icon = "ghost",
                default = "floating",
                options = [
                    schema.Option(
                        display = "Floating/Drifting",
                        value = "floating",
                    ),
                    schema.Option(
                        display = "Orbiting Around Text",
                        value = "orbiting",
                    ),
                    schema.Option(
                        display = "Crossing Screen",
                        value = "crossing",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "ghost_style",
                name = "Ghost Style",
                desc = "Choose the ghost sprite style",
                icon = "ghost",
                default = "pixel",
                options = [
                    schema.Option(
                        display = "Pixel Art",
                        value = "pixel",
                    ),
                    schema.Option(
                        display = "Animated GIF",
                        value = "animated",
                    ),
                ],
            ),
            schema.Text(
                id = "ghost_gif_url",
                name = "Ghost GIF URL",
                desc = "Enter the URL of the animated ghost GIF (only used when Ghost Style is Animated GIF)",
                icon = "link",
                default = "https://64.media.tumblr.com/536ff61c1beb4b95a8125dd3d9b61b2f/tumblr_mqq8rk5J7s1rfjowdo1_500.gif",
            ),
            schema.Dropdown(
                id = "pumpkin_style",
                name = "Pumpkin Style",
                desc = "Choose the jack-o'-lantern face style",
                icon = "ghost",
                default = "happy",
                options = [
                    schema.Option(
                        display = "Happy Classic",
                        value = "happy",
                    ),
                    schema.Option(
                        display = "Scary/Angry",
                        value = "scary",
                    ),
                    schema.Option(
                        display = "Skeletal/Stitched",
                        value = "skeletal",
                    ),
                    schema.Option(
                        display = "Animated GIF",
                        value = "animated",
                    ),
                ],
            ),
            schema.Text(
                id = "gif_url",
                name = "Pumpkin GIF URL",
                desc = "Enter the URL of the animated pumpkin GIF (only used when Pumpkin Style is Animated GIF)",
                icon = "link",
                default = "https://media.tenor.com/yGQVr9voUZYAAAAj/jack-jack-o-lantern.gif",
            ),
            schema.Toggle(
                id = "enable_particles",
                name = "Spooky Particles",
                desc = "Add floating sparkle particles in the background",
                icon = "circle",
                default = True,
            ),
            schema.Toggle(
                id = "enable_pulsing",
                name = "Pulsing Text Colors",
                desc = "Make countdown text pulse between Halloween colors",
                icon = "palette",
                default = False,
            ),
        ],
    )
