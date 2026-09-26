"""
Applet: Rainbows
Summary: Colorful wave animations.
Description: Choose between Rainbow Magic, Rainbow Smoke, Rainbow Drops (water ripples), or Random.
Author: andersheie
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "style",
                name = "Animation Style",
                desc = "Choose your preferred wave animation",
                icon = "palette",
                default = "flag",
                options = [
                    schema.Option(
                        display = "Rainbow Splats (Default)",
                        value = "flag",
                    ),
                    schema.Option(
                        display = "Rainbow Magic",
                        value = "magic",
                    ),
                    schema.Option(
                        display = "Rainbow Smoke",
                        value = "smoke",
                    ),
                    schema.Option(
                        display = "Rainbow Drops",
                        value = "drops",
                    ),
                    schema.Option(
                        display = "Rainbow Farts",
                        value = "farts",
                    ),
                    schema.Option(
                        display = "Random",
                        value = "random",
                    ),
                ],
            ),
        ],
    )

# Fast hex conversion
HEX_CHARS = "0123456789abcdef"

def to_hex_fast(val):
    """Fast hex conversion matching original"""
    return HEX_CHARS[val // 16] + HEX_CHARS[val % 16]

def get_cached_animation(style):
    """Get cached animation frames for the given style"""
    cache_key = "rainbows_pixels_%s" % style
    cached_pixels = cache.get(cache_key)

    if cached_pixels != None:
        # Reconstruct frames from cached pixel data
        pixel_data = json.decode(cached_pixels)
        return build_frames_from_pixels(pixel_data)

    # Generate new pixel data
    if style == "flag":
        pixel_data = rainbow_flag_pixels()
    elif style == "magic":
        pixel_data = rainbow_magic_pixels()
    elif style == "smoke":
        pixel_data = rainbow_smoke_pixels()
    elif style == "drops":
        pixel_data = rainbow_drops_pixels()
    elif style == "farts":
        pixel_data = rainbow_farts_pixels()
    else:
        pixel_data = rainbow_flag_pixels()

    # Cache pixel data as JSON for 1 hour (3600 seconds)
    cache.set(cache_key, json.encode(pixel_data), ttl_seconds = 3600)
    return build_frames_from_pixels(pixel_data)

def build_frames_from_pixels(pixel_data):
    """Build render frames from pixel color data"""
    frames = []
    for frame_pixels in pixel_data:
        rows = []
        for row_pixels in frame_pixels:
            pixels_in_row = []
            for hex_color in row_pixels:
                pixels_in_row.append(render.Box(width = 1, height = 1, color = hex_color))
            rows.append(render.Row(children = pixels_in_row))
        frame_render = render.Column(children = rows)
        frames.append(frame_render)
    return frames

def rainbow_flag_pixels():
    """Generate Paint Splat pixel color data"""

    # Bright rainbow colors for paint
    paint_colors = ["#ff0000", "#ff8000", "#ffff00", "#00ff00", "#0080ff", "#8000ff", "#ff0080"]

    # Display dimensions
    width = 64
    height = 32

    # Pre-generate all paint splats
    splats = []

    # Create 25 main splats
    num_splats = 25

    for i in range(num_splats):
        # Randomization
        base_rand = i * 7919 + 1237
        rand1 = (base_rand * 139) % 9973
        rand2 = (base_rand * 277) % 8971
        rand3 = (base_rand * 419) % 7919
        rand4 = (base_rand * 563) % 6857
        rand5 = (base_rand * 701) % 5813

        # Staggered birth frames (0-70, ensuring 10+ frames to fade)
        birth_frame = rand5 % 70

        # Random position anywhere on screen (including borders)
        center_x = rand1 % width
        center_y = rand2 % height

        # Random color - use a different seed for better distribution
        color_idx = (rand3 + i * 13) % len(paint_colors)
        color = paint_colors[color_idx]
        r = int(color[1:3], 16)
        g = int(color[3:5], 16)
        b = int(color[5:7], 16)

        # Random splat size (3-12 pixels)
        splat_size = (rand4 % 10) + 3

        # Create irregular splat shape - each splat has unique pixels
        splat_pixels = []

        # Main oblong shape
        for dy in range(-splat_size, splat_size + 1):
            for dx in range(-splat_size, splat_size + 1):
                px = center_x + dx
                py = center_y + dy

                # Skip out of bounds
                if px < 0 or px >= width or py < 0 or py >= height:
                    continue

                # Simple smooth circular splats - no randomness to avoid lines
                distance = math.sqrt(dx * dx + dy * dy)

                # Single smooth gradient from center to edge - no tiers
                if distance <= splat_size:
                    intensity = 1.0 - (distance / splat_size)  # Smooth 1.0 to 0.0
                    if intensity > 0.1:  # Skip very dim pixels
                        splat_pixels.append([px, py, intensity])

        # Add a few side splats (2-4 small satellite splats)
        num_side_splats = (rand4 % 3) + 2
        for side_idx in range(num_side_splats):
            side_rand1 = (base_rand * (side_idx + 7)) % 8971
            side_rand2 = (base_rand * (side_idx + 11)) % 6857

            # Side splat position (3-8 pixels away from main)
            side_distance = (side_rand1 % 6) + 3
            side_angle = side_rand2 % 8  # 8 directions

            if side_angle == 0:
                side_dx, side_dy = side_distance, 0
            elif side_angle == 1:
                side_dx, side_dy = side_distance, side_distance
            elif side_angle == 2:
                side_dx, side_dy = 0, side_distance
            elif side_angle == 3:
                side_dx, side_dy = -side_distance, side_distance
            elif side_angle == 4:
                side_dx, side_dy = -side_distance, 0
            elif side_angle == 5:
                side_dx, side_dy = -side_distance, -side_distance
            elif side_angle == 6:
                side_dx, side_dy = 0, -side_distance
            else:
                side_dx, side_dy = side_distance, -side_distance

            side_center_x = center_x + side_dx
            side_center_y = center_y + side_dy

            # Small side splat (1-3 pixels)
            side_size = (side_rand1 % 3) + 1
            for sdy in range(-side_size, side_size + 1):
                for sdx in range(-side_size, side_size + 1):
                    spx = side_center_x + sdx
                    spy = side_center_y + sdy

                    if spx >= 0 and spx < width and spy >= 0 and spy < height:
                        side_dist = math.sqrt(sdx * sdx + sdy * sdy)
                        if side_dist <= side_size:
                            side_intensity = (1.0 - (side_dist / side_size)) * 0.7
                            splat_pixels.append([spx, spy, side_intensity])

        # Fade duration - early splats get longer fades, all finish at frame 80
        fade_duration = 80 - birth_frame  # Always fade to exactly frame 80

        splats.append([splat_pixels, r, g, b, birth_frame, fade_duration])

    frames = []

    # Create 80 frames
    for frame in range(80):
        # Create frame canvas
        canvas = []
        for y in range(height):
            row = []
            for x in range(width):
                row.append([0.0, 0.0, 0.0])  # RGB float values for better mixing
            canvas.append(row)

        # Draw all active splats
        for splat_pixels, splat_r, splat_g, splat_b, birth_frame, fade_duration in splats:
            # Calculate age and fade
            age = frame - birth_frame
            if age >= fade_duration or age < 0:
                continue  # Skip expired or not-yet-born splats

            # Fade factor (1.0 = full bright, 0.0 = transparent)
            fade_factor = 1.0 - (age / fade_duration)

            # Draw each pixel in the splat
            for px, py, intensity in splat_pixels:
                final_intensity = intensity * fade_factor

                # Mix colors (additive blending)
                current_r, current_g, current_b = canvas[py][px]

                # Simple additive blending - let colors mix naturally
                new_r = current_r + (splat_r * final_intensity * 0.6)
                new_g = current_g + (splat_g * final_intensity * 0.6)
                new_b = current_b + (splat_b * final_intensity * 0.6)

                # Clamp to 255
                new_r = min(255, new_r)
                new_g = min(255, new_g)
                new_b = min(255, new_b)

                canvas[py][px] = [new_r, new_g, new_b]

        # Convert canvas to hex color data
        frame_pixels = []
        for y in range(height):
            row_pixels = []
            for x in range(width):
                pixel_r, pixel_g, pixel_b = canvas[y][x]

                # Convert to integers
                final_r = int(pixel_r)
                final_g = int(pixel_g)
                final_b = int(pixel_b)

                if final_r > 0 or final_g > 0 or final_b > 0:
                    hex_color = "#" + to_hex_fast(final_r) + to_hex_fast(final_g) + to_hex_fast(final_b)
                else:
                    hex_color = "#000000"

                row_pixels.append(hex_color)

            frame_pixels.append(row_pixels)

        frames.append(frame_pixels)

    return frames

def hue_to_rgb(hue):
    """Convert hue (0-1) to RGB values (0-255)"""
    hue = hue % 1.0
    h = hue * 6.0

    # c = 255
    x = int(255 * (1 - abs(h % 2 - 1)))

    if h < 1:
        return (255, x, 0)
    elif h < 2:
        return (x, 255, 0)
    elif h < 3:
        return (0, 255, x)
    elif h < 4:
        return (0, x, 255)
    elif h < 5:
        return (x, 0, 255)
    else:
        return (255, 0, x)

def rainbow_magic_pixels():
    """Generate Rainbow Magic sparkle/twinkle pixel data"""

    width = 64
    height = 32

    # Pre-generate sparkles
    sparkles = []
    num_sparkles = 80

    for i in range(num_sparkles):
        base_rand = i * 7919 + 2341
        rand1 = (base_rand * 139) % 9973
        rand2 = (base_rand * 277) % 8971
        rand4 = (base_rand * 563) % 6857

        # Position
        x = rand1 % width
        y = rand2 % height

        # Starting hue (0-1) - will cycle through rainbow
        start_hue = (rand1 % 100) / 100.0

        # Sparkle timing
        birth_frame = rand4 % 70
        life_span = 8 + (rand1 % 12)

        # Size (1-3 pixels)
        size = 1 + (rand2 % 3)

        sparkles.append([x, y, start_hue, birth_frame, life_span, size])

    frames = []

    for frame in range(80):
        canvas = []
        for y in range(height):
            row = []
            for x in range(width):
                row.append([0.0, 0.0, 0.0])
            canvas.append(row)

        for sx, sy, start_hue, birth, life, size in sparkles:
            age = frame - birth
            if age < 0 or age >= life:
                continue

            # Cycle through rainbow colors during life
            current_hue = (start_hue + age * 0.15) % 1.0
            sr, sg, sb = hue_to_rgb(current_hue)

            # Twinkle effect
            mid_life = life / 2.0
            if age < mid_life:
                intensity = age / mid_life
            else:
                intensity = 1.0 - ((age - mid_life) / mid_life)
            intensity = intensity * intensity

            for dy in range(-size + 1, size):
                for dx in range(-size + 1, size):
                    px = sx + dx
                    py = sy + dy

                    if px < 0 or px >= width or py < 0 or py >= height:
                        continue

                    dist = abs(dx) + abs(dy)
                    if dist >= size:
                        continue

                    pixel_intensity = intensity * (1.0 - dist / size)

                    current_r, current_g, current_b = canvas[py][px]
                    new_r = min(255, current_r + sr * pixel_intensity)
                    new_g = min(255, current_g + sg * pixel_intensity)
                    new_b = min(255, current_b + sb * pixel_intensity)
                    canvas[py][px] = [new_r, new_g, new_b]

        frame_pixels = []
        for y in range(height):
            row_pixels = []
            for x in range(width):
                pixel_r, pixel_g, pixel_b = canvas[y][x]
                final_r = int(pixel_r)
                final_g = int(pixel_g)
                final_b = int(pixel_b)

                if final_r > 0 or final_g > 0 or final_b > 0:
                    hex_color = "#" + to_hex_fast(final_r) + to_hex_fast(final_g) + to_hex_fast(final_b)
                else:
                    hex_color = "#000000"
                row_pixels.append(hex_color)
            frame_pixels.append(row_pixels)

        frames.append(frame_pixels)

    return frames

def rainbow_smoke_pixels():
    """Generate Rainbow Smoke rising plumes pixel data"""

    width = 64
    height = 32

    # Pre-generate smoke plumes
    plumes = []
    num_plumes = 12

    for i in range(num_plumes):
        base_rand = i * 7919 + 5437
        rand1 = (base_rand * 139) % 9973
        rand2 = (base_rand * 277) % 8971
        rand3 = (base_rand * 419) % 7919

        # Starting position at bottom
        start_x = rand1 % width
        start_y = height - 1 - (rand2 % 5)

        # Starting hue - will shift as smoke rises
        start_hue = (rand3 % 100) / 100.0

        # Birth frame
        birth_frame = (rand1 + rand2) % 40

        # Horizontal drift direction
        drift = -1 if rand3 % 2 == 0 else 1
        drift_speed = 0.3 + (rand1 % 5) * 0.1

        plumes.append([start_x, start_y, start_hue, birth_frame, drift, drift_speed])

    frames = []

    for frame in range(80):
        canvas = []
        for y in range(height):
            row = []
            for x in range(width):
                row.append([0.0, 0.0, 0.0])
            canvas.append(row)

        for start_x, start_y, start_hue, birth, drift, drift_speed in plumes:
            age = frame - birth
            if age < 0:
                continue

            rise_speed = 0.8
            current_y = start_y - age * rise_speed
            current_x = start_x + age * drift_speed * drift

            if current_y < -10:
                continue

            expansion = 2 + age * 0.4
            fade = max(0, 1.0 - age / 50.0)

            # Draw smoke blob with rainbow gradient based on distance from center
            for dy in range(int(-expansion), int(expansion) + 1):
                for dx in range(int(-expansion), int(expansion) + 1):
                    px = int(current_x + dx)
                    py = int(current_y + dy)

                    if px < 0 or px >= width or py < 0 or py >= height:
                        continue

                    dist = math.sqrt(dx * dx + dy * dy)
                    if dist > expansion:
                        continue

                    # Rainbow gradient - hue shifts with distance from center and age
                    pixel_hue = (start_hue + dist * 0.05 + age * 0.05) % 1.0
                    pr, pg, pb = hue_to_rgb(pixel_hue)

                    intensity = (1.0 - dist / expansion) * fade * 0.7

                    current_r, current_g, current_b = canvas[py][px]
                    new_r = min(255, current_r + pr * intensity)
                    new_g = min(255, current_g + pg * intensity)
                    new_b = min(255, current_b + pb * intensity)
                    canvas[py][px] = [new_r, new_g, new_b]

        frame_pixels = []
        for y in range(height):
            row_pixels = []
            for x in range(width):
                pixel_r, pixel_g, pixel_b = canvas[y][x]
                final_r = int(pixel_r)
                final_g = int(pixel_g)
                final_b = int(pixel_b)

                if final_r > 0 or final_g > 0 or final_b > 0:
                    hex_color = "#" + to_hex_fast(final_r) + to_hex_fast(final_g) + to_hex_fast(final_b)
                else:
                    hex_color = "#000000"
                row_pixels.append(hex_color)
            frame_pixels.append(row_pixels)

        frames.append(frame_pixels)

    return frames

def rainbow_drops_pixels():
    """Generate Rainbow Drops water ripple pixel data"""

    width = 64
    height = 32

    # Pre-generate drop impacts
    drops = []
    num_drops = 15

    for i in range(num_drops):
        base_rand = i * 7919 + 8123
        rand1 = (base_rand * 139) % 9973
        rand2 = (base_rand * 277) % 8971
        rand3 = (base_rand * 419) % 7919

        # Impact position
        x = rand1 % width
        y = rand2 % height

        # Starting hue
        start_hue = (rand3 % 100) / 100.0

        # Birth frame
        birth_frame = (rand1 + rand2) % 60

        drops.append([x, y, start_hue, birth_frame])

    frames = []

    # 60 (max birth) + 35 (fade duration) = 95 frames needed
    for frame in range(100):
        canvas = []
        for y in range(height):
            row = []
            for x in range(width):
                row.append([0.0, 0.0, 0.0])
            canvas.append(row)

        for dx_pos, dy_pos, start_hue, birth in drops:
            age = frame - birth
            if age < 0 or age > 35:
                continue

            # Ripple expands outward
            ripple_radius = age * 0.9
            ripple_width = 1.5

            # Fade over time
            fade = 1.0 - (age / 35.0)

            # Draw ripple ring with rainbow colors based on angle
            for py in range(height):
                for px in range(width):
                    dist_x = px - dx_pos
                    dist_y = py - dy_pos
                    dist = math.sqrt(dist_x * dist_x + dist_y * dist_y)

                    ring_dist = abs(dist - ripple_radius)
                    if ring_dist < ripple_width:
                        # Rainbow based on angle around the circle
                        angle = math.atan2(dist_y, dist_x)
                        angle_hue = (angle / (2 * math.pi) + 0.5) % 1.0
                        pixel_hue = (start_hue + angle_hue + age * 0.05) % 1.0
                        dr, dg, db = hue_to_rgb(pixel_hue)

                        intensity = (1.0 - ring_dist / ripple_width) * fade * 0.8

                        current_r, current_g, current_b = canvas[py][px]
                        new_r = min(255, current_r + dr * intensity)
                        new_g = min(255, current_g + dg * intensity)
                        new_b = min(255, current_b + db * intensity)
                        canvas[py][px] = [new_r, new_g, new_b]

        frame_pixels = []
        for y in range(height):
            row_pixels = []
            for x in range(width):
                pixel_r, pixel_g, pixel_b = canvas[y][x]
                final_r = int(pixel_r)
                final_g = int(pixel_g)
                final_b = int(pixel_b)

                if final_r > 0 or final_g > 0 or final_b > 0:
                    hex_color = "#" + to_hex_fast(final_r) + to_hex_fast(final_g) + to_hex_fast(final_b)
                else:
                    hex_color = "#000000"
                row_pixels.append(hex_color)
            frame_pixels.append(row_pixels)

        frames.append(frame_pixels)

    return frames

def rainbow_farts_pixels():
    """Generate Rainbow Farts burst cloud pixel data"""

    width = 64
    height = 32

    # Pre-generate fart bursts
    bursts = []
    num_bursts = 8

    for i in range(num_bursts):
        base_rand = i * 7919 + 3141
        rand1 = (base_rand * 139) % 9973
        rand2 = (base_rand * 277) % 8971
        rand3 = (base_rand * 419) % 7919
        rand4 = (base_rand * 563) % 6857

        # Starting position on left or right edge
        if rand4 % 2 == 0:
            start_x = 0
            direction = 1
        else:
            start_x = width - 1
            direction = -1

        start_y = 8 + (rand2 % 16)

        # Starting hue
        start_hue = (rand3 % 100) / 100.0

        # Birth frame
        birth_frame = (rand1 % 50)

        # Speed variation
        speed = 1.2 + (rand1 % 10) * 0.08

        bursts.append([start_x, start_y, start_hue, birth_frame, direction, speed])

    frames = []

    for frame in range(80):
        canvas = []
        for y in range(height):
            row = []
            for x in range(width):
                row.append([0.0, 0.0, 0.0])
            canvas.append(row)

        for start_x, start_y, start_hue, birth, direction, speed in bursts:
            age = frame - birth
            if age < 0:
                continue

            current_x = start_x + age * speed * direction
            wave_y = start_y + math.sin(age * 0.5) * 3

            if age < 15:
                size = 3 + age * 0.4
            else:
                size = max(1, 9 - (age - 15) * 0.2)

            fade = max(0, 1.0 - age / 40.0)

            if fade <= 0:
                continue

            # Draw cloud puffs with rainbow gradient
            num_puffs = 3
            for puff in range(num_puffs):
                puff_offset = puff * 2 - 2
                puff_x = current_x - direction * puff * 3
                puff_y = wave_y + puff_offset

                # Each puff has a different hue offset
                puff_hue_offset = puff * 0.15

                for dy in range(int(-size), int(size) + 1):
                    for dx in range(int(-size), int(size) + 1):
                        px = int(puff_x + dx)
                        py = int(puff_y + dy)

                        if px < 0 or px >= width or py < 0 or py >= height:
                            continue

                        dist = math.sqrt(dx * dx + dy * dy)
                        if dist > size:
                            continue

                        # Rainbow gradient based on distance from center and puff position
                        pixel_hue = (start_hue + puff_hue_offset + dist * 0.08 + age * 0.04) % 1.0
                        br, bg, bb = hue_to_rgb(pixel_hue)

                        intensity = (1.0 - dist / size) * fade * 0.6

                        current_r, current_g, current_b = canvas[py][px]
                        new_r = min(255, current_r + br * intensity)
                        new_g = min(255, current_g + bg * intensity)
                        new_b = min(255, current_b + bb * intensity)
                        canvas[py][px] = [new_r, new_g, new_b]

        frame_pixels = []
        for y in range(height):
            row_pixels = []
            for x in range(width):
                pixel_r, pixel_g, pixel_b = canvas[y][x]
                final_r = int(pixel_r)
                final_g = int(pixel_g)
                final_b = int(pixel_b)

                if final_r > 0 or final_g > 0 or final_b > 0:
                    hex_color = "#" + to_hex_fast(final_r) + to_hex_fast(final_g) + to_hex_fast(final_b)
                else:
                    hex_color = "#000000"
                row_pixels.append(hex_color)
            frame_pixels.append(row_pixels)

        frames.append(frame_pixels)

    return frames

def main(config):
    style = config.get("style", "flag")
    original_style = style

    # Handle random selection
    if style == "random":
        # Use time-based selection - changes every minute
        now = time.now().unix
        minute_selector = int(now / 60) % 5  # 0, 1, 2, 3, or 4
        if minute_selector == 0:
            style = "flag"
        elif minute_selector == 1:
            style = "magic"
        elif minute_selector == 2:
            style = "smoke"
        elif minute_selector == 3:
            style = "drops"
        else:
            style = "farts"

    # Debug: Print which style is being used (visible in pixlet serve output)
    print("Config style:", original_style, "-> Running:", style)

    # Get cached animation frames
    frames = get_cached_animation(style)

    return render.Root(
        delay = 100,  # Slower animation (default is ~50ms)
        child = render.Animation(children = frames),
    )
