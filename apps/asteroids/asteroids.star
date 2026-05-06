load("render.star", "render")
load("random.star", "random")
load("time.star", "time")

# Precomputed Sine and Cosine (36 steps, 10 degrees each)
COS = [1.0, 0.985, 0.94, 0.866, 0.766, 0.643, 0.5, 0.342, 0.174, 0.0, -0.174, -0.342, -0.5, -0.643, -0.766, -0.866, -0.94, -0.985, -1.0, -0.985, -0.94, -0.866, -0.766, -0.643, -0.5, -0.342, -0.174, -0.0, 0.174, 0.342, 0.5, 0.643, 0.766, 0.866, 0.94, 0.985]
SIN = [0.0, 0.174, 0.342, 0.5, 0.643, 0.766, 0.866, 0.94, 0.985, 1.0, 0.985, 0.94, 0.866, 0.766, 0.643, 0.5, 0.342, 0.174, 0.0, -0.174, -0.342, -0.5, -0.643, -0.766, -0.866, -0.94, -0.985, -1.0, -0.985, -0.94, -0.866, -0.766, -0.643, -0.5, -0.342, -0.174]

def get_line_pixels(x0, y0, x1, y1):
    pixels = []
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy

    # Failsafe loop to prevent Pixlet timeouts
    for _ in range(150):
        pixels.append((x0, y0))
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy
    return pixels

def draw_shape(cx, cy, points, angle_idx, scale):
    pixels = []
    c = COS[angle_idx % 36]
    s = SIN[angle_idx % 36]

    rotated = []
    for p in points:
        rx = p[0] * c - p[1] * s
        ry = p[0] * s + p[1] * c
        rotated.append((int(cx + rx * scale), int(cy + ry * scale)))

    for i in range(len(rotated)):
        p1 = rotated[i]
        p2 = rotated[(i + 1) % len(rotated)]
        pixels.extend(get_line_pixels(p1[0], p1[1], p2[0], p2[1]))

    return pixels

def spawn_fragments(a, new_asteroids_list):
    if a["tier"] <= 1:
        return

    t = a["tier"] - 1
    s = a["scale"] * 0.6

    # Physics: By adding and subtracting vx/vy, the resulting vectors are rotated 45 degrees
    # and their magnitude increases by exactly sqrt(2). After two splits (Tier 3 -> 2 -> 1),
    # the final small asteroids will mathematically move exactly 2x as fast as the large ones.
    vx1 = a["vx"] - a["vy"]
    vy1 = a["vy"] + a["vx"]

    vx2 = a["vx"] + a["vy"]
    vy2 = a["vy"] - a["vx"]

    new_asteroids_list.append({"x": a["x"] + vx1 * 4, "y": a["y"] + vy1 * 4, "vx": vx1, "vy": vy1, "points": a["points"], "scale": s, "angle": a["angle"], "spin": a["spin"] * 2, "tier": t})
    new_asteroids_list.append({"x": a["x"] + vx2 * 4, "y": a["y"] + vy2 * 4, "vx": vx2, "vy": vy2, "points": a["points"], "scale": s, "angle": a["angle"] + 18, "spin": -a["spin"] * 2, "tier": t})

