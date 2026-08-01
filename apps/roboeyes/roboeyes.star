"""
Applet: Robo Eyes
Summary: Animated robot eyes
Description: Animated robot eyes that look around, blink, and react with different moods.
Author: Dennis Hoelscher, Dominique Meurisse, and Brombomb

Copyright (C) 2024-2025 Dennis Hoelscher (FluxGarage C++ Version)
Copyright (C) 2025 Dominique Meurisse (MicroPython Version)
Copyright (C) 2026 Brombomb (Starlark/Pixlet Version)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
"""

load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def draw_rounded_rect(x, y, w, h, r, color):
    x = int(x)
    y = int(y)
    w = int(w)
    h = int(h)
    r = int(r)

    # Ensure w and h are positive
    if w <= 0 or h <= 0:
        return None

    # Clamp r to min(w, h) // 2
    r = min(r, w // 2, h // 2)
    if r <= 0:
        return render.Padding(
            pad = (x, y, 0, 0),
            child = render.Box(width = w, height = h, color = color),
        )

    diameter = 2 * r
    return render.Padding(
        pad = (x, y, 0, 0),
        child = render.Stack(
            children = [
                # Horizontal center box
                render.Padding(
                    pad = (0, r, 0, 0),
                    child = render.Box(width = w, height = h - diameter, color = color),
                ),
                # Vertical center box
                render.Padding(
                    pad = (r, 0, 0, 0),
                    child = render.Box(width = w - diameter, height = h, color = color),
                ),
                # Corners
                render.Padding(
                    pad = (0, 0, 0, 0),
                    child = render.Circle(diameter = diameter, color = color),
                ),
                render.Padding(
                    pad = (w - diameter, 0, 0, 0),
                    child = render.Circle(diameter = diameter, color = color),
                ),
                render.Padding(
                    pad = (0, h - diameter, 0, 0),
                    child = render.Circle(diameter = diameter, color = color),
                ),
                render.Padding(
                    pad = (w - diameter, h - diameter, 0, 0),
                    child = render.Circle(diameter = diameter, color = color),
                ),
            ],
        ),
    )

def draw_triangle(x, y, w, h, slope_right, color):
    x = int(x)
    y = int(y)
    w = int(w)
    h = int(h)
    if w <= 0 or h <= 0:
        return []
    lines = []
    prev_dy = -1
    start_dx = 0
    for dx in range(w + 1):
        if dx < w:
            if slope_right:
                dy = int(h * (dx + 1) / w)
            else:
                dy = int(h * (w - dx) / w)
        else:
            dy = -1
        if dx == 0:
            prev_dy = dy
            start_dx = 0
            continue
        if dy != prev_dy:
            if prev_dy > 0:
                run_width = dx - start_dx
                lines.append(
                    render.Padding(
                        pad = (x + start_dx, y, 0, 0),
                        child = render.Box(width = run_width, height = prev_dy, color = color),
                    ),
                )
            prev_dy = dy
            start_dx = dx
    return lines

def main(config):
    # Seed random
    random.seed(int(time.now().unix))

    # Scale and dimensions
    scale = 2 if canvas.is2x() else 1
    width = 64 * scale
    height = 32 * scale

    # Config options
    eye_color_mode = config.get("eye_color_mode", "cyan")
    custom_eye_color = config.get("custom_eye_color", "#00f0ff")

    bg_color_mode = config.get("bg_color_mode", "black")
    custom_bg_color = config.get("custom_bg_color", "#000000")

    mood_config = config.get("mood", "normal")

    # Map curious mode
    curious_mode_config = config.get("curious", "on")
    if curious_mode_config == "random":
        curious = (random.number(0, 1) == 1)
    else:
        curious = (curious_mode_config == "on")

    # Map cyclops mode
    cyclops_mode_config = config.get("cyclops", "off")
    if cyclops_mode_config == "random":
        cyclops = (random.number(0, 1) == 1)
    else:
        cyclops = (cyclops_mode_config == "on")

    # Map eye color
    eye_color = "#00f0ff"
    if eye_color_mode == "random":
        colors = ["#00f0ff", "#003cff", "#00ff3c", "#ff003c", "#ffcc00", "#ff00cc", "#ffffff", "#ff6c00"]
        eye_color = colors[random.number(0, len(colors) - 1)]
    elif eye_color_mode == "custom":
        eye_color = custom_eye_color
    else:
        color_map = {
            "cyan": "#00f0ff",
            "blue": "#003cff",
            "green": "#00ff3c",
            "red": "#ff003c",
            "yellow": "#ffcc00",
            "magenta": "#ff00cc",
            "white": "#ffffff",
            "orange": "#ff6c00",
        }
        eye_color = color_map.get(eye_color_mode, "#00f0ff")

    # Map bg color
    bg_color = "#000000"
    if bg_color_mode == "random":
        bg_colors = ["#000000", "#121212", "#0a0f1d", "#1a0a2a"]
        bg_color = bg_colors[random.number(0, len(bg_colors) - 1)]
    elif bg_color_mode == "custom":
        bg_color = custom_bg_color
    else:
        bg_color_map = {
            "black": "#000000",
            "dark_grey": "#121212",
            "dark_blue": "#0a0f1d",
        }
        bg_color = bg_color_map.get(bg_color_mode, "#000000")

    # Map mood
    mood = mood_config
    if mood == "random":
        moods = ["normal", "tired", "angry", "happy", "frozen", "scary"]
        mood = moods[random.number(0, len(moods) - 1)]

    duration_secs = int(config.get("duration", "15"))
    frame_delay = 100
    frame_count = int(duration_secs * 1000 / frame_delay)

    # Geometry settings (scaled)
    eye_width = 18 * scale
    eye_height = 18 * scale
    border_radius = 4 * scale
    space_between = 5 * scale

    # Bounds constraints
    if cyclops:
        max_x = width - eye_width
    else:
        max_x = width - eye_width * 2 - space_between
    max_y = height - eye_height

    # Simulation variables (start closed in center)
    curr_x_l = float(max_x // 2)
    curr_y_l = float(max_y // 2)
    curr_h_l = 1.0
    curr_h_r = 1.0

    target_x_l = curr_x_l
    target_y_l = curr_y_l

    eyelids_tired_curr = 0.0
    eyelids_angry_curr = 0.0
    eyelids_happy_curr = 0.0

    # Randomized schedule timers
    next_blink_frame = 30 + random.number(0, 20)
    next_look_frame = 15 + random.number(0, 15)
    next_shake_frame = 60 + random.number(0, 30)
    shake_type = random.number(0, 1)  # 0 = confused, 1 = laugh

    frames = []

    for frame_idx in range(frame_count):
        # Shake offsets
        shake_x = 0.0
        shake_y = 0.0

        if mood == "frozen":
            shake_x = float(2 * scale) if (frame_idx % 2 == 0) else float(-2 * scale)
        elif mood == "scary":
            shake_y = float(2 * scale) if (frame_idx % 2 == 0) else float(-2 * scale)

        # Curious mode height offsets
        curious_offset_l = 0.0
        curious_offset_r = 0.0

        # Target open height for this frame
        th_l = float(eye_height)
        th_r = float(eye_height)

        # Default mood targets
        tired_target = 0.0
        angry_target = 0.0
        happy_target = 0.0

        if mood == "tired" or mood == "scary":
            tired_target = curr_h_l / 2.0
        elif mood == "angry":
            angry_target = curr_h_l / 2.0
        elif mood == "happy":
            happy_target = curr_h_l / 2.0

        # 1. Timeline Script Logic
        # Startup opening (first 10 frames)
        if frame_idx < 10:
            target_x_l = float(max_x // 2)
            target_y_l = float(max_y // 2)

            # Shake sequence logic (confused/laugh)
        elif frame_idx >= next_shake_frame and frame_idx < next_shake_frame + 12:
            # Force looking center during a shake
            target_x_l = float(max_x // 2)
            target_y_l = float(max_y // 2)

            if shake_type == 0:
                # Confused horizontal shake
                shake_x = float(2 * scale) if (frame_idx % 2 == 0) else float(-2 * scale)
                curious_offset_l = float(3 * scale)
                curious_offset_r = float(3 * scale)
            else:
                # Laughing vertical shake
                shake_y = float(2 * scale) if (frame_idx % 2 == 0) else float(-2 * scale)
                happy_target = curr_h_l / 2.0

            # Schedule next shake when this one ends
            if frame_idx == next_shake_frame + 11:
                next_shake_frame = frame_idx + 80 + random.number(0, 60)
                shake_type = random.number(0, 1)

        # Blink logic (takes precedence over looking around)
        if frame_idx >= next_blink_frame and frame_idx < next_blink_frame + 2:
            th_l = 1.0
            th_r = 1.0
            if frame_idx == next_blink_frame + 1:
                next_blink_frame = frame_idx + 35 + random.number(0, 40)

        # Look repositioning logic (only triggers on the specific frame)
        if frame_idx == next_look_frame:
            target_x_l = float(random.number(0, int(max_x)))
            target_y_l = float(random.number(0, int(max_y)))
            next_look_frame = frame_idx + 20 + random.number(0, 20)

        # Curious gaze logic (taller outer eye when looking far left/right)
        if curious and (frame_idx < next_shake_frame or frame_idx >= next_shake_frame + 12):
            if target_x_l <= 2 * scale:
                curious_offset_l = float(4 * scale)
            elif target_x_l >= max_x - 2 * scale:
                if cyclops:
                    curious_offset_l = float(4 * scale)
                else:
                    curious_offset_r = float(4 * scale)

        # 2. Physics / Tween updates
        curr_x_l = curr_x_l + (target_x_l - curr_x_l) * 0.4
        curr_y_l = curr_y_l + (target_y_l - curr_y_l) * 0.4

        curr_x_r = curr_x_l + eye_width + space_between
        curr_y_r = curr_y_l

        curr_h_l = curr_h_l + (th_l + curious_offset_l - curr_h_l) * 0.5
        curr_h_r = curr_h_r + (th_r + curious_offset_r - curr_h_r) * 0.5

        eyelids_tired_curr = eyelids_tired_curr + (tired_target - eyelids_tired_curr) * 0.4
        eyelids_angry_curr = eyelids_angry_curr + (angry_target - eyelids_angry_curr) * 0.4
        eyelids_happy_curr = eyelids_happy_curr + (happy_target - eyelids_happy_curr) * 0.4

        # Display coordinates with shake offsets
        disp_x_l = int(curr_x_l + shake_x)
        disp_y_l = int(curr_y_l + (eye_height - curr_h_l) / 2.0 + shake_y)

        disp_x_r = int(curr_x_r + shake_x)
        disp_y_r = int(curr_y_r + (eye_height - curr_h_r) / 2.0 + shake_y)

        # Clamp drawing coordinates to screen bounds
        disp_x_l = max(0, min(width - 1, disp_x_l))
        disp_y_l = max(0, min(height - 1, disp_y_l))
        disp_x_r = max(0, min(width - 1, disp_x_r))
        disp_y_r = max(0, min(height - 1, disp_y_r))

        w_l = int(eye_width)
        h_l = max(1, int(curr_h_l))
        w_r = int(eye_width)
        h_r = max(1, int(curr_h_r))

        # 3. Assemble widgets in stack
        frame_children = [
            # Background
            render.Box(color = bg_color),
        ]

        # Draw eyes
        left_eye_w = draw_rounded_rect(disp_x_l, disp_y_l, w_l, h_l, border_radius, eye_color)
        if left_eye_w:
            frame_children.append(left_eye_w)

        if not cyclops:
            right_eye_w = draw_rounded_rect(disp_x_r, disp_y_r, w_r, h_r, border_radius, eye_color)
            if right_eye_w:
                frame_children.append(right_eye_w)

        # Eyelids tired overlays
        if eyelids_tired_curr > 0.5:
            lh = int(eyelids_tired_curr)
            if not cyclops:
                frame_children.extend(draw_triangle(disp_x_l, disp_y_l, w_l, lh, False, bg_color))
                frame_children.extend(draw_triangle(disp_x_r, disp_y_r, w_r, lh, True, bg_color))
            else:
                frame_children.extend(draw_triangle(disp_x_l, disp_y_l, w_l // 2, lh, False, bg_color))
                frame_children.extend(draw_triangle(disp_x_l + w_l // 2, disp_y_l, w_l - w_l // 2, lh, True, bg_color))

        # Eyelids angry overlays
        if eyelids_angry_curr > 0.5:
            lh = int(eyelids_angry_curr)
            if not cyclops:
                frame_children.extend(draw_triangle(disp_x_l, disp_y_l, w_l, lh, True, bg_color))
                frame_children.extend(draw_triangle(disp_x_r, disp_y_r, w_r, lh, False, bg_color))
            else:
                frame_children.extend(draw_triangle(disp_x_l, disp_y_l, w_l // 2, lh, True, bg_color))
                frame_children.extend(draw_triangle(disp_x_l + w_l // 2, disp_y_l, w_l - w_l // 2, lh, False, bg_color))

        # Eyelids happy overlays
        if eyelids_happy_curr > 0.5:
            lh = int(eyelids_happy_curr)
            happy_y_l = disp_y_l + h_l - lh
            happy_y_r = disp_y_r + h_r - lh

            happy_l = draw_rounded_rect(disp_x_l - 1 * scale, happy_y_l, w_l + 2 * scale, eye_height, border_radius, bg_color)
            if happy_l:
                frame_children.append(happy_l)

            if not cyclops:
                happy_r = draw_rounded_rect(disp_x_r - 1 * scale, happy_y_r, w_r + 2 * scale, eye_height, border_radius, bg_color)
                if happy_r:
                    frame_children.append(happy_r)

        # Append complete stack to frames list
        frames.append(render.Stack(children = frame_children))

    return render.Root(
        delay = frame_delay,
        child = render.Animation(children = frames),
    )

def get_schema():
    eye_colors = [
        schema.Option(display = "Random", value = "random"),
        schema.Option(display = "Cyan", value = "cyan"),
        schema.Option(display = "Blue", value = "blue"),
        schema.Option(display = "Green", value = "green"),
        schema.Option(display = "Red", value = "red"),
        schema.Option(display = "Yellow", value = "yellow"),
        schema.Option(display = "Magenta", value = "magenta"),
        schema.Option(display = "White", value = "white"),
        schema.Option(display = "Orange", value = "orange"),
        schema.Option(display = "Custom Color", value = "custom"),
    ]

    bg_colors = [
        schema.Option(display = "Black", value = "black"),
        schema.Option(display = "Dark Grey", value = "dark_grey"),
        schema.Option(display = "Dark Blue", value = "dark_blue"),
        schema.Option(display = "Random", value = "random"),
        schema.Option(display = "Custom Color", value = "custom"),
    ]

    moods = [
        schema.Option(display = "Normal", value = "normal"),
        schema.Option(display = "Tired", value = "tired"),
        schema.Option(display = "Angry", value = "angry"),
        schema.Option(display = "Happy", value = "happy"),
        schema.Option(display = "Frozen", value = "frozen"),
        schema.Option(display = "Scary", value = "scary"),
        schema.Option(display = "Random", value = "random"),
    ]

    three_way_options = [
        schema.Option(display = "On", value = "on"),
        schema.Option(display = "Off", value = "off"),
        schema.Option(display = "Random", value = "random"),
    ]

    durations = [
        schema.Option(display = "15 Seconds", value = "15"),
        schema.Option(display = "20 Seconds", value = "20"),
        schema.Option(display = "30 Seconds", value = "30"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "eye_color_mode",
                name = "Eye Color Preset",
                desc = "Select a preset color, random, or custom.",
                icon = "palette",
                default = "cyan",
                options = eye_colors,
            ),
            schema.Color(
                id = "custom_eye_color",
                name = "Custom Eye Color",
                desc = "Used if Eye Color Preset is set to Custom Color.",
                icon = "brush",
                default = "#00f0ff",
            ),
            schema.Dropdown(
                id = "bg_color_mode",
                name = "Background Color Preset",
                desc = "Select a preset color, random, or custom.",
                icon = "image",
                default = "black",
                options = bg_colors,
            ),
            schema.Color(
                id = "custom_bg_color",
                name = "Custom Background Color",
                desc = "Used if Background Color Preset is set to Custom Color.",
                icon = "brush",
                default = "#000000",
            ),
            schema.Dropdown(
                id = "mood",
                name = "Mood",
                desc = "The mood/expression of the robot eyes.",
                icon = "robot",
                default = "normal",
                options = moods,
            ),
            schema.Dropdown(
                id = "curious",
                name = "Curious Mode",
                desc = "Make outer eye larger when looking left or right.",
                icon = "eye",
                default = "on",
                options = three_way_options,
            ),
            schema.Dropdown(
                id = "cyclops",
                name = "Cyclops Mode",
                desc = "Render a single centered eye.",
                icon = "eye",
                default = "off",
                options = three_way_options,
            ),
            schema.Dropdown(
                id = "duration",
                name = "Animation Duration",
                desc = "How long the animation loop runs.",
                icon = "clock",
                default = "15",
                options = durations,
            ),
        ],
    )
