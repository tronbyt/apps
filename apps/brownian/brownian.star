load("render.star", "render")
load("schema.star", "schema")

# Custom PRNG
def get_rand(state, min_val, max_val):
    state[0] = (state[0] * 1103515245 + 12345) % 2147483648
    high_bits = state[0] // 65536
    return min_val + (high_bits % (max_val - min_val + 1))

def main(config):
    NUM_PARTICLES = int(config.get("num_particles", "100"))
    DIAMETER = int(config.get("circle_diameter", "6"))
    SEED = int(config.get("seed", "8675309"))

    CIRCLE_R = DIAMETER // 2
    if CIRCLE_R < 1:
        CIRCLE_R = 1

    WIDTH = 64
    HEIGHT = 32
    FRAMES = 150
    HALF_FRAMES = FRAMES // 2
    CIRCLE_R_SQ = CIRCLE_R * CIRCLE_R

    rng_state = [SEED]
    initial_cx = get_rand(rng_state, 5 + CIRCLE_R, WIDTH - 6 - CIRCLE_R)
    initial_cy = get_rand(rng_state, 5 + CIRCLE_R, HEIGHT - 6 - CIRCLE_R)

    circle_state = [initial_cx * 100, initial_cy * 100, 0, 0]
    particles = []

    # Starlark forbids `while` loops to prevent infinite server hangs.
    for _ in range(NUM_PARTICLES * 10):
        if len(particles) >= NUM_PARTICLES:
            break

        x = get_rand(rng_state, 0, WIDTH - 1)
        y = get_rand(rng_state, 0, HEIGHT - 1)
        vx = get_rand(rng_state, -1, 1)
        vy = get_rand(rng_state, -1, 1)

        # Ensure particles always have some momentum
        if vx == 0 and vy == 0:
            vx = 1
            vy = -1

        dx = x - initial_cx
        dy = y - initial_cy
        if (dx * dx) + (dy * dy) > CIRCLE_R_SQ:
            particles.append([x, y, vx, vy])

    animation_frames = []

    # Replaced 'frame_idx' with '_' to resolve the unused-variable linting error
    for _ in range(HALF_FRAMES):
        frame_children = []

        # --- CIRCLE PHYSICS UPDATE ---
        circle_state[0] += circle_state[2]
        circle_state[1] += circle_state[3]

        # Retain momentum, applying a very light friction
        circle_state[2] = (circle_state[2] * 95) // 100
        circle_state[3] = (circle_state[3] * 95) // 100

        # --- STRICT CIRCLE WALL BOUNCE ---
        min_x = CIRCLE_R * 100
        max_x = (WIDTH - CIRCLE_R - 1) * 100
        if circle_state[0] <= min_x:
            circle_state[0] = min_x
            circle_state[2] = -circle_state[2]
        elif circle_state[0] >= max_x:
            circle_state[0] = max_x
            circle_state[2] = -circle_state[2]

        min_y = CIRCLE_R * 100
        max_y = (HEIGHT - CIRCLE_R - 1) * 100
        if circle_state[1] <= min_y:
            circle_state[1] = min_y
            circle_state[3] = -circle_state[3]
        elif circle_state[1] >= max_y:
            circle_state[1] = max_y
            circle_state[3] = -circle_state[3]

        cx = circle_state[0] // 100
        cy = circle_state[1] // 100

        frame_children.append(render.Padding(pad = (cx - CIRCLE_R, cy - CIRCLE_R, 0, 0), child = render.Circle(color = "#ff0000", diameter = CIRCLE_R * 2)))

        # Move all particles and check wall/circle collisions
        for p in particles:
            p[0] += p[2]
            p[1] += p[3]

            # --- STRICT PARTICLE WALL BOUNCE ---
            if p[0] <= 0:
                p[0] = 0
                p[2] = -p[2]
            elif p[0] >= WIDTH - 1:
                p[0] = WIDTH - 1
                p[2] = -p[2]

            if p[1] <= 0:
                p[1] = 0
                p[3] = -p[3]
            elif p[1] >= HEIGHT - 1:
                p[1] = HEIGHT - 1
                p[3] = -p[3]

            # --- SAFETY PUSH: Eject from circle ---
            cdx = p[0] - cx
            cdy = p[1] - cy
            dist_sq = (cdx * cdx) + (cdy * cdy)

            if dist_sq <= CIRCLE_R_SQ:
                dist = 1
                if dist_sq > 4:
                    dist = 2
                if dist_sq > 9:
                    dist = 3
                if dist_sq > 16:
                    dist = 4

                p[0] = cx + (cdx * (CIRCLE_R + 1)) // dist
                p[1] = cy + (cdy * (CIRCLE_R + 1)) // dist

                p[2] = -p[2]
                p[3] = -p[3]
                circle_state[2] += p[2] * 20
                circle_state[3] += p[3] * 20

                if p[0] < 0:
                    p[0] = 0
                if p[0] >= WIDTH:
                    p[0] = WIDTH - 1
                if p[1] < 0:
                    p[1] = 0
                if p[1] >= HEIGHT:
                    p[1] = HEIGHT - 1

        # --- PARTICLE-PARTICLE COLLISIONS ---
        # Check every particle against every other particle
        num_p = len(particles)
        for i in range(num_p):
            for j in range(i + 1, num_p):
                # If two particles occupy the exact same pixel, they collide
                if particles[i][0] == particles[j][0] and particles[i][1] == particles[j][1]:
                    # Swap X velocities
                    temp_vx = particles[i][2]
                    particles[i][2] = particles[j][2]
                    particles[j][2] = temp_vx

                    # Swap Y velocities
                    temp_vy = particles[i][3]
                    particles[i][3] = particles[j][3]
                    particles[j][3] = temp_vy

        # Render all particles
        for p in particles:
            frame_children.append(render.Padding(pad = (p[0], p[1], 0, 0), child = render.Box(width = 1, height = 1, color = "#ffffff")))

        animation_frames.append(render.Stack(children = frame_children))

    # Boomerang the animation loop
    for i in range(len(animation_frames) - 1, -1, -1):
        animation_frames.append(animation_frames[i])

    return render.Root(delay = 100, child = render.Animation(children = animation_frames))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "num_particles",
                name = "Particle Count",
                desc = "Number of molecules to simulate",
                icon = "certificate",
                default = "100",
            ),
            schema.Text(
                id = "circle_diameter",
                name = "Circle Diameter",
                desc = "Diameter of the central red circle",
                icon = "circle",
                default = "6",
            ),
            schema.Text(
                id = "seed",
                name = "Random Seed",
                desc = "Change this number to randomize the simulation",
                icon = "dice",
                default = "8675309",
            ),
        ],
    )