def main():
    # Seed the randomizer to ensure a unique starting orientation each time
    random.seed(time.now().unix_nano)

    frames = []
    num_frames = 150

    ship_x = 32.0
    ship_y = 16.0
    ship_scale = 0.65
    ship_speed = 0.8
    ship_dead_timer = 0
    
    # Pick a random starting angle from the 36 available steps
    ship_angle_idx = random.number(0, 35)

    ship_points = [(4, 0), (-3, -3), (-1, 0), (-3, 3)]
    ship_particles = []

    ast1_points = [(2, -2), (3, 0), (2, 2), (0, 3), (-2, 2), (-3, 0), (-2, -3), (0, -2)]
    ast2_points = [(1, -3), (3, -1), (2, 2), (-1, 3), (-3, 1), (-2, -2)]
    ast3_points = [(2, -1), (1, 1), (-1, 2), (-2, 0), (-1, -2)]

    # Lowered initial speeds so the large asteroids move exactly half the speed of the small ones
    asteroids = [
        {"x": 10.0, "y": 5.0, "vx": 0.4, "vy": 0.2, "points": ast1_points, "scale": 1.5, "angle": 0, "spin": 1, "tier": 3},
        {"x": 50.0, "y": 25.0, "vx": -0.3, "vy": -0.3, "points": ast2_points, "scale": 1.5, "angle": 5, "spin": -1, "tier": 3},
        {"x": 10.0, "y": 25.0, "vx": 0.4, "vy": -0.2, "points": ast3_points, "scale": 1.5, "angle": 12, "spin": 2, "tier": 3},
    ]

    bullets = []

    background_elements = [
        render.Box(width = 64, height = 32, color = "#000000"),
        render.Padding(pad = (10, 10, 0, 0), child = render.Box(width = 1, height = 1, color = "#444")),
        render.Padding(pad = (50, 5, 0, 0), child = render.Box(width = 1, height = 1, color = "#444")),
        render.Padding(pad = (25, 28, 0, 0), child = render.Box(width = 1, height = 1, color = "#444")),
        render.Padding(pad = (60, 20, 0, 0), child = render.Box(width = 1, height = 1, color = "#444")),
    ]

    for i in range(num_frames):
        frame_children = list(background_elements)
        all_pixels = {}
        destroyed_asteroids = {}
        new_asteroids = []

        # 1. Ship AI, State, & Movement
        if ship_dead_timer > 0:
            ship_dead_timer -= 1
            if ship_dead_timer == 0:
                ship_x = 32.0
                ship_y = 16.0
                # When respawning after a crash, pick a new random orientation
                ship_angle_idx = random.number(0, 35)
        else:
            danger = False
            turn_dir = 0
            closest_dist = 9999

            c_forward = COS[ship_angle_idx % 36]
            s_forward = SIN[ship_angle_idx % 36]

            # AI: Scan for nearby asteroids in the forward trajectory
            for a_idx in range(len(asteroids)):
                if a_idx in destroyed_asteroids:
                    continue
                a = asteroids[a_idx]

                dx = a["x"] - ship_x
                if dx > 32:
                    dx -= 64.0
                elif dx < -32:
                    dx += 64.0

                dy = a["y"] - ship_y
                if dy > 16:
                    dy -= 32.0
                elif dy < -16:
                    dy += 32.0

                dist_sq = dx * dx + dy * dy

                if dist_sq < 400:
                    dot = c_forward * dx + s_forward * dy
                    if dot > 0:
                        if dist_sq < closest_dist:
                            closest_dist = dist_sq
                            danger = True
                            cross = c_forward * dy - s_forward * dx
                            if cross > 0:
                                turn_dir = -2
                            else:
                                turn_dir = 2

            if danger:
                ship_angle_idx = (ship_angle_idx + turn_dir) % 36

            c = COS[ship_angle_idx]
            s = SIN[ship_angle_idx]

            ship_x = (ship_x + ship_speed * c) % 64
            ship_y = (ship_y + ship_speed * s) % 32

            # Fire pattern: Strict maximum of 2 bullets alive
            cycle = i % 24
            if (cycle == 0 or cycle == 2) and len(bullets) < 2:
                tip_x = ship_x + (4 * ship_scale) * c
                tip_y = ship_y + (4 * ship_scale) * s
                bullets.append({"x": tip_x, "y": tip_y, "vx": 3.0 * c, "vy": 3.0 * s, "life": 22})

        # 2. Handle Wrapped Bullet Collisions
        active_bullets = []
        for b in bullets:
            b["life"] -= 1
            if b["life"] <= 0:
                continue

            b["x"] = (b["x"] + b["vx"]) % 64
            b["y"] = (b["y"] + b["vy"]) % 32

            hit = False
            for a_idx in range(len(asteroids)):
                if a_idx in destroyed_asteroids:
                    continue
                a = asteroids[a_idx]

                dx = abs(a["x"] - b["x"])
                if dx > 32:
                    dx = 64.0 - dx
                dy = abs(a["y"] - b["y"])
                if dy > 16:
                    dy = 32.0 - dy

                r = a["scale"] * 2.5

                if (dx * dx + dy * dy) < (r * r):
                    hit = True
                    destroyed_asteroids[a_idx] = True
                    spawn_fragments(a, new_asteroids)
                    break

            if hit == False:
                active_bullets.append(b)
                bx, by = int(b["x"]), int(b["y"])
                all_pixels["%d_%d" % (bx, by)] = {"x": bx, "y": by, "color": "#FFFFFF"}
        bullets = active_bullets

        # 3. Handle Ship-Asteroid Collisions
        if ship_dead_timer == 0:
            for a_idx in range(len(asteroids)):
                if a_idx in destroyed_asteroids:
                    continue
                a = asteroids[a_idx]

                dx = abs(a["x"] - ship_x)
                if dx > 32:
                    dx = 64.0 - dx
                dy = abs(a["y"] - ship_y)
                if dy > 16:
                    dy = 32.0 - dy

                r_sum = (a["scale"] * 2.5) + (4 * ship_scale)

                if (dx * dx + dy * dy) < (r_sum * r_sum):
                    ship_dead_timer = 25
                    destroyed_asteroids[a_idx] = True
                    spawn_fragments(a, new_asteroids)

                    for sp in ship_points:
                        p_c = COS[ship_angle_idx]
                        p_s = SIN[ship_angle_idx]
                        p_vx = sp[0] * p_c - sp[1] * p_s
                        p_vy = sp[0] * p_s + sp[1] * p_c
                        ship_particles.append({"x": ship_x, "y": ship_y, "vx": p_vx * 0.6, "vy": p_vy * 0.6, "life": 12})
                    break

        # 4. Handle Asteroid Collisions
        for i_idx in range(len(asteroids)):
            if i_idx in destroyed_asteroids:
                continue
            a1 = asteroids[i_idx]

            for j_idx in range(i_idx + 1, len(asteroids)):
                if j_idx in destroyed_asteroids:
                    continue
                a2 = asteroids[j_idx]

                dx = abs(a1["x"] - a2["x"])
                if dx > 32:
                    dx = 64.0 - dx
                dy = abs(a1["y"] - a2["y"])
                if dy > 16:
                    dy = 32.0 - dy

                r_sum = (a1["scale"] + a2["scale"]) * 2.2

                if (dx * dx + dy * dy) < (r_sum * r_sum):
                    destroyed_asteroids[i_idx] = True
                    destroyed_asteroids[j_idx] = True
                    spawn_fragments(a1, new_asteroids)
                    spawn_fragments(a2, new_asteroids)
                    break

        # 5. Rebuild active asteroid list
        surviving_asteroids = []
        for a_idx in range(len(asteroids)):
            if a_idx not in destroyed_asteroids:
                surviving_asteroids.append(asteroids[a_idx])
        surviving_asteroids.extend(new_asteroids)

        if len(surviving_asteroids) > 8:
            surviving_asteroids = surviving_asteroids[:8]

        asteroids = surviving_asteroids

        for a in asteroids:
            a["x"] = (a["x"] + a["vx"]) % 64
            a["y"] = (a["y"] + a["vy"]) % 32
            a["angle"] = (a["angle"] + a["spin"]) % 36

            ast_pixels = draw_shape(a["x"], a["y"], a["points"], a["angle"], a["scale"])
            for p in ast_pixels:
                px, py = p[0] % 64, p[1] % 32
                all_pixels["%d_%d" % (px, py)] = {"x": px, "y": py, "color": "#888888"}

        # 6. Update and Draw Ship Particles
        active_particles = []
        for p in ship_particles:
            p["life"] -= 1
            if p["life"] > 0:
                p["x"] = (p["x"] + p["vx"]) % 64
                p["y"] = (p["y"] + p["vy"]) % 32
                active_particles.append(p)
                px, py = int(p["x"]), int(p["y"])
                all_pixels["%d_%d" % (px, py)] = {"x": px, "y": py, "color": "#FFFFFF"}
        ship_particles = active_particles

        # 7. Draw ship
        if ship_dead_timer == 0:
            ship_pixels = draw_shape(ship_x, ship_y, ship_points, ship_angle_idx, ship_scale)
            for p in ship_pixels:
                px, py = p[0] % 64, p[1] % 32
                all_pixels["%d_%d" % (px, py)] = {"x": px, "y": py, "color": "#FFFFFF"}

        # 8. Render frames
        for key in all_pixels:
            p = all_pixels[key]
            frame_children.append(
                render.Padding(
                    pad = (p["x"], p["y"], 0, 0),
                    child = render.Box(width = 1, height = 1, color = p["color"]),
                ),
            )

        frames.append(render.Stack(children = frame_children))

    return render.Root(
        delay = 100,
        child = render.Animation(children = frames),
    )
