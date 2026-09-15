load("render.star", "render")
load("schema.star", "schema")

# Fast Newton-Raphson iterative approximation for square root
def sqrt(n):
    if n <= 0.0:
        return 0.0
    x = n
    for _ in range(6):
        x = 0.5 * (x + n / x)
    return x

# Pseudo-random number generator (Linear Congruential Generator)
def make_rng(seed_val):
    state = [seed_val]

    def next_float():
        state[0] = (state[0] * 1103515245 + 12345) % 2147483648
        return float(state[0]) / 2147483648.0

    return next_float

def main(config):
    # 1. Safely parse the user's seed from the config
    seed_str = config.get("seed") or "42"

    # Safely convert the string to an integer, ignoring non-numeric input
    seed = 0
    for c in seed_str.elems():
        if c in "0123456789":
            seed = seed * 10 + int(c)
    if seed == 0:
        seed = 42  # Fallback if they enter letters or leave it blank

    rng = make_rng(seed)

    frames = []

    # Exactly 250 frames at 60ms = 15 seconds (Pixlet's hard limit)
    num_frames = 250

    # 15 standard pool ball colors - Updated greens for visibility
    colors = [
        "#fdd835",
        "#1e88e5",
        "#e53935",
        "#8e24aa",
        "#fb8c00",
        "#00ff00",  # Changed from #43a047 (Medium Green) to Bright Lime Green
        "#880e4f",
        "#111111",
        "#fff59d",
        "#90caf9",
        "#ef9a9a",
        "#ce93d8",
        "#ffcc80",
        "#69f0ae",  # Changed from #a5d6a7 (Light Green) to Bright Mint Green
        "#f48fb1",
    ]

    # Initialize the balls
    balls = []

    # 2. Build the 15-ball rack with random micro-variations
    idx = 0
    for col in range(5):
        for row in range(col + 1):
            base_x = 45.0 + col * 1.75
            base_y = 16.0 + (row - col / 2.0) * 2.0

            jitter_x = (rng() - 0.5) * 0.1
            jitter_y = (rng() - 0.5) * 0.1

            balls.append({
                "x": base_x + jitter_x,
                "y": base_y + jitter_y,
                "vx": 0.0,
                "vy": 0.0,
                "color": colors[idx],
                "active": True,
            })
            idx += 1

    # 3. Add the Cue ball at index 15 with randomized break physics
    cue_vy = (rng() - 0.5) * 1.5
    cue_vx = 6.5 + (rng() * 1.5)
    cue_y = 16.0 + (rng() - 0.5) * 2.0

    balls.append({
        "x": 15.0,
        "y": cue_y,
        "vx": cue_vx,
        "vy": cue_vy,
        "color": "#ffffff",
        "active": True,
    })

    pockets = [(2, 2), (32, 2), (62, 2), (2, 30), (32, 30), (62, 30)]

    # Main simulation loop
    for f in range(num_frames):
        # --- 4 SHOTS IN 15 SECONDS ---
        # Fire every 60 frames.
        if f == 60 or f == 120 or f == 180:
            cue = balls[15]

            # If the cue ball scratched, respawn it
            if not cue["active"]:
                cue["x"] = 15.0
                cue["y"] = 16.0
                cue["vx"] = 0.0
                cue["vy"] = 0.0
                cue["active"] = True

            # Find the closest active ball to target
            target = None
            min_dist = 9999.0
            for i in range(15):
                b = balls[i]
                if b["active"]:
                    dx = b["x"] - cue["x"]
                    dy = b["y"] - cue["y"]
                    dist_sq = dx * dx + dy * dy
                    if dist_sq < min_dist:
                        min_dist = dist_sq
                        target = b

            # If target exists, shoot
            if target:
                dx = target["x"] - cue["x"]
                dy = target["y"] - cue["y"]
                dist = sqrt(dx * dx + dy * dy)
                if dist > 0:
                    nx = dx / dist
                    ny = dy / dist
                    shot_power = 4.5 + (rng() * 1.5)
                    cue["vx"] = nx * shot_power
                    cue["vy"] = ny * shot_power

        # 4 physics substeps per frame
        for _ in range(4):
            # 1. Update positions and apply friction
            for b in balls:
                if not b["active"]:
                    continue

                b["x"] += b["vx"] * 0.25
                b["y"] += b["vy"] * 0.25

                # SLIGHTLY HIGHER FRICTION (0.980 instead of 0.985)
                # This ensures balls settle within the 60-frame window
                b["vx"] *= 0.980
                b["vy"] *= 0.980

                # 2. Check Pocket Collisions
                pocketed = False
                for px, py in pockets:
                    dx = b["x"] - px
                    dy = b["y"] - py
                    if (dx * dx + dy * dy) < 6.0:
                        b["active"] = False
                        pocketed = True
                        break

                if pocketed:
                    continue

                # 3. Check Wall Bounces
                if b["x"] < 3.0:
                    b["x"] = 3.0
                    b["vx"] *= -0.7
                elif b["x"] > 61.0:
                    b["x"] = 61.0
                    b["vx"] *= -0.7

                if b["y"] < 3.0:
                    b["y"] = 3.0
                    b["vy"] *= -0.7
                elif b["y"] > 29.0:
                    b["y"] = 29.0
                    b["vy"] *= -0.7

            # 4. Check Ball-to-Ball Collisions
            for i in range(len(balls)):
                b1 = balls[i]
                if not b1["active"]:
                    continue

                for j in range(i + 1, len(balls)):
                    b2 = balls[j]
                    if not b2["active"]:
                        continue

                    dx = b2["x"] - b1["x"]
                    dy = b2["y"] - b1["y"]
                    dist_sq = dx * dx + dy * dy

                    if dist_sq < 4.0:
                        dist = sqrt(dist_sq)
                        if dist == 0.0:
                            dist = 0.001

                        overlap = 2.0 - dist
                        nx = dx / dist
                        ny = dy / dist

                        b1["x"] -= nx * overlap * 0.5
                        b1["y"] -= ny * overlap * 0.5
                        b2["x"] += nx * overlap * 0.5
                        b2["y"] += ny * overlap * 0.5

                        p_dx = b1["vx"] - b2["vx"]
                        p_dy = b1["vy"] - b2["vy"]
                        dot = p_dx * nx + p_dy * ny

                        if dot > 0:
                            b1["vx"] -= dot * nx * 0.95
                            b1["vy"] -= dot * ny * 0.95
                            b2["vx"] += dot * nx * 0.95
                            b2["vy"] += dot * ny * 0.95

        # 5. Render the frame
        children = []

        # Rails
        children.append(
            render.Box(width = 64, height = 32, color = "#3e2723"),
        )

        # Felt
        children.append(
            render.Padding(
                pad = (2, 2, 0, 0),
                child = render.Box(width = 60, height = 28, color = "#1a5e20"),
            ),
        )

        # Pockets
        for px, py in pockets:
            children.append(
                render.Padding(
                    pad = (px - 2, py - 2, 0, 0),
                    child = render.Box(width = 4, height = 4, color = "#000000"),
                ),
            )

        # Draw Balls
        for b in balls:
            if b["active"]:
                rx = int(b["x"]) - 1
                ry = int(b["y"]) - 1

                children.append(
                    render.Padding(
                        pad = (rx, ry, 0, 0),
                        child = render.Box(width = 2, height = 2, color = b["color"]),
                    ),
                )

        frames.append(render.Stack(children = children))

    return render.Root(
        delay = 60,
        child = render.Animation(children = frames),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "seed",
                name = "Random Seed",
                desc = "Enter a number to change the break physics.",
                icon = "dice",
                default = "42",
            ),
        ],
    )
