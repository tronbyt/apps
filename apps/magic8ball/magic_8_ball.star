"""
App: Magic 8 Ball
Summary: Answer your deepest questions
Desc: Roll one of 20 classic Magic 8 Ball answers. Good luck!
Author: frame-shift
"""

load("animation.star", "animation")
load("images/back_1x.png", BACK_1X = "file")
load("images/back_2x.png", BACK_2X = "file")
load("images/front_1x.png", FRONT_1X = "file")
load("images/front_2x.png", FRONT_2X = "file")
load("images/sheet_1x.png", SHEET_1X = "file")
load("images/sheet_2x.png", SHEET_2X = "file")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")

# Display assists
DISPLAY_W, DISPLAY_H = canvas.size()
IS_SQ = DISPLAY_W == DISPLAY_H  # Check if 64x64
IS_2X = canvas.is2x()  # Returns False if 64x64

# Colors and fonts
BG_COLOR = "#777"
BOX_COLOR = "#2742c0"
ANSWER_COLOR = "#d9dce7"
ANSWER_FONT = "terminus-18-light" if IS_2X else "tb-8"

# Ball rendering assists
SHEET = render.Image(src = (SHEET_2X if (IS_2X or IS_SQ) else SHEET_1X).readall())
SHEET_W = SHEET.size()[0]
FRAME_DIM = 52 if (IS_2X or IS_SQ) else 26
FRAME_DELAYS = [
    # (frame number, frame delay in 1/100 sec)
    # 8-ball face
    (0, 106),
    # Rotation
    (1, 6),
    (2, 6),
    (3, 6),
    (4, 6),
    (5, 6),
    (6, 6),
    (7, 6),
    (8, 6),
    (9, 6),
    (10, 6),
    (11, 6),
    (12, 6),
    (13, 6),
    (14, 6),
    (15, 6),
    (16, 6),
    (17, 6),
    (18, 6),
    (19, 6),
    # Empty window hold
    (20, 51),
    # Triangle surfacing
    (21, 18),
    (22, 14),
    (23, 14),
    (24, 12),
    (25, 12),
    (26, 16),
    # 8-ball back
    (27, 100),
]
BALL_FRONT = render.Image(src = (FRONT_2X if (IS_2X or IS_SQ) else FRONT_1X).readall())
BALL_BACK = render.Image(src = (BACK_2X if (IS_2X or IS_SQ) else BACK_1X).readall())

# Animation assists
FRAME_BASE_DELAY = 10  # ms per tick, by default this is 50 on pixlet
FPS = int(1000 // FRAME_BASE_DELAY)
BOX_W = int(DISPLAY_W * 0.90625)
BOX_H = FRAME_DIM if not IS_SQ else DISPLAY_H - 6  # Ensures taller box on 64x64 displays

# Magic 8 Ball answers
ANSWERS = [
    "It is certain",
    "It is decidedly so",
    "Without a doubt",
    "Yes definitely",
    "You may rely on it",
    "As I see it, yes",
    "Most likely",
    "Outlook good",
    "Yes",
    "Signs point to yes",
    "Reply hazy, try again",
    "Ask again later",
    "Better not tell you now",
    "Cannot predict now",
    "Concentrate and ask again",  # ANSWERS[14], the longest
    "Don't count on it",
    "My reply is no",
    "My sources say no",
    "Outlook not so good",
    "Very doubtful",
]

def main(config):
    """Render the Magic 8 Ball animation.

    Args:
      config: (dict) App configuration values, including the optional background color.

    Returns:
      root: (render.Root) Root render tree for the full Magic 8 Ball animation.
    """
    bg_color = config.get("bg_color", BG_COLOR)

    return render.Root(
        delay = FRAME_BASE_DELAY,
        show_full_animation = True,
        child = render.Box(
            color = bg_color,
            width = DISPLAY_W,
            height = DISPLAY_H,
            child = render.Sequence(
                children = [
                    ball_pause(2, "front"),
                    ball_shake(2),
                    ball_spin(),  # This takes 4.57 secs at FRAME_BASE_DELAY = 10
                    ball_pause(0.5, "back"),
                    box_zoom(1),
                    show_answer(5),
                ],
            ),
        ),
    )

def ball_pause(dur, face):
    """Pause on a ball face for a duration.

    Args:
      dur: (float | int) Pause length in seconds.
      face: (str) Which face to display, either "front" or "back".

    Returns:
      animation: (render.Animation) Static animation for the selected face.
    """
    total_frames = int(dur * FPS)
    ball_face = BALL_BACK if face == "back" else BALL_FRONT

    return render.Animation(
        children = [ball_face for _ in range(total_frames)],
    )

def ball_spin():
    """Spin the 8-ball through its frame sequence.

    Returns:
      animation: (render.Animation) Full spin animation for the ball.
    """
    frames = []
    for f in FRAME_DELAYS:
        f_num, f_del = f
        offset = SHEET_W - (FRAME_DIM * ((2 * f_num) + 1))
        for _ in range(f_del):
            frames.append(
                render.Box(
                    width = FRAME_DIM,
                    height = FRAME_DIM,
                    child = render.Padding(
                        child = SHEET,
                        pad = (offset, 0, 0, 0),
                    ),
                ),
            )

    return render.Animation(
        children = frames,
    )

def ball_shake(dur):
    """Shake the ball side to side for a duration.

    Args:
      dur: (float | int) Shake length in seconds.
    Returns:
      animation: (animation.Transformation) Side-to-side movement animation for the ball.
    """
    total_frames = int(dur * FPS)
    shakes = 6  # One shake = moving either left or right
    move_amt = 4 if IS_2X else 2  # Amount to move in pixels

    # Assemble move amounts and keyframe percents
    movements = [0] + [move_amt if s % 2 == 0 else -move_amt for s in range(shakes)] + [0]
    num_movements = len(movements)
    percents = [x / num_movements for x in range(num_movements)]

    # Assemble keyframes
    built_keyframes = []
    for i in range(num_movements):
        built_keyframes.append(
            animation.Keyframe(
                percentage = percents[i],
                transforms = [animation.Translate(movements[i], 0)],
            ),
        )

    return animation.Transformation(
        child = BALL_FRONT,
        width = FRAME_DIM,
        height = FRAME_DIM,
        duration = total_frames,
        keyframes = built_keyframes,
    )

def box_zoom(dur):
    """Zoom the answer box into view.

    Args:
      dur: (float | int) Zoom animation duration in seconds.

    Returns:
      stack: (render.Stack) Growing answer box layered over the back face.
    """

    # Make one new box size every 20ms rather than every tick (int(dur * FPS))
    # Browsers stretch frames shorter than 20ms, which made zoom play slowly
    total_frames = int(dur * 1000 // 20)

    frames = []
    for i in range(total_frames):
        t = (i + 1) / total_frames  # Animation progress from 0 to 1
        easing = t * t * (3 - 2 * t)  # Easing smoothstep curve simulating ease_in_out
        for _ in range(2):  # Append each size twice so it stays on screen for two 10ms ticks (20ms)
            frames.append(
                render.Box(
                    width = max(int(BOX_W * easing), 1),
                    height = max(int(BOX_H * easing), 1),
                    color = BOX_COLOR,
                ),
            )

    return render.Stack(
        children = [
            render.Box(
                width = DISPLAY_W,
                height = DISPLAY_H,
                child = BALL_BACK,
            ),
            render.Box(
                width = DISPLAY_W,
                height = DISPLAY_H,
                child = render.Animation(
                    children = frames,
                ),
            ),
        ],
    )

def show_answer(dur):
    """Show a random answer inside the 8-ball box.

    Args:
      dur: (float | int) Answer display duration in seconds.

    Returns:
      sequence: (render.Sequence) Repeated answer frame sequence.
    """
    total_frames = int(dur * FPS)
    answer = ANSWERS[random.number(0, len(ANSWERS) - 1)].upper()
    # answer = ANSWERS[10].upper()  # For testing; ANSWERS[14] is longest; ANSWERS[10] is webp
    # print(answer)  # For testing

    answer_txt = render.WrappedText(
        width = BOX_W - 1,
        content = answer,
        align = "center",
        color = ANSWER_COLOR,
        font = ANSWER_FONT,
    )

    answer_box = render.Box(
        width = BOX_W,
        height = BOX_H,
        color = BOX_COLOR,
        child = answer_txt,
    )

    frame = render.Box(
        child = answer_box,
        width = DISPLAY_W,
        height = DISPLAY_H,
    )

    return render.Sequence(
        children = [frame for _ in range(total_frames)],
    )

def get_schema():
    """Create the app settings schema.

    Returns:
      schema: (schema.Schema) Schema for the app configuration fields.
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "bg_color",
                name = "Background color",
                desc = "",
                icon = "brush",
                default = BG_COLOR,
                palette = [
                    BG_COLOR,
                ],
            ),
        ],
    )
